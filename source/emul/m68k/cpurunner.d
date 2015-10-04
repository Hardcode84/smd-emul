module emul.m68k.cpurunner;

import std.string;
import std.algorithm;
import std.exception;

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
        alias BreakHandler = bool delegate(ref Cpu cpu);
        alias ProcessHandler = bool delegate(ref Cpu cpu);
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

    void run(ref Cpu cpu,in RunParams params = RunParams.init) const
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
        void function(ref Cpu) impl;
        this(in Instruction instr) @safe pure
        {
            size = instr.size;
            impl = instr.impl;
        }
    }

    static void invalidOp(Dummy)(ref Cpu cpu)
    {
        //const pc = cpu.state.PC - 0x2;
        //debugfOut("Invalid op: 0x%.6x 0x%.4x",pc,cpu.getMemValue!ushort(pc));
        cpu.triggerBreak(InvalidOpCode);
        assert(false);
    }

    static void createOps(Op[] ops)
    {
        ops[] = Op(Instruction("illegal",0x0,0x2,&invalidOp!void));
        const instructions = createInstructions();
        //debugfOut("Total instructions: %s",instructions.length);
        foreach(i,instr; instructions)
        {
            ops[i] = Op(instr);
        }
    }

    bool defProcessHandler(ref Cpu) const
    {
        return true;
    }

    void runImpl(bool SingleStep)(ref Cpu cpu, in RunParams params) const
    {
        const processHandler = (params.processHandler is null ? &defProcessHandler : params.processHandler);
        assert((params.breakHandlers[BreakReason.SingleStep] !is null) == SingleStep);
        if(xsetjmp(cpu.jmpbuf) == InvalidOpCode)
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
                cpu.state.TickCounter += op.ticks;
                op.impl(cpu);
                cpu.endInstruction();
            }
        }
    }
}