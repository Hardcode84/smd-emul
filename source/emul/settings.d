module emul.settings;

enum Model
{
    Domestic = 0,
    Overseas
}

enum DisplayFormat
{
    NTSC = 0,
    PAL
}

enum FramesyncMethod
{
    None,
    Normal
}

struct Settings
{
    Model model = Model.Overseas;
    DisplayFormat vmode = DisplayFormat.NTSC;
    ubyte consoleVer = 0;
    int frameskip = 0;
    int scale = 1;
    FramesyncMethod framesyncMethod = FramesyncMethod.Normal;
}