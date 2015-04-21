module emul.m68k.instructions.ori;

import emul.m68k.instructions.common;

package pure nothrow:
void addOriInstructions(ref Instruction[ushort] ret)
{
    //ori
    foreach(v; TupleRange!(0,writeAddressModesWSize.length))
    {
        enum mode = writeAddressModesWSize[v];
        static if(addressModeTraits!mode.Data && addressModeTraits!mode.Alterable)
        {
            alias Type = sizeField!(mode >> 6);
            enum dataSize = 0x2 + max(Type.sizeof,0x2);
            ret.addInstruction(Instruction("oru",0x0000 | mode,dataSize,&oriImpl!(Type,mode)));
        }
    }
}

private:
void oriImpl(Type,ubyte Mode)(CpuPtr cpu)
{
    const val = cpu.getMemValueNoHook!Type(cast(uint)(cpu.state.PC - Type.sizeof));
    addressModeWSize!(AddressModeType.ReadWriteDontExtendRegister,Mode,(cpu,b)
        {
            const result = cast(Type)(val | b);
            updateFlags(cpu,result);
            return result;
        })(cpu);
}