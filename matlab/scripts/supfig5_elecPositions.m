%% display electrode positions of two sessions
% date: November 2020

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


%% patient characteristics

cfg.sub_label = ['sub-' input('Patient number (REC2StimXX): ','s')];

%%
close all

cfg.show_labels = 'no';
cfg.save_fig = 'yes'; % saves rendering in derivatives

% session = {'ses-1'};
% renderBrainwElecs(myDataPath,cfg,session)
session = {'ses-2'};
renderBrainwElecs(myDataPath,cfg,session)
session = {'ses-1','ses-2'};
renderBrainwElecs(myDataPath,cfg,session)

