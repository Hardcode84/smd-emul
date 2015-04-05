module emul.cpu.cpu;

public import emul.cpu.cpustate;
public import emul.cpu.memory;

struct Cpu
{
    CpuState state;
    Memory memory;
}

