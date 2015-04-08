module emul.cpu.cpu;

public import emul.cpu.cpustate;
public import emul.cpu.memory;

import gamelib.memory.saferef;

struct Cpu
{
    CpuState state;
    Memory memory;
}

alias CpuPtr = SafeRef!Cpu;