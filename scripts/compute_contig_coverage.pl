use strict;
use Getopt::Long; 
use JSON;
use Pod::Usage;
use Log::Message::Simple qw[:STD :CARP];
use File::Basename;

my ($in, $out, %skip, $skip_file);

### set default values
my $help = 0;
my $verbose = 1;

GetOptions(
	'h'	=> \$help,
        'i=s'   => \$in,
        'o=s'   => \$out,
	'help'	=> \$help,
	'input=s'  => \$in,
	'output=s' => \$out,
	'v'        => \$verbose,
	'verbose'  => \$verbose,
	's=s'	=> \$skip_file,
	'skip=s'   => \$skip_file,

) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 2,
          -noperldoc => 1,
         ) if $help;


### redirect log output
my ($scriptname,$scriptpath,$scriptsuffix) = fileparse($0, ".pl");
open STDERR, ">>$scriptname.log" or die "cannot open log file";
local $Log::Message::Simple::MSG_FH     = \*STDERR;
local $Log::Message::Simple::ERROR_FH   = \*STDERR;
local $Log::Message::Simple::DEBUG_FH   = \*STDERR;

### set up i/o handles
my ($ih, $oh);

if ($in) {
    open $ih, "<", $in or die "Cannot open input file $in: $!";
}
elsif (! (-t STDIN))  {
    $ih = \*STDIN;
}
if ($out) {
    open $oh, ">", $out or die "Cannot open output file $out: $!";
}
else {
    $oh = \*STDOUT;
}

if ($skip_file) { 
  open SKIP, $skip_file or die "could not open skip file $skip_file.";
  while (<SKIP>) {
    my ($id) = split /\s+/;
    $skip{$id}++;
  }
  close SKIP;
}


### main logic
### load the requested assembler template
if (defined $ENV{KB_DEPLOYMENT_CONFIG} && -e $ENV{KB_DEPLOYMENT_CONFIG}) {
    $cfg = new Config::Simple($ENV{KB_DEPLOYMENT_CONFIG}) or
	die "can not create Config object";
    msg( "using $ENV{KB_DEPLOYMENT_CONFIG} for configs", $verbose);
}
else {
    $cfg = new Config::Simple(syntax=>'ini');
    $cfg->param('homology_service.assembly_tt','/homes/brettin/local/dev_container/modules/homology_service/templat
es/bwa-idx.tt');
    $cfg->param('homology_service.assembly_tt','/homes/brettin/local/dev_container/modules/homology_service/templat
es/bwa-mem.tt');
    msg("using hardcoded config values " . $cfg->param('homology_service.bwa-idx_tt'), $verbose);
    msg("using hardcoded config values " . $cfg->param('homology_service.bwa-mem_tt'), $verbose)
}

if ($ih) { 
  while(<$ih>) {
    my($metagenome_id, $contigs, $reads) = split /\s+/;
    if ( $skip{$metagenome_id} >= 1) { print "skipping $metagenome_id\n"; next; }
    die "$filename not readable" unless (-e $filename and -r $filename);

    # infile is the contigs file
    my $vars = { infile => $filename, idx => $infile, reads => $reads };
    my $tt = Template->new( {'ABSOLUTE' => 1} );

    $tt->process($cfg->param('homology_service.assembly_tt'), $vars, \$cmd)
      or die $tt->error(), "\n";

    msg( "cmd: $cmd", $verbose );

    # !system $cmd or die "could not execute $cmd\n$!";

    print $oh $metagenome_id, "\t", $vars->{out_dir} . "/final.contigs.fa\n";

    msg( "cmd: finished", $verbose );


    my $cmd1 = bwa index $contigs;
    my $cmd2 = bwa mem $contig

    msg ("done processing $filename");
  }
}
else {
  die "no input found, input is required";
}



 

=pod

=head1	NAME

compute_contig_coverage

=head1	SYNOPSIS

compute_contig_coverage <options>

=head1	DESCRIPTION

The compute_contig_coverage command ...

=head1	OPTIONS

=over

=item	-h, --help

Basic usage documentation

=item   -i, --input

The input file, default is STDIN

=item   -o, --output

The output file, default is STDOUT

=item	-v, --verbose

Sets logging to verbose. By default, logging goes to a file named compute_contig_coverage.log.

=item	-s, --skip

An optional file with a list of metagenome ids to skip if found in the input.

=back

=head1	AUTHORS

Thomas Brettin

=cut

1;

