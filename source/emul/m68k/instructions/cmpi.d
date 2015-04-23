module emul.m68k.instructions.cmpi;

import emul.m68k.instructions.common;

package pure nothrow:
void addCmpiInstructions(ref Instruction[ushort] ret)
{
    foreach(v; TupleRange!(0,readAddressModesWSize.length))
    {
        enum mode = readAddressModesWSize[v];
        static if(addressModeTraits!mode.Data)
        {
            alias Type = sizeField!(mode >> 6);
            enum dataSize = 0x2 + max(Type.sizeof,0x2);
            const instr = 0x0c00 | mode;
            ret.addInstruction(Instruction("cmpi",cast(ushort)instr,dataSize,&cmpiImpl!mode));
        }
    }
}

private:
void cmpiImpl(ubyte Mode)(CpuPtr cpu)
{
    alias Type = sizeField!(Mode >> 6);
    const vali = cpu.getMemValueNoHook!Type(cast(uint)(cpu.state.PC - Type.sizeof));
    addressModeWSize!(AddressModeType.Read,Mode,(cpu,val)
        {
            cast(void)sub(val, vali, cpu);
        })(cpu);
}