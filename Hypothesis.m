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
        function obj = Hypothesis(periodNew,phaseNew,windowNew)
            obj.period = periodNew;
            obj.phase = phaseNew;
            obj.window = windowNew;
        end

        % Returns projections from t ms
        function proj = project(self,s,t)
            sShift = s-self.phase;

            % Shift back by phase, ceil(start/period)*period, shift back
            % (Draw it out later)
            projStart = ceil((sShift)/self.period)*self.period+self.phase;
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
            % Start window ms back
            s = t-self.window;
            if s<0
                error("At least "+self.window+" seconds needed to "+...
                    "project hypothesis");
            end
            proj = project(s,t);
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
function [projMatch,onsetMatch] = closestPairs(proj,onsets)
    projN = length(proj);
    onsetsN = length(onsets);
    pair = zeros(1,projN);      % Tracks closest onset per proj
    dist = Inf(1,projN);        % Tracks distance of closest onset
    onsetDist = Inf(1,onsetsN); % Tracks shortest distance to onset
    
    pair(1) = onsets(1);
    dist(1) = abs(proj(1)-onsets(pair(1)));
    for i = 1:projN
        pair(i) = pair(i-1);                    % initialize to prev proj's match TODO: WILL OUT OF BOUNDS FOR 1
        newDist = abs(proj(i)-onsets(pair(i))); % inital dist
        while pair(i)<onsetsN && dist(i)>=newDist
            pair(i) = pair(i)+1;
            dist(i) = newDist;
            newDist = abs(proj(i)-onsets(pair(i)+1));
        end

        % Updates onsetDist if pair is shorter
        if dist(i) < onsetDist(pair(i))
            onsetDist(pair(i)) = dist(i);
        end
    end

    % Above loop still O(n) I think


    matches = cell(1,min(projN,onsetsN));
    matches(1).proj = 1;
    onsetMatch(1) = pair(1);
    matchDist(1) = dist(1);
    matchIdx = 1;
    for i = 2:projN
        if onsetMatch(matchIdx) ~= pair(i)                     % TODO: WIll out of bounds for 1
            projMatch(matchIdx+1) = i;
            onsetMatch(matchIdx+1) = pair(i);
            matchDist(matchIdx+1) = dist(i);
            matchIdx = matchIdx+1;
        elseif dist(i) < matchDist(matchIdx) % override its pair
            oldMatch = projMatch(matchIdx); % Previous overriden match
            candidate = onsetsMatch(matchIdx-1); % TODO Verify this won't happen on 1.

            projMatch(matchIdx) = i;
            matchDist(matchIdx) = dist(i);

            % Iterate back to correct
            while abs(proj(oldMatch)-onsets(onsetsMatch(matchIdx-1)))<

            end
        elseif % in bounds, then restart

        end
    end
end


function [newProj,newOnsets,newDist] = feedBack(projMatch,onsetsMatch, ...
    matchDists)
    

end

% Calculates number of hits as sum of 0.01^(|proj-onset|/period) for each
% period and onset.
function numHits = concurrence(proj,onsets,period)
    % TODO: This is wrong. Need to calculate error by closest, unique
    % onset, not just corresponding indices. Dimensions wont be equal
    error = abs(proj-onsets);
    scaledErr = error/period;
    hits = 0.01^scaledErr;      % Error weight function, could use Gauss
    numHits = sum(hits);
end

% Returns a subset of a given vector, where values are in a certain range.
%
% Inputs:
%   x: Vector to get window of
%   s: Start of window (inclusive)
%   t: End of window (inclusive)
function window = getWindow(x,s,t)
    window = x(s<=x & x<=t);
end