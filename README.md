# pastry

command line tool to paste files to https://paste.myst.rs/

## download

you can get the binaries from the [release page](https://github.com/CodeMyst/pastry/releases) or build it from source

there is an arch package in the aur: [pastry-aur](https://aur.archlinux.org/packages/pastry/)

to build from source you will need dmd and dub, then just run `dub build`

## usage

create paste from files
```
pastry file1.txt file2.txt someDir/
```

set title
```
pastry file1.txt -t "paste title"
```

set language of all files
```
pastry file1 -l markdown
```

set expires in
```
pastry file1 -e oneHour
```

setting the default expires in time, this value will be used when you dont specify the `--expires|-e` option
```
pastry --set-default-expires oneDay
```

setting the language to be used for files without an extension, default is plaintext
```
pastry --set-no-extension markdown
```

set the token, you can get your token on your pastemyst profile settings page. once you set the token you can create private pastes, and all pastes you make will show on your profile
```
pastry --set-token <YOUR_TOKEN>

# create private paste
pastry file1.txt -p
```
