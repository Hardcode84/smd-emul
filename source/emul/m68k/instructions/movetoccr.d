module emul.m68k.instructions.movetoccr;

import emul.m68k.instructions.common;

package pure nothrow:
void addMovetoccrInstructions(ref Instruction[ushort] ret)
{
    foreach(v; TupleRange!(0,readAddressModes.length))
    {
        enum mode = readAddressModes[v];
        static if(addressModeTraits!mode.Data)
        {
            ret.addInstruction(Instruction("move to ccr",0x44c0 | mode,0x2,&movetoccrImpl!mode));
        }
    }
}

private:
void movetoccrImpl(ubyte Mode)(CpuPtr cpu)
{
    addressMode!(ushort,AddressModeType.Read,Mode,(cpu,val)
        {
            cpu.state.CCR = cast(ubyte)val;
        })(cpu);
}