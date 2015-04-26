module emul.vdp.vdpmemory;

struct VdpMemory
{
pure nothrow @nogc @safe:
    ushort[64] cram;
    ushort[40] vsram;
    ubyte[0x10000] vram;

    void writeVram(uint address, ubyte value)
    {
        vram[address & 0xffff] = value;
    }
    void writeCram(uint address, ushort value)
    {
        cram[(address >> 1) & 0b111_111] = value;
    }
    void writeVsram(uint address, ushort value)
    {
        const addr = (address >> 1) & 0b111_111;
        if(addr < vsram.length)
        {
            cram[addr] = value;
        }
    }
}

