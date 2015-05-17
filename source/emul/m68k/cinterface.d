module emul.m68k.cinterface;

version(M68k_SharedLib):

import core.memory;

import gamelib.memory.saferef;

import emul.m68k.cpu;
import emul.m68k.cpurunner;

nothrow:
extern(C) export
{
    struct m68k_params
    {
        uint ramStart;
        uint ramEnd;
        uint romStart;
        uint romEnd;
    }

    struct context
    {
        Cpu cpu;
        CpuRunner runner;
    }

    context* m68k_init(const m68k_params* params)
    {
        if(params is null) return null;
        try
        {
            CpuParams p = {ramStart:params.ramStart, ramEnd:params.ramEnd, romStart:params.romStart, romEnd:params.romEnd};
            context* ret = new context(Cpu(p), CpuRunner(0));
            GC.addRoot(ret);
            return ret;
        }
        catch(Exception e)
        {
            return null;
        }
    }

    void m68k_reset(context* ctx)
    {
    }

    void m68k_execute(context* ctx, uint pc)
    {
        ctx.cpu.state.PC = pc;
        try
        {
            convertSafe2((CpuPtr cpu)
                {
                    ctx.runner.run(cpu);
                },
                () {assert(false);},
                &ctx.cpu);
        }
        catch(Exception e)
        {
        }
    }

    void m68k_release(context* ctx)
    {
        GC.removeRoot(ctx);
    }


    uint m68k_get_pc(const context* ctx)
    {
        return ctx.cpu.state.PC;
    }

    void m68k_set_pc(context* ctx, uint pc)
    {
        ctx.cpu.state.PC = pc;
    }

    uint m68k_get_ccr(const context* ctx)
    {
        return ctx.cpu.state.CCR;
    }

    void m68k_set_ccr(context* ctx, uint ccr)
    {
        ctx.cpu.state.CCR = cast(ubyte)ccr;
    }

    uint m68k_get_dreg(const context* ctx, int d)
    {
        return ctx.cpu.state.D[d];
    }

    void m68k_set_dreg(context* ctx, int d, uint value)
    {
        ctx.cpu.state.D[d] = value;
    }

    uint m68k_get_areg(const context* ctx, int d)
    {
        return ctx.cpu.state.D[d];
    }
    
    void m68k_set_areg(context* ctx, int d, uint value)
    {
        ctx.cpu.state.D[d] = value;
    }
}