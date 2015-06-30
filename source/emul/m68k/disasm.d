module emul.m68k.disasm;

import std.algorithm;
import std.exception;
import std.bitmanip;

import emul.m68k.cpu;

import emul.m68k.instructions.create;

struct Disasm
{
pure nothrow:
    this(int dummy)
    {
        Desc[] tempDescs;
        tempDescs.length = ushort.max + 1;
        foreach(const ref instr;createInstructions().byKeyValue)
        {
            tempDescs[swapEndian(instr.key)].desc = instr.value.name;
        }
        mDescs = tempDescs.assumeUnique;
    }

    string getDesc(in ref Cpu cpu, uint address) const @nogc
    {
        if(!cpu.memory.checkRange!true(address, ushort.sizeof))
        {
            return "inaccesible";
        }
        const opcode = cpu.memory.getValue!ushort(address);
        return mDescs[opcode].desc;
    }
private:
    struct Desc
    {
        string desc = "unknown";
    };
    immutable Desc[] mDescs;
}

