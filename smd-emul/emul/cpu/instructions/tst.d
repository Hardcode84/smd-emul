module emul.cpu.instructions.tst;

import emul.cpu.instructions.create;

package pure nothrow:
void addTstInstructions(ref Instruction[ushort] ret)
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
    addressModeWSize!(false,Mode,(a,b)
        {
            updateFlags(a,b);
        })(cpu);
}