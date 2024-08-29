function sortedReport = loadPreprocessSzDiary(myDataPath,cfg)

% only use type 1(seizure)  or type 3 (twitches), type == 2 --> aura

%% load Castor Export
% Use the latest export!
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
idx = contains({files(:).name},'Aanvalsdagboek');

% Load excel file
table = readtable(fullfile(files(idx).folder, files(idx).name),'VariableNamingRule','preserve');
Castor = table2struct(table);

%% convert table to useful data per patient

CastorIDs = unique({Castor(:).CastorParticipantID});

% find subject, in Castor it is REC2Stim003 instead of REC2Stim03
sub_labeldigits = regexp(cfg.sub_label,'\d','match');
subj = find(contains(CastorIDs,['REC2Stim00', sub_labeldigits{end}]));

fprintf('---- Subject %s ----\n',CastorIDs{subj})

report = struct;
count = 1;

% find which rows are completed for specific subject
selectDiary = find(strcmp({Castor.CastorParticipantID},CastorIDs{subj}));

% for each time a diary is filled in Castor
for nn = 1:size(selectDiary,2)

    % In Castor, 7 sets of 10 seizures can be annotated, so m=1
    % contains the seizures 1-10, m=2 contains seizures 11-20 etc.
    % Increase these numbers if you would like to add more than 70
    % seizures!
    for m = 1:7
        for k = 1:10 % so k=1 is the first of a set of 10.

            type =  Castor(selectDiary(nn)).(['sz_diary_',num2str(m),'_Voorval',num2str((m-1)*10+k),'_Type']);
            if type == 1 || type == 3 % seizure || twitches, type == 2 --> aura

                orig_time = Castor(selectDiary(nn)).(['sz_diary_',num2str(m),'_Voorval',num2str((m-1)*10+k),'_Tijd_hh_mm_']);
                [convertTime,certain] = convertCastorTime(orig_time);

                for ii = 1:size(convertTime,1)

                    % change date string to datetime if it is not
                    % datetime yet
                    if isdatetime(Castor(selectDiary(nn)).(['sz_diary_',num2str(m),'_Voorval',num2str((m-1)*10+k),'_Datum']))
                        % don't do anything, because we want to work
                        % with datetimes
                    elseif ischar(Castor(selectDiary(nn)).(['sz_diary_',num2str(m),'_Voorval',num2str((m-1)*10+k),'_Datum']))
                        Castor(selectDiary(nn)).(['sz_diary_',num2str(m),'_Voorval',num2str((m-1)*10+k),'_Datum']) = datetime(Castor(selectDiary(nn)).(['sz_diary_',num2str(m),'_Voorval',num2str((m-1)*10+k),'_Datum']),'Format','dd-MM-yyyy');
                    end

                    if isnat(Castor(selectDiary(nn)).(['sz_diary_',num2str(m),'_Voorval',num2str((m-1)*10+k),'_Datum'])) % in the rare situation that no date is filled in, use the date of previous report
                        report(count).szDate = report(count-1).szDate;
                    else
                        report(count).szDate = string(Castor(selectDiary(nn)).(['sz_diary_',num2str(m),'_Voorval',num2str((m-1)*10+k),'_Datum']));
                    end

                    report(count).time = convertTime{ii};
                    report(count).recorded = Castor(selectDiary(nn)).(['sz_diary_',num2str(m),'_Voorval',num2str((m-1)*10+k),'_OpgenomenMetKastje_']); % if patient did not fill in anything, the value is NaN
                    report(count).certain = certain(ii);
                    report(count).date = datetime(append(report(count).szDate, ' ', report(count).time),'InputFormat','dd-MM-yyyy HH:mm');
                    report(count).datestr = string(report(count).date);
                    
                    count = count+1;
                end
            end
        end
    end
end

% sort report in chronological order
T = struct2table(report); % convert the struct array to a table
sortedT = sortrows(T, 'date'); % sort the table by 'datenum'
sortedReport = table2struct(sortedT); % change it back to struct array

end