module emul.m68k.tests.testroxlroxr;


unittest
{
    import std.stdio;
    import emul.m68k.tests.testcore;
    writeln("test roxl/roxr");
    auto core = makeSafe!TestCore();

    //roxl.l
    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe390);
    core.run(1);
    assert(0x2468ACF0 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe590);
    core.run(1);
    assert(0x48D159E0 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe790);
    core.run(1);
    assert(0x91A2B3C0 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe990);
    core.run(1);
    assert(0x23456780 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xeb90);
    core.run(1);
    assert(0x468ACF01 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xed90);
    core.run(1);
    assert(0x8D159E02 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xef90);
    core.run(1);
    assert(0x1A2B3C04 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe190);
    core.run(1);
    assert(0x34567809 == core.cpu.state.D[0]);


    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe390);
    core.run(1);
    assert(0x2468ACF1 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe590);
    core.run(1);
    assert(0x48D159E2 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe790);
    core.run(1);
    assert(0x91A2B3C4 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe990);
    core.run(1);
    assert(0x23456788 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xeb90);
    core.run(1);
    assert(0x468ACF11 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xed90);
    core.run(1);
    assert(0x8D159E22 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xef90);
    core.run(1);
    assert(0x1A2B3C44 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe190);
    core.run(1);
    assert(0x34567889 == core.cpu.state.D[0]);


    //roxr.l
    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe290);
    core.run(1);
    assert(0x091A2B3C == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe490);
    core.run(1);
    assert(0x048D159E == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe690);
    core.run(1);
    assert(0x02468ACF == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe890);
    core.run(1);
    assert(0x01234567 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xea90);
    core.run(1);
    assert(0x8091A2B3 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xec90);
    core.run(1);
    assert(0xC048D159 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xee90);
    core.run(1);
    assert(0xE02468AC == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe090);
    core.run(1);
    assert(0xF0123456 == core.cpu.state.D[0]);


    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe290);
    core.run(1);
    assert(0x891A2B3C == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe490);
    core.run(1);
    assert(0x448D159E == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe690);
    core.run(1);
    assert(0x22468ACF == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe890);
    core.run(1);
    assert(0x11234567 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xea90);
    core.run(1);
    assert(0x8891A2B3 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xec90);
    core.run(1);
    assert(0xC448D159 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xee90);
    core.run(1);
    assert(0xE22468AC == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.setFlags!(CCRFlags.X)();
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe090);
    core.run(1);
    assert(0xF1123456 == core.cpu.state.D[0]);
}
