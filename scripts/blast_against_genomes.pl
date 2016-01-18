use Bio::KBase::HomologyService::Client;
use Data::Dumper;
use strict;
use File::Slurp;
use Getopt::Long::Descriptive;

my($opt, $usage) = describe_options("%c %o genome-id [genome-id...] [< input]",
				    ["program|p=s", "blast program (blastp / blastn / blastx / tblastx / tblastn)", { default => 'blastp' }],
				    ["contigs", "blast against contigs, not features"],
				    ["evalue|e=s", "evalue cutoff"],
				    ["max-hits|n=s", "max hits"],
				    ["coverage=s", "coverage"],
				    ["url|u=s", "URL to homology service"],
				    ["input|i=s", "Input file (if not specified, use stdin)"],
				    ["help|h", "Show this help message"]);
print($usage->text), exit 0 if $opt->help;
die($usage->text) if @ARGV == 0;

my @genomes = @ARGV;

my $cli = Bio::KBase::HomologyService::Client->new($opt->url);

my $data;
if ($opt->input)
{
    $data = read_file($opt->input);
}
else
{
    $data = read_file(\*STDIN);
}

my @res = $cli->blast_fasta_to_genomes($data, $opt->program, \@genomes,  ($opt->contigs ? 'contigs' : 'features'), $opt->evalue, $opt->max_hits, $opt->coverage);

print Dumper(\@res);
