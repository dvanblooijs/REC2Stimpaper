function [timestr_all,certain] = convertCastorTime(time_orig)
% author: Dorien van Blooijs
% date: December 2021

% this function converts times reported in seizure diaries (dutch) to a
% time (HH:MM) which can be used for further analysis

% times were reported as:
% 7.30 which is converted as 07:30
% 7:30 --> 07:30
% 0.3125 --> 07:30

% in case of the following options of reporting, it is also noted that
% these moments are uncertain (certain = 0).
% ochtend (morning) --> 08:00
% nacht (night) --> 03:00
% avond (evening) --> 20:00
% - or ? --> 12:00

% sometimes, multiple dates were mentioned in one report:
% e.g. 20:00-20:30 --> it was unclear whether one event occurred in this
% time window or two events occured. This was converted to 20:00
% e.g. 20:00-20:25-21:40 --> it was assumed that three events were
% reported, so this was converted to 3 times: 20:00, 20:25 and 21:40. 
% e.g. 20:00&20:30 --> it was assumed that two events were reported, so
% this was converted to 2 times: 20:00, 20:30.
% e.g. 1.00 tot 23:00 --> it was assumed that an event occurred in this
% period of time, so only the first event was used.

% split time into multiple times if - or & was used
if contains(time_orig,'&')
    indiv_times = strsplit(time_orig,'&');
elseif contains(time_orig,'-')
    indiv_times = strsplit(time_orig,'-')';
    if size(indiv_times,1) == 2
        indiv_times(2) = [];
    end
elseif contains(time_orig,{' en','en '}) 
    indiv_times = strsplit(time_orig,'en');
    indiv_times = strtrim(indiv_times);
elseif contains(time_orig,'/')
    indiv_times = strsplit(time_orig,'/');
    indiv_times = strtrim(indiv_times);
elseif contains(time_orig,'tot')
    indiv_times = strsplit(time_orig,'tot');
    indiv_times = strtrim(indiv_times);
    indiv_times(2) = [];
else
    indiv_times = {time_orig};
end

% pre-allocation
timestr_all = cell(length(indiv_times),1);
certain = ones(length(indiv_times),1);

% for all times mentioned in one cell in excel (so
% 'sz_diary_1_Voorval_1_Tijd_hh_mm_' for example)
for jj = 1:length(indiv_times)
    time_char = indiv_times{jj};

    %% if time does not contain any text
    if ~isnan(str2double(time_char)) % e.g. '0.31' or '7.30'

        time_int = str2double(time_char);

        if time_int > 0 && time_int < 1 % e.g. 0.31 --> which means 07:30

            timestr = datestr(time_int,'HH:MM');

        elseif time_int >= 1 % e.g. 7.30, which should be 07:30

            time_temp = floor(time_int)/24+(time_int-floor(time_int))*100/(24*60); % hours/24 + min/(24*60)
            timestr = datestr(time_temp,'HH:MM');

        elseif time_int == 0 % it is assumed that nothing is filled in, since 0 is not a time

            timestr = '12:00';
            certain(jj) = 0;

        end

        %% if time contains text
    elseif isnan(str2double(time_char)) % e.g. '7.30 uur ong'/'nacht'
        select = regexp(time_char,{'[0-9:.]'});

        if ~isempty(select{:}) && length(select{:}) > 3 && length(select{:}) <6 % e.g. '7.30 uur ong'
            time_char = time_char(select{:});

            if contains(time_char,'.') % e.g. '7.30'

                time_int = str2double(time_char);
                time_temp = floor(time_int)/24+(time_int-floor(time_int))*100/(24*60); % hours/24 + min/(24*60)
                timestr = datestr(time_temp,'HH:MM');

            elseif contains(time_char,':') % e.g.'7:30'
                time_char = replace(time_char,':','.');

                time_int = str2double(time_char);
                time_temp = floor(time_int)/24+(time_int-floor(time_int))*100/(24*60); % hours/24 + min/(24*60)
                timestr = datestr(time_temp,'HH:MM');

            elseif size(regexp(time_char,'\d'),2) == size(time_char,2) % e.g. '07 00' --> 0700 --> only digits
                time_int = str2double(time_char)/100;
                time_temp = floor(time_int)/24+(time_int-floor(time_int))*100/(24*60); % hours/24 + min/(24*60)
                timestr = datestr(time_temp,'HH:MM');
            end
        elseif isempty(select{:}) % e.g. '?', 'ochtend', '-'
            if contains(time_char,'ochtend')
                timestr = '08:00';
            elseif contains(time_char,'avond')
                timestr = '20:00';
            elseif contains(time_char,'nacht')
                timestr = '03:00';
            elseif contains(time_char,{'?','-',''})
                timestr = '12:00';
            end

            certain(jj) = 0;

        else
            timestr = '12:00';
            warning('Original time = %s, Converted time = %s \n', time_orig,timestr)
            certain(jj) = 0;
        end
    else % in case it is unknown what time a certain time is....
        timestr = '12:00';
        warning('Original time = %s, Converted time = %s \n', time_orig,timestr)
        certain(jj) = 0;
    end

    if exist('timestr','var')
        fprintf('Original time = %s, Converted time = %s \n', time_orig,timestr)
    end

    timestr_all{jj} = timestr;

end
end



%% TEST FOR ALL CASTOR TIMES
% all_time = cell(1);
% count = 1;
% for nn = 1:size(Castor,1)
%
%     for m = 1:7
%         for k = 1:10
%
%             type =  Castor(nn).(['sz_diary_',num2str(m),'_Voorval_',num2str((m-1)*10+k),'_Type']);
%             if type == 1 || type == 3 % seizure || twitches, type == 2 --> aura
%                 %                 datum = Castor(selectDiary(nn)).sz_diary_1_Voorval_1_Datum;
%
%                 all_time{count} = Castor(nn).(['sz_diary_',num2str(m),'_Voorval_',num2str((m-1)*10+k),'_Tijd_hh_mm_']);
%                 count = count+1;
%             end
%         end
%     end
% end
%
% %%
% clc
%
% remove = [];
% all_time_new = cell(1);
% count = 1;
%
