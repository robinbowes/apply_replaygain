# NAME

apply\_replaygain.pl - write ReplayGain tags to flac files

## SYNOPSIS

$0 \[options\] \[directory\]

    [directory]               Directory containing flac files
                              Uses current directory if not specified

    Options:

     --force, --processall    process all files (don't check existing tags)
     --info                   print informational output
     --debug                  print debugging output
     --usage                  brief usage
     --help                   show detailed help
     --man                    full documentation
     --version                show program version

## OPTIONS

- **force**, **processall**
- **info**
- **debug**
- **usage**
- **help**
- **man**
- **version**

## DESCRIPTION

**apply\_replaygain.pl**

apply\_replaygain looks for all flac files in the supplied directory
and calculates ReplayGain tags. It adds both Track and Album gain tags.

It assumes that files are stored with each album in a separate directory,
i.e. Album gain tags are calculated per directory.

If no directory is supplied on the command line, apply\_replaygain.pl use
the current working directory.

Ensure the Audio::FLAC::Header module is installed.
