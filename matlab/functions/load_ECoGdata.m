% function to read data into dataBase

function dataBase = load_ECoGdata(myDataPath,selectSubj)

dataPath = myDataPath.dataPath;
sub_label = selectSubj.sub_label;
ses_label = selectSubj.ses_label;
run_label = selectSubj.run_label;

dataBase = struct([]);

for n = 1:size(run_label,1)
    
    D = dir(fullfile(dataPath, sub_label,ses_label,'ieeg',...
        [sub_label,'_',ses_label,'_task-*_',run_label{n},'_ieeg.eeg']));
   
    % determine task_label
    task_label = D(1).name(strfind(D(1).name,'task-'):strfind(D(1).name,'_run')-1);
    
    dataName = fullfile(D(1).folder, D(1).name);
    
    ccep_data = ft_read_data(dataName,'dataformat','brainvision_eeg');
    ccep_header = ft_read_header(dataName);
    
    % load events
    D = dir(fullfile(dataPath,sub_label,ses_label,'ieeg',...
        [sub_label '_' ses_label '_' task_label '_' run_label{n} '_events.tsv']));
    
    eventsName = fullfile(D(1).folder, D(1).name);
    
    tb_events = readtable(eventsName,'FileType','text','Delimiter','\t');
    
    % load electrodes
    D = dir(fullfile(dataPath,sub_label,ses_label,'ieeg',...
        [sub_label '_' ses_label ,'_electrodes.tsv']));
    
    elecsName = fullfile(D(1).folder, D(1).name);
    
    tb_electrodes = readtable(elecsName,'FileType','text','Delimiter','\t');
    idx_elec_incl = ~strcmp(tb_electrodes.group,'other');
    tb_electrodes = tb_electrodes(idx_elec_incl,:);
    
    % load channels
    D = dir(fullfile(dataPath,sub_label, ses_label,'ieeg',...
        [sub_label '_' ses_label '_' task_label ,'_',run_label{n},'_channels.tsv']));
    
    channelsName = fullfile(D(1).folder, D(1).name);
    
    tb_channels = readtable(channelsName,'FileType','text','Delimiter','\t');
    idx_ch_incl = strcmp(tb_channels.type,'ECOG');
    tb_channels = tb_channels(idx_ch_incl,:);
    
    ch = tb_channels.name;
    
    data = ccep_data(idx_ch_incl,:);
    
    dataBase(n).sub_label = sub_label;
    dataBase(n).tb_electrodes = tb_electrodes;
    dataBase(n).ses_label = ses_label;
    dataBase(n).task_label = task_label;
    dataBase(n).run_label = run_label;
    dataBase(n).dataName = dataName;
    dataBase(n).ccep_header = ccep_header;
    dataBase(n).tb_events = tb_events;
    dataBase(n).tb_channels = tb_channels;
    dataBase(n).ch = ch;
    dataBase(n).data = data;
    fprintf('...Subject %s, file %s has been run...\n',sub_label,run_label{n})
end


