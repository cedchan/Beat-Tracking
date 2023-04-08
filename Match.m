classdef Match < handle
    properties (SetAccess = private)
        proj    % Index of projection
        dist    % Distance between projection and onset
        onset   % Index of onset
    end

    methods
        function obj = Match(proj,dist,onset)
            obj.proj = proj;
            obj.dist = dist;
            obj.onset = onset;
        end

        function update(self,proj,dist,onset)
            self.proj = proj;
            self.dist = dist;
            if exist("onset","var")
                self.onset = onset;
            end
        end
    end
end