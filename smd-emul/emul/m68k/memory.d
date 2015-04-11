module emul.m68k.memory;

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
    
    auto getValue(T)(uint offset) const
    {
        //debugfOut("getVal %#.6x %s",offset,T.stringof);
        const o = offset & AddressMask;
        checkRange!true(o,T.sizeof);
        ubyte[T.sizeof] temp = (cast(const(ubyte)[])data)[o..o+T.sizeof];
        return bigEndianToNative!(T,T.sizeof)(temp);
    }

    void setValue(T)(uint offset, in T val)
    {
        //debugfOut("setVal %#.6x %s %x",offset,T.stringof,val);
        const o = offset & AddressMask;
        checkRange!false(o,T.sizeof);
        ubyte[T.sizeof] temp = nativeToBigEndian(val);
        (cast(ubyte[])data)[o..o+T.sizeof] = temp;
    }

    auto getRawValue(T)(uint offset) const
    {
        const o = offset & AddressMask;
        checkRange!true(o,T.sizeof);
        assert((o + T.sizeof) <= data.length);
        return *cast(T*)(data.ptr + o);
    }

    void checkRange(bool Read)(uint ptr, uint size) const
    {
        const ptrEnd = (ptr + size);
        if(ptr >= 0xa00000 && ptrEnd <= 0xa14003) return;
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

