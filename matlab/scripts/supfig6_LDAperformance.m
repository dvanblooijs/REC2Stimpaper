%% RECStim02_SzFreq

% in this script, the seizure frequency of all subjects is plotted
% author: Dorien van Blooijs, 2023

%% first run RECStim01_prepSzFreq

% remove those fields to save memory and make the rest of the script run
% faster
dataBase.visit = rmfield(dataBase.visit, 'log');
dataBase.visit = rmfield(dataBase.visit, 'rec');
dataBase.visit = rmfield(dataBase.visit, 'szReport');
dataBase.visit = rmfield(dataBase.visit, 'PatientMarker');

%% number of seizures during data collection phase (DCP)
DCPvisits = [];

for nVisit = 1:size(dataBase.visit,2)
    if dateshift(dataBase.visit(nVisit).visitdate,'start','day') >=  cfg.period_startDCP && ...
            dateshift(dataBase.visit(nVisit).visitdate,'start','day') <= cfg.period_stopDCP

        DCPvisits = [DCPvisits, nVisit];
    end
end

numSz = size(horzcat(dataBase.visit(DCPvisits).reclogszDiary),2);

fprintf('%s: number of seizures during DCP: %3.0f \n', cfg.sub_label,numSz)

%% load detection algorithms

dataBase = loadDetAlg(myDataPath,cfg,dataBase);

detAlg = vertcat(dataBase.visit(:).detAlg);
[~,~,vv] = unique(detAlg,'rows','stable');

vv = num2cell(vv);
[dataBase.visit(:).vv] = deal(vv{:});

disp('Detection algorithms are loaded')

%% calculate FP, TP, FN detections per visit

dataBase = calcLDAperformance(dataBase);

disp('Calculated true positive/false positive/false negative events')

%% calculate performance
sens = NaN(size(dataBase.visit,2),1);
PPV = NaN(size(dataBase.visit,2),1);
FDR = NaN(size(dataBase.visit,2),1);

for nVisit = 1:size(dataBase.visit,2)
    
    if ~isempty(dataBase.visit(nVisit).Detection) && ~isempty(dataBase.visit(nVisit).reclogszDiary)

        if sum(strcmp({dataBase.visit(nVisit).Detection.performance},'TP')) ~= sum(strcmp({dataBase.visit(nVisit).reclogszDiary.performance},'TP'))
            error('Something is wrong in calculating TP events in visit %d',nVisit)
        end

        sens(nVisit) = sum(strcmp({dataBase.visit(nVisit).reclogszDiary.performance},'TP')) / size(dataBase.visit(nVisit).reclogszDiary,2);
        PPV(nVisit) = sum(strcmp({dataBase.visit(nVisit).Detection.performance},'TP')) / size(dataBase.visit(nVisit).Detection,2);

        recHours = hms(days(size(dataBase.visit(nVisit).logdateswData,2)));
        FDR(nVisit) = sum(strcmp({dataBase.visit(nVisit).Detection.performance},'FP')) / recHours;
    end

end

disp('Calculated sensitivity, PPV and FDR (/hour)')

%% save figure

cmapDetAlg = parula(max([dataBase.visit(DCPvisits).vv]));

% Positive Predictive Value
ymin = 0;
ymax = 1.5*max(PPV(DCPvisits));

figure,
hold on
for nVisit = 2:size(dataBase.visit(DCPvisits),2)
    fill([dataBase.visit(nVisit-1).visitdate, dataBase.visit(nVisit).visitdate,...
        dataBase.visit(nVisit).visitdate, dataBase.visit(nVisit-1).visitdate],...
        [ymin ymin ymax ymax],cmapDetAlg(dataBase.visit(nVisit).vv,:), ...
        "FaceColor",cmapDetAlg(dataBase.visit(nVisit).vv,:),"EdgeColor","none")
    
    if ~isnan(PPV(DCPvisits(nVisit)))
        plot([dataBase.visit(DCPvisits(nVisit)).visitdate],PPV(DCPvisits(nVisit)),...
            'o','MarkerFaceColor',cmapDetAlg(dataBase.visit(DCPvisits(nVisit)).vv,:),...
            'MarkerEdgeColor',cmapDetAlg(dataBase.visit(DCPvisits(nVisit)).vv,:),...
            'MarkerSize',10)
    end
    
end
plot([dataBase.visit(DCPvisits).visitdate],PPV(DCPvisits), ...
    '-','LineWidth',2,'Color',cmap(1,:))
hold off
xlabel('Visit date')
ylabel('Positive Predictive Value')
xlim([dataBase.visit(DCPvisits(1)).visitdate dataBase.visit(DCPvisits(end)).visitdate])
ylim([ymin ymax])
title(cfg.sub_label)
ax = gca;
ax.XTick = dateshift(dataBase.visit(DCPvisits(1)).visitdate,'start','month'):calmonths(1):...
    dateshift(dataBase.visit(DCPvisits(end)).visitdate,'start','month');

figureName = sprintf('%sfig_PPV_%s',...
    myDataPath.Figures,cfg.sub_label);

set(gcf,'PaperPositionMode','auto')
print('-vector','-depsc',figureName)
print('-dpng','-r300',figureName)

fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

% sensitivity
ymin = 0;
ymax = 1;

figure,
hold on
for nVisit = 2:size(dataBase.visit(DCPvisits),2)
    fill([dataBase.visit(nVisit-1).visitdate, dataBase.visit(nVisit).visitdate,...
        dataBase.visit(nVisit).visitdate, dataBase.visit(nVisit-1).visitdate],...
        [ymin ymin ymax ymax],cmapDetAlg(dataBase.visit(nVisit).vv,:), ...
        "FaceColor",cmapDetAlg(dataBase.visit(nVisit).vv,:),"EdgeColor","none")
    
    if ~isnan(sens(DCPvisits(nVisit)))
        plot([dataBase.visit(DCPvisits(nVisit)).visitdate],sens(DCPvisits(nVisit)),...
            'o','MarkerFaceColor',cmapDetAlg(dataBase.visit(DCPvisits(nVisit)).vv,:),...
            'MarkerEdgeColor',cmapDetAlg(dataBase.visit(DCPvisits(nVisit)).vv,:),...
            'MarkerSize',10)
    end
end
plot([dataBase.visit(DCPvisits).visitdate],sens(DCPvisits), ...
    '-','LineWidth',2,'Color',cmap(1,:))
hold off
xlabel('Visit date')
ylabel('Sensitivity')
xlim([dataBase.visit(DCPvisits(1)).visitdate dataBase.visit(DCPvisits(end)).visitdate])
ylim([ymin ymax])
title(cfg.sub_label)
ax = gca;
ax.XTick = dateshift(dataBase.visit(DCPvisits(1)).visitdate,'start','month'):calmonths(1):...
    dateshift(dataBase.visit(DCPvisits(end)).visitdate,'start','month');

figureName = sprintf('%sfig_Sens_%s',...
    myDataPath.Figures,cfg.sub_label);

set(gcf,'PaperPositionMode','auto')
print('-vector','-depsc',figureName)
print('-dpng','-r300',figureName)

fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

% False detection rate
ymin = 0;
ymax = 1.5*max(FDR(DCPvisits));

figure,
hold on
for nVisit = 2:size(dataBase.visit(DCPvisits),2)
    fill([dataBase.visit(nVisit-1).visitdate, dataBase.visit(nVisit).visitdate,...
        dataBase.visit(nVisit).visitdate, dataBase.visit(nVisit-1).visitdate],...
        [ymin ymin ymax ymax],cmapDetAlg(dataBase.visit(nVisit).vv,:), ...
        "FaceColor",cmapDetAlg(dataBase.visit(nVisit).vv,:),"EdgeColor","none")
    
    if ~isnan(FDR(DCPvisits(nVisit)))
        plot([dataBase.visit(DCPvisits(nVisit)).visitdate],FDR(DCPvisits(nVisit)),...
            'o','MarkerFaceColor',cmapDetAlg(dataBase.visit(DCPvisits(nVisit)).vv,:),...
            'MarkerEdgeColor',cmapDetAlg(dataBase.visit(DCPvisits(nVisit)).vv,:),...
            'MarkerSize',10)
    end
end
plot([dataBase.visit(DCPvisits).visitdate],FDR(DCPvisits), ...
    '-','LineWidth',2,'Color',cmap(1,:))
hold off
xlabel('Visit date')
ylabel('False detection rate (/hour)')
xlim([dataBase.visit(DCPvisits(1)).visitdate dataBase.visit(DCPvisits(end)).visitdate])
ylim([ymin ymax])
title(cfg.sub_label)
ax = gca;
ax.XTick = dateshift(dataBase.visit(DCPvisits(1)).visitdate,'start','month'):calmonths(1):...
    dateshift(dataBase.visit(DCPvisits(end)).visitdate,'start','month');

figureName = sprintf('%sfig_FDR_%s',...
    myDataPath.Figures,cfg.sub_label);

set(gcf,'PaperPositionMode','auto')
print('-vector','-depsc',figureName)
print('-dpng','-r300',figureName)

fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

%% figure with detAlgs

figure,
hold on
for nVisit = 2:size(dataBase.visit(DCPvisits),2)
    plot([dataBase.visit(nVisit-1).visitdate, dataBase.visit(nVisit).visitdate],...
        dataBase.visit(nVisit).vv * ones(1,2),'-o','linewidth',2,...
        'Color',cmap(dataBase.visit(nVisit).vv,:),...
        'MarkerFaceColor',cmapDetAlg(dataBase.visit(nVisit).vv,:),...
        'MarkerEdgeColor',cmapDetAlg(dataBase.visit(nVisit).vv,:))
end
hold off

f = gcf;
f.Units = "normalized";
f.Position = [0.3536 0.3769 0.2917 0.05];

%%
numDetections = NaN(size(dataBase.visit,2),1);
recDays = NaN(size(dataBase.visit,2),1);

for nVisit = 1:size(dataBase.visit,2)
    numDetections(nVisit) = size(dataBase.visit(nVisit).Detection,2);
    recDays(nVisit) = size(dataBase.visit(nVisit).logdateswData,2);
end

cmapDetAlg = parula(max([dataBase.visit(:).vv]));

figure,
hold on
for nVisit = 1:size(dataBase.visit,2)
    plot(dataBase.visit(nVisit).visitdate,numDetections(nVisit)/recDays(nVisit),...
        'o','MarkerFaceColor',cmapDetAlg(dataBase.visit(nVisit).vv,:),...
        'MarkerEdgeColor',cmapDetAlg(dataBase.visit(nVisit).vv,:))
end
hold off

%% end script