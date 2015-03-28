module emul.rom;

import std.string;
import std.exception;
import std.traits;
import std.bitmanip;

class Rom
{
pure:
    struct Header
    {
        string consoleName;
        string copyright;
        string domesticGameName;
        string overseasGameName;
        string productType;
        string productVersion;
        short checkSum;
        string ioSupport;
        uint romStartAddress;
        uint romEndAddress;
    }

    this(immutable(void)[] data)
    {
        mData = data;
        header = readHeader();
    }

    immutable Header header;

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
        return bigEndianToNative!(T,T.sizeof)(cast(ubyte[T.sizeof])mData[offset..offset+T.sizeof]);
    }
    Header readHeader()
    {
        Header h;
        h.consoleName      = readString(0x100,0x10);
        h.copyright        = readString(0x110,0x10);
        h.domesticGameName = readString(0x120,0x30);
        h.overseasGameName = readString(0x150,0x30);
        h.productType      = readString(0x180,0x2);
        h.productVersion   = readString(0x182,0xc);
        h.checkSum         = readValue!short(0x18e);
        h.ioSupport        = readString(0x190,0x10);
        h.romStartAddress  = readValue!uint(0x1a0);
        h.romEndAddress    = readValue!uint(0x1a4);
        return h;
    }

private:
    immutable(void)[] mData;
}

