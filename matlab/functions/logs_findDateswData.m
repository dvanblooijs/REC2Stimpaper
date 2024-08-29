function [dateswData] = logs_findDateswData(logfile, logvisit_prev, logvisit_cur)

idx_logdates = contains(logfile,', ');

alldates = extractAfter(logfile(idx_logdates),', ');
% datenumwData = unique(floor(datenum(datetime(alldates(:),'InputFormat','MM/dd/yyyy hh:mm:ss aa'))));
% dateswData = datetime(datenumwData,'ConvertFrom','datenum');

% ASSUMPTION: that all dates between the first date in log-file and last
% date in log-file should be logged in the logbook
alldates = dateshift(datetime(alldates(:),'InputFormat','MM/dd/yyyy hh:mm:ss aa'),'start','day');

% remove dates that are before the date of the previous visit and after the
% date of this visit! (REC2Stim03 has a log-note on 18 march 2000 (in
% logfile of 16 feb 2021), which is incorrect, since we were not recording
% in this patient at that time)
idx_corData = alldates>=dateshift(logvisit_prev,'start','day') & alldates<=dateshift(logvisit_cur,'start','day');
alldates = alldates(idx_corData);

mindatenums = min(alldates);
maxdatenums = max(alldates);
dateswData = mindatenums:maxdatenums;


end