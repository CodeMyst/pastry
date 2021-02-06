import std.stdio;
import std.getopt;
import std.file;
import std.path;
import std.typecons;
import core.thread;
import dyaml;
import pastemyst;

private string CONFIG_PATH = "~/.config/pastry/config.yml";
private const string CONFIG_TEMPLATE = "token: \nno-ext: \ndefault-expires: \n";

string title = "";
ExpiresIn expires = ExpiresIn.never;
string overrideLang = "";
string token = "";
bool isPrivate = false;
string noExt = "";
ExpiresIn defaultExpires = ExpiresIn.never;

PastyCreateInfo[] pasties;

string[string] langCache;

public void main(string[] args)
{
    // todo: windows
    CONFIG_PATH = expandTilde(CONFIG_PATH);

    auto helpInfo = getopt(
        args,
        "title|t", "title of the paste", &title,
        "expires|e","when the paste expires, possible options: " ~
            "never, oneHour, twoHours, tenHours, oneDay, twoDays, oneWeek, oneMonth, oneYear", &expires,
        "lang|l", "set the language of *all* files to the specified one", &overrideLang,
        "private|p", "make a private paste, you have to set the token first", &isPrivate,
        "set-default-expires", "set the default expires in time", &defaultExpires,
        "set-token", "sets the token and saves it for future runs of the program. this way you can create private " ~
            "pastes and pastes that show on your pastemyst profile. you can get the token on your pastemyst " ~
            "profile settings page. the token is saved in plaintext in $HOME/.config/pastry/config.yml", &token,
        "set-no-extension", "sets which lang to use when a file doesnt have an extension, you can provide any " ~
            "supported language or \"autodetect\"", &noExt
    );

    if (helpInfo.helpWanted)
    {
        printHelp(helpInfo.options);
        return;
    }

    if (token != "")
    {
        yamlSet("token", token);
        writeln("token set");
        return;
    }
    else
    {
        token = yamlGet("token");
    }

    if (overrideLang != "")
    {
        if (getLanguageByExtension(overrideLang).isNull)
        {
            // todo: return error status code
            writeln("language " ~ overrideLang ~ " doesnt exist");
            return;
        }
    }

    if (isPrivate && token == "")
    {
        // todo: return error status code
        writeln("cant create a private paste without setting the token. set the token with --set-token");
        return;
    }

    if (noExt != "")
    {
        yamlSet("no-ext", noExt);
        writeln("no extension language set");
        return;
    }
    else
    {
        noExt = yamlGet("no-ext");

        if (noExt == "")
        {
            noExt = "plain text";
        }
    }

    if (defaultExpires != ExpiresIn.never)
    {
        yamlSet("default-expires", defaultExpires);
        writeln("default expires set");
        return;
    }
    else
    {
        const res = yamlGet("default-expires");
        if (!valueToEnum!ExpiresIn(res).isNull)
        {
            defaultExpires = valueToEnum!ExpiresIn(res).get();
        }
    }

    foreach (arg; args[1..$])
    {
        if (isDir(arg))
        {
            uploadDir(arg);
        }
        else
        {
            uploadFile(arg);
        }
    }

    ExpiresIn actualExpires = ExpiresIn.never;

    if (expires == ExpiresIn.never && defaultExpires != ExpiresIn.never)
    {
        actualExpires = defaultExpires;
    }

    const createInfo = PasteCreateInfo(title, actualExpires, isPrivate, false, "", pasties);

    const res = createPaste(createInfo, token);

    writeln("https://paste.myst.rs/" ~ res.id);
}

private void uploadDir(string path)
{
    foreach (string entry; dirEntries(path, SpanMode.shallow))
    {
        if (isDir(entry))
        {
            uploadDir(entry);
        }
        else
        {
            uploadFile(entry);
        }
    }
}

private void uploadFile(string path)
{
    string contents = readText(path);
    string ext = extension(path);

    string lang;

    if (overrideLang == "")
    {
        if (ext.length > 1)
        {
            if (ext[1..$] in langCache)
            {
                lang = langCache[ext[1..$]];
            }
            else
            {
                auto searchedLang = getLanguageByExtension(ext[1..$]);
                if (searchedLang.isNull)
                {
                    lang = "plain text";
                }
                else
                {
                    lang = searchedLang.get().name;
                    langCache[ext[1..$]] = lang;
                }
                // sleep for 200ms to not hit rate limit
                Thread.sleep(dur!("msecs")(200));
            }
        }
        else
        {
            lang = noExt;
        }
    }
    else
    {
        lang = overrideLang;
    }

    pasties ~= PastyCreateInfo(baseName(path), lang, contents);
}

private void yamlSet(string key, string val)
{
    if (!exists(CONFIG_PATH))
    {
        mkdirRecurse(dirName(CONFIG_PATH));
        std.file.write(CONFIG_PATH, CONFIG_TEMPLATE);
    }

    Node root = Loader.fromFile(CONFIG_PATH).load();

    root[key] = val;

    dumper().dump(File(CONFIG_PATH, "w").lockingTextWriter, root);
}

private string yamlGet(string key)
{
    if (!exists(CONFIG_PATH))
    {
        return "";
    }

    Node root = Loader.fromFile(CONFIG_PATH).load();

    string res = root[key].as!string();

    return res == "null" ? "" : res;
}

private void printHelp(Option[] options)
{
    writeln("--------------------------------------------------------------------------------");
    writeln("pastry - command line tool to paste files to https://paste.myst.rs/");
    writeln("--------------------------------------------------------------------------------");

    writeln();

    writeln("usage:\n    pastry <list of files and/or directories> [options]\n");

    writeln("options:");

    foreach (opt; options[0..$-1])
    {
        // writeln("    " ~ opt.optLong ~ ", " ~ opt.optShort ~ "\t\t" ~  opt.help);
        writef("    %-25s %-3s %-s\n", opt.optLong, opt.optShort, opt.help);
    }

    writef("    %-25s %-3s %-s\n", "--help", "-h", "displays this help screen");
}

private Nullable!T valueToEnum(T, R)(R value) @safe
{
    T[R] lookup;

    static foreach (member; __traits(allMembers, T))
    {
        lookup[cast(R) __traits(getMember, T, member)] = __traits(getMember, T, member);
    }

    if (value in lookup)
    {
        return (*(value in lookup)).nullable;
    }
    else
    {
        return Nullable!T.init;
    }
}
