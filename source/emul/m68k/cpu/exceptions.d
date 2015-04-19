module emul.m68k.cpu.exceptions;

import std.array;
import std.range;
import std.algorithm;

import gamelib.debugout;

import emul.m68k.cpu;

enum ExceptionCodes
{
    Start_stack_address = 0,
    Reset = 0,
    Start_code_address,
    Bus_error,
    Address_error,
    Illegal_instruction,
    Divistion_by_zero,
    CHK_exception,
    TRAPV_exception,
    Privilege_violation,
    TRACE_exeption,
    LINE_1010_EMULATOR,
    LINE_1111_EMULATOR,
    Reserved_by_Motorola1,
    Reserved_by_Motorola2,
    Reserved_by_Motorola3,
    Reserved_by_Motorola4,
    Reserved_by_Motorola5,
    Reserved_by_Motorola6,
    Reserved_by_Motorola7,
    Reserved_by_Motorola8,
    Reserved_by_Motorola9,
    Reserved_by_Motorola10,
    Reserved_by_Motorola11,
    Reserved_by_Motorola12,
    Spurious_exception,
    IRQ_1,
    IRQ_2,
    IRQ_3,
    IRQ_4,//Horizontal_blank,
    IRQ_5,
    IRQ_6,//Vertical_blank,
    IRQ_7,
    TRAP_00_exception,
    TRAP_01_exception,
    TRAP_02_exception,
    TRAP_03_exception,
    TRAP_04_exception,
    TRAP_05_exception,
    TRAP_06_exception,
    TRAP_07_exception,
    TRAP_08_exception,
    TRAP_09_exception,
    TRAP_10_exception,
    TRAP_11_exception,
    TRAP_12_exception,
    TRAP_13_exception,
    TRAP_14_exception,
    TRAP_15_exception,
    Reserved_by_Motorola13,
    Reserved_by_Motorola14,
    Reserved_by_Motorola15,
    Reserved_by_Motorola16,
    Reserved_by_Motorola17,
    Reserved_by_Motorola18,
    Reserved_by_Motorola19,
    Reserved_by_Motorola20,
    Reserved_by_Motorola21,
    Reserved_by_Motorola22,
    Reserved_by_Motorola23,
    Reserved_by_Motorola24,
    Reserved_by_Motorola25,
    Reserved_by_Motorola26,
    Reserved_by_Motorola27,
    Reserved_by_Motorola28
}

static immutable ExceptionCodes[] exceptionsByPriotities = [
    ExceptionCodes.Reset,
    ExceptionCodes.Address_error,
    ExceptionCodes.Bus_error,
    ExceptionCodes.TRACE_exeption,
    ExceptionCodes.Spurious_exception,
    ExceptionCodes.IRQ_1,
    ExceptionCodes.IRQ_2,
    ExceptionCodes.IRQ_3,
    ExceptionCodes.IRQ_4,
    ExceptionCodes.IRQ_5,
    ExceptionCodes.IRQ_6,
    ExceptionCodes.IRQ_7,
    ExceptionCodes.Illegal_instruction,
    ExceptionCodes.Privilege_violation,
    ExceptionCodes.TRAP_00_exception,
    ExceptionCodes.TRAP_01_exception,
    ExceptionCodes.TRAP_02_exception,
    ExceptionCodes.TRAP_03_exception,
    ExceptionCodes.TRAP_04_exception,
    ExceptionCodes.TRAP_05_exception,
    ExceptionCodes.TRAP_06_exception,
    ExceptionCodes.TRAP_07_exception,
    ExceptionCodes.TRAP_08_exception,
    ExceptionCodes.TRAP_09_exception,
    ExceptionCodes.TRAP_10_exception,
    ExceptionCodes.TRAP_11_exception,
    ExceptionCodes.TRAP_12_exception,
    ExceptionCodes.TRAP_13_exception,
    ExceptionCodes.TRAP_14_exception,
    ExceptionCodes.TRAP_15_exception,
    ExceptionCodes.TRAPV_exception,
    ExceptionCodes.CHK_exception,
    ExceptionCodes.Divistion_by_zero];

static immutable int[] priotitiesByExceptions =
    iota(ExceptionCodes.max + 1).map!(a => exceptionsByPriotities[].countUntil(cast(ExceptionCodes)a)).array;

struct Exceptions
{
pure nothrow @nogc:
    void setInterrupt(ExceptionCodes code)
    in
    {
        assert(isIRQ(code), debugConv(code));
    }
    body
    {
        setPendingException(code);
    }
package:
    union
    {
        ulong pendingExceptions = (1 << priotitiesByExceptions[ExceptionCodes.Reset]);
        struct
        {
            uint pendingExceptionsLo = void;
            uint pendingExceptionsHi = void;
        }
    }
    void setPendingException(ExceptionCodes code)
    {
        const ind = priotitiesByExceptions[code];
        assert(ind >= 0);
        pendingExceptions |= (1 << ind);
    }
    void clearPendingException(ExceptionCodes code)
    {
        const ind = priotitiesByExceptions[code];
        assert(ind >= 0);
        pendingExceptions &= ~(1 << ind);
    }
}

pure nothrow @nogc:
bool isMemoryError(ExceptionCodes code) @safe
{
    return code == ExceptionCodes.Address_error || code == ExceptionCodes.Bus_error;
}
bool isIRQ(ExceptionCodes code) @safe
{
    return code >= ExceptionCodes.Spurious_exception && code <= ExceptionCodes.IRQ_7;
}

bool enterException(CpuPtr cpu, ExceptionCodes code)
{
    assert(code != ExceptionCodes.Start_code_address);
    const oldSR = cpu.state.SR;
    if(ExceptionCodes.Reset == code)
    {
        cpu.state.setFlags(SRFlags.S);
        cpu.state.clearFlags(SRFlags.T);
        cpu.exceptions.pendingExceptions = 0;
        cpu.state.PC = cpu.getMemValue!uint(ExceptionCodes.Start_code_address * uint.sizeof);
        cpu.state.SP = cpu.getMemValue!uint(ExceptionCodes.Start_stack_address * uint.sizeof);
        cpu.state.interruptLevel = 7;
        return true;
    }
    else if(isMemoryError(code))
    {
        assert(false,"Unimplemented");
    }
    else if(isIRQ(code))
    {
        if((code - ExceptionCodes.Spurious_exception) <= cpu.state.interruptLevel) return false;
        cpu.state.interruptLevel = cast(ubyte)(code - ExceptionCodes.Spurious_exception);
    }
    cpu.state.setFlags(SRFlags.S);
    cpu.state.clearFlags(SRFlags.T);

    cpu.exceptions.clearPendingException(code);
    cpu.state.SSP -= uint.sizeof;
    cpu.setMemValue(cpu.state.SSP,cpu.state.PC);
    cpu.state.SSP -= ushort.sizeof;
    cpu.setMemValue(cpu.state.SSP,oldSR);
    cpu.state.PC = cpu.getMemValue!uint(code * uint.sizeof);
    return true;
}

void returnFromException(CpuPtr cpu)
{
    assert(cpu.state.testFlags(SRFlags.S),debugConv(cpu.state.SR));
    cpu.state.SR = cpu.getMemValue!ushort(cpu.state.SP);
    cpu.state.SP += ushort.sizeof;
    cpu.state.PC = cpu.getMemValue!uint(cpu.state.SP);
    cpu.state.SP += uint.sizeof;
}