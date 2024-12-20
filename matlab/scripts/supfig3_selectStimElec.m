% determine electrodes with best stimuluation parameters

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

%% find ECoGs with stimulation tests

files = dir(fullfile(myDataPath.dataPath,selectSubj.sub_label,selectSubj.ses_label,'ieeg'));
idx_events = contains({files(:).name},'events.tsv');

files_events = files(idx_events);
run_label = cell(1);
count = 1;

for nFile = 1:size(files_events,1)

    eventsName = fullfile(files_events(nFile).folder,files_events(nFile).name);
    tb_events = readtable(eventsName,'FileType','text','Delimiter','\t');

    if any(strcmpi(tb_events.trial_type,'electrical_stimulation')) && any(strcmpi(tb_events.sub_type,'REC2Stim'))

        run_temp = extractBetween(files_events(nFile).name,'run-','_events');
        run_label{count,1} = ['run-', run_temp{:}];

        count = count+1;
    end
end

selectSubj.run_label = run_label;

disp('ECoGs are selected')

% housekeeping
clear count eventsName files files_events idx_events nFile tb_events run_label run_temp

%% load all ECoGs with at least one stimulation test

dataBase = load_ECoGdata(myDataPath,selectSubj);

disp('All ECoGs are loaded')

%% rereferencing with common average

SOZelec = {'IH05','IH06','IH13','IH14'};
SOZelec2 = {'IH5','IH6','IH13','IH14'};

for nFile = 1:size(dataBase,2)

    idx_SOZch = contains(dataBase(nFile).ch,SOZelec);
    if sum(idx_SOZch) < size(SOZelec,2)
        idx_SOZch = contains(dataBase(nFile).ch,SOZelec2);
    end

    if sum(idx_SOZch) < size(SOZelec,2)
        error('Not all channels are found in channel list for ECoG file %d',n)
    end

    idx_good = strcmpi(dataBase(nFile).tb_channels.type,'ecog') & ...
        strcmpi(dataBase(nFile).tb_channels.status_description,'included');

    idx_incl = contains(dataBase(nFile).ch, dataBase(nFile).tb_channels.name(idx_good));

    avg = mean(dataBase(nFile).data(idx_incl,:));

    dataBase(nFile).dataReref = dataBase(nFile).data(idx_SOZch,:)- avg;

end

disp('Re-referencing is performed')

% housekeeping
clear avg idx_good idx_incl nFile

%% especially with 2 and 7 Hz, all separate stimuli are annotated. So we
% need to cluster these to determine epochs

for nFile = 1:size(dataBase,2)

    fs = dataBase(nFile).ccep_header.Fs;
    tb_events = dataBase(nFile).tb_events;
    tb_stim = tb_events(strcmp(tb_events.sub_type,'REC2Stim') & strcmp(tb_events.trial_type,'electrical_stimulation'),:);

    tb_stimClust = tb_stim(1,:);
    count = 1;

    % find which stimuli are more than 15s after each other
    idx = diff(tb_stim.sample_start) > 15*fs;

    for nStim = 1:size(tb_stim,1)-1
        if idx(nStim) == 1
            tb_stimClust.offset(count) = tb_stim.offset(nStim);
            tb_stimClust.sample_end(count) = tb_stim.sample_end(nStim);
            tb_stimClust.duration(count) = tb_stimClust.offset(count) - tb_stimClust.onset(count);

            count = count+1;
            tb_stimClust(count,:) = tb_stim(nStim+1,:);
        end
    end
    tb_stimClust.offset(count) = tb_stim.offset(end);
    tb_stimClust.sample_end(count) = tb_stim.sample_end(end);
    tb_stimClust.duration(count) = tb_stimClust.offset(count) - tb_stimClust.onset(count);

    dataBase(nFile).tb_stimClust = tb_stimClust;

end

disp('Cluster stimuli is performed')

% housekeeping
clear count idx nFile nStim tb_events tb_stim tb_stimClust

%% remove stimulus artefact
% the value 10 samples before and 30 samples after stimulation are
% averaged. This value is given to the samples from the start of
% stimulation until 20 samples after stimulation.

for nFile = 1:size(dataBase,2)

    data = dataBase(nFile).dataReref;
    tb_stimClust = dataBase(nFile).tb_stimClust;

    sampStart = floor(tb_stimClust.sample_start);
    sampStop = ceil(tb_stimClust.sample_end);

    for nStim = 1:size(sampStart,1)

        data(:,sampStart(nStim):sampStop(nStim)+20) = repmat(mean(...
            [data(:,sampStart(nStim)-10) data(:,sampStop(nStim)+30)],2),...
            1,sampStop(nStim)-sampStart(nStim)+21);

    end

    dataBase(nFile).dataStimRem = data;
end

SOZch = find(idx_SOZch ==1);
n = 1;

nFile = 1;
time = 1/fs:1/fs:size(dataBase(nFile).data,2)/fs;
figure,
plot(time,dataBase(nFile).data(SOZch(n),:))
hold on
plot(time,dataBase(nFile).dataReref(n,:))
plot(time,dataBase(nFile).dataStimRem(n,:))
hold off
legend('raw data', 'rereferenced data', 'w/h stim artefact')

disp('Stimulus artefact is removed')

% housekeeping
clear tb_stimClust data idx_SOZch n nFile nStim sampStart sampStop SOZelec SOZelec2 time

%% combine all stimulus parameters

stimParAll = cell(size(dataBase,2),1);
size_tbStim = NaN(size(dataBase,2),1);

for nFile = 1:size(dataBase,2)

    tb_stimClust = dataBase(nFile).tb_stimClust;
    size_tbStim(nFile) = size(tb_stimClust,1);

    stimPar = cell(size(tb_stimClust,1),1);
    if iscell(tb_stimClust.electrical_stimulation_current)
        for nStim = 1:size(tb_stimClust,1)
            stimPar{nStim} = [tb_stimClust.electrical_stimulation_site{nStim}, '_', ...
                tb_stimClust.electrical_stimulation_current{nStim}, '_', ...
                tb_stimClust.electrical_stimulation_frequency{nStim}];
        end
    else
        for nStim = 1:size(tb_stimClust,1)
            stimPar{nStim} = [tb_stimClust.electrical_stimulation_site{nStim}, '_', ...
                num2str(tb_stimClust.electrical_stimulation_current(nStim)), '_', ...
                num2str(tb_stimClust.electrical_stimulation_frequency(nStim))];
        end
    end

    stimParAll{nFile,1} = stimPar;
    stimParAll{nFile,2} = num2cell(nFile * ones(size(stimPar)));
    stimParAll{nFile,3} = num2cell(permute(1:size(stimPar,1) * ones(size(stimPar)),[2 1]));
end

stimParAll = [vertcat(stimParAll{:,1}), vertcat(stimParAll{:,2}), vertcat(stimParAll{:,3})];
[uniquestimPar,~,IC] = unique(stimParAll(:,1));
nIC = histcounts(IC,'BinMethod','integers');

disp('All stimulus parameters are combined')

% housekeeping
clear stimPar nFile nStim size_tbStim tb_stimClust

%% convert stim parameters cell to doubles
stimParSet = NaN(size(uniquestimPar,1),5);

for nStim = 1: size(uniquestimPar,1)
    splitStim = split(uniquestimPar{nStim},'_');
    stimChan = split(splitStim{1},'-');

    for nChan = 1:2
        stimParSet(nStim,nChan) = find(contains(dataBase(1).ch, stimChan{nChan}) == 1);
    end

    stimParSet(nStim,3) = str2double(splitStim{2});
    stimParSet(nStim,4) = str2double(splitStim(3));
end

%% make epochs

% pre-allocation
preStim = 45; % epoch period before stimulus
postStim = 45; % epoch period after stimulus
freqs = [4 7; 8 14; 15 25; 26 40; 65 95];
power_preStim = NaN(size(SOZch,1),size(uniquestimPar,1),max(nIC),size(freqs,1),10*fs+1); % [SOZ channels (4) x stimulus pairs (50) x trials (11) x freqbans (5) x samples (10s)]
power_postStim = NaN(size(SOZch,1),size(uniquestimPar,1),max(nIC),size(freqs,1),10*fs+1); % [SOZ channels (4) x stimulus pairs (50) x trials (11) x freqbans (5) x samples (10s)]

for nStim = 1:size(uniquestimPar,1)
    idx = find(IC==nStim);

    % if there are at least 9 stimuli with these parameters
    if size(idx,1) >= 9
        disp(stimParAll{idx(1)})

        for nTrial = 1:size(idx,1)

            stimFile = stimParAll{idx(nTrial),2};
            stimTrial = stimParAll{idx(nTrial),3};
            sampstart = dataBase(stimFile).tb_stimClust.sample_start(stimTrial);
            sampstop = round(dataBase(stimFile).tb_stimClust.sample_end(stimTrial));

            % if the part of the file after the stimulus is less than 45 s
            if sampstart + postStim*fs < size(dataBase(stimFile).dataStimRem,2) && ...
                    sampstart - preStim*fs > 0

                signal_temp = dataBase(stimFile).dataStimRem(:,sampstart-preStim*fs:sampstart+postStim*fs);
                signal = signal_temp';

                % filter parameters om 50Hz eruit te filteren
                analysis_params.hpfreq=[];
                analysis_params.lpfreq=[];
                analysis_params.notchhpfreq = 47;
                analysis_params.notchlpfreq = 53;
                analysis_params.sample_rate = fs;

                % filteren van signaal
                signalFilt = filter_signal(signal, analysis_params, 1); % signal must be [samples x chans]

                % filter parameters om 100Hz eruit te filteren
                analysis_params.notchhpfreq = 97;
                analysis_params.notchlpfreq = 103;

                % filteren van signaal
                signalFilt2 = filter_signal(signalFilt, analysis_params, 1);

                % gabor filter parameters
                params.sample_rate = fs;
                params.W = 4;
                params.spectra = 1:100;

                % amplitudes van re-referenced signalen op verschillende frequenties [time x electrodes x frequencies]
                gabor = jun_gabor_cov_fitted(signalFilt2',params,'amp',1,1).^2; % quadratic(.^2) = power
                gabor_logcortemp = gabor./repmat(mean(gabor,1),[size(gabor,1) 1 1]); %[samples (184321) x SOZchannels (4) x frequencies (100)]
                gabor_logcor = permute(gabor_logcortemp,[2,1,3]); % [sozChannels (4) x samples(184321) x frequencies (100)]

                % extract power 10s before and 10s after stimulation in
                % specific frequency band (4-7Hz for example)
                for nFreqs = 1:size(freqs,1)
                    power_preStim(:,nStim,nTrial,nFreqs,:) = mean(gabor_logcor(:,...
                        preStim*fs-11*fs:preStim*fs-1*fs,...
                        freqs(nFreqs,1):freqs(nFreqs,2)),3); % [samples (20481) x SOZchannels (4) x frequencies (4-7Hz)]
                    power_postStim(:,nStim,nTrial,nFreqs,:) = mean(gabor_logcor(:,...
                        sampstop-sampstart+preStim*fs+1*fs:sampstop-sampstart+preStim*fs+11*fs,...
                        freqs(nFreqs,1):freqs(nFreqs,2)),3); % [samples (20481) x SOZchannels (4) x frequencies (4-7Hz)]
                end

                fprintf('stimPair %s, trial %d has run \n', uniquestimPar{nStim,1},nTrial)

            else % when epoch starts before start of file, or ends after end of file
                % don't include this epoch
            end
        end
    else
        % do nothing because it is not a train of at least 9 stimuli of
        % one specific stimulus parameter set
    end
end

% remove all stimPairs that do not have a train of 9 stimuli
idx = ~isnan(power_preStim(1,:,5,1,1));
uniquestimPar = uniquestimPar(idx,:);
power_preStim = power_preStim(:,idx,:,:,:);
power_postStim = power_postStim(:,idx,:,:,:);
stimParSet = stimParSet(idx,:);

disp('The data is epoched and power calculated')

% housekeeping
clear analysis_params gabor gabor_logcor gabor_logcortemp idx nFreqs
clear nIC nStim nTrial params sampstart sampstop signal signal_temp
clear signalFilt signalFilt2 stimFile stimTrial

%% statistics - wilcoxon signed rank test

p = NaN(size(power_preStim,2),size(power_preStim,4)); %[stimulus pairs (30) x frequency bands (5)]

for nStim = 1:size(power_preStim,2)
    for nFreq = 1:size(freqs,1)
        power_pre = median(squeeze(power_preStim(:,nStim,:,nFreq,:)),3,'omitnan'); % median of all samples --> [soz electrodes (4) x trials (11)]
        power_post = median(squeeze(power_postStim(:,nStim,:,nFreq,:)),3,'omitnan'); % median of all samples --> [soz electrodes (4) x trials (11)]

%         power_diff = power_post(:)-power_pre(:);
        %         [~,p_temp] = ttest(power_pre(:),power_post(:));
        [p_temp] = signrank([power_post(:)],[power_pre(:)]);
        p(nStim,nFreq) = p_temp;
    end
end

% housekeeping
clear p_temp h nStim nFreq power_pre power_post

%% FDR correction
pAll = p(~isnan(p(:,1)),:);

pFDR = 0.05;

[pSort,pInd] = sort(pAll(:));

m = size(pAll(:),1);
thisVal = NaN(size(pSort));
for kk = 1:length(pSort)
    thisVal(kk) = (kk/m)*pFDR;
end

pSig = pAll;
pSig(pInd) = pSort < thisVal;

% housekeeping
clear pSort pInd m thisVal kk

%% Wilcoxon signed rank test 
% visualized with lines connecting power pre- and post-stimulation

close all

for nStim = 1:size(power_preStim,2)

    figure(nStim)
    hold on
    for nFreq = 1:size(freqs,1)

            prePowIndiv = median(squeeze(power_preStim(:,nStim,:,nFreq,:)),3,'omitnan'); %[soz elec (4) x trials (11)]
            postPowIndiv = median(squeeze(power_postStim(:,nStim,:,nFreq,:)),3,'omitnan');

            for nChan = 1:size(prePowIndiv,1)

                plot(transpose(ones(size(prePowIndiv,2),1)*[nFreq-0.2,nFreq+0.2]), [prePowIndiv(nChan,:); ...
                    postPowIndiv(nChan,:)],'color','b')
            end

        plot([nFreq-0.2,nFreq+0.2], [median(prePowIndiv(:),'omitnan'); ...
            median(postPowIndiv(:),'omitnan')],'color','k','LineWidth',2)
    end

    ymax = ceil(max([reshape(median(squeeze(power_preStim(:,nStim,:,:,:)),4,'omitnan'),[],1);...
        reshape(median(squeeze(power_postStim(:,nStim,:,:,:)),4,'omitnan'),[],1)]));
    ylim([0 1.1*ymax])

    for nFreq = 1:size(pSig,2)
        if pSig(nStim,nFreq) == 1
            if pAll(nStim,nFreq) < 0.001
                text(nFreq,ymax,'***','HorizontalAlignment','center')
            elseif pAll(nStim,nFreq) < 0.01
                text(nFreq,ymax,'**','HorizontalAlignment','center')
            elseif pAll(nStim,nFreq) < 0.05
                text(nFreq,ymax,'*','HorizontalAlignment','center')
            end
        else
            if pAll(nStim,nFreq) < 0.001
                text(nFreq,ymax,'***','HorizontalAlignment','center','Color',[169, 169, 169]/256)
            elseif pAll(nStim,nFreq) < 0.01
                text(nFreq,ymax,'**','HorizontalAlignment','center','Color',[169, 169, 169]/256)
            elseif pAll(nStim,nFreq) < 0.05
                text(nFreq,ymax,'*','HorizontalAlignment','center','Color',[169, 169, 169]/256)
            end
        end
    end
    hold off

    ax = gca;
    ax.XTick = 0:nFreq+1;
    ax.XTickLabel = {'','4-7Hz','8-14Hz','15-25Hz','26-40Hz','65-95Hz',''};
    ax.XLabel.String = 'Frequency bands';
    ax.YLabel.String = 'Power';

    stimParset = split(uniquestimPar{nStim},'_');
    title(sprintf('%s, %d mA, %s Hz',...
        stimParset{1},str2double(stimParset{2})*1000,stimParset{3}))

    figureName = sprintf('%ssupfig3_stimSet%s',myDataPath.Figures,replace(uniquestimPar{nStim},'.',''));

    set(gcf,'PaperPositionMode','auto')
    print('-dpng','-r300',figureName)
    print('-vector','-depsc',figureName)

    fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

end

%% summarize all stimulus parameters

uniqueStimChans = unique(sort(stimParSet(:,[1,2]),2),'rows');

% make a figure for each stimulus pair, summarizing all parameters
% (stimulus frequencies)
for nStim = 1:size(uniqueStimChans,1)

    % find stimulation sets in which the specified stimulus pair is
    % stimulated
    idx = find((stimParSet(:,1)== uniqueStimChans(nStim,1) & stimParSet(:,2) == uniqueStimChans(nStim,2)) | ...
        (stimParSet(:,2) == uniqueStimChans(nStim,1) & stimParSet(:,1) == uniqueStimChans(nStim,2)));
    
    summarizeStimPart = NaN(size(idx,1),size(freqs,1));

    for n = 1:size(idx,1)
        for nFreq = 1:size(freqs,1)
            summarizeStimPart(n,nFreq) = median(reshape(median(power_postStim(:,idx(n),:,nFreq,:),5,'omitnan'),[],1) - ...
                reshape(median(power_preStim(:,idx(n),:,nFreq,:),5,'omitnan'),[],1),'omitnan' );
        end
    end
    
    stimParSetPart = stimParSet(idx,:);
    pAllPart = pAll(idx,:);

    % reorder based on stimulus frequency
    [~,I] = sort(stimParSetPart(:,4));

    yTickLabels = cell(size(I));
    for n = 1:size(I,1)
        %     yTickLabels{n} = [num2str(stimParSetPart(I(n),3)*1000), ' mA, ' num2str(stimParSetPart(I(n),4)), ' Hz'];
        yTickLabels{n} = [num2str(stimParSetPart(I(n),4)), ' Hz'];
    end

    [rrr,ccc] = find((pAllPart(I,:)<0.001));
    [rr,cc] = find((pAllPart(I,:)<0.01));
    [r,c] = find((pAllPart(I,:)<0.05));

    colorMin = - round(max([0-min(summarizeStimPart(:)); max(summarizeStimPart(:))-0]),1);
    colorMax = round(max([0-min(summarizeStimPart(:)); max(summarizeStimPart(:))-0]),1);

    figure(30+nStim),
    imagesc(summarizeStimPart(I,:),[colorMin colorMax])
    hold on,
    plot(c,r,'ok','MarkerSize',3,'MarkerFaceColor','k','MarkerEdgeColor','w')
    plot(cc,rr,'ok','MarkerSize',6,'MarkerFaceColor','k','MarkerEdgeColor','w')
    plot(ccc,rrr,'ok','MarkerSize',9,'MarkerFaceColor','k','MarkerEdgeColor','w')
    hold off
    colorbar

    colormap(turbo);

    ax = gca;
    ax.XTick = 1:5;
    ax.XTickLabel = {'4-7Hz','8-14Hz','15-25Hz','26-40Hz','65-95Hz'};
    ax.XLabel.String = 'Frequency bands';
    ax.YTick = 1.5:2:9.5;
    ax.YTickLabel = yTickLabels(1:2:end);
    ax.YLabel.String = 'Stimulus frequency';
    title(sprintf('%s-%s' ,dataBase(1).ch{uniqueStimChans(nStim,1)},dataBase(1).ch{uniqueStimChans(nStim,2)}))

    figureName = sprintf('%ssupfig3b_stimSet%s-%s',myDataPath.Figures,...
        dataBase(1).ch{uniqueStimChans(nStim,1)},dataBase(1).ch{uniqueStimChans(nStim,2)});

    set(gcf,'PaperPositionMode','auto')
    print('-dpng','-r300',figureName)
    print('-vector','-depsc',figureName)

    fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

end

%% old code %%

%% figure - boxplots pre- and post-stimulation power

namesPre = cell(size(squeeze(power_preStim(:,1,:,:,1)))); % [soz elec x trials x frequency bands]
[namesPre{:,:,1}] = deal('freq1_prestim');
[namesPre{:,:,2}] = deal('freq2_prestim');
[namesPre{:,:,3}] = deal('freq3_prestim');
[namesPre{:,:,4}] = deal('freq4_prestim');
[namesPre{:,:,5}] = deal('freq5_prestim');
namesPreAll = namesPre(:);
namesPost = cell(size(squeeze(power_postStim(:,1,:,:,1))));
[namesPost{:,:,1}] = deal('freq1_poststim');
[namesPost{:,:,2}] = deal('freq2_poststim');
[namesPost{:,:,3}] = deal('freq3_poststim');
[namesPost{:,:,4}] = deal('freq4_poststim');
[namesPost{:,:,5}] = deal('freq5_poststim');
namesPostAll = namesPost(:);

namesAll = vertcat(namesPreAll,namesPostAll);
summarizeStim = NaN(size(power_preStim,2),size(freqs,1));

for nStim = 1:size(power_preStim,2)

    prePowIndiv = median(squeeze(power_preStim(:,nStim,:,:,:)),4,'omitnan'); %[soz elec (4) x trials (11) x frequency bands (5)]
    prePowIndivvec = prePowIndiv(:);
    postPowIndiv = median(squeeze(power_postStim(:,nStim,:,:,:)),4,'omitnan');
    postPowIndivvec = postPowIndiv(:);

    powIndivvec = [prePowIndivvec; postPowIndivvec];

    for nFreqs = 1:size(pSig,2)
        
        summarizeStim(nStim,nFreqs) = median(reshape(prePowIndiv(:,:,nFreqs),[],1) -...
            reshape(postPowIndiv(:,:,nFreqs),[],1),'omitnan');

    end

    figure(nStim);
    boxplot(powIndivvec,namesAll, 'PlotStyle','compact','Colors','br', ...
        'GroupOrder',{'freq1_prestim','freq1_poststim','freq2_prestim', ...
        'freq2_poststim','freq3_prestim','freq3_poststim','freq4_prestim', ...
        'freq4_poststim','freq5_prestim','freq5_poststim'})

    ymax = ceil(max(powIndivvec));
    ylim([0 1.1*ymax])

    hold on
    plot(repmat(2.5:2:12,2,1),[0 1.1*ymax],'k:')

    for nFreq = 1:size(pSig,2)
        if pSig(nStim,nFreq) == 1
            if pAll(nStim,nFreq) < 0.001
                text(nFreq*2-0.5,ymax,'***','HorizontalAlignment','center')
            elseif pAll(nStim,nFreq) < 0.01
                text(nFreq*2-0.5,ymax,'**','HorizontalAlignment','center')
            elseif pAll(nStim,nFreq) < 0.05
                text(nFreq*2-0.5,ymax,'*','HorizontalAlignment','center')
            end
        else
            if pAll(nStim,nFreq) < 0.001
                text(nFreq*2-0.5,ymax,'***','HorizontalAlignment','center','Color',[169, 169, 169]/256)
            elseif pAll(nStim,nFreq) < 0.01
                text(nFreq*2-0.5,ymax,'**','HorizontalAlignment','center','Color',[169, 169, 169]/256)
            elseif pAll(nStim,nFreq) < 0.05
                text(nFreq*2-0.5,ymax,'*','HorizontalAlignment','center','Color',[169, 169, 169]/256)
            end
        end
    end
    hold off

    ax = gca;
    ax.XTick = 1.5:2:12;
    ax.XTickLabel = {'4-7Hz','8-14Hz','15-25Hz','26-40Hz','65-95Hz'};
    ax.XLabel.String = 'Frequency bands';
    ax.YLabel.String = 'Power';

    stimParset = split(uniquestimPar{nStim},'_');
    title(sprintf('%s, %d mA, %s Hz',...
        stimParset{1},str2double(stimParset{2})*1000,stimParset{3}))

    figureName = sprintf('%ssupfig3_stimSet%s',myDataPath.Figures,uniquestimPar{nStim});

    set(gcf,'PaperPositionMode','auto')
    print('-dpng','-r300',figureName)
    print('-vector','-depsc',figureName)

    fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

end

% housekeeping
clear ax h IA IC idx kk m namesAll namesPost namesPostAll namesPre namesPreAll
clear figureName stimParset postPowIndiv postPowIndivvec powIndivvec
clear prePowIndiv prePowIndivvec ymax nFreq nStim

%% nog een x statistiek met IH1-2 en IH2-1 samen genomen. --> geen succes!

% convert stim parameters to doubles
stimParSet = NaN(size(uniquestimPar,1),5);

for nStim = 1: size(uniquestimPar,1)
    splitStim = split(uniquestimPar{nStim},'_');
    stimChan = split(splitStim{1},'-');

    for nChan = 1:2
        stimParSet(nStim,nChan) = find(contains(dataBase(1).ch, stimChan{nChan}) == 1);
    end

    stimParSet(nStim,3) = str2double(splitStim{2});
    stimParSet(nStim,4) = str2double(splitStim(3));
end

pComb = NaN(size(power_preStim,2),size(power_preStim,4)); %[stimulus pairs (30) x frequency bands (5)]

for nStim = 1:size(uniquestimPar,1)

    if isnan(stimParSet(nStim,5))
        combSets = find(stimParSet(:,1) == stimParSet(nStim,2) & ...
            stimParSet(:,3) == stimParSet(nStim,3) & ...
            stimParSet(:,4) == stimParSet(nStim,4));

        stimParSet(nStim,5) = nStim;
        stimParSet(combSets,5) = nStim;

        for nFreq = 1:size(freqs,1)
            power_pre = mean(squeeze(power_preStim(:,[nStim; combSets],:,nFreq,:)),4,'omitnan');
            power_post = mean(squeeze(power_postStim(:,[nStim; combSets],:,nFreq,:)),4,'omitnan');

            [~,p_temp] = ttest(power_pre(:),power_post(:));
            pComb(nStim,nFreq) = p_temp;
        end
    end
end

% --> dit maakt het verre van significanter! Vooral omdat het dus uit lijkt
% te maken welke kant je op stimuleert in wat voor effect je bereikt in de
% SOZelektrodes.

%% FDR correction
pAllComb = pComb(~isnan(pComb(:,1)),:);

pFDR = 0.05;

[pSort,pInd] = sort(pAllComb(:));

m = size(pAllComb(:),1);
thisVal = NaN(size(pSort));
for kk = 1:length(pSort)
    thisVal(kk) = (kk/m)*pFDR;
end

pSigComb = pAllComb;
pSigComb(pInd) = pSort < thisVal;

% housekeeping
clear pSort pInd m thisVal kk pAllComb

