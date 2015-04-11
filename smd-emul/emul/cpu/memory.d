module emul.cpu.memory;

import std.bitmanip;

import gamelib.debugout;

struct Memory
{
pure nothrow @nogc:
    enum AddressMask = 0xffffff;
    void[] data;

    auto getValue(T)(uint offset) const
    {
        debugfOut("getVal %#.6x %s",offset,T.stringof);
        const o = offset & AddressMask;
        ubyte[T.sizeof] temp = (cast(const(ubyte)[])data)[o..o+T.sizeof];
        return bigEndianToNative!(T,T.sizeof)(temp);
    }

    void setValue(T)(uint offset, in T val)
    {
        debugfOut("setVal %#.6x %s %x",offset,T.stringof,val);
        const o = offset & AddressMask;
        ubyte[T.sizeof] temp = nativeToBigEndian(val);
        (cast(ubyte[])data)[o..o+T.sizeof] = temp;
    }

    auto getRawValue(T)(uint offset) const
    {
        const o = offset & AddressMask;
        assert((o + T.sizeof) <= data.length);
        return *cast(T*)(data.ptr + o);
    }
}

