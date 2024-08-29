%% supfig1_Transient power suppression

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

selectSubj.sub_label = 'sub-REC2Stim03'; %['sub-' input('Patient number (REC2StimXX): ','s')];
selectSubj.ses_label = 'ses-1'; %input('Session number (ses-X): ','s');

%% select Single Pulse Electrical Stimulation (SPES)-data

files = dir(fullfile(myDataPath.dataPath,selectSubj.sub_label,selectSubj.ses_label,'ieeg'));
idx_events = contains({files(:).name},'events.tsv');

files_events = files(idx_events);
run_label = cell(1);
count = 1;

for nFile = 1:size(files_events,1)
    
    eventsName = fullfile(files_events(nFile).folder,files_events(nFile).name);
    tb_events = readtable(eventsName,'FileType','text','Delimiter','\t');

    if any(strcmpi(tb_events.trial_type,'electrical_stimulation') & strcmpi(tb_events.sub_type,'SPESclin'))
        
        run_temp = extractBetween(files_events(nFile).name,'run-','_events');
        run_label{count,1} = ['run-', run_temp{:}];

        count = count+1;
    end
end

selectSubj.run_label = run_label;

% housekeeping
clear count eventsName files files_events idx_events nFile tb_events run_label run_temp

%% load all ECoGs with SPES data

dataBase = load_ECoGdata(myDataPath,selectSubj);

disp('All ECoGs are loaded') 

%% electrodes covering the seizure onset zone

SOZch = {'IH05','IH06','IH13','IH14'}; 
SOZch2 = {'IH5','IH6','IH13','IH14'}; 

if size(find(contains(dataBase(1).ch,SOZch)),1) == size(SOZch,2)
    SOZelec = find(contains(dataBase(1).ch,SOZch));
elseif size(find(contains(dataBase(1).ch,SOZch2)),1) == size(SOZch2,2)
    SOZelec = find(contains(dataBase(1).ch,SOZch2));
else
    error('Not all SOZ electrodes are found.')
end

%% preprocessing CCEP in ECoG
cfg = [];

% sort stimulation pairs
cfg.dir = 'no'; % if you want to take negative/positive stimulation into account
cfg.amp = 'no'; % if you want to take stimulation current into account

% select epochs and average
cfg.epoch_length = 4; % in seconds, -2:2
cfg.epoch_prestim = 2;

dataBase = preprocess_ECoG_ccep(dataBase,cfg);

disp('All ECoGs are preprocessed')

%% rereference data
cfg.reref = 1; % (1 = re-reference, 0 = no re-reference)

tt_postStim = cfg.epoch_prestim*dataBase(1).ccep_header.Fs + 20 : cfg.epoch_length*dataBase(1).ccep_header.Fs; % exclude the first 20 samples after stimulation due to the stimulus artefact

for nRun = 1:size(dataBase,2)
    
    if cfg.reref == 1
        for nStim = 1:size(dataBase(nRun).cc_epoch_sorted,3)
            
            for nTrial = 1:size(dataBase(nRun).cc_epoch_sorted,2)
                
                % find 10 signals with lowest variance (post-Stim) and not being a bad channel or part stimulus pair
                variance = var(squeeze(dataBase(nRun).cc_epoch_sorted(:,nTrial,nStim,tt_postStim)),1,2); % [channels x trials x stimulus pairs x samples]
                [~,idx_var] = sort(variance,'ascend');
                
                idx_var = setdiff(idx_var,[find(strcmp(dataBase(nRun).tb_channels.status,'bad'));dataBase(nRun).cc_stimsets(nStim,:)'],'stable');
                
                ref = median(squeeze(dataBase(nRun).cc_epoch_sorted(idx_var(1:10),nTrial,nStim,:)));
                
                dataBase(nRun).cc_epoch_sorted_reref(:,nTrial,nStim,:) = squeeze(dataBase(nRun).cc_epoch_sorted(:,nTrial,nStim,:)) - ref;
                
            end
        end
    else
        
        dataBase(nRun).cc_epoch_sorted_reref = dataBase(nRun).cc_epoch_sorted;        
    end
    
    dataBase(nRun).cc_epoch_sorted_avg = squeeze(mean(dataBase(nRun).cc_epoch_sorted_reref,2,'omitnan'));
end

disp('All ECoGs are re-referenced')

%% make TF-SPES Event-Related - Stimulus - Perturbations
close all
cfg.saveERSP = 'yes';

dataBase = makeTFSPES(dataBase,cfg, myDataPath);

%% or load previously made TFSPES plots

for nRun = 1:size(dataBase,2)

    files = dir(fullfile(myDataPath.dataPath,'derivatives','TFSPES_orig',dataBase(1).sub_label, ...
        dataBase(1).ses_label,'orig_tijdensIEMU',[dataBase(nRun).run_label{nRun},'_noreref']));

    idx = contains({files(:).name},'.mat');
    tmp = load(fullfile(files(idx).folder, files(idx).name));

    dataBase(nRun).ERSP = tmp;
    clear tmp
    
end

%%

close all

%  stimp = [7 8];
% stimp = [9 10];
% stimp = [15 16];
% stimp = [41 42]; %C25-26
stimp = [23 24]; %C7-8
% chan = 5;
% chan = 6;
% chan = 13;
chan = 14;

for nRun = 1:size(dataBase,2)

    if any(ismember(dataBase(nRun).cc_stimsets,stimp,'rows'))
        idx = find(ismember(dataBase(nRun).cc_stimsets,stimp,'rows'));
        plot_ERSP(dataBase(nRun).ERSP,idx,chan)

        figureName = sprintf('%sERSP_%s_Stimp%s-%s_resp%s',myDataPath.Figures, ...
            dataBase(nRun).sub_label,dataBase(nRun).ch{stimp(1)}, ...
            dataBase(nRun).ch{stimp(2)},dataBase(nRun).ch{chan});

        set(gcf,'PaperPositionMode','auto')
        print('-dpng','-r300',figureName)
        print('-vector','-depsc',figureName)

        fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

        break
    end
end
