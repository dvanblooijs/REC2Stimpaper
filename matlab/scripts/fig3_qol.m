% figX_qol, nineholepeg, ARAT
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

reps = dir(fullfile(myDataPath.dataPath,'sourcedata','castorExport'));
reps([reps(:).isdir] == 0) = [];
reps(contains({reps(:).name},'.')) = [];

if size(reps,1) > 1 % when there are multiple exports

     [~,I] = max([reps(:).datenum]);

     rep = reps(I);

else
    rep = reps(1);
end
 
files = dir(fullfile(rep(1).folder,rep(1).name));
files_aqol = files(contains({files(:).name},'aqol-8d','IgnoreCase',true));
files_ARAT = files(contains({files(:).name},'arat','IgnoreCase',true));
files_USER = files(contains({files(:).name},'user','IgnoreCase',true));
files_NHPtest = files(contains({files(:).name},'nine-hole_peg_test','IgnoreCase',true));

% Load excel files
table_aqol = readtable(fullfile(files_aqol.folder, files_aqol.name));
table_ARAT = readtable(fullfile(files_ARAT.folder, files_ARAT.name));
table_USER = readtable(fullfile(files_USER.folder, files_USER.name));
table_NHPtest = readtable(fullfile(files_NHPtest.folder, files_NHPtest.name));

%% remove all files from tables that are after the defined stopdate
subjects = unique(vertcat(table_aqol.ParticipantId, table_ARAT.ParticipantId, table_USER.ParticipantId, table_NHPtest.ParticipantId));

% pre-allocation
keep_aqol = NaN(size(table_aqol,1),size(subjects,1));
keep_ARAT = NaN(size(table_ARAT,1),size(subjects,1));
keep_USER = NaN(size(table_USER,1),size(subjects,1));
keep_NHP = NaN(size(table_NHPtest,1),size(subjects,1));

for nSub = 1:size(subjects,1)
    config = config_period(subjects{nSub});

    keep_aqol(:,nSub) = datetime(table_aqol.AQol_date,'InputFormat','dd-MM-yyyy') < dateshift(config.period_stop + calmonths(1),'end','month') & contains(table_aqol.ParticipantId,subjects{nSub});
    keep_ARAT(:,nSub) = datetime(table_ARAT.ARAT_date,'InputFormat','dd-MM-yyyy') < dateshift(config.period_stop + calmonths(1),'end','month') & contains(table_ARAT.ParticipantId,subjects{nSub});
    keep_USER(:,nSub) = datetime(table_USER.USERPar_date,'InputFormat','dd-MM-yyyy') < dateshift(config.period_stop + calmonths(1),'end','month') & contains(table_USER.ParticipantId,subjects{nSub});
    keep_NHP(:,nSub) = datetime(table_NHPtest.nhpt_date,'InputFormat','dd-MM-yyyy') < dateshift(config.period_stop + calmonths(1),'end','month') & contains(table_NHPtest.ParticipantId,subjects{nSub});

end

keep_aqol = logical(sum(keep_aqol,2));
keep_ARAT = logical(sum(keep_ARAT,2));
keep_USER = logical(sum(keep_USER,2));
keep_NHP = logical(sum(keep_NHP,2));

table_aqol = table_aqol(keep_aqol,:);
table_ARAT = table_ARAT(keep_ARAT,:);
table_USER = table_USER(keep_USER,:);
table_NHPtest = table_NHPtest(keep_NHP,:);

%% CALCULATE AQOL-8D

% subjects
subjects = unique(table_aqol.ParticipantId);

% preallocation
qol = struct;

for nSub = 1:size(subjects,1)
    
    table_aqolSub = table_aqol(contains(table_aqol.ParticipantId,subjects{nSub}),:);

    for nMeas = 1:size(table_aqolSub,1)
        
        qol(nSub).date(nMeas) = datetime(table_aqolSub.AQol_date{nMeas},'InputFormat','dd-MM-yyyy');
        qol(nSub).IL(nMeas) = table_aqolSub.AQol30(nMeas) + table_aqolSub.AQol03(nMeas) + table_aqolSub.AQol15(nMeas) + table_aqolSub.AQol19(nMeas);
        qol(nSub).Sen(nMeas) = table_aqolSub.AQol28(nMeas) + table_aqolSub.AQol32(nMeas) + table_aqolSub.AQol11(nMeas);
        qol(nSub).Pain(nMeas) = table_aqolSub.AQol06(nMeas) + table_aqolSub.AQol22(nMeas) + table_aqolSub.AQol24(nMeas);
        qol(nSub).MH(nMeas) = table_aqolSub.AQol33(nMeas) + table_aqolSub.AQol12(nMeas) + table_aqolSub.AQol14(nMeas) + table_aqolSub.AQol16(nMeas) + table_aqolSub.AQol35(nMeas) + table_aqolSub.AQol18(nMeas) + table_aqolSub.AQol05(nMeas) + table_aqolSub.AQol08(nMeas);
        qol(nSub).Hap(nMeas) = table_aqolSub.AQol27(nMeas) + table_aqolSub.AQol17(nMeas) + table_aqolSub.AQol20(nMeas) + table_aqolSub.AQol25(nMeas);
        qol(nSub).SW(nMeas) = table_aqolSub.AQol26(nMeas) + table_aqolSub.AQol13(nMeas) + table_aqolSub.AQol07(nMeas);
        qol(nSub).Cop(nMeas) = table_aqolSub.AQol01(nMeas) + table_aqolSub.AQol29(nMeas) + table_aqolSub.AQol21(nMeas);
        qol(nSub).Rel(nMeas) = table_aqolSub.AQol23(nMeas) + table_aqolSub.AQol10(nMeas) + table_aqolSub.AQol31(nMeas) + table_aqolSub.AQol02(nMeas) + table_aqolSub.AQol34(nMeas) + table_aqolSub.AQol09(nMeas) + table_aqolSub.AQol04(nMeas);

    end
end

%% plot QOL in spider web
close all
cmap = parula(10);
cmap = cmap([1,9],:);

minmaxVal = [4 22; ...  % IL
    3 16;...            % Sen
    3 13; ...           % Pain
    8 41; ...           % MH
    4 20; ...           % Hap
    3 15; ...           % SW
    3 15; ...           % Cop
    7 34];              % Rel

Labels = {'Independent Living', 'Senses','Pain','Mental Health','Happiness',...
    'Self Worth','Coping','Relationships'};

for nSub = 1:size(subjects,1)

    data = qol(nSub);
    [dates,I] = sort(data.date);

    P = [data.IL; ...
           data.Sen; ...
           data.Pain; ...
           data.MH; ...
           data.Hap; ...
           data.SW; ...
           data.Cop; ...
           data.Rel];
    P = P(:,I); 

    figure(nSub)
    hold on
    for nMeas = 1:size(P,2)
        radarPlot(P(:,nMeas),minmaxVal,Labels,'LineWidth',2,'Color',cmap(nMeas,:))
    end
    title(subjects{nSub})
    legend(string(dates))

% %     save figure
figureName = fullfile(myDataPath.Figures,sprintf('%s_qol',subjects{nSub}));
set(gcf,'PaperPositionMode','auto')
print('-dpng','-r300',figureName)
print('-vector','-depsc',figureName)

fprintf('Figure is saved as .eps and .png in \n %s \n', ...
    figureName)

end

%% CALCULATE USER

% subjects
subjects = unique(table_USER.ParticipantId);

% preallocation
user = struct;

for nSub = 1:size(subjects,1)
    
    table_USERSub = table_USER(contains(table_USER.ParticipantId,subjects{nSub}),:);
    USERSub = table2array(table_USERSub(:,8:end));
    USERSub(USERSub == 999) = NaN;

    for nMeas = 1:size(table_USERSub,1)
        % date
        user(nSub).date(nMeas) = datetime(table_USERSub.USERPar_date{nMeas},'InputFormat','dd-MM-yyyy');
        % part 1A
        if sum(~isnan([USERSub(nMeas,1:4)])) > 2
            user(nSub).USER1A(nMeas) = mean([USERSub(nMeas,1:4)],'omitnan')/5*100;
        else
            user(nSub).USER1A(nMeas) = NaN;
        end

        % part 1B
        if sum(~isnan([USERSub(nMeas,6:12)])) > 4
            user(nSub).USER1B(nMeas) = mean([USERSub(nMeas,6:12)],'omitnan')/5*100;
        else
            user(nSub).USER1B(nMeas) = NaN;
        end

        % part 1 - total
        user(nSub).USER1(nMeas) = (user(nSub).USER1A(nMeas) + user(nSub).USER1B(nMeas)) / 2;

        % part 2
        user(nSub).USER2(nMeas) = mean([USERSub(nMeas,15:25)],'omitnan')/3*100;

        % part 3
        if sum(~isnan([USERSub(nMeas,27:36)])) > 5
            user(nSub).USER3(nMeas) = mean([USERSub(nMeas,27:36)],'omitnan')/4*100;
        else
            user(nSub).USER3(nMeas) = NaN;
        end
    end
end

%% plot USER in spider web
close all

minmaxVal = [0 100; ...  % 1
    0 100; ...           % 2
    0 100];              % 3

Labels = {'Frequency score', 'Limitations score','Satisfaction score'};

for nSub = 1:size(subjects,1)

    data = user(nSub);
    [dates,I] = sort(data.date);

    P = [data.USER1; ...
           data.USER2; ...
           data.USER3];
    P = P(:,I); 

    figure(nSub)
    hold on
    for nMeas = 1:size(P,2)
        radarPlot(P(:,nMeas),minmaxVal,Labels,'LineWidth',2,'Color',cmap(nMeas,:))
    end
    title(subjects{nSub})
    legend(string(dates))

% save figure
figureName = fullfile(myDataPath.Figures,sprintf('%s_user',subjects{nSub}));
set(gcf,'PaperPositionMode','auto')
print('-dpng','-r300',figureName)
print('-vector','-depsc',figureName)

fprintf('Figure is saved as .eps and .png in \n %s \n', ...
    figureName)

end

%% calculate ARAT

% subjects
subjects = unique(table_ARAT.ParticipantId);

% preallocation
ARAT = struct;

for nSub = 1:size(subjects,1)
    
    table_ARATSub = table_ARAT(contains(table_ARAT.ParticipantId,subjects{nSub}),:);
    
    for nMeas = 1:size(table_ARATSub,1)
        
        % date
        ARAT(nSub).date(nMeas) = datetime(table_ARATSub.ARAT_date{nMeas},'InputFormat','dd-MM-yyyy');
        
        ARAT(nSub).totalScore(nMeas) = table_ARATSub.ARAT_score_total(nMeas);

    end
end

%% plot ARAT
close all

minDate = dateshift(min(horzcat(ARAT.date)),'start','month');
maxDate = dateshift(max(horzcat(ARAT.date)),'end','month');

for nSub = 1:size(ARAT,2)
    data = ARAT(nSub);
    [dates,I] = sort(data.date);

    P = data.totalScore;
    P = P(:,I);

    figure(nSub),
    plot(dates,P,'-o','Color',cmap(1,:),'MarkerEdgeColor',cmap(1,:),'MarkerFaceColor',cmap(1,:))

    ylim([0 60])
    xlim([minDate maxDate])
    xlabel('Date')
    ylabel('Total ARAT score')
    title(subjects{nSub})
    
    h = gcf;
    h.Units = 'normalized';
    h.Position = [0.3536 0.5065 0.15 0.3889];

    % save figure
    figureName = fullfile(myDataPath.Figures,sprintf('%s_arat',subjects{nSub}));
    set(gcf,'PaperPositionMode','auto')
    print('-dpng','-r300',figureName)
    print('-vector','-depsc',figureName)

    fprintf('Figure is saved as .eps and .png in \n %s \n', ...
        figureName)
end

%% calculate NineHolePegtest

% subjects
subjects = unique(table_NHPtest.ParticipantId);

% preallocation
NHP = struct;

for nSub = 1:size(subjects,1)
    
    table_NHPSub = table_NHPtest(contains(table_NHPtest.ParticipantId,subjects{nSub}),:);
    
    for nMeas = 1:size(table_NHPSub,1)
        
        % date
        NHP(nSub).date(nMeas) = datetime(table_NHPSub.nhpt_date{nMeas},'InputFormat','dd-MM-yyyy');
        
        NHP(nSub).L1(nMeas) = table_NHPSub.nhpt_dur_left_1(nMeas);
        NHP(nSub).L2(nMeas) = table_NHPSub.nhpt_dur_left_2(nMeas);
        NHP(nSub).R1(nMeas) = table_NHPSub.nhpt_dur_right_1(nMeas);
        NHP(nSub).R2(nMeas) = table_NHPSub.nhpt_dur_right_2(nMeas);
    end
end

%% plot NHPtest
close all

cmap = parula(10);
cmap = cmap([8,3],:);

minDate = dateshift(min(horzcat(NHP.date)),'start','month');
maxDate = dateshift(max(horzcat(NHP.date)),'end','month');

for nSub = 1:size(NHP,2)
    data = NHP(nSub);
    [dates,I] = sort(data.date);

    P = [data.L1; data.L2; data.R1; data.R2];
    P = P(:,I);
    P(P == 999) = nan;

    ymin = floor(0.9*min(P(:)));
    ymax = ceil(1.1*max(P(:)));

    figure(nSub),
    ll = plot(dates,mean(P(1:2,:),1,'omitnan'),'-','Color',cmap(1,:));
    hold on
    plot(dates,P(1:2,:)','o','MarkerEdgeColor',cmap(1,:),'MarkerFaceColor',cmap(1,:))
    rr = plot(dates,mean(P(3:4,:),1,'omitnan'),'-','Color',cmap(2,:));
    plot(dates,P(3:4,:)','o','MarkerEdgeColor',cmap(2,:),'MarkerFaceColor',cmap(2,:))
    hold off

    ylim([ymin ymax])
    xlim([minDate maxDate])
    xlabel('Date')
    ylabel('Time (s)')
    title(subjects{nSub})
    legend([ll,rr],'left hand','right hand','Location','best')

    h = gcf;
    h.Units = 'normalized';
    h.Position = [0.3536 0.5065 0.15 0.3889];

    % save figure
    figureName = fullfile(myDataPath.Figures,sprintf('%s_nhp',subjects{nSub}));
    set(gcf,'PaperPositionMode','auto')
    print('-dpng','-r300',figureName)
    print('-vector','-depsc',figureName)

    fprintf('Figure is saved as .eps and .png in \n %s \n', ...
        figureName)
end
