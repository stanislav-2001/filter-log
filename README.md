# Filter log

This is a bash script that is able to print out filtered lines from a Java log file by given parameters.

## Usage

Set `filterlog.sh` as executable:
```bash
chmod +x filterlog.sh
```

The script presumes the log file exists on path `\var\log\filterlog.log`. The feature to put your own path is not yet implemented.
You can copy your file to this path, and you can use the `flog.log` example file. The scripts presumes LF line endings.

You can use the script like this:
```bash
./filterlog.sh <parameters>
```
Where parameters are the following:
```bash
-m                            Prints lines not older than 5 minutes
-H                            Prints lines not older than a hour
-u <user>                     Prints lines with given user
-g <string>                   Prints lines with message that contains given string
-j <trieda>                   Prints lines by exact Java class name
-l <DEBUG|INFO|WARN|ERROR>    Prints lines with log level this or higher
-h                            Prints help
```
If you don't provide a parameter, it will return all lines of the file.

