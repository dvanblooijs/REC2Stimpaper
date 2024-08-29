function dataBase = calcLDAperformance(dataBase)

% ASSUMPTIONS:
% - in case of recorded and annotated seizure: 
%       TP when detection is within -10s:end annotated seizure
% - in case of patient marker (push button) in log note/recording
%       TP when detection is within 10min of seizure
% - in case of diary report
%       TP when detection is within 1 hour of seizure

%% for each visit   

for nVisit = 1:size(dataBase.visit,2)

    detections = dataBase.visit(nVisit).Detection;
    seizures = dataBase.visit(nVisit).reclogszDiary;

    if ~isempty(detections) && ~isempty(seizures)
        detPerformance = cell(size(detections));
        [detPerformance{:}] = deal('FP');

        szPerformance = cell(size(seizures));
        [szPerformance{:}] = deal('FN');

        timediffSpIns = dataBase.visit(nVisit).timediffSpIns;

        for nSz = 1:size(seizures,2)
            filetype = seizures(nSz).filetype;
            event = seizures(nSz).event;

            if strcmpi(filetype,'lognote')
                if any(abs([detections.dateConvertSP] - seizures(nSz).dateConvertSP) < minutes(10))

                    % set seizure to true positive
                    szPerformance{nSz} = 'TP';

                    % find accompanying detection
                    idx = find(abs([detections.dateConvertSP] - seizures(nSz).dateConvertSP) < minutes(10));
                    [~, minIdx] = min(abs([detections.dateConvertSP] - seizures(nSz).dateConvertSP));

                end

            elseif strcmpi(filetype,'Recording')
                if strcmpi(event,'annotation')

                    if any([detections.dateConvertSP] > seizures(nSz).dateConvertSP - seconds(30) & ...
                            [detections.dateConvertSP] < seizures(nSz).date_stop + timediffSpIns)

                        % set seizure to true positive
                        szPerformance{nSz} = 'TP';

                        % find accompanying detection
                        idx = find([detections.dateConvertSP] > seizures(nSz).dateConvertSP - seconds(10) & ...
                            [detections.dateConvertSP] < seizures(nSz).date_stop + timediffSpIns);
                        [~, minIdx] = min(abs([detections.dateConvertSP] - seizures(nSz).dateConvertSP));

                    end

                else % patient marker but no annotation in the recording
                    if any(abs([detections.dateConvertSP] - seizures(nSz).dateConvertSP) < minutes(10))

                        % set seizure to true positive
                        szPerformance{nSz} = 'TP';

                        % find accompanying detection
                        idx = find(abs([detections.dateConvertSP] - seizures(nSz).dateConvertSP) < minutes(10));
                        [~, minIdx] = min(abs([detections.dateConvertSP] - seizures(nSz).dateConvertSP));

                    end
                end

            elseif strcmpi(filetype,'diary')
                if any(abs([detections.dateConvertSP] - seizures(nSz).dateConvertSP) < hours(1))

                    % set seizure to true positive
                    szPerformance{nSz} = 'TP';

                    % find accompanying detection
                    idx = find(abs([detections.dateConvertSP] - seizures(nSz).dateConvertSP) < hours(1));
                    [~, minIdx] = min(abs([detections.dateConvertSP] - seizures(nSz).dateConvertSP));

                end
            end

            % set detection to TP/TPtwice
            if strcmpi(szPerformance{nSz},'TP')

                detPerformance{minIdx} = 'TP';
                % set date to NaT, so that this specific detection cannot be used for multiple seizures
                detections(minIdx).dateConvertSP = NaT;

                % if more than one detection, set these detections to TPtwice
                if size(idx,2) >1
                    otherIdx = setdiff(idx,minIdx);
                    [detPerformance{otherIdx}] = deal('TPtwice');
                end
            end

        end % for-loop seizures

        [dataBase.visit(nVisit).Detection.performance] = deal(detPerformance{:});
        [dataBase.visit(nVisit).reclogszDiary.performance] = deal(szPerformance{:});

    elseif ~isempty(detections) && isempty(seizures)
        
        detPerformance = cell(size(detections));
        [detPerformance{:}] = deal('FP');

        [dataBase.visit(nVisit).Detection.performance] = deal(detPerformance{:});

    elseif isempty(detections) && ~isempty(seizures)
        
        szPerformance = cell(size(seizures));
        [szPerformance{:}] = deal('FN');

        [dataBase.visit(nVisit).reclogszDiary.performance] = deal(szPerformance{:});

    elseif isempty(detections) && isempty(seizures)
        % do nothing
    end
end