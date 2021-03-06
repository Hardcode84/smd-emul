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
    string rebuildStr = "rebuild";
    bool rebuild = params.canFind(rebuildStr);
    const string exeName = "smd-emul";
    const string outputPath = "bin";
    const string currPath = "./";
    const string cacheFile = ".cache";
    const string[] importPaths = ["d-gamelib","source","d-gamelib/gamelib/3rdparty/DerelictUtil-master/source","d-gamelib/gamelib/3rdparty/DerelictSDL2-master/source"];
    const string[] sourcePaths = ["d-gamelib","source"];
    const string buildDir = currPath ~ ".build/";

    const againStr = "again";
    const isAgain = params.canFind(againStr);

    const parallelStr = "parallel";
    const isParallel = params.canFind(parallelStr);

    const helpStr = "help";
    const isHelp = params.canFind(helpStr);

    const sharedStr = "shared";
    const sharedLib = params.canFind(sharedStr);
    const string exeExt = (sharedLib ? ".dll" : ".exe");

    const freeOptions = [parallelStr,rebuildStr,againStr,helpStr].dup.sort;

    enum dmdConfs = [
        "" : "-w -c",
        "debug" : "-debug -g",
        "unittest" : "-unittest",
        "shared" : "-shared -version=M68k_SharedLib",
        "release" : "-O -release -inline",
        "m64" : "-m64"];
    enum ldcConfs = [
        "" : "-oq -w -c",
        "debug" : "-g",
        "unittest" : "-unittest",
        "shared" : "-shared -version=M68k_SharedLib",
        "release" : "-O5 -release",
        "m64" : "-m64"];
    const string[string][string] compilerOpts = ["dmd" : dmdConfs, "ldc2" : ldcConfs ];
    const compilers = compilerOpts.byKey.array.sort;

    enforce(compilers.map!(a => params.count(a)).sum(0) < 2, "More than one compiler.");
    string compiler = chain(params.findAmong(compilers),"dmd".only).front;

    enum dmdLinkConfs = [
        "" : "-w",
        "debug" : "-debug -g",
        "unittest" : "-unittest",
        "shared" : "-shared -version=M68k_SharedLib",
        "release" : "-O -release -inline",
        "m64" : "-m64"];
    enum ldcLinkConfs = [
        "" : "-oq -w",
        "debug" : "-g",
        "unittest" : "-unittest",
        "shared" : "-shared -version=M68k_SharedLib",
        "release" : "-O5 -release",
        "m64" : "-m64"];
    const string[string][string] linkerOpts = ["dmd" : dmdLinkConfs, "ldc2" : ldcLinkConfs ];

    if(isHelp)
    {
        enforce(params.length == 1, "Help must be used alone");
        writeln("Supported options:");
        freeOptions.each!(a => writefln("    %s",a));
        writeln("Supported compilers:");
        foreach(comp;compilers[])
        {
            writefln("    %s:",comp);
            setUnion(
                compilerOpts[comp].byKey.array.sort,
                linkerOpts[comp].byKey.array.sort).
            filter!(a => !a.empty).uniq.each!(a => writefln("        %s",a));
        }
        return;
    }

    const string[string] importOpts = ["dmd" : "-I\"%s\"","ldc2" : "-I=\"%s\""];
    const string[string] outputOpts = ["dmd" : "-of\"%s\"","ldc2" : "-of=\"%s\""];

    const currentOpts = compilerOpts[compiler];
    const currentLinkerOpts = linkerOpts[compiler];
    const importOpt = importOpts[compiler];
    const outputOpt = outputOpts[compiler];

    const knownOptions = chain(
        freeOptions,
        compilers,
        currentOpts.byKey,
        currentLinkerOpts.byKey).map!(a => tuple(a, true)).assocArray;

    auto unknownOptions = params.filter!(a => a !in knownOptions);
    enforce(unknownOptions.empty, format("Unknown options: %s", unknownOptions));

    if(!exists(buildDir))
    {
        mkdirRecurse(buildDir);
    }
    JSONValue cache;
    const cachePath = buildDir ~ cacheFile;
    if(exists(cachePath))
    {
        cache = parseJSON(std.file.readText(cachePath));
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

    string[] config;
    if(isAgain)
    {
        enforce("config" in cache.object && "compiler" in cache.object, "No saved config");
        enforce(0 == params.filter!(a => a in currentOpts || compilers.canFind(a)).count, "again cannot be used with other options");
        compiler = cache["compiler"].str;
        config = cache["config"].str.split(" ").sort;
    }
    else
    {
        config = params.filter!(a => a in currentOpts).array.sort;
    }
    writeln("Compiler: ", compiler);
    string configStr = config.join(" ");

    if(!rebuild)
    {
        if("compiler" !in cache.object || cache["compiler"].str != compiler ||
           "config"   !in cache.object || cache["config"].str   != configStr)
        {
            rebuild = true;
        }
    }

    const buildStr = chain(
        compiler.only,
        currentOpts[""].only,
        config.map!(a => currentOpts.get(a,"")).filter!(a => !a.empty),
        importPaths.map!(a => format(importOpt,currPath ~ a)),
        " ".only).join(" ").to!string;

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
                (timeLastModified(name) != SysTime.fromISOString(cacheFiles[prettyName]["buildTime"].str)).ifThrown(true);

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
        cache.object["config"] = configStr;
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

    const outputDir = currPath ~ outputPath ~ "/"~configStr.replace(" ","_")~"/";
    if(!exists(outputDir))
    {
        mkdirRecurse(outputDir);
    }

    const outFile = outputDir~exeName~exeExt;
    if(rebuild ||
        numCompiledFiles > 0 ||
        !exists(outFile) ||
        "lastBuildTime" !in cache ||
        (timeLastModified(outFile) != SysTime.fromISOString(cache["lastBuildTime"].str)).ifThrown(true))
    {
        const linkCmd = chain(
            compiler.only,
            currentLinkerOpts[""].only,
            params.dup.sort.map!(a => currentLinkerOpts.get(a,"")).filter!(a => !a.empty),
            objFiles.data.map!(a => "\""~a~"\""),
            format(outputOpt,outFile).only).join(" ").to!string;

        const linkStartTime = Clock.currTime();
        writefln("Linking: %s",outFile);
        const status = executeShell(linkCmd);
        writefln("Link Time: %s",Clock.currTime() - linkStartTime);
        enforce(0 == status.status, format("Link error %s, command:\n%s", status.status, linkCmd, status.output));
        cache.object["lastBuildTime"] = JSONValue(timeLastModified(outFile).toISOString());
    }
    else
    {
        writeln("All up to date");
    }
}