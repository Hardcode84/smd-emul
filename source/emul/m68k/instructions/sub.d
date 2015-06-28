module emul.m68k.instructions.sub;

import emul.m68k.instructions.common;
import emul.m68k.instructions.arith;

package nothrow:
void addSubInstructions(ref Instruction[ushort] ret) pure
{
    //sub
    foreach(v; TupleRange!(0,readAddressModesWSize.length))
    {
        enum mode = readAddressModesWSize[v];
        foreach(d; TupleRange!(0,2))
        {
            static if(0 == d || addressModeTraits!mode.Alterable)
            {
                foreach(r; 0..8)
                {
                    const instr = 0x9000 | (r << 9) | (d << 8) | mode;
                    ret.addInstruction(Instruction("sub", cast(ushort)instr,0x2,&subImpl!(d,mode)));
                }
            }
        }
    }
}

private:
void subImpl(ubyte d,ubyte Mode)(ref Cpu cpu)
{
    alias Type = sizeField!(Mode >> 6);
    const reg = (cpu.getInstructionData!ubyte(cpu.state.PC - 0x2) >> 1) & 0b111;
    const val = cast(Type)cpu.state.D[reg];
    static if(0 == d)
    {
        addressModeWSize!(AddressModeType.Read,Mode,(ref cpu,b)
            {
                truncateReg!Type(cpu.state.D[reg]) = sub(val, b, cpu);
            })(cpu);
    }
    else
    {
        addressModeWSize!(AddressModeType.ReadWriteDontExtendRegister,Mode,(ref cpu,b)
            {
                return sub(val, b, cpu);
            })(cpu);
    }
}