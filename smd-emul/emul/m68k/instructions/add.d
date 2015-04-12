module emul.m68k.instructions.add;

import emul.m68k.instructions.create;

package pure nothrow:
void addAddInstructions(ref Instruction[ushort] ret)
{
    //add
    foreach(v; TupleRange!(0,readAddressModesWSize.length))
    {
        enum mode = readAddressModesWSize[v];
        foreach(d; TupleRange!(0,2))
        {
            static if(0 == d || addressModeTraits!mode.Alterable)
            {
                alias Type = sizeField!(mode >> 6);
                foreach(r; 0..8)
                {
                    const instr = 0xd000 | (r << 9) | (d << 8) | mode;
                    ret.addInstruction(Instruction("add", cast(ushort)instr,0x2,&addImpl!(Type,d,mode)));
                }
            }
        }
    }
}

private:
void addImpl(Type,ubyte d,ubyte Mode)(CpuPtr cpu)
{
    const reg = (cpu.memory.getValue!ubyte(cpu.state.PC - 0x2) >> 2) & 0b111;
    const int val = cpu.state.D[reg];
    addressModeWSize!(AddressModeType.Read,Mode,(cpu,b)
        {
            const result = add(val, b, cpu);
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