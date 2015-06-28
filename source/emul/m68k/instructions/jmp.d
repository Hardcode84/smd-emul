module emul.m68k.instructions.jmp;

import emul.m68k.instructions.common;

package nothrow:
void addJmpInstructions(ref Instruction[ushort] ret) pure
{
    //jmp
    foreach(v; TupleRange!(0,readAddressModes.length))
    {
        enum mode = readAddressModes[v];
        static if(addressModeTraits!mode.Control)
        {
            ret.addInstruction(Instruction("jmp",0x4ec0 | mode,0x2,&jmpImpl!mode));
        }
    }
}

private:
void jmpImpl(byte Mode)(ref Cpu cpu)
{
    addressMode!(uint,AddressModeType.ReadAddress,Mode,(ref cpu,b)
        {
            cpu.state.PC = b;
        })(cpu);
}