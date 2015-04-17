module emul.m68k.cpurunner;

import std.string;
import std.algorithm;
import std.exception;

import gamelib.debugout;
import gamelib.memory.saferef;

import emul.rom;
import emul.m68k.cpu;

import emul.m68k.instructions.create;

class CpuRunner
{
public:
    enum BreakReason
    {
        SingleStep = 0
    }
    struct RunParams
    {
        alias BreakHandler = bool delegate(CpuPtr cpu) pure nothrow;
        BreakHandler[BreakReason.max + 1] breakHandlers;
    }
    this(RomRef rom)
    {
        mRom = rom;
        enforce(mRom.header.romEndAddress < mRom.header.ramEndAddress,
            format("Invalid memory ranges %s %s", mRom.header.romEndAddress, mRom.header.ramEndAddress));
        mCpu.memory.data.length = mRom.header.ramEndAddress + 1;
        mCpu.memory.data[0..mRom.data.length] = mRom.data[];

        mCpu.memory.romStartAddress = rom.header.romStartAddress;
        mCpu.memory.romEndAddress   = rom.header.romEndAddress;
        mCpu.memory.ramStartAddress = rom.header.ramStartAddress;
        mCpu.memory.ramEndAddress   = rom.header.ramEndAddress;

        mCpu.state.PC = mRom.header.entryPoint;
        mCpu.state.SP = mRom.header.stackPointer;
        createOps();
    }

    void run(in RunParams params)
    {
        convertSafe2((CpuPtr a)
            {
                if(params.breakHandlers[BreakReason.SingleStep] is null)
                {
                    runImpl!false(a,params);
                }
                else
                {
                    runImpl!true(a,params);
                }
            },
        () {assert(false);},
        &mCpu);
    }
private:
    Cpu mCpu;
    SafeRef!Rom mRom;
    Op[] mOps;

    struct Op
    {
        ushort size;
        ushort ticks = 1;
        void function(CpuPtr) @nogc pure nothrow impl;
        this(in Instruction instr)
        {
            size = instr.size;
            impl = instr.impl;
        }
    }

    static void invalidOp(Dummy)(CpuPtr cpu)
    {
        const pc = cpu.state.PC;
        debugfOut("Invalid op: 0x%.6x 0x%.4x",pc,cpu.memory.getValue!ushort(pc));
        assert(false, "Invalid op");
    }

    void createOps()
    {
        mOps.length = ushort.max + 1;
        mOps[] = Op(Instruction("illegal",0x0,0x0,&invalidOp!void));
        const instructions = createInstructions();
        debugfOut("Total instructions: %s",instructions.length);
        foreach(i,instr; instructions)
        {
            mOps[i] = Op(instr);
        }
    }

    void runImpl(bool SingleStep)(CpuPtr cpu, in RunParams params)
    {
        assert((params.breakHandlers[BreakReason.SingleStep] !is null) == SingleStep);
        scope(failure) debugOut(cpu.state);
        while(true)
        {
            static if(SingleStep)
            {
                if(!params.breakHandlers[BreakReason.SingleStep](cpu))
                {
                    break;
                }
            }
            const opcode = mCpu.memory.getRawValue!ushort(mCpu.state.PC);
            const op = mOps[opcode];
            debug
            {
                //debugfOut("0x%.6x op: 0x%.4x %s",mCpu.state.PC,opcode,op.name);
            }
            mCpu.state.PC += op.size;
            mCpu.state.tickCounter += op.ticks;
            op.impl(cpu);
        }
    }
}

