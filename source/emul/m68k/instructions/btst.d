module emul.m68k.instructions.btst;

import emul.m68k.instructions.common;

package nothrow:
void addBtstInstructions(ref Instruction[ushort] ret) pure
{
    foreach(v; TupleRange!(0,readAddressModes.length))
    {
        enum mode = readAddressModes[v];
        static if(addressModeTraits!mode.Data)
        {
            static if(((mode >> 3) & 0b111) == 0b000) //Data reg
            {
                alias Type = uint;
            }
            else
            {
                alias Type = ubyte;
            }
            ret.addInstruction(Instruction("btst",0x0800 | mode,0x4,&btstiImpl!(Type,mode)));
            foreach(r; 0..8)
            {
                ret.addInstruction(Instruction("btst",cast(ushort)(0x0100 | (r << 9) | mode),0x2,&btstImpl!(Type,mode)));
            }
        }
    }
}

private:
void btstiImpl(Type,ubyte Mode)(ref Cpu cpu)
{
    const bit = cpu.getInstructionData!ubyte(cpu.state.PC - 0x1) % (Type.sizeof * 8);
    addressMode!(Type,AddressModeType.Read,Mode,(ref cpu,b)
        {
            cpu.state.setFlags!(CCRFlags.Z)(0 == ((b >> bit) & 0x1));
        })(cpu);
}

void btstImpl(Type,ubyte Mode)(ref Cpu cpu)
{
    const reg = ((cpu.getInstructionData!ubyte(cpu.state.PC - 0x2) >> 1) & 0b111);
    const bit = cpu.state.D[reg] % (Type.sizeof * 8);
    addressMode!(Type,AddressModeType.Read,Mode,(ref cpu,b)
        {
            cpu.state.setFlags!(CCRFlags.Z)(0 == ((b >> bit) & 0x1));
        })(cpu);
}