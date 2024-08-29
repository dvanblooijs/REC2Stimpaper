%% RECStim02_SzFreq

% in this script, the seizure frequency of all subjects is plotted

% author: Dorien van Blooijs, 2023
% 
% close all
% clear;
% clc;
% 
% %% set paths
% 
% % add current path from folder which contains this script
% rootPath = matlab.desktop.editor.getActiveFilename;
% RepoPath = fileparts(rootPath);
% matlabFolder = strfind(RepoPath,'matlab');
% addpath(genpath(RepoPath(1:matlabFolder+6)));
% 
% myDataPath = REC2Stim_setLocalDataPath(1);
% 
% % housekeeping
% clear rootPath RepoPath matlabFolder

%% first run RECStim01_prepSzFreq

%% combine all seizures into one array

sz = cell(1);
datesWData = cell(1);

for nVisit = 1:size(dataBase.visit,2)
    if isfield(dataBase.visit(nVisit).reclogszDiary,'dateConvertSP')
        sz{nVisit} = vertcat(dataBase.visit(nVisit).reclogszDiary(:).dateConvertSP);
    end
    datesWData{nVisit} = horzcat(dataBase.visit(nVisit).logdateswData);
end

szAll = vertcat(sz{:});
datesWDataAll = horzcat(datesWData{:});

%% calculate number of seizures per day

minDate = cfg.period_start; %min([szAll; datesWDataAll']);
maxDate = cfg.period_stop; %max([szAll; datesWDataAll']);
allDates = minDate:maxDate;
szFreq = cell(size(allDates,2),3);

for nDate = 1:size(allDates,2)
    szFreq{nDate,1} = allDates(nDate);
    szFreq{nDate,2} = string(allDates(nDate));
    szFreq{nDate,3} = sum(allDates(nDate) == dateshift(szAll,'start','day'));

    if szFreq{nDate,3} == 0
        if any(datesWDataAll==allDates(nDate))

        else
            szFreq{nDate,3} = NaN;
        end
    end
end

%% calculate daily frequency per month and plot

allMonths = sort([cfg.period_start, ...
    dateshift(cfg.period_start,'start','month')+calmonths(1):calmonths(1):...
    dateshift(cfg.period_stop,'end','month'), cfg.period_stop, cfg.period_startStim],'ascend'); 

allMonths = allMonths(~isnat(allMonths));

plotMeanSz = NaN(size(allMonths,2)-1,1);
plotSDSz = NaN(size(allMonths,2)-1,1);
n = NaN(size(allMonths,2)-1,1);

for nMonth = 1:size(allMonths,2)-1
    idx = vertcat(szFreq{:,1}) >= allMonths(nMonth) & vertcat(szFreq{:,1}) < allMonths(nMonth+1);

    plotMeanSz(nMonth) = mean(vertcat(szFreq{idx,3}),'omitnan');
    plotSDSz(nMonth) = std(vertcat(szFreq{idx,3}),'omitnan');
    n(nMonth) = sum(~isnan(vertcat(szFreq{idx,3})));
end

allMonths = allMonths(1:end-1);

%% calculate mean seizure frequency during DCP and during the last two months of stimulation phase
idxDCP = vertcat(szFreq{:,1}) >= cfg.period_startDCP & vertcat(szFreq{:,1}) < cfg.period_startStim;
meanSzDCP = mean(vertcat(szFreq{idxDCP,3}),'omitnan');

if ~isnat(cfg.period_startStim(1))

    idxStim = vertcat(szFreq{:,1}) > cfg.period_stop-calmonths(2) & vertcat(szFreq{:,1}) <= cfg.period_stop;
    meanSzStim = mean(vertcat(szFreq{idxStim,3}),'omitnan');

    p = ranksum(vertcat(szFreq{idxDCP,3}),vertcat(szFreq{idxStim,3}));

    fprintf('%s: Mean szFreq DCP = %1.2f, Mean szFreq SP = %1.2f, p = %1.3f, reduction = %2.1f%% \n',...
        dataBase.sub_label ,meanSzDCP, meanSzStim, p, (meanSzDCP-meanSzStim)/meanSzDCP*100);
end

%% plot seizure frequency

DCP = [cfg.period_startDCP, ...
    dateshift(cfg.period_startDCP,'start','month')+calmonths(1):calmonths(1):dateshift(cfg.period_stopDCP,'start','month'), cfg.period_stopDCP];
stimPeriod = [cfg.period_startStim, dateshift(cfg.period_startStim,'start','month')+calmonths(1):...
    calmonths(1):dateshift(cfg.period_stop,'start','month')];

SE = plotSDSz./sqrt(n);

lo_SD = plotMeanSz - SE;
up_SD = plotMeanSz + SE;

% cmap = parula(3);
cmap(1,1:3) = [0 174 239]/256;
cmap(2,1:3) = [46 46 146]/256;
cmap(3,1:3) = [43 182 115]/256;

figure,
kk = fill([allMonths, flip(allMonths)],[lo_SD; flip(up_SD)]',cmap(1,:),'FaceAlpha',0.2,'EdgeColor','none');
hold on
% plot(allMonths,plotMeanSz,'Color',cmap(1,:),'LineWidth',1)
[DCP_all,idxMonths] = intersect(allMonths,DCP);
hh = plot(DCP_all,plotMeanSz(idxMonths),'Color',cmap(2,:),'LineWidth',3);
[stimP_all,idxMonths] = intersect(allMonths,stimPeriod);
mm = plot(stimP_all,plotMeanSz(idxMonths),'Color',cmap(3,:),'LineWidth',3);

if ~isnat(cfg.period_startStim)

    nn = plot([cfg.period_startDCP;cfg.period_startStim],ones(2,1)*meanSzDCP,'--','Color',cmap(2,:));
    pp = plot([cfg.period_stop-calmonths(2); cfg.period_stop],ones(2,1)*meanSzStim,'--','Color',cmap(3,:));

    if p<0.001
        text(cfg.period_stop-calmonths(1),ceil(meanSzStim)*1.5,'***','HorizontalAlignment','center')
    elseif p<0.01
        text(cfg.period_stop-calmonths(1),ceil(meanSzStim)*1.5,'**','HorizontalAlignment','center')
    elseif p<0.05
        text(cfg.period_stop-calmonths(1),ceil(meanSzStim)*1.5,'*','HorizontalAlignment','center')
    end
end

hold off

xlabel('Time (months)')
ylabel('Seizure frequency (/day)')
title(cfg.sub_label)
ylim([0 max([1.2*max(up_SD) 6])])
xlim([dateshift(allMonths(1),'start','month') allMonths(end)])

ax = gca;
ax.XTick = dateshift(allMonths(1),'start','month'): calmonths(3):allMonths(end);

legend([kk,hh,mm,nn,pp],'SEM','Data Collection Phase', 'Stimulation Phase','Mean frequency DCP', 'Mean frequency SP')

% save figure
figureName = sprintf('%sfig_szFreq_%s',...
    myDataPath.Figures,cfg.sub_label);

set(gcf,'PaperPositionMode','auto')
print('-vector','-depsc',figureName)
print('-dpng','-r300',figureName)

fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

%% end script