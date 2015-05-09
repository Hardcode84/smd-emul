module emul.vdp.vdpmemory;

struct VdpMemory
{
pure nothrow @nogc @safe:
    uint cramChanged = 1;
    uint vsRamChanged = 1;
    uint vramChanged = 1;
    ushort[64] cram;
    ushort[40] vsram;
    ubyte[0x10000] vram;

    void writeVram(uint address, ubyte value)
    {
        ++vramChanged;
        vram[address & 0xffff] = value;
    }
    void writeVram(uint address, ushort value)
    {
        const swapBytes = (0x0 != (address & 0x1));
        const addr = address & 0xfffe;
        if(swapBytes)
        {
            vram[addr + 0] = cast(ubyte)(value);
            vram[addr + 1] = cast(ubyte)(value >> 8);
        }
        else
        {
            vram[addr + 0] = cast(ubyte)(value >> 8);
            vram[addr + 1] = cast(ubyte)(value);
        }
        ++vramChanged;
    }
    void writeCram(uint address, ushort value)
    {
        ++cramChanged;
        cram[(address >> 1) & 0b111_111] = value;
    }
    void writeVsram(uint address, ushort value)
    {
        const addr = (address >> 1) & 0b111_111;
        if(addr < vsram.length)
        {
            ++vsRamChanged;
            cram[addr] = value;
        }
    }
}