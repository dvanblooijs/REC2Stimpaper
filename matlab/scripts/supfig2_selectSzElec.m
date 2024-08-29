%% DetermineSeizureDetectionParameters

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

%% find ECoGs with seizures

files = dir(fullfile(myDataPath.dataPath,selectSubj.sub_label,selectSubj.ses_label,'ieeg'));
idx_events = contains({files(:).name},'events.tsv');

files_events = files(idx_events);
run_label = cell(1);
count = 1;

for nFile = 1:size(files_events,1)
    
    eventsName = fullfile(files_events(nFile).folder,files_events(nFile).name);
    tb_events = readtable(eventsName,'FileType','text','Delimiter','\t');

    if any(strcmpi(tb_events.trial_type,'seizure'))
        
        run_temp = extractBetween(files_events(nFile).name,'run-','_events');
        run_label{count,1} = ['run-', run_temp{:}];

        count = count+1;
    end
end

selectSubj.run_label = run_label;

% housekeeping
clear count eventsName files files_events idx_events nFile tb_events run_label run_temp

%% load all ECoGs with at least one seizure

dataBase = load_ECoGdata(myDataPath,selectSubj);

disp('All ECoGs are loaded') 

%% select epochs with seizure activity
SOZelec = {'IH05','IH06','IH13','IH14'}; 
SOZelec2 = {'IH5','IH6','IH13','IH14'}; 
durPreSz = 30;
durPostSz = 30;

count = 1;

seizure = struct([]);

for n = 1:size(dataBase,2)

    ch = contains(dataBase(n).ch,SOZelec);
    if sum(ch) < size(SOZelec,2)
        ch = contains(dataBase(n).ch,SOZelec2);
    end

    if sum(ch) < size(SOZelec,2)
        error('Not all channels are found in channel list for ECoG file %d',n)
    end

    fs = dataBase(n).ccep_header.Fs;
    idx_sz = find(contains(dataBase(n).tb_events.trial_type,'seizure'));

    % if there is only one seizure in a data-file
    for szNum = 1
        
        sampSzStart = dataBase(n).tb_events.sample_start(idx_sz(szNum));

        if sampSzStart - durPreSz*fs > 1 && sampSzStart + durPostSz*fs < size(dataBase(n).data,2)

            seizure(count).data = dataBase(n).data(ch,sampSzStart - durPreSz*fs: sampSzStart + durPostSz*fs);
            seizure(count).file = n;
            seizure(count).fs = fs;
            count = count + 1;
        end
    end

    % if there are more than one seizures in a data-file
    for szNum = 2:size(idx_sz,1)
        sampSzStart = dataBase(n).tb_events.sample_start(idx_sz(szNum));
        sampPrevSzStop = dataBase(n).tb_events.sample_end(idx_sz(szNum-1));

        if sampSzStart - durPreSz*fs > sampPrevSzStop + durPostSz*fs && sampSzStart + durPostSz*fs < size(dataBase(n).data,2)

            seizure(count).data = dataBase(n).data(ch,sampSzStart - durPreSz*fs: sampSzStart + durPostSz*fs);
            seizure(count).file = n;
            seizure(count).fs = fs;
            count = count + 1;
        end

    end
end

disp('Selected seizure epochs')

% housekeeping
clear count ch idx_sz n SOZelec2 szNum

%% calculate power - this step takes a while

powerall = powerspectrum_seizureonset(seizure); %[122881 x 4 x 100] <- samples (60s) x channels x frequencies

%% statistical analysis - paired t-test / wilcoxon signed rank test

freqs = [4 7; 8 14; 15 25; 26 40; 65 95];

preictPow = NaN(size(powerall,2),size(freqs,1),size(SOZelec,2)); %[12x5x4] <- #seizures x frequencie bands x electrodes
ictPow = NaN(size(powerall,2),size(freqs,1),size(SOZelec,2)); %[12x5x4] <- #seizures x frequencie bands x electrodes

for n = 1:size(powerall,2) % for each seizure
    fs = seizure(n).fs;
    for elec = 1:size(powerall(n).power,2)
        for nFreq = 1:size(freqs,1)
            preictPow(n,nFreq,elec) = mean(mean(squeeze(powerall(n).power((durPreSz-15)*fs:durPreSz*fs, elec,freqs(nFreq,1):freqs(nFreq,2)))));
            ictPow(n,nFreq,elec) = mean(mean(squeeze(powerall(n).power(durPreSz*fs:(durPreSz+5)*fs, elec, freqs(nFreq,1):freqs(nFreq,2)))));

        end
    end
end

pAll = NaN(size(freqs,1),size(SOZelec,2)); %[frequency bands x elecs]
for elec = 1:size(powerall(n).power,2) % for each electrode
    for nFreq = 1:size(freqs,1) % for each frequency band
%         [h,p] = ttest(preictPow(:,nFreq,elec),ictPow(:,nFreq,elec)); % one pre-ictal value and one ictal value per seizure: [12x1] vs [12x1]
        p = signrank(preictPow(:,nFreq,elec), ictPow(:,nFreq,elec));
        pAll(nFreq,elec) = p;
    end
end

% FDR correction
pFDR = 0.05;

[pSort,pInd] = sort(pAll(:));

m = size(pAll(:),1);
thisVal = NaN(size(pSort));
for kk = 1:length(pSort)
    thisVal(kk) = (kk/m)*pFDR;
end

pSig = pAll;
pSig(pInd) = pSort < thisVal;

%% Wilcoxon signed rank test 
% visualized with lines connecting power pre- and post-stimulation

close all

for elec = 1:size(powerall(1).power,2)

    preIctPowIndiv = preictPow(:,:,elec); %[12x5]
    ictPowIndiv = ictPow(:,:,elec);
    
    figure(elec)
    hold on
    for nFreq = 1:size(freqs,1)

        plot(transpose(ones(size(preIctPowIndiv,1),1)*[nFreq-0.2,nFreq+0.2]),...
            transpose([preIctPowIndiv(:,nFreq), ictPowIndiv(:,nFreq)]), ...
            'color','b')

        plot([nFreq-0.2,nFreq+0.2], [median(preIctPowIndiv(:,nFreq),'omitnan'); ...
            median(ictPowIndiv(:,nFreq),'omitnan')],'color','k','LineWidth',2)
    end

    ymax = ceil(max([preIctPowIndiv(:);...
        ictPowIndiv(:)]));
    ylim([0 1.1*ymax])

    for nFreq = 1:size(pSig,1)
        if pSig(nFreq,elec) == 1
            if pAll(nFreq,elec) < 0.001
                text(nFreq,ymax,'***','HorizontalAlignment','center')
            elseif pAll(nFreq,elec) < 0.01
                text(nFreq,ymax,'**','HorizontalAlignment','center')
            elseif pAll(nFreq,elec) < 0.05
                text(nFreq,ymax,'*','HorizontalAlignment','center')
            end
        else
            if pAll(nFreq,elec) < 0.001
                text(nFreq,ymax,'***','HorizontalAlignment','center','Color',[169, 169, 169]/256)
            elseif pAll(nFreq,elec) < 0.01
                text(nFreq,ymax,'**','HorizontalAlignment','center','Color',[169, 169, 169]/256)
            elseif pAll(nFreq,elec) < 0.05
                text(nFreq,ymax,'*','HorizontalAlignment','center','Color',[169, 169, 169]/256)
            end
        end
    end
    hold off

    ax = gca;
    ax.XTick = 0:nFreq+1;
    ax.XTickLabel = {'','4-7','8-14','15-25','26-40','65-95',''};
    ax.XLabel.String = 'Frequency bands (Hz)';
    ax.YLabel.String = 'Power';

    title(sprintf('SOZ electrode %s',SOZelec{elec}))

    figureName = sprintf('%ssupfig2_SOZelec%s',myDataPath.Figures,SOZelec{elec});

    set(gcf,'PaperPositionMode','auto')
    print('-dpng','-r300',figureName)
    print('-vector','-depsc',figureName)

    fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

end

%% figure - boxpot - OUD

% namesPre = cell(size(preictPow(:,:,1)));
%     [namesPre{:,1}] = deal('freq1_preict');
%     [namesPre{:,2}] = deal('freq2_preict');
%     [namesPre{:,3}] = deal('freq3_preict');
%     [namesPre{:,4}] = deal('freq4_preict');
%     [namesPre{:,5}] = deal('freq5_preict');
%     namesPreAll = namesPre(:);
% namesIct = cell(size(ictPow(:,:,1)));
%     [namesIct{:,1}] = deal('freq1_ict');
%     [namesIct{:,2}] = deal('freq2_ict');
%     [namesIct{:,3}] = deal('freq3_ict');
%     [namesIct{:,4}] = deal('freq4_ict');
%     [namesIct{:,5}] = deal('freq5_ict');
%     namesIctAll = namesIct(:);
% 
%     namesAll = vertcat(namesPreAll,namesIctAll); %[120x1]
% 
% for elec = 1:size(powerall(1).power,2)
% 
%     preIctPowIndiv = preictPow(:,:,elec); %[12x5]
%     preIctPowIndivvec = preIctPowIndiv(:); %[60x1]
%     ictPowIndiv = ictPow(:,:,elec);
%     ictPowIndivvec = ictPowIndiv(:);
% 
%     powIndivvec = [preIctPowIndivvec; ictPowIndivvec]; %[120x1]
% 
%     h = figure(elec);
%     boxplot(powIndivvec,namesAll, 'PlotStyle','compact','Colors','br', ...
%         'GroupOrder',{'freq1_preict','freq1_ict','freq2_preict', ...
%         'freq2_ict','freq3_preict','freq3_ict','freq4_preict', ...
%         'freq4_ict','freq5_preict','freq5_ict'})
%     
%     ymax = ceil(max(powIndivvec));
%     ylim([0 1.1*ymax])
% 
%     hold on
%     plot(repmat(2.5:2:12,2,1),[0 1.1*ymax],'k:')
% 
% 
%     for p = 1:size(pSig,1)
%         if pSig(p,elec) == 1
%             if pAll(p,elec) < 0.001
%                text(p*2-0.5,ymax,'***','HorizontalAlignment','center')
%             elseif pAll(p,elec) < 0.01
%                text(p*2-0.5,ymax,'**','HorizontalAlignment','center')
%             elseif pAll(p,elec) < 0.05
%                text(p*2-0.5,ymax,'*','HorizontalAlignment','center')
%             end
%         end
%     end
%     hold off
% 
%     ax = gca;
%     ax.XTick = 1.5:2:12;
%     ax.XTickLabel = {'4-7Hz','8-14Hz','15-25Hz','26-40Hz','65-95Hz'};
%     ax.XLabel.String = 'Frequency bands';
%     ax.YLabel.String = 'Power';    
% 
%     title(sprintf('SOZ electrode %s',SOZelec{elec}))
% 
%     figureName = sprintf('%ssupfig2_SOZelec%s',myDataPath.Figures,SOZelec{elec});
% 
% %     set(gcf,'PaperPositionMode','auto')
% %     print('-dpng','-r300',figureName)
% %     print('-vector','-depsc',figureName)
% 
% %     fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)
% 
% end
