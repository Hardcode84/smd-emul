module emul.rom;

import std.string;
import std.exception;
import std.traits;
import std.bitmanip;

import gamelib.memory.saferef;

import emul.m68k.cpu;

class Rom
{
pure:
    struct Header
    {
    pure @safe:
        uint[ExceptionCodes.max + 1] interrupts;

        @property auto ref stackPointer() @nogc nothrow inout { return interrupts[ExceptionCodes.Start_stack_address]; }
        @property auto ref entryPoint()   @nogc nothrow inout { return interrupts[ExceptionCodes.Start_code_address]; }

        string consoleName;
        string copyright;
        string domesticGameName;
        string overseasGameName;
        string productType;
        string productVersion;
        ushort checksum;
        string ioSupport;
        uint romStartAddress;
        uint romEndAddress;
        uint ramStartAddress;
        uint ramEndAddress;

        string toString() const
        {
            import std.array: appender;
            import std.format: formattedWrite;
            auto ret = appender!(char[])();
            foreach(i,ref v; this.tupleof)
            {
                enum fieldName = this.tupleof[i].stringof["this*".length..$];
                static if(this.tupleof[i].offsetof == interrupts.offsetof)
                {
                    formattedWrite(ret, fieldName~":\n");
                    foreach(j,val; v)
                    {
                        formattedWrite(ret, "    %s: 0x%x\n",cast(ExceptionCodes)j,val);
                    }
                }
                else static if(isIntegral!(typeof(v)))
                {
                    formattedWrite(ret, fieldName~": 0x%x\n", v);
                }
                else static if(isSomeString!(typeof(v)))
                {
                    formattedWrite(ret, fieldName~": \"%s\"\n", v);
                }
                else
                {
                    formattedWrite(ret, fieldName~": %s\n", v);
                }
            }
            return ret.data;
        }
    }

    this(immutable void[] data)
    {
        mData = data;
        header = readHeader();
    }

    immutable Header header;
    @property auto data() const { return mData; }

private:
const:
    void checkRange(uint offset, uint size)
    {
        enforce(offset < mData.length && (offset + size) <= mData.length,
            format("Invalid read: 0x%x-0x%x of 0x0-0x%x",offset,offset+size,mData.length));
    }
    string readString(uint offset, uint size)
    {
        checkRange(offset,size);
        return cast(string)mData[offset..offset+size];
    }
    auto readValue(T)(uint offset)
    {
        checkRange(offset,T.sizeof);
        ubyte[T.sizeof] data = (cast(immutable(ubyte)[])mData)[offset..offset+T.sizeof];
        return bigEndianToNative!(T,T.sizeof)(data);
    }
    auto readPtr(uint offset)
    {
        return readValue!uint(offset);
    }
    Header readHeader()
    {
        Header h;
        h.stackPointer     = readPtr(0x000);
        h.entryPoint       = readPtr(0x004);
        foreach(i,ref v; h.interrupts)
        {
            auto ptr = cast(uint)(i * uint.sizeof);
            assert(ptr < 0x100);
            v = readPtr(ptr);
        }
        h.consoleName      = readString(0x100,0x10);
        h.copyright        = readString(0x110,0x10);
        h.domesticGameName = readString(0x120,0x30);
        h.overseasGameName = readString(0x150,0x30);
        h.productType      = readString(0x180,0x2);
        h.productVersion   = readString(0x182,0xc);
        h.checksum         = readValue!ushort(0x18e);
        h.ioSupport        = readString(0x190,0x10);
        h.romStartAddress  = readPtr(0x1a0);
        h.romEndAddress    = readPtr(0x1a4);
        h.ramStartAddress  = readPtr(0x1a8);
        h.ramEndAddress    = readPtr(0x1ac);
        return h;
    }

private:
    immutable void[] mData;
}

alias RomRef = SafeRef!Rom;

enum RomFormat
{
    BIN,
    MD,
}

RomRef createRom(in RomFormat format, in immutable(void)[] data) pure
{
    immutable(void)[] decoded;
    final switch(format)
    {
        case RomFormat.BIN:
            decoded = data;
            break;
        case RomFormat.MD:
            decoded = decodeMD(data);
            break;
    }
    return makeSafe!Rom(decoded);
}

RomRef createRom(in RomFormat format, in void[] data) pure
{
    immutable(void)[] decoded;
    final switch(format)
    {
        case RomFormat.BIN:
            decoded = data.idup;
            break;
        case RomFormat.MD:
            decoded = decodeMD(data);
            break;
    }
    return makeSafe!Rom(decoded);
}

private auto decodeMD(in void[] data) pure nothrow
{
    ubyte[] ret;
    const size = data.length;
    const middle = size / 2;
    ret.length = size;
    foreach(i, b; (cast(const ubyte[])data)[])
    {
        if(i <= middle)
        {
            ret[i * 2] = b;
        }
        else
        {
            ret[i * 2 - size - 1] = b;
        }
    }
    return cast(immutable(void)[])ret;
}