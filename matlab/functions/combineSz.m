function dataBase = combineSz(dataBase)

for nVisit = 1:size(dataBase.visit,2)

    if ~isempty(dataBase.visit(nVisit).recSz) && ~isempty(dataBase.visit(nVisit).logP)
        dateRecSz = [dataBase.visit(nVisit).recSz(:).dateConvertSP];
        datelogP = [dataBase.visit(nVisit).logP(:).dateConvertSP];

        for nSz = 1:size(datelogP,2)
            if sum(abs( dateRecSz - repmat(datelogP(nSz),1,size(dateRecSz,2))) < 2/(24*60*60))

                dataBase.visit(nVisit).logP(nSz).double = 1;

            else
                dataBase.visit(nVisit).logP(nSz).double = 0;

            end
        end
    elseif isempty(dataBase.visit(nVisit).recSz) && ~isempty(dataBase.visit(nVisit).logP)
        datelogP = [dataBase.visit(nVisit).logP(:).dateConvertSP];
        for nSz = 1:size(datelogP,2)
            dataBase.visit(nVisit).logP(nSz).double = 0;
        end
    end
end

%% combine seizures into one file

for nVisit = 1:size(dataBase.visit,2)
    if ~isempty(dataBase.visit(nVisit).recSz) && ~isempty(dataBase.visit(nVisit).logP)
        dateRecSz = [dataBase.visit(nVisit).recSz(:).dateConvertSP];
        markerRecSz = horzcat(dataBase.visit(nVisit).recSz(:).subevent);
        idxRec = strcmpi(markerRecSz,'seizure');

        datelogP = [dataBase.visit(nVisit).logP(:).dateConvertSP];
        doublelogP = [dataBase.visit(nVisit).logP(:).double];
        idxLog = doublelogP == 0;

        dataBase.visit(nVisit).sz = [dateRecSz(idxRec), datelogP(idxLog)];

    elseif ~isempty(dataBase.visit(nVisit).recSz) && isempty(dataBase.visit(nVisit).logP)

        dateRecSz = [dataBase.visit(nVisit).recSz(:).dateConvertSP];
        markerRecSz = horzcat(dataBase.visit(nVisit).recSz(:).subevent);
        idxRec = strcmpi(markerRecSz,'seizure');

        dataBase.visit(nVisit).sz = [dateRecSz(idxRec)];

    elseif isempty(dataBase.visit(nVisit).recSz) && ~isempty(dataBase.visit(nVisit).logP)

        datelogP = [dataBase.visit(nVisit).logP(:).dateConvertSP];
        doublelogP = [dataBase.visit(nVisit).logP(:).double];
        idxLog = doublelogP == 0;

        dataBase.visit(nVisit).sz = [datelogP(idxLog)];
    end
end


