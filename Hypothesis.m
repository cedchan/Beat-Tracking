classdef Hypothesis < handle

    properties (SetAccess = private)
        period          % Predicted period
        phase           % Predicted phase (offset from start)
        scores = []     % Array of scores
        corrs = {}      % Cell array of corrections
    end

    properties (SetAccess = immutable)
        window          % Size of window in ms
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
            % initialize to prev proj's match 
            pair(i) = pair(i-1);
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

    % Truncates to smaller of onset/projection vectors
    matchesN = min(projN,onsetsN);
    % Space allocate matches cell array (note that cell array is stored
    % indices, not proj/onset values)
    matches = cell(1,matchesN);
    % Initialize first match to first pair
    matches{1} = Match(1,dist(1),pair(1));
    % Index of fully matched pairs
    matchIdx = 1;
    for i = 2:matchesN
        if matches{matchIdx}.onset ~= pair(i)
            % If no conflict with most recent pair, adds to next idx
            matches{matchIdx+1} = Match(i,dist(i),pair(i));
            matchIdx = matchIdx+1;
        elseif dist(i) < matches{matchIdx}.dist
            % If conflicts with recent pair, but has shorter distance,
            % kicks recent pair using 'feedBack()' and overrides recent.
            [matches,matchIdx] = feedBack(proj,onsets,matches,matchIdx);
            matches{matchIdx} = Match(i,dist(i),pair(i)); % TODO: CHECK
        elseif matchIdx < matchesN
            % If conflicts but has less than or equal distance, sets
            % closest match to next onset, so long as it's in bounds.
            newDist = abs(proj(i)-onsets(pair(i)+1));
            matches{matchIdx+1} = Match(i,newDist,pair(i)+1);
            matchIdx = matchIdx+1;
        end
    end
end


% Recursively kicks a given index to it's next closest pair backward, until
% there are no outstanding losing conflicts.
%
% Inputs:
%   proj: Projected beats times in ms
%   onsets: Actual onset times in ms
%   matches: Cell array of current matches (in indices) to fix
%   i: Index to start fixing backward from 
function [matches,matchIdx] = feedBack(proj,onsets,matches,i)
    if i <= 0 || matches{i}.onset <= 1
        % Does nothing if there are no other possible matches.
        return
    end

    old = matches{i}.proj;
%     candidate = matches{i-1}.onset;
    candidate = matches{i}.onset-1;
    newDist = abs(proj(old)-onsets(candidate));

    matchIdx = i;

    if i == 1 || matches{i-1}.onset ~= candidate
        % Immedietly updates if no conflict with previous match.
        matches{i}.update(i,newDist,candidate)
        matchIdx = matchIdx+1;
    elseif newDist < matches{i-1}.dist
        % If conflicts, overrides if there's shorter distance
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
    error = cellfun(@(m) m.dist,matches); % extract distances from error
    scaledErr = error/period;
    hits = 0.01.^scaledErr;      % Error weight function, could use Gauss
    numHits = sum(hits);
end