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


% Calculates number of hits as sum of 0.01^(|proj-onset|/period) for each
% period and onset.
function numHits = concurrence(proj,onsets,period)
    % TODO: This is wrong. Need to calculate error by closest, unique
    % onset, not just corresponding indices. Dimensions wont be equal
    error = abs(proj-onsets);
    scaledErr = error/period;
    hits = 0.01^scaledErr;
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