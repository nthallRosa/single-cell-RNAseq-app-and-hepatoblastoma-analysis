## Project overview
In this portfolio project, I demonstrate my capability to conduct single cell RNAseq analysis and develop apps using Rshiny. The hepatoblastoma dataset was developed by Bondoc et. al in 2021 with the goal of identifying cell populations and molecular pathways that serve as key drivers of the disease. This dataset can be found using the following Gene Expression Omnibus accession number (GSE180666). The following link leads to the html file from which one can view the entire report:
(Include link)

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
