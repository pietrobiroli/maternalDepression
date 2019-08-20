# Maternal Depression Data and Code
This readmefile explains how to replicate the analysis in
Baranov, Bhalotra, Biroli, Maselko (2019)
"Maternal Depression, Women’s Empowerment, and Parental Investment: Evidence from a Randomized Control Trial"

Authors: Victoria Baranov & Pietro Biroli

Date: August 11, 2019

Data and Code can be downloaded here: https://github.com/pietrobiroli/maternalDepression


## How to replicate the results
### STEP 1:
- Download and unpack the zip file into a preferred location.
- Folder should contain the following elements
    -  folders:
        -  dataClean/
        -  figures/
        -  logfiles/
        -  tables/

  -  files:
      -  README.md
      -  README.pdf
      -  00_runall.do
      -  THP_analysis.do
      -  THP_cleandata.do
      -  THP_mergedata.do
      -  THP_label_variables.do
      -  _gweightave.ado
      -  pstar.ado
      -  randcmd.ado
      -  randcmd.sthlp
      -  stepdownB.ado
      -  stepdownrandcmd.ado

### STEP 2:
  - Open 00_runall.do in Stata
  - Change the "global maindir" location to the path on your computer where you downloaded the data
  - run 00_runall.do: this will run the data analysis, probably over serval days, and produce all of the
	output presented in the paper.
  - To obtain only a subset of the output, open THP_analysis.do and set the switches to 1 or 0 accordingly
  - To make the code run faster, open THP_analysis.do and change "global iterations" to a lower number (e.g.
	10)
  - NB: Files THP_merge.do and THP_cleandata.do merge and clean raw data that is not publicly available due to confidential information on respondents and health workers.



## Description of the code
### NOT FOR REPLICATION:

0. THP_merge.do --
This file merges the raw data and ensures that the publically available data contains no confidential information. The raw datasets are not included as they all contain	identifying information on respondents and health workers.


1. THP_cleandata.do -- This file starts from the merged data and cleans it for the analysis
    * This file will use the following inputs
        * /dataRaw/THP_merge.dta

    *This file will produce the following outputs
        * /dataClean/THP_clean.dta
        * /dataClean/THP_clean.csv

    * commands needed:
        * _gweightave (From Haushofer 2013)
        * mat2txt
        * xtgraph
        * zanthro (from https://www.stata-journal.com/article.html?article=dm0004_1)

### FOR REPLICATION:

2. THP_analysis.do -- 	This file takes the clean data (from THP_cleandata.do) and runs the analysis for the paper.
NB: The code can take several days to run to reproduce all the tables in the paper because of the randomization inference and stepdown procedures.

    * This file will use the following inputs
        * /dataClean/THP_clean.dta

    * This file will produce the following outputs
        * all Tables and Figures in the manuscript and online appendix.

    * commands needed:
         * pstar           (from https://github.com/PrincetonBPL/ado-gallery)
         * leebounds       (from https://github.com/PrincetonBPL/ado-gallery)
         * randcmd         (from A Young's website http://personal.lse.ac.uk/YoungA/)
         * stepdownB       (adapted from https://github.com/PrincetonBPL/ado-gallery)
         * stepdownrancmd  (adapted from https://github.com/PrincetonBPL/ado-gallery)
         * mat2txt
         * estout
         * moremata
         * xtgraph
         * kdens
         * coefplot
         * blindschemes
         * grc1leg     (from http://www.stata.com/users/vwiggins/grc1leg/grc1leg.ado)
         * leebounds   (from https://www.stata-journal.com/article.html?article=st0364)
