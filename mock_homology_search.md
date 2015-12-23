
## Homology Search Workflow (Mock Narrative Method)

### Input 1: Select query sequences in a combination of the following ways:
* Text box for pasting a single amino acid or DNA sequence
* List of KBase sequence identifiers
* Uploaded sequence data
* Defined KBase feature set

### Input 2: Specify the scope of the databases searched:

* Precomputed genome sets: All Genomes; Representative Genomes
* Defined genome set
* Additional genomes specified by genome IDs

### Input 3: Specify the desired output format:

* A list of identifiers with scoring information
* A set of matching sequences and alignment information
* The KBase object corresponding to one of these
  * FeatureSet for features meeting the cutoffs
  * GenomeSet for genomes that have matching sequences

### Input 4: Specify the details of the search:

* Choice of algorithm (identical match; similarity; fast kmer-based search)
* Is the target to be amino acid or DNA sequences? If DNA sequences, feature sequences or genomic sequences?
* Cutoffs for search (per-algorithm limits on number of hits, required identity or similarity score, etc.)

### Computation

The homology search algorithms are invoked on the persistent homology
server which houses the precomputed and cached indices of the sequence
database.

### Output:

In addition to generating the specified output objects in the
workspace, the service will present visual alignment info in the
output widget leveraging the work Ranjan's team has done on the BLAST
methods.








