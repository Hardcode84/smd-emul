module emul.vdp.vdpspritetable;

import std.range;
import std.algorithm;

import gamelib.debugout;

import emul.vdp.vdpstate;
import emul.vdp.vdpmemory;
import emul.vdp.vdppattern;

enum MaxSprites = 80;

struct VdpSpriteTable
{
pure nothrow @nogc @safe:
    struct VdpSprite
    {
        pure nothrow @nogc @safe:
        ushort x,y;
        Priotity priority;
        bool vflip;
        bool hflip;
        ubyte vsize;
        ubyte hsize;
        ubyte link;
        ubyte palette;
        VdpPattern[4*4] patterns = void;

        this(in ref VdpMemory memory, uint offset)
        {
            const ubyte[] data = memory.getVramRange(offset, 8);
            x = ((data[6] & 0b11) << 8) | data[7];
            y = ((data[0] & 0b11) << 8) | data[1];
            const pattern = (((data[4] & 0b111) << 8) | data[5]) << 5;
            priority = (0 != (data[4] & (1 << 7)) ? Priotity.High : Priotity.Low);
            vflip = (0 != (data[4] & (1 << 4)));
            hflip = (0 != (data[4] & (1 << 3)));
            vsize = 1 + (data[2] & 0b11);
            hsize = 1 + ((data[2] & 0b1100) >> 2);
            link  = data[3] & 0x7f;
            palette = (data[4] >> 5) & 0b11;
            assert(x < 512,debugConv(x));
            assert(y < 512,debugConv(y));
            assert(vsize > 0 && vsize < 5,debugConv(vsize));
            assert(hsize > 0 && hsize < 5,debugConv(hsize));
            assert(palette < 4,debugConv(palette));
            foreach(i;0..(hsize * vsize))
            {
                const patOffset = pattern + i * 32;
                patterns[i] = VdpPattern(memory.getVramRange(patOffset, 32),palette);
            }
        }

        void getData(ubyte[] outData, int xpat, int ypat, int line, int start, int end) const
        in
        {
            assert(xpat >= 0 && xpat < hsize,debugConv(xpat));
            assert(ypat >= 0 && ypat < vsize,debugConv(ypat));
        }
        body
        {
            if(vflip) ypat = vsize - ypat - 1;
            if(hflip) xpat = hsize - xpat - 1;
            patterns[ypat + vsize * xpat].getData(outData, line, vflip, hflip, start, end);
        }
    }

    enum Priotity
    {
        Low,
        High
    }

    void update(in ref VdpState state, in ref VdpMemory memory)
    {
        if(vramBase != state.spriteAttributeTable || vramChanged != memory.vramChanged)
        {
            vramBase = state.spriteAttributeTable;
            vramChanged = memory.vramChanged;
            foreach(i; 0..MaxSprites)
            {
                const offset = vramBase + i * 8;
                sprites[i] = VdpSprite(memory, offset);
            }
            int currentLink = 0;
            currentOrder = order[0..0];
            foreach(i; 0..MaxSprites)
            {
                currentOrder = order[0..i + 1];
                order[i] = currentLink;
                currentLink = sprites[currentLink].link;
                if(0 == currentLink || currentLink >= MaxSprites) break;
            }
        }
    }

    void drawSprites(Priotity pri)(ubyte[] outData, in ref VdpState state, in ref VdpMemory memory, int line) const
    {
        void drawSprite(Priotity pri)(
            ubyte[] outData, in ref VdpSprite sprite, in ref VdpState state, in ref VdpMemory memory, int line) const
        {
            if(sprite.priority == pri)
            {
                const xstart = sprite.x - 128;
                const xend = xstart + sprite.hsize * 8;
                if(xstart >= outData.length || xend <= 0) return;
                const ystart = sprite.y - 128;
                const yend = ystart + sprite.vsize * 8;
                if(ystart > line || yend <= line) return;
                const row = (line - ystart) / 8;
                const patLine = (line - ystart) % 8;
                int currxstart = xstart;
                foreach(i;0..sprite.hsize)
                {
                    const currxend = currxstart + 8;
                    const start = (currxstart >= 0 ? 0 : -currxstart);
                    const end = (currxend <= outData.length ? 8 : 8 - (currxend - outData.length));
                    if(end > start)
                    {
                        sprite.getData(outData[max(0,currxstart)..min(outData.length,currxend)],i,row,patLine,start,end);
                    }
                    currxstart += 8;
                    if(currxstart >= outData.length) break;
                }
            }
        }

        foreach(i;currentOrder[].retro)
        {
            drawSprite!pri(outData, sprites[i], state, memory, line);
        }
    }

private:
    uint vramChanged = 0;
    uint vramBase = 0xffffffff;
    VdpSprite[MaxSprites] sprites;
    int[MaxSprites] order;
    int[] currentOrder;
}

