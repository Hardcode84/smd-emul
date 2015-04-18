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
import core.sync.mutex;

auto moduleRegex = ctRegex!("module\\s.*[^;];");
auto importRegex = ctRegex!("import\\s.*[^;];");

void main(string[] args)
{
    const startTime = Clock.currTime();
    scope(exit) writefln("Total time: %s",Clock.currTime() - startTime);
    writeln("Preparing...");
    scope(success) writeln("Success");
    scope(failure) writeln("Failure");
    bool rebuild = args[1..$].canFind("rebuild");
    const string exeName = "smd-emul";
    const string outputPath = "bin";
    const string currPath = "./";
    const string cacheFile = ".cache";
    const string[] importPaths = ["d-gamelib","source","d-gamelib/gamelib/3rdparty/DerelictUtil-master/source","d-gamelib/gamelib/3rdparty/DerelictSDL2-master/source"];
    const string[] sourcePaths = ["d-gamelib","source"];
    const string buildDir = currPath ~ ".build/";
    const string compiler = "dmd";
    const string config = args[1..$].canFind("unittest") ? "unittest" : "debug";

    const dmdConfs = ["debug" : "-debug -g -w -c","unittest" : "-g -w -c -unittest"];
    const string[string][string] compilerOpts = ["dmd" : dmdConfs];
    const string[string] importOpts = ["dmd" : "-I\"%s\""];
    const string[string] outputOpts = ["dmd" : "-of\"%s\""];

    const currentOpts = compilerOpts[compiler][config];
    const importOpt = importOpts[compiler];
    const buildStr = compiler ~ " " ~ currentOpts ~ " " ~ importPaths.map!(a => format(importOpt,currPath~a)).join(" ") ~ " ";
    const outputOpt = outputOpts[compiler];
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
    scope(exit) std.file.write(cachePath,cache.toPrettyString());

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
    if("compiler" !in cache.object || cache["compiler"].str != compiler ||
       "config"   !in cache.object || cache["config"].str   != config)
    {
        rebuild = true;
    }

    char[] readBuf;
    struct BuildEntry
    {
        string name;
        string prettyName;
        string objDir;
        string objName;
        string moduleName;
        string[] dependencies;
        bool changed;
        this(string name_)
        {
            name = name_;
            enforce(exists(name), format("File not found: \"%s\"",name));
            prettyName = name.find(currPath)[currPath.length..$].text;
            objDir = buildDir ~ prettyName.retro.find!(a => a == '\\' || a == '/').retro.text;
            objName = objDir ~ prettyName.retro.splitter!(a => a == '\\' || a == '/').front.find('.').array.retro.text ~ "obj";
            changed = rebuild || !exists(objName) || (prettyName !in cacheFiles.object) ||
                ("buildTime" !in cacheFiles[prettyName].object) ||
                ("moduleName" !in cacheFiles[prettyName].object) ||
                ("dependencies" !in cacheFiles[prettyName].object) ||
                timeLastModified(name) != SysTime.fromISOString(cacheFiles[prettyName]["buildTime"].str);
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
                        moduleName = m[0].stripLeft["module".length..$-1].strip.idup;
                    }
                    const deps = matchAll(readBuf,importRegex).map!(a => a.hit.stripLeft["import".length..$-1]
                        .splitter(':').front.splitter(',').map!(a => a.splitter('=').retro.front)
                        .map!(a => a.text.strip).filter!(a => !a.empty).map!text).joiner.array;
                    dependencies ~= deps;
                }
            }
            if(moduleName.length == 0)
            {
                moduleName = prettyName.map!(a => dchar(a == '\\' || a == '/' ? '.' : a)).text;
                writefln("Empty module name, generated \"%s\"",moduleName);
            }
        }

        void save() const
        {
            cacheFiles.object[prettyName] = JSONValue(["buildTime" : timeLastModified(name).toISOString(),
                                                       "moduleName" : moduleName]);
            cacheFiles[prettyName].object["dependencies"] = dependencies;
        }
    }
    auto createEntry(string name)
    {
        return BuildEntry(name);
    }
    auto sourceList = sourcePaths[]
        .map!(a => currPath~a)
        .map!(a => a.dirEntries(SpanMode.depth)).joiner
        .filter!(a => a.isFile && a.name.endsWith(".d")).map!(a => createEntry(a.name)).array;

    if(!rebuild)
    {
        bool[string] changedModules;
        foreach(ref e; sourceList)
        {
            if(e.changed) changedModules[e.moduleName] = true;
        }
        writeln("Changed modules: ",changedModules.byKey());
        while(true)
        {
            bool hasChanges = false;
            foreach(ref e; sourceList)
            {
                if(!e.changed && e.dependencies.any!(a => a in changedModules))
                {
                    changedModules[e.moduleName] = true;
                    e.changed = true;
                    hasChanges = true;
                }
            }
            if(!hasChanges) break;
        }
        writeln("Changed modules with deps: ",changedModules.byKey());
    }

    writeln("Compiling...");
    int numCompiledFiles = 0;

    auto objFiles = appender!(string[])();
    auto mutex = new Mutex;
    const csourceList = sourceList;
    foreach(const ref e; csourceList)
    {
        if(e.changed && e.objName.exists)
        {
            writefln("Remove \"%s\"" ,e.objName);
            e.objName.remove;
        }
    }
    scope(exit)
    {
        cache.object["files"] = cacheFiles;
        cache.object["compiler"] = compiler;
        cache.object["config"] = config;
    }
    foreach(const ref e; parallel(csourceList, 1))
    {
        if(e.changed)
        {
            string cmd = buildStr ~ e.name ~ " " ~ format(outputOpt,e.objName);
            Pid pid;
            synchronized(mutex)
            {
                if(!exists(e.objDir))
                {
                    mkdirRecurse(e.objDir);
                }
                pid = spawnShell(cmd);
            }

            const status = wait(pid);
            enforce(0 == status, format("Build error %s, command:\n%s", status, cmd));
        }

        synchronized(mutex)
        {
            e.save();
            if(e.changed)
            {
                ++numCompiledFiles;
                writefln("Compiled: \"%s\"",e.prettyName);
            }
            else
            {
                writefln("\"%s\" is up to date",e.prettyName);
            }
            objFiles ~= e.objName;
        }
    }
    writeln("Files compiled: ",numCompiledFiles);

    const outputDir = currPath ~ outputPath ~ "/"~config~"/";
    if(!exists(outputDir))
    {
        mkdirRecurse(outputDir);
    }

    const cmd = compiler ~ " " ~ currentOpts ~ " " ~ objFiles.data.map!(a => "\""~a~"\"").join(" ") ~ " " ~ format(outputOpt,outputDir~exeName);
    writeln("Linking...");
    writeln(cmd);
    const status = executeShell(cmd);
    enforce(0 == status.status, format("Build error %s, output:\n%s", status.status, status.output));
}