﻿module emul.m68k.instructions.lea;

import emul.m68k.instructions.common;

package nothrow:
void addLeaInstructions(ref Instruction[ushort] ret) pure
{
    //lea
    foreach(r; 0..8)
    {
        foreach(v; TupleRange!(0,readAddressModes.length))
        {
            enum mode = readAddressModes[v];
            if(addressModeTraits!mode.Control)
            {
                const instr = 0x41c0 | (r << 9) | mode;
                ret.addInstruction(Instruction("lea",cast(ushort)instr,0x2,&leaImpl!mode));
            }
        }
    }
}

private:
void leaImpl(ubyte Mode)(ref Cpu cpu)
{
    const reg = ((cpu.getInstructionData!ubyte(cpu.state.PC - 0x2) >> 1) & 0b111);
    addressMode!(uint,AddressModeType.ReadAddress,Mode,(ref cpu,val)
        {
            cpu.state.A[reg] = val;
        })(cpu);
}