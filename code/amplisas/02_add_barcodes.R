###.............................................................................
# (c) Miguel Camacho Sánchez
# miguelcamachosanchez@gmail.com
# May 2024
###.............................................................................
#GOAL: add barcodes to raw sequences and write them to data/intermediate
#PROJECT: tidyGenR_benchmarking
###.............................................................................
# add barcodes to raw sequences
library(dplyr)
library(ShortRead)
library(Biostrings)
library(DNABarcodes)

# read samples
samples <-
  tidyGenR::check_raw_reads(freads = list.files("data/raw", "1.fastq",
                                                full.names = TRUE),
                            low_readcount = 0)$samples
#generate barcodes
nnucl <- 6
barcod <- DNABarcodes::create.dnabarcodes(nnucl)
assertthat::assert_that(length(barcod) > length(samples),
                        msg = "The number of barcodes is less ",
                        "than the number of samples. Increase the n paramter")
# dataframe with barcodes
barcodes <-
  barcod[seq_along(samples)] %>%
  {data.frame(sample = samples, barcode = .)}
# quality associated to barcode
highestqual <-
  rep("I", nnucl) %>% paste0(collapse = "")

# create directory for writing fastq files with barcodes
fp <- "data/intermediate/amplisas/raw-barcoded"
dir.create(fp)
# read fastq demultiplexed by individual
c("1.fastq", "2.fastq") %>%
  lapply(function(fr) {
    samples %>%
      lapply(function(sample) {
        path2reads <- list.files("data/raw",
                                 pattern = paste0(sample, ".", fr),
                                 full.names = TRUE)
        # read fastq file
        h <- ShortRead::readFastq(path2reads)
        barcode1 <- barcodes$barcode[barcodes$sample == sample]
        # create new reads with barcodes
        #add vector with highest quality to 5' end.
        ShortReadQ(
          quality = Biostrings::quality(h)@quality %>%
            as.character() %>%
            {paste0(highestqual, .)} %>%
            BStringSet(),
          sread = ShortRead::sread(h) %>% #add barcode to 5' end
            as.character() %>%
            {paste0(barcode1, .)} %>%
            Biostrings::DNAStringSet(),
          id = h@id #same fastq headers
        ) %>%
          ShortRead::writeFastq(file = file.path(fp, fr),
                                mode = "a") #append to existing file
      })
    })

# append barcode data to ampliSAS input
barcodes %>%
  dplyr::mutate(barcode_r = barcode) %>%
  dplyr::rename(">sample" = sample,
                barcode_f = barcode) %>%
write.table(file = "data/intermediate/amplisas/amplicon-data.csv",
          quote = FALSE,
          row.names = FALSE,
          sep = ",",
          append = TRUE)
