module emul.m68k.instructions.eori;

import emul.m68k.instructions.common;

package nothrow:
void addEoriInstructions(ref Instruction[ushort] ret) pure
{
    foreach(v; TupleRange!(0,writeAddressModesWSize.length))
    {
        enum mode = writeAddressModesWSize[v];
        static if(addressModeTraits!mode.Data && addressModeTraits!mode.Alterable)
        {
            alias Type = sizeField!(mode >> 6);
            enum dataSize = 0x2 + max(Type.sizeof,0x2);
            ret.addInstruction(Instruction("eori",0x0a00 | mode,dataSize,&eoriImpl!(Type,mode)));
        }
    }
}

private:
void eoriImpl(Type,ubyte Mode)(ref Cpu cpu)
{
    const val = cpu.getInstructionData!Type(cast(uint)(cpu.state.PC - Type.sizeof));
    addressModeWSize!(AddressModeType.ReadWriteDontExtendRegister,Mode,(ref cpu,b)
        {
            const result = cast(Type)(val ^ b);
            updateFlags(cpu,result);
            return result;
        })(cpu);
}