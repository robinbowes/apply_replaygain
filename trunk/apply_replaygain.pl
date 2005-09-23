#!/usr/bin/perl -w
#
# apply_replaygain.pl
#
# Applies replaygain tags to all .flac files found within the
# specified directory tree.
#
# Album gain is also calculated for all files within each directory.
#
# Usage:
#
#  apply_replaygain.pl [options] [directory]
#
# Options:
#  --processall      Default behaviour is if all files in the directory
#                    have ReplayGain information (specifically, the
#                    REPLAY_ALBUM_GAIN tag) then the directory is skipped.
#                    This option recalculates ReplayGain information
#                    for all directories.
#	--info           Output information (directories processed, etc.)
#	--debug          Output debugging information
#
#  directory is the directory to scan for flac files. If omitted, the
#  current directory is processed.
#
# Possible customisations:
#  location of perl in line 1
#  location of metaflac program (see $metaflac below)
#  metaflac arguments (see $metaflacargs below)
#
# Robin Bowes (robin@robinbowes.com), 2004

use strict;
use Audio::FLAC::Header;
use Getopt::Long;

#------------------- Begin User-changeable options --------------------

# Assume metaflac is in the path.
# Change this line if it is not.
my $metaflaccmd = "metaflac";

# Depending on your application, you may not require --preserve-modtime
my @flacargs = qw ( --preserve-modtime --add-replay-gain );

#-------------------- End User-changeable options ---------------------

use vars qw (
  $processall
  $d_info
  $d_debug
);

# Set defaults
$processall = 0;
$d_info     = 0;
$d_debug    = 0;

GetOptions(
    "processall!" => \$processall,
    "info!"       => \$d_info,
    "debug!"      => \$d_debug
);

showusage() unless ( scalar @ARGV <= 1 );

# Use current directory if no dir specified on command-line
@ARGV = ('.') unless @ARGV;

process_dirs(@ARGV);

1;
## End of main program

sub process_dirs {
    my @dirlist = @_;
    foreach my $dir (@dirlist) {
        $::d_info && msg("Checking directory: $dir\n");

        # get all directory entries
        opendir( DIR, $dir ) or die "Couldn't open directory $dir\n";
        my @direntries = readdir(DIR)
          or die "Couldn't read directory entries for directory $dir\n";
        closedir(DIR);

        # get all target files within the present directory
        my @target_files = map { $_->[1] }    # extract pathnames
          map { [ $_, "$dir/$_" ] }           # form (name, path)
          grep { /\.flac$/ }                  # just flac files
          sort @direntries;

        # get all subdirs of the present directory
        my @subdirs = map { $_->[1] }         # extract pathnames
          grep { -d $_->[1] }                 # only directories
          map { [ $_, "$dir/$_" ] }           # form (name, path)
          grep { !/^\.\.?$/ }                 # not . or ..
          sort @direntries;

        $::d_debug && msg("processall:   $processall\n");

        # If any files exist to be processed
        if (@target_files) {

            # Don't bother checking the target files if
            # processall options specified
            my $processdir = 0;
            if ( !$processall ) {

                # Check all files for ReplayGain tags
                # Process the whole directory is any files found without
                # ReplayGain.
                foreach my $flacfile (@target_files) {

                    $::d_debug && msg("processing file:   $flacfile\n");

                    my $flac = Audio::FLAC::Header->new($flacfile);

                    # Check for existence of REPLAYGAIN tag
                    my $RPGTag = $flac->tags("REPLAYGAIN_ALBUM_GAIN");
                    $processdir = 1 unless defined $RPGTag;

                    $::d_debug && msg("RPGTag:   $RPGTag\n")
                      unless !defined $RPGTag;
                }
            }

            $::d_debug && msg("process_dir:   $processdir\n");

            if ( $processall || $processdir ) {

                $::d_info && msg("Processing dir: $dir\n");

                # run metaflac on all target files in present directory
                system( $metaflaccmd, @flacargs, @target_files );
            }
        }

        # process any subdirs of present directory
        if (@subdirs) {
            &process_dirs(@subdirs);
        }
    }
}

sub showusage {
    print "Usage goes here\n";
    exit 1;
}

sub msg {
    my $msg = shift;
    print "$msg";
}

# vim: autoindent
# vim: textwidth=78
# vim: backspace=indent,eol,start
# vim: tabstop=4
# vim: expandtab
# vim: shiftwidth=4
# vim: shiftwidth=4:
# vim: softtabstop=4:
