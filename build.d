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
import std.datetime;
import std.regex;

auto moduleRegex = ctRegex!("module.*;");
auto importRegex = ctRegex!("import.*;");

void main(string[] args)
{
    writeln("Preparing...");
    scope(success) writeln("Success");
    scope(failure) writeln("Failure");
    const bool rebuild = args[1..$].canFind("rebuild");
    const string exeName = "smd-emul";
    const string outputPath = "bin";
    const string currPath = "./";
    const string cacheFile = ".cache";
    const string[] importPaths = ["d-gamelib","source","d-gamelib/gamelib/3rdparty/DerelictUtil-master/source","d-gamelib/gamelib/3rdparty/DerelictSDL2-master/source"];
    const string[] sourcePaths = ["d-gamelib","source"];
    const string buildDir = currPath ~ ".build/";
    const string compiler = "dmd";
    const string config = "debug";

    const dmdConfs = ["debug" : "-debug -g -w -c"];
    const string[string][string] compilerOpts = ["dmd" : dmdConfs];
    const string[string] importOpts = ["dmd" : "-I%s"];
    const string[string] outputOpts = ["dmd" : "-of%s"];

    const currentOpts = compilerOpts[compiler][config];
    if(!exists(buildDir))
    {
        mkdirRecurse(buildDir);
    }
    JSONValue cache;
    const cachePath = buildDir ~ cacheFile;
    if(exists(cachePath))
    {
        if(rebuild)
        {
            remove(cachePath);
        }
        else
        {
            cache = parseJSON(std.file.readText(cachePath));
        }
    }
    scope(exit)
    {
        std.file.write(cachePath,cache.toPrettyString());
    }
    const importOpt = importOpts[compiler];
    const buildStr = compiler ~ " " ~ currentOpts ~ " " ~ importPaths.map!(a => format(importOpt,currPath~a)).join(" ") ~ " ";
    auto objFiles = appender!(string[])();
    const outputOpt = outputOpts[compiler];

    if(cache.isNull())
    {
        string[string] dummy;
        cache = JSONValue(["files" : dummy]);
    }
    JSONValue cacheFiles = cache.object["files"];
    if(cacheFiles.isNull())
    {
        string[string] dummy;
        cacheFiles = JSONValue(dummy);
    }

    char[] readBuf;
    struct BuildEntry
    {
        string name;
        string prettyName;
        string fileDir;
        string objName;
        string moduleName;
        string[] dependencies;
        bool changed;
        this(string name_)
        {
            name = name_;
            prettyName = name.find(currPath)[currPath.length..$].retro.find('.').retro.text;
            fileDir = buildDir ~ name.retro.find!(a => a == '\\' || a == '/').retro.text;
            objName = fileDir ~ name.retro.find('.').retro.text ~ "obj";
            changed = rebuild || !exists(objName) || (prettyName !in cacheFiles.object) || ("buildTime" !in cacheFiles[prettyName].object) ||
                ("moduleName" !in cacheFiles[prettyName].object) ||
                ("dependencies" !in cacheFiles[prettyName].object) ||
                timeLastModified(name) == SysTime.fromISOString(cacheFiles[prettyName]["buildTime"].str);
            if(!changed)
            {
                try
                {
                    moduleName = cacheFiles[prettyName]["moduleName"].str;
                    dependencies = cacheFiles[prettyName]["dependencies"].array.map!(a => a.str).array;
                }
                catch(Exception e)
                {
                    writeln("BuildEntry error: ",e);
                    changed = true;
                }
            }

            if(changed)
            {
                auto f = File(name, "r");
                while(f.readln(readBuf))
                {
                    auto m = matchFirst(readBuf,moduleRegex);
                    if(!m.empty)
                    {
                        moduleName = m[0]["module".length..$-1].strip.idup;
                    }
                    dependencies ~= matchAll(readBuf,importRegex).map!(a => a.hit["import".length..$-1]
                        .splitter(':').takeOne[0].splitter(',').map!(a => a.strip).filter!(a => !a.empty)).map!text.array;
                }
            }
            if(moduleName.length == 0)
            {
                moduleName = prettyName.map!(a => (a == '\\' || a == '/' ? '.' : a)).text;
                writefln("Empty module name, generated \"%s\"",moduleName);
            }
        }

        void save()
        {
            cacheFiles.object[prettyName] = JSONValue(["buildTime" : timeLastModified(name).toISOString(),
                                                       "moduleName" : moduleName]);
            cacheFiles[prettyName].object["dependencies"] = dependencies;
        }
    }
    const sourceList = sourcePaths[]
        .map!(a => currPath~a)
        .map!(a => a.dirEntries(SpanMode.depth)).joiner
        .filter!(a => a.isFile && a.name.endsWith(".d")).map!(a => a.name).array;

    scope(exit) cache.object["files"] = cacheFiles;
    writeln("Compiling...");
    //foreach(d; parallel(sourceList, 1))
    foreach(d; sourceList)
    {
        writeln("----");
        const file = d;
        const prettyFile = d.find(currPath)[currPath.length..$].text;
        enforce(exists(file), format("File not found: %s",file));
        const fileDir = buildDir ~ file.retro.find!(a => a == '\\' || a == '/').retro.text;
        if(!exists(fileDir))
        {
            mkdirRecurse(fileDir);
        }
        const objFile = fileDir ~ file.retro.find('.').retro.text ~ "obj";
        scope(success) objFiles ~= objFile;
        if(!rebuild &&
            exists(objFile) &&
            (prettyFile in cacheFiles.object) &&
            timeLastModified(file) == SysTime.fromISOString(cacheFiles[prettyFile].str))
        {
            writeln(format("\"%s\" is up to date",prettyFile));
            continue;
        }
        scope(success) cacheFiles.object[prettyFile] = JSONValue(timeLastModified(file).toISOString());
        //writeln(file);
        //writeln(objFile);
        //writeln(fileDir);
        const cmd = buildStr ~ d ~ " " ~ format(outputOpt,objFile);
        writeln(cmd);
        const status = executeShell(cmd);
        enforce(0 == status.status, format("Build error %s, output:\n%s", status.status, status.output));
    }
    const outputDir = currPath ~ outputPath ~ "/"~config~"/";
    if(!exists(outputDir))
    {
        mkdirRecurse(outputDir);
    }

    const cmd = "dmd " ~ objFiles.data.join(" ") ~ " " ~ format(outputOpt,outputDir~exeName);
    writeln("Linking...");
    writeln(cmd);
    const status = executeShell(cmd);
    enforce(0 == status.status, format("Build error %s, output:\n%s", status.status, status.output));
}