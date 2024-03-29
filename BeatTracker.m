classdef BeatTracker < handle

    properties (SetAccess = immutable)
        window  % Note: Window must be greater than period
        mult
        decay
        delta
    end

    methods
        function obj = BeatTracker(window,mult,decay,delta)
            obj.window = window;
            obj.mult = mult;
            obj.decay = decay;
            obj.delta = delta;
        end

        function out = beats(self,x,fs)
            onsets = OnsetDetector(x,fs).onsets;
            model = BeatModel(onsets,self.window,self.mult,self.decay,self.delta);
            model.track();
            model.formatOut()
            out = model.out;
        end
    end
end