module emul.m68k.instructions.neg;

import emul.m68k.instructions.common;
import emul.m68k.instructions.arith;

package nothrow:
void addNegInstructions(ref Instruction[ushort] ret) pure
{
    foreach(v; TupleRange!(0,writeAddressModesWSize.length))
    {
        enum mode = writeAddressModesWSize[v];
        static if(addressModeTraits!mode.Data && addressModeTraits!mode.Alterable)
        {
            ret.addInstruction(Instruction("neg",0x4400 | mode,0x2,&negImpl!mode));
        }
    }
}

private:
void negImpl(ubyte Mode)(CpuPtr cpu)
{
    alias Type = sizeField!(Mode >> 6);
    addressModeWSize!(AddressModeType.ReadWriteDontExtendRegister,Mode,(cpu,val)
        {
            return sub(cast(Type)0,val,cpu);
        })(cpu);
}