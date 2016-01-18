use strict;
use DB_File;
use Getopt::Long::Descriptive;
use Data::Dumper;

=head1 NAME

build_nr_map_db

=head1 SYNOPSIS

build_nr_map_db map-file.tab map-file.btree

=head1 DESCRIPTION

Given a NR mapping file build a btree database for optimized lookups.

=cut

my($opt, $usage) = describe_options("%c %o map-file.tab map-file.btree",
				    ["sort-program=s", "Use this sort program"],
				    ["parallel=s", "Use this parallelism in the sort"],
				    ["memory=s", "Use this much memory for the sort", { default => '10G' } ],
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
#open(S, "(head -n 100 $tab_file; head -n 100 $tab_file) | sort -k1,1|") or die "Cannot open sort: $!";

my $sort = $opt->sort_program || "sort";
my @par;
@par = ("--parallel", $opt->parallel) if $opt->parallel;

open(S, "-|", $sort, @par, "-S", $opt->memory, "-k1,1", $tab_file) or die "Cannot open sort: $!";
my $last;
my @data;
while (<S>)
{
    if (my($md5, $fid, $func, $genome) = /^([0-9a-f]{32})\t(kb\|\S+)\s{3}(.*)\s{3}\[([^]]+)\]/)
    {
	if ($md5 ne $last)
	{
	    if ($last)
	    {
		$idx{$last} = join($;, @data);
		@data = ();
	    }
	    $last = $md5;
	}

	push(@data, join("\t", $fid, $func, $genome));
    }
}
    
$idx{$last} = join($;, @data);

untie %idx;
