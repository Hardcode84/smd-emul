module emul.vdp.vdppattern;

import std.range;
import std.algorithm;

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
            int j = 0;
            foreach(ref pixels; line[].chunks(2))
            {
                const d = srcdata[i * 4 + j];
                pixels[0] = cast(ubyte)(p | (d & 0b1111));
                pixels[1] = cast(ubyte)(p | ((d >> 4) & 0b1111));
                ++j;
            }
        }
    }

    void getData(ubyte[] outData, int line, bool vflip, bool hflip) const
    in
    {
        assert(outData.length == 8);
        assert(line >= 0 && line < 8);
    }
    body
    {
        const srcLine = (vflip ? 7 - line : line);
        if(hflip)
        {
            foreach(i, c; data[srcLine][])
            {
                if(0 != c) outData[7 - i] = c;
            }
        }
        else
        {
            foreach(i, c; data[srcLine][])
            {
                if(0 != c) outData[i] = c;
            }
        }
    }
}

