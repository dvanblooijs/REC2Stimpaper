%% RECStim01_prepSzFreq

% in this script, both log file from Activa PC+S and seizure diary from
% Castor are combined to enable evaluation of the seizure frequency in
% time, and the performance of the detector

% author: Dorien van Blooijs, 2023

close all
clear;
clc;

%% set paths

% add current path from folder which contains this script
rootPath = matlab.desktop.editor.getActiveFilename;
RepoPath = fileparts(rootPath);
matlabFolder = strfind(RepoPath,'matlab');
addpath(genpath(RepoPath(1:matlabFolder+6)));

myDataPath = REC2Stim_setLocalDataPath(1);

% housekeeping
clear rootPath RepoPath matlabFolder

cmap = parula(10);

%% patient settings

cfg(1).sub_label = ['sub-' input('Patient number (REC2StimXX): ','s')];
cfg(1).ses_label = 'ses-2'; %input('Session number (ses-X): ','s');

% define period of which we would like to analyze events
cfgtemp = config_period(cfg(1).sub_label);
cfg = merge_fields(cfg,cfgtemp);

% housekeeping 
clear cfgtemp

%% load visits
tic
dataBase = loadVisits(myDataPath,cfg);
toc

%% load and preprocess log-files per visit of specific patient --> duration ~1min

tic
dataBase = loadPreprocessLogFiles(myDataPath,dataBase);
toc

disp('Preprocessed log-files')

%% load and preprocess rec-files per visit of specific patient --> duration ~1min

tic
dataBase = loadPreprocessRecFiles(myDataPath,dataBase);
toc

disp('Preprocessed rec-files')

%% convert INS time in recordings to SP time

tic
dataBase = convertINStime2SPtime(dataBase);
toc

disp('Converted INS time to SP time in all recordings')

%% load and preprocess seizure diary exported from Castor of specific patient

szReport = loadPreprocessSzDiary(myDataPath,cfg);

disp('Preprocessed Castor file')

%% check for double seizures from logbook and recordings

% for each visit
% type: PatientMarker / Detection
tic
type = 'PatientMarker';
dataBase = combineEvents(dataBase,szReport,type);
disp('Combined seizures')
toc

tic
type = 'Detection';
dataBase = combineEvents(dataBase,szReport,type);
disp('Combined detections')
toc

%% run fig2_SzFreq to plot seizure frequency in time

%% run supfig6_LDAperformance to plot performance of LDA with each visit









