module emul.vdp.vdpspritetable;

import gamelib.debugout;

import emul.vdp.vdpstate;
import emul.vdp.vdpmemory;

enum MaxSprites = 80;

struct VdpSprite
{
pure nothrow @nogc @safe:
    ushort x,y;
    ushort pattern;
    bool priority;
    bool vflip;
    bool hflip;
    ubyte vsize = 1,hsize = 1;
    ubyte link;
    ubyte palette;
    invariant
    {
        assert(x < 512,debugConv(x));
        assert(y < 512,debugConv(y));
        assert(vsize > 0 && vsize < 5,debugConv(vsize));
        assert(hsize > 0 && hsize < 5,debugConv(hsize));
        assert(palette < 4,debugConv(palette));
    }
    this(in ubyte[] data)
    {
        x = ((data[6] & 0b11) << 8) & data[7];
        y = ((data[0] & 0b11) << 8) & data[1];
        pattern = ((data[4] & 0b111) << 8) & data[5];
        priority = (0 != (data[4] & (1 << 7)));
        vflip = (0 != (data[4] & (1 << 4)));
        hflip = (0 != (data[4] & (1 << 3)));
        vsize = 1 + (data[2] & 0b11);
        hsize = 1 + ((data[2] & 0b1100) >> 2);
        link  = data[3] & 0x7f;
        palette = (data[4] >> 5) & 0b11;
    }
}

struct VdpSpriteTable
{
pure nothrow @nogc @safe:
    uint vramChanged = 0;
    uint vramBase = 0xffffffff;
    VdpSprite[MaxSprites] sprites;
    private int[MaxSprites] order;
    int[] currentOrder;
    void update(in ref VdpState state, in ref VdpMemory memory)
    {
        if(vramBase != state.spriteAttributeTable || vramChanged != memory.vramChanged)
        {
            //debugOut("VdpSpriteTable.update");
            vramBase = state.spriteAttributeTable;
            vramChanged = memory.vramChanged;
            foreach(i; 0..MaxSprites)
            {
                const offset = vramBase + i * 8;
                sprites[i] = VdpSprite(memory.vram[offset..offset + 8]);
            }
            int currentLink = 0;
            currentOrder = order[0..0];
            foreach(i; 0..MaxSprites)
            {
                currentOrder = order[0..i + 1];
                order[i] = currentLink;
                if( 0 == currentLink || currentLink >= MaxSprites ) break;
                currentLink = sprites[currentLink].link;
            }
            //debugOut("sprites: ",sprites);
            //debugOut("order: ",currentOrder);
        }
    }
}

