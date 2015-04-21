module emul.m68k.instructions.lsllsr;

import emul.m68k.instructions.common;

package pure nothrow:
void addLslLsrInstructions(ref Instruction[ushort] ret)
{
    //rol ror
    foreach(dr; TupleRange!(0,2))
    {
        foreach(ir; TupleRange!(0,2))
        {
            foreach(size, Type; TypeTuple!(byte,short,int))
            {
                foreach(r; 0..8)
                {
                    foreach(c; 0..8)
                    {
                        const instr = 0xe008 | (c << 9) | (dr << 8) | (size << 6) | (ir << 5) | r;
                        ret.addInstruction(Instruction((0 == dr ? "lsr" : "lsl"),cast(ushort)instr,0x2,&lshiftImpl!(Type,dr,ir)));
                    }
                }
            }
        }
        
        foreach(v; TupleRange!(0,writeAddressModes.length))
        {
            enum mode = writeAddressModes[v];
            static if(addressModeTraits!mode.Memory && addressModeTraits!mode.Alterable)
            {
                enum instr = 0xe2c0 | (dr << 8) | mode;
                ret.addInstruction(Instruction((0 == dr ? "lsr" : "lsl"),instr,0x2,&lshiftmImpl!(dr,mode)));
            }
        }
    }
}

private:
void lshiftImpl(Type,ubyte dr,ubyte ir)(CpuPtr cpu)
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
            val >>>= (count - 1);
            cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != (val & 0x1));
            val >>>= 1;
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
    updateNZFlags(cpu,val);
    *(cast(Type*)&cpu.state.D[reg]) = cast(Type)val;
}

void lshiftmImpl(ubyte dr,ubyte Mode)(CpuPtr cpu)
{
    addressMode!(short,AddressModeType.ReadWrite,Mode,(cpu,val)
        {
            static if(0 == dr) //right
            {
                cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != (val & 0x1));
                const result = val >>> 1;
            }
            else
            {
                cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != (val & (1 << (short.sizeof * 8 - 1))));
                const result = val << 1;
            }
            cpu.state.clearFlags!(CCRFlags.V);
            updateNZFlags(cpu,val);
            return cast(short)result;
        })(cpu);
}