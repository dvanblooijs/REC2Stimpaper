
function filtered_signal = filter_signal(signal, analysis_params, do_filtfilt)

% perform analog filtering before we do the analysis
hpfreq=analysis_params.hpfreq;
lpfreq=analysis_params.lpfreq;
notchhpfreq=analysis_params.notchhpfreq;
notchlpfreq=analysis_params.notchlpfreq;
samplefreq=analysis_params.sample_rate;
num_chan=size(signal,2);

filtered_signal = zeros(size(signal));

if nargin==3
    use_filtfilt = do_filtfilt;
else
    use_filtfilt = 0;
end

if (hpfreq > 0)   % only perform the filtering if we want to
%     h = waitbar(0,'bandpass filtering signal ...');
   if (lpfreq > 0)
      [b, a]=butter(3, [(hpfreq/samplefreq)*2 (lpfreq/samplefreq)*2]);
   else
      [b, a]=butter(3, (hpfreq/samplefreq)*2, 'high');
   end
   for ch=1:num_chan
       if (use_filtfilt)
    filtered_signal(:,ch)=single(filtfilt(b, a, double(signal(:,ch))));       
       else
    filtered_signal(:,ch)=filter(b, a, signal(:,ch));
       end
%     waitbar(ch/num_chan,h);
   end
%    close(h);
else
   filtered_signal = signal;
end
if (notchhpfreq > 0)   % only perform the filtering if we want to
%     h = waitbar(0,'filtering signal using notch ...');
   [b, a]=butter(3, [(notchhpfreq/samplefreq)*2 (notchlpfreq/samplefreq)*2], 'stop');
   for ch=1:num_chan
        if (use_filtfilt)
    filtered_signal(:,ch)=single(filtfilt(b, a, double(filtered_signal(:,ch))));       
       else
    filtered_signal(:,ch)=filter(b, a, filtered_signal(:,ch));
       end
%     waitbar(ch/num_chan,h);
   end
%    close(h);
end


%% My old messed up code
% if (hpfreq > 0)   % only perform the filtering if we want to
%    fprintf(1, 'bandpass filtering signal\n');
%    if (lpfreq > 0)
%       [b, a]=butter(3, [(hpfreq/samplefreq)*2 (lpfreq/samplefreq)*2]);
%    else
%       [b, a]=butter(3, (hpfreq/samplefreq)*2, 'high');
%    end
%    for ch=1:size(signal, 1)
%     signal(ch,:)=filter(b, a, signal(ch,:)')';
%    end
% end
% if (notchhpfreq > 0)   % only perform the filtering if we want to
%    fprintf(1, 'filtering signal using notch\n');
%    [b, a]=butter(3, [(notchhpfreq/samplefreq)*2 (notchlpfreq/samplefreq)*2], 'stop');
%    for ch=1:size(signal, 1)
%     signal(ch,:)=filter(b, a, signal(ch,:)')';
%    end
% end

%% Nick's code
% if (hpfreq > 0)   % only perform the filtering if we want to
%    fprintf(1, 'bandpass filtering signal\n');
%    if (lpfreq > 0)
%       [b, a]=butter(3, [(hpfreq/samplefreq)*2 (lpfreq/samplefreq)*2]);
%    else
%       [b, a]=butter(3, (hpfreq/samplefreq)*2, 'high');
%    end
%    for ch=1:size(signal, 2)
%     signal(:, ch)=filter(b, a, signal(:, ch));
%    end
% end
% if (notchhpfreq > 0)   % only perform the filtering if we want to
%    fprintf(1, 'filtering signal using notch\n');
%    [b, a]=butter(3, [(notchhpfreq/samplefreq)*2 (notchlpfreq/samplefreq)*2], 'stop');
%    for ch=1:size(signal, 2)
%     signal(:, ch)=filter(b, a, signal(:, ch));
%    end
% end
% filtered_signal = signal;