module emul.m68k.instructions.common;

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
    void function(CpuPtr) @nogc nothrow impl;
}

package pure nothrow @safe:
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
    static assert(isSigned!T);
    if(val < 0) cpu.state.setFlags!(CCRFlags.N);
    else        cpu.state.clearFlags!(CCRFlags.N);
    if(val == 0) cpu.state.setFlags!(CCRFlags.Z);
    else         cpu.state.clearFlags!(CCRFlags.Z);
}

void updateFlags(T)(CpuPtr cpu, in T val)
{
    updateNZFlags(cpu, val);
    cpu.state.clearFlags!(CCRFlags.V | CCRFlags.C);
}
