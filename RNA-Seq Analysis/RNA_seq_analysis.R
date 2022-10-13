library(recount)
library(DESeq2)
library(ggplot2)
library(gplots)
library(tidyverse)
library(ggrepel)
library(org.Hs.eg.db)
library(clusterProfiler)
library(DOSE)
library(DT)
require(biomaRt)
library(pheatmap)

study_acession <- "SRP041538"

if (!file.exists(file.path(study_acession, "rse_gene.Rdata"))) {
  download_study(study_acession)
}

load(file.path(study_acession, "rse_gene.Rdata"))

rse <- scale_counts(rse_gene)

rse$condition <- sapply(strsplit(as.character(rse$title), "-"), `[`, 2)

dds <- DESeqDataSet(rse, ~condition)

dds$treatment <- relevel(dds$condition, ref = "NOR")
dds <- DESeq(dds)

res <- as_tibble(results(dds, alpha = 0.05), rownames = "gene") %>%
  rename(logFC=log2FoldChange) %>% rename(FDR=padj)

ensembl <- useMart("ENSEMBL_MART_ENSEMBL", dataset = "hsapiens_gene_ensembl", host = "www.ensembl.org")

genes <- gsub("\\..*", "", res$gene)

genemap <- getBM(
  attributes = c("ensembl_gene_id", "hgnc_symbol"),
  filters = "ensembl_gene_id",
  values = genes,
  mart = ensembl
)

check_local_symbol <- function(ref, local_symbols) {
  if (ref %in% local_symbols$group_name) {
    hgnc_symbol <- local_symbols$value[local_symbols$group_name == ref][1]
    if (!hgnc_symbol == "") {
      return(hgnc_symbol)
    } else {
      return(ref)
    }
  } else {
    return(ref)
  }
}

local_symbols <- data.frame(rowData(dds)$symbol)
local_symbols$value[is.na(local_symbols$value)]<-""
gene_id_list <- NULL


for (ref in genes) {
  if (ref %in% genemap$ensembl_gene_id) {
    hgnc_symbol <- genemap$hgnc_symbol[genemap$ensembl_gene_id == ref][1]
    if (!hgnc_symbol == "") {
      gene_id_list <- append(gene_id_list, hgnc_symbol)
    } else {
      ref<-check_local_symbol(ref, local_symbols)
      gene_id_list <- append(gene_id_list, ref)
    }
  } else {
    ref<-check_local_symbol(ref, local_symbols)
    gene_id_list <- append(gene_id_list, ref)
  }
}

res<-res %>%
  add_column(symbol=gene_id_list) %>%
  relocate(symbol, .after = gene)

deseq_genes <- res %>%
  as.data.frame() %>%
  filter(FDR < 0.05) %>%
  filter(logFC>=log2(2)|logFC<=-log2(2)) %>%
  dplyr::select(EnsemblID= gene, symbol, logFC, pvalue, FDR) %>%
arrange(FDR)
deseq_genes_count <- nrow(deseq_genes)
output_note <- paste0("\nTotal differential expressed genes with adjusted p<0.05: ", deseq_genes_count, "\n(top 1000 shown above)")
deseq_genes %>%
  datatable()

res <- res %>%
  mutate(
    Expression = case_when(
      logFC >= log2(2) & FDR <= 0.05 ~ "Up-regulated",
      logFC <= -log2(2) & FDR <= 0.05 ~ "Down-regulated",
      TRUE ~ "Unchanged"
    )
  ) %>%
  mutate(
    Significance = case_when(
      abs(logFC) >= log2(2) & FDR <= 0.05 & FDR > 0.01 ~ "FDR 0.05",
      abs(logFC) >= log2(2) & FDR <= 0.01 & FDR > 0.001 ~ "FDR 0.01",
      abs(logFC) >= log2(2) & FDR <= 0.001 ~ "FDR 0.001",
      TRUE ~ "Unchanged"
    )
  )


top <- 25
top_genes <- bind_rows(
  res %>%
    filter(Expression == "Up-regulated") %>%
    arrange(FDR, desc(abs(logFC))) %>%
    head(top),
  res %>%
    filter(Expression == "Down-regulated") %>%
    arrange(FDR, desc(abs(logFC))) %>%
    head(top)
)

volcano_plot <- ggplot(res, aes(logFC, -log(FDR, 10))) +
  geom_point(aes(color = Significance), size = 2 / 5) +
  xlab(expression("log"[2] * "(Fold change)")) +
  ylab(expression("-log"[10] * "FDR")) +
  scale_color_viridis_d(option = "B") +
  guides(colour = guide_legend(override.aes = list(size = 1.5))) +
  geom_vline(xintercept = c(-1, 1), col = "red") +
  geom_hline(yintercept = -log10(0.05), col = "red") +
  ggtitle("Lung tissue transcriptome of COPD patients x Healthy individuals") +
  geom_label_repel(
    data = top_genes,
    mapping = aes(logFC, -log(FDR, 10), label = symbol),
    size = 2,
    max.overlaps = Inf
  )

volcano_plot

#PCA

tdds <- vst(dds,blind = T)

pcaData <- plotPCA(tdds, intgroup="condition", returnData=TRUE)

percentVar <- round(100 * attr(pcaData, "percentVar"))

ggplot(pcaData, aes(PC1, PC2, color=group)) +
  geom_point(size=3) +
  xlab(paste0("PC1: ",percentVar[1],"% variance")) +
  ylab(paste0("PC2: ",percentVar[2],"% variance")) + 
  coord_fixed()+
  stat_ellipse(aes(x=PC1,y=PC2,fill=factor(group)), show.legend=FALSE,
               geom="polygon", level=0.8, alpha=0.05)+
  guides(color=guide_legend("Cluster"))+
  ggtitle("PCA plot of COPD patients x Healthy individuals")

#Heatmap

tddsa <- assay(tdds)
rownames(tddsa) <- gsub("\\..*", "", row.names(tddsa))
topDE <- tddsa[genes,]
rownames(topDE) <- res$symbol
top_bottom_DE <- rbind(head(topDE, n=10), tail(topDE, n=10))
annotation <- as.data.frame(colData(tdds)[, 'condition'])
rownames(annotation) <- colnames(top_bottom_DE)
pheatmap(top_bottom_DE, scale = "row", clustering_distance_rows = "correlation", annotation_col = annotation, main="Top 10 over-expressed \nand top 10 under-expressed \nDifferentially Expressed genes")

#GSE

human <- "org.Hs.eg.db"

stat_list<-res$stat
names(stat_list)<-genes
gene_list = sort(stat_list, decreasing = TRUE)

gse <- gseGO(geneList=gene_list, 
             ont ="MF", 
             keyType = "ENSEMBL", 
             nPerm = 10000, 
             minGSSize = 3, 
             maxGSSize = 800, 
             pvalueCutoff = 0.05, 
             verbose = TRUE, 
             OrgDb = human, 
             pAdjustMethod = "none")

dotplot(gse, showCategory=10, split=".sign", font.size = 5) + facet_grid(.~.sign)
