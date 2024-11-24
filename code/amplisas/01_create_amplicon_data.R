###.............................................................................
# (c) Miguel Camacho Sánchez
# miguelcamachosanchez@gmail.com
# May 2024
###.............................................................................
#GOAL: create input amplicon data for AmpliSAS
#PROJECT: tidyGenR_benchmarking
###.............................................................................
library(dplyr)
#input for amplisas
primers <-
  read.csv("data/raw/primers.csv", sep = ";") %>%
  dplyr::rename(primer_f = 1,
                primer_r = 2,
                marker = 3)

#length of alleles
# read reference alleles from Rattus and set lengths
ref_alleles <-
  bioseq::read_fasta("data/raw/reference-alleles.fasta") %>%
  {setNames(., tolower(names(.)) %>%
              {sapply(strsplit(., "_"), `[`, 1, simplify=FALSE)})} %>%
  bioseq::seq_nchar() %>%
  {data.frame(marker = names(.), "length" = .)}
# all loci have a reference?
assertthat::assert_that(all(primers$marker %in% ref_alleles$marker))
# read locus data and write locus info
# create directory
fp <- "data/intermediate/amplisas"
dir.create(fp)
primers %>%
  dplyr::left_join(ref_alleles, by = "marker") %>%
  dplyr::mutate(length = paste(length - 20, length + 20, sep = "-"),
                species = "Rbaluensis",
                gene = paste0(marker, "_gene"),
                feature = paste0(marker, "_feature")) %>%
  dplyr::select(marker, length, primer_f, primer_r, gene, feature, species) %>%
  dplyr::rename(">marker" = marker) %>%
  write.csv(file = file.path(fp, "amplicon-data.csv"), quote = F, row.names = F)
