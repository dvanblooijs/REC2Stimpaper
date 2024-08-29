
%% THIS IS AN EXAMPLE FILE
% copy this one and fill in your own

function localDataPath = PRIOS_personalDataPath_example(varargin)

% function that contains local data path, is ignored in .gitignore
localDataPath.elec_input = '/folder/to/electrodes/excels/Metadata/Electrodes/';
localDataPath.CCEPpath = '/folder/to/location/to/save/derivatives/PRIOSstudy/'; 
localDataPath.dataPath = '/folder/with/bidsdata/PRIOSstudy/';
localDataPath.CCEP_allpat = '/folder/to/location/to/save/derivatives/CCEP_files_allPat/' ;
localDataPath.CCEP_interObVar = '/folder/to/location/with/interobserver/data/';

% set paths
fieldtrip_folder  = '/folder/to/gitrepository/fieldtrip/';
fieldtrip_private = '/folder/to/gitrepository/fieldtrip_private/';
jsonlab_folder    = '/folder/to/gitrepository/jsonlab/';
violin_folder     = '/folder/to/gitrepository/external/Violinplot-Matlab/';
addpath(violin_folder)
addpath(fieldtrip_folder)
addpath(fieldtrip_private)
addpath(jsonlab_folder)
ft_defaults

% Remove paths (remove retrospective folder because filenames are matching)
warning('off','all');
rmpath(genpath('/folder/to/gitrepository/external/signal')) % to avoid usage of fieldtrip butter and filtfilt instead matlab functions
warning('on','all');

end
