module emul.m68k.instructions.addi;

import emul.m68k.instructions.common;

package pure nothrow:
void addAddiInstructions(ref Instruction[ushort] ret)
{
    //addi
    foreach(v; TupleRange!(0,writeAddressModesWSize.length))
    {
        enum mode = writeAddressModesWSize[v];
        static if(addressModeTraits!mode.Data && addressModeTraits!mode.Alterable)
        {
            alias Type = sizeField!(mode >> 6);
            enum dataSize = 0x2 + max(Type.sizeof,0x2);
            ret.addInstruction(Instruction("addi",0x0600 | mode,dataSize,&addiImpl!(Type,mode)));
        }
    }
}

private:
void addiImpl(Type,ubyte Mode)(CpuPtr cpu)
{
    const val = cpu.getMemValueNoHook!Type(cast(uint)(cpu.state.PC - Type.sizeof));
    addressModeWSize!(AddressModeType.ReadWriteDontExtendRegister,Mode,(cpu,b)
        {
            const result = add(val, b, cpu);
            return result;
        })(cpu);
}