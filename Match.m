classdef Match < handle
    properties
        proj
        onset
        dist
    end

    methods
        function obj = Match(proj,onset,dist)
            obj.proj = proj;
            obj.onset = onset;
            obj.dist = dist;
        end
    end
end