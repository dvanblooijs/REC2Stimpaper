% supfig7_battery_impedance
% deze code klopt nu helemaal
% alleen nog zorgen voor een nieuwe export vanuit Castor en dan de plaatjes
% in illustrator zetten.

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

%% load data

files = dir(fullfile(myDataPath.dataPath,'sourcedata','castorExport'));
files([files(:).bytes] == 0) = [];
files_visit = files(contains({files(:).name},'REC2Stimstudy_Visit'));

if size(files_visit,1)>1    % When there are multiple exports

    % find the newest export
     [~,I] = max([files_visit(:).datenum]);

     file = files_visit(I);

else
    file = files_visit(1);
end
 
% Load excel file
table = readtable(fullfile(file.folder, file.name));

%% remove all files from tables that are after the defined stopdate
subjects = unique(table.ParticipantId);

% pre-allocation
keep = NaN(size(table,1),size(subjects,1));

for nSub = 1:size(subjects,1)
    config = config_period(subjects{nSub});

    keep(:,nSub) = datetime(table.date_visit,'InputFormat','dd-MM-yyyy') < dateshift(config.period_stop,'end','month') & contains(table.ParticipantId,subjects{nSub});

end

keep = logical(sum(keep,2));
table = table(keep,:);

%% select one subject, convert the date strings to datetime and plot the impedance in time

close all

subject = table.ParticipantId;
allSubjects = unique(subject);
dateVisit = datetime(table.date_visit,'InputFormat','dd-MM-yyyy');
impedance = [table.impval_E0_E1, table.impval_E0_E2, table.impval_E0_E3, ...
    table.impval_E1_E2, table.impval_E1_E3, table.impval_E2_E3, ...
    table.impval_E8_E9, table.impval_E8_E10, table.impval_E8_E11, ...
    table.impval_E9_E10, table.impval_E9_E11, table.impval_E10_E11];
impedanceElec = {'E0-E1','E0-E2','E0-E3','E1-E2','E1-E3','E2-E3','E8-E9',...
    'E8-E10','E8-E11','E9-E10','E9-E11','E10-E11'};

% make selection of visits of one subject
for nSub = 1:size(allSubjects,1)
    idx = strcmp(subject,allSubjects{nSub});
    impedanceSub = impedance(idx,:);
    dateVisitSub = dateVisit(idx);

    [~,idx] = sort(dateVisitSub,'ascend');

    figure(nSub),
    plot(dateVisitSub(idx),impedanceSub(idx,:))
    legend(impedanceElec,'Location','bestoutside')

    title(sprintf('Impedance of %s',allSubjects{nSub}))

end


%% part 2: convert the date strings to datetime and plot the impedance in time

cmap = parula(10);

close all
% minDate = dateshift(min(datetime(table.date_visit,'InputFormat','dd-MM-yyyy')),'start','month');
% maxDate = dateshift(max(datetime(table.date_visit,'InputFormat','dd-MM-yyyy')),'end','month');

subject = table.ParticipantId;
allSubjects = unique(subject);
dateVisit = datetime(table.date_visit,'InputFormat','dd-MM-yyyy');
impedance = [table.impval_E0_E1, table.impval_E0_E2, table.impval_E0_E3, ...
    table.impval_E1_E2, table.impval_E1_E3, table.impval_E2_E3, ...
    table.impval_E8_E9, table.impval_E8_E10, table.impval_E8_E11, ...
    table.impval_E9_E10, table.impval_E9_E11, table.impval_E10_E11];
impedanceElec = {'E0-E1','E0-E2','E0-E3','E1-E2','E1-E3','E2-E3','E8-E9',...
    'E8-E10','E8-E11','E9-E10','E9-E11','E10-E11'};

for nSub = 1:size(allSubjects,1)

    % make selection of visits of one subject
    idx = strcmp(subject,allSubjects{nSub});
    dateVisitSub = dateVisit(idx);
    impedanceSub = impedance(idx,:);
    impedanceSub(impedanceSub>10000) = 10000;

    minDate = dateshift(min(dateVisitSub),'start','month');
    maxDate = dateshift(max(dateVisitSub),'end','month');

    % select only the electrodes used for stimulation and for sensing
    subj = allSubjects{nSub};
    config = config_period(subj);
    configtmp = config_sensStim(subj);
    config = merge_fields(config,configtmp);

    sensElec = NaN(size(config.sensElec,2));
    for nElec = 1:size(config.sensElec,2)
        sensElec(nElec) = find(contains(impedanceElec,config.sensElec{nElec}));
    end

    stimElec = NaN(size(config.sensElec,2));
    if ~isempty(config.stimElec{1})
        for nElec = 1:size(config.stimElec,2)
            stimElec(nElec) = find(contains(impedanceElec,config.stimElec{nElec}));
        end
    end

    impedanceSub(isnat(dateVisitSub),:) = NaN;
    clear dateVisittmp

    [~,idx] = sort(dateVisitSub,'ascend');

    ymin = 0;
    if ~isempty(config.stimElec{1})
        ymax = max([max(impedanceSub(idx,[stimElec,sensElec])), 5000])+500;
    else
        ymax = max([max(impedanceSub(idx,sensElec)), 5000])+500;
    end

    figure(nSub),
    plot(dateVisitSub(idx),impedanceSub(idx,sensElec),LineWidth=2,Color=cmap(1,:)),

    hold on
    if ~isempty(config.stimElec{1})
        plot(dateVisitSub(idx),impedanceSub(idx,stimElec),Color=cmap(5,:)),
    end
    
    % mark data collection phase
    fill([config.period_startDCP config.period_stopDCP config.period_stopDCP config.period_startDCP], ...
        [ymin ymin ymax ymax],[0 174 239]/256,'FaceAlpha',0.1,'EdgeColor','none')
    % mark stimulation phase
    if ~isnat(config.period_startStim)
        fill([config.period_startStim maxDate maxDate config.period_startStim], ...
            [ymin ymin ymax ymax],[46 49 146]/256,'FaceAlpha',0.1,'EdgeColor','none')
    end
    hold off

    xlabel('Date')
    ylabel('Impedance (Ohm)')
    xlim([minDate maxDate])
    ylim([ymin ymax])
    
    if ~isempty(config.stimElec{1})
        legend(impedanceElec{[sensElec, stimElec]},'Location','best')
    else
        legend(impedanceElec{sensElec},'Location','best')
    end

    title(sprintf('Impedance of %s',allSubjects{nSub}))

    ax = gca;
    ax.XTick = minDate:calmonths(3):maxDate;

    % save figure
    figureName = fullfile(myDataPath.Figures,sprintf('%s_impedance',allSubjects{nSub}));

    set(gcf,'PaperPositionMode','auto')
    print('-dpng','-r300',figureName)
    print('-vector','-depsc',figureName)

    fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

end

%% battery

close all

% minDate = dateshift(min(datetime(table.date_visit,'InputFormat','dd-MM-yyyy')),'start','month');
% maxDate = dateshift(max(datetime(table.date_visit,'InputFormat','dd-MM-yyyy')),'end','month');

subject = table.ParticipantId;
allSubjects = unique(subject);
dateVisit = table.RepeatingDataNameCustom;
battery = table.batval;
battery(contains(table.RepeatingDataParent,'Implantation')) = NaN; % during implantation, the batterylevel is not noted in 4/5 patients

% make selection of visits of one subject
for nSub = 1:size(allSubjects,1)
    idx = strcmp(subject,allSubjects{nSub});
    dateVisitSub = dateVisit(idx);
    batterySub = battery(idx,:);

    subj = allSubjects{nSub};
    config = config_period(subj);

    dateVisittmp = NaT(size(dateVisitSub));
    % convert dates to datetime
    for nDate = 1:size(dateVisitSub,1)
        if contains(dateVisitSub{nDate},'TC')
            dateVisittmp(nDate) = NaT;
        
        else

            datetmp = extractAfter(dateVisitSub{nDate},'- ');
            dateVisittmp(nDate) = datetime(datetmp,'InputFormat','dd-MM-yyyy');
        end
    end

    dateVisitSub = dateVisittmp;
    batterySub(isnat(dateVisitSub),:) = NaN;
    clear dateVisittmp

    minDate = dateshift(min(dateVisitSub),'start','month');
    maxDate = dateshift(max(dateVisitSub),'end','month');

    [~,idx] = sort(dateVisitSub,'ascend');

    figure(nSub),
    plot(dateVisitSub(idx),batterySub(idx),'Color',cmap(1,:)),
    hold on
    % mark data collection phase
    fill([config.period_startDCP config.period_stopDCP config.period_stopDCP config.period_startDCP], ...
        [ymin ymin ymax ymax],[0 174 239]/256,'FaceAlpha',0.1,'EdgeColor','none')
    % mark stimulation phase
    if ~isnat(config.period_startStim)
        fill([config.period_startStim maxDate maxDate config.period_startStim], ...
            [ymin ymin ymax ymax],[46 49 146]/256,'FaceAlpha',0.1,'EdgeColor','none')
    end
    hold off

    xlabel('Date')
    ylabel('Battery level (V)')
    xlim([minDate maxDate])
    ylim([0 3.5])
    title(sprintf(allSubjects{nSub}))

    ax = gca;
    ax.XTick = minDate:calmonths(3):maxDate;

    % save figure
    figureName = fullfile(myDataPath.Figures,sprintf('%s_battery',allSubjects{nSub}));

    set(gcf,'PaperPositionMode','auto')
    print('-dpng','-r300',figureName)
    print('-vector','-depsc',figureName)

    fprintf('Figure is saved as .png and .eps in \n %s \n',figureName)

end

