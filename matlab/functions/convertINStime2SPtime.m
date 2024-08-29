function dataBase = convertINStime2SPtime(dataBase)

% author: Dorien van Blooijs
% date: June 2023


%% LOAD EVENTS PER VISIT

% for each visit
for nVisit = 1:size(dataBase.visit,2)
    
    % time difference between Sense Programmer and Implanted
    % Neurostimulator (INS)
    timediffSpIns = dataBase.visit(nVisit).timediffSpIns;

    % for each recording in a visit, load the event file
    for nRec = 1:size(dataBase.visit(nVisit).rec,2)

            if ~isempty(timediffSpIns)
                dataBase.visit(nVisit).rec(nRec).dateConvertSP = dataBase.visit(nVisit).rec(nRec).date_start + timediffSpIns;
            else
                dataBase.visit(nVisit).rec(nRec).dateConvertSP = dataBase.visit(nVisit).rec(nRec).date_start ;
            end
            
            dataBase.visit(nVisit).rec(nRec).dateConvertSPstr = string(dataBase.visit(nVisit).rec(nRec).dateConvertSP);

    end % for-loop rec files
end % for-loop visit

end