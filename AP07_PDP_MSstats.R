## AP07 PDP MSstats connector
## Anywhere there is a variable assigned from PDP, have noted PDP SOURCE

#### Load required pacakges, MSstats ####
list.of.packages <- c("MSstats", "MSstatsTMT")
## installing instead in dockerfile specific versions
lapply(list.of.packages, library, character.only = TRUE)

#### Read in data from PDP ####
## One dataset to be passed from PDP
## PDP SOURCE
## for Spectronaut example
# setwd("~/Desktop")
# df_raw_from_PDP <- read.table("Report_CardioCRISPR_FullScreen_Plates1-4_DIA-30SPD.tsv", sep = "\t", header = T, na.strings = c("NA", "NULL", "Null", "null", "NaN", "Na", ""))
## for PD example
# df_raw_from_PDP <- read.csv("_GIPR_Lumos_TMT6_MS3_ytp_exp61_GIPR_TEselectivity_rerunFraction5_PeptideGroups.txt", sep = "\t", header = T, na.strings = c("NA", "NULL", "Null", "null", "NaN", "Na"))
# df_raw_from_PDP <- read.csv("./example_files_scratch/FBXO22KO_PSMs_112624.csv", header = T, na.strings = c("NA", "NULL", "Null", "null", "NaN", "Na"))
## a local download from Kari
df_raw_from_PDP <- read.csv("/Users/PANOVA02/Downloads/2024_12_16_TRAF7_IP_TMT18_FINAL_all_columns_PSMs (1).txt", header = T, na.strings = "", sep = "\t")
## Assign a character that dictates where the sourced data is from, which dictates which converter to use. Options are "Spectronaut", "
## PDP SOURCE
# char_PDP_df_source <- "Spectronaut"
char_PDP_df_source <- "PD"

## Need to check that the data has the correct columns to move forward. Maybe this can be a message inside of PDP?
if (char_PDP_df_source == "Spectronaut") {
  vec_colnames_needed <- c("R.Condition", "R.FileName", "R.Replicate", "PG.ProteinGroups", 
                           "PG.Qvalue", "EG.ModifiedSequence", "FG.Charge", "F.Charge", 
                           "F.FrgIon", "F.FrgLossType", "F.ExcludedFromQuantification", 
                           "F.PeakArea", "EG.Qvalue")
  if(all(vec_colnames_needed %in% names(df_raw_from_PDP)) == FALSE) {
    print(
      paste0(
        paste0("The necessary ProteomeDiscoverer columns are not present in the data. Please make sure the following columns are present: "), 
        ## no gsub here since the cols in Spectronaut actually do have a "."
        paste0(vec_colnames_needed, collapse = ", "),
      ))
    stop()
  }
}

if (char_PDP_df_source == "PD") {
  ## Ions.Score is only for Mascot search
  ## Ions.Score is needed if doing Mascot searches, which I don't think anyone is using currently
  # vec_colnames_needed <- c("Master.Protein.Accessions","Protein.Accessions", "Annotated.Sequence", "Charge", "Ions.Score", "Spectrum.File", "Quan.Info", "X..Proteins")
  vec_colnames_needed <- c("Master.Protein.Accessions","Protein.Accessions", "Annotated.Sequence", "Charge", "Spectrum.File", "Quan.Info", "X..Proteins")
  ## Groton and Cambridge use two different PD versions. Groton == 2.4, Cambridge == 3.1. This means different columns!! Let's see if MSstatsTMT can handle File.ID. No. So we need to change the "File.ID" to "Spectrum.File". 
  colnames(df_raw_from_PDP)[which(colnames(df_raw_from_PDP)=="File.ID")] <- "Spectrum.File"
  char_colnames_needed_regex <- c("Abundance")
  if(all(vec_colnames_needed %in% names(df_raw_from_PDP)) == FALSE | sum(grepl(char_colnames_needed_regex, colnames(df_raw_from_PDP)))==0) {
    print(
      paste0(
      paste0("The necessary ProteomeDiscoverer columns are not present in the data. Please make sure the following columns are present: "), 
      paste0(gsub("\\.", " ", vec_colnames_needed), collapse = ", "),
      paste0(", or ", char_colnames_needed_regex, "(s).")
    ))
    stop()
  }
}
## are these actually the only columns we need? 
colnames(df_raw_from_PDP)
df_raw_from_PDP <- df_raw_from_PDP[,which(colnames(df_raw_from_PDP) %in% vec_colnames_needed | grepl("Abundance", colnames(df_raw_from_PDP)))]


#### Filtering and MSstats to X Conversion, Annotation file ####
## Spectronaut specific step
if (char_PDP_df_source == "Spectronaut") {
  ## drop rows that MSstats throws out, don't make a new df since this is prob already large
  df_raw_from_PDP <- df_raw_from_PDP[which(df_raw_from_PDP$F.ExcludedFromQuantification=="False" & df_raw_from_PDP$F.FrgLossType=="noloss"),]
  ## Create annotations and run Converter
  ## REMOVE
  df_annot_precursor <- unique(df_raw_from_PDP[,c("R.Condition", "R.FileName", "R.Replicate")])
  df_annot <- data.frame(
    Run = df_annot_precursor$R.FileName,
    Condition = df_annot_precursor$R.Condition,
    BioReplicate = df_annot_precursor$R.Replicate
  )
  ## save memory
  df_annot_precursor <- NULL
  ## Run the MSstats converter
  list_quant <- MSstats::SpectronauttoMSstatsFormat(df_raw_from_PDP,
                                                  annotation = df_annot,
                                                  filter_with_Qvalue = T,
                                                  qvalue_cutoff = 0.01,
                                                  removeProtein_with1Feature = T)
  ## save memory
  df_raw_from_PDP <- NULL
  ## Run dataProcess step, "actual math" as Liang says
  ## If running Mac/Linux, can use multiple cores. Leave this commented out for now.
  # if (.Platform$OS.type=="unix") {
  #   spectronaut_proposed_30 <- MSstats::dataProcess(quant_30, 
  #                                                   normalization = 'EQUALIZEMEDIANS',
  #                                                   summaryMethod = "TMP",
  #                                                   # cutoffCensored = "minFeature",
  #                                                   censoredInt = "0",
  #                                                   ## suggested by Devon Kohler for large datasets
  #                                                   MBimpute = FALSE,
  #                                                   ## for DIA datasets, use topN
  #                                                   featureSubset = "topN",
  #                                                   ## for DIA datasets, use topN
  #                                                   n_top_feature = 20,
  #                                                   ## for MacOS or Linux, can assign multiple cores
  #                                                   numberOfCores = 4,
  #                                                   maxQuantileforCensored = 0.999)
  # }
  # if (.Platform$OS.type=="windows") {
  #   spectronaut_proposed_30 <- MSstats::dataProcess(quant_30, 
  #                                                   normalization = 'EQUALIZEMEDIANS',
  #                                                   summaryMethod = "TMP",
  #                                                   # cutoffCensored = "minFeature",
  #                                                   censoredInt = "0",
  #                                                   ## suggested by Devon Kohler for large datasets
  #                                                   MBimpute = FALSE,
  #                                                   ## for DIA datasets, use topN
  #                                                   featureSubset = "topN",
  #                                                   ## for DIA datasets, use topN
  #                                                   n_top_feature = 20,
  #                                                   ## for MacOS or Linux, can assign multiple cores
  #                                                   # numberOfCores = 4,
  #                                                   maxQuantileforCensored = 0.999)
  # }
  ## dataProcess step with the output from the converter
  list_spectronaut_proposed <- MSstats::dataProcess(list_quant, 
                                                  normalization = 'EQUALIZEMEDIANS',
                                                  summaryMethod = "TMP",
                                                  # cutoffCensored = "minFeature",
                                                  censoredInt = "0",
                                                  ## suggested by Devon Kohler for large datasets
                                                  MBimpute = FALSE,
                                                  ## for DIA datasets, use topN
                                                  featureSubset = "topN",
                                                  ## for DIA datasets, use topN, aywhere from 10-30, Liang suggested 10
                                                  n_top_feature = 10,
                                                  ## for MacOS or Linux, can assign multiple cores, commented out for now
                                                  # numberOfCores = 4,
                                                  maxQuantileforCensored = 0.999)
  ## save memory, compost
  list_quant <- NULL
  ## need to hold onto the entire list_spectronaut_proposed for the groupComparison step later
  
}

## temp
# df_annot <- read.csv("PD_annotation.csv", header = T)
df_annot <- read.csv("./example_files_scratch/PD_annot_Mary.csv", header = T)
df_annot <- do.call("rbind", replicate(length(unique(df_raw_from_PDP$Spectrum.File)), df_annot, simplify = FALSE))
df_annot$TechRepMixture <- 1
df_annot$Fraction <- rep(c(1:length(unique(df_raw_from_PDP$Spectrum.File))), each = length(unique(df_annot$Channel)))
vec_spectrum_files <- unique(df_raw_from_PDP$Spectrum.File)
vec_spectrum_files <- vec_spectrum_files[order(nchar(vec_spectrum_files), vec_spectrum_files)]
df_annot$Run <- rep(vec_spectrum_files, each = length(unique(df_annot$Channel)))

if (char_PDP_df_source == "PD") {
  ## Create annotations and run Converter
  # df_annot_precursor <- unique(df_raw_from_PDP[,c("R.Condition", "R.FileName", "R.Replicate")])
  # df_annot <- data.frame(
  #   Run = df_annot_precursor$R.FileName,
  #   Condition = df_annot_precursor$R.Condition,
  #   BioReplicate = df_annot_precursor$R.Replicate
  # )
  ## save memory
  df_annot_precursor <- NULL
  ## Run the MSstats converter. "Master.Protein.Accessions" is used for "ProteinName". "Sequence" and "Modifications" are used for "PeptideSequence". "Charge"
  list_quant <- MSstatsTMT::PDtoMSstatsTMTFormat(input = df_raw_from_PDP, annotation = df_annot)
  ## save memory
  df_raw_from_PDP <- NULL
  ## Run dataProcess step, "actual math" as Liang says
  ## If running Mac/Linux, can use multiple cores. Leave this commented out for now.
  # if (.Platform$OS.type=="unix") {
  #   spectronaut_proposed_30 <- MSstats::dataProcess(quant_30, 
  #                                                   normalization = 'EQUALIZEMEDIANS',
  #                                                   summaryMethod = "TMP",
  #                                                   # cutoffCensored = "minFeature",
  #                                                   censoredInt = "0",
  #                                                   ## suggested by Devon Kohler for large datasets
  #                                                   MBimpute = FALSE,
  #                                                   ## for DIA datasets, use topN
  #                                                   featureSubset = "topN",
  #                                                   ## for DIA datasets, use topN
  #                                                   n_top_feature = 20,
  #                                                   ## for MacOS or Linux, can assign multiple cores
  #                                                   numberOfCores = 4,
  #                                                   maxQuantileforCensored = 0.999)
  # }
  # if (.Platform$OS.type=="windows") {
  #   spectronaut_proposed_30 <- MSstats::dataProcess(quant_30, 
  #                                                   normalization = 'EQUALIZEMEDIANS',
  #                                                   summaryMethod = "TMP",
  #                                                   # cutoffCensored = "minFeature",
  #                                                   censoredInt = "0",
  #                                                   ## suggested by Devon Kohler for large datasets
  #                                                   MBimpute = FALSE,
  #                                                   ## for DIA datasets, use topN
  #                                                   featureSubset = "topN",
  #                                                   ## for DIA datasets, use topN
  #                                                   n_top_feature = 20,
  #                                                   ## for MacOS or Linux, can assign multiple cores
  #                                                   # numberOfCores = 4,
  #                                                   maxQuantileforCensored = 0.999)
  # }
  ## dataProcess step with the output from the converter
  list_PD_proposed <- MSstatsTMT::proteinSummarization(list_quant,
                                                       method = "msstats",
                                                       global_norm = TRUE,
                                                       MBimpute = FALSE)
  ## save memory, compost
  list_quant <- NULL
  ## need to hold onto the entire list_spectronaut_proposed for the groupComparison step later
  
}
# dataProcessPlotsTMT(data = list_PD_proposed, type = "QCplot", which.Protein = "allonly", width = 21, height = 7)
## This is nice for peptide level analysis!
# dataProcessPlotsTMT(data = list_PD_proposed, type = "ProfilePlot", which.Protein = 1, width = 21, height = 7)
#### Assigning Control and Experimental Groups ####
## This code is the same for any experiment
## make the controls, aka denominator
## PDP SOURCE
vec_control_conditions <- c("AAVS1_G1G2", "HPRT_G1G2", "HPRT_G1")
## create a list to collapse at end of building, one matrix for each control condition
## each element of this list will become a matrix, which we will rbind together at end
list_mat_comparison_msstats <- vector("list", length= length(vec_control_conditions))
## make the experimental conditions. These have to match what PDP assigns as vec_control_conditions, have to match what is in the dataset. For Spectronaut, this is R.Condition column. 
vec_experimental_conditions <- levels(list_spectronaut_proposed$ProteinLevelData$GROUP)[!(levels(list_spectronaut_proposed$ProteinLevelData$GROUP) %in% vec_control_conditions)]
## how to automate this matrix, hmm

## First create matrices that are length(vec_experimental_conditions) rows long with rownames == vec_experimental_conditions and colnames == all.
for (i in 1:length(list_mat_comparison_msstats)) {
  ## for now, the rownames do not contain the name of the control condition. We will replace later after grepl step. 
  list_mat_comparison_msstats_names01 <- list(mat_comparison_rows = paste0(vec_experimental_conditions),
                                                 mat_comparison_cols = levels(list_spectronaut_proposed$ProteinLevelData$GROUP))
  list_mat_comparison_msstats[[i]] <- matrix(ncol = length(levels(list_spectronaut_proposed$ProteinLevelData$GROUP)),
                                                nrow = length(vec_experimental_conditions),
                                                dimnames = list_mat_comparison_msstats_names01)
}

## This is the major matrix creation step
for (j in 1:length(list_mat_comparison_msstats)) {
  for (i in 1:length(vec_experimental_conditions)) {
    a <- vec_experimental_conditions[i]
    b <- list_mat_comparison_msstats[[j]][i,]
    list_mat_comparison_msstats[[j]][i,] <- as.integer(grepl(a, names(b)))
  }
}

## Now that we have that, we can assign the controls a value of -1
for (i in 1:length(vec_control_conditions)) {
  list_mat_comparison_msstats[[i]][,grep(paste0("^", vec_control_conditions[i], "$"), colnames(list_mat_comparison_msstats[[i]]))] <- -1
}

## last step is to add the control to the rownames
for (i in 1:length(list_mat_comparison_msstats)) {
  list_mat_comparison_msstats_names02 <- paste0(vec_experimental_conditions, "-", vec_control_conditions[i])
  rownames(list_mat_comparison_msstats[[i]]) <-  list_mat_comparison_msstats_names02
  
}

## Collapse into comparison matrix
mat_comparison_msstats <- do.call(rbind, list_mat_comparison_msstats)
## BOOM

#### Run groupComparison, the stats portion, of MSstats ####
## Run the differential analysis using MSstats
list_DA_msstats <- MSstats::groupComparison(contrast.matrix = mat_comparison_msstats, data = list_spectronaut_proposed)

## save memory, compost
list_spectronaut_proposed <- NULL

## Send back to PDP the comparison table
df_back_to_PDP <- list_DA_msstats$ComparisonResult
## PDP SOURCE