module emul.m68k.instructions.cmpm;

import emul.m68k.instructions.common;
import emul.m68k.instructions.arith;

package nothrow:
void addCmpmInstructions(ref Instruction[ushort] ret) pure
{
    foreach(sz; TupleRange!(0,3))
    {
        foreach(rx; TupleRange!(0,8))
        {
            foreach(ry; TupleRange!(0,8))
            {
                const instr = 0xb108 | (rx << 9) | (sz << 6) | ry;
                ret.addInstruction(Instruction("cmpm",cast(ushort)instr,0x2,&cmpmImpl!(sz,rx,ry)));
            }
        }
    }
}

private:
void cmpmImpl(ubyte Sz, ubyte Ax, ubyte Ay)(ref Cpu cpu)
{
    alias Type = sizeField!(Sz);
    enum Modex = 0b011000 | Ax;
    enum Modey = 0b011000 | Ay;
    addressMode!(Type,AddressModeType.Read,Modex,(ref cpu,valx)
        {
            addressMode!(Type,AddressModeType.Read,Modey,(ref cpu,valy)
                {
                    cast(void)sub_no_x(valx, valy, cpu);
                })(cpu);
        })(cpu);
}