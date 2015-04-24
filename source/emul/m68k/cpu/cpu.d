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

    alias InterruptsHook = void delegate(const CpuPtr, ref Exceptions) pure nothrow @nogc;
    alias MemReadHook    = uint delegate(CpuPtr,uint,size_t) pure nothrow @nogc;
    alias MemWriteHook   = void delegate(CpuPtr,uint,size_t,uint) pure nothrow @nogc;

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
        const hook = getHook!true(offset);
        if(hook !is null)
        {
            mixin SafeThis;
            return cast(T)hook(safeThis, offset, T.sizeof);
        }
        memory.checkRange!true(offset,T.sizeof);
        return memory.getValue!T(offset);
    }

    void setMemValue(T)(uint offset, in T val)
    {
        const hook = getHook!false(offset);
        if(hook !is null)
        {
            mixin SafeThis;
            return hook(safeThis, offset, T.sizeof, cast(uint)val);
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

    void processExceptions()
    {
        mixin SafeThis;
        if(mInterruptsHook !is null)
        {
            mInterruptsHook(safeThis, exceptions);
        }

        if(0 != exceptions.pendingExceptions)
        {
            static if(size_t.sizeof == ulong.sizeof)
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

    void beginNextInstruction()
    {
        mCurrentInstructionBuff = mInstructionBuff[0..0];
        fetchInstruction(ushort.sizeof);
        mCurrentInstruction = getInstructionData!(ushort,true)(state.PC);
    }

    void fetchInstruction(uint size)
    {
        const start = state.PC + mCurrentInstructionBuff.length;
        memory.checkRange!true(start,size);
        const buffStart = mCurrentInstructionBuff.length;
        const buffEnd = buffStart + size;
        mInstructionBuff[buffStart..buffEnd] = memory.getRawData(start,size)[0..$];
        mCurrentInstructionBuff = mInstructionBuff[0..buffEnd];
    }

pure @safe:
    @property auto ref jmpbuf() inout { return mJumpBuf; }
    @property auto currentInstruction() const { return mCurrentInstruction; }

    auto getInstructionData(T,bool Raw = false)(uint pc) const
    {
        const start = pc - state.PC;
        const end   = start + T.sizeof;
        import std.bitmanip;
        debugfOut("%x",pc);
        debugfOut("%x %x", start, end);
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
pure:
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