module emul.vdp.vdplayers;

import gamelib.debugout;
import gamelib.math;

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
        this(in ref VdpMemory memory,uint address)
        {
            const data = memory.readVram!ushort(address);
            priority = (0 != (data & (1 << 15))) ? Priotity.High : Priotity.Low;
            palette = ((data >> 13) & 0b11);
            vflip = (0 != (data & (1 << 12)));
            hflip = (0 != (data & (1 << 11)));
            const patternAddress = (data << 5) & 0xffff;
            pattern = VdpPattern(memory.getVramRange(patternAddress, 32),palette);
        }

        void getData(ubyte[] outData, int line, int start, int end) const
        {
            pattern.getData(outData, line, vflip, hflip, start, end);
        }
    }

    int vramchanged = 0;
    int width, height;
    bool wideWindow;
    uint planeAbase = 0xffffffff;
    uint planeBbase = 0xffffffff;
    uint windowBase = 0xffffffff;

    Cell[64*64][2] planes;
    Cell[32*64] windowPlane;

    void update(in ref VdpState state, in ref VdpMemory memory)
    {
        if(planeAbase  != state.patternNameTableLayerA ||
           planeBbase  != state.patternnameTableLayerB ||
           windowBase  != state.patternNameTableWindow ||
           width       != state.layerWidth ||
           height      != state.layerHeight ||
           wideWindow  != (state.CellWidth > 32) ||
           vramchanged != memory.vramChanged)
        {
            planeAbase = state.patternNameTableLayerA;
            planeBbase = state.patternnameTableLayerB;
            windowBase = state.patternNameTableWindow;
            width = state.layerWidth;
            height = state.layerHeight;
            wideWindow = state.CellWidth > 32;
            assert(ispow2(width),  debugConv(width));
            assert(ispow2(height), debugConv(height));
            vramchanged = memory.vramChanged;
            foreach(i; 0..height)
            {
                foreach(j; 0..width)
                {
                    const offset = i * width + j;
                    planes[Plane.A][offset] = Cell(memory, planeAbase + offset * cast(uint)ushort.sizeof);
                    planes[Plane.B][offset] = Cell(memory, planeBbase + offset * cast(uint)ushort.sizeof);
                }
            }
            foreach(offset; 0..(state.CellHeight * (wideWindow ? 64 : 32)))
            {
                windowPlane[offset] = Cell(memory, windowBase + offset * cast(uint)ushort.sizeof);
            }
        }
    }

    void drawPlanes(Priotity pri)(ubyte[] outData, in ref VdpState state, in ref VdpMemory memory, int line) const
    {
        const hscroll = getHScrollValue(state, memory, line);
        import std.typetuple;
        foreach(i;TypeTuple!(Plane.B, Plane.A))
        {
            drawPlane!(pri,i)(outData, hscroll[i], state, memory, line);
        }
    }

private:
    static bool checkWindow(in ref VdpState state, int cell, int line)
    in
    {
        assert(cell >= 0);
        assert(line >= 0);
    }
    body
    {
        if(!state.windowEnabled)
        {
            return false;
        }

        if(state.windowIsDown)
        {
            if(line < (8 * state.windowVPos)) return false;
        }
        else
        {
            if(line >= (8 * state.windowVPos)) return false;
        }

        if(state.windowIsRight)
        {
            if(cell < (2 * state.windowHPos)) return false;
        }
        else
        {
            if(cell >= (2 * state.windowHPos)) return false;
        }
        return true;
    }

    void drawPlane(Priotity pri,Plane pla)(
                ubyte[] outData,
                in int hscroll,
                in ref VdpState state,
                in ref VdpMemory memory,
                int line) const
    {
        foreach(cell;0..(cast(uint)outData.length / 8))
        {
            if(pla == Plane.A && checkWindow(state, cell, line))
            {
                const start = cell * 8;
                const end   = start + 8;
                if(end > start)
                {
                    getWindowCellData!pri(outData[start..end], state, memory, cell, line);
                }
            }
            else
            {
                static if(pla == Plane.A)
                {
                    if(!state.planeAVisible) return;
                }
                else
                {
                    if(!state.planeBVisible) return;
                }
                const start = cell * 8;
                const wmask = (width * 8 - 1);
                const begin1 = (start - hscroll) & wmask;
                const beginCell1 = (begin1 / 8);
                const offset1 = (begin1 % 8);
                const len1 = 8 - offset1;
                const begin2 = (begin1 + 8) & wmask;
                const beginCell2 = (begin2 / 8);
                const len2 = 8 - len1;
                const center = start + len1;
                const end = start + 8;
                if(center > start)
                {
                    getCellData!pri(outData[start..center], state, memory, line, cell, beginCell1, pla, offset1, offset1 + len1);
                }
                if(end > center)
                {
                    getCellData!pri(outData[center..end],   state, memory, line, cell, beginCell2, pla, 0, len2);
                }
            }
        }
    }

    int[2] getHScrollValue(in ref VdpState state, in ref VdpMemory memory, int line) const
    in
    {
        assert(line >= 0);
    }
    body
    {
        uint offset = void;
        final switch(state.hscrollMode)
        {
            case HScrollMode.FullScreen:
                offset = state.hScrollTableAddress;
                break;
            case HScrollMode.FirstEightLines:
                offset = state.hScrollTableAddress + (line & 0b111) * cast(uint)short.sizeof * 2;
                break;
            case HScrollMode.EveryRow:
                offset = state.hScrollTableAddress + (line & ~0b111) * cast(uint)short.sizeof * 2;
                break;
            case HScrollMode.EveryLine:
                offset = state.hScrollTableAddress + line * cast(uint)short.sizeof * 2;
                break;
        }
        int[2] ret = void;
        ret[Plane.A] = memory.readVram!short(offset + Plane.A * cast(uint)short.sizeof) & 0x3ff;
        ret[Plane.B] = memory.readVram!short(offset + Plane.B * cast(uint)short.sizeof) & 0x3ff;
        return ret;
    }

    int getVScrollValue(in ref VdpState state, in ref VdpMemory memory, int cell, Plane plane) const
    in
    {
        assert(cell >= 0);
    }
    body
    {
        final switch(state.vscrollMode)
        {
            case VScrollMode.FullScreen:
                return memory.readVsram(plane);
            case VScrollMode.TwoCell:
                return memory.readVsram(plane + cell / 2);
        }
        assert(false);
    }

    void getCellData(Priotity pri)(
        ubyte[] data,
        in ref VdpState state,
        in ref VdpMemory memory,
        int line,
        int visCell, int cell, Plane plane, int start = 0, int end = 8) const
    in
    {
        assert(data.length == (end - start));
        assert(line >= 0);
        assert(cell >= 0);
    }
    body
    {
        const xcell = cell % width;
        const vscroll = getVScrollValue(state, memory, visCell, plane);
        const y = line + vscroll;
        const ycell = (y / 8) % height;
        const srcCell = xcell + ycell * width;
        if(planes[plane][srcCell].priority != pri)
        {
            return;
        }
        const ypat = y % 8;
        planes[plane][srcCell].getData(data,ypat,start,end);
    }

    void getWindowCellData(Priotity pri)(
        ubyte[] data,
        in ref VdpState state,
        in ref VdpMemory memory,
        int cell,
        int line) const
    in
    {
        assert(line >= 0);
        assert(cell >= 0);
    }
    body
    {
        const ycell = line / 8;
        const srcCell = cell + ycell * state.CellWidth;
        if(windowPlane[srcCell].priority != pri)
        {
            return;
        }
        windowPlane[srcCell].getData(data, line % 8, 0, 8);
    }
}

