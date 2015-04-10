module emul.cpu.addressmodes;

import emul.cpu.cpu;

template addressMode(T, bool Write, ubyte Val)
{
pure nothrow @nogc @safe:
    private enum Mode = Val >> 3;
    private enum Reg =  Val & 0b111;
    private void memProxy(alias F)(CpuPtr cpu, uint address)
    {
        static if(Write)
        {
            cpu.memory.setValue!T(address,F(cpu));
        }
        else
        {
            F(cpu,cpu.memory.getValue!T(address));
        }
    }
    private enum RegInc = (7 == Reg ? max(2,T.sizeof) : T.sizeof);

    static if(0b000 == Mode)
    {
        void call(alias F)(CpuPtr cpu)
        {
            static if(Write)
            {
                cpu.state.D[Reg] = F(cpu);
            }
            else
            {
                F(cpu,cast(T)cpu.state.D[Reg]);
            }
        }
    }
    static if(0b001 == Mode)
    {
        void call(alias F)(CpuPtr cpu)
        {
            static if(Write)
            {
                cpu.state.A[Reg] = F(cpu);
            }
            else
            {
                F(cpu,cast(T)cpu.state.A[Reg]);
            }
        }
    }
    static if(0b010 == Mode)
    {
        void call(alias F)(CpuPtr cpu)
        {
            memProxy!F(cpu,cpu.state.A[Reg]);
        }
    }
    static if(0b011 == Mode)
    {
        void call(alias F)(CpuPtr cpu)
        {
            memProxy!F(cpu,cpu.state.A[Reg]);
            cpu.state.A[Reg] += RegInc;
        }
    }
    static if(0b100 == Mode)
    {
        void call(alias F)(CpuPtr cpu)
        {
            cpu.state.A[Reg] -= RegInc;
            memProxy!F(cpu,cpu.state.A[Reg]);
        }
    }
    static if(0b101 == Mode)
    {
        void call(alias F)(CpuPtr cpu)
        {
            const address = cpu.state.A[Reg] + cpu.memory.getValue!short(cpu.state.PC);
            cpu.state.PC += short.sizeof;
            memProxy!F(cpu,address);
        }
    }
    static if(0b110 == Mode)
    {
        void call(alias F)(CpuPtr cpu)
        {
            const address = decodeExtensionWord(cpu,cpu.state.A[Reg]);
            memProxy!F(cpu,address);
        }
    }
    static if(0b111 == Mode && 0b010 == Reg && !Write)
    {
        void call(alias F)(CpuPtr cpu)
        {
            const address = cpu.state.PC + cpu.memory.getValue!short(cpu.state.PC);
            cpu.state.PC += short.sizeof;
            memProxy!F(cpu,address);
        }
    }
    static if(0b111 == Mode && 0b011 == Reg && !Write)
    {
        void call(alias F)(CpuPtr cpu)
        {
            const address = decodeExtensionWord(cpu,cpu.state.PC);
            memProxy!F(cpu,address);
        }
    }
    static if(0b111 == Mode && 0b000 == Reg)
    {
        void call(alias F)(CpuPtr cpu)
        {
            const address = cpu.memory.getValue!short(cpu.state.PC);
            cpu.state.PC += short.sizeof;
            memProxy!F(cpu,address);
        }
    }
    static if(0b111 == Mode && 0b001 == Reg)
    {
        void call(alias F)(CpuPtr cpu)
        {
            const address = cpu.memory.getValue!uint(cpu.state.PC);
            cpu.state.PC += uint.sizeof;
            memProxy!F(cpu,address);
        }
    }
    static if(0b111 == Mode && 0b100 == Reg)
    {
        void call(alias F)(CpuPtr cpu)
        {
            const pc = cpu.state.PC;
            cpu.state.PC += T.sizeof;
            static if(Write)
            {
                cpu.memory.setValue!T(pc,F(cpu));
            }
            else
            {
                F(cpu,cpu.memory.getValue!T(pc));
            }
        }
    }
}

import std.array;
import std.algorithm;
import std.range;
import std.typecons;

enum ubyte[] writeAddressModes = cartesianProduct(iota(7),iota(8)).map!(a => (a[0] << 3 | a[1]))
    .chain([0b111000,0b111001,0b111100]).array;

enum ubyte[] readAddressModes = writeAddressModes[].chain([0b111010,0b111011]).array;

version(unittest)
{
    void readFunc(T)(CpuPtr, in T) {}
    T    writeFunc(T)(CpuPtr) { return 0; }
}

unittest
{
    import std.typetuple;
    import gamelib.memory.saferef;
    import gamelib.util;
    foreach(T; TypeTuple!(byte,short,int))
    {
        foreach(v; TupleRange!(0,readAddressModes.length))
        {
            static assert(__traits(compiles,addressMode!(T,false,readAddressModes[v]).call!(readFunc!T)(makeSafe!Cpu)));
        }
        foreach(v; TupleRange!(0,writeAddressModes.length))
        {
            static assert(__traits(compiles,addressMode!(T,true,writeAddressModes[v]).call!(writeFunc!T)(makeSafe!Cpu)));
        }
    }
}

pure nothrow @nogc @safe:
private uint decodeExtensionWord(CpuPtr cpu, uint addrRegVal) 
{
    auto pc = cpu.state.PC;
    const word = cpu.memory.getValue!ushort(pc);
    pc += ushort.sizeof;
    scope(exit) cpu.state.PC = pc;
    const bool da = (0 == (word & (1 << 15)));
    const ushort reg = (word >> 12) & 0b111;
    const bool wl = (0 == (word & (1 << 11)));
    const int scale = 1 << ((word >> 9) & 0b11);
    int indexVal = (da ? cpu.state.D[reg] : cpu.state.A[reg]);
    if(wl) indexVal = cast(short)indexVal;
    if(0 == (word & (1 << 8))) // BRIEF EXTENSION WORD FORMAT
    {
        const int disp = cast(byte)(word & 0xff);
        return addrRegVal + disp + scale * indexVal;
    }
    else // FULL EXTENSION WORD FORMAT
    {
        const bool BS = (0 == (word & (1 << 7)));
        const bool IS = (0 == (word & (1 << 6)));
        const ushort BDSize = (word >> 4) & 0b11;
        int baseDisp = 0;
        if(2 == BDSize)
        {
            baseDisp = cpu.memory.getValue!short(pc);
            pc +=short.sizeof;
        }
        else if(3 == BDSize)
        {
            baseDisp = cpu.memory.getValue!int(pc);
            pc += int.sizeof;
        }
        else
        {
            assert(false);
        }

        const IIS = word & 0b111;

        if(0 == IIS) // Address Register Indirect with Index
        {
            return addrRegVal + baseDisp + scale * indexVal + baseDisp;
        }
        else
        {
            int outerDisp = void;
            switch(IIS & 0b11)
            {
                case 2:
                    outerDisp = cpu.memory.getValue!short(pc);
                    pc += short.sizeof;
                    break;
                case 3:
                    outerDisp = cpu.memory.getValue!int(pc);
                    pc += int.sizeof;
                    break;
                default:
                    outerDisp = 0;
            }

            if(IS)
            {
                if(0 == (IIS & 0b100)) // Indirect Preindexed
                {
                    const intermediate = addrRegVal + baseDisp + indexVal * scale;
                    return cpu.memory.getValue!uint(intermediate) + outerDisp;
                }
                else // Indirect Postindexed
                {
                    const intermediate = addrRegVal + baseDisp;
                    return cpu.memory.getValue!uint(intermediate) + indexVal * scale + outerDisp;
                }
            }
            else
            {
                assert(0 == (IIS & 0b100));
                // Memory Indirect
                const intermediate = addrRegVal + baseDisp;
                return cpu.memory.getValue!uint(intermediate) + outerDisp;
            }
        }
    }
}