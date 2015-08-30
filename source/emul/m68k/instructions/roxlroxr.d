module emul.m68k.instructions.roxlroxr;

import emul.m68k.instructions.common;

package nothrow:
void addRoxlRoxrInstructions(ref Instruction[ushort] ret) pure
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
                        const instr = 0xe010 | (c << 9) | (dr << 8) | (size << 6) | (ir << 5) | r;
                        ret.addInstruction(Instruction((0 == dr ? "roxr" : "roxl"),cast(ushort)instr,0x2,&rotatexImpl!(Type,dr,ir)));
                    }
                }
            }
        }
        
        foreach(v; TupleRange!(0,writeAddressModes.length))
        {
            enum mode = writeAddressModes[v];
            static if(addressModeTraits!mode.Memory && addressModeTraits!mode.Alterable)
            {
                enum instr = 0xe4c0 | (dr << 8) | mode;
                ret.addInstruction(Instruction((0 == dr ? "roxr" : "roxl"),instr,0x2,&rotatexmImpl!(dr,mode)));
            }
        }
    }
}

private:
void rotatexImpl(Type,ubyte dr,ubyte ir)(ref Cpu cpu)
{
    const word = cpu.getMemValue!ushort(cpu.state.PC - 0x2);
    const cr = ((word >> 9) & 0b111);
    static if(0 == ir)
    {
        const count = (cr == 0 ? 8 : cr);
    }
    else
    {
        const count = cpu.state.D[cr] % 64;
    }
    const reg = (word & 0b111);
    auto val = cast(Type)cpu.state.D[reg];
    if(count > 0)
    {
        const ulong X = (cpu.state.testFlags!(CCRFlags.X) ? 1 : 0);
        static if(0 == dr) //right
        {
            const temp = (cast(ulong)val >> count) | (cast(ulong)val << (Type.sizeof * 8 - count + 1));
            const flag = (val >> (count - 1)) & 0x1;
            cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != flag);
            val = cast(Type)temp | cast(Type)(X << (Type.sizeof * 8 - (count % (Type.sizeof * 8))));
        }
        else
        {
            const temp = (cast(ulong)val << count) | (cast(ulong)val >> (Type.sizeof * 8 - count + 1));
            const flag = (val >> (Type.sizeof * 8 - count)) & 0x1;
            cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != flag);
            val = cast(Type)temp | cast(Type)(X << ((count - 1) % (Type.sizeof * 8)));
        }
    }
    else
    {
        cpu.state.setFlags!(CCRFlags.C)(cpu.state.testFlags!(CCRFlags.X));
    }
    cpu.state.clearFlags!(CCRFlags.V);
    cpu.state.setFlags!(CCRFlags.Z)(0 == val);
    cpu.state.setFlags!(CCRFlags.N)(0x0 != (val & (1 << (Type.sizeof * 8 - 1))));
    truncateReg!Type(cpu.state.D[reg]) = cast(Type)val;
}

void rotatexmImpl(ubyte dr,ubyte Mode)(ref Cpu cpu)
{
    addressMode!(ushort,AddressModeType.ReadWrite,Mode,(ref cpu,val)
        {
            static if(0 == dr) //right
            {
                const flag = (val & 0x1);
                const result = cast(ushort)(val >> 1) | cast(ushort)(cpu.state.testFlags!(CCRFlags.X) << (ushort.sizeof * 8 - 1));
                cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != flag);
            }
            else
            {
                const flag = ((val >> (ushort.sizeof * 8 - 1)) & 0x1);
                const result = cast(ushort)(val << 1) | cast(ushort)(cpu.state.testFlags!(CCRFlags.X) & 0x1);
                cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != flag);
            }
            cpu.state.clearFlags!(CCRFlags.V);
            cpu.state.setFlags!(CCRFlags.Z)(0 == val);
            cpu.state.setFlags!(CCRFlags.N)(0x0 != (val & (1 << (ushort.sizeof * 8 - 1))));
            return cast(ushort)result;
        })(cpu);
}