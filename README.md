# Thesis-supplementary-material
This repository contains supplementary material for the research on "Multispectral Observation in the VIS-SWIR Range: Atmospheric Effects and the potential of enhanced DRI through Sensor Fusion". The repository includes MATLAB scripts developed during the thesis and technical documentation of the hardware used.

## Data Sheets
In the folder called "Data sheets" you will find the technical specification for each product used in the research. The sheets are directly aquired from the supllier whom we purchased the products. 

## MODTRAN
To motivate the selection of filters (found in the datasheets folder), different transmittance spectra had to be created. These were generated with the help of PcModWin 6 (https://ontar.com/pcmodwin-6), a standard Windows interface for MODTRAN6. The simulated data was obtained as ".csv"-files and analyzed in MATLAB.

The goal of the code was to simplify the analysis of MODTRAN data, allowing users select desired datapoints and specify how to display them. The specific slections you can make in this code are: 

### Data Selection
This feature makes it easier for the user to plot sevral diffrent dataset in the same figure for simple comparison between diffrent weather conditions and study how the transmittance behaviour changes.

### Averaging Type
Due to each file containng a large amount of datapoints, the selected transmittance can be averaged over a few moivng points to facilitate an easier analysis of the plots. Arbitary moving averages over 7, 31 and 71 points were created.

### Transmittance Type
Since Transmittance is caused by the amount of specific particles in the air, each MODTRAN file contain 41 columns of transmittance data caused by specified substance, such as H2O, O3, N2, HNO3 an so on. The two first column of transmittance data are "Total transmittance" and "H2O" and are the most significant for this study. 

### Filter selection
To underline which filters that should be used for the study, the user can slect them to be plotted togheter with the MODTRAN data. This provides a greater understanding of which wavelenghts will be recieved by the sensor. 

## Image Processing 

### Main Script
The main MATLAB script served as the entry point for the image processing workflow. 

### Intensity Profile
The Intensity profile function extracts a 1D intensity distrobution plot from a user-defined region of interest. The purpose of the function is to quantitaviley evaluate how well inherent target features can be resolved in each image. 



### Alignment
