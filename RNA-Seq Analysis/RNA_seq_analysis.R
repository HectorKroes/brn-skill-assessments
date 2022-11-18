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

res <- as_tibble(results(dds, alpha = 0.05), rownames = "gene", pAdjustMethod = "BH") %>%
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

diffexpgen <- res %>%
  filter(Expression == "Up-regulated" | Expression == "Down-regulated")

tdds <- tdds[rownames(tdds) %in% diffexpgen$gene, ]

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

relexp <- function(eid, res) {
  index <- res %>%
    filter(gene == eid) %>%
    dplyr::select(logFC)
  return(2**index$logFC)
}

getpvalue <- function(symb, res) {
  padj <- res %>%
    filter(symbol == symb) %>%
    dplyr::select(FDR)
  padj <- round(padj$FDR, digits = 3)[1]
  print(padj)
  if (padj == 0) {
    return("p-value\n<0.001")
  } else {
    return(paste0("p-value\n", padj))
  }
}

inf_genes_symb <- c("CXCR1", "CXCR2", "CXCL12", "IL1B", "RELA", "EGFR")
inf_genes_eid <- c("ENSG00000163464.7", "ENSG00000180871.7", "ENSG00000107562.16", "ENSG00000125538.11", "ENSG00000173039.18", "ENSG00000146648.16")
c1 <- c(rep(inf_genes_symb, 2))
c2 <- c(c(rep("NOR", length(inf_genes_symb))), c(rep("COPD", length(inf_genes_symb))))
c3 <- c(c(rep(1, length(inf_genes_symb))), c(sapply(inf_genes_eid, relexp, res)))
c4 <- sapply(inf_genes_symb, getpvalue, res)

annot1 <-
  tibble(
    variable = inf_genes_symb,
    label = c4,
    xpos = c(1:length(inf_genes_symb)),
    ypos = Inf,
    vjustvar = 2
  )

df <- data.frame(c1, c2, c3)
df$c2 <- factor(df$c2, levels = c("NOR", "COPD"))

bargraph <- ggplot(data = df) +
  geom_bar(aes(
    x = c1,
    y = c3,
    fill = c2,
    color = c2
  ),
  stat = "identity",
  position = position_dodge()
  ) +
  geom_text(data = annot1, aes(label = label, x = xpos, y = ypos, vjust = vjustvar)) +
  labs(
    x = "Genes", y = "Relative expression",
    title = "Relative expression of genes in CXCL-8-CXCR1/2 axis"
  ) +
  expand_limits(x = c(0, 0), y = c(0, 2.5))
bargraph

serpins <- (res %>% filter(FDR < 0.05) %>% filter(grepl("SERPIN", symbol)))
serp_genes_symb <- serpins$symbol
serp_genes_eid <- serpins$gene
c1 <- c(rep(serp_genes_symb, 2))
c2 <- c(c(rep("NOR", nrow(serpins))), c(rep("COPD", nrow(serpins))))
c3 <- c(c(rep(1, nrow(serpins))), c(sapply(serp_genes_eid, relexp, res)))
c4 <- sapply(serp_genes_symb, getpvalue, res)

annot <-
  tibble(
    variable = serp_genes_symb,
    label = c4,
    xpos = c(1:nrow(serpins)),
    ypos = Inf,
    vjustvar = 2
  )

df <- data.frame(c1, c2, c3)
df$c2 <- factor(df$c2, levels = c("NOR", "COPD"))

bargraph <- ggplot(data = df) +
  geom_bar(aes(
    x = c1,
    y = c3,
    fill = c2,
    color = c2
  ),
  stat = "identity",
  position = position_dodge()
  ) +
  geom_text(data = annot, aes(label = label, x = xpos, y = ypos, vjust = vjustvar)) +
  labs(
    x = "Genes", y = "Relative expression",
    title = "Relative expression of genes in CXCL-8-CXCR1/2 axis"
  ) +
  expand_limits(x = c(0, 0), y = c(0, 2.5))
bargraph

mito_plot <- plotEnrichment(pathways[["Mitochondrial translation"]], ranked_genes) + labs(title = "Mitochondrial translation enrichment")

mito_plot
