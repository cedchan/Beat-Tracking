classdef OnsetDetector < handle
    properties (SetAccess = private)
        cmplxDm     % Complex-domain spectrogram
        onsets      % Onset times in ms
        fs          % Sampling frequency
    end

    properties (Constant)
        WIND_N = 128 
        OVERLAP = 64
        MED_SHIFT = 0.05
        MED_SCALE = 1
    end

    methods        
        % Inputs:
        %   x: Audio vector
        %   fs: Sampling frequency of audio
        function obj = OnsetDetector(x,fs)
            obj.fs = fs;
            obj.detectFunc(x)
            obj.findPeaks()
        end
    end

    methods (Access = private)
        function detectFunc(self,x)
            % Length of both STFT window and moving median window (later)
            % Overlap of STFT windows
            S = stft(x,self.fs,'Window',hann(self.WIND_N),'OverlapLength',self.OVERLAP);
            nS = width(S);  % num of windowed segments
            
            % Amplitude
            amp = abs(S);
            amp1 = amp(:,3:nS);
            amp0 = amp(:,2:(nS-1));
            
            % Phase
            phase = angle(S);
            dPhase = phase(:,3:nS)-2*phase(:,2:(nS-1))+phase(:,1:(nS-2));
            
            % Rotated Euclidean distance
            dist = (amp1.^2+amp0.^2-2*amp1.*amp0.*cos(dPhase)).^0.5;
            
            % Complex domain calculation
            self.cmplxDm = sum(dist(1:height(dist)/2,:),1);
        end

        function findPeaks(self)
            % Normalize
            cd = self.cmplxDm;
            cd = (cd-mean(cd))/range(cd);
            
            % Low-pass filter
            fc = 600; % Cuttoff frequency (Hz)
            [b,a] = butter(6,fc/(self.fs/2));
            cd = filter(b,a,cd);
            cd = flip(filter(b,a,flip(cd))); % Apply on flipped for phase shift
            cd = max(cd,0);
            
            % Subtract moving median adaptive threshold
            threshold = self.MED_SHIFT+self.MED_SCALE*movmedian(cd,60*self.fs/1000);
            cd = max(cd-threshold,0); % Max is to cut off negative vals
            
            % Find local maxima as onsets
            timeFft = (0:(length(cd)-1))/self.fs*(self.WIND_N-self.OVERLAP);
            [~,peakLocs] = findpeaks(cd);
            self.onsets = timeFft(peakLocs);
        end
    end
end