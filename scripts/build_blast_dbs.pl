#!/usr/bin/env perl

#`source /vol/kbase/deployment/user-env.sh`;

use strict;
use warnings;
use Getopt::Long;

$0 =~ m/([^\/]+)$/;
my $self = $1;
my $usage = $self. qq( --db fna|ffn|fna --db_type blast|diamond  --help); 

my $help;
my @db = ();
my @db_type = ();


my $opts = GetOptions(
    "help" => \$help,
    "db=s" => \@db,
    "db_type=s" => \@db_type
);

if (!$opts || $help){
  warn qq(\n   usage: $usage\n\n);
  exit(0);
}

@db = split(/,/, join(',', @db));
@db_type = split(/,/, join(',', @db_type));

my @genomes = getGenomes();

foreach my $genome (@genomes){

	my ($genome_id, $genome_name) = $genome=~/^(.*)\t(.*)\n/;	

	print "Processing genome: $genome_id\t$genome_name\n";

	prepareFNADB($genome_id, $genome_name) if grep {$_ eq "fna"} @db;
	prepareFFNDB($genome_id, $genome_name) if grep {$_ eq "ffn"} @db;
	prepareFAADB($genome_id, $genome_name) if grep {$_ eq "faa"} @db;

}

sub getGenomes {

	print "Getting genomes...\n";

	my ($self) = @_;
	
	my @genomes = `all_entities_Genome | tail -n 3375 | genomes_to_genome_data | cut -f 1,6`;

	return @genomes;
		
}

sub prepareFNADB {

	my ($genome_id, $genome_name) = @_;

	my $fna_file = "$genome_id.fna";

	open FNA, ">$fna_file"; 

	print "Preparing FNA database for $genome_id..\n";

	my @contigs = `echo \"$genome_id\" | genomes_to_contigs | contigs_to_sequences --fasta 0`;

	foreach my $contig (@contigs){

		my ($gid, $contig_id, $contig_seq) = $contig =~/(.*)\t(.*)\t(.*)\n/;

		my $sequence = join("\n", $contig_seq=~ /(.{1,60})/g);

		print FNA ">$contig_id   [$genome_name]\n$sequence\n";

	} 

	close FNA;

	makeBlastDB($fna_file, "nucl") if grep {$_ eq "blast"} @db_type;

}


sub prepareFFNDB {

	my ($genome_id, $genome_name) = @_;

	my $ffn_file = "$genome_id.ffn";

	open FFN, ">$ffn_file"; 

	print "Preparing FFN database for $genome_id..\n";

	my @genes = `echo \"$genome_id\" | genomes_to_fids | fids_to_dna_sequences --fasta 0`;

	foreach my $gene (@genes){

		my ($gid, $gene_id, $gene_seq) = $gene =~/(.*)\t(.*)\t(.*)\n/;

		my $sequence = join("\n", $gene_seq=~ /(.{1,60})/g);

		print FFN ">$gene_id   [$genome_name]\n$sequence\n";

	} 

	close FFN;

	makeBlastDB($ffn_file, "nucl") if grep {$_ eq "blast"} @db_type;

}

sub prepareFAADB {

	my ($genome_id, $genome_name) = @_;

	my $faa_file = "$genome_id.faa";

	open FAA, ">$faa_file"; 

	print "Preparing FAA database for $genome_id..\n";

	my @proteins = `echo \"$genome_id\" | genomes_to_fids | fids_to_protein_sequences --fasta 0`;

	foreach my $protein (@proteins){

		my ($gid, $protein_id, $protein_seq) = $protein =~/(.*)\t(.*)\t(.*)\n/;

		my $sequence = join("\n", $protein_seq=~ /(.{1,60})/g);

		print FAA ">$protein_id   [$genome_name]\n$sequence\n";

	}

	close FAA; 

	makeBlastDB($faa_file, "prot") if grep {$_ eq "blast"} @db_type;
	makeDiamondDB($faa_file) if grep {$_ eq "diamond"} @db_type;

}

sub makeBlastDB {

	my ($fasta_file, $db_type) = @_;

	`makeblastdb -in "$fasta_file" -dbtype $db_type`;

}


sub makeDiamondDB {

	my ($fasta_file) = @_;

	`diamond makedb --in "$fasta_file" --db "$fasta_file"`;

}
