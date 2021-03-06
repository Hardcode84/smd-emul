﻿module emul.m68k.instructions.aslasr;

import emul.m68k.instructions.common;

package nothrow:
void addAslAsrInstructions(ref Instruction[ushort] ret) pure
{
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
void ashiftImpl(Type,ubyte dr,ubyte ir)(ref Cpu cpu)
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

    enum msbMask = (1 << (Type.sizeof * 8 - 1));
    if(count > 0)
    {
        const oldVal = val;
        static if(0 == dr) //right
        {
            if(count <= (Type.sizeof * 8))
            {
                val >>= (count - 1);
                cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != (val & 0x1));
                val >>= 1;
            }
            else
            {
                val >>= (Type.sizeof * 8 - 1);
                cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != (val & 0x1));
            }
            cpu.state.clearFlags!(CCRFlags.V);
        }
        else
        {
            if(count <= (Type.sizeof * 8))
            {
                val <<= (count - 1);
                cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != (val & msbMask));
                val <<= 1;
            }
            else
            {
                val = 0;
                cpu.state.clearFlags!(CCRFlags.C|CCRFlags.X);
            }
            bool changed = false;
            foreach(i; 0..min(count,Type.sizeof * 8))
            {
                if(0 != (((oldVal << (i + 1)) ^ oldVal) & msbMask))
                {
                    changed = true;
                    break;
                }
            }
            cpu.state.setFlags!(CCRFlags.V)(changed);
        }
    }
    else
    {
        cpu.state.clearFlags!(CCRFlags.C | CCRFlags.V);
    }

    cpu.state.setFlags!(CCRFlags.Z)(0 == val);
    cpu.state.setFlags!(CCRFlags.N)(0x0 != (val & msbMask));
    truncateReg!Type(cpu.state.D[reg]) = cast(Type)val;
}

void ashiftmImpl(ubyte dr,ubyte Mode)(ref Cpu cpu)
{
    alias Type = short;
    enum msbMask = (1 << (Type.sizeof * 8 - 1));
    addressMode!(Type,AddressModeType.ReadWrite,Mode,(ref cpu,val)
        {
            static if(0 == dr) //right
            {
                cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != (val & 0x1));
                const result = val >> 1;
                cpu.state.clearFlags!(CCRFlags.V);
            }
            else
            {
                cpu.state.setFlags!(CCRFlags.C|CCRFlags.X)(0x0 != (val & msbMask));
                const result = val << 1;
                cpu.state.setFlags!(CCRFlags.V)(0 != ((val ^ result) & msbMask));
            }
            cpu.state.setFlags!(CCRFlags.Z)(0 == val);
            cpu.state.setFlags!(CCRFlags.N)(0x0 != (val & msbMask));
            return cast(ushort)result;
        })(cpu);
}