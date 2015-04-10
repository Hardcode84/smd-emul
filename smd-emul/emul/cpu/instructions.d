module emul.cpu.instructions;

import std.bitmanip;
import std.algorithm;

import gamelib.util;

import emul.cpu.cpu;

struct Instruction
{
    string name;
    ushort opcode;
    ushort size;
    void function(CpuPtr) @nogc pure nothrow impl;
}

enum InvalidInstruction = Instruction("invalid",0x0,0x2,&invalidImpl);
enum Instructions = initInstructions();

private pure nothrow:
void addInstruction(Instruction[ushort] instructions, in Instruction instr)
{
    version(BigEndian)
    {
        ushort ind = instr.opcode;
    }
    else
    {
        ushort ind = swapEndian(instr.opcode);
    }
    //const ind = instr.opcode;
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

    //ret.addInstruction(Instruction("tst",0x4a00,0x2,&braImpl!int));
    return ret;
}

template sizeType(ubyte val)
{
         static if(0x00b == val) alias sizeType = byte;
    else static if(0x01b == val) alias sizeType = short;
    else static if(0x11b == val) alias sizeType = int;
    else static assert(false);
}
enum ubyte[] sizeTypeValues = [0x0,0x1,0x2];

template addressMode(T, bool Write, ubyte Mode, ubyte Reg)
{
    private void memProxy(F)(CpuPtr cpu, uint address)
    {
        static if(Write)
        {
            cpu.memory.setValue!T(address,F(cpu));
        }
        else
        {
            F(cpu,cpu.memoty.getValue!T(address));
        }
    }
    private enum RegInc = (7 == Reg ? max(2,T.sizeof) : T.sizeof);
    static if(0x000b == Mode)
    {
        enum exWords = 0;
        void call(F)(CpuPtr cpu)
        {
            static if(Write)
            {
                cpu.state.D[Reg] = F(cpu);
            }
            else
            {
                F(cpu,cpu.state.D[Reg]);
            }
        }
    }
    static if(0x001b == Mode)
    {
        enum exWords = 0;
        void call(F)(CpuPtr cpu)
        {
            static if(Write)
            {
                cpu.state.A[Reg] = F(cpu);
            }
            else
            {
                F(cpu,cpu.state.A[Reg]);
            }
        }
    }
    static if(0x010b == Mode)
    {
        enum exWords = 0;
        void call(F)(CpuPtr cpu)
        {
            memProxy!F(cpu,cpu.state.A[Reg]);
        }
    }
    static if(0x011b == Mode)
    {
        enum exWords = 0;
        void call(F)(CpuPtr cpu)
        {
            memProxy!F(cpu,cpu.state.A[Reg]);
            cpu.state.A[Reg] += RegInc;
        }
    }
    static if(0x101b == Mode)
    {
        enum exWords = 1;
        void call(F)(CpuPtr cpu)
        {
            const address = cpu.state.A[Reg] + cpu.memory.getValue!short(cpu.state.PC - short.sizeof);
            memProxy!F(cpu,address);
        }
    }
}

@nogc:
void invalidImpl(CpuPtr)
{
    //TODO
    assert(false);
}

void nopImpl(CpuPtr)
{
    //TODO
}

void braBImpl(byte offset)(CpuPtr cpu)
{
    cpu.state.PC += offset;
}
void braImpl(T)(CpuPtr cpu)
{
    const offset = cpu.memory.getValue!T(cpu.state.PC - T.sizeof);
    cpu.state.PC += offset;
}

void tstImpl(CpuPtr cpu)
{
}