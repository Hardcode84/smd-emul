module emul.cpu.instructions.create;

package import std.array;
package import std.bitmanip;
package import std.algorithm;
package import std.typetuple;
package import std.range;

package import gamelib.util;

package import emul.cpu.cpu;
package import emul.cpu.addressmodes;
package import emul.cpu.conditional;

struct Instruction
{
    string name;
    ushort opcode;
    ushort size;
    void function(CpuPtr) @nogc pure nothrow impl;
}

enum InvalidInstruction = Instruction("invalid",0x0,0x2,&invalidImpl);

pure nothrow:
auto createInstructions()
{
    Instruction[ushort] ret;

    // nop
    ret.addInstruction(Instruction("nop",0x4e71,0x2,&nopImpl));

    import emul.cpu.instructions.bra;
    addBraInstructions(ret);

    import emul.cpu.instructions.bcc;
    addBccInstructions(ret);

    import emul.cpu.instructions.tst;
    addTstInstructions(ret);

    import emul.cpu.instructions.lea;
    addLeaInstructions(ret);

    import emul.cpu.instructions.movem;
    addMovemInstructions(ret);

    import emul.cpu.instructions.move;
    addMoveInstructions(ret);

    import emul.cpu.instructions.andi;
    addAndiInstructions(ret);

    return ret;
}

package:
void addInstruction(ref Instruction[ushort] instructions, in Instruction instr) @safe
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
    //assert(ind != 0);
    assert(null == (ind in instructions));
    instructions[ind] = instr;
}

@nogc:

void updateFlags(T)(CpuPtr cpu, in T val)
{
    if(val < 0) cpu.state.setFlags(CCRFlags.N);
    else        cpu.state.clearFlags(CCRFlags.N);
    if(val == 0) cpu.state.setFlags(CCRFlags.Z);
    else         cpu.state.clearFlags(CCRFlags.Z);
    cpu.state.clearFlags(CCRFlags.V | CCRFlags.C);
}

void invalidImpl(CpuPtr)
{
    //TODO
    assert(false);
}

void nopImpl(CpuPtr)
{
    //TODO
}