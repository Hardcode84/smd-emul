﻿module emul.m68k.instructions.movefromsr;

import emul.m68k.instructions.common;

package pure nothrow:
void addMovefromsrInstructions(ref Instruction[ushort] ret)
{
    //move to sr
    foreach(v; TupleRange!(0,writeAddressModes.length))
    {
        enum mode = writeAddressModes[v];
        static if(addressModeTraits!mode.Data && addressModeTraits!mode.Alterable)
        {
            ret.addInstruction(Instruction("move from sr",0x40c0 | mode,0x2,&movefromsrImpl!mode));
        }
    }
}

private:
void movefromsrImpl(ubyte Mode)(CpuPtr cpu)
{
    addressMode!(ushort,AddressModeType.WriteDontExtendRegister,Mode,(cpu)
        {
            return cpu.state.SR;
        })(cpu);
}