import inspect, os
__INSTALL_DIR__ = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
__PC_DIR__ = "%s/pipeline_components" % __INSTALL_DIR__

###############################################################################

import json
dconfig = json.load(open("%s/defaults.json"% __PC_DIR__, "r"))
dconfig.update(config)

###############################################################################

__RUN_DIR__ = os.path.abspath(dconfig["outdir"]) + "/run"
__PROTS_OUTDIR__ = "%s/prots" % __RUN_DIR__
__EXONS_OUTDIR__ = "%s/exons" % __RUN_DIR__
__BLAST_OUTDIR__ = "%s/blast" % __RUN_DIR__

###############################################################################

rule genProteins:
  input:
    genome = lambda wildcards: dconfig["genomes"][wildcards.genome]["genome"],
    gff    = lambda wildcards: dconfig["genomes"][wildcards.genome]["gff"]
  output:
    fa = "%s/prots.{genome}.fasta"% _PROTS_OUTDIR__
  conda: "%s/conda.yaml"% __PC_DIR__
  shell: """
    gffread -y "{output.fa}.orig" -g "{input.genome}" "{input.gff}"
    sed -e 's/^>\([^ ]\+\).*/>\\1/' {output.fa}.orig \
     | tr '\n>' '\t\n' \
     | sed -e 's/^\([^\t]\+\)\t/>\\1\\n/' \
     | sed -e 's/[.]\([\t]\?\)$/\\1/' \
     | grep -B1 --no-group-separator '^[^>.][^.-]\+$' \
     | tr '\t' '\n' \
     | sed -e '/^$/d' \
     > {output.fa}
  """

rule codingExonSequences:
  input:
    prots = lambda wildcards: "%s/prots.%s.fasta" % (__PROTS_OUTDIR__, wildcards.genome)
    gff   = lambda wildcards: dconfig["genomes"][wildcards.genome]["gff"]
  output:
    exonFasta = "%s/exons.{genome}.fasta" % __EXONS_OUTDIR__,
    exonInfo  = "%s/exons.{genome}.info" % __EXONS_OUTDIR__
  run:
    import pipeline_components.utils as utils

    G = utils.readGFF3File(input.gff)
    F = utils.loadFasta(input.fasta)

    
   
###############################################################################
 # BLAST

rule blastDB:
  input:
    exonFasta = lambda wildcards: "%s/exons.%s.fasta"% (__EXONS_OUTDIR__, wildcards.genome)
  output:
    blastdb = "%s/blastdb.{genome}.db" % __BLAST_OUTDIR__
  conda: "%s/conda.yaml"% __PC_DIR__
  shell: """
    makeblastdb -dbtype prot -in {input.exonFasta} -out {output.db}
    touch {output.db}
  """

rule runBlast:
  input:
    query = lambda wildcards: "%s/blastdb.%s.db" % (__BLAST_OUTDIR__, wildcards.genomeA),
    db    = lambda wildcards: "%s/exons.%s.fasta" % (__BLAST_OUTDIR__, wildcards.genomeB)
  output:
    hits = "%s/hits.{genomeA},{genomeB}.tsv" % __BLAST_OUTDIR__
  conda: "%s/conda.yaml" % __PC_DIR__
  threads: 4
  params:
    blastfields = dconfig["blastfields"]
  shell: """
    blastp -query {input.query} -db {input.db} -outfmt "6 {params.blastfields}" -out {output.hits} -num_threads {threads}
  """

###############################################################################
 # Recalculating the hit score

rule hitScoreK:
  input:
    hits = lambda wildcards: "%s/hits.%s,%s.tsv" % (__BLAST_OUTDIR__, wildcards.genomeA, wildcards.genomeB)
  output:
    hits = "%s/hitscores.{genomeA},{genomeB}.tsv" % __HITSCORE_OUTDIR__
  run:
   import pipeline_components.utils as utils
    H = utils.readBlastFile(input.hits, dconfig["blastfields"])
    augmentedBlastType = utils.BlastHitType()
    augmentedBlastType.setFields(dconfig["blastfields"] + ",K")

    
