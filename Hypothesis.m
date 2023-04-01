classdef Hypothesis < handle

    properties (SetAccess = private)
        period          % Predicted period
        phase           % Predicted phase (offset from start)
        scores = []     % Array of scores
        corrs = {}      % Cell array of corrections
    end

    properties (SetAccess = immutable)
        window      % Size of window in ms
    end

    methods
        % Constructor
        function obj = Hypothesis(period,phase,window)
            obj.period = period;
            obj.phase = phase;
            obj.window = window;
        end

        % Returns projections from t ms back window ms
        function proj = project(self,t)
            % Start window ms back
            s = t-self.window;
            if s<0
                error("At least "+self.window+" seconds needed to "+ ...
                    "project hypothesis");
            end

            sShift = s-self.phase;

            % Shift back by phase, ceil(start/period)*period, shift back
            % (Draw it out later)
            projStart = ceil(sShift/self.period)*self.period+self.phase;
            proj = projStart:self.period:t;
        end

        % Inputs:
        %   onsets: Onsets to update on
        %   t: Time to end at in ms
        function update(self,onsets,t)
            corr = Correction(self,onsets,t);

            % Add correction to list of corrections
            self.corrs{end+1} = corr;

            % Update period and phase
        end

        % Inputs:
        %   onsets: Onsets to update on
        %   t: Time to end at in ms
        function score(self,onsets,t)
            proj = self.project(t);
            
            s = t-self.window;  % Checked for error by proj
            onsetWind = getWindow(onsets,s,t);

            numProj = length(proj);
            numOnsets = length(onsetWind);
            numHits = concurrence(proj,onsetWind,self.period); % TODO parameters

            % This is like precision and recall
            precision = numHits/numProj;
            recall = numHits/numOnsets; % Sort of, because onsets aren't "beats"
            f1 = 2*(precision*recall)/(precision+recall); % TODO: Currently unused
            self.scores(end+1) = precision*recall;
        end
    end

    methods (Static)
        function sim = similarity(hyp1,hyp2)
            % return numeric similarity (or maybe just true false)
            % TODO
        end
    end
end

% Finds closest onset to each projected beat, without repetition. If two
% projections are closest to the same onset, the closer one wins. Truncates
% if there are not enough beats in either.
% 
% TODO: Need some way to deal with projection being multiple of onsets
% 
% Inputs:
%   proj: Projected beats times in ms
%   onsets: Actual onset times in ms
function matches = closestPairs(proj,onsets)
    projN = length(proj);
    onsetsN = length(onsets);
    pair = zeros(1,projN);      % Tracks index of closest onset per proj 
    dist = Inf(1,projN);        % Tracks distance of closest onset
    
    % Find every proj's closest onset
    pair(1) = 1;
    dist(1) = abs(proj(1)-onsets(pair(1)));
    for i = 1:projN
        if i ~= 1
            pair(i) = pair(i-1);     % initialize to prev proj's match 
        end
        dist(i) = abs(proj(i)-onsets(pair(i)));

        if pair(i) < onsetsN
            newDist = abs(proj(i)-onsets(pair(i)+1)); % inital dist
            while pair(i) < onsetsN && newDist < dist(i)
                newDist = abs(proj(i)-onsets(pair(i)+1));
                pair(i) = pair(i)+1;
                dist(i) = newDist;
            end
        end
    end

    % Find best matches
    matchesN = min(projN,onsetsN);
    matches = cell(1,min(projN,onsetsN));
    matches{1} = Match(1,dist(1),pair(1));
    matchIdx = 1;
    for i = 2:matchesN
        if matches{matchIdx}.onset ~= pair(i)                     % TODO: WIll out of bounds for 1
            matches{matchIdx+1} = Match(i,dist(i),pair(i));
            matchIdx = matchIdx+1;
        elseif dist(i) < matches{matchIdx}.dist % override its pair
            matches = feedBack(proj,onsets,matches,matchIdx);       % Fix previous ones
            matches{matchIdx}.update(i,dist(i));
        elseif matchIdx < matchesN
            newDist = abs(proj(i)-onsets(pair(i)+1));
            matches{matchIdx+1} = Match(i,newDist,pair(i)+1);
            matchIdx = matchIdx+1;
        end
    end
end


% Correct backwards
%   i: Index to start fixing backward from 
% TODO actually not so sure abt the runtime
function matches = feedBack(proj,onsets,matches,i)
    if i <= 1
        return
    end

    old = matches{i}.proj;
    candidate = matches{i-1}.onset;
    newDist = abs(proj(old)-onsets(candidate));

    if newDist < matches{i-1}.dist
        matches = feedBack(proj,onsets,matches,i-1);
        matches{i-1}.update(i,newDist);
    end
end

% Calculates number of hits as sum of 0.01^(|proj-onset|/period) for each
% period and onset.
% 
% Input:
%   proj: List of projected times (ms) in desired window
%   onsets: List of onset times (ms) in desired window
%   period: Hypothesis period (ms)
function numHits = concurrence(proj,onsets,period)
    matches = closestPairs(proj,onsets);
    error = cellfun(@(m) m.dist, matches); % extract distances from error
    scaledErr = error/period;
    hits = 0.01.^scaledErr;      % Error weight function, could use Gauss
    numHits = sum(hits);
end

% Returns a subset of a given vector, where values are in a certain range.
%
% Inputs:
%   x: Vector to get window of
%   s: Start of window (inclusive)
%   t: End of window (inclusive)
function window = getWindow(x,s,t)
    window = x(s <= x & x <= t);
end