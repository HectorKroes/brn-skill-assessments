library(ChIPseeker)
library(ChIPpeakAnno)
library(TxDb.Hsapiens.UCSC.hg38.knownGene)

txdb <- TxDb.Hsapiens.UCSC.hg38.knownGene

sbj43 <- readPeakFile("ENCFF994CJC.bed")
sbj69 <- readPeakFile("ENCFF040RST.bed")

overlaps <- findOverlapsOfPeaks(sbj43, sbj69)

makeVennDiagram(overlaps, fill=c("#acdd9d", "#e28989"))

promoters <- getPromoters(TxDb=txdb, upstream=10000, downstream=10000)

tm_sbj43 <- getTagMatrix(sbj43, windows=promoters)
tm_sbj69 <- getTagMatrix(sbj69, windows=promoters)
tm_overlap <- getTagMatrix(overlaps$peaklist[["sbj43///sbj69"]], windows=promoters)

plotAvgProf(list(sbj43=tm_sbj43, sbj69=tm_sbj69, "sbj43///sbj69"=tm_overlap), xlim=c(-10000, 10000),
            xlab="Genomic Region (5'-> 3')", ylab = "Read Count Frequency")