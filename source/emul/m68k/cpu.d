module emul.m68k.cpu;

public import emul.m68k.cpustate;
public import emul.m68k.memory;

import gamelib.memory.saferef;

struct Cpu
{
    CpuState state;
    Memory memory;
}

alias CpuPtr = SafeRef!Cpu;