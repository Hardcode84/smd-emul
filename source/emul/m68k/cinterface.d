module emul.m68k.cinterface;

version(M68k_SharedLib):

import std.algorithm;
import std.string;
import std.exception;
import std.c.stdio;
import core.memory;

import gamelib.memory.saferef;

import emul.m68k.cpu;
import emul.m68k.cpurunner;

nothrow:

private void printException(Throwable e)
{
    try
    {
        printf("Exception %s",e.toString.toStringz);
    }
    catch(Throwable e)
    {
        printf("Second exception thrown");
    }
}

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
            void[] mem;
            mem.length = max(params.ramEnd, params.romEnd);
            CpuParams p = {ramStart:params.ramStart, ramEnd:params.ramEnd, romStart:params.romStart, romEnd:params.romEnd, memory:mem};
            context* ret = new context(Cpu(p), CpuRunner(0));
            GC.addRoot(ret);
            return ret;
        }
        catch(Throwable e)
        {
            printException(e);
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
        catch(Throwable e)
        {
            printException(e);
        }
    }

    void m68k_release(context* ctx)
    {
        try
        {
            GC.removeRoot(ctx);
        }
        catch(Throwable e)
        {
            printException(e);
        }
    }


    uint m68k_get_pc(const context* ctx)
    {
        try
        {
            return ctx.cpu.state.PC;
        }
        catch(Throwable e)
        {
            printException(e);
            return 0;
        }
    }

    void m68k_set_pc(context* ctx, uint pc)
    {
        try
        {
            ctx.cpu.state.PC = pc;
        }
        catch(Throwable e)
        {
            printException(e);
        }
    }

    uint m68k_get_ccr(const context* ctx)
    {
        try
        {
            return ctx.cpu.state.CCR;
        }
        catch(Throwable e)
        {
            printException(e);
            return 0;
        }
    }

    void m68k_set_ccr(context* ctx, uint ccr)
    {
        try
        {
            ctx.cpu.state.CCR = cast(ubyte)ccr;
        }
        catch(Throwable e)
        {
            printException(e);
        }
    }

    uint m68k_get_dreg(const context* ctx, int d)
    {
        try
        {
            return ctx.cpu.state.D[d];
        }
        catch(Throwable e)
        {
            printException(e);
            return 0;
        }
    }

    void m68k_set_dreg(context* ctx, int d, uint value)
    {
        try
        {
            ctx.cpu.state.D[d] = value;
        }
        catch(Throwable e)
        {
            printException(e);
        }
    }

    uint m68k_get_areg(const context* ctx, int d)
    {
        try
        {
            return ctx.cpu.state.D[d];
        }
        catch(Throwable e)
        {
            printException(e);
            return 0;
        }
    }

    void m68k_set_areg(context* ctx, int d, uint value)
    {
        try
        {
            ctx.cpu.state.D[d] = value;
        }
        catch(Throwable e)
        {
            printException(e);
        }
    }

    uint m68k_get_byte(context* ctx, uint addr)
    {
        try
        {
            return ctx.cpu.getMemValue!ubyte(addr);
        }
        catch(Throwable e)
        {
            printException(e);
            return 0;
        }
    }

    void m68k_put_byte(context* ctx, uint addr, ubyte v)
    {
        try
        {
            ctx.cpu.setMemValue(addr,v);
        }
        catch(Throwable e)
        {
            printException(e);
        }
    }

    uint m68k_get_word(context* ctx, uint addr)
    {
        try
        {
            return ctx.cpu.getMemValue!ushort(addr);
        }
        catch(Throwable e)
        {
            printException(e);
            return 0;
        }
    }

    void m68k_put_word(context* ctx, uint addr, ushort v)
    {
        try
        {
            ctx.cpu.setMemValue(addr,v);
        }
        catch(Throwable e)
        {
            printException(e);
        }
    }

    uint m68k_get_long(context* ctx, uint addr)
    {
        try
        {
            return ctx.cpu.getMemValue!uint(addr);
        }
        catch(Throwable e)
        {
            printException(e);
            return 0;
        }
    }

    void m68k_put_long(context* ctx, uint addr, uint v)
    {
        try
        {
            ctx.cpu.setMemValue(addr,v);
        }
        catch(Throwable e)
        {
            printException(e);
        }
    }
}