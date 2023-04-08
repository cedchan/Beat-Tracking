% onsets = 5:100:1000;
% onsets(2) = [];
onsets = (0:10:500);
onsets = onsets+2*(rand(1,length(onsets))-0.5)+5;
onsets = [0 2 3 4 5 6];

window = 4;
mult = 2;
decay = 0.0001;
delta = 5;
tracker = BeatTracker(onsets,window,mult,decay,delta);
tracker.track();

period = cellfun(@(h) h.period,tracker.H);
phase = cellfun(@(h) h.phase,tracker.H);

tracker.out
% sum = [period' phase']
% t = Correction(tracker.H{4},tracker.H{4}.project(1100,1100),onsets,2,0.0001)