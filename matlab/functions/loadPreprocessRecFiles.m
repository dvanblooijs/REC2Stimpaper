function dataBase = loadPreprocessRecFiles(myDataPath,dataBase)

% author: Dorien van Blooijs
% date: June 2023

% this function loads event files of all recordings transferred from the
% Activa PC+S to the computer during all visits in a specific time period.
% In these event-files, specific events (seizures/interictal) were
% annotated while converting the raw data to BIDS structure.

% INPUT:
% - myDataPath: struct, containing the fields:
%   - dataPath: string with repository with the data in BIDS
%   - derivPath: string, with repository to save derivatives
%   - Figures: string with repository to save figures
% - dataBase: struct, containing the fields:
%   - sub_label: string with subject label
%   - ses_label: string with ses label
%   - visit: struct containing the fields:
%       - visitname: string with repository name of this visit
%       - visitdate: datetime with the date of this visit
%       - visitdatestr: string of the datetime of this visit
%       - logfiles: struct with information of all log-files during each
%       visit
%       - log: struct with all log-files combined, containing the fields:
%           - visit: string with visitname
%           - visitdate: datetime of the visit date
%           - visitdatestr: string of datetime of visit date
%           - logNotes: cell with all log notes
%           - log_dateswData: datetime array with dates of which events are
%           logged. This is very important to make a difference between
%           dates in which no events are logged due to full memory or dates
%           when no events were logged because there were no events.

% OUTPUT:


%% LOAD EVENTS PER VISIT

% for each visit
for nVisit = 1:size(dataBase.visit,2)
    
    rec = struct();
    count = 1; % a recording can contain multiple patient markers (PP/SP), so count from 1 in each visit

    % select event files
    eventsfiles = dir(fullfile(myDataPath.dataPath,dataBase.sub_label, dataBase.ses_label,'ieeg',dataBase.visit(nVisit).visitfolder));
    idxEvents = contains({eventsfiles(:).name},'events.tsv') & ~contains({eventsfiles(:).name},'~lock');
    eventsfiles = eventsfiles(idxEvents);

    % for each recording in a visit, load the event file
    for nEvent = 1:size(eventsfiles,1)

        file = eventsfiles(nEvent).name;
        tb_events = read_tsv(fullfile(eventsfiles(nEvent).folder,eventsfiles(nEvent).name));

        %% load and preprocess markers from the recorded epochs

        % CONVERT ONSET-TIME FROM CELL TO DATETIME ARRAY
        onset_time = NaT(1,1);
        if iscell(tb_events.onset_time)
            for nMarker = 1:size(tb_events,1)
                if strcmp(tb_events.onset_time{nMarker},'n/a')
                    onset_time(nMarker) = NaT;
                else
                    onset_time(nMarker) = datetime(tb_events.onset_time{nMarker});
                end
            end
        else
            onset_time = datetime(tb_events.onset_time);
        end

        for nMarker = 1:size(tb_events,1)
            tmp = extractBetween(file,'run-','_events');
            rec(count).filenum = tmp{1};
            rec(count).filetype = 'Recording';
            
            if isnat(onset_time(nMarker))
                if isnan(tb_events.onset(nMarker)) && ...
                        strcmp(tb_events.sub_type{nMarker},'seizure') && ...
                        strcmp(tb_events.notes{nMarker},'no seizure annotated')
                    rec(count).date_start = min(onset_time);
                    sub_type = 'interictal';
                else
                    rec(count).date_start = min(onset_time) + seconds(tb_events.onset(nMarker));
                    sub_type = tb_events.sub_type(nMarker);
                end
            else
                rec(count).date_start = min(onset_time) + seconds(tb_events.onset(nMarker));
                sub_type = tb_events.sub_type(nMarker);
            end

            if isnan(tb_events.offset(nMarker))
                rec(count).date_stop = NaT;
            else
                rec(count).date_stop = rec(count).date_start + seconds(tb_events.offset(nMarker));
            end
            
            rec(count).event = tb_events.trial_type(nMarker);
            rec(count).subevent = sub_type;

            count = count+1;

        end % for-loop nMarker in event file
    end % for-loop event file

    if isfield(rec,'date_start')
        % sort dates chronologically
        [~,I] = sort(vertcat(rec(:).date_start),'ascend');
        dataBase.visit(nVisit).rec = rec(I);
    else

    end
end % for-loop visit

% %% load and preprocess SP and PP markers from the recorded epochs (for seizures)
% 
% % for each visit
% for nVisit = 1:size(dataBase.visit,2)
%     % for each recording per visit
%     for nRec = 1:size(dataBase.visit(nVisit).epochs,2)
%         count = 1; % a recording can contain multiple patient markers (PP/SP), so count from 1 in each recording
% 
%         % time difference between Sense Programmer and Implanted
%         % Neurostimulator (INS)
%         timediffSpIns = dataBase.visit(nVisit).log.timediffSpIns;
% 
%         % CONVERT ONSET-TIME FROM CELL TO DATETIME ARRAY
%         onset_time = NaT(1,1);
%         if iscell(dataBase.visit(nVisit).epochs(nRec).events.onset_time)
%             for iEvent = 1:size(dataBase.visit(nVisit).epochs(nRec).events.onset_time,1)
%                 if strcmp(dataBase.visit(nVisit).epochs(nRec).events.onset_time{iEvent},'n/a')
%                     onset_time(iEvent) = NaT;
%                 else
%                     onset_time(iEvent) = datetime(dataBase.visit(nVisit).epochs(nRec).events.onset_time(iEvent));
%                 end
%             end
%         else
%             onset_time = dataBase.visit(nVisit).epochs(nRec).events.onset_time;
%         end
% 
%         if any(contains(dataBase.visit(nVisit).epochs(nRec).events.trial_type,'PatientMarker'))
% 
%             idxPP = find(contains(dataBase.visit(nVisit).epochs(nRec).events.trial_type,'PatientMarker'));
% 
%             for nPP = 1:size(idxPP,1)
%                 dataBase.visit(nVisit).recP(nRec).filenum(count) = nRec;
%                 dataBase.visit(nVisit).recP(nRec).filetype{count} = 'Recording';
%                 dataBase.visit(nVisit).recP(nRec).date_start(count) = onset_time(idxPP(nPP));
%                 %                 dataBase.visit(nVisit).recP(nRec).date_startstr{count} = string(dataBase.visit(nVisit).recP(nRec).date_start(count)) ;
%                 dataBase.visit(nVisit).recP(nRec).dateConvertSP(count) = onset_time(idxPP(nPP)) + timediffSpIns;
%                 %                 dataBase.visit(nVisit).recP(nRec).dateConvertSPstr{count} = string(dataBase.visit(nVisit).recP(nRec).dateConvertSP(count) );
% 
%                 dataBase.visit(nVisit).recP(nRec).date_stop(count) = NaT;
%                 %                 dataBase.visit(nVisit).recP(nRec).date_stopstr{count} = string(dataBase.visit(nVisit).recP(nRec).date_stop(count));
%                 if strcmp(dataBase.visit(nVisit).epochs(nRec).events.trial_type(idxPP(nPP)),'PPPatientMarker')
%                     dataBase.visit(nVisit).recP(nRec).event{count} = 'PP Marker';
%                     dataBase.visit(nVisit).recP(nRec).subevent{count} = dataBase.visit(nVisit).epochs(nRec).events.sub_type{idxPP(nPP)};
%                 elseif strcmp(dataBase.visit(nVisit).epochs(nRec).events.trial_type(idxPP(nPP)),'SPPatientMarker')
%                     dataBase.visit(nVisit).recP(nRec).event{count} = 'SP Marker';
%                     dataBase.visit(nVisit).recP(nRec).subevent{count} = dataBase.visit(nVisit).epochs(nRec).events.sub_type{idxPP(nPP)};
%                 end
%                 count = count+1;
%             end
%         end
%     end % for-loop epochs
% end % for-loop visit

end  % end function

