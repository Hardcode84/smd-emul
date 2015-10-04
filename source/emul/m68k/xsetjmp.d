module emul.m68k.xsetjmp;

version(Windows)
{
    version(X86)
    {
        extern(C) nothrow @nogc:
        alias xjmp_buf = int[6];

        int xsetjmp(ref xjmp_buf)
        {
            asm nothrow @nogc
            {
                naked;
                mov     EDX, [ESP+4];
                mov     [EDX], EBP;
                mov     [EDX+4], EBX;
                mov     [EDX+8], EDI;
                mov     [EDX+12], ESI;
                mov     [EDX+16], ESP;
                mov     EAX, [ESP];
                mov     [EDX+20], EAX;
                xor     EAX, EAX;
                ret;
            }
        } 

        void xlongjmp(ref xjmp_buf, int)
        {
            asm nothrow @nogc
            {
                naked;
                mov     EDX, [ESP+4];
                mov     EBP, [EDX];
                mov     EBX, [EDX+4];
                mov     EDI, [EDX+8];
                mov     ESI, [EDX+12];
                mov     EAX, [ESP+8];
                test    EAX, EAX;
                jne     __;
                inc     EAX;
                __:
                mov     ESP, [EDX+16];
                add     ESP, 4;
                mov     EDX, [EDX+20];
                jmp     EDX;
            }
        }
    }
    version(X86_64)
    {
        extern(C) nothrow @nogc:
        align(16) struct jmp_buf
        {
            long[32] data;
        }

        int setjmp(ref xjmp_buf);
        void longjmp(ref xjmp_buf, int);

        alias xjmp_buf = jmp_buf;
        alias xsetjmp = setjmp;
        alias xlongjmp = longjmp;
    }
}

unittest
{
    import gamelib.debugout;
    debugOut("xsetjmp test");
    xjmp_buf buf;
    int res = xsetjmp(buf);
    if(0 == res)
    {
        debugOut("normal");
    }
    else
    {
        debugOut("jump! ",res);
        assert(42 == res);
        return;
    }
    void foo()
    {
        debugOut("foo");
        xlongjmp(buf,42);
        assert(false);
    }
    foo();
}