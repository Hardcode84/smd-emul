module emul.m68k.instructions.create;

import emul.m68k.instructions.common;
public import emul.m68k.instructions.common : Instruction;

pure nothrow:
auto createInstructions()
{
    Instruction[ushort] ret;

    import emul.m68k.instructions.nop;
    addNoplInstructions(ret);

    import emul.m68k.instructions.illegal;
    addIllegalInstructions(ret);

    import emul.m68k.instructions.bra;
    addBraInstructions(ret);

    import emul.m68k.instructions.bsr;
    addBsrInstructions(ret);

    import emul.m68k.instructions.bcc;
    addBccInstructions(ret);


    import emul.m68k.instructions.tst;
    addTstInstructions(ret);

    import emul.m68k.instructions.cmp;
    addCmpInstructions(ret);

    import emul.m68k.instructions.lea;
    addLeaInstructions(ret);


    import emul.m68k.instructions.movem;
    addMovemInstructions(ret);

    import emul.m68k.instructions.moveq;
    addMoveqInstructions(ret);

    import emul.m68k.instructions.movea;
    addMoveaInstructions(ret);

    import emul.m68k.instructions.moveusp;
    addMoveuspInstructions(ret);

    import emul.m68k.instructions.movetosr;
    addMovetosrInstructions(ret);

    import emul.m68k.instructions.move;
    addMoveInstructions(ret);


    import emul.m68k.instructions.andi;
    addAndiInstructions(ret);

    import emul.m68k.instructions.or;
    addOrInstructions(ret);

    import emul.m68k.instructions.rolror;
    addRolRorInstructions(ret);

    import emul.m68k.instructions.add;
    addAddInstructions(ret);

    import emul.m68k.instructions.addq;
    addAddqInstructions(ret);

    import emul.m68k.instructions.addi;
    addAddiInstructions(ret);

    import emul.m68k.instructions.subq;
    addSubqInstructions(ret);

    import emul.m68k.instructions.mul;
    addAddMulInstructions(ret);

    import emul.m68k.instructions.swap;
    addSwapInstructions(ret);

    import emul.m68k.instructions.dbcc;
    addDbccInstructions(ret);

    import emul.m68k.instructions.btst;
    addBtstInstructions(ret);


    import emul.m68k.instructions.jmp;
    addJmpInstructions(ret);

    import emul.m68k.instructions.jsr;
    addJsrInstructions(ret);

    import emul.m68k.instructions.rts;
    addRtsInstructions(ret);

    import emul.m68k.instructions.rte;
    addRteInstructions(ret);


    import emul.m68k.instructions.clr;
    addClrInstructions(ret);

    return ret;
}
