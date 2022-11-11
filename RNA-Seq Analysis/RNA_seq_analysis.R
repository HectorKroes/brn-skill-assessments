library(recount)
library(DESeq2)
library(ggplot2)
library(gplots)
library(tidyverse)
library(ggrepel)
library(DOSE)
library(DT)
require(biomaRt)
library(pheatmap)
library(fgsea)
library(reactome.db)
library(DiagrammeR)

study_acession <- "SRP041538"

if (!file.exists(file.path(study_acession, "rse_gene.Rdata"))) {
  download_study(study_acession)
}

load(file.path(study_acession, "rse_gene.Rdata"))

rse <- scale_counts(rse_gene)

rse$condition <- sapply(strsplit(as.character(rse$title), "-"), `[`, 2)

dds <- DESeqDataSet(rse, ~condition)
dds$condition <- relevel(dds$condition, ref = "NOR")

keepers <- (rowSums(counts(dds)) / ncol(dds)) >= quantile((rowSums(counts(dds)) / ncol(dds)), .2)
dds <- dds[keepers, ]

dds <- DESeq(dds)

res <- as_tibble(results(dds, alpha = 0.05), rownames = "gene",  pAdjustMethod = "BH") %>%
  rename(logFC = log2FoldChange) %>%
  rename(FDR = padj)

ensembl <- useMart("ENSEMBL_MART_ENSEMBL", dataset = "hsapiens_gene_ensembl", host = "www.ensembl.org")

genes <- gsub("\\..*", "", res$gene)

genemap <- getBM(
  attributes = c("ensembl_gene_id", "hgnc_symbol", "entrezgene_id"),
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
      return(NA)
    }
  } else {
    return(NA)
  }
}

local_symbols <- data.frame(rowData(dds)$symbol)
local_symbols$value[is.na(local_symbols$value)] <- ""
gene_id_list <- NULL


for (ref in genes) {
  if (ref %in% genemap$ensembl_gene_id) {
    hgnc_symbol <- genemap$hgnc_symbol[genemap$ensembl_gene_id == ref][1]
    if (!hgnc_symbol == "") {
      gene_id_list <- append(gene_id_list, hgnc_symbol)
    } else {
      ref <- check_local_symbol(ref, local_symbols)
      gene_id_list <- append(gene_id_list, ref)
    }
  } else {
    ref <- check_local_symbol(ref, local_symbols)
    gene_id_list <- append(gene_id_list, ref)
  }
}

res <- res %>%
  add_column(symbol = gene_id_list) %>%
  relocate(symbol, .after = gene)

deseq_genes <- res %>%
  as.data.frame() %>%
  filter(FDR < 0.05) %>%
  dplyr::select(EnsemblID = gene, symbol, logFC, pvalue, FDR) %>%
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


top_bottom <- function(top, res) {
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
  return(top_genes)
}

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
    data = top_bottom(40, res),
    mapping = aes(logFC, -log(FDR, 10), label = symbol),
    size = 2,
    max.overlaps = Inf
  )

volcano_plot

# PCA

tdds <- vst(dds, blind = T)

pcaData <- plotPCA(tdds, intgroup = "condition", returnData = TRUE)

percentVar <- round(100 * attr(pcaData, "percentVar"))

ggplot(pcaData, aes(PC1, PC2, color = group)) +
  geom_point(size = 3) +
  xlab(paste0("PC1: ", percentVar[1], "% variance")) +
  ylab(paste0("PC2: ", percentVar[2], "% variance")) +
  coord_fixed() +
  stat_ellipse(aes(x = PC1, y = PC2, fill = factor(group)),
    show.legend = FALSE,
    geom = "polygon", level = 0.8, alpha = 0.05
  ) +
  guides(color = guide_legend("Cluster")) +
  ggtitle("PCA plot of COPD patients x Healthy individuals")

# Heatmap

tddsa <- assay(tdds)
rownames(tddsa) <- gsub("\\..*", "", row.names(tddsa))

filtered_res <- res %>%
  filter(!is.na(symbol))

heat_genes <- top_bottom(10, filtered_res)
heat_genes$gene <- gsub("\\..*", "", heat_genes$gene)

topDE <- tddsa[heat_genes$gene, ]
rownames(topDE) <- heat_genes$symbol

col_annotation <- as.data.frame(colData(tdds)[, "condition"])
colnames(col_annotation) <- "Condition"
rownames(col_annotation) <- colnames(topDE)

row_annotation <- as.data.frame(heat_genes$Expression)
colnames(row_annotation) <- "Expression"
rownames(row_annotation) <- heat_genes$symbol

pheatmap(topDE,
  scale = "row",
  clustering_distance_rows = "correlation",
  annotation_col = col_annotation,
  annotation_row = row_annotation,
  show_colnames = FALSE,
  annotation_names_row = FALSE,
  annotation_names_col = FALSE,
  main = "20 genes with the strongest differential expression"
)

# GSEA

genemap$entrezgene_id[is.null(genemap$entrezgene_id)] <- NA

entrez_id_list <- NULL

for (ref in genes) {
  if (ref %in% genemap$ensembl_gene_id) {
    entrez_id <- genemap$entrezgene_id[genemap$ensembl_gene_id == ref][1]
    if (!is.na(entrez_id)) {
      entrez_id_list <- append(entrez_id_list, entrez_id)
    } else {
      entrez_id_list <- append(entrez_id_list, NA)
    }
  } else {
    entrez_id_list <- append(entrez_id_list, NA)
  }
}

res$entrez_id <- as.character(entrez_id_list)

gsea_data <- subset(res, !is.na(stat)) %>%
  subset(!is.na(FDR))

pathways <- reactomePathways(gsea_data$entrez_id)

ranked_genes <- gsea_data$stat
names(ranked_genes) <- gsea_data$entrez_id

fgseaRes <- fgsea(pathways, ranked_genes, maxSize = 500)

topPathwaysUp <- fgseaRes[NES > 0][head(order(padj), n = 10), pathway]
topPathwaysDown <- fgseaRes[NES < 0][head(order(padj), n = 10), pathway]
topPathways <- c(topPathwaysUp, rev(topPathwaysDown))
plotGseaTable(pathways[topPathways], ranked_genes, fgseaRes,
  gseaParam = 0.5
)
