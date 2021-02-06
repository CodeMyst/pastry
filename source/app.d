import std.stdio;
import std.getopt;
import std.file;
import std.path;
import pastemyst;

void main(string[] args)
{
    string filePath = args[1];

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

    const pasty = PastyCreateInfo(baseName(filePath), lang, contents);
    const createInfo = PasteCreateInfo("", ExpiresIn.never, false, false, "", [pasty]);

    const res = createPaste(createInfo);

    writeln("https://paste.myst.rs/" ~ res.id);
}
