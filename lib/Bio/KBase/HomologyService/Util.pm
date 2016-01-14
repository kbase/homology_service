package Bio::KBase::HomologyService::Util;

use strict;
use File::Temp;
use Data::Dumper;
use base 'Class::Accessor';
use IPC::Run 'run';
use JSON::XS;

__PACKAGE__->mk_accessors(qw(blast_db_genomes impl json));

my %blast_command_subject_type = (blastp => 'a',
				  blastn => 'd',
				  blastx => 'a',
				  tblastn => 'd',
				  tblastx => 'd');
my %blast_command_exe_name = (blastp => 'blastp',
			      blastn => 'blastn',
			      blastx => 'blastx',
			      tblastn => 'tblastn',
			      tblastx => 'tblastx');

sub new
{
    my($class, $impl) = @_;

    my $self = {
	impl => $impl,
	blast_db_genomes => $impl->{_blast_db_genomes},
	json => JSON::XS->new->pretty(1),
    };
    return bless $self, $class;
}

sub find_genome_db
{
    my($self, $genome, $db_type, $type) = @_;

    my $base = $self->blast_db_genomes . "/$genome";
    my $file;
    my $check;
    if ($db_type =~ /^a/i)
    {
	$file = "$base.faa";
	$check = "$file.pin";
    }
    elsif ($db_type =~ /^d/i && $type =~ /^c/i)
    {
	$file = "$base.fna";
	$check = "$file.nin";
    }
    elsif ($db_type =~ /^d/i && $type =~ /^f/i)
    {
	$file = "$base.ffn";
	$check = "$file.nin";
    }
    else
    {
	die "find_genome_db: Invalid combination of db_type=$db_type and type=$type";
    }


    if (! -f $check)
    {
	die "find_genome_db: Could not find index file $check";
    }

    return $file;
}

#
# Build a blast alias database and return a File::Temp referring to it.
# If we just have a single genome we'll return the right db file. Don't
# delete the output from here (File::Temp will handle the deletion).
# 
sub build_alias_database
{
    my($self, $subj_genomes, $subj_db_type, $subj_type) = @_;

    if (@$subj_genomes == 0)
    {
	return;
    }
    elsif (@$subj_genomes == 1)
    {
	return $self->find_genome_db($subj_genomes->[0], $subj_db_type, $subj_type);
    }

    my @db_files;
    for my $g (@$subj_genomes)
    {
	my $f = $self->find_genome_db($g, $subj_db_type, $subj_type);
	push(@db_files, $f);
    }
    my $build_db;
    print STDERR Dumper(\@db_files);
    my $db_file = File::Temp->new(UNLINK => 1);
    close($db_file);
    $build_db = ["blastdb_aliastool",
		 "-dblist", join(" ", @db_files),
		 "-title", join(" ", @$subj_genomes),
		 "-dbtype", (($subj_db_type =~ /^a/i) ? 'prot' : 'nucl'),
			 "-out", $db_file];
    my $ok = run($build_db);
    $ok or die "Error running database build @$build_db\n";
    print STDERR "Built db $db_file\n";
    return $db_file;
}

sub blast_fasta_to_genomes
{
    my ($self, $fasta_data, $program, $genomes, $subj_type, $evalue_cutoff, $max_hits, $min_coverage) = @_;

    my $subj_db_type = $blast_command_subject_type{$program};
    my $exe = $blast_command_exe_name{$program};

    my $suffix = $self->impl->{_blast_program_suffix};
    $exe .= $suffix if $suffix;
    my $prefix = $self->impl->{_blast_program_prefix};
    $exe = $prefix . $exe if $prefix;

    if (!$subj_db_type || !$exe)
    {
	die "blast_fasta_to_genomes: Couldn't find blast program $program";
    }
    
    my $db_file = $self->build_alias_database($genomes, $subj_db_type, $subj_type);
    $db_file or die "Couldn't find db file for @$genomes with subj_db_type=$subj_db_type and subj_type=$subj_type";
    my @cmd = ($exe);
    if ($evalue_cutoff)
    {
	push(@cmd, "-evalue", $evalue_cutoff);
    }
    if ($max_hits)
    {
	push(@cmd, "-max_target_seqs", $max_hits);
#	push(@cmd, "-max_hsps", $max_hits);
    }
    if ($min_coverage)
    {
	push(@cmd, "-qcov_hsp_perc", $min_coverage);
    }

    my $fmt = 15;		# JSON single file

    push(@cmd, "-db", "$db_file");
    push(@cmd, "-outfmt", $fmt);
    
    my $json;
    my $err;
    my $ok = run(\@cmd, "<", \$fasta_data, ">", \$json, "2>", \$err);

    if (!$ok)
    {
	die "Blast failed @cmd: $err";
    }

    my $doc = eval { $self->json->decode($json) };
    if ($@)
    {
	die "json parse failed: $@\nfor cmd @cmd\n$json\n";
    }
    $doc = $doc->{BlastOutput2};
    $doc or die "JSON output didn't have expected key BlastOutput2";

    my $metadata = {};
    for my $report (@$doc)
    {
	my $search = $report->{report}->{results}->{search};
	$search->{query_id} =~ s/^gnl\|//;
	if ($search->{query_id} =~ /^Query_\d+/)
	{
	    my($xid) = $search->{query_title} =~ /^(\S+)/;
	    $search->{query_id} = $xid if $xid;
	}
	for my $res (@{$search->{hits}})
	{
	    for my $desc (@{$res->{description}})
	    {
		my $md;
		if ($desc->{id} =~ /^gnl\|BL_ORD/)
		{
		    if ($desc->{title} =~ /^(\S+)\s+(.*)\s{3}\[(.*?)(\s*\|\s*(\S+))?\]\s*$/)
		    {
			$desc->{id} = $1;
			$md->{function} = $2;
			$md->{genome_name} = $3;
			$md->{genome_id} = $5 if $5;
		    }
		    elsif ($desc->{title} =~ /^(\S+)\s+\[(.*?)(\s*\|\s*(\S+))?\]\s*$/)
		    {
			$desc->{id} = $1;
			$md->{genome_name} = $2;
			$md->{genome_id} = $4 if $4;
		    }
		}
		else
		{
		    $desc->{id} =~ s/^gnl\|//;
		    if ($desc->{title} =~ /^\s*(.*)\s{3}\[(.*?)(\s*\|\s*(\S+))?\]\s*$/)
		    {
			$md->{function} = $1;
			$md->{genome_name} = $2;
			$md->{genome_id} = $4 if $4;
		    }
		    elsif ($desc->{title} =~ /^\s*\[(.*?)(\s*\|\s*(\S+))?\]\s*$/)
		    {
			$md->{genome_name} = $1;
			$md->{genome_id} = $3 if $3;
		    }
		}
		if ($desc->{id} =~ /^(kb\|g\.\d+)/)
		{
		    $md->{genome_id} = $1;
		}
		$metadata->{$desc->{id}} = $md if $md;
	    }
	}
    }
    return($doc, $metadata);
}

