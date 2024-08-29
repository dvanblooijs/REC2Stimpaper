% supfig4_mechanism of seizure detection

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

%% patient settings

cfg(1).sub_label = 'sub-REC2Stim03'; % ['sub-' input('Patient number (REC2StimXX): ','s')];
cfg(1).ses_label = 'ses-2'; %input('Session number (ses-X): ','s');

% define period of which we would like to analyze events
cfgtemp = config_period(cfg(1).sub_label);
cfg = merge_fields(cfg,cfgtemp);

cmap = parula(10);

% housekeeping 
clear cfgtemp

%% load visits
tic
dataBase = loadVisits(myDataPath,cfg);
toc

%% load and preprocess rec-files per visit of specific patient --> duration ~5min

tic
loadData = 'annotseizures';
[epochs,paramSens,paramdetAlg,paramStim,channelspec] = loadNeuroStimData(myDataPath,cfg,loadData);
disp('Preprocessed rec-files')
toc

%% fig1: plot one TD seizure

idxEpoch = find([epochs(:).annotSz] == 1 & [epochs(:).TDSOZ] == 1);
nSelect = 128;
idxTDChan = find(strcmp(epochs(idxEpoch(nSelect)).channels.status,'TD'));
TDfs = epochs(idxEpoch(nSelect)).channels.sampling_frequency(idxTDChan);
idxEvent = strcmp(epochs(idxEpoch(nSelect)).events.trial_type,'annotation') & strcmp(epochs(idxEpoch(nSelect)).events.sub_type,'seizure');
startSz = epochs(idxEpoch(nSelect)).events.sample_start(idxEvent)/TDfs;

figure(1),
plot(1/TDfs:1/TDfs:size(epochs(idxEpoch(nSelect)).data,1)/TDfs,epochs(idxEpoch(nSelect)).data(:,idxTDChan),'Color',cmap(1,:))
hold on
plot([startSz startSz],[-0.5 0.5],'k:')
hold off
xlim([startSz - 6, startSz+24])
ylim([-0.5 0.5])
xlabel('Time (s)')
ylabel('Amplitude (\muV)')
title(sprintf('%s: Time domain data', ...
    epochs(idxEpoch(nSelect)).channels.name{idxTDChan}))

f = gcf;
f.Units = "normalized";
f.Position = [0.02 0.4 0.98 0.4];

% save figure
figureName = sprintf('%ssupfig_TDSz_%s', myDataPath.Figures,cfg.sub_label);

set(gcf,'PaperPositionMode','auto')
print('-vector','-depsc',figureName)
print('-dpng','-r300',figureName)

fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

%% fig2: calculate powerspectrum of TD channels with same properties

% find epochs with same properties as the seizure plotted in figure 1
idxVV = find([channelspec.(['channel' num2str(idxTDChan)]).vv] == channelspec.(['channel' num2str(idxTDChan)])(idxEpoch(nSelect)).vv);

% OPTIONAL
% find epochs in the same visit - optional
onset_time = NaT(size(epochs(idxEpoch(nSelect)).events,1),1);

if iscell([epochs(idxEpoch(nSelect)).events.onset_time])
    for nEvent = 1:size(epochs(idxEpoch(nSelect)).events,1)
        if ~strcmpi( epochs(idxEpoch(nSelect)).events.onset_time{nEvent},'n/a')
            onset_time(nEvent) = datetime(epochs(idxEpoch(nSelect)).events.onset_time{nEvent},'InputFormat','dd-MMM-uuuu HH:mm:ss');
        else
            onset_time(nEvent) = NaT;
        end
    end

else
    onset_time = [epochs(idxEpoch(nSelect)).events.onset_time];
end

nVisit = find([dataBase.visit(:).visitdate] > min(onset_time),1,'first');
keepidxVV = [];

for nEpoch = 1:size(idxVV,2)

    %pre-allocation
    onset_time = NaT(size(epochs(idxVV(nEpoch)).events,1),1);

    if iscell([epochs(idxVV(nEpoch)).events.onset_time])
        for nEvent = 1:size(epochs(idxVV(nEpoch)).events,1)
            if ~strcmpi( epochs(idxVV(nEpoch)).events.onset_time{nEvent},'n/a')
                onset_time(nEvent) = datetime(epochs(idxVV(nEpoch)).events.onset_time{nEvent},'InputFormat','dd-MMM-uuuu HH:mm:ss');
            else 
                onset_time(nEvent) = NaT;
            end
        end
    else
        onset_time = [epochs(idxVV(nEpoch)).events.onset_time];
    end

    if min(onset_time) > dataBase.visit(nVisit-1).visitdate && ...
            min(onset_time) < dataBase.visit(nVisit).visitdate
        keepidxVV = [keepidxVV, idxVV(nEpoch)];
    end
end

idxVV = keepidxVV;
% END OPTIONAL

% pre-allocation 
tdSz = NaN(sum([epochs(idxVV).annotSz] == 1),TDfs*60);
count = 1; 

% epoch all data into seizures with 30s pre and 30s post seizure onset
for nEpoch = 1:size(idxVV,2)
    if epochs(idxVV(nEpoch)).annotSz == 1
    
        % find event note with annotated seizure information
        idxAnnot = find(strcmpi(epochs(idxVV(nEpoch)).events.trial_type,'annotation') & ...
            strcmpi(epochs(idxVV(nEpoch)).events.sub_type,'seizure'));

        % annotated seizure should start at least 30s in the file, because
        % otherwise, I cannot epoch the data
        if epochs(idxVV(nEpoch)).events.onset(idxAnnot) >30
            
            startEpoch = epochs(idxVV(nEpoch)).events.sample_start(idxAnnot) - 30*TDfs;
            stopEpoch = epochs(idxVV(nEpoch)).events.sample_start(idxAnnot) + 30*TDfs;
            tdSz(count,:) = epochs(idxVV(nEpoch)).data(startEpoch:stopEpoch-1,idxTDChan);

            count = count + 1;
        end
    end
end

% remove all NaNs (so seizures that started within 30s from start file)
tdSz(isnan(tdSz(:,1)),:) = [];

%% fig2: calculate power in frequency bands

signal = tdSz';

% filter parameters om 50Hz eruit te filteren
analysis_params.hpfreq = [];
analysis_params.lpfreq = [];
analysis_params.notchhpfreq = 47;
analysis_params.notchlpfreq = 53;
analysis_params.sample_rate = TDfs;

% filteren van signaal
signalFilt = filter_signal(signal, analysis_params, 1); % signal must be [samples x chans]

% filter parameters om 100Hz eruit te filteren
analysis_params.notchhpfreq = 97;
analysis_params.notchlpfreq = 100;

%filteren van signaal
signalFilt2 = filter_signal(signalFilt, analysis_params, 1);

% gabor filter parameters
params.sample_rate = TDfs;
params.W = 4;
params.spectra = 1:100;

% amplitudes van re-referenced signalen op verschillende frequenties [time x electrodes x frequencies]
gabor = jun_gabor_cov_fitted(signalFilt2',params,'amp',1,1).^2; % quadratic(.^2) = power
gabor_logcor = gabor./repmat(mean(gabor,1),[size(gabor,1) 1 1]);

power = gabor_logcor;

%% fig 2: plot power spectrum

powerPreSz = squeeze(mean(power(20*TDfs:30*TDfs,:,:))); % [seizures x frequencies (1-100)]
powerSz = squeeze(mean(power(30*TDfs:35*TDfs,:,:))); % [seizures x frequencies (1-100)]

SEpowerPreSz = std(powerPreSz)/sqrt(size(powerPreSz,1));
SEpowerSz = std(powerSz)/sqrt(size(powerSz,1));

figure(2),
plot(params.spectra,mean(powerPreSz),'color',cmap(2,:),'LineWidth',1)
hold on
plot(params.spectra,mean(powerSz),'color',cmap(4,:),'LineWidth',1)
fill([params.spectra, flip(params.spectra)],[mean(powerPreSz)+SEpowerPreSz, flip(mean(powerPreSz)-SEpowerPreSz)],cmap(2,:),"FaceAlpha",0.3,"EdgeColor","none")
fill([params.spectra, flip(params.spectra)],[mean(powerSz)+SEpowerSz, flip(mean(powerSz)-SEpowerSz)],cmap(4,:),"FaceAlpha",0.3,"EdgeColor","none")
hold off

xlabel('Frequency (Hz)')
ylabel('Power')
legend('Power pre seizure onset (10 s)', 'Power seizure onset (5 s)')

% save figure
figureName = sprintf('%ssupfig_PowerspectrumSz_%s', myDataPath.Figures,cfg.sub_label);

set(gcf,'PaperPositionMode','auto')
print('-vector','-depsc',figureName)
print('-dpng','-r300',figureName)

fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

%% fig 3&4: plot power domain channels

idxPDChan = find(strcmp(epochs(idxEpoch(nSelect)).channels.status,'Power') & ...
    strcmp(epochs(idxEpoch(nSelect)).channels.name{idxTDChan},epochs(idxEpoch(nSelect)).channels.name));
PDfs = epochs(idxEpoch(nSelect)).channels.sampling_frequency(idxPDChan(1));
idxEvent = strcmp(epochs(idxEpoch(nSelect)).events.trial_type,'annotation') & strcmp(epochs(idxEpoch(nSelect)).events.sub_type,'seizure');
startSz = epochs(idxEpoch(nSelect)).events.sample_start(idxEvent)/TDfs;

figure(3),
plot(1/TDfs:1/TDfs:size(epochs(idxEpoch(nSelect)).data,1)/TDfs,epochs(idxEpoch(nSelect)).data(:,idxPDChan(1)),'color',cmap(1,:))
hold on
plot([startSz, startSz],[300 1000],'k:')
hold off

xlim([startSz - 6, startSz+24])
ylim([300 1000])
xlabel('Time (s)')
ylabel('Power')
title(sprintf('%s: Center frequency = %2.0f Hz, Bandwidth = %1.1f Hz', ...
    epochs(idxEpoch(nSelect)).channels.name{idxPDChan(1)},...
    epochs(idxEpoch(nSelect)).channels.center_frequency(idxPDChan(1)),...
    epochs(idxEpoch(nSelect)).channels.bandwidth(idxPDChan(1))))

f = gcf;
f.Units = "normalized";
f.Position = [0.02 0.4 0.98 0.4];

% save figure
figureName = sprintf('%ssupfig_PD_1_Sz_%s', myDataPath.Figures,cfg.sub_label);

set(gcf,'PaperPositionMode','auto')
print('-vector','-depsc',figureName)
print('-dpng','-r300',figureName)

fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

figure(4),
plot(1/TDfs:1/TDfs:size(epochs(idxEpoch(nSelect)).data,1)/TDfs,epochs(idxEpoch(nSelect)).data(:,idxPDChan(2)),'color',cmap(1,:))
hold on
plot([startSz, startSz],[200 600],'k:')
hold off

xlim([startSz - 6, startSz+24])
ylim([200 600])
xlabel('Time (s)')
ylabel('Power')
title(sprintf('%s: Center frequency = %2.0f Hz, Bandwidth = %1.1f Hz', ...
    epochs(idxEpoch(nSelect)).channels.name{idxPDChan(2)},...
    epochs(idxEpoch(nSelect)).channels.center_frequency(idxPDChan(2)),...
    epochs(idxEpoch(nSelect)).channels.bandwidth(idxPDChan(2))))

f = gcf;
f.Units = "normalized";
f.Position = [0.02 0.4 0.98 0.4];

% save figure
figureName = sprintf('%ssupfig_PD_2_Sz_%s', myDataPath.Figures,cfg.sub_label);

set(gcf,'PaperPositionMode','auto')
print('-vector','-depsc',figureName)
print('-dpng','-r300',figureName)

fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

%% fig 5: scatter plot with power pre and during seizure onset

% find epochs with same properties as the seizure plotted in figure 1
idxVV = find([channelspec.(['channel' num2str(idxPDChan(1))]).vv] == ...
    channelspec.(['channel' num2str(idxPDChan(1))])(idxEpoch(nSelect)).vv & ...
    [channelspec.(['channel' num2str(idxPDChan(2))]).vv] == ...
    channelspec.(['channel' num2str(idxPDChan(2))])(idxEpoch(nSelect)).vv) ;

% OPTIONAL
% find epochs in the same visit - optional
onset_time = NaT(size(epochs(idxEpoch(nSelect)).events,1),1);

if iscell([epochs(idxEpoch(nSelect)).events.onset_time])
    for nEvent = 1:size(epochs(idxEpoch(nSelect)).events,1)
        if ~strcmpi( epochs(idxEpoch(nSelect)).events.onset_time{nEvent},'n/a')
            onset_time(nEvent) = datetime(epochs(idxEpoch(nSelect)).events.onset_time{nEvent},'InputFormat','dd-MMM-uuuu HH:mm:ss');
        else
            onset_time(nEvent) = NaT;
        end
    end

else
    onset_time = [epochs(idxEpoch(nSelect)).events.onset_time];
end

nVisit = find([dataBase.visit(:).visitdate] > min(onset_time),1,'first');
keepidxVV = [];

for nEpoch = 1:size(idxVV,2)

    if iscell([epochs(idxVV(nEpoch)).events.onset_time])
        for nEvent = 1:size(epochs(idxVV(nEpoch)).events,1)
            if ~strcmpi( epochs(idxVV(nEpoch)).events.onset_time{nEvent},'n/a')
                onset_time(nEvent) = datetime(epochs(idxVV(nEpoch)).events.onset_time{nEvent},'InputFormat','dd-MMM-uuuu HH:mm:ss');
            else 
                onset_time(nEvent) = NaT;
            end
        end
    else
        onset_time = [epochs(idxVV(nEpoch)).events.onset_time];
    end

    if min(onset_time) > dataBase.visit(nVisit-1).visitdate && ...
            min(onset_time) < dataBase.visit(nVisit).visitdate
        keepidxVV = [keepidxVV, idxVV(nEpoch)];
    end
end

idxVV = keepidxVV;
% END OPTIONAL

% pre-allocation
pdPreSz = NaN(size(keepidxVV,2),11*PDfs,size(idxPDChan,1));
pdSz =  NaN(size(keepidxVV,2),6*PDfs,size(idxPDChan,1));

for nEpoch = 1:size(idxVV,2)

    idxAnnot = find(strcmpi([epochs(nEpoch).events.trial_type],'annotation') & ...
        strcmpi([epochs(nEpoch).events.sub_type],'seizure'));
    fs = max(epochs(nEpoch).channels.sampling_frequency);

    if epochs(nEpoch).events.sample_start(idxAnnot) > 10*fs

        startEpochPre = epochs(nEpoch).events.sample_start(idxAnnot)-10*fs;
        stopEpochPre = epochs(nEpoch).events.sample_start(idxAnnot)-1;
        startEpochSz = epochs(nEpoch).events.sample_start(idxAnnot);
        stopEpochSz = epochs(nEpoch).events.sample_start(idxAnnot)+5*fs-1;
        epochPre = epochs(nEpoch).data(startEpochPre:stopEpochPre,idxPDChan);
        epochSz = epochs(nEpoch).data(startEpochSz:stopEpochSz,idxPDChan);

        if fs == TDfs

            epochPre = unique(epochPre,'rows','stable');
            epochSz = unique(epochSz,'rows','stable');
            pdPreSz(nEpoch,1:size(epochPre,1),:) = epochPre;
            pdSz(nEpoch,1:size(epochSz,1),:) = epochSz;

        elseif fs == PDfs

            pdPreSz(nEpoch,1:size(epoch,1),:) = epochs(nEpoch).data(startEpochPre:stopEpochPre,idxPDChan);
            pdSz(nEpoch,1:size(epoch,1),:) = epochs(nEpoch).data(startEpochSz:stopEpochSz,idxPDChan);

        end
    end
end

pdPreSz = [reshape(pdPreSz(:,:,1),[],1) reshape(pdPreSz(:,:,2),[],1)];
pdPreSz = pdPreSz(~isnan(pdPreSz(:,1)),:);
pdSz = [reshape(pdSz(:,:,1),[],1) reshape(pdSz(:,:,2),[],1)];
pdSz = pdSz(~isnan(pdSz(:,1)),:);

%% fig 5: calculate LDA

X = [pdPreSz ; pdSz];
Y = [zeros(size(pdPreSz,1),1); ones(size(pdSz,1),1)];

%  Setup the data matrix appropriately, and add ones for the intercept term
[m, n] = size(X);

% Add intercept term to x and X_test
X_calc = [ones(m, 1) X];

% Initialize fitting parameters
initial_theta = zeros(n + 1, 1);

% Compute and display initial cost and gradient
[cost, grad] = costFunction(initial_theta, X_calc, Y);

if isnan(grad)
    error('Still NaNs in X, remove those before continuing!')
end

fprintf('Cost at initial theta (zeros): %f\n', cost);
fprintf('Gradient at initial theta (zeros): \n');
fprintf(' %f \n', grad);

options = optimset('GradObj', 'on', 'MaxIter', 400);

%  Run fminunc to obtain the optimal theta
%  This function will return theta and the cost
[theta, cost] = ...
    fminunc(@(t)(costFunction(t, X_calc, Y)), initial_theta, options);

% Print theta to screen
fprintf('Cost at theta found by fminunc: %f\n', cost);
fprintf('theta: \n');
fprintf(' %f \n', theta);

% determine coefficients for Activa PC+S
W1 = -1*theta(2);
W2 = -1*theta(3);

if size(theta,1) > 3
    W3 = -1*theta(4);
else
    W3 = 0;
end

W4 = 0;
b = theta(1);
NormConstB1 = 1;
NormConstB2 = 1;
NormConstB3 = 1;
NormConstB4 = 1;
NormConstA1 = 0;
NormConstA2 = 0;
NormConstA3 = 0;
NormConstA4 = 0;

detAlg.W1 = W1;
detAlg.W2 = W2;
detAlg.W3 = W3;
detAlg.W4 = W4;
detAlg.b = b;
detAlg.NormConstB1 = NormConstB1;
detAlg.NormConstB2 = NormConstB2;
detAlg.NormConstB3 = NormConstB3;
detAlg.NormConstB4 = NormConstB4;
detAlg.NormConstA1 = NormConstA1;
detAlg.NormConstA2 = NormConstA2;
detAlg.NormConstA3 = NormConstA3;
detAlg.NormConstA4 = NormConstA4;

x1 = 0:max(X(:,1))+round(0.1*max(X(:,1)));
x2 = (x1*W1*-1 +b) / W2;

%% fig 5: plot scatter with LDA

figure(5),
h = scatter(pdSz(:,1),pdSz(:,2),40,cmap(4,:),'filled');
hold on
k = scatter(pdPreSz(:,1),pdPreSz(:,2),40,cmap(2,:));
l = plot(x1,x2,'color',[0.5 0.5 0.5],'linewidth',2);
hold off

legend([k,h,l],'Pre-seizure onset (10 s)','Seizure onset (5 s)','Linear Discriminant')
xlabel(sprintf('Power in %3.1f Hz frequency band',channelspec.(['channel' num2str(idxPDChan(1))])(idxVV(1)).cfreq))
ylabel(sprintf('Power in %3.1f Hz frequency band',channelspec.(['channel' num2str(idxPDChan(2))])(idxVV(1)).cfreq))
title('Seizure and non-seizure data')
xlim([x1(1), x1(end)])

% save figure
figureName = sprintf('%ssupfig_scatterLDASz_%s', myDataPath.Figures,cfg.sub_label);

set(gcf,'PaperPositionMode','auto')
print('-vector','-depsc',figureName)
print('-dpng','-r300',figureName)

fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

%% fig 6: LDA signal with seizure

data = epochs(idxEpoch(nSelect)).data(:,idxPDChan);
distance = calcDistance(data,detAlg);

ymin = floor(1.1*min(distance));
ymax = ceil(1.1*max(distance));

figure(6),
plot(1/TDfs:1/TDfs:size(data,1)/TDfs,distance,'color',cmap(2,:))
hold on
plot([startSz startSz],[ymin ymax],'k:')
plot([1/TDfs size(data,1)/TDfs],[0 0],':','color',[0.5 0.5 0.5])
hold off

xlim([startSz - 6, startSz+24])
ylim([ymin ymax])
xlabel('Time (s)')
ylabel('Linear Discriminant')

f = gcf;
f.Units = "normalized";
f.Position = [0.02 0.4 0.98 0.4];

% save figure
figureName = sprintf('%ssupfig_LDA_%s', myDataPath.Figures,cfg.sub_label);

set(gcf,'PaperPositionMode','auto')
print('-vector','-depsc',figureName)
print('-dpng','-r300',figureName)

fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)
