module emul.m68k.addressmodes;

import emul.m68k.cpu;

enum AddressModeType
{
    Write,
    WriteDontExtendRegister,
    Read,
    ReadAddress,
    ReadWrite,
    ReadWriteDontExtendRegister
}

template addressMode(T, AddressModeType Type, ubyte Val, alias F)
{
nothrow @nogc:
    private enum Mode = (Val >> 3) & 0b111;
    private enum Reg =  Val & 0b111;
    private enum Write = (
        Type == AddressModeType.Write ||
        Type == AddressModeType.WriteDontExtendRegister ||
        Type == AddressModeType.ReadWrite ||
        Type == AddressModeType.ReadWriteDontExtendRegister);
    private void memProxy(ref Cpu cpu, uint address)
    {
        static if(Type == AddressModeType.Write || Type == AddressModeType.WriteDontExtendRegister)
        {
            cpu.setMemValue!T(address,F(cpu));
        }
        else static if(Type == AddressModeType.Read)
        {
            F(cpu,cpu.getMemValue!T(address));
        }
        else static if(Type == AddressModeType.ReadAddress)
        {
            F(cpu,cast(T)address);
        }
        else static if(Type == AddressModeType.ReadWrite || Type == AddressModeType.ReadWriteDontExtendRegister)
        {
            cpu.setMemValue!T(address,F(cpu,cast(T)cpu.getMemValue!T(address)));
        }
        else static assert(false);
    }
    private enum RegInc = (7 == Reg ? max(2,T.sizeof) : T.sizeof);

    static if(0b000 == Mode)
    {
        void addressMode(ref Cpu cpu)
        {
            static if(Type == AddressModeType.Write)
            {
                cpu.state.D[Reg] = F(cpu);
            }
            else static if(Type == AddressModeType.WriteDontExtendRegister)
            {
                truncateReg!T(cpu.state.D[Reg]) = F(cpu);
            }
            else static if(Type == AddressModeType.ReadWrite)
            {
                cpu.state.D[Reg] = F(cpu,cast(T)cpu.state.D[Reg]);
            }
            else static if(Type == AddressModeType.ReadWriteDontExtendRegister)
            {
                truncateReg!T(cpu.state.D[Reg]) = F(cpu,cast(T)cpu.state.D[Reg]);
            }
            else static if(Type == AddressModeType.Read || Type == AddressModeType.ReadAddress)
            {
                F(cpu,cast(T)cpu.state.D[Reg]);
            }
            else static assert(false);
        }
    }
    else static if(0b001 == Mode)
    {
        void addressMode(ref Cpu cpu)
        {
            static if(Type == AddressModeType.Write)
            {
                cpu.state.A[Reg] = F(cpu);
            }
            else static if(Type == AddressModeType.WriteDontExtendRegister)
            {
                truncateReg!T(cpu.state.A[Reg]) = F(cpu);
            }
            else static if(Type == AddressModeType.ReadWrite)
            {
                cpu.state.A[Reg] = F(cpu,cast(T)cpu.state.A[Reg]);
            }
            else static if(Type == AddressModeType.ReadWriteDontExtendRegister)
            {
                truncateReg!T(cpu.state.A[Reg]) = F(cpu,cast(T)cpu.state.A[Reg]);
            }
            else static if(Type == AddressModeType.Read || Type == AddressModeType.ReadAddress)
            {
                F(cpu,cast(T)cpu.state.A[Reg]);
            }
            else static assert(false);
        }
    }
    else static if(0b010 == Mode)
    {
        void addressMode(ref Cpu cpu)
        {
            memProxy(cpu,cpu.state.A[Reg]);
        }
        void addressMode(ref Cpu cpu, int count)
        {
            const address = cpu.state.A[Reg];
            foreach(i;0..count)
            {
                memProxy(cpu,cast(uint)(address + T.sizeof * i));
            }
        }
    }
    else static if(0b011 == Mode)
    {
        void addressMode(ref Cpu cpu)
        {
            memProxy(cpu,cpu.state.A[Reg]);
            cpu.state.A[Reg] += RegInc;
        }
        void addressMode(ref Cpu cpu, int count)
        {
            auto address = cpu.state.A[Reg];
            foreach(i; 0..count)
            {
                memProxy(cpu,address);
                address += RegInc;
            }
            cpu.state.A[Reg] = address;
        }
    }
    else static if(0b100 == Mode)
    {
        void addressMode(ref Cpu cpu)
        {
            cpu.state.A[Reg] -= RegInc;
            memProxy(cpu,cpu.state.A[Reg]);
        }
        void addressMode(ref Cpu cpu, int count)
        {
            auto address = cpu.state.A[Reg];
            foreach(i; 0..count)
            {
                address -= RegInc;
                memProxy(cpu,address);
            }
            cpu.state.A[Reg] = address;
        }
    }
    else static if(0b101 == Mode)
    {
        void addressMode(ref Cpu cpu)
        {
            cpu.fetchInstruction(short.sizeof);
            const address = cpu.state.A[Reg] + cpu.getInstructionData!short(cpu.state.PC);
            cpu.state.PC += short.sizeof;
            memProxy(cpu,address);
        }
        void addressMode(ref Cpu cpu, int count)
        {
            cpu.fetchInstruction(short.sizeof);
            const address = cpu.state.A[Reg] + cpu.getInstructionData!short(cpu.state.PC);
            cpu.state.PC += short.sizeof;
            foreach(i; 0..count)
            {
                memProxy(cpu,cast(uint)(address + i * T.sizeof));
            }
        }
    }
    else static if(0b110 == Mode)
    {
        void addressMode(ref Cpu cpu)
        {
            const address = decodeExtensionWord(cpu,cpu.state.A[Reg]);
            memProxy(cpu,address);
        }
        void addressMode(ref Cpu cpu, int count)
        {
            const address = decodeExtensionWord(cpu,cpu.state.A[Reg]);
            foreach(i; 0..count)
            {
                memProxy(cpu,cast(uint)(address + i * T.sizeof));
            }
        }
    }
    else static if(0b111 == Mode && 0b010 == Reg && !Write)
    {
        void addressMode(ref Cpu cpu)
        {
            cpu.fetchInstruction(short.sizeof);
            const address = cpu.state.PC + cpu.getInstructionData!short(cpu.state.PC);
            cpu.state.PC += short.sizeof;
            memProxy(cpu,address);
        }
        void addressMode(ref Cpu cpu, int count)
        {
            cpu.fetchInstruction(short.sizeof);
            const address = cpu.state.PC + cpu.getInstructionData!short(cpu.state.PC);
            cpu.state.PC += short.sizeof;
            foreach(i; 0..count)
            {
                memProxy(cpu,cast(uint)(address + i * T.sizeof));
            }
        }
    }
    else static if(0b111 == Mode && 0b011 == Reg && !Write)
    {
        void addressMode(ref Cpu cpu)
        {
            const address = decodeExtensionWord(cpu,cpu.state.PC);
            memProxy(cpu,address);
        }
        void addressMode(ref Cpu cpu, int count)
        {
            const address = decodeExtensionWord(cpu,cpu.state.PC);
            foreach(i; 0..count)
            {
                memProxy(cpu,cast(uint)(address + i * T.sizeof));
            }
        }
    }
    else static if(0b111 == Mode && 0b000 == Reg)
    {
        void addressMode(ref Cpu cpu)
        {
            cpu.fetchInstruction(short.sizeof);
            const address = cpu.getInstructionData!short(cpu.state.PC);
            cpu.state.PC += short.sizeof;
            memProxy(cpu,address);
        }
        void addressMode(ref Cpu cpu, int count)
        {
            cpu.fetchInstruction(short.sizeof);
            const address = cpu.getInstructionData!short(cpu.state.PC);
            cpu.state.PC += short.sizeof;
            foreach(i; 0..count)
            {
                memProxy(cpu,cast(uint)(address + i * T.sizeof));
            }
        }
    }
    else static if(0b111 == Mode && 0b001 == Reg)
    {
        void addressMode(ref Cpu cpu)
        {
            cpu.fetchInstruction(uint.sizeof);
            const address = cpu.getInstructionData!uint(cpu.state.PC);
            cpu.state.PC += uint.sizeof;
            memProxy(cpu,address);
        }
        void addressMode(ref Cpu cpu, int count)
        {
            cpu.fetchInstruction(uint.sizeof);
            const address = cpu.getInstructionData!uint(cpu.state.PC);
            cpu.state.PC += uint.sizeof;
            foreach(i; 0..count)
            {
                memProxy(cpu,cast(uint)(address + i * T.sizeof));
            }
        }
    }
    else static if(0b111 == Mode && 0b100 == Reg && !Write)
    {
        void addressMode(ref Cpu cpu)
        {
            static if(T.sizeof == 1)
            {
                const pc = cpu.state.PC + 1;
            }
            else
            {
                const pc = cpu.state.PC;
            }
            const sz = max(T.sizeof,ushort.sizeof);
            cpu.fetchInstruction(sz);
            cpu.state.PC += sz;
            static if(Type == AddressModeType.Read)
            {
                F(cpu,cpu.getInstructionData!T(pc));
            }
            else static if(Type == AddressModeType.ReadAddress)
            {
                F(cpu,cast(T)pc);
            }
            else static assert(false);
        }
    }
    else
    {
        static assert(false);
    }
}

template addressModeTraits(ubyte Val)
{
    private enum Mode = (Val >> 3) & 0b111;
    private enum Reg =  Val & 0b111;
    static if(0b000 == Mode)
    {
        enum Data = true;
        enum Memory = false;
        enum Control = false;
        enum Alterable = true;
        enum Predecrement = false;
        enum Postincrement = false;
    }
    else static if(0b001 == Mode)
    {
        enum Data = false;
        enum Memory = false;
        enum Control = false;
        enum Alterable = true;
        enum Predecrement = false;
        enum Postincrement = false;
    }
    else static if(0b010 == Mode)
    {
        enum Data = true;
        enum Memory = true;
        enum Control = true;
        enum Alterable = true;
        enum Predecrement = false;
        enum Postincrement = false;
    }
    else static if(0b011 == Mode)
    {
        enum Data = true;
        enum Memory = true;
        enum Control = false;
        enum Alterable = true;
        enum Predecrement = false;
        enum Postincrement = true;
    }
    else static if(0b100 == Mode)
    {
        enum Data = true;
        enum Memory = true;
        enum Control = false;
        enum Alterable = true;
        enum Predecrement = true;
        enum Postincrement = false;
    }
    else static if(0b101 == Mode)
    {
        enum Data = true;
        enum Memory = true;
        enum Control = true;
        enum Alterable = true;
        enum Predecrement = false;
        enum Postincrement = false;
    }
    else static if(0b110 == Mode)
    {
        enum Data = true;
        enum Memory = true;
        enum Control = true;
        enum Alterable = true;
        enum Predecrement = false;
        enum Postincrement = false;
    }
    else static if(0b111 == Mode && 0b010 == Reg)
    {
        enum Data = true;
        enum Memory = true;
        enum Control = true;
        enum Alterable = false;
        enum Predecrement = false;
        enum Postincrement = false;
    }
    else static if(0b111 == Mode && 0b011 == Reg)
    {
        enum Data = true;
        enum Memory = true;
        enum Control = true;
        enum Alterable = false;
        enum Predecrement = false;
        enum Postincrement = false;
    }
    else static if(0b111 == Mode && 0b000 == Reg)
    {
        enum Data = true;
        enum Memory = true;
        enum Control = true;
        enum Alterable = true;//false; bug in PRM?
        enum Predecrement = false;
        enum Postincrement = false;
    }
    else static if(0b111 == Mode && 0b001 == Reg)
    {
        enum Data = true;
        enum Memory = true;
        enum Control = true;
        enum Alterable = true;//false; bug in PRM?
        enum Predecrement = false;
        enum Postincrement = false;
    }
    else static if(0b111 == Mode && 0b100 == Reg)
    {
        enum Data = true;
        enum Memory = true;
        enum Control = false;
        enum Alterable = false;
        enum Predecrement = false;
        enum Postincrement = false;
    }
    else
    {
        static assert(false);
    }
}

template sizeField(ubyte Val)
{
         static if(0x0 == Val) alias sizeField = byte;
    else static if(0x1 == Val) alias sizeField = short;
    else static if(0x2 == Val) alias sizeField = int;
    else static assert(false);
}

template addressModeWSize(AddressModeType Type, ubyte Val, alias F)
{
    alias addressModeWSize = addressMode!(sizeField!(Val >> 6),Type,Val & 0b111111,F);
}

import std.array;
import std.algorithm;
import std.range;
import std.typecons;

enum ubyte[] sizeFields = [0,1,2];

enum ubyte[] writeAddressModes = cartesianProduct(iota(7),iota(8)).map!(a => (a[0] << 3) | a[1])
    .chain([0b111000,0b111001]).array;

enum ubyte[] readAddressModes = writeAddressModes[].chain([0b111010,0b111011,0b111100]).array;

enum ubyte[] writeAddressModesWSize = cartesianProduct(sizeFields,writeAddressModes).map!(a => (a[0] << 6) | a[1]).array;
enum ubyte[] readAddressModesWSize = cartesianProduct(sizeFields,readAddressModes).map!(a => (a[0] << 6) | a[1]).array;

unittest
{
    static assert(writeAddressModes.all!(a => 0x0 == (a & 0b11000000)));
    static assert(readAddressModes.all!(a => 0x0 == (a & 0b11000000)));
    import std.typetuple;
    import gamelib.memory.saferef;
    import gamelib.util;
    foreach(T; TypeTuple!(byte,short,int))
    {
        foreach(v; TupleRange!(0,readAddressModes.length))
        {
            static assert(__traits(compiles,addressMode!(T,AddressModeType.Read,readAddressModes[v],(a,b){})(makeSafe!Cpu)));
        }
        foreach(v; TupleRange!(0,writeAddressModes.length))
        {
            static assert(__traits(compiles,addressMode!(T,AddressModeType.Write,writeAddressModes[v],(a){return cast(T)0;})(makeSafe!Cpu)));
        }
    }
}

nothrow @nogc:
private uint decodeExtensionWord(ref Cpu cpu, uint addrRegVal)
{
    cpu.fetchInstruction(ushort.sizeof);
    auto pc = cpu.state.PC;
    const word = cpu.getInstructionData!ushort(pc);
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
        const IIS = word & 0b111;
        const ushort BDSize = (word >> 4) & 0b11;
        int baseDisp = 0;

        uint sizeToFetch;
        if(2 == BDSize)      sizeToFetch = short.sizeof;
        else if(3 == BDSize) sizeToFetch = int.sizeof;
        else assert(false);

        switch(IIS & 0b11)
        {
            case 2:
                sizeToFetch += short.sizeof;
                break;
            case 3:
                sizeToFetch += int.sizeof;
                break;
            default:
                break;
        }
        cpu.fetchInstruction(sizeToFetch);

        if(2 == BDSize)
        {
            baseDisp = cpu.getInstructionData!short(pc);
            pc += short.sizeof;
        }
        else if(3 == BDSize)
        {
            baseDisp = cpu.getInstructionData!int(pc);
            pc += int.sizeof;
        }

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
                    outerDisp = cpu.getInstructionData!short(pc);
                    pc += short.sizeof;
                    break;
                case 3:
                    outerDisp = cpu.getInstructionData!int(pc);
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
                    return cpu.getMemValue!uint(intermediate) + outerDisp;
                }
                else // Indirect Postindexed
                {
                    const intermediate = addrRegVal + baseDisp;
                    return cpu.getMemValue!uint(intermediate) + indexVal * scale + outerDisp;
                }
            }
            else
            {
                assert(0 == (IIS & 0b100));
                // Memory Indirect
                const intermediate = addrRegVal + baseDisp;
                return cpu.getMemValue!uint(intermediate) + outerDisp;
            }
        }
    }
}