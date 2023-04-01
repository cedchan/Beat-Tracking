classdef Match < handle
    properties
        proj
        dist
        onset
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