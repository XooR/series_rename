#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  rename_series.pl
#
#        USAGE:  rename_series.pl (<-n name_of_series><-i id_of_series>)\
#        (--se-regex "(season)(episode)"|-r) [--dummy|-d] file_to_rename...
#
#  DESCRIPTION:
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Stanislav Antic (), stanislav.antic@gmail.com
#      COMPANY:  ETF
#      VERSION:  1.0
#      CREATED:  08/22/2009 08:35:54 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

die "No arguments!"
  unless $ARGV[0];

use Getopt::Long;
use File::Copy;
use File::Basename;

my $series_name = undef;
my $series_id   = undef;

my $se_regex    = undef;
my $dont_write  = 0;

GetOptions(
    "series_name|n=s" => \$series_name,
    "series_id|i=i"   => \$series_id,
    "se-regex|r=s"   => \$se_regex,
    "dont-write|d"   => \$dont_write,
);

die "You didn't gave series name!"
  unless $series_name || $series_id;

use TVDB::API;

my $tvdb = TVDB::API->new()
  or die "Error in initializing TVDB API!";

unless (defined $series_id) {
    my $series_record_for_ref = $tvdb->getPossibleSeriesId($series_name);

# if there is more than one possible match
    if ( ( scalar keys %$series_record_for_ref ) > 1 ) {
        print "Possible series ID are:";
# Print choices of possible series IDs to a user
        for my $series_id ( keys %{$series_record_for_ref} ) {
            print "$series_id\n";
            print "Name: ",
                  $series_record_for_ref->{$series_id}{SeriesName},
                  "\n"
            ;
            print " " x 4 . "Overview:\n";
            print $series_record_for_ref->{$series_id}->{Overview} . "\n";
        }

        print "Use -i option to specify ID of a series directly\n";
        exit(-1);
    }
}
# When you don't give a name
$series_name = $tvdb->getSeriesName($series_id)
  if $series_id;

FILE:
for my $file (@ARGV) {
# Not really safe
    my ($season, $episode) = ($file =~ m/$se_regex/);

# Check if you got season and episode numbers...
    unless ($season && $episode) {
        warn "Error in parsing name of file: $file";

        next FILE;
    }

    my $name_of_episode = $tvdb->getEpisodeName( $series_name, $season, $episode );

    my $new_file_name
        = $series_name
        ."-"
        ."S"
        .$season
        ."xE"
        .$episode
        ."-$name_of_episode"
# Gets suffix from old name
        .($file =~ m/(\.[^.]*)$/)[0]
        ;

    print $file."->".$new_file_name."\n";
    move($file, $new_file_name)
        unless $dont_write;

}
