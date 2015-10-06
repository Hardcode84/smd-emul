module emul.m68k.tests.testexg;

unittest
{
    import std.stdio;
    import emul.m68k.tests.testcore;
    writeln("test exg");
    auto core = makeSafe!TestCore();

    // data - data
    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 1;
    core.cpu.state.D[1] = 2;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xc141);
    core.run(1);
    assert(2 == core.cpu.state.D[0]);
    assert(1 == core.cpu.state.D[1]);

    //address - address
    core.reset(0x200,0xffffff);
    core.cpu.state.A[0] = 1;
    core.cpu.state.A[1] = 2;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xc149);
    core.run(1);
    assert(2 == core.cpu.state.A[0]);
    assert(1 == core.cpu.state.A[1]);

    //data - address
    core.reset(0x200,0xffffff);
    core.cpu.state.D[1] = 1;
    core.cpu.state.A[1] = 2;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xc389);
    core.run(1);
    assert(2 == core.cpu.state.D[1]);
    assert(1 == core.cpu.state.A[1]);
}