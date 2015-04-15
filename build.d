import std.stdio;
import std.file;
import std.algorithm;
import std.range;
import std.array;
import std.parallelism;
import std.process;
import std.exception;
import std.conv;

void main(string[] args)
{
    writeln("Preparing...");
    scope(success) writeln("Success");
    const string currPath = "./";
    const string[] importPaths = ["d-gamelib","source"];
    const string[] sourcePaths = ["d-gamelib","source"];
    const string projName = "smd-emul";
    const string buildDir = currPath ~ ".build/";
    const string compiler = "dmd";
    const string config = "debug";

    const dmdConfs = ["debug" : "-debug -g -w -c"];
    const string[string][string] compilerOpts = ["dmd" : dmdConfs];

    const sourceList = sourcePaths[]
        .map!(a => currPath~a)
        .map!(a => a.dirEntries(SpanMode.depth)).joiner
        .filter!(a => a.isFile && a.name.endsWith(".d")).map!(a => a.name).array;
    const currentOpts = compilerOpts[compiler][config];
    if(exists(buildDir))
    {
        rmdirRecurse(buildDir);
    }
    mkdirRecurse(buildDir);
    const buildStr = compiler ~ " " ~ currentOpts ~ " " ~ importPaths.map!(a => "-I"~a).join(" ") ~ " ";
    auto objFiles = appender!(string[])();
    writeln("Compiling...");
    //foreach(d; parallel(sourceList, 1))
    foreach(d; sourceList)
    {
        const file = d.find(currPath)[currPath.length..$].array;
        const fileDir = buildDir ~ file.retro.find!(a => a == '\\' || a == '/').retro.text;
        if(!exists(fileDir))
        {
            mkdirRecurse(fileDir);
        }
        const objFile = fileDir ~ file.retro.find('.').retro.text ~ "obj";
        //writeln(file);
        //writeln(objFile);
        //writeln(fileDir);
        const cmd = buildStr ~ d ~ " -of"~objFile;
        writeln("----");
        writeln(cmd);
        executeShell(cmd);
        objFiles ~= objFile;
    }
}