function dataBase = loadVisits(myDataPath, cfg)
% author: Dorien van Blooijs
% date: June 2023

%% load all visit folders

% pre-allocation
dataBase = struct();
visit = struct();

dataBase.sub_label = cfg(1).sub_label;
dataBase.ses_label = cfg(1).ses_label;

% pathname of log-files
sourcepathname = fullfile(myDataPath.dataPath,'sourcedata',cfg(1).sub_label,cfg(1).ses_label,'ieeg'); % log files are only available in sourcedata

% select visitfolders
visitfolders = dir(sourcepathname);
idxRec = contains({visitfolders(:).name},'Session');
visitfolders = visitfolders(idxRec);

% for each visit
for nVisit = 1:size(visitfolders,1)

    visit(nVisit).visitfolder = replace(visitfolders(nVisit).name,'Session_','rec-');

    % FIND LOG FILE
    logfolder = dir(fullfile(visitfolders(nVisit).folder,visitfolders(nVisit).name));
    idxLogfile = contains({logfolder(:).name},'LOG.txt');

    if sum(idxLogfile) < 1 % if there is no logfile, for example when there is only realtime recording (during surgery)

        % reconstruct time of visit by calculating visitdates from
        % txt-files and use recording of first file, but create
        % visit 10 minutes before this file
        idxTxt = find(contains({logfolder(:).name},'txt')==1);

        % pre-allocation
        visitdate = NaT(size(idxTxt)); visitname = cell(size(idxTxt));

        for nTxt = 1:size(idxTxt,2)

            digitfile = regexp(logfolder(idxTxt(nTxt)).name,'[0-9 _]');
            visitname{nTxt} = logfolder(idxTxt(nTxt)).name(7:digitfile(end-2));
            visitdate(nTxt) = datetime(visitname{nTxt},'inputformat','yyyy_MM_dd_HH_mm_ss');
        end

        visitdate = sort(visitdate,'ascend');
        visit(nVisit).visitdate = visitdate(1) - minutes(10);

    else % if there is at least one logfile

        numLog = find(idxLogfile==1);

        % pre-allocation
        logfiles = struct();

        for nLog = 1:size(numLog,2) % for each log-file

            filename = fullfile(logfolder(numLog(nLog)).folder,logfolder(numLog(nLog)).name);
            [~,fname,~] = fileparts(filename);

            visitname = extractBefore(fname(7:end),'_LOG');
            visitdate = datetime(visitname,'inputformat','yyyy_MM_dd_HH_mm_ss');

            logfiles(nLog).visitdate = visitdate;

        end % for-loop for each logfile

        visit(nVisit).visitdate = min([logfiles(:).visitdate]);

    end % if there is a logfile or not
end % for each visit

dataBase.visit = visit;

disp('All visits are loaded')

