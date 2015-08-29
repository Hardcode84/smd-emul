module emul.m68k.tests.testmul;

unittest
{
    import std.stdio;
    import emul.m68k.tests.testcore;
    writeln("test mul");
    auto core = makeSafe!TestCore();

    //muls.w
    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0xffffffff;
    core.cpu.state.D[1] = 0xffffffff;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xc3c0);
    core.run(1);
    assert(1 == core.cpu.state.D[1]);

    //mulu.w
    core.reset(0x200,0xffffff);
    core.cpu.state.D[0] = 0xffffffff;
    core.cpu.state.D[1] = 0xffffffff;
    core.cpu.memory.setValueUnchecked!ushort(0x200,0xc2c0);
    core.run(1);
    assert(0xfffe0001 == core.cpu.state.D[1]);
}