classdef OnsetDetector < handle
    properties (SetAccess = private)
        spec    % Complex-domain spectrogram
        onsets  % Onset times in ms
    end

    methods        
        % Inputs:
        %   x: Audio vector
        %   fs: Sampling frequency of audio
        function obj = OnsetDetector(x,fs)
            obj.detectFunc(x,fs)
        end
    end

    methods (Access = private)
        function detectFunc(self,x,fs)
            S = stft(x,fs);
            nS = width(S);  % num of windowed segments
            amp = abs(S);
            amp1 = amp(:,3:nS);
            amp0 = amp(:,2:(nS-1));
            phase = angle(S);
            dPhase = phase(:,3:nS)-2*phase(:,2:(nS-1))+phase(:,1:(nS-2));
            dist = (amp1.^2+amp0.^2-2*amp1.*amp0.*cos(dPhase)).^0.5;
            self.spec = sum(dist(1:height(dist)/2),1);
        end
    end
end