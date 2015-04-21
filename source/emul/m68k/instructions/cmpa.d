module emul.m68k.instructions.cmpa;

import emul.m68k.instructions.common;

package pure nothrow:
void addCmpaInstructions(ref Instruction[ushort] ret)
{
    //cmpa
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
void cmpaImpl(Type,ubyte Reg,ubyte Mode)(CpuPtr cpu)
{
    addressMode!(Type,AddressModeType.Read,Mode,(cpu,val)
        {
            cast(void)sub(cast(int)cpu.state.A[Reg], val, cpu);
        })(cpu);
}