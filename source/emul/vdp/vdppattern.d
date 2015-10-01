module emul.vdp.vdppattern;

import std.range;
import std.algorithm;

import gamelib.debugout;

struct VdpPattern
{
pure nothrow @nogc @safe:
    ubyte[8][8] data;
    this(in ubyte[] srcdata, ubyte palette)
    in
    {
        assert(srcdata.length == 32);
        assert(palette < 4);
    }
    body
    {
        const p = palette << 4;
        foreach(i, ref line; data[])
        {
            foreach(j; 0..4)
            {
                const d = srcdata[i * 4 + j];
                line[j * 2 + 1] = cast(ubyte)(p | (d & 0b1111));
                line[j * 2 + 0] = cast(ubyte)(p | ((d >> 4) & 0b1111));
            }
        }
    }

    void getData(ubyte[] outData, int line, bool vflip, bool hflip, int start = 0, int end = 8) const
    in
    {
        assert(outData.length > 0);
        assert(start >= 0,debugConv(start));
        assert(end <= 8,debugConv(end));
        assert(end >= start);
        assert(outData.length == (end - start));
        assert(line >= 0 && line < 8);
    }
    body
    {
        const srcLine = (vflip ? 7 - line : line);
        if(hflip)
        {
            const nstart = 8 - end;
            const mend   = 8 - start;
            foreach(i, c; data[srcLine][nstart..mend])
            {
                const ind = end - start - 1 - i;
                assert(ind >= 0);
                assert(ind < outData.length);
                if(0 != c) outData[ind] = c;
            }
        }
        else
        {
            foreach(i, c; data[srcLine][start..end])
            {
                if(0 != c) outData[i] = c;
            }
        }
    }
}

