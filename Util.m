classdef Util
    methods (Static)
        % Finds closest onset to each projected beat, without repetition. If two
        % projections are closest to the same onset, the closer one wins. Truncates
        % if there are not enough beats in either.
        % 
        % Inputs:
        %   proj: Projected beats times in ms
        %   onsets: Actual onset times in ms
        function matches = closestPairs(proj,onsets)
            projN = length(proj);
            onsetsN = length(onsets);

            if projN == 0 || onsetsN == 0
                matches = {};
                return
            end

            pair = zeros(1,projN);      % Tracks index of closest onset per proj 
            dist = Inf(1,projN);        % Tracks distance of closest onset
            
            % Find every proj's closest onset
            pair(1) = 1;
            dist(1) = abs(proj(1)-onsets(pair(1)));
            for i = 1:projN
                if i ~= 1
                    % initialize to prev proj's match 
                    pair(i) = pair(i-1);
                end
                dist(i) = abs(proj(i)-onsets(pair(i)));
        
                if pair(i) < onsetsN
                    newDist = abs(proj(i)-onsets(pair(i)+1)); % inital dist
                    while pair(i) < onsetsN-1 && newDist < dist(i)
                        pair(i) = pair(i)+1;
                        dist(i) = newDist;
                        newDist = abs(proj(i)-onsets(pair(i)+1));
                    end
                end
            end
        
            % Find best matches
        
            % Truncates to smaller of onset/projection vectors
            matchesN = min(projN,onsetsN);
            % Space allocate matches cell array (note that cell array is stored
            % indices, not proj/onset values)
            matches = cell(1,matchesN);
            % Initialize first match to first pair
            matches{1} = Match(1,dist(1),pair(1));
            % Index of fully matched pairs
            matchIdx = 1;
            for i = 2:projN
                if matches{matchIdx}.onset ~= pair(i)
                    % If no conflict with most recent pair, adds to next idx
                    matches{matchIdx+1} = Match(i,dist(i),pair(i));
                    matchIdx = matchIdx+1;
                elseif dist(i) < matches{matchIdx}.dist
                    % If conflicts with recent pair, but has shorter distance,
                    % kicks recent pair using 'feedBack()' and overrides recent.
                    [matches,matchIdx] = feedBack(proj,onsets,matches,matchIdx);
                    matches{matchIdx} = Match(i,dist(i),pair(i)); % TODO: CHECK
                elseif matchIdx < matchesN
                    % If conflicts but has less than or equal distance, sets
                    % closest match to next onset, so long as it's in bounds.
                    newDist = abs(proj(i)-onsets(pair(i)+1));
                    matches{matchIdx+1} = Match(i,newDist,pair(i)+1);
                    matchIdx = matchIdx+1;
                end
            end

            % Remove empty cells
            matches = matches(~cellfun('isempty',matches));
        end

        
        % Returns a subset of a given vector, where values are in a certain 
        % range.
        %
        % Inputs:
        %   x: Vector to get window of
        %   s: Start of window (inclusive)
        %   t: End of window (inclusive)
        function window = getWindow(x,s,t)
            window = x(s <= x & x <= t);
        end
    end
end


% Recursively kicks a given index to it's next closest pair backward, until
% there are no outstanding losing conflicts.
%
% Inputs:
%   proj: Projected beats times in ms
%   onsets: Actual onset times in ms
%   matches: Cell array of current matches (in indices) to fix
%   i: Index to start fixing backward from 
function [matches,matchIdx] = feedBack(proj,onsets,matches,i)
    matchIdx = i;

    if i <= 0 || matches{i}.onset <= 1
        % Does nothing if there are no other possible matches.
        return
    end

    old = matches{i}.proj;
%     candidate = matches{i-1}.onset;
    candidate = matches{i}.onset-1;
    newDist = abs(proj(old)-onsets(candidate));

    if i == 1 || matches{i-1}.onset ~= candidate
        % Immedietly updates if no conflict with previous match.
        matches{i}.update(i,newDist,candidate)
        matchIdx = matchIdx+1;
    elseif newDist < matches{i-1}.dist
        % If conflicts, overrides if there's shorter distance
        matches = feedBack(proj,onsets,matches,i-1);
        matches{i-1}.update(i,newDist);
    end
end