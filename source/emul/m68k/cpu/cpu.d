module emul.m68k.cpu.cpu;

import std.typecons;
import std.algorithm;
import std.range;

import emul.m68k.cpu.cpustate;
import emul.m68k.cpu.memory;

import gamelib.memory.saferef;

struct Cpu
{
    CpuState state;
    Memory memory;

    alias MemReadHook  = uint delegate(CpuPtr,uint,size_t) pure nothrow @nogc;
    alias MemWriteHook = void delegate(CpuPtr,uint,size_t,uint) pure nothrow @nogc;

    void addReadHook(MemReadHook hook, uint begin, uint end)
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

    void addWriteHook(MemWriteHook hook, uint begin, uint end)
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

    pure nothrow @nogc
    {
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

        auto getMemValueNoHook(T)(uint offset) @safe
        {
            memory.checkRange!true(offset,T.sizeof);
            return memory.getValue!T(offset);
        }

        auto getRawMemValue(T)(uint offset) const
        {
            memory.checkRange!true(offset,T.sizeof);
            return memory.getRawValue!T(offset);
        }
    }

private:
    alias ReadHookTuple  = Tuple!(uint, "begin", uint, "end", MemReadHook,  "hook");
    alias WriteHookTuple = Tuple!(uint, "begin", uint, "end", MemWriteHook, "hook");
    ReadHookTuple[]  mReadHooks;
    WriteHookTuple[] mWriteHooks;
    auto mReadHooksRange  = tuple(0xffffffff,0x0);
    auto mWriteHooksRange = tuple(0xffffffff,0x0);

    static void checkHooksRange(T)(in T[] hooks)
    {
        if(zip(hooks,hooks.dropOne).canFind!(a => (a[0].end >= a[1].begin)))
        {
            assert(false, "Overlapping hooks");
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