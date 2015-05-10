module emul.vdp.vdplayers;

import gamelib.debugout;

import emul.vdp.vdpstate;
import emul.vdp.vdpmemory;
import emul.vdp.vdppattern;

struct VdpLayers
{
pure nothrow @nogc @safe:
    struct Cell
    {
    pure nothrow @nogc @safe:
        bool priority;
        ubyte palette;
        bool vflip;
        bool hflip;
        VdpPattern pattern;
        this(in uint address, in ref VdpMemory memory)
        {
            const data = memory.readVram!ushort(address);
            priority = (0 != (data & (1 << 15)));
            palette = ((data >> 13) & 0b11);
            vflip = (0 != (data & (1 << 12)));
            hflip = (0 != (data & (1 << 11)));
            const patternAddress = (data << 5);
            pattern = VdpPattern(memory.vram[patternAddress..patternAddress + 32]);
        }
    }

    int vramchanged = 0;
    int width, height;
    uint planeAbase = 0xffffffff;
    uint planeBbase = 0xffffffff;

    Cell[64*64] planeA;
    Cell[64*64] planeB;

    void update(in ref VdpState state, in ref VdpMemory memory)
    {
        if(planeAbase != state.patternNameTableLayerA ||
           planeBbase != state.patternnameTableLayerB ||
           width != state.layerWidth ||
           height != state.layerHeight ||
           vramchanged != memory.vramChanged)
        {
            debugOut("VdpLayers.update");
            planeAbase = state.patternNameTableLayerA;
            planeBbase = state.patternnameTableLayerB;
            width = state.layerWidth;
            height = state.layerHeight;
            vramchanged = memory.vramChanged;
            foreach(i; 0..height)
            {
                foreach(j; 0..width)
                {
                    const offset = i * width + j;
                    planeA[offset] = Cell(planeAbase + offset * ushort.sizeof, memory);
                    planeB[offset] = Cell(planeBbase + offset * ushort.sizeof, memory);
                }
            }
        }
    }
}

