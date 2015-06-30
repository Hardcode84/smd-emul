module emul.m68k.instructions.movefromsr;

import emul.m68k.instructions.common;

package nothrow:
void addMovefromsrInstructions(ref Instruction[ushort] ret) pure
{
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
void movefromsrImpl(ubyte Mode)(ref Cpu cpu)
{
    addressMode!(ushort,AddressModeType.WriteDontExtendRegister,Mode,(ref cpu)
        {
            return cpu.state.SR;
        })(cpu);
}