% onsets = 5:100:1000;
% onsets(2) = [];
% onsets = (0:10:500);
% onsets = onsets+2*(rand(1,length(onsets))-0.5)+5;
onsets = [1 2 2.5 3.5 4];
for i = 1:2
    onsets = [onsets (onsets(end)+onsets)];
end
onsets = [onsets (onsets(end)+[1 4 7 10 13 16])];
% onsets = [0 1 2 3 4 5 6 7 8 9 10 13 16 19 22 25 28 31 34 37]

% | . | . | . | . 
% x   x x   x x

onsets = [1 2 3.1 4.3 5.6 7 8.7];

onsets = 10*[0 1 1.5 2.5 3 4 5 5.5 6.5 7 8 9 9.5 10.5 11];


%%%%%

[x,fs] = audioread('test2.wav');
x=x(:,1);

onsets = OnsetDetector(x,fs).onsets;

window = 10;
mult = 3;
decay = 0.0001;
delta = 0.25;
tracker = BeatModel(onsets,window,mult,decay,delta);
tracker.track();

period = cellfun(@(h) h.period,tracker.H);
phase = cellfun(@(h) h.phase,tracker.H);
score = cellfun(@(h) h.score,tracker.H);

tracker.formatOut()
sum = [period' phase' score'];

xline(onsets)

% test = Hypothesis(1,0,1,2);
% p = test.project(11,5);
% o = Util.getWindow(onsets,11-5,11);
% m = Util.closestPairs(p,o);
% Correction.calcScore(test,p,o,m)
