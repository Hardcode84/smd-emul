module emul.m68k.instructions.subx;

import emul.m68k.instructions.common;
import emul.m68k.instructions.arith;

package nothrow:
void addSubxInstructions(ref Instruction[ushort] ret) pure
{
    foreach(rx;TupleRange!(0,8))
    {
        foreach(ry;TupleRange!(0,8))
        {
            foreach(sz; TupleRange!(0,3))
            {
                alias Type = sizeField!sz;
                foreach(isMem; TupleRange!(0,2))
                {
                    const instr = 0x9100 | (rx << 9) | (sz << 6) | (isMem << 3) | (ry);
                    ret.addInstruction(Instruction("subx", cast(ushort)instr,0x2,&subxImpl!(rx,ry,Type,1 == isMem)));
                }
            }
        }
    }
}

private:
void subxImpl(ubyte rx,ubyte ry,Type,bool isMem)(ref Cpu cpu)
{
    static if(isMem)
    {
        enum DestMode = 0b100_000 | rx;
        enum SrcMode  = 0b100_000 | ry;
        addressMode!(Type,AddressModeType.Read,SrcMode,(ref cpu,srcval)
            {
                addressMode!(Type,AddressModeType.ReadWrite,DestMode,(ref cpu,destval)
                    {
                        return subx(destval,srcval,cpu);
                    })(cpu);
            })(cpu);
    }
    else
    {
        const srcval  = truncateReg!Type(cpu.state.D[ry]);
        const destval = truncateReg!Type(cpu.state.D[rx]);
        truncateReg!Type(cpu.state.D[rx]) = subx(destval,srcval,cpu);
    }
}