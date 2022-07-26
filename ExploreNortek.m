% sample script for using NortekADCPTools to quickly explore data 


%% Identify and load file you wish to explore
clear
% filename="103461_DMCS_test_mux/DMCS_test_mux.ad2cp.00000.mat"; %must be .mat file as converted by MIDAS
filename="104007_test/test.ad2cp.00000.mat";
% filename="104007_BEAM235500/BEAM235500.ad2cp.00000.mat";
% filename="104007_TEST500b/TEST500b_.ad2cp.00000.mat";

load(filename)

%% Gather some select variables into a simplified structure 

adcp=GatherData(Config,Data);

%% Plot raw beam velocities 

% Use RemBTvel=1 as an input to have bottom track velocities removed from beam velocities
%   - note that in this sample data the bottom track velocities can be an order of magnitude larger than the beam velocities

Bax=ViewBeamData(adcp);

%% Fill in missing beams

opt=1; %opt=1 uses beam 5 for Z-matching if available, opt=2 runs a standard 3-beam solution
adcp_filled=FillBeams(adcp,'missing_beams',opt); 

%% Rotate to Earth coordinates
% identify data to be used
if isstruct(adcp_filled) 
    adcp_data=adcp_filled;
    fb=find(adcp_data.FilledBeams);
    num=length(fb);
    if num==1
        mb=string(fb);
    elseif num==2
        mb=string(fb(1))+" and "+string(fb(2));
    end
    tt="Missing beams "+mb+" have been filled";
else
    adcp_data=adcp;
    tt="No beams have been filled";
end

adcp_data=B2Erotation(adcp_data,UseBT=1);

%% Plot velocities in Earth coordinates
if strcmp(adcp_data.config.sampling,"Avg_mux")
    tt=tt+", Beams were multiplexed";
end
Eax=ViewUVW(adcp_data,title=tt);

