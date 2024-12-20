function powerall = powerspectrum_seizureonset(seizure)

for n = 1:size(seizure,2)
    
    fs = seizure(n).fs;
    
    signal = seizure(n).data';
    
    % filter parameters om 50Hz eruit te filteren
    analysis_params.hpfreq=[];
    analysis_params.lpfreq=[];
    analysis_params.notchhpfreq = 47;
    analysis_params.notchlpfreq = 53;
    analysis_params.sample_rate = fs;
    
    % filteren van signaal
    signalFilt = filter_signal(signal, analysis_params, 1); % signal must be [samples x chans]
    
    % filter parameters om 100Hz eruit te filteren
    analysis_params.notchhpfreq = 97;
    analysis_params.notchlpfreq = 103;
    
    %filteren van signaal
    signalFilt2 = filter_signal(signalFilt, analysis_params, 1);
    
    % gabor filter parameters
    params.sample_rate = fs;
    params.W = 4;
    params.spectra = 1:100;
    
    % amplitudes van re-referenced signalen op verschillende frequenties [time x electrodes x frequencies]
    gabor = jun_gabor_cov_fitted(signalFilt2',params,'amp',1,1).^2; % quadratic(.^2) = power
    gabor_logcor = gabor./repmat(mean(gabor,1),[size(gabor,1) 1 1]);

%     % remove first and last part of the signal
%     power = gabor_logcor(10*fs:end-(10*fs),:,:);
      
    powerall(n).power = gabor_logcor;
end




