module emul.m68k.instructions.addi;

import emul.m68k.instructions.create;

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
    addressModeWSize!(AddressModeType.Read,Mode,(cpu,b)
        {
            addressModeWSize!(AddressModeType.WriteDontExtendRegister,Mode,(cpu)
                {
                    const result = add(val, b, cpu);
                    updateFlags(cpu,result);
                    return cast(Type)result;
                })(cpu);
        })(cpu);
}