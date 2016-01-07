Homology Search Service Architecture Notes
==========================================

This document defines the requirements and architecture for the homology
search service.

The clients of this service include both end users via the Narrative and
other computational services (e.g. the use by model development services
to improve gapfilling) via the homology service network API.

Definitions
-----------

We define the following terms for the purpose of this document:

-   A **reference genome** is a genome residing in the KBase Central
    Store. Reference genomes are identified with KBase genome
    identifiers. Reference genomes may also be available in a well-known
    public workspace in which case they may be identified using a KBase
    workspace path.

-   A **user genome** is a genome annotated by a KBase end user. User
    genomes reside in the workspace and are identified with KBase
    workspace paths.

-   A **protein sequence** is a sequence of amino acid characters. It
    does not necessarily include an identifier.

-   A **DNA sequence** is a sequence of DNA characters. It does not
    necessarily include an identifier.

-   A **subject sequence** is a sequence in one of the references being
    searched (typically a reference genome or a user genome). A subject
    sequence may be either an amino acid sequence (in the case of a
    genome, this refers to a protein encoding gene that is called in the
    genome) or a DNA sequence. In a genome a DNA sequence may refer to
    either the DNA of a feature on the genome (e.g. a protein encoding
    gene, RNA feature, etc) or the contigs of the genome. The desired
    sequence (feature vs. contig) must be specified explicitly.

-   A **query sequence** is a protein or DNA sequence or set of
    sequences provided by the end user as the data for which the service
    is to search.

-   A **query** is a set of one or more query sequences; if multiple
    sequences are to be searched each must be associated with an
    identifier in order to disambiguate output.

-   A **match** is an instance of a homologous match between a query and
    subject sequence. A match associates a query sequence with the
    corresponding region in a subject sequence. The details of the
    association vary based on the particular algorithm used to determine
    the match, but may include

    -   Corresponding regions on the subject and query sequence

    -   A homology score (value ranges which depend on the particular
        algorithm and the size of the subject database)

    -   Query and subject coverage

    -   Identity or matching character score

User Operations
---------------

From a user’s high level point of view, the inputs to the homology
search may be

-   Amino acid or DNA characters pasted into an input widget in the
    Narrative

-   A sequence identifier (KBase identifier or other well-known
    identifier e.g. RefSeq protein identifier)

-   A set of either of the above

-   A batch search against an uploaded file of sequence data

-   A search using one of the KBase data types that represent sets of
    sequence data (e.g. FeatureSet)

The user must also specify the scope of the databases searched:

-   “All genomes”

-   A given genome or set of genomes chosen by a Narrative widget

-   A set of genomes stored in a GenomeSet

-   One of the precomputed reference sets

    -   =\> This implies an interface to enumerate available reference
        sets

The user must specify the desired output format. The output at the
highest level is one of the following:

-   A list of identifiers with optional scoring information from the
    underlying search algorithm

-   A set of matching sequences, again with optional scoring
    information.

-   A set of alignments, when appropriate from the underlying search
    algorithm.

-   The KBase object corresponding to one of these (FeatureSet for
    features meeting the cutoffs; GenomeSet for genomes that have
    matching sequences, etc.)

Finally the user must specify the details of the search:

-   Choice of algorithm (identical match; similarity; fast kmer-based
    search)

-   Is the target to be amino acid or DNA sequences? If DNA sequences,
    feature sequences or genomic sequences?

-   Cutoffs for search (per-algorithm limits on number of hits, required
    identity or similarity score, etc.)

Architectural Notes
-------------------

The homology service may be thought of as providing two different levels
of abstraction:

-   The **user operation** level of abstraction corresponds to the
    operations described in the User Operations section above.

-   The **core computation** level of abstraction corresponds to the
    underlying algorithms that the service provides to implement the
    user operations.

Core Computation Services
-------------------------

The core computation service layer exposes access to the homology search
algorithms supported by the service. We discuss each of these services.

### BLAST

BLAST searches require the existence of pre-indexed databases. We will
initially create these databases for the following data sets:

-   Each genome in the KBase central store (amino acid and DNA sequences
    of features, plus genomic DNA).

-   A nonredundant database of protein sequences for a representative
    set of genomes from the KBase Central Store

-   A nonredundant database of protein sequences for all genomes in the
    KBase Central Store.

Searches for more than one genome may be performed using the BLAST
facility for the creation of alias databases.

### Kmer-based Similarity Search

We also support the in-house developed fast kmer-based similarity
search technology. The kmer-based search returns matches of protein
query sequences to a database of preloaded reference proteins.

Implementation Plan
-------------------

We plan implementation of the Homology Service in the following stages:

1.  Definition of an API specification file for the initial set of core
    and user services. Jan 4-8 (Bob).

2.  Collection and creation of representative BLAST database from KBase
    Central Store. Jan 4-8 (Maulik)

3.  Creation of pre-computed Diamond databases. Jan 4-8 (Fangfang) 

4.  Implementation of BLAST-based core computation service. Jan 18-22
    (Bob)

5.  Implementation of kmer-based core computation service. Jan 11-15
    (Bob)

6.  Implementation of user-level operations. Jan 18-29 (Bob, Maulik,
    Harry etc). This overlaps \#4 so that the user-level operations can
    help influence BLAST-based compute service as it is being built.


