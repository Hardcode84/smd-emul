module emul.vdp.vdppattern;

import std.range;

struct VdpPattern
{
pure nothrow @nogc @safe:
    ubyte[8][8] data;
    this(in ubyte[] srcdata)
    in
    {
        assert(srcdata.length == 32);
    }
    body
    {
        foreach(i, ref line; data[])
        {
            int j = 0;
            foreach(ref pixels; line[].chunks(2))
            {
                const d = srcdata[i * 4 + j];
                pixels[0] = cast(ubyte)(d & 0b1111);
                pixels[1] = cast(ubyte)((d >> 4) & 0b1111);
                ++j;
            }
        }
    }
}

