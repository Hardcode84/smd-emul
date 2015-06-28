module emul.m68k.instructions.adda;

import emul.m68k.instructions.common;

package nothrow:
void addAddaInstructions(ref Instruction[ushort] ret) pure
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
                const instr = 0xd000 | (r << 9) | (opm << 6) | mode;
                ret.addInstruction(Instruction("adda",cast(ushort)instr,0x2,&addaImpl!(Type,r,mode)));
            }
        }
    }
}

private:
void addaImpl(Type,ubyte Reg,ubyte Mode)(ref Cpu cpu)
{
    addressMode!(Type,AddressModeType.Read,Mode,(ref cpu,val)
        {
            cpu.state.A[Reg] += val;
        })(cpu);
}