# Amplicon genotyping with AmpliSAS


AmpliSAT was run from a [DOCKER container]( https://hub.docker.com/repository/docker/sixthresearcher/amplisat).

Navigate to directory with F and R reads:

```
cd data/intermediate/amplisas/raw-barcoded
```

Merge F and R reads:

```
docker run -v $PWD:/workdir --rm sixthresearcher/amplisat ampliMERGE.pl \
    -i 1.fastq.gz 2.fastq.gz \
    -o merged_reads > amplisas.log
```

_ampliCLEAN.pl_ seems to collapse due to the large file sizes. For that reason I split the FASTQ files into 10 parts:

```
seqkit split -p 10 merged_reads.fq >> amplisas.log
rm merged_reads.fq
rm 1.fastq.gz
rm 2.fastq.gz
```

Clean merged reads:
```
cp ../amplicon-data.csv .
for partx in merged_reads.fq.split/*fq
do
  outname=$(echo $partx | sed 's|^.*\(part.*\).fq|\1|')
  docker run -v $PWD:/workdir --rm sixthresearcher/amplisat ampliCLEAN.pl \
      -i $partx \
      -mqual 17 \
      -min 200 \
      -d amplicon-data.csv \
      -o filtered_reads_$outname >> amplisas.log
done

rm -rf merged_reads.fq.split
```

Concatenate split sequences:

```
cat filtered_reads_part*fq > filtered_reads.fq
rm *part_0*fq
```

Edit parameters to mimic _tidyGenR_ parameters _maf_ = 0.1 and _ad_ = 10:

```
cp amplicon-data.csv amplicon-data_ampliSAS.csv

echo ">param,amplicon,value" >> amplicon-data_ampliSAS.csv
echo "min_amplicon_seq_depth,all,10" >> amplicon-data_ampliSAS.csv
echo "min_amplicon_seq_frequency,all,10" >> amplicon-data_ampliSAS.csv
```

Run amplisSAS:
```

docker run -v $PWD:/workdir --rm sixthresearcher/amplisat ampliSAS.pl \
-i filtered_reads.fq \
-min 10 \
-t Illumina \
-d amplicon-data_ampliSAS.csv \
-thr 5 \
-o results_amplisas > amplisas.log
```

Remove intermediate files:
```
rm filtered_reads.fq
```
