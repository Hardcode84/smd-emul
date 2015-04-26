module emul.m68k.cpurunner;

import std.string;
import std.algorithm;
import std.exception;

import gamelib.debugout;
import gamelib.memory.saferef;

import emul.m68k.cpu;

import emul.m68k.instructions.create;
import emul.m68k.xsetjmp;

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
        @nogc nothrow:
        ushort size;
        ushort ticks = 1;
        void function(CpuPtr) impl;
        this(in Instruction instr) @safe pure
        {
            size = instr.size;
            impl = instr.impl;
        }
    }

    static void invalidOp(Dummy)(CpuPtr cpu)
    {
        const pc = cpu.state.PC - 0x2;
        debugfOut("Invalid op: 0x%.6x 0x%.4x",pc,cpu.getMemValue!ushort(pc));
        assert(false, "Invalid op");
    }

    void createOps()
    {
        mOps.length = ushort.max + 1;
        mOps[] = Op(Instruction("illegal",0x0,0x2,&invalidOp!void));
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
        xsetjmp(cpu.jmpbuf);
    outer: while(true)
        {
            cpu.processExceptions();
            foreach(i;0..10)
            {
                static if(SingleStep)
                {
                    if(!params.breakHandlers[BreakReason.SingleStep](cpu))
                    {
                        break outer;
                    }
                }
                cpu.beginNextInstruction();
                const op = mOps[cpu.currentInstruction];
                assert(op.size >= 0x2);
                cpu.fetchInstruction(op.size - 0x2);
                cpu.state.PC += op.size;
                cpu.state.TickCounter += op.ticks;
                op.impl(cpu);
            }
        }
    }
}

alias CpuRunnerRef = SafeRef!CpuRunner;