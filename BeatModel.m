classdef BeatModel < handle
    properties (SetAccess = private)
        onsets      % List of sequential onsets in ms
        H = {}      % Cell array of current hypotheses
        out
    end

    properties (SetAccess = immutable)
        window  % Note: Window must be greater than period, or there will be many errors
        mult
        decay
        delta
    end

    methods
        % Constructor
        % 
        % Inputs:
        %   sampOnsets: List of sequential onsets in ms
        %   window: Size of sliding window for tracking in ms
        %   mult: Correction multiplier (see Correction.m)
        %   decay: Correction decay (see Correction.m)
        %   delta: Similarity tolerance threshold in ms (see Hypothesis.m)
        function obj = BeatModel(onsets,window,mult,decay,delta)
            obj.onsets = onsets;
            obj.window = window;
            obj.mult = mult;
            obj.decay = decay;
            obj.delta = delta;

            obj.out = zeros(length(onsets),6);
            obj.out(:,1) = obj.onsets';
        end

        % Main beat tracking function, based on onsets fed into program.
        function track(self)
            self.H = {};
            for on = 2:length(self.onsets)
                t = self.onsets(on);

                % Generate new hypothesis from current and previous onsets
                period = t-self.onsets(on-1);
                phase = mod(t,period);
                self.H{end+1} = Hypothesis(period,phase,on-1,on);

                % Calculate start time of window
                s = t-self.window; 
                
                % Skip if not enough time to window
                if s < 0
                    continue
                end

                % Get windowed onsets
                onsetWind = Util.getWindow(self.onsets,s,t);

                for h = 1:length(self.H)
                    hyp = self.H{h};
                    % Get windowed projection
                    proj = hyp.project(t,self.window);
    
                    % Update hypothesis:
                    %   1. Calculate correction in given window
                    %   2. Calculate score
                    %   3. Update hypothesis and store changes
                    hyp.update(proj,onsetWind,self.mult,self.decay)

                end
    
                % Iterate through every unique pair hyp1, hyp2 in H to delete 
                % ones that are too similar to each other.
                if length(self.H) < 2
                    continue
                end
                hypIdx = nchoosek(1:length(self.H),2);
                delete = [];
                for i = 1:height(hypIdx)
                    hyp1 = self.H{hypIdx(i,1)};
                    hyp2 = self.H{hypIdx(i,2)};
                    % If h1, h2 too similar, remove the most recent one (TODO:
                    % see if lower scoring is better)
                    if Hypothesis.similar(hyp1,hyp2,self.delta)
                        % Cell array deletion
                        delete(end+1) = hypIdx(i,2);
                    end
                end
                self.H(delete) = [];
            end
            self.findOptimum()
        end

        

        % Finds optimal beat at different times given score
        function findOptimum(self)
            % Rows: Onsets
            % Columns: Period, Phase, Score
            for h = 1:length(self.H)
                hyp = self.H{h};
                for on = 1:length(self.onsets)
                    t = self.onsets(on);
                    s = t-self.window; 
                    
                    % Skip if not enough time to window
                    if s < 0
                        continue
                    end
    
                    % Get windowed onsets
                    proj = hyp.project(t,self.window);
                    onsetWind = Util.getWindow(self.onsets,s,t);
   
                    matches = Util.closestPairs(proj,onsetWind);
                    score = Correction.calcScore(hyp,proj,onsetWind,matches);
                    if score > self.out(on,6)
                        self.out(on,2:6) = [hyp.startOn hyp.endOn hyp.period hyp.phase score];
                    end
                end
            end

            if height(self.out) < 2
                return
            end

            self.formatOut()
        end

        function outTab = formatOut(self)
            outTab = array2table(self.out(self.out(:,2) > 0,:), ...
                'VariableNames', ["Onset Time" "Hyp Start Ind" ...
                "Hyp End Ind" "Period" "Phase" "Score"]);
        end

        function fitted = fitHyp(self)
            % Create dict of [start end] to hypothesis
            hyps = dictionary();
            for h = 1:length(self.H)
                hyp = self.H{h};
                hyps({[hyp.startOn hyp.endOn]}) = hyp;
            end

%             fitted = table([],[],[],[],[],[],[],'VariableNames', ...
%                 ["Interval Start","Interval End","Hyp Start Ind", ...
%                 "Hyp End Ind","Period","Phase","Score"]);
            fitted = zeros(0,7);
            fitHyps = {};

            hypId = self.out(1,2:3);
            wind = [self.onsets(1) self.out(1,1)];

            for on = 2:length(self.onsets)
                nextId = self.out(on,2:3);

                if isequal(hypId,[0 0])
                    hypId = nextId;
                    continue
                end

                if isequal(hypId,nextId)
                    wind(2) = self.out(on,1);
                else
                    t = self.onsets(on);
                    windLen = wind(2)-wind(1);
                    s = t-windLen;
                    
                    % Skip if not enough time to window
                    if s < 0
                        continue
                    end
    
                    hyp = hyps({hypId});

                    % Get windowed onsets
                    proj = hyp.project(t,windLen);
                    onsetWind = Util.getWindow(self.onsets,s,t);
   
                    corr = Correction(hyp,proj,onsetWind,self.mult,self.decay);
                    
                    period = hyp.period+corr.deltaPeriod;
                    phase = hyp.phase+corr.deltaPhase;
                    hyp = Hypothesis(period,phase,hyp.startOn,hyp.endOn);
                    
                    fitHyps{end+1} = hyp; % TODO
                    fitted(end+1,:) = [wind(1) wind(2) hyp.startOn hyp.endOn hyp.period hyp.phase corr.score];

                    % Reset window
                    wind(1) = self.out(on,1);
                    hypId = nextId;
                end
            end

            % TODO handle last interval
        end

        % TODO ritardando??
    end
end