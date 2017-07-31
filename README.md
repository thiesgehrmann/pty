# pty
An ongoing re-implementation of proteny, because the old one sucks!

## Installation


## Example usage

Provided is a small example using the genomes of
 * [Candida Glabrata CBS138](http://www.candidagenome.org/download/sequence/C_glabrata_CBS138/current/)
 * [Zygosaccharomyces rouxii CBS732](http://genome.jgi.doe.gov/Zygro1/Zygro1.download.html)

To download and run the example dataset, run the following on your command line:

```bash
  git clone https://github.com/thiesgehrmann/pty.git
  cd pty
  snakemake --use-conda --cores 10 --configfile example_config.json hitScoreK
```
