module emul.m68k.cpurunner;

import std.string;
import std.algorithm;
import std.exception;

import gamelib.debugout;
import gamelib.memory.saferef;

import emul.m68k.cpu;

import emul.m68k.instructions.create;

class CpuRunner
{
public:
pure:
    enum BreakReason
    {
        SingleStep = 0
    }
    struct RunParams
    {
        alias BreakHandler = bool delegate(CpuPtr cpu) pure nothrow;
        BreakHandler[BreakReason.max + 1] breakHandlers;
    }

    this()
    {
        createOps();
    }

    void run(CpuPtr cpu,in RunParams params)
    {
        if(params.breakHandlers[BreakReason.SingleStep] is null)
        {
            runImpl!false(cpu,params);
        }
        else
        {
            runImpl!true(cpu,params);
        }
    }
private:
    Op[] mOps;

    struct Op
    {
        @nogc pure nothrow:
        ushort size;
        ushort ticks = 1;
        void function(CpuPtr) impl;
        this(in Instruction instr) @safe
        {
            size = instr.size;
            impl = instr.impl;
        }
    }

    static void invalidOp(Dummy)(CpuPtr cpu)
    {
        const pc = cpu.state.PC;
        debugfOut("Invalid op: 0x%.6x 0x%.4x",pc,cpu.getMemValue!ushort(pc));
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
        uint savedPC = 0;
        while(true)
        {
            static if(SingleStep)
            {
                if(!params.breakHandlers[BreakReason.SingleStep](cpu))
                {
                    break;
                }
            }
            savedPC = cpu.state.PC;
            const opcode = cpu.getRawMemValue!ushort(savedPC);
            const op = mOps[opcode];
            cpu.state.PC += op.size;
            cpu.state.tickCounter += op.ticks;
            op.impl(cpu);
        }
    }
}

alias CpuRunnerRef = SafeRef!CpuRunner;