module emul.m68k.instructions.movetosr;

import emul.m68k.instructions.common;

package nothrow:
void addMovetosrInstructions(ref Instruction[ushort] ret) pure
{
    foreach(v; TupleRange!(0,readAddressModes.length))
    {
        enum mode = readAddressModes[v];
        static if(addressModeTraits!mode.Data)
        {
            ret.addInstruction(Instruction("move to sr",0x46c0 | mode,0x2,&movetosrImpl!mode));
        }
    }
}

private:
void movetosrImpl(ubyte Mode)(ref Cpu cpu)
{
    addressMode!(ushort,AddressModeType.Read,Mode,(ref cpu,val)
        {
            cpu.state.SR = val;
        })(cpu);
}