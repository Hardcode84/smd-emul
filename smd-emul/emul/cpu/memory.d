module emul.cpu.memory;

import std.bitmanip;

struct Memory
{
pure nothrow @nogc:
    void[] data;

    auto getValue(T)(uint offset) const
    {
        ubyte[T.sizeof] temp = (cast(const(ubyte)[])data)[offset..offset+T.sizeof];
        return bigEndianToNative!(T,T.sizeof)(temp);
    }
}

