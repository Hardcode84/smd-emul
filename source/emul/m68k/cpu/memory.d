module emul.m68k.cpu.memory;

import std.bitmanip;

import gamelib.debugout;

struct Memory
{
pure nothrow @nogc:
    enum AddressMask = 0xffffff;
    void[] data;
    uint romStartAddress;
    uint romEndAddress;
    uint ramStartAddress;
    uint ramEndAddress;

package:
    auto getValue(T)(uint offset) const
    {
        if(offset == 0xa11100) return cast(T)0; // TODO
        const o = offset & AddressMask;
        assert((o + T.sizeof) <= data.length);
        ubyte[T.sizeof] temp = (cast(const(ubyte)[])data)[o..o+T.sizeof];
        return bigEndianToNative!(T,T.sizeof)(temp);
    }

    void setValue(T)(uint offset, in T val)
    {
        const o = offset & AddressMask;
        assert((o + T.sizeof) <= data.length);
        ubyte[T.sizeof] temp = nativeToBigEndian(val);
        (cast(ubyte[])data)[o..o+T.sizeof] = temp;
    }

    auto getRawValue(T)(uint offset) const
    {
        const o = offset & AddressMask;
        assert((o + T.sizeof) <= data.length);
        return *cast(T*)(data.ptr + o);
    }

    void checkRange(bool Read)(uint ptr, uint size) const
    {
        const ptrStart = ptr & AddressMask;
        const ptrEnd = (ptr + size - 1) & AddressMask;
        if(ptr >= 0xa00000 && ptrEnd <= 0xa14003) return;
        if(ptr >= 0xc00011 && ptrEnd <= 0xc00011) return;
        static if(Read)
        {
            if((ptr < romStartAddress || ptrEnd > romEndAddress) &&
               (ptr < ramStartAddress || ptrEnd > ramEndAddress))
            {
                debugfOut("invalid read access: %#.8x %x",ptr,size);
                assert(false); // TODO
            }
        }
        else
        {
            if(ptr < ramStartAddress || ptrEnd > ramEndAddress)
            {
                debugfOut("invalid write access: %#.8x %x",ptr,size);
                assert(false); // TODO
            }
        }
    }
}

