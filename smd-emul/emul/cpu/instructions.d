module emul.cpu.instructions;

import std.bitmanip;
import std.algorithm;

import gamelib.util;

import emul.cpu.cpu;
import emul.cpu.addressmodes;
import emul.cpu.conditional;

struct Instruction
{
    string name;
    ushort opcode;
    ushort size;
    void function(CpuPtr) @nogc pure nothrow impl;
}

enum InvalidInstruction = Instruction("invalid",0x0,0x2,&invalidImpl);
enum Instructions = initInstructions();
pragma(msg,Instructions.length);

private pure nothrow:
void addInstruction(ref Instruction[ushort] instructions, in Instruction instr)
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
    assert(null == (ind in instructions));
    instructions[ind] = instr;
}

auto initInstructions()
{
    Instruction[ushort] ret;

    // nop
    ret.addInstruction(Instruction("nop",0x4e71,0x2,&nopImpl));

    //bra
    foreach(i;TupleRange!(0x1,0xfe))
    {
        ret.addInstruction(Instruction("bra",0x6000 | i,0x2,&braBImpl!(cast(byte)i)));
    }
    ret.addInstruction(Instruction("bra",0x6000,0x4,&braImpl!short));
    ret.addInstruction(Instruction("bra",0x60ff,0x6,&braImpl!int));

    //bcc
    foreach(v; TupleRange!(0,conditionalTestsBcc.length))
    {
        enum cond = conditionalTestsBcc[v];
        enum instr = 0x6000 | (cast(ushort)cond << 8);
        foreach(i;TupleRange!(0x1,0xfe))
        {
            ret.addInstruction(Instruction("bcc",instr | i,0x2,&bccBImpl!(cond,cast(byte)i)));
        }
        ret.addInstruction(Instruction("bcc",instr | 0x00,0x4,&bccImpl!(cond,short)));
        ret.addInstruction(Instruction("bcc",instr | 0xff,0x6,&bccImpl!(cond,int)));
    }

    //tst
    foreach(v; TupleRange!(0,readAddressModesWSize.length))
    {
        enum mode = readAddressModesWSize[v];
        ret.addInstruction(Instruction("tst",0x4a00 | mode,0x2,&tstImpl!mode));
    }
    return ret;
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

void bccBImpl(ubyte condition,byte offset)(CpuPtr cpu)
{
    if(conditionalTest!condition(cpu))
    {
        cpu.state.PC += offset;
    }
}
void bccImpl(ubyte condition,T)(CpuPtr cpu)
{
    if(conditionalTest!condition(cpu))
    {
        const offset = cpu.memory.getValue!T(cpu.state.PC - T.sizeof);
        cpu.state.PC += offset;
    }
}

void tstImpl(ubyte Mode)(CpuPtr cpu)
{
    addressModeWSize!(false,Mode,(a,b)
        {
            if(b < 0) a.state.setFlags(CCRFlags.N);
            else a.state.clearFlags(CCRFlags.N);
            if(b == 0) a.state.setFlags(CCRFlags.Z);
            else a.state.clearFlags(CCRFlags.Z);
            a.state.clearFlags(CCRFlags.V | CCRFlags.C);
        })(cpu);
}
