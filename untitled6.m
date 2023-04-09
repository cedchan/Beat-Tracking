% onsets = 5:100:1000;
% onsets(2) = [];
% onsets = (0:10:500);
% onsets = onsets+2*(rand(1,length(onsets))-0.5)+5;
onsets = [1 2 2.5 3.5 4];
for i = 1:2
    onsets = [onsets (onsets(end)+onsets)];
end
onsets = [onsets (onsets(end)+[1 4 7 10 13 16])]
% onsets = [0 1 2 3 4 5 6 7 8 9 10 13 16 19 22 25 28 31 34 37]

% | . | . | . | . 
% x   x x   x x


window = 8;
mult = 3;
decay = 0.0001;
delta = 0.25;
tracker = BeatTracker(onsets,window,mult,decay,delta);
tracker.track();

period = cellfun(@(h) h.period,tracker.H);
phase = cellfun(@(h) h.phase,tracker.H);
score = cellfun(@(h) h.score,tracker.H);

tracker.out
sum = [period' phase' score']
% t = Correction(tracker.H{4},tracker.H{4}.project(1100,1100),onsets,2,0.0001)