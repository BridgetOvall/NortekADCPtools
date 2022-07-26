
function adcp = FillBeams(adcp,purpose,opt)
%FillBeams      Calculates values for missing beam data by assuming zero error velocity
%
%   FillBeams(adcp,purpose,opt) 
%   
%   adcp = FillBeams(adcp,purpose,opt)  Uses available beam velocities and assumption of zero error velocity to calculate
%       missing beam data according to the opt specification. Available beam data is assessed and an error is thrown if
%       it does not meet the requirements of the specified purpose
% 
% INPUTS:
%       adcp        adcp data structure as formatted by GatherData()
%       purpose     Use 'missing_beams' to calculate values for beams turned off during sampling
%                   Use 'masked_data' to calculate values for beam data that is masked over discrete portions of time/space
%       opt         (set as 1 or 2) With a 5-beam ADCP, there are two options for setting error velocity to zero. With opt=1,
%                   if one side beam from a pair is missing, Z for that pair of beams is set equal to beam 5 velocity. Missing
%                   values can be calculated for two beams as long as they are not from the same pair. With opt=2, if one side
%                   beam from a pair is missing, Z for that pair of beams is set equal to Z from the other pair (standard 
%                   three-beam solution). Missing data can only be calculated in the case of one missing side beam. If beam 5
%                   was not used, opt will be ignored.
% 
% OUTPUTS:
%       adcp        data structure with missing beam data filled in and a field added (FilledBeams) that specifies which beams 
%                   are calculated values
%                   note:   if no beams are missing, returns empty vector
%                           if unable to fill beams (too many beams missing or user doesn't confirm continue), returns NaN
% 
% This is a modified version of Dylan Winters' prep_nbeam_solutions - Bridget Ovall 7/2022
%       - check for existing data in beam 5 column to assess whether this should be considered a 4-beam or 5-beam ADCP
%       - added data verifications for either 'missing_beams' or 'masked_data'
%       - added options for Z-matching
%



% GatherData() creates a matrix of NaNs with space for 5 beams and then fills in columns for the beams actually used
% Reduce size of matrix if no data exists for beam 5
if all(isnan(adcp.vel(:,5,:)))
    adcp.vel = adcp.vel(:,1:4,:);
end

% get velocity dimensions
[nc, nb, nt] = size(adcp.vel);

% reshape velocity matrix to columns of beam data
vb=reshape(permute(adcp.vel,[3 1 2]),nc*nt,nb);

% create a logical mask for NaN-valued beam data, i.e.
% 1 0 0 0 0 <-- beam 1 is bad
% 0 0 1 0 0 <-- beam 3 is bad
% 0 0 0 1 1 <-- beams 4 & 5 are bad, etc.
bmask = isnan(vb);

% Find all combinations of bad beams. These are just the unique rows of the above matrix.
[bad_beams, ~, type] = unique(bmask,'rows');

% run some checks depending on the purpose for filling beam data
if strcmp(purpose,'missing_beams')
    % end function if there are no missing beams or if data is missing over discrete portions of time/space
    if sum(bad_beams)==0
        disp("no missing beams")
        adcp=[];
        return
    elseif size(bad_beams,1)>1 && sum(bad_beams(2,:)~=nb) %allowed to continue if only other scenario is when all beams are missing
        disp("discrete portions of data missing")
        disp("bad_beams = ")
        disp(bad_beams)
        adcp=NaN;
        return
    end
    % identify which beams will be filled (caution will need to be taken if there is later masking of discrete data to be filled) 
    adcp.FilledBeams=bad_beams;
elseif strcmp(purpose,'masked_data')
    if isfield(adcp,'FilledBeams')
        xx=input('Some beams have already been filled.\nDo you want to continue? Y/N','s');
        if isempty(xx)
            xx='N';
        end
        if xx~='Y' && xx~='y'
            disp('missing data has not been filled')
            adcp=NaN;
            return
        end
    end
end
    
% Also define a function to convert arbitrary combinations of bad beams to unique integers by treating these rows as binary numbers:
id =@(bad_beams) sum(2.^bad_beams); 

% Loop over all types of bad beam combinations and fill in masked velocity data
% where possible.
for i = 1:size(bad_beams,1)
    % Get the indices of velocity entries with this type of beam failure
    idx = type == i;
    c = 1/(2*sind(adcp.config.beam_angle));

    % ====== 3-beam solutions for 4-beam ADCP ====== %
    if nb==4
    switch id(find(bad_beams(i,:)))
      % ====== 1 side beam bad ====== %
      % The best we can do with a 4-beam ADCP is set error velocity equal to
      % zero, i.e. impose that the estimate of Z velocity from both beam
      % pairs is equal, then solve for the missing beam. Beam 1 example:
      %
      %     Z1 = c*v1 + c*v3     (1) Z estimate from 1st beam pair
      %     Z2 = c*v2 + c*v4     (2) Z estimate from 2nd beam pair
      %
      % Then impose Z1 = Z2 and solve for v1:
      %
      %     c*v1 + c*v3 = c*v2 + c*v4
      %     ===>     v1 = v2 + v4 - v3
      %
      % Similar for other beams.
      case id(1) % only beam 1 bad
        % c*v1 + c*v3 = c*v2 + c*v4
        % ===>     v1 = v2 + v4 - v3
        vb(idx,1) = vb(idx,2) + vb(idx,4) - vb(idx,3);

      case id(2) % only beam 2 bad
        % c*v1 + c*v3 = c*v2 + c*v4
        % ===>     v2 = v1 + v3 - v4
        vb(idx,2) = vb(idx,1) + vb(idx,3) - vb(idx,4);

      case id(3) % only beam 3 bad
        % c*v1 + c*v3 = c*v2 + c*v4
        % ===>     v3 = v2 + v4 - v1
        vb(idx,3) = vb(idx,2) + vb(idx,4) - vb(idx,1);

      case id(4) % only beam 3 bad
        % c*v1 + c*v3 = c*v2 + c*v4
        % ===>     v4 = v1 + v3 - v2
        vb(idx,4) = vb(idx,1) + vb(idx,3) - vb(idx,2);
    end
    end

    % ====== 3- and 4-beam solutions for 5-beam ADCP ====== %
    if nb==5
        if opt==1 %using beam 5 for Z matching, let NaNs feed through if beam 5 is bad
            switch id(find(bad_beams(i,:)))

            % ====== 1 side beam bad ====== %
            % Each opposite-side pair of side beams gives an estimate of Z velocity. With
            % a single bad side beam, we can impose that its pair's estimate of Z velocity
            % is equal to beam 5's measurement, and reconstruct the bad beam's velocity.
            %
            % For example, if beam 1 is bad (c is a scale factor depending on beam angle):
            %
            % If opt=1,
            %     Z1 = c*v1 + c*v3   (1) Z velocity estimate from combining beams 1 & 2
            %     Z2 = v5            (2) Z velocity estimate directly from beam 5
            %
            % By imposing that Z1 = Z2, we can combine (1) and (2) to solve for v1:
            %
            %     v5 = c*v1 + c*v3
            % ==> v1 = (v5 - c*v3)/c
            %
            % Then for all entries where only beam 1 is NaN, we set beam 1 velocity to
            % (v5 - c*v2)/c
            %
            % The process is similar for any single bad side beam.
            %
            % If opt=2, set Z2 = c*v2 + c*v4 and solve for v1

            case id(1) % only beam 1 bad, as in example above
            %     v5 = c*v1 + c*v3
            % ==> v1 = (v5 - c*v3)/c
            vb(idx,1) = (vb(idx,5) - c*vb(idx,3))/c;

            case id(2) % only beam 2 bad
            %     v5 = c*v2 + c*v4
            % ==> v2 = (v5 - c*v4)/c
            vb(idx,2) = (vb(idx,5) - c*vb(idx,4))/c;

            case id(3) % only beam 3 bad
            %     v5 = c*v1 + c*v3
            % ==> v3 = (v5 - c*v1)/c
            vb(idx,3) = (vb(idx,5) - c*vb(idx,1))/c;

            case id(4) % only beam 4 bad
            %     v5 = c*v2 + c*v4
            % ==> v4 = (v5 - c*v2)/c
            vb(idx,4) = (vb(idx,5) - c*vb(idx,2))/c;

            % ====== 2 side beams bad ====== %
            % Because we can handle a single bad beam from the 1&3 beam pair and the
            % 2&4 beam pair independently, we can also handle cases where a single
            % beam is bad for both pairs:

            case id([1,2]) % beams 1 & 2 bad
            %     v5 = c*v1 + c*v3
            % ==> v1 = (v5 - c*v3)/c
            vb(idx,1) = (vb(idx,5) - c*vb(idx,3))/c;
            %     v5 = c*v2 + c*v4
            % ==> v2 = (v5 - c*v4)/c
            vb(idx,2) = (vb(idx,5) - c*vb(idx,4))/c;

            case id([1,4]) % beams 1 & 4 bad
            %     v5 = c*v1 + c*v3
            % ==> v1 = (v5 - c*v3)/c
            vb(idx,1) = (vb(idx,5) - c*vb(idx,3))/c;
            %     v5 = c*v2 + c*v4
            % ==> v4 = (v5 - c*v2)/c
            vb(idx,4) = (vb(idx,5) - c*vb(idx,2))/c;

            case id([2,3]) % beams 2 & 3 bad
            %     v5 = c*v2 + c*v4
            % ==> v2 = (v5 - c*v4)/c
            vb(idx,2) = (vb(idx,5) - c*vb(idx,4))/c;
            %     v5 = c*v1 + c*v3
            % ==> v3 = (v5 - c*v1)/c
            vb(idx,3) = (vb(idx,5) - c*vb(idx,1))/c;

            case id([3,4]) % beams 3 & 4 bad
            %     v5 = c*v1 + c*v3
            % ==> v3 = (v5 - c*v1)/c
            vb(idx,3) = (vb(idx,5) - c*vb(idx,1))/c;
            %     v5 = c*v2 + c*v4
            % ==> v4 = (v5 - c*v2)/c
            vb(idx,4) = (vb(idx,5) - c*vb(idx,2))/c;

            end
            
        elseif opt==2 %set Z equal to estimate from other pair, let NaNs feed through if one beam from each pair is bad
            switch id(find(bad_beams(i,:)))

            % ====== 1 side beam bad ====== %
            % without using beam 5, this is the typical 3-beam solution
            case id(1) % only beam 1 bad 
            % c*v1 + c*v3 = c*v2 + c*v4
            % ===>     v1 = v2 + v4 - v3
            vb(idx,1) = vb(idx,2) + vb(idx,4) - vb(idx,3);

            case id(2)  % only beam 2 bad 
            % c*v1 + c*v3 = c*v2 + c*v4
            % ===>     v2 = v1 + v3 - v4
            vb(idx,2) = vb(idx,1) + vb(idx,3) - vb(idx,4);

            case id(3) % only beam 3 bad 
            % c*v1 + c*v3 = c*v2 + c*v4
            % ===>     v3 = v2 + v4 - v1
            vb(idx,3) = vb(idx,2) + vb(idx,4) - vb(idx,1);

            case id(4) % only beam 4 bad 
            % c*v1 + c*v3 = c*v2 + c*v4
            % ===>     v4 = v1 + v3 - v2
            vb(idx,4) = vb(idx,1) + vb(idx,3) - vb(idx,2);

            % ====== 1 side beam and 5th beam bad ====== %
            % This is the same calculation as above
            case id([1,5]) % beams 1 and 5 bad
            % c*v1 + c*v3 = c*v2 + c*v4
            % ===>     v1 = v2 + v4 - v3
            vb(idx,1) = vb(idx,2) + vb(idx,4) - vb(idx,3);

            case id([2,5]) % beams 2 and 5 bad
            % c*v1 + c*v3 = c*v2 + c*v4
            % ===>     v2 = v1 + v3 - v4
            vb(idx,2) = vb(idx,1) + vb(idx,3) - vb(idx,4);

            case id([3,5]) % beams 3 and 5 bad
            % c*v1 + c*v3 = c*v2 + c*v4
            % ===>     v3 = v2 + v4 - v1
            vb(idx,3) = vb(idx,1) + vb(idx,2) - vb(idx,4);

            case id([4,5]) % beams 4 and 5 bad
            % c*v1 + c*v3 = c*v2 + c*v4
            % ===>     v4 = v1 + v3 - v2
            vb(idx,4) = vb(idx,1) + vb(idx,3) - vb(idx,2);

%             % ===== Beam 5 bad ===== %              ** NOT SURE IF THIS WOULD EVER BE NECESSARY **            
%             case id(5) % only beam 5 bad, set to average Z from beam pairs
%             %     v5 = c/2*(v1+v2+v3+v4)
%             vb(idx,5) = c/2*(vb(idx,1) + vb(idx,2) + vb(idx,3) + vb(idx,4));

            end
            
        end
    end
end
% Reshape beam velocity to original size and store in adcp struct
adcp.vel = permute(reshape(vb',nb,nt,nc), [3 1 2]);
