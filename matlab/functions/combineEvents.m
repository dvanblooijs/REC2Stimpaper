function dataBase = combineEvents(dataBase,szReport,type)

% author: Dorien van Blooijs, June 2023
% 1. the PP Markers and SP Markers in log file are combined with the PP
% Markers and SP markers in each recording. There should be a difference of
% <1s, because it is both a kind of log note.
% 2. in the recording files, we annotated whether a SP/PP Marker was a test
% or a seizure. So the Markers that were no seizures, should be removed
% from the data.
% 3. in the recording files, seizures are annotated if there was a seizure
% visible in time domain. This is additional to the PP/SP Markers and could
% also be annotated in time triggered data. We combine this data with the
% PP/SP markers if there is <2miutes between the SP/PP Marker and the
% annotated seizure.

% type = Patient Marker or Detection
if strcmpi(type,'PatientMarker')
    eventTypeLog = {'PP Marker','SP Marker','SPPatientMarker','PPPatientMarker'};
    eventTypeRec = {'seizure'};
elseif strcmpi(type,'Detection')
    eventTypeLog = {'Detection'};
    eventTypeRec = {'Detection'};
else
    error('type should be either Detection or PatientMarker')
end

%% first combine the PP/SP markers of the recordings and logfiles
for nVisit = 1:size(dataBase.visit,2)

    if ~isempty(dataBase.visit(nVisit).log)

        % find the log files in which the note is either SP Marker or PP
        % Marker
        log = dataBase.visit(nVisit).log;
        [log(:).double] = deal(0);
        idxLog = contains({dataBase.visit(nVisit).log(:).event},eventTypeLog,"IgnoreCase",true);
        log = log(idxLog);
    else
        log = struct('filenum',[],'filetype',[],'date_start',[],'dateConvertSP',[],'dateConvertSPstr',[],'date_stop',[],'event',[],'subevent',[],'double',[]);
    end

    if ~isempty(dataBase.visit(nVisit).rec)

        % find the recordings in which the event is either SPPatientMarker
        % or PPPatientMarker (or Detection)
        rec = dataBase.visit(nVisit).rec;
        [rec(:).double] = deal(0);
        idxRec = contains(vertcat(dataBase.visit(nVisit).rec(:).event),eventTypeLog,"IgnoreCase",true);
        rec = rec(idxRec);

        if strcmp(type,'PatientMarker')
            % find the recordings with recordings in which the subevent is Seizure
            recsz = dataBase.visit(nVisit).rec;
            [recsz(:).double] = deal(0);
            idxRecsz = contains(vertcat(dataBase.visit(nVisit).rec(:).subevent),eventTypeRec,"IgnoreCase",true) & ...
                contains(vertcat(dataBase.visit(nVisit).rec(:).event),'annotation',"IgnoreCase",true);
            recsz = recsz(idxRecsz);
        end

    else
        rec = struct('filenum',[],'filetype',[],'date_start',[],'dateConvertSP',[],'dateConvertSPstr',[],'date_stop',[],'event',[],'subevent',[],'double',[]);
        recsz = struct('filenum',[],'filetype',[],'date_start',[],'dateConvertSP',[],'dateConvertSPstr',[],'date_stop',[],'event',[],'subevent',[],'double',[]);
    end

    % step 1: combine all PP Markers and SP Markers of log-file and recordings and
    % remove duplicates (or Detections)
    if size(rec,2) >0 && ~isempty(rec(1).filenum) && size(log,2) >0 && ~isempty(log(1).filenum) % log and rec present
        for nLog = 1:size(log,2)
            if any(abs(repmat(log(nLog).dateConvertSP,size(rec,2),1) - vertcat(rec(:).dateConvertSP)) < seconds(1))
                idxRec = abs(repmat(log(nLog).dateConvertSP,size(rec,2),1) - vertcat(rec(:).dateConvertSP)) < seconds(1);

                log(nLog).double = 1;
                [rec(idxRec).double] = deal(1);
            end
        end

        reclogTmp = horzcat(log([log(:).double] == 0), rec);

    elseif (size(rec,2) == 0 || isempty(rec(1).filenum)) && size(log,2) >0 && ~isempty(log(1).filenum) % only log present
        reclogTmp = horzcat(log([log(:).double] == 0));
    elseif size(rec,2) >0 && ~isempty(rec(1).filenum) && (size(log,2) == 0 || isempty(log(1).filenum)) % only rec present
        reclogTmp = horzcat(rec([rec(:).double] == 0));
    else % no rec or log present
        reclogTmp = struct();
    end

    if strcmp(type,'PatientMarker')
        % step2: remove all non seizure SP/PP markers, so keep n/a or seizure
        if isfield(reclogTmp ,'subevent')
            idxSz = strcmpi(vertcat(reclogTmp(:).subevent),{'seizure'});
            idxna = strcmpi(vertcat(reclogTmp(:).subevent),{'n/a'});
            idx = sum([idxSz,idxna],2)>0;

            reclogTmp = reclogTmp(idx);
        end

        % step3: combine all annotated seizures and the PP/SP markers of the
        % combined log&rec-file. A seizure is bothed marked by the patient and
        % annotated if there is less than 2 minutes between both events.
        [reclogTmp(:).double] = deal(0);

        if size(recsz,2) >0 && ~isempty(recsz(1).filenum)
            for nLog = 1:size(reclogTmp,2)

                if any(abs(repmat(reclogTmp(nLog).dateConvertSP,size(recsz,2),1) - vertcat(recsz(:).dateConvertSP)) < minutes(2) & ...
                        vertcat(recsz(:).double) ~= 1)

                    [idxRecsz] = find(abs(repmat(reclogTmp(nLog).dateConvertSP,size(recsz,2),1) - vertcat(recsz(:).dateConvertSP)) < minutes(2) & ...
                        vertcat(recsz(:).double) ~= 1,1,'first');

                    reclogTmp(nLog).double = 1;
                    recsz(idxRecsz).double = 1;

                end
            end

            reclogTmpsz = horzcat(reclogTmp([reclogTmp(:).double] == 0), recsz);

        else
            reclogTmpsz = horzcat(reclogTmp([reclogTmp(:).double] == 0));
        end

        if isfield(reclogTmp,'dateConvertSP')
            [~,I] = sort([reclogTmpsz(:).dateConvertSP]);
            dataBase.visit(nVisit).(type) = reclogTmpsz(I);
        end
    else
        if isfield(reclogTmp,'dateConvertSP')
            [~,I] = sort([reclogTmp(:).dateConvertSP]);
            dataBase.visit(nVisit).(type) = reclogTmp(I);
        end
    end

end % for-loop each visit

%% combine with seizure report
% only relevant for PatientMarker, and not for Detection
if strcmp(type,'PatientMarker')

    % categorize seizure report per visit
    for nVisit = 2:size(dataBase.visit,2)
        idx = (vertcat(szReport(:).date) > dataBase.visit(nVisit-1).visitdate & ...
            vertcat(szReport(:).date) <= dataBase.visit(nVisit).visitdate) ;

        dataBase.visit(nVisit).szReport = szReport(idx);
    end

    % 1. it depends on the certainty of the time of seizure report, what the
    %   next steps will be:
    %   1a. the time is certain, then the seizure report and log should be within
    %       1 hour difference
    %   1b. when the time is uncertain, the seizure report and log should be
    %       within the same day
    %   1c. unrecorded seizure diary reports should be added to the
    %       database anyhow

    for nVisit = 1:size(dataBase.visit,2)

        if ~isempty(dataBase.visit(nVisit).szReport)
            [dataBase.visit(nVisit).szReport(:).double] = deal(0);
           
            if ~isempty(dataBase.visit(nVisit).PatientMarker)
                [dataBase.visit(nVisit).PatientMarker(:).double] = deal(0);

                % /// certain recorded (or NaN recorded) seizure diary reports --> should be within <1
                % hours from logRec-SP/PPmarkers
                idxCertainRec = find(vertcat(dataBase.visit(nVisit).szReport.certain) == 1 & ...
                    (vertcat(dataBase.visit(nVisit).szReport.recorded) == 1 | ...
                    isnan(vertcat(dataBase.visit(nVisit).szReport.recorded))));
                for nLog = 1:size(idxCertainRec,1)
                    if any(abs(vertcat(dataBase.visit(nVisit).PatientMarker.dateConvertSP) - ...
                            repmat(dataBase.visit(nVisit).szReport(idxCertainRec(nLog)).date,size(dataBase.visit(nVisit).PatientMarker,2),1)) < hours(1))
                        [~,idx] = min(abs(vertcat(dataBase.visit(nVisit).PatientMarker.dateConvertSP) - ...
                            repmat(dataBase.visit(nVisit).szReport(idxCertainRec(nLog)).date,size(dataBase.visit(nVisit).PatientMarker,2),1)));

                        dataBase.visit(nVisit).PatientMarker(idx).double = 1;
                        dataBase.visit(nVisit).szReport(idxCertainRec(nLog)).double = 1;

                    end
                end

                % /// uncertain recorded (or NaN recorded) seizure diary reports --> should be
                % within the same day as logRec-SP/PPmarkers
                idxUnCertainRec = find(vertcat(dataBase.visit(nVisit).szReport.certain) ~= 1 & ...
                    (vertcat(dataBase.visit(nVisit).szReport.recorded) == 1 | ...
                    isnan(vertcat(dataBase.visit(nVisit).szReport.recorded))));
                for nLog = 1:size(idxUnCertainRec,1)
                    if any(dataBase.visit(nVisit).szReport(idxUnCertainRec(nLog)).date - ...
                            dateshift(vertcat(dataBase.visit(nVisit).PatientMarker.dateConvertSP),'start','day') < days(1) & ...
                            dataBase.visit(nVisit).szReport(idxUnCertainRec(nLog)).date - ...
                            dateshift(vertcat(dataBase.visit(nVisit).PatientMarker.dateConvertSP),'start','day') >= 0)

                        [~,idx] = min(abs(dataBase.visit(nVisit).szReport(idxUnCertainRec(nLog)).date - ...
                            vertcat(dataBase.visit(nVisit).PatientMarker.dateConvertSP)));

                        dataBase.visit(nVisit).PatientMarker(idx).double = 1;
                        dataBase.visit(nVisit).szReport(idxUnCertainRec(nLog)).double = 1;

                    end
                end
            end
            % /// unrecorded seizures in diary reports should be included
            % in the dataBase.

            % make struct with fields similar to
            % dataBase.visit.PatientMarker
            szReportTmp = struct();
            nszReport = size(find(vertcat(dataBase.visit(nVisit).szReport(:).double) == 0),1);
            [szReportTmp(1:nszReport).filenum] = deal(0);
            [szReportTmp(1:nszReport).filetype] = deal('diary');
            [szReportTmp(1:nszReport).date_start] = dataBase.visit(nVisit).szReport(vertcat(dataBase.visit(nVisit).szReport(:).double) == 0).date;
            [szReportTmp(1:nszReport).dateConvertSP] = dataBase.visit(nVisit).szReport(vertcat(dataBase.visit(nVisit).szReport(:).double) == 0).date;
            [szReportTmp(1:nszReport).dateConvertSPstr] = dataBase.visit(nVisit).szReport(vertcat(dataBase.visit(nVisit).szReport(:).double) == 0).datestr;
            [szReportTmp(1:nszReport).date_stop] = deal(NaT);
            [szReportTmp(1:nszReport).event] = deal('seizure');
            [szReportTmp(1:nszReport).subevent] = deal('seizure');
            [szReportTmp(1:nszReport).double] = dataBase.visit(nVisit).szReport(vertcat(dataBase.visit(nVisit).szReport(:).double) == 0).double;

            reclogTmpdiary = horzcat(dataBase.visit(nVisit).PatientMarker, ...
                szReportTmp);
            [~,I] = sort([reclogTmpdiary(:).dateConvertSP]);
            dataBase.visit(nVisit).reclogszDiary = reclogTmpdiary(I);

        else

            reclogTmpdiary = horzcat(dataBase.visit(nVisit).PatientMarker);

            if isfield(reclogTmpdiary,'dateConvertSP')
                [~,I] = sort([reclogTmpdiary(:).dateConvertSP]);
                dataBase.visit(nVisit).reclogszDiary = reclogTmpdiary(I);
            end
        end
    end
end