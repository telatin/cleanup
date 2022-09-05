# Generate a Kraken2 database

1. Place the contaminant sequences in a directory (e. g. `cont/*.fasta`)
2. Generate a new Kraken2 database: `kraken2-build --db kraken2-contaminants --download-taxonomy`
3. Flag the sequences with `|kraken:taxid|{ID}`
  * For example: 694448 for Coronavirus, 374840 for PhiX.
4. Concatenate the genomes, for example as `contaminants.fasta`
5. Add the sequences: `kraken2-build --add-to-library contaminants.fasta --db kraken2-contaminants`
6. Finally: `kraken2-build --build --db kraken2-contaminants --threads $THREADS`

