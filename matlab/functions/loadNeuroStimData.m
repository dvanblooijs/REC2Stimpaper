function [epochs,paramSens,paramdetAlg,paramStim,channelspec] = loadNeuroStimData(myDataPath,cfg,loadData)

%% this code loads all required data
% input:
% - string:
% can be "seizures", which loads all seizures annotated by the patient
% can be "annotseizures", which loads only seizures annotated by the researcher
% can be "all", which loads all data

%% load scans.tsv and load all data to extract seizures later
if ~exist('string','var')
    loadData = 'all';
end

filename = fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',...
    [cfg(1).sub_label,'_',cfg(1).ses_label,'_scans.tsv']);

% read existing scans-file
scans_tsv = read_tsv(filename);

epochs = struct; n=1; paramStim = struct;
for nScans = 1:size(scans_tsv,1)
    addEpoch = 0;

    if strcmp(loadData,'seizures')
        if scans_tsv.nPPseizures(nScans) == 1
            addEpoch = 1;
            epochs(n).file = scans_tsv.name{nScans};
            epochs(n).electrodes = read_tsv(fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',[cfg(1).sub_label,'_',cfg(1).ses_label,'_electrodes.tsv']));
            epochs(n).events = read_tsv(fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',scans_tsv.recfolder{nScans},replace(scans_tsv.name{nScans},'_ieeg','_events.tsv')));
            epochs(n).channels = read_tsv(fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',scans_tsv.recfolder{nScans},replace(scans_tsv.name{nScans},'_ieeg','_channels.tsv')));
            epochs(n).data = importdata(fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',scans_tsv.recfolder{nScans},[scans_tsv.name{nScans},'.txt']));
            epochs(n).detAlg = read_tsv(fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',scans_tsv.recfolder{nScans},replace(scans_tsv.name{nScans},'_ieeg','_detAlg.tsv')));

        end

    elseif strcmp(loadData,'annotseizures')
        if scans_tsv.nAnnotSeizures(nScans) == 1
            addEpoch = 1;
            epochs(n).file = scans_tsv.name{nScans};
            epochs(n).electrodes = read_tsv(fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',[cfg(1).sub_label,'_',cfg(1).ses_label,'_electrodes.tsv']));
            epochs(n).events = read_tsv(fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',scans_tsv.recfolder{nScans},replace(scans_tsv.name{nScans},'_ieeg','_events.tsv')));
            epochs(n).channels = read_tsv(fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',scans_tsv.recfolder{nScans},replace(scans_tsv.name{nScans},'_ieeg','_channels.tsv')));
            epochs(n).data = importdata(fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',scans_tsv.recfolder{nScans},[scans_tsv.name{nScans},'.txt']));
            epochs(n).detAlg = read_tsv(fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',scans_tsv.recfolder{nScans},replace(scans_tsv.name{nScans},'_ieeg','_detAlg.tsv')));
        end

    elseif strcmp(loadData,'all')
        addEpoch = 1;
        epochs(n).file = scans_tsv.name{nScans};
        epochs(n).electrodes = read_tsv(fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',[cfg(1).sub_label,'_',cfg(1).ses_label,'_electrodes.tsv']));
        epochs(n).events = read_tsv(fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',scans_tsv.recfolder{nScans},replace(scans_tsv.name{nScans},'_ieeg','_events.tsv')));
        epochs(n).channels = read_tsv(fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',scans_tsv.recfolder{nScans},replace(scans_tsv.name{nScans},'_ieeg','_channels.tsv')));
        epochs(n).data = importdata(fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',scans_tsv.recfolder{nScans},[scans_tsv.name{nScans},'.txt']));
        epochs(n).detAlg = read_tsv(fullfile(myDataPath.dataPath,cfg(1).sub_label,cfg(1).ses_label,'ieeg',scans_tsv.recfolder{nScans},replace(scans_tsv.name{nScans},'_ieeg','_detAlg.tsv')));
    end
    
    if addEpoch == 1
        %% add stimulation on/off (1/0)
        if any(contains(epochs(n).events.notes,'"off"')) && all(~contains(epochs(n).events.notes,'"on"'))
            epochs(n).stimOnOff = 0;
            
            paramStim(n).freq = NaN;
            paramStim(n).ch = NaN;
            paramStim(n).cur = NaN;
            paramStim(n).pulse = NaN;
            
        elseif any(contains(epochs(n).events.notes,'"on"')) && all(~contains(epochs(n).events.notes,'"off"'))
            epochs(n).stimOnOff = 1;
            
            idx = find(contains(epochs(n).events.notes,'hz','IgnoreCase',true)==1);
            
            freq = cell(size(idx)); ch = cell(size(idx)); cur = cell(size(idx)); pulse = cell(size(idx));
            for k = 1 : size(idx,1)
            
                stringParts = strsplit(epochs(n).events.notes{idx(k)},{'; ',';'});
                stringParts_low = lower(stringParts);
                
                idx_freq = contains(stringParts_low,'hz');
                freq{k} = str2double(extractBefore(stringParts_low{idx_freq},'hz'));
                
                idx_chtemp = find(contains(stringParts,'E') & contains(stringParts,'-'));
                idx_ch = [];
                for m = 1:size(idx_chtemp,2)
                    if ~isempty(regexp(stringParts_low{idx_chtemp(m)},'[0-9]', 'once')) && size(regexp(stringParts_low{idx_chtemp(m)},'[a-z]'),2) == 2
                        idx_ch(m) = idx_chtemp(m); %#ok<AGROW>
                    end
                end
                if size(idx_ch,2) ~= 1
                    error('Not just 1 stringparts with E in events-file of epoch %s',epochs(n).file)
                end
                ch{k} = stringParts{idx_ch};
                
                idx_cur_temp = find(contains(stringParts_low,'v'));
                idx_cur = [];
                for m = 1:size(idx_cur_temp,2)
                   if ~isempty(regexp(stringParts_low{idx_cur_temp(m)},'[0-9]', 'once')) && size(regexp(stringParts_low{idx_cur_temp(m)},'[a-z]'),2) == 1
                        idx_cur(m) = idx_cur_temp(m); %#ok<AGROW>
                   end
                end
                if size(idx_cur,2) ~= 1
                    error('Not just 1 stringpart with v in events-file of epoch %s',epochs(n).file)
                end
                cur{k} = str2double(extractBefore(stringParts_low{idx_cur},'v'));
                
                % find part of string containing info about pulse width
                idx_pulse_temp = find(contains(stringParts_low,'us'));
                idx_pulse = [];
                for m = 1:size(idx_pulse_temp,2)
                   if ~isempty(regexp(stringParts_low{idx_pulse_temp(m)},'[0-9]', 'once')) && size(regexp(stringParts_low{idx_pulse_temp(m)},'[a-z]'),2) == 2
                        idx_pulse(m) = idx_pulse_temp(m); %#ok<AGROW>
                   end
                end
                
                if size(idx_pulse,2) ~= 1
                    error('Not just 1 stringpart with us in events-file of epoch %s',epochs(n).file)
                end
                pulse{k} = str2double(extractBefore(stringParts_low{idx_pulse},'us'));
                
            end
            paramStim(n).freq = vertcat(freq{:});
            paramStim(n).ch = ch(:);
            paramStim(n).cur = vertcat(cur{:});
            paramStim(n).pulse = vertcat(pulse{:});
        else
            warning('It is unclear in %s if stimulation is on/off',epochs(n).file)
        end
        
        %% add TD in SOZ channel
        idx_SOZelec = strcmpi(epochs(n).electrodes.soz,'yes');
        if ~isempty(find(contains(epochs(n).channels.status,'TD') & contains(epochs(n).channels.name,epochs(n).electrodes.name(idx_SOZelec))==1, 1))
            epochs(n).TDSOZ = 1;
        else
            epochs(n).TDSOZ = 0;
        end
        
        %% add seizure annotation
        % add whether:
        % seizure onset is annotated (1),
        % TD data was checked and nothing was annotated (0),
        % TD data was recorded realtime (0), or
        % no TD was present and so no seizure onset could be annotated (NaN)
        annotnum = find(strcmp(epochs(n).events.trial_type,'annotation') & strcmp(epochs(n).events.sub_type,'seizure'));
        if ~isempty(annotnum) && epochs(n).TDSOZ == 1 % if observer looked at data
            
            % if seizure is annotated (sample_start = NaN when data is checked, an no
            % seizure was annoted, sample_start = 1234, when data is checked and a seizure is annotated)
            if ~isnan(epochs(n).events.sample_start(annotnum))
                epochs(n).annotSz = 1;
            else
                epochs(n).annotSz = 0;
            end
            
        elseif isempty(annotnum) && epochs(n).TDSOZ == 1 % if there is TD in SOZchan but no seizure annotated (for example in RealtimeRecordings)
            epochs(n).annotSz = 0;
            
        else % if there is no TD in SOZ
            epochs(n).annotSz = NaN;
        end
        
        %% add when stimuli are annotated
        annotnum = find(strcmp(epochs(n).events.trial_type,'annotation') & strcmp(epochs(n).events.sub_type,'stimulation'));
        if ~isempty(annotnum)
            
            if ~isnan(epochs(n).events.sample_start(annotnum))
                epochs(n).annotStim = 1;
            else
                epochs(n).annotStim = 0;
            end
            
        elseif isempty(annotnum)
            epochs(n).annotStim = 0;
            
        end
        
        n=n+1;
    end
end

%% find different versions of detection algorithm
paramdetAlg = struct;
for n=1:size(epochs,2)
    paramdetAlg(n).W1 = epochs(n).detAlg.W1 ;
    paramdetAlg(n).W2 = epochs(n).detAlg.W2 ;
    paramdetAlg(n).W3 = epochs(n).detAlg.W3 ;
    paramdetAlg(n).W4 = epochs(n).detAlg.W4 ;
    paramdetAlg(n).NormConstA1 = epochs(n).detAlg.NormConstA1 ;
    paramdetAlg(n).NormConstA2 = epochs(n).detAlg.NormConstA2 ;
    paramdetAlg(n).NormConstA3 = epochs(n).detAlg.NormConstA3 ;
    paramdetAlg(n).NormConstA4 = epochs(n).detAlg.NormConstA4 ;
    paramdetAlg(n).NormConstB1 = epochs(n).detAlg.NormConstB1 ;
    paramdetAlg(n).NormConstB2 = epochs(n).detAlg.NormConstB2 ;
    paramdetAlg(n).NormConstB3 = epochs(n).detAlg.NormConstB3 ;
    paramdetAlg(n).NormConstB4 = epochs(n).detAlg.NormConstB4 ;
    paramdetAlg(n).b = epochs(n).detAlg.b ;
    
end

%% find similar detAlg settings
[~,b,vv]=unique([vertcat(paramdetAlg(:).W1), ...
    vertcat(paramdetAlg(:).W2) ,...
    vertcat(paramdetAlg(:).W3),...
    vertcat(paramdetAlg(:).W4) ,...
    vertcat(paramdetAlg(:).NormConstA1) ,...
    vertcat(paramdetAlg(:).NormConstA2),...
    vertcat(paramdetAlg(:).NormConstA3),...
    vertcat(paramdetAlg(:).NormConstA4),...
    vertcat(paramdetAlg(:).NormConstB1),...
    vertcat(paramdetAlg(:).NormConstB2) ,...
    vertcat(paramdetAlg(:).NormConstB3) ,...
    vertcat(paramdetAlg(:).NormConstB4) ,...
    vertcat(paramdetAlg(:).b)],...
    'rows');

% set detAlg versions in correct order
vv2 = NaN(size(vv));
for nScans=1:size(unique(vv),1)
    
    sortb = sort(b);
    idx = (vv == vv(sortb(nScans)));
    vv2(idx) = nScans;
end

for nScans=1:size(paramdetAlg,2)
    paramdetAlg(nScans).vv = vv2(nScans);
end


%% find channel settings of each epoch

paramSens = struct;
for n=1:size(epochs,2)
    
    paramSens(n).fs = NaN(4,1);
    % fs
    if any(contains(epochs(n).channels.status,'TD'))
        paramSens(n).fs(~isnan(epochs(n).channels.sampling_frequency)) = unique(epochs(n).channels.sampling_frequency(contains(epochs(n).channels.status,'TD')));
        
    else
        paramSens(n).fs(~isnan(epochs(n).channels.sampling_frequency)) = unique(epochs(n).channels.sampling_frequency(contains(epochs(n).channels.status,'Power')));
    end
    
    % channels & bandwidth & center frequency
    paramSens(n).bandwidth = epochs(n).channels.bandwidth;
    paramSens(n).cfreq = epochs(n).channels.center_frequency;
    paramSens(n).name = epochs(n).channels.name;
    paramSens(n).gain = epochs(n).channels.gain;
    paramSens(n).high_cutoff_inputPlus = epochs(n).channels.high_cutoff_inputPlus;
    paramSens(n).high_cutoff_inputMin = epochs(n).channels.high_cutoff_inputMin;
    paramSens(n).low_cutoff= epochs(n).channels.low_cutoff;
    paramSens(n).chosenGain = epochs(n).channels.selected_gain;
        
    ch_num = NaN(1,8);
    for nScans=1:size(paramSens(n).name,1)
        if contains(paramSens(n).name{nScans},{'E','-'})
            ch_num(1,nScans*2-1) = str2double(extractBetween(paramSens(n).name{nScans},'E','-'));
            ch_num(1,nScans*2) = str2double(extractAfter(paramSens(n).name{nScans},'-E'));
        end
    end
    paramSens(n).ch_num = ch_num;
end


%% find similar channel settings
combineparmsz = [horzcat(paramSens(:).bandwidth)', horzcat(paramSens(:).cfreq)', ...
    horzcat(paramSens(:).gain)', horzcat(paramSens(:).chosenGain)', vertcat(paramSens(:).ch_num), ...
    horzcat(paramSens(:).high_cutoff_inputMin)', horzcat(paramSens(:).high_cutoff_inputPlus)', horzcat(paramSens(:).low_cutoff)'];
combineparmsz(isnan(combineparmsz)) = Inf;

[~,b,vv]=unique(combineparmsz,'rows');
% for i=1:size(paramsz,2)
%     paramsz(i).vv = vv(i);
% end

% set param versions in correct order
vv2 = NaN(size(vv));
for nScans=1:size(unique(vv),1)
    
    sortb = sort(b);
    idx = (vv == vv(sortb(nScans)));
    vv2(idx) = nScans;
end

for nScans=1:size(paramSens,2)
    paramSens(nScans).vv = vv2(nScans);
end

%% look at channel specific parameters

bandwidthall = horzcat(paramSens(:).bandwidth)';
cfreqall = horzcat(paramSens(:).cfreq)';
ch_numall = vertcat(paramSens(:).ch_num);
gainall = horzcat(paramSens(:).gain)';
chosenGainall = horzcat(paramSens(:).chosenGain)';
low_cutoff = horzcat(paramSens(:).low_cutoff)';
high_cutoff_inputPlus = horzcat(paramSens(:).high_cutoff_inputPlus)';
high_cutoff_inputMin = horzcat(paramSens(:).high_cutoff_inputMin)';

channelspec = struct;
for nScans=1:4
    for j=1:size(cfreqall,1)
        channelspec.(['channel', num2str(nScans)])(j).ch_num = ch_numall(j,nScans*2-1:nScans*2);
        channelspec.(['channel', num2str(nScans)])(j).cfreq = cfreqall(j,nScans);
        channelspec.(['channel', num2str(nScans)])(j).bandwidth = bandwidthall(j,nScans);
        channelspec.(['channel', num2str(nScans)])(j).gain = gainall(j,nScans);
        channelspec.(['channel', num2str(nScans)])(j).chosenGain = chosenGainall(j,nScans);
        channelspec.(['channel', num2str(nScans)])(j).low_cutoff = low_cutoff(j,nScans);
        channelspec.(['channel', num2str(nScans)])(j).high_cutoff_inputPlus = high_cutoff_inputPlus(j,nScans);
        channelspec.(['channel', num2str(nScans)])(j).high_cutoff_inputMin = high_cutoff_inputMin(j,nScans);
       
    end
end

%% find unique channel specifications

for chan = 1:4
    
    chanspecs = [vertcat(channelspec.(['channel' num2str(chan)]).ch_num), ...
        vertcat(channelspec.(['channel' num2str(chan)]).cfreq),...
        vertcat(channelspec.(['channel' num2str(chan)]).bandwidth),...
        vertcat(channelspec.(['channel' num2str(chan)]).gain),...
        vertcat(channelspec.(['channel' num2str(chan)]).chosenGain),...
        vertcat(channelspec.(['channel' num2str(chan)]).high_cutoff_inputPlus),...
        vertcat(channelspec.(['channel' num2str(chan)]).high_cutoff_inputMin),...
        vertcat(channelspec.(['channel' num2str(chan)]).low_cutoff)];
    
    chanspecs(isnan(chanspecs)) = Inf;
    
    [~,b,vv] = unique(chanspecs,'rows');
    % for i=1:size(paramsz,2)
    %     paramsz(i).vv = vv(i);
    % end
    
    % set param versions in correct order
    vv2 = NaN(size(vv));
    for nScans = 1:size(unique(vv),1)
        
        sortb = sort(b);
        idx = (vv == vv(sortb(nScans)));
        vv2(idx) = nScans;
    end
    
    for nScans = 1:size(channelspec.(['channel' num2str(chan)]),2)
        channelspec.(['channel' num2str(chan)])(nScans).vv = vv2(nScans);
    end
end
