module emul.m68k.tests.testdiv;

unittest
{
    import std.stdio;
    import emul.m68k.tests.testcore;
    writeln("test div");
    auto core = makeSafe!TestCore();

    //divs.w
    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0xffffffff;
    core.cpu.state.D[1] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0x83c0);
    core.run(1);
    assert(0x12345678 == core.cpu.state.D[1]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.D[1] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0x83c0);
    core.run(1);
    assert(0x252035E5 == core.cpu.state.D[1]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.D[1] = 0xffff0001;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0x83c0);
    core.run(1);
    assert(0xACF1FFFE == core.cpu.state.D[1]);

    //divu.w
    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0xffffffff;
    core.cpu.state.D[1] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0x82c0);
    core.run(1);
    assert(0x68AC1234 == core.cpu.state.D[1]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.D[1] = 0x12345678;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0x82c0);
    core.run(1);
    assert(0x252035E5 == core.cpu.state.D[1]);

    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0x12345678;
    core.cpu.state.D[1] = 0xffff0001;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0x82c0);
    core.run(1);
    assert(0xFFFF0001 == core.cpu.state.D[1]);
}

