import std.stdio;
import std.getopt;
import std.file;
import std.path;
import dyaml;
import pastemyst;

private string CONFIG_PATH = "~/.config/pastry/config.yml";
private const string CONFIG_TEMPLATE = "token: \nno-ext: \n";

public void main(string[] args)
{
    // todo: windows
    CONFIG_PATH = expandTilde(CONFIG_PATH);

    string title = "";
    ExpiresIn expires = ExpiresIn.never;
    string overrideLang = "";
    string token = "";
    bool isPrivate = false;
    string noExt = "";

    auto helpInfo = getopt(
        args,
        "title|t", "title of the paste", &title,
        "expires|e","when the paste expires, possible options: " ~
            "never, oneHour, twoHours, tenHours, oneDay, twoDays, oneWeek, oneMonth, oneYear", &expires,
        "lang|l", "set the language of *all* files to the specified one", &overrideLang,
        "set-token", "sets the token and saves it for future runs of the program. this way you can create private " ~
            "pastes and pastes that show on your pastemyst profile. you can get the token on your pastemyst " ~
            "profile settings page. the token is saved in plaintext in $HOME/.config/pastry/config.yml", &token,
        "private|p", "make a private paste, you have to set the token first", &isPrivate,
        "set-no-extension", "sets which lang to use when a file doesnt have an extension, you can provide any " ~
            "supported language or \"autodetect\"", &noExt
    );

    if (helpInfo.helpWanted)
    {
        defaultGetoptPrinter("pastry - create pastes from the commandline - https://paste.myst.rs/\n",
                helpInfo.options);
        return;
    }

    if (token != "")
    {
        yamlSet("token", token);
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

    PastyCreateInfo[] pasties;

    foreach (arg; args[1..$])
    {
        string filePath = arg;

        string contents = readText(filePath);
        string ext = extension(filePath);

        string lang;

        if (overrideLang == "")
        {
            if (ext.length > 1)
            {
                lang = getLanguageByExtension(ext[1..$]).get().name;
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

        pasties ~= PastyCreateInfo(baseName(filePath), lang, contents);
    }

    const createInfo = PasteCreateInfo(title, expires, isPrivate, false, "", pasties);

    const res = createPaste(createInfo, token);

    writeln("https://paste.myst.rs/" ~ res.id);
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
