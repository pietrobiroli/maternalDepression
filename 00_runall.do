* This readmefile explains how to replicate the analysis in 
* Baranov, Bhalotra, Biroli, Maselko (2019)
* "Maternal Depression, Women’s Empowerment, and Parental Investment: Evidence 
* from a Randomized Control Trial"
* README By: Victoria Baranov & Pietro Biroli
* August 11, 2019

/*
STEP 1: 
  - Dowload and unpack the zip file into a preferred location.
  - Folder should contain the following elements
	* folders: 	dataClean
				figures
				logfiles
				tables 
				
	* files: 	README.txt 
				README.pdf 
				00_runall.do 
				THP_cleandata.do 
				THP_mergedata.do 
				THP_analysis.do 
				THP_label_variables.do 
				_gweightave.ado pstar.ado  
				randcmd.sthlp 
				randcmd.ado 
				stepdownB.ado 
				stepdownrandcmd.ado

STEP 2:
  - Open 00_runall.do
  - Change the "global maindir" location to the path on your computer where you 
	downloaded the data
  - Run 00_runall.do: this will run the data analysis, probably over serval days
	, and produce all of the output presented in the paper. 
  - To obtain only a subset of the output, open THP_analysis.do and set the 
	switches to 1 or 0 accordingly 
  - To make the code run faster, open THP_analysis.do and change "global 
	iterations" to a lower number (e.g. 10)
  - Files THP_merge.do and THP_cleandata.do merge and clean raw data that is not
	publically available due to confidential information on respondents and 
	health workers. 
*/


* TO BE CHANGED: SET THE DIRECTORY
global maindir "/Users/cicciobello/Downloads/supercoolpapers/maternalDepression/"
global maindir "/home/ubuntu/maternalDepression/"


* DO NOT CHANGE
global tablefile "${maindir}/tables/"
global figurefile "${maindir}/figures/"

cd ${maindir}

* Install, if needed
ssc install mat2txt 
ssc install moremata
ssc install xtgraph
ssc install kdens
ssc install coefplot
ssc install blindschemes
ssc install estout 


// search zanthro   //(from https://www.stata-journal.com/article.html?article=dm0004_1)
net install dm0004_1, from(http://www.stata-journal.com/software/sj13-2)
//search grc1leg   //(from http://www.stata.com/users/vwiggins/grc1leg/grc1leg.ado)
net install grc1leg, from(http://www.stata.com/users/vwiggins)
//search leebounds //(from https://www.stata-journal.com/article.html?article=st0364)
net install st0364, from(http://www.stata-journal.com/software/sj14-4)
// search ivqte
net install st0203, from(http://www.stata-journal.com/software/sj10-3)
*


/*
*------------------------------------------------------------------------------
* NOT FOR REPLICATION:
*-------------------------------------------------------------------------------
do THP_mergedata.do 

*-- This file merges the raw data and ensures that the publically available data
	contains no confidential information. The raw datasets are not included as 
	they all contain identifying information on respondents and health workers.


do THP_cleandata.do 

*-- This file starts from the merged data and cleans it for the analysis

  *This file will use the following inputs	
  *in:  /dataRaw/THP_merge.dta
  
  *This file will produce the following outputs	
  *out: /dataClean/THP_clean.dta
  *     /dataClean/THP_clean.csv
*/ 

*-------------------------------------------------------------------------------
* FOR REPLICATION:
*-------------------------------------------------------------------------------
do THP_analysis.do 

*-- This file takes the clean data (from THP_cleandata.do) and runs the analysis
*	for the paper. NB: The code can take several days to run to reproduce all 
*	the tables in the paper because of the randomization inference and stepdown 
*	procedures.

  *This file will use the following inputs	
  *in: /dataClean/THP_clean.dta
  
  *This file will produce the following outputs	
  *out: all Tables and Figures in the manuscript and online appendix.
 

exit
