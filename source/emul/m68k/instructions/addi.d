module emul.m68k.instructions.addi;

import emul.m68k.instructions.common;
import emul.m68k.instructions.arith;

package nothrow:
void addAddiInstructions(ref Instruction[ushort] ret) pure
{
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
void addiImpl(Type,ubyte Mode)(ref Cpu cpu)
{
    const val = cpu.getInstructionData!Type(cast(uint)(cpu.state.PC - Type.sizeof));
    addressModeWSize!(AddressModeType.ReadWriteDontExtendRegister,Mode,(ref cpu,b)
        {
            const result = add(val, b, cpu);
            return result;
        })(cpu);
}