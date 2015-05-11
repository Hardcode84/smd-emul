module emul.vdp.vdplayers;

import gamelib.debugout;

import emul.vdp.vdpstate;
import emul.vdp.vdpmemory;
import emul.vdp.vdppattern;

struct VdpLayers
{
pure nothrow @nogc @safe:
    enum Priotity
    {
        Low,
        High
    }
    
    enum Plane
    {
        A = 0,
        B = 1
    }

    struct Cell
    {
    pure nothrow @nogc @safe:
        Priotity priority;
        ubyte palette;
        bool vflip;
        bool hflip;
        VdpPattern pattern;
        this(in uint address, in ref VdpMemory memory)
        {
            const data = memory.readVram!ushort(address);
            priority = (0 != (data & (1 << 15))) ? Priotity.High : Priotity.Low;
            palette = ((data >> 13) & 0b11);
            vflip = (0 != (data & (1 << 12)));
            hflip = (0 != (data & (1 << 11)));
            const patternAddress = (data << 5);
            pattern = VdpPattern(memory.vram[patternAddress..patternAddress + 32],palette);
        }

        void getData(ubyte[] outData, int line) const
        in
        {
            assert(outData.length == 8);
            assert(line >= 0 && line < 8);
        }
        body
        {
            pattern.getData(outData, line, vflip, hflip);
        }
    }

    int vramchanged = 0;
    int width, height;
    uint planeAbase = 0xffffffff;
    uint planeBbase = 0xffffffff;

    Cell[64*64][2] planes;

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
                    planes[Plane.A][offset] = Cell(planeAbase + offset * ushort.sizeof, memory);
                    planes[Plane.B][offset] = Cell(planeBbase + offset * ushort.sizeof, memory);
                }
            }
        }
    }

    void drawPlanes(Priotity pri)(in ref VdpState state, in ref VdpMemory memory, int line, ubyte[] outData) const
    {
        const hscroll = getHScrollValue(state, memory, line);
        foreach(i, const ref plane; planes[])
        {
            const begin = hscroll[i];
            const end = begin + outData.length;
            const beginCell = begin / 8;
            const endCell = end / 8;
            //special case for the 1st cell
            ubyte[8] temp = void;
            getCellData(temp[], state, memory, line, beginCell, i);
            const outBegin = begin % 8;
            const len = 8 - outBegin;
            outData[0..len] == temp[outBegin..$];
            int currPos = len;
            foreach(j; (beginCell + 1)..(endCell - 1))
            {
                getCellData(outData[currPos..currPos + 8], state, memory, line, j, i);
                currPos += 8;
            }
            //special case for the last cell
            getCellData(temp[], state, memory, line, endCell - 1, i);
            const remLen = outData.length - currPos;
            outData[currPos..$] = temp[0..remLen];
        }
    }

    private int[2] getHScrollValue(in ref VdpState state, in ref VdpMemory memory, int line) const
    in
    {
        assert(line >= 0);
    }
    body
    {
        size_t offset = void;
        final switch(state.hscrollMode)
        {
            case HScrollMode.FullScreen:
                offset = state.hScrollTableAddress;
                break;
            case HScrollMode.FirstEightLines:
                offset = state.hScrollTableAddress + (line & 0b111) * short.sizeof * 2;
                break;
            case HScrollMode.EveryRow:
                offset = state.hScrollTableAddress + (line & ~0b111) * short.sizeof * 2;
                break;
            case HScrollMode.EveryLine:
                offset = state.hScrollTableAddress + line * short.sizeof * 2;
                break;
        }
        int[2] ret = void;
        ret[Plane.A] = memory.readVram!short(offset + Plane.A * short.sizeof) & 0x3ff;
        ret[Plane.B] = memory.readVram!short(offset + Plane.B * short.sizeof) & 0x3ff;
        return ret;
    }

    private int getVScrollValue(in ref VdpState state, in ref VdpMemory memory, int cell, Plane plane) const
    in
    {
        assert(cell >= 0);
    }
    body
    {
        final switch(state.vscrollMode)
        {
            case VScrollMode.FullScreen:
                return memory.vsram[plane] & 0x7ff;
            case VScrollMode.TwoCell:
                return memory.vsram[plane + cell & ~0x1] & 0x7ff;
        }
        assert(false);
    }

    void getCellData(ubyte[] data, in ref VdpState state, in ref VdpMemory memory, int line, int cell, Plane plane) const
    in
    {
        assert(data.length == 8);
        assert(line >= 0);
        assert(cell >= 0);
    }
    body
    {
        const xcell = cell % width;
        const vscroll = getVScrollValue(state, memory, cell, plane);
        const y = line + vscroll;
        const ycell = (y / 8) % height;
        const ypat = y % 8;
        planes[plane][xcell + ycell * width].getData(data,ypat);
    }
}

