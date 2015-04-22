module emul.m68k.instructions.aslasr;

import emul.m68k.instructions.common;

package pure nothrow:
void addAslAsrInstructions(ref Instruction[ushort] ret)
{
    foreach(dr; TupleRange!(0,2))
    {
        foreach(ir; TupleRange!(0,2))
        {
            foreach(size, Type; TypeTuple!(ubyte,ushort,uint))
            {
                foreach(r; 0..8)
                {
                    foreach(c; 0..8)
                    {
                        const instr = 0xe000 | (c << 9) | (dr << 8) | (size << 6) | (ir << 5) | r;
                        ret.addInstruction(Instruction((0 == dr ? "asr" : "asl"),cast(ushort)instr,0x2,&ashiftImpl!(Type,dr,ir)));
                    }
                }
            }
        }
        
        foreach(v; TupleRange!(0,writeAddressModes.length))
        {
            enum mode = writeAddressModes[v];
            static if(addressModeTraits!mode.Memory && addressModeTraits!mode.Alterable)
            {
                enum instr = 0xe0c0 | (dr << 8) | mode;
                ret.addInstruction(Instruction((0 == dr ? "asr" : "asl"),instr,0x2,&ashiftmImpl!(dr,mode)));
            }
        }
    }
}

private:
void ashiftImpl(Type,ubyte dr,ubyte ir)(CpuPtr cpu)
{
    const word = cpu.getMemValue!ushort(cpu.state.PC - 0x2);
    const cr = ((word >> 9) & 0b111);
    static if(0 == ir)
    {
        const count = (cr == 0 ? 8 : cr);
    }
    else
    {
        const count = cpu.state.D[cr] % 32;
    }
    const reg = (word & 0b111);
    auto val = cast(Type)cpu.state.D[reg];
    if(count > 0)
    {
        static if(0 == dr) //right
        {
            val >>= (count - 1);
            cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != (val & 0x1));
            val >>= 1;
        }
        else
        {
            val <<= (count - 1);
            cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != (val & (1 << (Type.sizeof * 8 - 1))));
            val <<= 1;
        }
    }
    else
    {
        cpu.state.clearFlags!(CCRFlags.C);
    }
    cpu.state.clearFlags!(CCRFlags.V);
    cpu.state.setFlags!(CCRFlags.Z)(0 == val);
    cpu.state.setFlags!(CCRFlags.N)(0x0 != (val & (1 << (Type.sizeof * 8 - 1))));
    truncateReg!Type(cpu.state.D[reg]) = cast(Type)val;
}

void ashiftmImpl(ubyte dr,ubyte Mode)(CpuPtr cpu)
{
    addressMode!(ushort,AddressModeType.ReadWrite,Mode,(cpu,val)
        {
            static if(0 == dr) //right
            {
                cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != (val & 0x1));
                const result = val >> 1;
            }
            else
            {
                cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != (val & (1 << (ushort.sizeof * 8 - 1))));
                const result = val << 1;
            }
            cpu.state.clearFlags!(CCRFlags.V);
            cpu.state.setFlags!(CCRFlags.Z)(0 == val);
            cpu.state.setFlags!(CCRFlags.N)(0x0 != (val & (1 << (ushort.sizeof * 8 - 1))));
            return cast(ushort)result;
        })(cpu);
}