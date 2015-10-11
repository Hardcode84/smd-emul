﻿module emul.m68k.tests.testscc;

unittest
{
    import std.stdio;
    import emul.m68k.tests.testcore;
    writeln("test scc");
    auto core = makeSafe!TestCore();

    //scc
    foreach(a;results[])
    {
        core.reset(0x200,0xffffff);
        core.cpu.state.CCR = cast(ubyte)a[0];
        core.cpu.memory.setValueUnchecked!ushort(0x200,cast(ushort)a[1]);
        core.run(1);
        assert(a[2] == core.cpu.state.D[0]);
        assert((a[3] & 0xff) == (core.cpu.state.SR & 0xff));
    }
}

version(unittest)
{

immutable uint[4][] results = [
    [0x0,0x50C0,0xFF,0x2000],
    [0x0,0x51C0,0x0,0x2000],
    [0x0,0x52C0,0xFF,0x2000],
    [0x0,0x53C0,0x0,0x2000],
    [0x0,0x54C0,0xFF,0x2000],
    [0x0,0x55C0,0x0,0x2000],
    [0x0,0x56C0,0xFF,0x2000],
    [0x0,0x57C0,0x0,0x2000],
    [0x0,0x58C0,0xFF,0x2000],
    [0x0,0x59C0,0x0,0x2000],
    [0x0,0x5AC0,0xFF,0x2000],
    [0x0,0x5BC0,0x0,0x2000],
    [0x0,0x5CC0,0xFF,0x2000],
    [0x0,0x5DC0,0x0,0x2000],
    [0x0,0x5EC0,0xFF,0x2000],
    [0x0,0x5FC0,0x0,0x2000],
    [0x1,0x50C0,0xFF,0x2001],
    [0x1,0x51C0,0x0,0x2001],
    [0x1,0x52C0,0x0,0x2001],
    [0x1,0x53C0,0xFF,0x2001],
    [0x1,0x54C0,0x0,0x2001],
    [0x1,0x55C0,0xFF,0x2001],
    [0x1,0x56C0,0xFF,0x2001],
    [0x1,0x57C0,0x0,0x2001],
    [0x1,0x58C0,0xFF,0x2001],
    [0x1,0x59C0,0x0,0x2001],
    [0x1,0x5AC0,0xFF,0x2001],
    [0x1,0x5BC0,0x0,0x2001],
    [0x1,0x5CC0,0xFF,0x2001],
    [0x1,0x5DC0,0x0,0x2001],
    [0x1,0x5EC0,0xFF,0x2001],
    [0x1,0x5FC0,0x0,0x2001],
    [0x2,0x50C0,0xFF,0x2002],
    [0x2,0x51C0,0x0,0x2002],
    [0x2,0x52C0,0xFF,0x2002],
    [0x2,0x53C0,0x0,0x2002],
    [0x2,0x54C0,0xFF,0x2002],
    [0x2,0x55C0,0x0,0x2002],
    [0x2,0x56C0,0xFF,0x2002],
    [0x2,0x57C0,0x0,0x2002],
    [0x2,0x58C0,0x0,0x2002],
    [0x2,0x59C0,0xFF,0x2002],
    [0x2,0x5AC0,0xFF,0x2002],
    [0x2,0x5BC0,0x0,0x2002],
    [0x2,0x5CC0,0x0,0x2002],
    [0x2,0x5DC0,0xFF,0x2002],
    [0x2,0x5EC0,0x0,0x2002],
    [0x2,0x5FC0,0xFF,0x2002],
    [0x3,0x50C0,0xFF,0x2003],
    [0x3,0x51C0,0x0,0x2003],
    [0x3,0x52C0,0x0,0x2003],
    [0x3,0x53C0,0xFF,0x2003],
    [0x3,0x54C0,0x0,0x2003],
    [0x3,0x55C0,0xFF,0x2003],
    [0x3,0x56C0,0xFF,0x2003],
    [0x3,0x57C0,0x0,0x2003],
    [0x3,0x58C0,0x0,0x2003],
    [0x3,0x59C0,0xFF,0x2003],
    [0x3,0x5AC0,0xFF,0x2003],
    [0x3,0x5BC0,0x0,0x2003],
    [0x3,0x5CC0,0x0,0x2003],
    [0x3,0x5DC0,0xFF,0x2003],
    [0x3,0x5EC0,0x0,0x2003],
    [0x3,0x5FC0,0xFF,0x2003],
    [0x4,0x50C0,0xFF,0x2004],
    [0x4,0x51C0,0x0,0x2004],
    [0x4,0x52C0,0x0,0x2004],
    [0x4,0x53C0,0xFF,0x2004],
    [0x4,0x54C0,0xFF,0x2004],
    [0x4,0x55C0,0x0,0x2004],
    [0x4,0x56C0,0x0,0x2004],
    [0x4,0x57C0,0xFF,0x2004],
    [0x4,0x58C0,0xFF,0x2004],
    [0x4,0x59C0,0x0,0x2004],
    [0x4,0x5AC0,0xFF,0x2004],
    [0x4,0x5BC0,0x0,0x2004],
    [0x4,0x5CC0,0xFF,0x2004],
    [0x4,0x5DC0,0x0,0x2004],
    [0x4,0x5EC0,0x0,0x2004],
    [0x4,0x5FC0,0xFF,0x2004],
    [0x5,0x50C0,0xFF,0x2005],
    [0x5,0x51C0,0x0,0x2005],
    [0x5,0x52C0,0x0,0x2005],
    [0x5,0x53C0,0xFF,0x2005],
    [0x5,0x54C0,0x0,0x2005],
    [0x5,0x55C0,0xFF,0x2005],
    [0x5,0x56C0,0x0,0x2005],
    [0x5,0x57C0,0xFF,0x2005],
    [0x5,0x58C0,0xFF,0x2005],
    [0x5,0x59C0,0x0,0x2005],
    [0x5,0x5AC0,0xFF,0x2005],
    [0x5,0x5BC0,0x0,0x2005],
    [0x5,0x5CC0,0xFF,0x2005],
    [0x5,0x5DC0,0x0,0x2005],
    [0x5,0x5EC0,0x0,0x2005],
    [0x5,0x5FC0,0xFF,0x2005],
    [0x6,0x50C0,0xFF,0x2006],
    [0x6,0x51C0,0x0,0x2006],
    [0x6,0x52C0,0x0,0x2006],
    [0x6,0x53C0,0xFF,0x2006],
    [0x6,0x54C0,0xFF,0x2006],
    [0x6,0x55C0,0x0,0x2006],
    [0x6,0x56C0,0x0,0x2006],
    [0x6,0x57C0,0xFF,0x2006],
    [0x6,0x58C0,0x0,0x2006],
    [0x6,0x59C0,0xFF,0x2006],
    [0x6,0x5AC0,0xFF,0x2006],
    [0x6,0x5BC0,0x0,0x2006],
    [0x6,0x5CC0,0x0,0x2006],
    [0x6,0x5DC0,0xFF,0x2006],
    [0x6,0x5EC0,0x0,0x2006],
    [0x6,0x5FC0,0xFF,0x2006],
    [0x7,0x50C0,0xFF,0x2007],
    [0x7,0x51C0,0x0,0x2007],
    [0x7,0x52C0,0x0,0x2007],
    [0x7,0x53C0,0xFF,0x2007],
    [0x7,0x54C0,0x0,0x2007],
    [0x7,0x55C0,0xFF,0x2007],
    [0x7,0x56C0,0x0,0x2007],
    [0x7,0x57C0,0xFF,0x2007],
    [0x7,0x58C0,0x0,0x2007],
    [0x7,0x59C0,0xFF,0x2007],
    [0x7,0x5AC0,0xFF,0x2007],
    [0x7,0x5BC0,0x0,0x2007],
    [0x7,0x5CC0,0x0,0x2007],
    [0x7,0x5DC0,0xFF,0x2007],
    [0x7,0x5EC0,0x0,0x2007],
    [0x7,0x5FC0,0xFF,0x2007],
    [0x8,0x50C0,0xFF,0x2008],
    [0x8,0x51C0,0x0,0x2008],
    [0x8,0x52C0,0xFF,0x2008],
    [0x8,0x53C0,0x0,0x2008],
    [0x8,0x54C0,0xFF,0x2008],
    [0x8,0x55C0,0x0,0x2008],
    [0x8,0x56C0,0xFF,0x2008],
    [0x8,0x57C0,0x0,0x2008],
    [0x8,0x58C0,0xFF,0x2008],
    [0x8,0x59C0,0x0,0x2008],
    [0x8,0x5AC0,0x0,0x2008],
    [0x8,0x5BC0,0xFF,0x2008],
    [0x8,0x5CC0,0x0,0x2008],
    [0x8,0x5DC0,0xFF,0x2008],
    [0x8,0x5EC0,0x0,0x2008],
    [0x8,0x5FC0,0xFF,0x2008],
    [0x9,0x50C0,0xFF,0x2009],
    [0x9,0x51C0,0x0,0x2009],
    [0x9,0x52C0,0x0,0x2009],
    [0x9,0x53C0,0xFF,0x2009],
    [0x9,0x54C0,0x0,0x2009],
    [0x9,0x55C0,0xFF,0x2009],
    [0x9,0x56C0,0xFF,0x2009],
    [0x9,0x57C0,0x0,0x2009],
    [0x9,0x58C0,0xFF,0x2009],
    [0x9,0x59C0,0x0,0x2009],
    [0x9,0x5AC0,0x0,0x2009],
    [0x9,0x5BC0,0xFF,0x2009],
    [0x9,0x5CC0,0x0,0x2009],
    [0x9,0x5DC0,0xFF,0x2009],
    [0x9,0x5EC0,0x0,0x2009],
    [0x9,0x5FC0,0xFF,0x2009],
    [0xA,0x50C0,0xFF,0x200A],
    [0xA,0x51C0,0x0,0x200A],
    [0xA,0x52C0,0xFF,0x200A],
    [0xA,0x53C0,0x0,0x200A],
    [0xA,0x54C0,0xFF,0x200A],
    [0xA,0x55C0,0x0,0x200A],
    [0xA,0x56C0,0xFF,0x200A],
    [0xA,0x57C0,0x0,0x200A],
    [0xA,0x58C0,0x0,0x200A],
    [0xA,0x59C0,0xFF,0x200A],
    [0xA,0x5AC0,0x0,0x200A],
    [0xA,0x5BC0,0xFF,0x200A],
    [0xA,0x5CC0,0xFF,0x200A],
    [0xA,0x5DC0,0x0,0x200A],
    [0xA,0x5EC0,0xFF,0x200A],
    [0xA,0x5FC0,0x0,0x200A],
    [0xB,0x50C0,0xFF,0x200B],
    [0xB,0x51C0,0x0,0x200B],
    [0xB,0x52C0,0x0,0x200B],
    [0xB,0x53C0,0xFF,0x200B],
    [0xB,0x54C0,0x0,0x200B],
    [0xB,0x55C0,0xFF,0x200B],
    [0xB,0x56C0,0xFF,0x200B],
    [0xB,0x57C0,0x0,0x200B],
    [0xB,0x58C0,0x0,0x200B],
    [0xB,0x59C0,0xFF,0x200B],
    [0xB,0x5AC0,0x0,0x200B],
    [0xB,0x5BC0,0xFF,0x200B],
    [0xB,0x5CC0,0xFF,0x200B],
    [0xB,0x5DC0,0x0,0x200B],
    [0xB,0x5EC0,0xFF,0x200B],
    [0xB,0x5FC0,0x0,0x200B],
    [0xC,0x50C0,0xFF,0x200C],
    [0xC,0x51C0,0x0,0x200C],
    [0xC,0x52C0,0x0,0x200C],
    [0xC,0x53C0,0xFF,0x200C],
    [0xC,0x54C0,0xFF,0x200C],
    [0xC,0x55C0,0x0,0x200C],
    [0xC,0x56C0,0x0,0x200C],
    [0xC,0x57C0,0xFF,0x200C],
    [0xC,0x58C0,0xFF,0x200C],
    [0xC,0x59C0,0x0,0x200C],
    [0xC,0x5AC0,0x0,0x200C],
    [0xC,0x5BC0,0xFF,0x200C],
    [0xC,0x5CC0,0x0,0x200C],
    [0xC,0x5DC0,0xFF,0x200C],
    [0xC,0x5EC0,0x0,0x200C],
    [0xC,0x5FC0,0xFF,0x200C],
    [0xD,0x50C0,0xFF,0x200D],
    [0xD,0x51C0,0x0,0x200D],
    [0xD,0x52C0,0x0,0x200D],
    [0xD,0x53C0,0xFF,0x200D],
    [0xD,0x54C0,0x0,0x200D],
    [0xD,0x55C0,0xFF,0x200D],
    [0xD,0x56C0,0x0,0x200D],
    [0xD,0x57C0,0xFF,0x200D],
    [0xD,0x58C0,0xFF,0x200D],
    [0xD,0x59C0,0x0,0x200D],
    [0xD,0x5AC0,0x0,0x200D],
    [0xD,0x5BC0,0xFF,0x200D],
    [0xD,0x5CC0,0x0,0x200D],
    [0xD,0x5DC0,0xFF,0x200D],
    [0xD,0x5EC0,0x0,0x200D],
    [0xD,0x5FC0,0xFF,0x200D],
    [0xE,0x50C0,0xFF,0x200E],
    [0xE,0x51C0,0x0,0x200E],
    [0xE,0x52C0,0x0,0x200E],
    [0xE,0x53C0,0xFF,0x200E],
    [0xE,0x54C0,0xFF,0x200E],
    [0xE,0x55C0,0x0,0x200E],
    [0xE,0x56C0,0x0,0x200E],
    [0xE,0x57C0,0xFF,0x200E],
    [0xE,0x58C0,0x0,0x200E],
    [0xE,0x59C0,0xFF,0x200E],
    [0xE,0x5AC0,0x0,0x200E],
    [0xE,0x5BC0,0xFF,0x200E],
    [0xE,0x5CC0,0xFF,0x200E],
    [0xE,0x5DC0,0x0,0x200E],
    [0xE,0x5EC0,0x0,0x200E],
    [0xE,0x5FC0,0xFF,0x200E],
    [0xF,0x50C0,0xFF,0x200F],
    [0xF,0x51C0,0x0,0x200F],
    [0xF,0x52C0,0x0,0x200F],
    [0xF,0x53C0,0xFF,0x200F],
    [0xF,0x54C0,0x0,0x200F],
    [0xF,0x55C0,0xFF,0x200F],
    [0xF,0x56C0,0x0,0x200F],
    [0xF,0x57C0,0xFF,0x200F],
    [0xF,0x58C0,0x0,0x200F],
    [0xF,0x59C0,0xFF,0x200F],
    [0xF,0x5AC0,0x0,0x200F],
    [0xF,0x5BC0,0xFF,0x200F],
    [0xF,0x5CC0,0xFF,0x200F],
    [0xF,0x5DC0,0x0,0x200F],
    [0xF,0x5EC0,0x0,0x200F],
    [0xF,0x5FC0,0xFF,0x200F],
    [0x10,0x50C0,0xFF,0x2010],
    [0x10,0x51C0,0x0,0x2010],
    [0x10,0x52C0,0xFF,0x2010],
    [0x10,0x53C0,0x0,0x2010],
    [0x10,0x54C0,0xFF,0x2010],
    [0x10,0x55C0,0x0,0x2010],
    [0x10,0x56C0,0xFF,0x2010],
    [0x10,0x57C0,0x0,0x2010],
    [0x10,0x58C0,0xFF,0x2010],
    [0x10,0x59C0,0x0,0x2010],
    [0x10,0x5AC0,0xFF,0x2010],
    [0x10,0x5BC0,0x0,0x2010],
    [0x10,0x5CC0,0xFF,0x2010],
    [0x10,0x5DC0,0x0,0x2010],
    [0x10,0x5EC0,0xFF,0x2010],
    [0x10,0x5FC0,0x0,0x2010],
    [0x11,0x50C0,0xFF,0x2011],
    [0x11,0x51C0,0x0,0x2011],
    [0x11,0x52C0,0x0,0x2011],
    [0x11,0x53C0,0xFF,0x2011],
    [0x11,0x54C0,0x0,0x2011],
    [0x11,0x55C0,0xFF,0x2011],
    [0x11,0x56C0,0xFF,0x2011],
    [0x11,0x57C0,0x0,0x2011],
    [0x11,0x58C0,0xFF,0x2011],
    [0x11,0x59C0,0x0,0x2011],
    [0x11,0x5AC0,0xFF,0x2011],
    [0x11,0x5BC0,0x0,0x2011],
    [0x11,0x5CC0,0xFF,0x2011],
    [0x11,0x5DC0,0x0,0x2011],
    [0x11,0x5EC0,0xFF,0x2011],
    [0x11,0x5FC0,0x0,0x2011],
    [0x12,0x50C0,0xFF,0x2012],
    [0x12,0x51C0,0x0,0x2012],
    [0x12,0x52C0,0xFF,0x2012],
    [0x12,0x53C0,0x0,0x2012],
    [0x12,0x54C0,0xFF,0x2012],
    [0x12,0x55C0,0x0,0x2012],
    [0x12,0x56C0,0xFF,0x2012],
    [0x12,0x57C0,0x0,0x2012],
    [0x12,0x58C0,0x0,0x2012],
    [0x12,0x59C0,0xFF,0x2012],
    [0x12,0x5AC0,0xFF,0x2012],
    [0x12,0x5BC0,0x0,0x2012],
    [0x12,0x5CC0,0x0,0x2012],
    [0x12,0x5DC0,0xFF,0x2012],
    [0x12,0x5EC0,0x0,0x2012],
    [0x12,0x5FC0,0xFF,0x2012],
    [0x13,0x50C0,0xFF,0x2013],
    [0x13,0x51C0,0x0,0x2013],
    [0x13,0x52C0,0x0,0x2013],
    [0x13,0x53C0,0xFF,0x2013],
    [0x13,0x54C0,0x0,0x2013],
    [0x13,0x55C0,0xFF,0x2013],
    [0x13,0x56C0,0xFF,0x2013],
    [0x13,0x57C0,0x0,0x2013],
    [0x13,0x58C0,0x0,0x2013],
    [0x13,0x59C0,0xFF,0x2013],
    [0x13,0x5AC0,0xFF,0x2013],
    [0x13,0x5BC0,0x0,0x2013],
    [0x13,0x5CC0,0x0,0x2013],
    [0x13,0x5DC0,0xFF,0x2013],
    [0x13,0x5EC0,0x0,0x2013],
    [0x13,0x5FC0,0xFF,0x2013],
    [0x14,0x50C0,0xFF,0x2014],
    [0x14,0x51C0,0x0,0x2014],
    [0x14,0x52C0,0x0,0x2014],
    [0x14,0x53C0,0xFF,0x2014],
    [0x14,0x54C0,0xFF,0x2014],
    [0x14,0x55C0,0x0,0x2014],
    [0x14,0x56C0,0x0,0x2014],
    [0x14,0x57C0,0xFF,0x2014],
    [0x14,0x58C0,0xFF,0x2014],
    [0x14,0x59C0,0x0,0x2014],
    [0x14,0x5AC0,0xFF,0x2014],
    [0x14,0x5BC0,0x0,0x2014],
    [0x14,0x5CC0,0xFF,0x2014],
    [0x14,0x5DC0,0x0,0x2014],
    [0x14,0x5EC0,0x0,0x2014],
    [0x14,0x5FC0,0xFF,0x2014],
    [0x15,0x50C0,0xFF,0x2015],
    [0x15,0x51C0,0x0,0x2015],
    [0x15,0x52C0,0x0,0x2015],
    [0x15,0x53C0,0xFF,0x2015],
    [0x15,0x54C0,0x0,0x2015],
    [0x15,0x55C0,0xFF,0x2015],
    [0x15,0x56C0,0x0,0x2015],
    [0x15,0x57C0,0xFF,0x2015],
    [0x15,0x58C0,0xFF,0x2015],
    [0x15,0x59C0,0x0,0x2015],
    [0x15,0x5AC0,0xFF,0x2015],
    [0x15,0x5BC0,0x0,0x2015],
    [0x15,0x5CC0,0xFF,0x2015],
    [0x15,0x5DC0,0x0,0x2015],
    [0x15,0x5EC0,0x0,0x2015],
    [0x15,0x5FC0,0xFF,0x2015],
    [0x16,0x50C0,0xFF,0x2016],
    [0x16,0x51C0,0x0,0x2016],
    [0x16,0x52C0,0x0,0x2016],
    [0x16,0x53C0,0xFF,0x2016],
    [0x16,0x54C0,0xFF,0x2016],
    [0x16,0x55C0,0x0,0x2016],
    [0x16,0x56C0,0x0,0x2016],
    [0x16,0x57C0,0xFF,0x2016],
    [0x16,0x58C0,0x0,0x2016],
    [0x16,0x59C0,0xFF,0x2016],
    [0x16,0x5AC0,0xFF,0x2016],
    [0x16,0x5BC0,0x0,0x2016],
    [0x16,0x5CC0,0x0,0x2016],
    [0x16,0x5DC0,0xFF,0x2016],
    [0x16,0x5EC0,0x0,0x2016],
    [0x16,0x5FC0,0xFF,0x2016],
    [0x17,0x50C0,0xFF,0x2017],
    [0x17,0x51C0,0x0,0x2017],
    [0x17,0x52C0,0x0,0x2017],
    [0x17,0x53C0,0xFF,0x2017],
    [0x17,0x54C0,0x0,0x2017],
    [0x17,0x55C0,0xFF,0x2017],
    [0x17,0x56C0,0x0,0x2017],
    [0x17,0x57C0,0xFF,0x2017],
    [0x17,0x58C0,0x0,0x2017],
    [0x17,0x59C0,0xFF,0x2017],
    [0x17,0x5AC0,0xFF,0x2017],
    [0x17,0x5BC0,0x0,0x2017],
    [0x17,0x5CC0,0x0,0x2017],
    [0x17,0x5DC0,0xFF,0x2017],
    [0x17,0x5EC0,0x0,0x2017],
    [0x17,0x5FC0,0xFF,0x2017],
    [0x18,0x50C0,0xFF,0x2018],
    [0x18,0x51C0,0x0,0x2018],
    [0x18,0x52C0,0xFF,0x2018],
    [0x18,0x53C0,0x0,0x2018],
    [0x18,0x54C0,0xFF,0x2018],
    [0x18,0x55C0,0x0,0x2018],
    [0x18,0x56C0,0xFF,0x2018],
    [0x18,0x57C0,0x0,0x2018],
    [0x18,0x58C0,0xFF,0x2018],
    [0x18,0x59C0,0x0,0x2018],
    [0x18,0x5AC0,0x0,0x2018],
    [0x18,0x5BC0,0xFF,0x2018],
    [0x18,0x5CC0,0x0,0x2018],
    [0x18,0x5DC0,0xFF,0x2018],
    [0x18,0x5EC0,0x0,0x2018],
    [0x18,0x5FC0,0xFF,0x2018],
    [0x19,0x50C0,0xFF,0x2019],
    [0x19,0x51C0,0x0,0x2019],
    [0x19,0x52C0,0x0,0x2019],
    [0x19,0x53C0,0xFF,0x2019],
    [0x19,0x54C0,0x0,0x2019],
    [0x19,0x55C0,0xFF,0x2019],
    [0x19,0x56C0,0xFF,0x2019],
    [0x19,0x57C0,0x0,0x2019],
    [0x19,0x58C0,0xFF,0x2019],
    [0x19,0x59C0,0x0,0x2019],
    [0x19,0x5AC0,0x0,0x2019],
    [0x19,0x5BC0,0xFF,0x2019],
    [0x19,0x5CC0,0x0,0x2019],
    [0x19,0x5DC0,0xFF,0x2019],
    [0x19,0x5EC0,0x0,0x2019],
    [0x19,0x5FC0,0xFF,0x2019],
    [0x1A,0x50C0,0xFF,0x201A],
    [0x1A,0x51C0,0x0,0x201A],
    [0x1A,0x52C0,0xFF,0x201A],
    [0x1A,0x53C0,0x0,0x201A],
    [0x1A,0x54C0,0xFF,0x201A],
    [0x1A,0x55C0,0x0,0x201A],
    [0x1A,0x56C0,0xFF,0x201A],
    [0x1A,0x57C0,0x0,0x201A],
    [0x1A,0x58C0,0x0,0x201A],
    [0x1A,0x59C0,0xFF,0x201A],
    [0x1A,0x5AC0,0x0,0x201A],
    [0x1A,0x5BC0,0xFF,0x201A],
    [0x1A,0x5CC0,0xFF,0x201A],
    [0x1A,0x5DC0,0x0,0x201A],
    [0x1A,0x5EC0,0xFF,0x201A],
    [0x1A,0x5FC0,0x0,0x201A],
    [0x1B,0x50C0,0xFF,0x201B],
    [0x1B,0x51C0,0x0,0x201B],
    [0x1B,0x52C0,0x0,0x201B],
    [0x1B,0x53C0,0xFF,0x201B],
    [0x1B,0x54C0,0x0,0x201B],
    [0x1B,0x55C0,0xFF,0x201B],
    [0x1B,0x56C0,0xFF,0x201B],
    [0x1B,0x57C0,0x0,0x201B],
    [0x1B,0x58C0,0x0,0x201B],
    [0x1B,0x59C0,0xFF,0x201B],
    [0x1B,0x5AC0,0x0,0x201B],
    [0x1B,0x5BC0,0xFF,0x201B],
    [0x1B,0x5CC0,0xFF,0x201B],
    [0x1B,0x5DC0,0x0,0x201B],
    [0x1B,0x5EC0,0xFF,0x201B],
    [0x1B,0x5FC0,0x0,0x201B],
    [0x1C,0x50C0,0xFF,0x201C],
    [0x1C,0x51C0,0x0,0x201C],
    [0x1C,0x52C0,0x0,0x201C],
    [0x1C,0x53C0,0xFF,0x201C],
    [0x1C,0x54C0,0xFF,0x201C],
    [0x1C,0x55C0,0x0,0x201C],
    [0x1C,0x56C0,0x0,0x201C],
    [0x1C,0x57C0,0xFF,0x201C],
    [0x1C,0x58C0,0xFF,0x201C],
    [0x1C,0x59C0,0x0,0x201C],
    [0x1C,0x5AC0,0x0,0x201C],
    [0x1C,0x5BC0,0xFF,0x201C],
    [0x1C,0x5CC0,0x0,0x201C],
    [0x1C,0x5DC0,0xFF,0x201C],
    [0x1C,0x5EC0,0x0,0x201C],
    [0x1C,0x5FC0,0xFF,0x201C],
    [0x1D,0x50C0,0xFF,0x201D],
    [0x1D,0x51C0,0x0,0x201D],
    [0x1D,0x52C0,0x0,0x201D],
    [0x1D,0x53C0,0xFF,0x201D],
    [0x1D,0x54C0,0x0,0x201D],
    [0x1D,0x55C0,0xFF,0x201D],
    [0x1D,0x56C0,0x0,0x201D],
    [0x1D,0x57C0,0xFF,0x201D],
    [0x1D,0x58C0,0xFF,0x201D],
    [0x1D,0x59C0,0x0,0x201D],
    [0x1D,0x5AC0,0x0,0x201D],
    [0x1D,0x5BC0,0xFF,0x201D],
    [0x1D,0x5CC0,0x0,0x201D],
    [0x1D,0x5DC0,0xFF,0x201D],
    [0x1D,0x5EC0,0x0,0x201D],
    [0x1D,0x5FC0,0xFF,0x201D],
    [0x1E,0x50C0,0xFF,0x201E],
    [0x1E,0x51C0,0x0,0x201E],
    [0x1E,0x52C0,0x0,0x201E],
    [0x1E,0x53C0,0xFF,0x201E],
    [0x1E,0x54C0,0xFF,0x201E],
    [0x1E,0x55C0,0x0,0x201E],
    [0x1E,0x56C0,0x0,0x201E],
    [0x1E,0x57C0,0xFF,0x201E],
    [0x1E,0x58C0,0x0,0x201E],
    [0x1E,0x59C0,0xFF,0x201E],
    [0x1E,0x5AC0,0x0,0x201E],
    [0x1E,0x5BC0,0xFF,0x201E],
    [0x1E,0x5CC0,0xFF,0x201E],
    [0x1E,0x5DC0,0x0,0x201E],
    [0x1E,0x5EC0,0x0,0x201E],
    [0x1E,0x5FC0,0xFF,0x201E],
    [0x1F,0x50C0,0xFF,0x201F],
    [0x1F,0x51C0,0x0,0x201F],
    [0x1F,0x52C0,0x0,0x201F],
    [0x1F,0x53C0,0xFF,0x201F],
    [0x1F,0x54C0,0x0,0x201F],
    [0x1F,0x55C0,0xFF,0x201F],
    [0x1F,0x56C0,0x0,0x201F],
    [0x1F,0x57C0,0xFF,0x201F],
    [0x1F,0x58C0,0x0,0x201F],
    [0x1F,0x59C0,0xFF,0x201F],
    [0x1F,0x5AC0,0x0,0x201F],
    [0x1F,0x5BC0,0xFF,0x201F],
    [0x1F,0x5CC0,0xFF,0x201F],
    [0x1F,0x5DC0,0x0,0x201F],
    [0x1F,0x5EC0,0x0,0x201F],
    [0x1F,0x5FC0,0xFF,0x201F]];
}
