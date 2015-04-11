module emul.cpu.instructions;

import std.array;
import std.bitmanip;
import std.algorithm;
import std.typetuple;
import std.range;

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

    //lea
    foreach(r; TupleRange!(0,8))
    {
        foreach(v; TupleRange!(0,readAddressModes.length))
        {
            enum mode = readAddressModes[v];
            if(addressModeTraits!mode.Control)
            {
                enum instr = 0x41c0 | (r << 9) | mode;
                ret.addInstruction(Instruction("lea",instr,0x2,&leaImpl!(r,mode)));
            }
        }
    }

    //movem
    foreach(s,T; TypeTuple!(short,int))
    {
        foreach(dr; TupleRange!(0,2))
        {
            enum Write = (0 == dr);
            static if(Write)
            {
                alias modes = writeAddressModes;
            }
            else
            {
                alias modes = readAddressModes;
            }
            foreach(v; TupleRange!(0,modes.length))
            {
                enum mode = modes[v];
                if(addressModeTraits!mode.Control ||
                    (Write && addressModeTraits!mode.Predecrement) ||
                    (!Write && addressModeTraits!mode.Postincrement))
                {
                    enum instr = 0x4880 | (dr << 10) | (s << 6) | mode;
                    ret.addInstruction(Instruction("movem",instr,0x4,&movemImpl!(dr,T,mode)));
                }
            }
        }
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

void leaImpl(ubyte reg, ubyte Mode)(CpuPtr cpu)
{
    addressMode!(int,false,Mode,(a,b)
        {
            a.state.A[reg] = b;
        })(cpu);
}

void movemImpl(ubyte dr, Type, ubyte mode)(CpuPtr cpu)
{
    import core.bitop;
    int*[16] regs = void;
    int** reg = regs.ptr;
    const uint mask = cpu.memory.getValue!ushort(cpu.state.PC - ushort.sizeof);
    const count = popcnt(mask);
    enum Write = (0 == dr);
    static if(Write)
    {
        auto func(CpuPtr cpu) { return cast(Type)(**(reg++)); }
    }
    else
    {
        void func(CpuPtr cpu, in Type val) { **(reg++) = val; }
    }
    static if(addressModeTraits!mode.Predecrement)
    {
        static immutable indices = iota(16).retro.array;
    }
    else
    {
        static immutable indices = iota(16).array;
    }
    int i = 0;
    foreach(ind;indices[])
    {
        if(0x0 != ((1 << ind) & mask))
        {
            regs[i] = &cpu.state.AllregsS[ind];
            ++i;
        }
    }
    addressMode!(Type,Write,mode,func)(cpu);
}