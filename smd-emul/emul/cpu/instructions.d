module emul.cpu.instructions;

import std.bitmanip;

import gamelib.util;

import emul.cpu.cpu;

struct Instruction
{
    string name;
    ushort opcode;
    ushort size;
    void function(Cpu*) pure nothrow impl;
}

enum InvalidInstruction = Instruction("invalid",0x0,0x2,&invalidImpl);
enum Instructions = initInstructions();

private pure nothrow:
void addInstruction(Instruction[ushort] instructions, in Instruction instr)
{
    /*version(BigEndian)
    {
        ushort ind = instr.opcode;
    }
    else
    {
        ushort ind = swapEndian(instr.opcode);
    }*/
    const ind = instr.opcode;
    assert(ind != 0);
    instructions[ind] = instr;
}

auto initInstructions()
{
    Instruction[ushort] ret;

    ret.addInstruction(Instruction("nop",0x4e71,0x2,&nopImpl));
    foreach(i;TupleRange!(0x1,0xfe))
    {
        ret.addInstruction(Instruction("bra",0x6000 | i,0x2,&braBImpl!(cast(byte)i)));
    }
    ret.addInstruction(Instruction("bra",0x6000,0x4,&braImpl!short));
    ret.addInstruction(Instruction("bra",0x60ff,0x6,&braImpl!int));
    return ret;
}

void invalidImpl(Cpu*)
{
    //TODO
    assert(false);
}

void nopImpl(Cpu*)
{
    //TODO
}

void braBImpl(byte offset)(Cpu* cpu)
{
    cpu.state.PC += offset;
}
void braImpl(T)(Cpu* cpu)
{
    const offset = cpu.memory.getValue!T(cpu.state.PC - T.sizeof);
    cpu.state.PC += offset;
}