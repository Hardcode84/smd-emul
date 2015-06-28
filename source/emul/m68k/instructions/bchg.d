module emul.m68k.instructions.bchg;

import emul.m68k.instructions.common;

package nothrow:
void addBchgInstructions(ref Instruction[ushort] ret) pure
{
    foreach(v; TupleRange!(0,readAddressModes.length))
    {
        enum mode = readAddressModes[v];
        static if(addressModeTraits!mode.Data && addressModeTraits!mode.Alterable)
        {
            static if(((mode >> 3) & 0b111) == 0b000) //Data reg
            {
                alias Type = uint;
            }
            else
            {
                alias Type = ubyte;
            }
            ret.addInstruction(Instruction("bchg",0x0840 | mode,0x4,&bchgiImpl!(Type,mode)));
            foreach(r; 0..8)
            {
                ret.addInstruction(Instruction("bchg",cast(ushort)(0x0140 | (r << 9) | mode),0x2,&bchgImpl!(Type,mode)));
            }
        }
    }
}

private:
void bchgiImpl(Type,ubyte Mode)(ref Cpu cpu)
{
    const bit = cpu.getInstructionData!ubyte(cpu.state.PC - 0x1) % (Type.sizeof * 8);
    addressMode!(Type,AddressModeType.ReadWriteDontExtendRegister,Mode,(ref cpu,b)
        {
            cpu.state.setFlags!(CCRFlags.Z)(0 == ((b >> bit) & 0x1));
            return cast(Type)(b ^ (1 << bit));
        })(cpu);
}

void bchgImpl(Type,ubyte Mode)(ref Cpu cpu)
{
    const reg = ((cpu.getInstructionData!ubyte(cpu.state.PC - 0x2) >> 1) & 0b111);
    const bit = cpu.state.D[reg] % (Type.sizeof * 8);
    addressMode!(Type,AddressModeType.ReadWriteDontExtendRegister,Mode,(ref cpu,b)
        {
            cpu.state.setFlags!(CCRFlags.Z)(0 == ((b >> bit) & 0x1));
            return cast(Type)(b ^ (1 << bit));
        })(cpu);
}