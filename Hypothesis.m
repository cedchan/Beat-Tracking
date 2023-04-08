classdef Hypothesis < handle

    properties (SetAccess = private)
        period          % Predicted period
        phase           % Predicted phase (offset from start)
        scores = []     % Array of scores
        corrs = {}      % Cell array of corrections
    end

    methods
        % Constructor
        function obj = Hypothesis(period,phase)
            obj.period = period;
            obj.phase = phase;
        end

        

        % Returns projections from t ms back window ms
        function proj = project(self,t,window)
            % Start window ms back
            s = t-window;
            if s < 0
                error("At least "+window+" seconds needed to "+ ...
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
        function update(self,proj,onsets,mult,decay)
            corr = Correction(self,proj,onsets,mult,decay);

            % Add correction to list of corrections
            self.corrs{end+1} = corr;
            self.scores(end+1) = corr.score;
            
            % Update period and phase
            self.period = self.period+corr.deltaPeriod;
            self.phase = mod(self.phase+corr.deltaPhase,self.period);
        end
    end

    methods (Static)
        % Returns similarity measure from 0 to 1 for two hypotheses by
        % checking if phase and period are within a given delta of each
        % other.
        %
        % Inputs:
        %   hyp1: First hypothesis
        %   hyp2: Second hypothesis
        %   delta: Permissible range of similarity (ms)
        function sim = similar(hyp1,hyp2,delta)
            phaseSim = abs(hyp1.phase-hyp2.phase) <= delta;
            periodSim = abs(hyp1.period-hyp2.period) <= delta;
            sim = phaseSim && periodSim;
        end
    end
end