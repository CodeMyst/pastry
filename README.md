# pastry

CLI tool to create pastes on https://paste.myst.rs/ from files

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
