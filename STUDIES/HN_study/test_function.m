addpath('C:\Projects\Research\medical\radiomics\rad_val\STUDIES\HN_study\Functions');
addpath('C:\Projects\Research\medical\radiomics\rad_val\STUDIES\HN_study\Utilities');
addpath('C:\Projects\Research\medical\radiomics\rad_val\STUDIES\HN_study\NonTextureFeatures');
addpath('C:\Projects\Research\medical\radiomics\rad_val\STUDIES\HN_study\MultivariableModeling');
addpath('C:\Projects\Research\medical\radiomics\rad_val\STUDIES\HN_study\TextureToolbox');


% **************************** INITIALIZATIONS ****************************
clc,clear,fprintf('\n')
timeStartAll = tic;
help masterScript_HN
warning off
cohorts = {'HGJ','HMR','CHUS','CHUM'}; nCohort = numel(cohorts);
featType = {'GTVp','GTVtot'}; nFeatType = numel(featType);

% LOADING VARIABLES
pathWORK = pwd;
clinical = load('clinical'); clinical = struct2cell(clinical); clinical = clinical{1}; % Clinical parameters: Age, T, N, TNM, HPV
load('outcomes'), load('roiNames'), load('timeToEvent'), load('subTypes') % Variables 'outcomes' and 'roiNames' now in the workspace
count = 0;
for i = 1:nCohort
    nPatient.(cohorts{i}) = size(roiNames.(cohorts{i}),1);
    count = count + nPatient.(cohorts{i});
end
nPatient.TOTAL = count;
nameOutcomes = fieldnames(outcomes.(cohorts{1})); 
nOutcomes = numel(nameOutcomes);

% TEXTURE EXTRACTION PARAMETERS AND DEGREES OF FREEDOM
scale_mat = [1,2,3,4,5];
algo_cell = {'Equal','Uniform'};
Ng_mat = [8,16,32,64];
paramSEP = {scale_mat,algo_cell,Ng_mat};
nameSEP = {'Scale','Quant.algo','Ng'};
baselineSEP = [3,2,3];
freedomSEP = [1,1,1];
nonTextName = {'SUVmax','SUVpeak','SUVmean','aucCSH','TLG','PercentInactive','gETU','Volume','Size','Solidity','Eccentricity','Compactness'}; nNonText = numel(nonTextName);
textType = {'Global','GLCM','GLRLM','GLSZM','NGTDM'}; nTextType = numel(textType);
textName = {{'Variance','Skewness','Kurtosis'}, ...
            {'Energy','Contrast','Entropy','Homogeneity','Correlation','SumAverage','Variance','Dissimilarity','AutoCorrelation'}, ...
            {'SRE','LRE','GLN','RLN','RP','LGRE','HGRE','SRLGE','SRHGE','LRLGE','LRHGE','GLV','RLV'}, ...
            {'SZE','LZE','GLN','ZSN','ZP','LGZE','HGZE','SZLGE','SZHGE','LZLGE','LZHGE','GLV','ZSV'}, ...
            {'Coarseness','Contrast','Busyness','Complexity','Strength'}};
nText = 0;
for t = 1:nTextType
    nText = nText + numel(textName{t});
end
        
% MULTIVARIABLE ANALYSIS PARAMETERS
nBoot = 100; % Number of bootstrapping experiments used in models construction
alpha = 0.5; delta = 0.5; setSize = 25; % Feature set reduction parameters. See (Vallières et al., Phys. Med. Biol., 2015) for more details
fSetNames = {'PET','CT','PETCT'}; nFset = numel(fSetNames); % PETCT --> Separate PET and CT radiomic features combined into one set
maxOrder = 10; % Maximum number or radiomics variable combinations
imbalance = 'IALR'; % Imbalance-adjusted logistic regression
tic, fprintf('\n --> INITIALIZATION: FINDING PATH TO "MINE.jar" EXECUTABLE ON THE SYSTEM ... ')
[pathMINE] = findMINE('Windows'); fprintf('DONE!\n'), toc
testCost = 0.5:0.1:2; % Emphasis factor on positive instances during random forest training
testSplit = 1/3; % Proportion of test cases in stratified random sub-sampling splits

% PARALLEL AND RANDOMIZATION OPTIONS
seed =  54288; rng(seed); % For reproducibility of results. A seed chosen with heart, to remind us that it was very close and that we must continue to believe in our dream --> #1995referendum. Replace this line by "rng('shuffle')" to make it completely random. 
seeds = ceil(1000000000*rand(4,1)); % A bootstrapping seed for feature set reduction, feature selection, prediction performance estimation and computation of final regression coefficients
nBatch = 9; % Number of parallel batch to use (3 outcomes * 3 different feature sets)
nBatch_Read = 4; % beware: RAM usage limitations
matlabPATH = 'matlab'; % Full path to the matlab executable on the system. Here, a symbolic link to the full MATLAB path has previously been created on Martin Vallieres' computer.

% DISPLAYING OPTIONS
display = false; % If this is set to true, all figures will be displayed. Setting it to false is useful to run this script in the background from terminal commands; in this case, manually open figures using "openfig('nameFigure.fig','new','visible');" after computation is over.
if ~display
    cd(pathWORK), mkdir('FIGURES'), cd('FIGURES'), pathFig = pwd; cd(pathWORK); % "FIGURES": folder where all figures will be saved
else
    pathFig = '';
end
% -------------------------------------------------------------------------



% *********************************** COMPUTATION OF RADIOMICS FEATURES *************************************
tStart = tic;
fprintf('\n\n************************* COMPUTATION OF RADIOMICS FEATURES *************************')
          
% 1. READ DATA DOWNLOADED FROM THE TCIA WEBSITE (xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)
tic, fprintf('\n--> READING AND PROCESSING DICOM DATA FROM TCIA WEBSITE ON %u CORES ... ',nBatch_Read)
mkdir('DATA'), pathData = fullfile(pathWORK,'DATA'); cd(fullfile(pathWORK,'DICOM'))
readAllDICOM(fullfile(pathWORK,'DICOM'),pathData,nBatch_Read)
fprintf('DONE!\n'), toc
