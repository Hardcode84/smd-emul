module main;

version(M68k_SharedLib)
{
    import std.c.windows.windows;
    import core.sys.windows.dll;
    version(Windows) extern(Windows)
        BOOL DllMain(HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
    {
        try
        {
            switch (ulReason)
            {
                case DLL_PROCESS_ATTACH:
                    dll_process_attach( hInstance, true );
                    break;
                    
                case DLL_PROCESS_DETACH:
                    dll_process_detach( hInstance, true );
                    break;
                    
                case DLL_THREAD_ATTACH:
                    dll_thread_attach( true, true );
                    break;
                    
                case DLL_THREAD_DETACH:
                    dll_thread_detach( true, true );
                    break;
                    
                default:
            }
        }
        catch(Exception e)
        {
            return false;
        }
        return true;
    }
}
else
{
    import gamelib.debugout;
    import gamelib.memory.saferef;

    import std.stdio;
    import std.file;
    import std.exception;
    import std.path;
    import std.algorithm;

    import emul.rom;
    import emul.core;

    void main(string[] args)
    {
        if( args.length <= 1 )
        {
            writeln("Hello World!");
            return;
        }

        const RomFormat format = args[1].extension.predSwitch(
            ".bin", RomFormat.BIN,
            ".md", RomFormat.MD,
            { enforce(false, "Unknown file extension"); }() );

        auto rom = createRom(format, read(args[1]).assumeUnique);
        writeln(rom.header);
        auto core = makeSafe!Core(rom);
        scope(exit) core.dispose();
        core.run();
    }
}