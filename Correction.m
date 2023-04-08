classdef Correction < handle

    properties (SetAccess = private)
        deltaPhase      % Phase change
        deltaPeriod     % Period change
        score           % Score
    end

    methods
        % Instantiates object and calculates correction
        % Inputs:
        %   proj: Projected beats (ms) in desired window
        %   onsets: Onsets (ms) in desired window
        %   mult: Correction multiplier
        %   decay: Correction decay
        function obj = Correction(hyp,proj,onsets,mult,decay)
            matches = Util.closestPairs(proj,onsets);
            obj.calcCorr(hyp,proj,onsets,matches,mult,decay)
            obj.calcScore(hyp,proj,onsets,matches)
        end
    end


    methods (Access = private)
        function calcCorr(self,hyp,proj,onsets,matches,mult,decay)
            projIdx = cellfun(@(m) m.proj,matches);
            onsetIdx = cellfun(@(m) m.onset,matches);
            error = proj(projIdx)-onsets(onsetIdx);
            scaledErr = mult*error.*decay.^(abs(error)/hyp.period);
            
            % Solve linear regression Ax=b, where b is the error, x is a
            % 2-element vector representing slope and intercept, and A has
            % a column of the matched projection indices, and a column of
            % 1s for the constant term.
            [h,~] = lsqr([projIdx' ones(length(projIdx),1)],scaledErr');
            
            self.deltaPeriod = h(1);
            self.deltaPhase = h(2);
        end
        
        function calcScore(self,hyp,proj,onsets,matches)
            numProj = length(proj);
            numOnsets = length(onsets);
            numHits = concurrence(matches,hyp.period); % TODO parameters
        
            % This is like precision and recall
            precision = numHits/numProj;
            recall = numHits/numOnsets; % Sort of, because onsets aren't "beats"
            f1 = 2*(precision*recall)/(precision+recall); % TODO: Currently unused
            self.score = precision*recall;
        end
    end

end


% Calculates number of hits as sum of 0.01^(|proj-onset|/period) for each
% period and onset.
% 
% Input:
%   matches: Cell array of Match objects for closest onset-projection pairs
%   period: Hypothesis period (ms)
function numHits = concurrence(matches,period)
    error = cellfun(@(m) m.dist,matches); % extract distances from error
    scaledErr = error/period;
    hits = 0.01.^scaledErr;      % Error weight function, could use Gauss
    hits = exp(-(error.^2)/(2*period^2));  % Gaussian
    numHits = sum(hits);
end