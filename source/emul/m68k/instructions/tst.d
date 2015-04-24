module emul.m68k.instructions.tst;

import emul.m68k.instructions.common;

package nothrow:
void addTstInstructions(ref Instruction[ushort] ret) pure
{
    //tst
    foreach(v; TupleRange!(0,readAddressModesWSize.length))
    {
        enum mode = readAddressModesWSize[v];
        ret.addInstruction(Instruction("tst",0x4a00 | mode,0x2,&tstImpl!mode));
    }
}

private:
void tstImpl(ubyte Mode)(CpuPtr cpu)
{
    addressModeWSize!(AddressModeType.Read,Mode,(a,b)
        {
            updateFlags(a,b);
        })(cpu);
}