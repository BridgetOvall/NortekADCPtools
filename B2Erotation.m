function adcp=B2Erotation(adcp,options)

arguments
    adcp struct % data structure as output from GatherData() - requires data for beams 1-4 (use FillBeams() for missing beams)
    options.b5weight (1,1) {mustBeInRange(options.b5weight,0,1)}=0 % set weighting for beam 5 influence on vertical velocity (values can be 0-1, with zero meaning disregard beam 5 and 1 meaning completely beam 5)
    options.UseBT logical=0 %select whether or not to remove ship velocity using bottom tracking velocity
    options.UseGPSvel logical=0 %select whether or not to remove ship velocity using velocity from GPS
    options.UseIntHead logical=1 %select whether to use internal or gps heading
end

% Note: For downward-facing ADCP: roll will read ~180, which will take care of rotating the reference frame so that + Z is up

%remove beam 5 position if beam 5 was not used
if all(isnan(adcp.vel(:,5,:)),'all')
    vel = adcp.vel(:,1:4,:);
else
    vel=adcp.vel;
end
% get velocity dimensions
[nc, nb, nt] = size(vel);

% determine how to use beam 5
K=options.b5weight;
if nb==4
    K=0;
end
K1=1-K;
%% Remove ship velocity if using bottom tracking
if options.UseBT==1
    if options.UseGPSvel==1
        error("Cannot use both bottom tracking and GPS to remove ship velocity")
    elseif ~isfield(adcp,'bt_vel')
        error("There is not bottom tracking data to remove")
    else
        bt_vel=adcp.bt_vel(1:nb,:);
        bt_vel=permute(repmat(bt_vel,1,1,50),[3 1 2]);
        vel=vel-bt_vel;
    end
end     

%% Beam to instrument transformation

% adjust beam to instrument transformation matrix
%   - combine Z rows to get just one vertical velocity
%   - add a row for error velocity
%   - add a column for beam 5, if necessary
ZZ=adcp.config.B2I(3,:)+adcp.config.B2I(4,:);
B2I=[adcp.config.B2I(1:2,:); K1*ZZ; [ZZ(1) -ZZ(2) ZZ(3) -ZZ(4)]];
if nb==5
    B2I=[B2I [0; 0; K; 0]];
end

vb=reshape(permute(vel,[3 1 2]),nc*nt,nb);
vi=(B2I*vb')';

%% Instrument to Earth transformation
if options.UseIntHead==1
% offset heading value so that it refers to the heading of the Y-axis (will be rotated to N-S velocity)
    offset=90;  
    head=adcp.head-offset;
end
angles=[-adcp.roll -adcp.pitch head];
q=quaternion(angles,'eulerd','XYZ','frame');
% repeat quat for each depth cell
I2Equat=repmat(q,nc,1);
% rotate to Earth coordinates
ve=rotateframe(I2Equat,vi(:,1:3));
% attach error velocities
ve=[ve vi(:,4)];
% reshape to original size
adcp.enu=permute(reshape(ve',4,nt,nc),[3 1 2]);

%% Remove ship velocity if using GPS
if options.UseGPSvel==1
    disp("Umm...So, you see...I haven't actually gotten all the GPS stuff worked out. But, here are your velocities with the ship speed still included. :)")
end

end






