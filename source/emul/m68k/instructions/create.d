﻿module emul.m68k.instructions.create;

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

    import emul.m68k.instructions.dbcc;
    addDbccInstructions(ret);


    import emul.m68k.instructions.tst;
    addTstInstructions(ret);

    import emul.m68k.instructions.cmp;
    addCmpInstructions(ret);

    import emul.m68k.instructions.cmpa;
    addCmpaInstructions(ret);

    import emul.m68k.instructions.cmpi;
    addCmpiInstructions(ret);

    import emul.m68k.instructions.cmpm;
    addCmpmInstructions(ret);


    import emul.m68k.instructions.scc;
    addSccInstructions(ret);


    import emul.m68k.instructions.lea;
    addLeaInstructions(ret);

    import emul.m68k.instructions.pea;
    addPeaInstructions(ret);


    import emul.m68k.instructions.movem;
    addMovemInstructions(ret);

    import emul.m68k.instructions.moveq;
    addMoveqInstructions(ret);

    import emul.m68k.instructions.movea;
    addMoveaInstructions(ret);

    import emul.m68k.instructions.moveusp;
    addMoveuspInstructions(ret);

    import emul.m68k.instructions.movetoccr;
    addMovetoccrInstructions(ret);

    import emul.m68k.instructions.movetosr;
    addMovetosrInstructions(ret);

    import emul.m68k.instructions.movefromsr;
    addMovefromsrInstructions(ret);

    import emul.m68k.instructions.move;
    addMoveInstructions(ret);


    import emul.m68k.instructions.not;
    addNotInstructions(ret);

    import emul.m68k.instructions.and;
    addAndInstructions(ret);

    import emul.m68k.instructions.andi;
    addAndiInstructions(ret);

    import emul.m68k.instructions.anditosr;
    addAnditosrInstructions(ret);

    import emul.m68k.instructions.or;
    addOrInstructions(ret);

    import emul.m68k.instructions.ori;
    addOriInstructions(ret);

    import emul.m68k.instructions.eor;
    addEorInstructions(ret);

    import emul.m68k.instructions.eori;
    addEoriInstructions(ret);

    import emul.m68k.instructions.oritoccr;
    addOritoccrInstructions(ret);

    import emul.m68k.instructions.oritosr;
    addOritosrInstructions(ret);

    import emul.m68k.instructions.rolror;
    addRolRorInstructions(ret);

    import emul.m68k.instructions.roxlroxr;
    addRoxlRoxrInstructions(ret);

    import emul.m68k.instructions.lsllsr;
    addLslLsrInstructions(ret);

    import emul.m68k.instructions.aslasr;
    addAslAsrInstructions(ret);

    import emul.m68k.instructions.ext;
    addExtInstructions(ret);

    import emul.m68k.instructions.neg;
    addNegInstructions(ret);

    import emul.m68k.instructions.add;
    addAddInstructions(ret);

    import emul.m68k.instructions.adda;
    addAddaInstructions(ret);

    import emul.m68k.instructions.addq;
    addAddqInstructions(ret);

    import emul.m68k.instructions.addi;
    addAddiInstructions(ret);

    import emul.m68k.instructions.addx;
    addAddxInstructions(ret);

    import emul.m68k.instructions.sub;
    addSubInstructions(ret);

    import emul.m68k.instructions.suba;
    addSubaInstructions(ret);

    import emul.m68k.instructions.subq;
    addSubqInstructions(ret);

    import emul.m68k.instructions.subi;
    addSubiInstructions(ret);

    import emul.m68k.instructions.subx;
    addSubxInstructions(ret);

    import emul.m68k.instructions.mul;
    addAddMulInstructions(ret);

    import emul.m68k.instructions.div;
    addAddDivInstructions(ret);

    import emul.m68k.instructions.swap;
    addSwapInstructions(ret);

    import emul.m68k.instructions.exg;
    addExgInstructions(ret);


    import emul.m68k.instructions.btst;
    addBtstInstructions(ret);

    import emul.m68k.instructions.bset;
    addBsetInstructions(ret);

    import emul.m68k.instructions.bchg;
    addBchgInstructions(ret);

    import emul.m68k.instructions.bclr;
    addBclrInstructions(ret);


    import emul.m68k.instructions.link;
    addLinkInstructions(ret);

    import emul.m68k.instructions.unlink;
    addUnlinkInstructions(ret);


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
