function adcp=GatherData(Config,Data)
%GatherData   Pulls key portions of raw beam data (velocity, amplitude, and correlation) collected from Nortek Signature AD2CP
%   
%   GatherData(Config,Data)  
%   
%   adcp = GatherData(Config,Data)    
%       Sorts through Config and Data structures to get relevant data and combines them into one simplified structure
% 
% 
% INPUTS: 
%       Config          Config structure from .mat file as converted by MIDAS
%       Data            Data structure from .mat file as converted by MIDAS
% 
% OUTPUTS:
%       adcp            structure containing the following fields:    
%           config          structure containing the following fields:
%               sampling        data sampling routine: "Burst", "Avg", or "Avg_mux"
%               n_beams         number of beams used
%               n_cells         number of depth cells
%               beam_angle      angle of side beams
%               ranges          distance to each depth bin
%               B2I             beam-to-instrument rotation matrix
%           time            sample time for side beams (note that the vertical beam data is offset from this time)
%           b5_time         (if beam 5 is used) sample time of beam 5 samples 
%           vel             matrix of velocity data, packed as ranges x beam x time
%           corr            matrix of correlation data, packed as ranges x beam x time
%           echo_amp        matrix of echo amplitude data, packed as ranges x beam x time
%           bt_dist         (if bottom tracking is used) distance to bottom, packed as beam x time
%           bt_vel          (if bottom tracking is used) relative bottom velocity for each beam, packed as ranges x beam x time
%           head            heading from internal sensor
%           pitch           pitch from internal sensor
%           roll            roll from internal sensor
%           
% 
% Author:  Bridget Ovall        Created:    07/2022

if Config.burst_enable==1
    adcp.config.sampling="Burst";
    adcp.config.n_beams=Config.burst_activeBeams;
    if adcp.config.n_beams==5 || contains(num2str(Config.burst_channelMapping),'5')
        sb=adcp.config.n_beams-1; getB5=1;
        beamID=[Data.Burst_Physicalbeam(1,1:sb) 5];
    else
        sb=adcp.config.n_beams; getB5=0;
        beamID=Data.Burst_Physicalbeam(1,1:sb);
    end   
    adcp.config.n_cells=Config.burst_nCells;
    adcp.config.beam_angle=Config.beamConfiguration1_theta;
    adcp.config.ranges=Data.Burst_Range;
    adcp.time=Data.Burst_MatlabTimeStamp;
    nr=length(adcp.config.ranges);
    nt=length(adcp.time);
    adcp.vel=NaN(nr,5,nt); adcp.corr=NaN(nr,5,nt); adcp.echo_amp=NaN(nr,5,nt); 
    for i=1:sb
        Velfn="Burst_VelBeam"+beamID(i);
        adcp.vel(:,beamID(i),:)=Data.(Velfn)';
        Corfn="Burst_CorBeam"+beamID(i);
        adcp.corr(:,beamID(i),:)=Data.(Corfn)';
        Ampfn="Burst_AmpBeam"+beamID(i);
        adcp.echo_amp(:,beamID(i),:)=Data.(Ampfn)';
    end
    if Config.burst_bottomTrack==1
        adcp.bt_dist=NaN(5,nt); adcp.bt_vel=NaN(5,nt);
        for i=1:4
            BTdistfn="BurstBT_DistanceBeam"+i;
            ln=length(Data.(BTdistfn));
            adcp.bt_dist(i,1:ln)=Data.(BTdistfn)';
            BTvelfn="BurstBT_VelBeam"+i;
            adcp.bt_vel(i,1:ln)=Data.(BTvelfn)';
        end
    end
    if getB5==1
        adcp.b5_time=Data.IBurst_TimeStamp;
        adcp.vel(:,5,:)=Data.IBurst_VelBeam5';
        adcp.corr(:,5,:)=Data.IBurst_CorBeam5';
        adcp.echo_amp(:,5,:)=Data.IBurst_AmpBeam5';
        adcp.bt_vel(5,1:ln)=zeros(1,ln);
    end
    adcp.head=Data.Burst_Heading;
    adcp.pitch=Data.Burst_Pitch;
    adcp.roll=Data.Burst_Roll;
    adcp.config.B2I=reshape(Config.burst_beam2xyz,[4 4])';
elseif Config.avg_enable==1
    adcp.config.sampling="Avg";
    if Config.avg_mux==1
        adcp.config.sampling=adcp.config.sampling+"_mux";
    end
    adcp.config.n_beams=Config.avg_activeBeams; 
    if adcp.config.n_beams==5 || contains(num2str(Config.avg_channelMapping),'5')
        sb=adcp.config.n_beams-1; getB5=1;
        beamID=[Data.Average_Physicalbeam(1,1:sb) 5];
    else
        sb=adcp.config.n_beams; getB5=0;
        beamID=Data.Average_Physicalbeam(1,1:sb);
    end   
    adcp.config.n_cells=Config.avg_nCells;
    adcp.config.beam_angle=Config.beamConfiguration1_theta;
    adcp.config.ranges=Data.Average_Range;
    adcp.time=Data.Average_MatlabTimeStamp;
    nr=length(adcp.config.ranges);
    nt=length(adcp.time);
    adcp.vel=NaN(nr,5,nt); adcp.corr=NaN(nr,5,nt); adcp.echo_amp=NaN(nr,5,nt); 
    for i=1:sb
        Velfn="Average_VelBeam"+beamID(i);
        adcp.vel(:,beamID(i),:)=Data.(Velfn)';
        Corfn="Average_CorBeam"+beamID(i);
        adcp.corr(:,beamID(i),:)=Data.(Corfn)';
        Ampfn="Average_AmpBeam"+beamID(i);
        adcp.echo_amp(:,beamID(i),:)=Data.(Ampfn)';
    end
    if Config.avg_bottomTrack==1
        adcp.bt_dist=NaN(5,nt); adcp.bt_vel=NaN(5,nt);
        for i=1:4
            BTdistfn="AverageBT_DistanceBeam"+i;
            ln=length(Data.(BTdistfn));
            adcp.bt_dist(i,1:ln)=Data.(BTdistfn)';
            BTvelfn="AverageBT_VelBeam"+i;
            adcp.bt_vel(i,1:ln)=Data.(BTvelfn)';
        end
    end
    if getB5==1
        adcp.b5_time=Data.IAverage_TimeStamp;
        adcp.vel(:,5,:)=Data.IAverage_VelBeam5';
        adcp.corr(:,5,:)=Data.IAverage_CorBeam5';
        adcp.echo_amp(:,5,:)=Data.IAverage_AmpBeam5';
        adcp.bt_vel(5,1:ln)=zeros(1,ln);
    end    
    adcp.head=Data.Average_Heading;
    adcp.pitch=Data.Average_Pitch;
    adcp.roll=Data.Average_Roll;
    adcp.config.B2I=reshape(Config.avg_beam2xyz,[4 4])';
end








