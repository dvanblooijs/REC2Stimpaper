function dataBase = loadDetAlg(myDataPath,cfg,dataBase)

dataBase.visit(1).detAlg = zeros(1,19);

for nVisit = 2:size(dataBase.visit,2)

    files = dir(fullfile(myDataPath.dataPath,cfg.sub_label,cfg.ses_label,...
        'ieeg',dataBase.visit(nVisit).visitfolder));
    idxDetAlg = contains({files(:).name},'detAlg.tsv');
    files = files(idxDetAlg);

    % select a file that is not the first or last date (because detection
    % algorithm might be different there)
    for nFile = 1:size(files,1)

        recDateTmp = extractBetween(files(nFile).name,'run-','_detAlg');
        recDate = datetime(recDateTmp{1},'InputFormat','uuuuMMddHHmmss');

        if dateshift(recDate,'start','day') > dateshift(dataBase.visit(nVisit-1).visitdate,'start','day') && ...
                dateshift(recDate,'start','day') < dateshift(dataBase.visit(nVisit).visitdate,'start','day')

            tb_detAlg = read_tsv(fullfile(files(nFile).folder,files(nFile).name));

            detAlg = table2array(tb_detAlg);
            dataBase.visit(nVisit).detAlg = detAlg(2:end);

            break
        end
    end

    if isempty(dataBase.visit(nVisit).detAlg)
        tb_detAlg = read_tsv(fullfile(files(1).folder,files(1).name));

        detAlg = table2array(tb_detAlg);
        dataBase.visit(nVisit).detAlg = detAlg(2:end);

    end
end