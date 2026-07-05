library(shiny)
library(shinydashboard)
library(shinydashboardPlus)
library(markdown)
library(shinyjs)
library(tools)
library(Seurat)
library(shinybusy)
library(ggplot2)
library(stringr)

load_seurat_obj <- function(path){
        errors <- c()
        # check file extension
        if (!tolower(tools::file_ext(path)) == "rds") { # ignores case
                errors <- c(errors, "Invalid rds file.")
                return(errors)
        }


# try to read in file
tryCatch(
        {
                obj <- readRDS(path)
        },
        error = function(e) {
                errors <- c(errors, "Invalid rds file.")
                return(errors)
        }
)

# Validate obj is a seurat object
if (!inherits(obj, "Seurat")){
        errors <- c(errors, "File is not a seurat object")
        return(errors)
}

return(obj)
}

create_metadata_UMAP <- function(obj, col){
        if (col %in% c("nCount_RNA", "nFeature_RNA", "percent.mt")){
                col_df <- data.frame(obj@reductions$umap@cell.embeddings, data = obj@meta.data[,col])
                umap <- ggplot(data = col_df) +
                        geom_point(mapping = aes(umap_1, umap_2, color = log10(data)), size = 0.01) +
                        scale_colour_gradientn(colours = rainbow(7))
        } else if (col %in% colnames(obj@meta.data)) {
                umap <- DimPlot(obj, pt.size = .1, label = T, label.size = 4, group.by = col, reduction = "umap",)
        } else {
                umap <- ggplot() +
                        theme_void() +
                        geom_text(aes(x = 0.5, y = 0.5, label = "col doesn't exist"), size = 15, color = "gray73", fontface = "bold") +
                        theme(plot.margin = unit(c(0, 0, 0, 0), "cm"))
        }
        return(umap)
}


create_feature_plot <- function(obj, gene) {
        if (gene %in% rownames(obj)) {
                FP <- FeaturePlot(obj, features = gene, pt.size = 0.001, combine = FALSE)
        } else {
                FP <- ggplot() + 
                        theme_void() + 
                        geom_text(aes(x = 0.5, y = 0.5, label = "Gene doesn't exist"), size = 15, color = "gray73", fontface = "bold") +
                        theme(plot.margin = unit(c(0, 0, 0, 0), "cm"))
        }
        return(FP)
}


de_analysis <- function(obj, group1, group2) {
        group1 <- as.character(group1)
        group2 <- as.character(group2)
                   de_output <- FindMarkers(obj,ident.1 = group1, 
                                        ident.2 = group2 ,test.use = "wilcox", 
                                        verbose = FALSE, slot = "data")
                   de_filter <- de_output[de_output$p_val_adj < 0.01 & (de_output$avg_log2FC > 1.5 | de_output$avg_log2FC < -1.5), ]
                   return(de_filter)
        
}

celltype_extract <- function(obj){
        # This function is used extract the cell types from the active ident
        # of a seurat object that contains information on cell type and condition.
        # This extraction is necessary for the proper functioning of the
        # visualizations generator in the DE Analysis panel
        ct_minus_treat <- c()
        ct_plus_treat <- levels(obj@active.ident)
        # Each level in the active ident, is looped through in reverse order
        # until a separator (number, special char, underscore, etc. is identified).
        # When one is found everything prior to the separator is extracted, stored
        # into ct_minus_treat, and the for loop for that character ends.
        for (i in ct_plus_treat){
                for (y in rev(1:nchar(i))){
                        ch <- substr(i, y,y)
                        if ((grepl("^[0-9_[:punct:][:space:]]$", ch))){
                                ct_minus_treat <- append(ct_minus_treat, substr(i, 1, y-1))
                                break
                        }
                }
        }
        
        ct_minus_treat <- unique(ct_minus_treat)
        return(ct_minus_treat)
        
}



de_vis <- function(obj, genes, groups, sep, v1 = T, v2 = F, v3 = F, multiple.groups = T){
        if (multiple.groups == T){
        # will use the celltype_extract to pull the celltypes from the
        # current ident
        celltypes <- celltype_extract(obj)
        # Identifies the metadata column name that contains those cell types.
        # This information will be used to switch the ident of the seurat
        # object to the ident that contains the cell types so it can be used
        # to generate the plots.
        for (i in seq_along(obj@meta.data)) {
                if(all(celltypes %in% levels(unique(obj@meta.data[[i]]))) & 
                   length(celltypes) == length(levels(unique(obj@meta.data[[i]])))){
                        col.name <- colnames(obj@meta.data[i])
                        Idents(obj) <- col.name
                        Idents(obj) <- factor(Idents(obj), levels = celltypes)
                }
        }
        }
        
        if (v1) {
                dot_plot <- DotPlot(subset(obj, idents = groups), features = genes, 
                cols = c("blue", "red"), split.by = sep) + RotatedAxis()
                return(dot_plot)
        }
        if(v2) {
                feature_plot <- FeaturePlot(obj, features = genes, split.by = sep, 
                                                    max.cutoff = 3, cols = c("grey","red"))
                return(feature_plot)
        }
        if(v3) {
                violin_plot <- VlnPlot(subset(obj, idents = groups), features = genes, 
                                split.by = sep, pt.size = 0, combine = FALSE)
                return(violin_plot)
                } 
}
