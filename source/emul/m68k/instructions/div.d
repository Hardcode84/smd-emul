module emul.m68k.instructions.div;

import emul.m68k.instructions.common;
import emul.m68k.cpu.exceptions;

package nothrow:
void addAddDivInstructions(ref Instruction[ushort] ret) pure
{
    foreach(v; TupleRange!(0,readAddressModes.length))
    {
        enum mode = readAddressModes[v];
        static if(addressModeTraits!mode.Data)
        {
            foreach(r; 0..8)
            {
                const instr1 = 0x81c0 | (r << 9) | mode;
                ret.addInstruction(Instruction("divs", cast(ushort)instr1,0x2,&divwImpl!(true,mode)));

                const instr2 = 0x80c0 | (r << 9) | mode;
                ret.addInstruction(Instruction("divu", cast(ushort)instr2,0x2,&divwImpl!(false,mode)));
            }
            
            const instr = 0x4c40 | mode;
            ret.addInstruction(Instruction("div", cast(ushort)instr,0x4,&divImpl!mode));
        }
    }
}

private:
void divwImpl(bool Signed, ubyte Mode)(CpuPtr cpu)
{
    const reg = ((cpu.getInstructionData!ubyte(cpu.state.PC - 0x2) >> 1) & 0b111);
    static if(Signed)
    {
        addressMode!(short,AddressModeType.Read,Mode,(cpu,val)
            {
                if(val == 0)
                {
                    cpu.triggerException(ExceptionCodes.Division_by_zero);
                    assert(false);
                }
                const result = cast(int)cpu.state.D[reg] / cast(int)val;
                if(result > short.max || result < short.min)
                {
                    cpu.state.setFlags!(CCRFlags.V);
                    cpu.state.clearFlags!(CCRFlags.C);
                    return;
                }
                const rem    = cast(int)cpu.state.D[reg] % cast(int)val;
                assert(rem >= short.min && rem <= short.max);
                updateFlags(cpu, result);
                cpu.state.D[reg] = result | (rem << 16);
            })(cpu);
    }
    else
    {
        addressMode!(ushort,AddressModeType.Read,Mode,(cpu,val)
            {
                if(val == 0)
                {
                    cpu.triggerException(ExceptionCodes.Division_by_zero);
                    assert(false);
                }
                const result = cast(uint)cpu.state.D[reg] / cast(uint)val;
                if(result > ushort.max)
                {
                    cpu.state.setFlags!(CCRFlags.V);
                    cpu.state.clearFlags!(CCRFlags.C);
                    return;
                }
                const rem    = cast(uint)cpu.state.D[reg] % cast(uint)val;
                assert(rem <= uint.max);
                updateFlags(cpu, cast(int)result);
                cpu.state.D[reg] = result | (rem << 16);
            })(cpu);
    }
}

void divImpl(ubyte Mode)(CpuPtr cpu)
{
    const word = cpu.getInstructionData!ushort(cpu.state.PC - 0x2);
    static immutable funcs = [
        &divImpl2!(false,false,Mode),
        &divImpl2!(false,true,Mode),
        &divImpl2!(true,false,Mode),
        &divImpl2!(true,true,Mode)];
    funcs[(word >> 10) & 0b11](cpu,word);
}

void divImpl2(bool S, bool Quad, ubyte Mode)(CpuPtr cpu, ushort word)
{
    static if(S)
    {
        alias Type = int;
        alias ResType = long;
    }
    else
    {
        alias Type = uint;
        alias ResType = ulong;
    }
    addressMode!(Type,AddressModeType.Read,Mode,(cpu,val)
        {
            if(val == 0)
            {
                cpu.triggerException(ExceptionCodes.Division_by_zero);
                assert(false);
            }
            const regl = ((word >> 12) & 0b111);
            const regh = (word & 0b111);
            auto dividend = cast(ResType)cpu.state.D[regl];
            static if(Quad)
            {
                dividend |= (cast(ResType)cpu.state.D[regh]) << 32;
            }
            const result = dividend / val;
            if(result > Type.max || result < Type.min)
            {
                cpu.state.setFlags!(CCRFlags.V);
                cpu.state.clearFlags!(CCRFlags.C);
                return;
            }

            updateFlags(cpu, cast(int)result);
            cpu.state.D[regl] = cast(int)result;
            if(regl != regh)
            {
                const rem = dividend % val;
                assert(rem >= Type.min && rem <= Type.max);
                cpu.state.D[regh] = cast(int)rem;
            }
        })(cpu);
}