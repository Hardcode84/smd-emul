module emul.m68k.instructions.scc;

import emul.m68k.instructions.common;

package nothrow:
void addSccInstructions(ref Instruction[ushort] ret) pure
{
    foreach(v; TupleRange!(0,writeAddressModes.length))
    {
        enum mode = readAddressModes[v];
        static if(addressModeTraits!mode.Data && addressModeTraits!mode.Alterable)
        {
            foreach(c; TupleRange!(0,conditionalTests.length))
            {
                enum cond = conditionalTests[c];
                ret.addInstruction(Instruction("scc",0x50c0 | (cond << 8) | mode,0x2,&sccImpl!(cond,mode)));
            }
        }
    }
}

private:
void sccImpl(ubyte Condition,ubyte Mode)(CpuPtr cpu)
{
    addressMode!(ubyte,AddressModeType.WriteDontExtendRegister,Mode,(cpu)
        {
            return cast(ubyte)(conditionalTest!Condition(cpu) ? 0xff : 0x0);
        })(cpu);
}