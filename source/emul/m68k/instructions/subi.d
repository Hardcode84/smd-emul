module emul.m68k.instructions.subi;

import emul.m68k.instructions.common;
import emul.m68k.instructions.arith;

package nothrow:
void addSubiInstructions(ref Instruction[ushort] ret) pure
{
    foreach(v; TupleRange!(0,writeAddressModesWSize.length))
    {
        enum mode = writeAddressModesWSize[v];
        static if(addressModeTraits!mode.Data && addressModeTraits!mode.Alterable)
        {
            alias Type = sizeField!(mode >> 6);
            enum dataSize = 0x2 + max(Type.sizeof,0x2);
            ret.addInstruction(Instruction("subi",0x0400 | mode,dataSize,&subiImpl!(Type,mode)));
        }
    }
}

private:
void subiImpl(Type,ubyte Mode)(ref Cpu cpu)
{
    const val = cpu.getInstructionData!Type(cast(uint)(cpu.state.PC - Type.sizeof));
    addressModeWSize!(AddressModeType.ReadWriteDontExtendRegister,Mode,(ref cpu,b)
        {
            const result = sub(val, b, cpu);
            return result;
        })(cpu);
}