module emul.rom;

import std.string;
import std.exception;
import std.traits;
import std.bitmanip;

enum Interrupts
{
    Bus_error = 0,
    Address_error,
    Illegal_instruction,
    Divistion_by_zero,
    CHK_exception,
    TRAPV_exception,
    Privilege_violation,
    TRACE_exeption,
    LINE_1010_EMULATOR,
    LINE_1111_EMULATOR,
    Reserved_by_Motorola1,
    Reserved_by_Motorola2,
    Reserved_by_Motorola3,
    Reserved_by_Motorola4,
    Reserved_by_Motorola5,
    Reserved_by_Motorola6,
    Reserved_by_Motorola7,
    Reserved_by_Motorola8,
    Reserved_by_Motorola9,
    Reserved_by_Motorola10,
    Reserved_by_Motorola11,
    Reserved_by_Motorola12,
    Spurious_exception,
    IRQ_1,
    IRQ_2,
    IRQ_3,
    IRQ_4_Horizontal_blank,
    IRQ_5,
    IRQ_6_Vertical_blank,
    IRQ_7,
    TRAP_00_exception,
    TRAP_01_exception,
    TRAP_02_exception,
    TRAP_03_exception,
    TRAP_04_exception,
    TRAP_05_exception,
    TRAP_06_exception,
    TRAP_07_exception,
    TRAP_08_exception,
    TRAP_09_exception,
    TRAP_10_exception,
    TRAP_11_exception,
    TRAP_12_exception,
    TRAP_13_exception,
    TRAP_14_exception,
    TRAP_15_exception,
    Reserved_by_Motorola13,
    Reserved_by_Motorola14,
    Reserved_by_Motorola15,
    Reserved_by_Motorola16,
    Reserved_by_Motorola17,
    Reserved_by_Motorola18,
    Reserved_by_Motorola19,
    Reserved_by_Motorola20,
    Reserved_by_Motorola21,
    Reserved_by_Motorola22,
    Reserved_by_Motorola23,
    Reserved_by_Motorola24,
    Reserved_by_Motorola25,
    Reserved_by_Motorola26,
    Reserved_by_Motorola27,
    Reserved_by_Motorola28
}

class Rom
{
pure:
    struct Header
    {
        uint stackPointer;
        uint entryPoint;

        uint[Interrupts.max] interrupts;

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

        string toString() const pure
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
                        formattedWrite(ret, "    %s: 0x%x\n",cast(Interrupts)j,val);
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

    this(immutable(void)[] data)
    {
        mData = data;
        header = readHeader();
        //const checksum = calcChecksum();
        //enforce(header.checksum == checksum,format("Invalid checksum %x %x",checksum,header.checksum));
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
            auto ptr = 0x8 + i * uint.sizeof;
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

    /*ushort calcChecksum() nothrow
    {
        ushort result = 0;
        foreach(i;0x200..header.romEndAddress)
        {
            result += (cast(ubyte[])mData)[i];
        }
        return cast(ushort)(result & 0xffff);
    }*/

private:
    immutable(void)[] mData;
}

