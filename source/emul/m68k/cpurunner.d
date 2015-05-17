module emul.m68k.cpurunner;

import std.string;
import std.algorithm;
import std.exception;

import gamelib.debugout;
import gamelib.memory.saferef;

import emul.m68k.cpu;

import emul.m68k.instructions.create;
import emul.m68k.xsetjmp;

struct CpuRunner
{
public:
    enum BreakReason
    {
        SingleStep = 0,
        InvalidOpCode
    }
    struct RunParams
    {
        alias BreakHandler = bool delegate(CpuPtr cpu);
        alias ProcessHandler = bool delegate(CpuPtr cpu);
        BreakHandler[BreakReason.max + 1] breakHandlers;
        ProcessHandler processHandler;
    }

    @disable this();

    this(int dummy)
    {
        Op[] opsTemp;
        opsTemp.length = ushort.max + 1;
        createOps(opsTemp[]);
        mOps = assumeUnique(opsTemp);
    }

    void run(CpuPtr cpu,in RunParams params = RunParams.init)
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
    enum InvalidOpCode = 0xffff;
    immutable Op[] mOps;

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
        //debugfOut("Invalid op: 0x%.6x 0x%.4x",pc,cpu.getMemValue!ushort(pc));
        cpu.triggerBreak(InvalidOpCode);
        assert(false);
    }

    static void createOps(Op[] ops)
    {
        ops[] = Op(Instruction("illegal",0x0,0x2,&invalidOp!void));
        const instructions = createInstructions();
        debugfOut("Total instructions: %s",instructions.length);
        foreach(i,instr; instructions)
        {
            ops[i] = Op(instr);
        }
    }

    bool defProcessHandler(CpuPtr)
    {
        return true;
    }

    void runImpl(bool SingleStep)(CpuPtr cpu, in RunParams params)
    {
        const processHandler = (params.processHandler is null ? &defProcessHandler : params.processHandler);
        assert((params.breakHandlers[BreakReason.SingleStep] !is null) == SingleStep);
        scope(failure) debugOut(cpu.state);
        const res = xsetjmp(cpu.jmpbuf);
        if(res == InvalidOpCode)
        {
            if(params.breakHandlers[BreakReason.InvalidOpCode] is null ||
               !params.breakHandlers[BreakReason.InvalidOpCode](cpu))
            {
                return;
            }
        }
    outer: while(processHandler(cpu))
        {
            cpu.process(10);
            while(!cpu.processed)
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
                cpu.state.TickCounter = (cpu.state.TickCounter + op.ticks) & 0xfffffff;
                op.impl(cpu);
                cpu.endInstruction();
            }
        }
    }
}

alias CpuRunnerPtr = SafeRef!CpuRunner;