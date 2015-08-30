module emul.m68k.tests.testrolror;

unittest
{
    import std.stdio;
    import emul.m68k.tests.testcore;
    writeln("test rol/ror");
    auto core = makeSafe!TestCore();

    //rol.l
    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe398);
    core.run(1);
    assert(0x2468ACF0 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe598);
    core.run(1);
    assert(0x48D159E0 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe798);
    core.run(1);
    assert(0x91A2B3C0 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe998);
    core.run(1);
    assert(0x23456781 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xeb98);
    core.run(1);
    assert(0x468ACF02 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xed98);
    core.run(1);
    assert(0x8D159E04 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xef98);
    core.run(1);
    assert(0x1A2B3C09 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe198);
    core.run(1);
    assert(0x34567812 == core.cpu.state.D[0]);


    //ror.l
    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe298);
    core.run(1);
    assert(0x091A2B3C == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe498);
    core.run(1);
    assert(0x048D159E == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe698);
    core.run(1);
    assert(0x02468ACF == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe898);
    core.run(1);
    assert(0x81234567 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xea98);
    core.run(1);
    assert(0xC091A2B3 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xec98);
    core.run(1);
    assert(0xE048D159 == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xee98);
    core.run(1);
    assert(0xF02468AC == core.cpu.state.D[0]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xe098);
    core.run(1);
    assert(0x78123456 == core.cpu.state.D[0]);
}

