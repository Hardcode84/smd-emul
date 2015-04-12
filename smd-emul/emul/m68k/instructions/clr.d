module emul.m68k.instructions.clr;

import emul.m68k.instructions.create;

package pure nothrow:
void addClrInstructions(ref Instruction[ushort] ret)
{
    //clr
    foreach(v; TupleRange!(0,writeAddressModesWSize.length))
    {
        enum mode = writeAddressModesWSize[v];
        static if(addressModeTraits!mode.Data && addressModeTraits!mode.Alterable)
        {
            ret.addInstruction(Instruction("clr",0x4200 | mode,0x2,&clrImpl!mode));
        }
    }
}

private:
void clrImpl(ubyte Mode)(CpuPtr cpu)
{
    addressModeWSize!(AddressModeType.Write,Mode,(cpu)
        {
            cpu.state.clearFlags(CCRFlags.N | CCRFlags.V | CCRFlags.C);
            cpu.state.setFlags(CCRFlags.Z);
            return cast(sizeField!(Mode >> 6))0;
        })(cpu);
}