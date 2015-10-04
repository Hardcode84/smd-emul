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
import std.typecons;
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

    auto params = args[1..$];
    bool rebuild = params.canFind("rebuild");
    const string exeName = "smd-emul";
    const string outputPath = "bin";
    const string currPath = "./";
    const string cacheFile = ".cache";
    const string[] importPaths = ["d-gamelib","source","d-gamelib/gamelib/3rdparty/DerelictUtil-master/source","d-gamelib/gamelib/3rdparty/DerelictSDL2-master/source"];
    const string[] sourcePaths = ["d-gamelib","source"];
    const string buildDir = currPath ~ ".build/";    

    const sharedStr = "shared";
    const sharedLib = params.canFind(sharedStr);

    const parallelStr = "parallel";
    const isParallel = params.canFind(parallelStr);
    const string exeExt = (sharedLib ? ".dll" : ".exe");

    const dmdConfs = [
        "" : "-w -c",
        "debug" : "-debug -g",
        "unittest" : "-unittest",
        "shared" : "-shared -version=M68k_SharedLib",
        "release" : "-O -release -inline",
        "m64" : "-m64"];
    const ldcConfs = [
        "" : "-oq -w -c",
        "debug" : "-g",
        "unittest" : "-unittest",
        "shared" : "-shared -version=M68k_SharedLib",
        "release" : "-O5 -release",
        "m64" : "-m64"];
    const string[string][string] compilerOpts = ["dmd" : dmdConfs, "ldc2" : ldcConfs ];
    const compilers = compilerOpts.byKey.array;

    enforce(compilers.map!(a => params.count(a)).sum(0) < 2, "More than one compiler.");
    const string compiler = chain(params.findAmong(compilers),"dmd".only).front;

    const dmdLinkConfs = [
        "" : "-w",
        "debug" : "-debug -g",
        "unittest" : "-unittest",
        "shared" : "-shared -version=M68k_SharedLib",
        "release" : "-O -release -inline",
        "m64" : "-m64"];
    const ldcLinkConfs = [
        "" : "-oq -w",
        "debug" : "-g",
        "unittest" : "-unittest",
        "shared" : "-shared -version=M68k_SharedLib",
        "release" : "-O5 -release",
        "m64" : "-m64"];
    const string[string][string] linkerOpts = ["dmd" : dmdLinkConfs, "ldc2" : ldcLinkConfs ];

    const string[string] importOpts = ["dmd" : "-I\"%s\"","ldc2" : "-I=\"%s\""];
    const string[string] outputOpts = ["dmd" : "-of\"%s\"","ldc2" : "-of=\"%s\""];

    const currentOpts = compilerOpts[compiler];
    const currentLinkerOpts = linkerOpts[compiler];
    const importOpt = importOpts[compiler];
    const outputOpt = outputOpts[compiler];

    const knownOptions = chain(
        parallelStr.only,
        compilers,
        currentOpts.byKey,
        currentLinkerOpts.byKey).map!(a => tuple(a, true)).assocArray;

    auto unknownOptions = params.filter!(a => a !in knownOptions);
    enforce(unknownOptions.empty, format("Unknown options: %s", unknownOptions));

    writeln("Compiler: ", compiler);

    const buildStr = chain(
        compiler.only,
        currentOpts[""].only,
        params.dup.sort.map!(a => currentOpts.get(a,"")).filter!(a => !a.empty),
        importPaths.map!(a => format(importOpt,currPath ~ a)),
        " ".only).join(" ").to!string;

    string config = params.filter!(a => a in currentOpts).array.sort.join(" ");

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

    if(!rebuild)
    {
        if("compiler" !in cache.object || cache["compiler"].str != compiler ||
           "config"   !in cache.object || cache["config"].str   != config)
        {
            rebuild = true;
        }
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
    foreach(const ref e; csourceList[])
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
    int compiledFiles = 0;
    const totalFiles = csourceList.length;
    void compilefunc(const ref BuildEntry e)
    {
        SysTime compStartTime;
        if(e.changed)
        {
            string cmd = buildStr ~ e.name ~ " " ~ format(outputOpt,e.objName);
            Pid pid;
            synchronized(mutex)
            {
                compStartTime = Clock.currTime();
                writefln("Compiling: \"%s\"",e.prettyName);
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
            ++compiledFiles;
            if(e.changed)
            {
                ++numCompiledFiles;
                writefln("[%s/%s] Compiled: \"%s\", %s",compiledFiles,totalFiles,e.prettyName,Clock.currTime() - compStartTime);
            }
            else
            {
                writefln("[%s/%s] \"%s\" is up to date",compiledFiles,totalFiles,e.prettyName);
            }
            objFiles ~= e.objName;
        }
    }

    if(isParallel)
    {
        foreach(const ref e; parallel(csourceList[], 1)) compilefunc(e);
    }
    else
    {
        foreach(const ref e; csourceList[]) compilefunc(e);
    }
    writeln("Files compiled: ",numCompiledFiles);

    const outputDir = currPath ~ outputPath ~ "/"~config~"/";
    if(!exists(outputDir))
    {
        mkdirRecurse(outputDir);
    }

    const linkStr = chain(
        compiler.only,
        currentLinkerOpts[""].only,
        params.dup.sort.map!(a => currentLinkerOpts.get(a,"")).filter!(a => !a.empty),
        objFiles.data.map!(a => "\""~a~"\""),
        format(outputOpt,outputDir~exeName~exeExt).only).join(" ").to!string;

    const linkStartTime = Clock.currTime();
    writeln("Linking...");
    writeln(linkStr);
    const status = executeShell(linkStr);
    writefln("Link Time: %s",Clock.currTime() - linkStartTime);
    enforce(0 == status.status, format("Build error %s, output:\n%s", status.status, status.output));
}