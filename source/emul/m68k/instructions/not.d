module emul.m68k.instructions.not;

import emul.m68k.instructions.common;

package nothrow:
void addNotInstructions(ref Instruction[ushort] ret) pure
{
    foreach(v; TupleRange!(0,writeAddressModesWSize.length))
    {
        enum mode = writeAddressModesWSize[v];
        static if(addressModeTraits!mode.Data && addressModeTraits!mode.Alterable)
        {
            ret.addInstruction(Instruction("not",0x4600 | mode,0x2,&notImpl!mode));
        }
    }
}

private:
void notImpl(ubyte Mode)(ref Cpu cpu)
{
    addressModeWSize!(AddressModeType.ReadWriteDontExtendRegister,Mode,(ref cpu,val)
        {
            const res = ~val;
            updateFlags(cpu,res);
            return res;
        })(cpu);
}