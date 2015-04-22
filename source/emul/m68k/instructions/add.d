module emul.m68k.instructions.add;

import emul.m68k.instructions.common;

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
                foreach(r; 0..8)
                {
                    const instr = 0xd000 | (r << 9) | (d << 8) | mode;
                    ret.addInstruction(Instruction("add", cast(ushort)instr,0x2,&addImpl!(d,mode)));
                }
            }
        }
    }
}

private:
void addImpl(ubyte d,ubyte Mode)(CpuPtr cpu)
{
    alias Type = sizeField!(Mode >> 6);
    const reg = (cpu.getMemValueNoHook!ubyte(cpu.state.PC - 0x2) >> 1) & 0b111;
    const val = cast(Type)cpu.state.D[reg];
    static if(0 == d)
    {
        addressModeWSize!(AddressModeType.Read,Mode,(cpu,b)
            {
                *(cast(Type*)&cpu.state.D[reg]) = add(val, b, cpu);
            })(cpu);
    }
    else
    {
        addressModeWSize!(AddressModeType.ReadWriteDontExtendRegister,Mode,(cpu,b)
            {
                return add(val, b, cpu);
            })(cpu);
    }
}