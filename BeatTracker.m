classdef BeatTracker < handle
    properties (SetAccess = private)
        onsets      % List of sequential onsets in ms
        H = {}      % Cell array of current hypotheses
    end

    methods
        % Constructor
        % 
        % Inputs:
        %   sampOnsets: List of sequential onsets in ms
        function obj = BeatTracker(sampOnsets)
            obj.onsets = sampOnsets;
        end

        % Main beat tracking function, based on onsets fed into program.
        function track(self)
            self.H = {};
            % append to H all new generated hypothesis trackings
            for hyp = self.H 
                % find first onset r_s > r_t - 6s
                % define correction delta_h for hyp according to (r_s..t)
                % update hyp.phase, hyp.period based on delta_h
                % score hyp based on (r_s..t)
                % append delts_h to hyp's internal corr list 
                % append score to hyp's internal scores list
            end

            % Iterate through every unique pair hyp1, hyp2 in H to delete 
            % ones that are too similar to each other.
            m = nchoosek(1:length(self.H),2);
            for i = 1:height(m)
                hyp1 = self.H{m(i,1)};
                hyp2 = self.H{m(i,2)};
                % if h1, h2 too similar, remove the most recently created
            end
        end
    end
end