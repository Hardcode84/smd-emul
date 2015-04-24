module emul.m68k.instructions.rolror;

import emul.m68k.instructions.common;

package nothrow:
void addRolRorInstructions(ref Instruction[ushort] ret) pure
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
                        const instr = 0xe018 | (c << 9) | (dr << 8) | (size << 6) | (ir << 5) | r;
                        ret.addInstruction(Instruction((0 == dr ? "ror" : "rol"),cast(ushort)instr,0x2,&rotateImpl!(Type,dr,ir)));
                    }
                }
            }
        }

        foreach(v; TupleRange!(0,writeAddressModes.length))
        {
            enum mode = writeAddressModes[v];
            static if(addressModeTraits!mode.Memory && addressModeTraits!mode.Alterable)
            {
                enum instr = 0xe6c0 | (dr << 8) | mode;
                ret.addInstruction(Instruction((0 == dr ? "ror" : "rol"),instr,0x2,&rotatemImpl!(dr,mode)));
            }
        }
    }
}

private:
void rotateImpl(Type,ubyte dr,ubyte ir)(CpuPtr cpu)
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
            val = cast(Type)(val >> count) | cast(Type)(val << (Type.sizeof * 8 - count));
            cpu.state.setFlags!(CCRFlags.C)(0x0 != (val & (1 << (Type.sizeof * 8 - 1))));
        }
        else
        {
            val = cast(Type)(val << count) | cast(Type)(val >> (Type.sizeof * 8 - count));
            cpu.state.setFlags!(CCRFlags.C)(0x0 != (val & 0x1));
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

void rotatemImpl(ubyte dr,ubyte Mode)(CpuPtr cpu)
{
    addressMode!(ushort,AddressModeType.ReadWrite,Mode,(cpu,val)
        {
            static if(0 == dr) //right
            {
                const result = cast(ushort)(val >> 1) | cast(ushort)(val << (ushort.sizeof * 8 - 1));
                cpu.state.setFlags!(CCRFlags.C)(0x0 != (val & (1 << (ushort.sizeof * 8 - 1))));
            }
            else
            {
                const result = cast(ushort)(val << 1) | cast(ushort)(val >> (ushort.sizeof * 8 - 1));
                cpu.state.setFlags!(CCRFlags.C)(0x0 != (val & 0x1));
            }
            cpu.state.clearFlags!(CCRFlags.V);
            cpu.state.setFlags!(CCRFlags.Z)(0 == val);
            cpu.state.setFlags!(CCRFlags.N)(0x0 != (val & (1 << (ushort.sizeof * 8 - 1))));
            return cast(ushort)result;
        })(cpu);
}