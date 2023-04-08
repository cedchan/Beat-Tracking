% onsets = 5:100:1000;
% onsets(2) = [];
onsets = (0:10:500);
onsets = onsets+10*(rand(1,length(onsets))-0.5)+5;

window = 60;
mult = 2;
decay = 0.0001;
delta = 5;
tracker = BeatTracker(onsets,window,mult,decay,delta);
tracker.track();


period = cellfun(@(h) h.period,tracker.H);
phase = cellfun(@(h) h.phase,tracker.H);

sum = [period' phase']
% t = Correction(tracker.H{4},tracker.H{4}.project(1100,1100),onsets,2,0.0001)