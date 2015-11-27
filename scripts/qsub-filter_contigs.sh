#!/bin/bash

#PBS -N homology 
#PBS -r n
#PBS -l mppwidth=32
#PBS -l walltime=24:00:00
#PBS -q batch

module swap PrgEnv-cray PrgEnv-gnu

export HOME=/lustre/beagle/$(whoami)
cd $PBS_O_WORKDIR

echo "arg1 = $arg1"
# /opt/cray/alps/5.2.1-2.0502.9072.13.1.gem/bin/aprun perl -I/lustre/beagle2/brettin/HOMOLOGY_SERVICE/homology_service/lib -I/lustre/beagle2/brettin/lib/perl5 -I/lustre/beagle2/brettin/lib/perl5/site_perl/5.10.0 /lustre/beagle2/brettin/HOMOLOGY_SERVICE/homology_service/scripts/assemble_metagenomes.pl -i $arg1 -o $arg1.am.out

/opt/cray/alps/5.2.1-2.0502.9072.13.1.gem/bin/aprun perl -I/lustre/beagle2/brettin/HOMOLOGY_SERVICE/homology_service/lib -I/lustre/beagle2/brettin/lib/perl5 -I/lustre/beagle2/brettin/lib/perl5/site_perl/5.10.0 /lustre/beagle2/brettin/HOMOLOGY_SERVICE/homology_service/scripts/filter_megahit_contigs.pl -i $1.am.out -o $1.fc.out

/opt/cray/alps/5.2.1-2.0502.9072.13.1.gem/bin/aprun perl -I/lustre/beagle2/brettin/HOMOLOGY_SERVICE/homology_service/lib -I/lustre/beagle2/brettin/lib/perl5 -I/lustre/beagle2/brettin/lib/perl5/site_perl/5.10.0 /lustre/beagle2/brettin/HOMOLOGY_SERVICE/homology_service/scripts/call_genes.pl -i $1.fc.out -o $1.cg.out

/opt/cray/alps/5.2.1-2.0502.9072.13.1.gem/bin/aprun perl -I/lustre/beagle2/brettin/HOMOLOGY_SERVICE/homology_service/lib -I/lustre/beagle2/brettin/lib/perl5 -I/lustre/beagle2/brettin/lib/perl5/site_perl/5.10.0 /lustre/beagle2/brettin/HOMOLOGY_SERVICE/homology_service/scripts/use_flexmd5.pl -i $1.cg.out -o $1.uf.out

/opt/cray/alps/5.2.1-2.0502.9072.13.1.gem/bin/aprun perl -I/lustre/beagle2/brettin/HOMOLOGY_SERVICE/homology_service/lib -I/lustre/beagle2/brettin/lib/perl5 -I/lustre/beagle2/brettin/lib/perl5/site_perl/5.10.0 /lustre/beagle2/brettin/HOMOLOGY_SERVICE/homology_service/scripts/find_location.pl -i $1.uf.out -o $1.fl.out
