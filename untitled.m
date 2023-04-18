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

[x,fs] = audioread('test.wav');
x=x(:,1);
S = stft(x,fs);
nS = width(S);  % num of windowed segments
amp = abs(S);
amp1 = amp(:,3:nS);
amp0 = amp(:,2:(nS-1));
phase = angle(S);
dPhase = phase(:,3:nS)-2*phase(:,2:(nS-1))+phase(:,1:(nS-2));
dist = (amp1.^2+amp0.^2-2*amp1.*amp0.*cos(dPhase)).^0.5;
spec = sum(dist(1:height(dist)/2),1);