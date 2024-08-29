%% supfig1_CCEPs 

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

%% detect N1 peaks

cfg.amplitude_thresh = 2.6;
cfg.n1_peak_range = 100;

[dataBase] = detect_n1peak_ECoG_ccep(dataBase, cfg);

%% load visual checks

for nRun = 1:size(selectSubj.run_label,1)
    filename = fullfile(myDataPath.dataPath,'derivatives','CCEP', ...
        selectSubj.sub_label,selectSubj.ses_label,selectSubj.run_label{nRun});

    files = dir(filename);
    idx = contains({files(:).name},'.mat');

    if sum(idx) == 1
        tmp = load(fullfile(files(idx).folder,files(idx).name));
        dataBase(nRun).ccep = tmp.ccep;
        clear tmp
    else
        disp('determine what to do in case more .mat files are present')
    end
end

%% make adjacency matrix by concatenating all runs

close all

Amat = dataBase(1).ccep.checked;
Amat = [Amat, zeros(size(dataBase(1).ch,1),1)];
cc_stimsets = dataBase(1).ccep.cc_stimsets;

for nRun = 2:size(dataBase,2)
    if isequal(dataBase(nRun).ccep.ch, dataBase(1).ccep.ch)
        for nStim = 1:size(dataBase(nRun).ccep.cc_stimsets,1)
            if any(ismember(cc_stimsets,dataBase(nRun).ccep.cc_stimsets(nStim,:),'rows'))

                idx = ismember(cc_stimsets,dataBase(nRun).ccep.cc_stimsets(nStim,:),'rows');

                tmp1 = Amat(:,idx);
                tmp2 = dataBase(nRun).ccep.checked(:,nStim);

                Amat(:,idx) = tmp1 == 1 | tmp2 == 1;
            
            else
                Amat = [Amat, dataBase(nRun).ccep.checked(:,nStim)];
                cc_stimsets = [cc_stimsets; dataBase(nRun).ccep.cc_stimsets(nStim,:)];

            end
        end
    end
end

% change Amat value to NaN if response channel = stimulus channel
for nStim = 1:size(Amat,2)
    Amat(cc_stimsets(nStim,1),nStim) = 2;
    Amat(cc_stimsets(nStim,2),nStim) = 2;
end

% find channel names for each stimulus pair
cc_stimLabels = cell(size(cc_stimsets,1),1);
for nStim = 1:size(cc_stimsets,1)
    cc_stimLabels{nStim} = [dataBase(1).ch{cc_stimsets(nStim,1)} '-' dataBase(1).ch{cc_stimsets(nStim,2)}];
end

% make figure
figure("Units","normalized","Position",[0.02 0 0.98 0.89]),
imagesc(Amat)

ax = gca;
ax.XLabel.String = 'Stimulus pairs';
ax.XTick = 1:size(Amat,2);
ax.XTickLabel = cc_stimLabels;
ax.YLabel.String = 'Response channels';
ax.YTick = 1:size(Amat,1);
ax.YTickLabel = dataBase(1).ch;
ax.XTickLabelRotation = 90;

figureName = sprintf('%ssupFig1_Amat_%s',myDataPath.Figures,selectSubj.sub_label);

set(gcf,'PaperPositionMode','auto')
print('-dpng','-r300',figureName)
print('-vector','-depsc',figureName)

fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

%% supplementary figure 1A
close all

% visualize CCEPs in SOZ when stimulating these stimulation pairs:
stimPairs{1} = {'IH07','IH08'};
stimPairs{2} = {'IH15','IH16'};
stimPairs{3} = {'IH09','IH10'};
stimPairs{4} = {'C25','C26'};
ystep = 500;

for nStim = 1:size(stimPairs,2)

    signal = NaN(size(dataBase,2),size(SOZelec,1),size(dataBase(1).cc_epoch_sorted_avg,3));
    ccep = NaN(size(dataBase,2),size(SOZelec,1));

    for nDataBase = 1:size(dataBase,2)
        if any((contains(dataBase(nDataBase).cc_stimchans(:,1),stimPairs{nStim}{1}) & ...
                contains(dataBase(nDataBase).cc_stimchans(:,2),stimPairs{nStim}{2})) | ...
                (contains(dataBase(nDataBase).cc_stimchans(:,1),stimPairs{nStim}{2}) & ...
                contains(dataBase(nDataBase).cc_stimchans(:,2),stimPairs{nStim}{1})))

            idxStim = find((contains(dataBase(nDataBase).cc_stimchans(:,1),stimPairs{nStim}{1}) & ...
                contains(dataBase(nDataBase).cc_stimchans(:,2),stimPairs{nStim}{2})) | ...
                (contains(dataBase(nDataBase).cc_stimchans(:,1),stimPairs{nStim}{2}) & ...
                contains(dataBase(nDataBase).cc_stimchans(:,2),stimPairs{nStim}{1})));

            signal(nDataBase,:,:) = squeeze(dataBase(nDataBase).cc_epoch_sorted_avg(SOZelec,idxStim,:));
            ccep(nDataBase,:) = dataBase(nDataBase).ccep.n1_peak_sample(SOZelec,idxStim);
 
        end
    end

    % average signal
    signal_avg = squeeze(mean(signal,1,"omitnan"));
    ccep_avg = mean(ccep,1,'omitnan');
    fs = dataBase(1).ccep_header.Fs;
    tt = -1*cfg.epoch_prestim:1/fs: cfg.epoch_length-cfg.epoch_prestim-1/fs;
%     ystep = ceil(max(max(signal_avg,[],2) - min(signal_avg,[],2))/100)*100;
    tt0 = find(tt >0,1,'first');

    figure(nStim), 
    plot(tt,(1:ystep:size(SOZch,2)*ystep)+signal_avg','k')
    hold on
    fill([tt(tt0), tt(tt0+19), tt(tt0+19), tt(tt0)],[-2000 -2000 2000 2000],[0.5 0.5 0.5],'FaceColor',[0.5 0.5 0.5],'EdgeColor','none','FaceAlpha',0.5)
    for nCCEP = 1:size(SOZch,2)
        if ~isnan(ccep_avg(nCCEP))
            plot(tt(ccep_avg(nCCEP)),((nCCEP-1)*ystep)+signal_avg(nCCEP,ccep_avg(nCCEP))','ko','MarkerFaceColor','k')
        end
    end
    hold off
    xlim([-0.5 1])
    ylim([-ystep  size(SOZch,2)*ystep])
    xlabel('Time (s)')
    ylabel('Amplitude (uV)')
    title(sprintf('Stimulus pair: %s-%s',stimPairs{nStim}{1},stimPairs{nStim}{2}))
    ax = gca;
    ax.YTickLabel = horzcat({' '},SOZch,{' '});

    figureName = sprintf('%ssupFig1_CCEP_%s_%s-%s',myDataPath.Figures,selectSubj.sub_label,stimPairs{nStim}{1},stimPairs{nStim}{2});

    set(gcf,'PaperPositionMode','auto')
    print('-dpng','-r300',figureName)
    print('-vector','-depsc',figureName)

    fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

end