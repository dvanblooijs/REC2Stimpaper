% configuration sensing and stimulation electrodes


function config = config_sensStim(subj)

% preprocess subj into right format
subjtmp = replace(subj,'sub-','');
subjtmp = replace(subjtmp,'REC2Stim','');
subjnum = str2double(subjtmp);

subj = ['REC2Stim0' num2str(subjnum)];

switch (subj)
    case {'REC2Stim01'}

        config.stimElec = {''}; % {'E2-E3','E9-E10'}; % 17-3-2022 started open-loop stimulation
        config.sensElec = {'E9-E10'};

    case {'REC2Stim03'}

        config.stimElec = {'E2-E3'}; % {'E0-E1','E2-E3'}; after 24-12-2021:E0-E1
        config.sensElec = {'E9-E10'};

    case {'REC2Stim05'}

        config.stimElec = {'E2-E3'};
        config.sensElec = {'E10-E11'};

    case {'REC2Stim06'}

        config.stimElec = {'E1-E2'};
        config.sensElec = {'E10-E11'};

    case {'REC2Stim07'}

        config.stimElec = {'E0-E1'};
        config.sensElec = {'E9-E10'};

end