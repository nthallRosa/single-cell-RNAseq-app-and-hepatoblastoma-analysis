## Project overview
In this portfolio project, I demonstrate my capability to conduct single cell RNAseq analysis and develop apps using Rshiny. The hepatoblastoma dataset was developed by Bondoc et. al in 2021 with the goal of identifying cell populations and molecular pathways that serve as key drivers of the disease. This dataset can be found using the following Gene Expression Omnibus accession number (GSE180666). The following link leads to the html file from which one can view the entire report: https://nthallRosa.github.io/single-cell-RNAseq-app-and-hepatoblastoma-analysis/hepatoblastoma.html

## Single cell analysis
Hepatoblastoma is one of the primary liver cancers in young children, and despite the many advancements made in the treatment of the disease, little is known about how it is initiated or progresses. The goal of this analysis was to focus on the non-tumor population of cells and see if there were increased expression of genes involved in biological processes that advanced tumor cells. 17 clusters were generated consisting of neurons, tumor cells, hepatocytes, stellate cells, endothelial cells, Kupffer/M2 macrophages, exhausted memory T cells, erythrocytes, and cholangiocytes. 
<div align="center">
    <img src="https://github.com/user-attachments/assets/82ce18c0-8d40-4a90-bc33-78ddc122f6cd" alt="Description" width="750">
</div>

Differential expression analysis results uncovered several genes upregulated in non-tumor cells that are involved processes that advance tumor cells. These include:
* endothelial cells (VEGF and HIF-1 alpha, involved in the promotion of angiogenesis via the Warburg effect)
* kupffer/M2 cells (SPP1, CSF1, ANGPT2, involved in angiogenesis, stemeness, M2 polarization, and tumor invation)
* exhausted memory T cells (IKZF2, ICOS, and SLAMF, involved in t cell exhaustion and immune suppression)
* Stellate cells (FAP, IL34, ANGPT2, and VCAM1, with possible roles in tumor macrophage recruitment/M2 polarization, angiogenesis, immune cell retention and erythroblastic island formation)

<div align="center">
    <img src="https://github.com/user-attachments/assets/2bbe7700-63ea-471b-8299-0847f77df1c0" alt="Description" width="600">
</div>

## Single cell analysis app
The single cell app enables one to examine UMAPs, explore feature maps for genes, and conduct differential gene expression analysis. Only seurat objects can be uploded, and users will be asked if they want to compare multiple conditions (e.g treatment vs normal, or multiple batches) or not. 
After uploading the .rds file, tabs “UMAP” and “Gene expression” will appear in the Data Exploration panel, enabling one to examine clusters and feature plots to look at gene expression.




https://github.com/user-attachments/assets/80cdbf9f-f991-446e-97e0-80a7088b1092





In the Tables tab one can conduct differential gene expression analysis between two groups and generate a table that can be downloaded for further use. In order to reduce the number of genes loaded onto the browser, the table is filtered so that only those with an adjusted p value less than 0.01 and an average log2 fold change greater than +1.5 or less than -1.5 are included. 






## Limitations and Steps to take before uploading
* The differential gene expression analyzer uses the current ident of the seurat object, so users will need to ensure it is switched to the right one before uploading the .rds file. For instance, if one wanted to compare cell types from different conditions it would be necessary to create a column in the metadata table of the seurat object that contained both that information and make that the active ident (e.g. a "celltype.stim" column that had CD4_T_normal, CD4_T_cancer, etc.). Those comparing across conditions must place some kind of seperator (space, number, underscore, or other special character) between the cell types and the condition, else the output will not be accurate.
* This app is optimal for small to mid sized datasets (~250 - 830MB). Those closer to the 800 range could take about a minute to upload, and users are advised to eliminate genes from their dataset they might not be intrested in to improve speed.
* In order to reduce the number of genes loaded onto the browser, the table is filtered so that only those with an adjusted p value less than 0.01 and an average log2 fold change greater than +/- 1.5 are included. Genes that fall outside of that range won't be included.




