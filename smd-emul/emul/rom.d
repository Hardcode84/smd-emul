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
    }

private:
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
        return bigEndianToNative!T(mData[offset..offset+T.sizeof]);
    }

private:
    immutable(void)[] mData;
}

