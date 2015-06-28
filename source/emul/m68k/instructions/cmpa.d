module emul.m68k.instructions.cmpa;

import emul.m68k.instructions.common;
import emul.m68k.instructions.arith;

package nothrow:
void addCmpaInstructions(ref Instruction[ushort] ret) pure
{
    foreach(v; TupleRange!(0,readAddressModes.length))
    {
        enum mode = readAddressModes[v];
        foreach(Type; TypeTuple!(short,int))
        {
            static if(is(Type == short)) enum opm = 0b011;
            else enum opm = 0b111;
            foreach(r; TupleRange!(0,8))
            {
                const instr = 0xb000 | (r << 9) | (opm << 6) | mode;
                ret.addInstruction(Instruction("cmpa",cast(ushort)instr,0x2,&cmpaImpl!(Type,r,mode)));
            }
        }
    }
}

private:
void cmpaImpl(Type,ubyte Reg,ubyte Mode)(ref Cpu cpu)
{
    addressMode!(Type,AddressModeType.Read,Mode,(ref cpu,val)
        {
            cast(void)sub_no_x(cast(int)cpu.state.A[Reg], val, cpu);
        })(cpu);
}