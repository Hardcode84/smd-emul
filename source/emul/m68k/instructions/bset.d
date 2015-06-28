module emul.m68k.instructions.bset;

import emul.m68k.instructions.common;

package nothrow:
void addBsetInstructions(ref Instruction[ushort] ret) pure
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
            ret.addInstruction(Instruction("bset",0x08c0 | mode,0x4,&bsetiImpl!(Type,mode)));
            foreach(r; 0..8)
            {
                ret.addInstruction(Instruction("bset",cast(ushort)(0x01c0 | (r << 9) | mode),0x2,&bsetImpl!(Type,mode)));
            }
        }
    }
}

private:
void bsetiImpl(Type,ubyte Mode)(ref Cpu cpu)
{
    const bit = cpu.getInstructionData!ubyte(cpu.state.PC - 0x1) % (Type.sizeof * 8);
    addressMode!(Type,AddressModeType.ReadWriteDontExtendRegister,Mode,(ref cpu,b)
        {
            cpu.state.setFlags!(CCRFlags.Z)(0 == ((b >> bit) & 0x1));
            return cast(Type)(b | (1 << bit));
        })(cpu);
}

void bsetImpl(Type,ubyte Mode)(ref Cpu cpu)
{
    const reg = ((cpu.getInstructionData!ubyte(cpu.state.PC - 0x2) >> 1) & 0b111);
    const bit = cpu.state.D[reg] % (Type.sizeof * 8);
    addressMode!(Type,AddressModeType.ReadWriteDontExtendRegister,Mode,(ref cpu,b)
        {
            cpu.state.setFlags!(CCRFlags.Z)(0 == ((b >> bit) & 0x1));
            return cast(Type)(b | (1 << bit));
        })(cpu);
}