#!/usr/bin/perl 
=pod

=head1 NAME

series_rename - Renames files of series with a given pattern.

=head1 SYNOPSIS

B<series_rename> [B<-d>] B<-n> name_of_series B<-r> capture_regex files...

B<series_rename> [B<-d>] B<-i> id_of_series B<-r> capture_regex files...

=head1 DESCRIPTION

series_rename fetches titles of episodes and use them to form a valid
file name. For now you cannot change the way how it is generating final name
except if you are editing code directly.

=head1 OPTIONS

=over

=item B<-d>, B<--dummy>

Don't move files. It just show result.

=item B<-r> B<--se-regex>

Regex that specifies how to fetch season and episode infos from file name.

Example:

C<-r "S(\d\d)E(\d\d)"> for files like "Jericho_S03E02" 

=item B<-i> B<--series_id>

Specifies series id of specific series. This could be necessary if name of
series isn't uniq.

=item B<-n> <--series_name>

Here you are giving name of series. If it isn't uniq it will give you list
of choices and IDs of series.

=back

=head1 EXAMPLES

$ series_rename -n "Everybody Loves Earl" -r "S(\d\d)E(\d\d)" -d *.avi

$ series_rename -i 79330 -r "S(\d\d)E(\d\d)" -d *.avi

=cut

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
    "se_regex|r=s"    => \$se_regex,
    "dummy|d"         => \$dont_write,
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

    if ($file =~ m{\Q*.\E # *. part of globing operator
            [[:alpha:]]+  # [a-zA-Z]+
            }xms
            ) {
# Push files that are given with onto @ARGV and continues
        push @ARGV, glob $file;
        next FILE;
    }
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
