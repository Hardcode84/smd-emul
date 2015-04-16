import std.stdio;
import std.file;
import std.algorithm;
import std.range;
import std.array;
import std.parallelism;
import std.process;
import std.exception;
import std.conv;
import std.string;
import std.json;

void main(string[] args)
{
    writeln("Preparing...");
    scope(success) writeln("Success");
    scope(failure) writeln("Failure");
    const string exeName = "smd-emul";
    const string currPath = "./";
    const string cacheFile = ".cache";
    const string[] importPaths = ["d-gamelib","source","d-gamelib/gamelib/3rdparty/DerelictUtil-master/source","d-gamelib/gamelib/3rdparty/DerelictSDL2-master/source"];
    const string[] sourcePaths = ["d-gamelib","source"];
    const string projName = "smd-emul";
    const string buildDir = currPath ~ ".build/";
    const string compiler = "dmd";
    const string config = "debug";

    const dmdConfs = ["debug" : "-debug -g -w -c"];
    const string[string][string] compilerOpts = ["dmd" : dmdConfs];
    const string[string] importOpts = ["dmd" : "-I%s"];
    const string[string] outputOpts = ["dmd" : "-of%s"];

    const sourceList = sourcePaths[]
        .map!(a => currPath~a)
        .map!(a => a.dirEntries(SpanMode.depth)).joiner
        .filter!(a => a.isFile && a.name.endsWith(".d")).map!(a => a.name).array;
    const currentOpts = compilerOpts[compiler][config];
    /*if(exists(buildDir))
    {
        rmdirRecurse(buildDir);
    }*/
    if(!exists(buildDir))
    {
        mkdirRecurse(buildDir);
    }
    JSONValue cache;
    const cachePath = buildDir ~ cacheFile;
    if(exists(cacheFile))
    {
        cache = parseJSON(std.file.readText(cachePath));
    }
    scope(success)
    {
        std.file.write(cachePath,cache.toPrettyString());
    }
    const importOpt = importOpts[compiler];
    const buildStr = compiler ~ " " ~ currentOpts ~ " " ~ importPaths.map!(a => format(importOpt,currPath~a)).join(" ") ~ " ";
    auto objFiles = appender!(string[])();
    const outputOpt = outputOpts[compiler];
    writeln("Compiling...");
    //foreach(d; parallel(sourceList, 1))
    foreach(d; sourceList)
    {
        const file = d;//d.find(currPath)[currPath.length..$].array;
        enforce(exists(file), format("File not found: %s",file));
        const fileDir = buildDir ~ file.retro.find!(a => a == '\\' || a == '/').retro.text;
        if(!exists(fileDir))
        {
            mkdirRecurse(fileDir);
        }
        const objFile = fileDir ~ file.retro.find('.').retro.text ~ "obj";
        //writeln(file);
        //writeln(objFile);
        //writeln(fileDir);
        const cmd = buildStr ~ d ~ " " ~ format(outputOpt,objFile);
        writeln("----");
        writeln(cmd);
        const status = executeShell(cmd);
        enforce(0 == status.status, format("Build error %s, output:\n%s", status.status, status.output));
        objFiles ~= objFile;
    }
    
    const cmd = "dmd " ~ objFiles.data.join(" ") ~ " " ~ format(outputOpt,exeName);
    writeln("Linking...");
    writeln(cmd);
    const status = executeShell(cmd);
    enforce(0 == status.status, format("Build error %s, output:\n%s", status.status, status.output));
}