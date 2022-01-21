# Human genome profiling

```bash
# Download a fraction of the human genome
wget http://hgdownload.cse.ucsc.edu/goldenpath/hg19/chromosomes/chr{18,21,X,Y,M}.fa.gz
```

```bash
REF=hg.fa
mkdir -p aln/
for i in reads/*_1.fq.gz;
do 
 j=${i/_1.fq.gz/_2.fq.gz}
 b=$(basename $i | cut -f 1 -d _)
 if [[ ! -e aln/$b.bam ]]; then
   minimap2 -ax sr $REF $i $j | samtools view -bS | samtools sort -o aln/$b.bam -
 fi
done
```

Tool     | Memory Peak | Time 
---------|------------:|------:
Bwa      |   813,016   | 31.0
Minimap2 | 2.597 GB   | 15.9 