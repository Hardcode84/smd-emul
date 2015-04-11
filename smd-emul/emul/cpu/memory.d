module emul.cpu.memory;

import std.bitmanip;

import gamelib.debugout;

struct Memory
{
pure nothrow @nogc:
    void[] data;

    auto getValue(T)(uint offset) const
    {
        debugfOut("getVal %#.6x %s",offset,T.stringof);
        ubyte[T.sizeof] temp = (cast(const(ubyte)[])data)[offset..offset+T.sizeof];
        return bigEndianToNative!(T,T.sizeof)(temp);
    }

    void setValue(T)(uint offset, in T val)
    {
        ubyte[T.sizeof] temp = nativeToBigEndian(val);
        (cast(ubyte[])data)[offset..offset+T.sizeof] = temp;
    }

    auto getRawValue(T)(uint offset) const
    {
        assert((offset + T.sizeof) <= data.length);
        return *cast(T*)(data.ptr + offset);
    }
}

