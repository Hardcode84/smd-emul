module emul.m68k.instructions.create;

package import std.array;
package import std.bitmanip;
package import std.algorithm;
package import std.typetuple;
package import std.range;
package import std.traits;

package import gamelib.util;

package import emul.m68k.cpu;
package import emul.m68k.addressmodes;
package import emul.m68k.conditional;

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

    import emul.m68k.instructions.bra;
    addBraInstructions(ret);

    import emul.m68k.instructions.bsr;
    addBsrInstructions(ret);

    import emul.m68k.instructions.bcc;
    addBccInstructions(ret);


    import emul.m68k.instructions.tst;
    addTstInstructions(ret);

    import emul.m68k.instructions.lea;
    addLeaInstructions(ret);


    import emul.m68k.instructions.movem;
    addMovemInstructions(ret);

    import emul.m68k.instructions.moveq;
    addMoveqInstructions(ret);

    import emul.m68k.instructions.movea;
    addMoveaInstructions(ret);

    import emul.m68k.instructions.moveusp;
    addMoveuspInstructions(ret);

    import emul.m68k.instructions.movetosr;
    addMovetosrInstructions(ret);

    import emul.m68k.instructions.move;
    addMoveInstructions(ret);


    import emul.m68k.instructions.andi;
    addAndiInstructions(ret);

    import emul.m68k.instructions.add;
    addAddInstructions(ret);

    import emul.m68k.instructions.mul;
    addAddMulInstructions(ret);

    import emul.m68k.instructions.dbcc;
    addDbccInstructions(ret);

    import emul.m68k.instructions.btst;
    addBtstInstructions(ret);


    import emul.m68k.instructions.jmp;
    addJmpInstructions(ret);

    import emul.m68k.instructions.jsr;
    addJsrInstructions(ret);

    import emul.m68k.instructions.rts;
    addRtsInstructions(ret);


    import emul.m68k.instructions.clr;
    addClrInstructions(ret);

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
    if((ind in instructions) !is null)
    {
        import gamelib.debugout;
        debugOut(instr);
        debugOut(instructions[ind]);
    }
    assert(null == (ind in instructions),instr.name);
    instructions[ind] = instr;
}

@nogc:

void updateNZFlags(T)(CpuPtr cpu, in T val)
{
    if(val < 0) cpu.state.setFlags(CCRFlags.N);
    else        cpu.state.clearFlags(CCRFlags.N);
    if(val == 0) cpu.state.setFlags(CCRFlags.Z);
    else         cpu.state.clearFlags(CCRFlags.Z);
}

void updateFlags(T)(CpuPtr cpu, in T val)
{
    updateNZFlags(cpu, val);
    cpu.state.clearFlags(CCRFlags.V | CCRFlags.C);
}

T add(T)(in T x, in T y, CpuPtr cpu)
{
    const r1 = cast(long)x + cast(long)y;
    cpu.state.setFlags(CCRFlags.V, (r1 < Signed!T.min || r1 > Signed!T.max));
    const r2 = cast(Unsigned!T)x + cast(Unsigned!T)y;
    cpu.state.setFlags(CCRFlags.C | CCRFlags.X, (r2 < int.min || r2 > int.max));
    cast(void)r2;
    updateNZFlags(cpu, cast(T)r1);
    return cast(T)r1;
}

T sub(T)(in T x, in T y, CpuPtr cpu)
{
    const r1 = cast(long)x - cast(long)y;
    cpu.state.setFlags(CCRFlags.V, (r1 < Signed!T.min || r1 > Signed!T.max));
    cpu.state.setFlags(CCRFlags.C | CCRFlags.X, (cast(Unsigned!T)x < cast(Unsigned!T)y));
    updateNZFlags(cpu, cast(T)r1);
    return cast(T)r1;
}

T mul(T)(in T x, in T y, CpuPtr cpu)
{
    const r1 = cast(long)x * cast(long)y;
    cpu.state.setFlags(CCRFlags.V, (r1 < Signed!T.min || r1 > Signed!T.max));
    cpu.state.clearFlags(CCRFlags.C);
    updateNZFlags(cpu, cast(T)r1);
    return cast(T)r1;
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