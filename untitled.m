% % proj = [10 20 30 40 50];
% % onsets = [10 30 40 50];
% % 
% % m = Util.closestPairs(proj,onsets);
% 
% proj = [100 300 500 700 900 1100];
% onsets = [0 95 200 300 500 700 900 1100];
% 
% hyp = Hypothesis(200,100);
% % proj = hyp.project(1100,1100);
% matches = Util.closestPairs(proj,onsets);
% projIdx = cellfun(@(m) m.proj,matches)
% onsetIdx = cellfun(@(m) m.onset,matches)
% dist = cellfun(@(m) m.dist,matches)
% 
% c = Correction(hyp,proj,onsets,2,0.0001)

% proj = [4.3922   12.9553   21.5185   30.0816   38.6447   47.2078   55.7709];
% onsets = [7.8255   12.9553   21.5185   38.4791   47.8485   52.7083   62.2781];
% 
% m = Util.closestPairs(proj,onsets)

[x,fs] = audioread('test2.wav');
x=x(:,1);
od = OnsetDetector(x,fs)

subplot(2,1,1)
plot(x)
subplot(2,1,2)
plot(od.cmplxDm)
figure()
plot(x)
xline(od.onsets)