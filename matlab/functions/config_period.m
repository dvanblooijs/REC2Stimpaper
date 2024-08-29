% configuration analysis period

function config = config_period(subj)

% preprocess subj into right format
subjtmp = replace(subj,'sub-','');
subjtmp = replace(subjtmp,'REC2Stim','');
subjnum = str2double(subjtmp);

subj = ['REC2Stim0' num2str(subjnum)];

switch (subj)
    case {'REC2Stim01'}

        config.period_start = datetime('12-11-2019','inputformat','dd-MM-yyyy'); % day of implantation neurostimulator
        config.period_stop = datetime('12-11-2020','inputformat','dd-MM-yyyy');
        config.period_startDCP = datetime('12-11-2019','inputformat','dd-MM-yyyy'); % start of data collection phase (DCP)
        config.period_stopDCP = datetime('28-05-2021','inputformat','dd-MM-yyyy'); % end of data collection phase (DCP)
        config.period_startStim = NaT; %datetime('17-03-2022','inputformat','dd-MM-yyyy'); % start of Stimulation phase (DCP) (after stop of analysis peirod)
    
    case {'REC2Stim02'} % excluded from study, due to possible resection outside eloquent cortex

        config.period_start = datetime('03-12-2019','inputformat','dd-MM-yyyy'); % day of IEMU
        config.period_stop = datetime('03-12-2020','inputformat','dd-MM-yyyy');

    case {'REC2Stim03'}

        config.period_start = datetime('14-1-2020','inputformat','dd-MM-yyyy'); % day of implantation neurostimulator
        config.period_stop = datetime('14-1-2021','inputformat','dd-MM-yyyy');
        config.period_startDCP = datetime('14-01-2020','inputformat','dd-MM-yyyy'); % start of data collection phase (DCP)
        config.period_stopDCP = datetime('16-06-2020','inputformat','dd-MM-yyyy'); % end of data collection phase (DCP)
        config.period_startStim = datetime('16-06-2020','inputformat','dd-MM-yyyy'); % start of Stimulation phase (DCP)

    case {'REC2Stim04'} % excluded from study, due to possible resection outside eloquent cortex

        config.period_start = datetime('04-02-2020','inputformat','dd-MM-yyyy'); % day of IEMU
        config.period_stop = datetime('04-02-2021','inputformat','dd-MM-yyyy');

    case {'REC2Stim05'}

        config.period_start = datetime('7-9-2020','inputformat','dd-MM-yyyy'); % day of implantation neurostimulator
        config.period_stop = datetime('7-9-2021','inputformat','dd-MM-yyyy');
        config.period_startDCP = datetime('7-9-2020','inputformat','dd-MM-yyyy'); % start of data collection phase (DCP)
        config.period_stopDCP = datetime('10-12-2020','inputformat','dd-MM-yyyy'); % end of data collection phase (DCP)
        config.period_startStim = datetime('10-12-2020','inputformat','dd-MM-yyyy'); % start of Stimulation phase (DCP)

    case {'REC2Stim06'}

        config.period_start = datetime('8-9-2020','inputformat','dd-MM-yyyy'); % day of implantation neurostimulator
        config.period_stop = datetime('8-9-2021','inputformat','dd-MM-yyyy');
        config.period_startDCP = datetime('8-9-2020','inputformat','dd-MM-yyyy'); % start of data collection phase (DCP)
        config.period_stopDCP = datetime('20-1-2021','inputformat','dd-MM-yyyy'); % end of data collection phase (DCP)
        config.period_startStim = datetime('20-1-2021','inputformat','dd-MM-yyyy'); % start of Stimulation phase (DCP)

    case {'REC2Stim07'}

        config.period_start = datetime('6-10-2020','inputformat','dd-MM-yyyy'); % day of implantation neurostimulator
        config.period_stop = datetime('6-10-2021','inputformat','dd-MM-yyyy');
        config.period_startDCP = datetime('6-10-2020','inputformat','dd-MM-yyyy'); % start of data collection phase (DCP)
        config.period_stopDCP = datetime('6-1-2021','inputformat','dd-MM-yyyy'); % end of data collection phase (DCP)
        config.period_startStim = datetime('6-1-2021','inputformat','dd-MM-yyyy'); % start of Stimulation phase (DCP)

end