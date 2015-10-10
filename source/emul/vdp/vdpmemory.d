module emul.vdp.vdpmemory;

import std.bitmanip;

struct VdpMemory
{
pure nothrow @nogc @safe:
    enum VramSize = 0x10000;
    enum CramSize = 64;
    enum VsRamSize = 40;
    void writeVram(uint address, ubyte value)
    {
        ++mVramChanged;
        vram[address & (VramSize - 1)] = value;
        vramTail[address & (VramSize - 1)] = value;
    }
    void writeVram(uint address, ushort value)
    {
        const swapBytes = (0x0 != (address & 0x1));
        const addr = address & (VramSize - 2);
        ++mVramChanged;
        if(swapBytes)
        {
            vram[addr + 0] = cast(ubyte)(value);
            vram[addr + 1] = cast(ubyte)(value >> 8);
            vramTail[addr + 0] = cast(ubyte)(value);
            vramTail[addr + 1] = cast(ubyte)(value >> 8);
        }
        else
        {
            vram[addr + 0] = cast(ubyte)(value >> 8);
            vram[addr + 1] = cast(ubyte)(value);
            vramTail[addr + 0] = cast(ubyte)(value >> 8);
            vramTail[addr + 1] = cast(ubyte)(value);
        }
    }

    void writeCram(uint address, ushort value)
    {
        ++mCramChanged;
        cram[(address >> 1) & 0b111_111] = value;
    }

    void writeVsram(uint address, ushort value)
    {
        const addr = (address >> 1) & 0b111_111;
        if(addr < vsram.length)
        {
            ++mVsRamChanged;
            vsram[addr] = value;
        }
    }

    auto readVram(T)(uint address) const
    in
    {
        assert(0 == (address % T.sizeof));
    }
    body
    {
        const addr = address & 0xffff;
        const ubyte[T.sizeof] temp = vram[addr..addr + T.sizeof];
        return bigEndianToNative!(T,T.sizeof)(temp);
    }

    const(ubyte)[] getVramRange(uint address, uint size) const
    in
    {
        assert(size <= VramSize);
    }
    body
    {
        const start = address & (VramSize - 1);
        const end = start + size;
        return vramDouble[start..end];
    }

    auto readCram(uint address) const
    in
    {
        assert(address < cram.length);
    }
    body
    {
        return cram[address];
    }

    auto readVsram(uint address) const
    in
    {
        assert(address < vsram.length);
    }
    body
    {
        return vsram[address] & 0x7ff;
    }

    @property const
    {
        auto cramChanged()  { return mCramChanged; }
        auto vsRamChanged() { return mVsRamChanged; }
        auto vramChanged()  { return mVramChanged; }
    }

private:
    uint mCramChanged = 1;
    uint mVsRamChanged = 1;
    uint mVramChanged = 1;
    ushort[CramSize] cram;
    ushort[VsRamSize] vsram;
    union
    {
        struct
        {
            ubyte[VramSize] vram;
            ubyte[VramSize] vramTail;
        }
        ubyte[VramSize * 2] vramDouble;
    }
}