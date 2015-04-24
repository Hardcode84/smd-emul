module emul.m68k.instructions.suba;

import emul.m68k.instructions.common;

package nothrow:
void addSubaInstructions(ref Instruction[ushort] ret) pure
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
                const instr = 0x9000 | (r << 9) | (opm << 6) | mode;
                ret.addInstruction(Instruction("suba",cast(ushort)instr,0x2,&subaImpl!(Type,r,mode)));
            }
        }
    }
}

private:
void subaImpl(Type,ubyte Reg,ubyte Mode)(CpuPtr cpu)
{
    addressMode!(Type,AddressModeType.Read,Mode,(cpu,val)
        {
            cpu.state.A[Reg] -= val;
        })(cpu);
}