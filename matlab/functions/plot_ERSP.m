function plot_ERSP(ERSPall,stimp,chan)

ERSP = ERSPall.allERSP;
ERSPboot = ERSPall.allERSPboot;
times = ERSPall.times;
freqs = ERSPall.freqs;
ch = ERSPall.ch;
cc_stimchans = ERSPall.cc_stimchans;

%Plot image manually
figure,
% subplot(1,2,1)
% a = ERSP{stimp,chan};
% a = flipud(a);
% imagesc(a,[-15,15])
% colormap jet
% title(sprintf('ERSP stimpair = %g, chan = %g without bootstrapping',stimp,chan))
% ax = gca;
% ax.YTick = min(freqs):50:max(freqs);
% ax.YTickLabels = max(freqs):-50:min(freqs);
% ax.XTick = 1:20:size(times,2);
% ax.XTickLabels = round(times(ax.XTick),1,'significant');
% xlabel('Time(ms)')
% ylabel('Frequency (Hz)')
% 

% subplot(1,2,2),
a = ERSPboot{stimp,chan};
a = flipud(a);
imagesc(a,[-15,15])
colormap jet
title(sprintf('ERSP stimpair = %s-%s, chan = %s with bootstrapping',cc_stimchans{stimp,1},cc_stimchans{stimp,2},ch{chan}))
ax = gca;
ax.YTick = min(freqs):50:max(freqs);
ax.YTickLabels = max(freqs):-50:min(freqs);
ax.XTick = 1:20:size(times,2);
ax.XTickLabels = round(times(ax.XTick),1,'significant');
xlabel('Time(ms)')
ylabel('Frequency (Hz)')

end