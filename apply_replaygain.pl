#!/usr/bin/env perl
#
# $Id$
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
#   --info           Output information (directories processed, etc.)
#   --debug          Output debugging information
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
use warnings;
use Audio::FLAC::Header;
use Getopt::Long;
use Pod::Usage;

#------------------- Begin User-changeable options --------------------

# Assume metaflac is in the path.
# Change this line if it is not.
our $metaflaccmd = "metaflac";

# Depending on your application, you may not require --preserve-modtime
our @flacargs = qw ( --preserve-modtime --add-replay-gain );

#-------------------- End User-changeable options ---------------------

our %Options;
$Options{info} = 1;

GetOptions( \%Options,
            "force|processall!",
            "info|quiet!",
            "debug!",
            "usage"     => sub { pod2usage() },
            "help"      => sub { pod2usage( -verbose => 1 ) },
            "man"       => sub { pod2usage( -verbose => 2 ) },
            "version"   => sub { show_version() },
) or pod2usage();

pod2usage() unless ( scalar @ARGV <= 1 );

# Use current directory if no dir specified on command-line
@ARGV = ('.') unless @ARGV;

process_dirs(@ARGV);

1;
## End of main program

sub process_dirs {
    my @dirlist = @_;
    foreach my $dir (@dirlist) {
        # remove trailing slash from directory
        $dir =~ s/\/$//;

        $::Options{info} && msg("Checking directory: $dir\n");

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

        $::Options{debug} && msg("force:   $::Options{force}\n");

        # If any files exist to be processed
        if (@target_files) {

            # Don't bother checking the target files if
            # processall options specified
            my $processdir = 0;
            if ( !$::Options{force} ) {

                # Check all files for ReplayGain tags
                # Process the whole directory is any files found without
                # ReplayGain.
                foreach my $flacfile (@target_files) {

                    $::Options{debug} && msg("processing file:   $flacfile\n");

                    my $flac = Audio::FLAC::Header->new($flacfile);

                    # Check for existence of REPLAYGAIN tag
                    my $RPGTag = $flac->tags("REPLAYGAIN_ALBUM_GAIN");
                    $processdir = 1 unless defined $RPGTag;

                    $::Options{debug} && msg("RPGTag:   $RPGTag\n")
                      unless !defined $RPGTag;

                    # no need to continue checking if untagged file found
                    last if $processdir;
                }
            }

            $::Options{debug} && msg("process_dir:   $processdir\n");

            if ( $::Options{force} || $processdir ) {

                $::Options{info} && msg("Processing dir: $dir\n");

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

sub msg {
    my $msg = shift;
    print "$msg";
}

__END__

=head1 NAME

apply_replaygain.pl - write ReplayGain tags to flac files

=head1 SYNOPSIS

$0 [options] [directory]

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

=head1 OPTIONS

=over 8

=item B<force>, B<processall>

=item B<info>

=item B<debug>

=item B<usage>

=item B<help>

=item B<man>

=item B<version>

=back

=head1 DESCRIPTION

B<apply_replaygain.pl>

apply_replaygain looks for all flac files in the supplied directory
and calculates ReplayGain tags. It adds both Track and Album gain tags.

It assumes that files are stored with each album in a separate directory,
i.e. Album gain tags are calculated per directory.

If no directory is supplied on the command line, apply_replaygain.pl use
the current working directory.

=cut

# vim: autoindent
# vim: textwidth=78
# vim: backspace=indent,eol,start
# vim: tabstop=4
# vim: expandtab
# vim: shiftwidth=4
# vim: shiftwidth=4:
# vim: softtabstop=4:
