import std.stdio;
import std.getopt;
import std.file;
import std.path;
import pastemyst;

void main(string[] args)
{
    PastyCreateInfo[] pasties;

    foreach (arg; args[1..$])
    {
        string filePath = arg;

        string contents = readText(filePath);
        string ext = extension(filePath);

        string lang;

        if (ext.length > 1)
        {
            lang = getLanguageByExtension(ext[1..$]).get().name;
        }
        else
        {
            lang = "plain text";
        }

        pasties ~= PastyCreateInfo(baseName(filePath), lang, contents);
    }

    const createInfo = PasteCreateInfo("", ExpiresIn.never, false, false, "", pasties);

    const res = createPaste(createInfo);

    writeln("https://paste.myst.rs/" ~ res.id);
}
