module emul.m68k.instructions.or;

import emul.m68k.instructions.create;

package pure nothrow:
void addOrInstructions(ref Instruction[ushort] ret)
{
    //add
    foreach(v; TupleRange!(0,readAddressModesWSize.length))
    {
        enum mode = readAddressModesWSize[v];
        foreach(d; TupleRange!(0,2))
        {
            static if((0 == d && addressModeTraits!mode.Data) || addressModeTraits!mode.Alterable)
            {
                alias Type = sizeField!(mode >> 6);
                foreach(r; 0..8)
                {
                    const instr = 0x8000 | (r << 9) | (d << 8) | mode;
                    ret.addInstruction(Instruction("or", cast(ushort)instr,0x2,&orImpl!(Type,d,mode)));
                }
            }
        }
    }
}

private:
void orImpl(Type,ubyte d,ubyte Mode)(CpuPtr cpu)
{
    const reg = (cpu.getMemValue!ubyte(cpu.state.PC - 0x2) >> 2) & 0b111;
    const int val = cpu.state.D[reg];
    addressModeWSize!(AddressModeType.Read,Mode,(cpu,b)
        {
            const result = val | b;
            updateFlags(cpu,result);
            static if(0 == d)
            {
                cpu.state.D[reg] = result;
            }
            else
            {
                addressModeWSize!(AddressModeType.Write,Mode,(cpu)
                    {
                        return cast(Type)result;
                    })(cpu);
            }
        })(cpu);
}