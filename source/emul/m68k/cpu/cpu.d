module emul.m68k.cpu.cpu;

import core.bitop;

import std.typecons;
import std.algorithm;
import std.range;

import emul.m68k.xsetjmp;
import emul.m68k.cpu.cpustate;
import emul.m68k.cpu.memory;
import emul.m68k.cpu.exceptions;

import gamelib.memory.saferef;

import gamelib.debugout;

auto ref truncateReg(T)(ref int val) pure nothrow @nogc { return *(cast(T*)&val); }
auto ref truncateReg(T)(ref uint val) pure nothrow @nogc { return *(cast(T*)&val); }

struct Cpu
{
nothrow:
    CpuState state;
    Memory memory;
    Exceptions exceptions;
    enum MemWordPart
    {
        Full,
        UpperByte,
        LowerByte
    }

    alias InterruptsHook = void   delegate(const CpuPtr, ref Exceptions) nothrow @nogc;
    alias MemReadHook    = ushort delegate(CpuPtr,uint,MemWordPart) nothrow @nogc;
    alias MemWriteHook   = void   delegate(CpuPtr,uint,MemWordPart,ushort) nothrow @nogc;

    void setInterruptsHook(InterruptsHook hook) @nogc pure
    {
        mInterruptsHook = hook;
    }

    void addReadHook(MemReadHook hook, uint begin, uint end) pure
    in
    {
        assert(hook !is null);
        assert(end > begin);
    }
    body
    {
        mReadHooks ~= ReadHookTuple(begin, end, hook);
        mReadHooks.sort!((a,b) => a.begin < b.begin);
        checkHooksRange(mReadHooks);
        mReadHooksRange = tuple(min(mReadHooksRange[0],begin),max(mReadHooksRange[1],end + uint.sizeof));
    }

    void addWriteHook(MemWriteHook hook, uint begin, uint end) pure
    in
    {
        assert(hook !is null);
        assert(end > begin);
    }
    body
    {
        mWriteHooks ~= WriteHookTuple(begin, end, hook);
        mWriteHooks.sort!((a,b) => a.begin < b.begin);
        checkHooksRange(mWriteHooks);
        mWriteHooksRange = tuple(min(mWriteHooksRange[0],begin),max(mWriteHooksRange[1],end + uint.sizeof));
    }

@nogc:
    auto getMemValue(T)(uint offset)
    {
        checkAddress!(T.sizeof)(offset);
        const hook = getHook!true(offset);
        if(hook !is null)
        {
            mixin SafeThis;
            static if(1 == T.sizeof)
            {
                const lower = (0x0 == (offset & 0x1));
                return cast(T)((hook(safeThis, offset & ~0x1, (lower ? MemWordPart.LowerByte : MemWordPart.UpperByte)) >> (lower ? 0 : 8)) & 0xff);
            }
            else static if(2 == T.sizeof)
            {
                return cast(T)hook(safeThis, offset, MemWordPart.Full);
            }
            else static if(4 == T.sizeof)
            {
                const upper = hook(safeThis, offset, MemWordPart.Full);
                const lower = hook(safeThis, offset + 0x2, MemWordPart.Full);
                return cast(T)(lower | (upper << 16));
            }
            else static assert(false);
        }
        memory.checkRange!true(offset,T.sizeof);
        return memory.getValue!T(offset);
    }

    void getMemRange(T)(uint offset, size_t count, scope void delegate(size_t, T) nothrow @nogc sink)
    {
        assert(sink !is null);
        checkAddress!(T.sizeof)(offset);
        //TODO: check hooks
        memory.checkRange!true(offset,count * T.sizeof);
        foreach(i; 0..count)
        {
            sink(i,memory.getValue!T(offset + i * T.sizeof));
        }
    }

    void setMemValue(T)(uint offset, in T val)
    {
        checkAddress!(T.sizeof)(offset);
        const hook = getHook!false(offset);
        if(hook !is null)
        {
            mixin SafeThis;
            static if(1 == T.sizeof)
            {
                const lower = (0x0 == (offset & 0x1));
                hook(safeThis, offset & ~0x1, (lower ? MemWordPart.LowerByte : MemWordPart.UpperByte), cast(ushort)(cast(ushort)val << (lower ? 0 : 8))) ;
            }
            else static if(2 == T.sizeof)
            {
                hook(safeThis, offset, MemWordPart.Full, cast(ushort)val);
            }
            else static if(4 == T.sizeof)
            {
                hook(safeThis, offset, MemWordPart.Full, cast(ushort)(val >>> 16));
                hook(safeThis, offset + 0x2, MemWordPart.Full, cast(ushort)val);
            }
            else static assert(false);
            return;
        }
        memory.checkRange!false(offset,T.sizeof);
        memory.setValue!T(offset,val);
    }

    void triggerException(ExceptionCodes code)
    {
        exceptions.setPendingException(code);
        xlongjmp(mJumpBuf,code);
        assert(false);
    }

    void checkAddress(ubyte Size)(uint offset)
    {
        static if(Size > 1)
        {
            if(0x0 != (offset & 0x1))
            {
                triggerException(ExceptionCodes.Address_error);
                assert(false);
            }
        }
    }

    void process(int ticks = 100)
    {
        mExecuteTicks = ticks;
        processExceptions();
    }

    void beginNextInstruction()
    {
        mSavedTicks = state.TickCounter;
        mCurrentInstructionBuff = mInstructionBuff[0..0];
        mSavedPC = state.PC;
        fetchInstruction(ushort.sizeof);
        mCurrentInstruction = getInstructionData!(ushort,true)(mSavedPC);
    }

    void fetchInstruction(uint size)
    {
        const start = mSavedPC + mCurrentInstructionBuff.length;
        memory.checkRange!true(start,size);
        const buffStart = mCurrentInstructionBuff.length;
        const buffEnd = buffStart + size;
        mInstructionBuff[buffStart..buffEnd] = memory.getRawData(start,size)[0..$];
        mCurrentInstructionBuff = mInstructionBuff[0..buffEnd];
    }

    void endInstruction()
    {
        const delta = cast(int)(state.TickCounter - mSavedTicks);
        mExecuteTicks = max(0,mExecuteTicks - delta);
    }

    void scheduleProcessStop(int ticks) pure @safe
    in
    {
        assert(ticks > 0);
    }
    body
    {
        mExecuteTicks = min(mExecuteTicks, ticks);
    }
    @property bool processed() pure @safe const { return mExecuteTicks <= 0; }
    @property auto ref jmpbuf() pure @safe inout { return mJumpBuf; }
    @property auto currentInstruction() pure @safe const { return mCurrentInstruction; }

    auto getInstructionData(T,bool Raw = false)(uint pc) const pure @safe
    {
        const start = pc - mSavedPC;
        const end   = start + T.sizeof;
        import std.bitmanip;
        static if(Raw)
        {
            import std.system;
            return mCurrentInstructionBuff[start..end].peek!(T,endian)();
        }
        else
        {
            ubyte[T.sizeof] temp = mCurrentInstructionBuff[start..end];
            return bigEndianToNative!(T,T.sizeof)(temp);
        }
    }
private:
    alias ReadHookTuple  = Tuple!(uint, "begin", uint, "end", MemReadHook,  "hook");
    alias WriteHookTuple = Tuple!(uint, "begin", uint, "end", MemWriteHook, "hook");
    InterruptsHook   mInterruptsHook;
    ReadHookTuple[]  mReadHooks;
    WriteHookTuple[] mWriteHooks;
    auto mReadHooksRange  = tuple(0xffffffff,0x0);
    auto mWriteHooksRange = tuple(0xffffffff,0x0);
    xjmp_buf mJumpBuf;
    ubyte[ushort.sizeof * 11] mInstructionBuff;
    ubyte[] mCurrentInstructionBuff;
    ushort mCurrentInstruction;
    uint   mSavedPC;
    uint   mSavedTicks;
    int    mExecuteTicks;

    void processExceptions()
    {
        mixin SafeThis;
        if(mInterruptsHook !is null)
        {
            mInterruptsHook(safeThis, exceptions);
        }
        
        if(0 != exceptions.pendingExceptions)
        {
            static if(size_t.sizeof == exceptions.pendingExceptions.sizeof)
            {
                int ind = bsf(exceptions.pendingExceptions);
            }
            else
            {
                int ind = void;
                if(0 != exceptions.pendingExceptionsLo) ind = bsf(exceptions.pendingExceptionsLo);
                else ind = bsf(exceptions.pendingExceptionsHi) + 32;
            }
            if(!enterException(safeThis,exceptionsByPriotities[ind]))
            {
                while(ind > 0)
                {
                    --ind;
                    const ex = exceptionsByPriotities[ind];
                    if((0x0 != (exceptions.pendingExceptions & (1 << ind))) && enterException(safeThis,ex)) break;
                }
            }
        }
    }

pure @safe:
    static void checkHooksRange(T)(in T[] hooks)
    {
        foreach(i, h2;hooks[1..$])
        {
            const h1 = hooks[i - 1];
            if(h1.end >= h2.begin) assert(false, "Overlapping hooks");
        }
    }

    auto getHook(bool Read)(uint begin) const
    {
        static if(Read)
        {
            if(begin < mReadHooksRange[0] || begin > mReadHooksRange[1]) return null;
            alias arr = mReadHooks;
        }
        else
        {
            if(begin < mWriteHooksRange[0] || begin > mWriteHooksRange[1]) return null;
            alias arr = mWriteHooks;
        }
        foreach_reverse(const ref item; arr)
        {
            if(begin < item.begin) continue;
            if(begin > item.end) break;
            return item.hook;
        }
        return null;
    }
}

alias CpuPtr = SafeRef!Cpu;