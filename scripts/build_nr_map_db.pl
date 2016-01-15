use strict;
use DB_File;
use Getopt::Long::Descriptive;

=head1 NAME

build_nr_map_db

=head1 SYNOPSIS

build_nr_map_db map-file.tab map-file.btree

=head1 DESCRIPTION

Given a NR mapping file build a btree database for optimized lookups.

=cut

my($opt, $usage) = describe_options("%c %o map-file.tab map-file.btree",
				    ["help|h", "Show this help message."],
				    );
print($usage->text), exit 0 if $opt->help;
die($usage->text) unless @ARGV == 2;

my $tab_file = shift;
my $btree_file = shift;

my %idx;
my $btree = tie %idx, 'DB_File', $btree_file, O_RDWR | O_CREAT, 0644, $DB_BTREE;
$btree or die "Cannot create btree $btree: $!";

-f $tab_file or die "$tab_file does not exist\n";
open(S, "-|", "sort", "-S", "20G", "-k1,1", $tab_file) or die "Cannot open sort: $!";
while (<S>)
{
    if (my($md5, $fid, $func, $genome) = /^([0-9a-f]{32})\tkb\|(\S+)\s{3}(.*)\s{3}\[([^]+)\]/)
    {
	print Dumper($md5, $fid, $func, $genome);
    }
}
    
