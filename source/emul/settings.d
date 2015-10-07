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

struct Settings
{
    Model model = Model.Overseas;
    DisplayFormat vmode = DisplayFormat.NTSC;
    ubyte ver = 0;
    int frameskip = 0;
}