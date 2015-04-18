module emul.m68k.cpu.cpu;

import emul.m68k.cpu.cpustate;
import emul.m68k.cpu.memory;

import gamelib.memory.saferef;

struct Cpu
{
    CpuState state;
    Memory memory;

    auto getMemValue(T)(uint offset) const
    {
        return memory.getValue!T(offset);
    }

    void setMemValue(T)(uint offset, in T val)
    {
        memory.setValue!T(offset,val);
    }

    auto getRawMemValue(T)(uint offset) const
    {
        return memory.getRawValue!T(offset);
    }
}

alias CpuPtr = SafeRef!Cpu;