function ax=ViewBeamData(adcp,options)

arguments
    adcp struct % data structure as output from GatherData()
    options.Vel logical=1 % select whether or not to plot velocities
    options.Amp logical=0 % select whether or not to plot echo amplitudes
    options.Cor logical=0 % select whether or not to plot correlations
    options.RemBTvel logical=0 % remove bottom tracked velocity if available
    options.vmax (1,1) double=NaN % set max (-min) value for velocity colormap
end
%ViewBeamData   Plots raw beam data (velocity, amplitude, and/or correlation) collected from Nortek Signature AD2CP
%   
%   ViewBeamData(adcp,options)  
%   
%   [ax,Config,Data,SampType] = ViewBeamData(adcp)    Plots timeseries of velocity for each beam contained in filename. 
%   Linkaxes is implemented for simpler examination of data. Returns axes handle(s) along with Config and Data 
%   structures from filename and the sampling strategy implemented.
% 
%   [ax,Config,Data,SampType] = ViewBeamData(adcp,options)    Plots timeseries for each beam contained in filename. 
%   Linkaxes is implemented for simpler examination of data. Use options to select which data to plot. There is also an option 
%   available to set the colorbar limits for velocity data. Returns axes handle(s) along with Config and Data structures 
%   from filename and the sampling strategy implemented.
% 
% INPUTS: 
%       adcp                        adcp data structure as formatted by GatherData()
%       options (Vel, Amp, Cor)     select which data to plot using logicals (ex: to plot amplitude, use Amp=1 as an input)
%                                   by default, Vel=1, Amp=0, Cor=0
%       options (RemBTvel)          when plotting velocity, first remove the bottom tracked velocity
%       options (vmax)              set limits for colorbar in velocity plots. Color bar limits will be symmetrical from
%                                   -vmax to vmax. If no value is given, vmax will be set by maximum magnitude of data.
% 
% OUTPUTS:
%       ax                          axes handle(s) for further customization of plots
%
% Requirements:
%       cmocean     https://www.mathworks.com/matlabcentral/fileexchange/57773-cmocean-perceptually-uniform-colormaps
%
% 
% Author:  Bridget Ovall        Created:    07/2022

%% Plot Data as Specified

%if velocity scale is not specified, use maximum of data (only velocity gets limits set)
if ~isnan(options.vmax)
    vmax=options.vmax;
else
    vmax=max(abs(adcp.vel),[],'all','omitnan'); 
end

% assess # of variables to be plotted
plotvars=sum([options.Vel options.Amp options.Cor]);

fig=figure('Position',[10 10 2000 1000]);
T=tiledlayout(adcp.config.n_beams*plotvars,1,'tilespacing','none','padding','tight');

% For plotting one variable:
if plotvars==1    
    T.TileSpacing='tight';
    if options.Vel==1
        if isfield(adcp,'bt_vel') && options.RemBTvel==1
            bv=permute(repmat(adcp.bt_vel,[1 1 adcp.config.n_cells]),[3 1 2]);
            data=adcp.vel-bv;
            note="bottom track velocity removed";
        else
            data=adcp.vel;
        end
        clabel="Beam Velocity (m/s)";
    elseif options.Amp==1
        data=adcp.echo_amp;
        clabel="Amplitude (dB)";
    elseif options.Cor==1
        data=adcp.corr;
        clabel="Correlation (%)";
    end
    p=1;
    for i=1:5
        if sum(~isnan(adcp.vel(:,i,:)),'all')~=0
            ax(p)=nexttile;
            pcolor(adcp.time,adcp.config.ranges,squeeze(data(:,i,:)))
            axis ij; shading flat
            hold on
            nn=length(adcp.bt_dist(1,:));
            plot(adcp.time(1:nn),adcp.bt_dist(i,:),'Color',[1 .5 0],'LineWidth',2)
            cbar=colorbar;
            if options.Vel==1
                colormap(ax(p),cmocean('balance'));
                caxis([-vmax vmax])
            end
            cbar.Label.String=clabel;
            if i==5
                title("Beam "+i+" (check time offset)")
            else
                title("Beam "+i)
            end
            set(gca,'FontSize',14,'Color','k')
            datetick('x')
            xlim([adcp.time(1) adcp.time(end)])
            if p==1 
                if strcmp(adcp.config.sampling,"Avg_mux")
                    text(.98,1,"Multiplexed",'FontSize',14,'BackgroundColor','w','HorizontalAlignment','right','VerticalAlignment','top','Units','normalized')
                end
                if exist('note','var')
                    text(.01,1,note,'FontSize',14,'BackgroundColor','w','VerticalAlignment','top','Units','normalized')
                end
            end
            p=p+1;
        end
    end
% For plotting two variables:
elseif plotvars==2
    if options.Vel==1
        if isfield(adcp,'bt_vel') && options.RemBTvel==1
            bv=permute(repmat(adcp.bt_vel,[1 1 adcp.config.n_cells]),[3 1 2]);
            data1=adcp.vel-bv;
            note="bottom track velocity removed";
        else
            data1=adcp.vel;
        end
        clabel1="Beam Velocity (m/s)";
        if options.Amp==1
            data2=adcp.echo_amp;
            clabel2="Amplitude (dB)";
        elseif options.Cor==1
            data2=adcp.corr;
            clabel2="Correlation (%)";
        end
    elseif options.Amp==1
        data1=adcp.echo_amp;
        clabel1="Amplitude (dB)";
        data2=adcp.corr;
        clabel2="Correlation(%)";
    end
    p=1;
    for i=1:5
        if sum(~isnan(adcp.vel(:,i,:)),'all')~=0
            ax(p)=nexttile;
            pcolor(adcp.time,adcp.config.ranges,squeeze(data1(:,i,:)))
            axis ij; shading flat
            hold on
            nn=length(adcp.bt_dist(1,:));
            plot(adcp.time(1:nn),adcp.bt_dist(i,:),'Color',[1 .5 0],'LineWidth',2)
            cbar1=colorbar;
            if options.Vel==1
                colormap(ax(p),cmocean('balance'));
                caxis([-vmax vmax])
            end
            cbar1.Label.String=clabel1;
            set(gca,'FontSize',14,'Color','k')
            datetick('x')
            xlim([adcp.time(1) adcp.time(end)])
            if i==5
                tt="Beam "+i+" (check time offset)";
            else
                tt="Beam "+i;
            end
            text(.5,1,tt,'Color','k','FontSize',18,'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','top','Units','normalized')
            if p==1 
                if strcmp(adcp.config.sampling,"Avg_mux")
                    text(.98,1,"Multiplexed",'FontSize',14,'BackgroundColor','w','HorizontalAlignment','right','VerticalAlignment','top','Units','normalized')
                end
                if exist('note','var')
                    text(.01,1,note,'FontSize',14,'BackgroundColor','w','VerticalAlignment','top','Units','normalized')
                end
            end
            p=p+1;

            ax(p)=nexttile;
            pcolor(adcp.time,adcp.config.ranges,squeeze(data2(:,i,:)))
            axis ij; shading flat
            hold on
            plot(adcp.time(1:nn),adcp.bt_dist(i,:),'Color',[1 .5 0],'LineWidth',2)
            cbar2=colorbar;
            cbar2.Label.String=clabel2;
            set(gca,'FontSize',14,'Color','k')
            datetick('x')
            xlim([adcp.time(1) adcp.time(end)])  
            p=p+1;
        end
    end
% For plotting three variables:
elseif plotvars==3
    p=1;
    for i=1:5
        if sum(~isnan(adcp.vel(:,i,:)),'all')~=0
            ax(p)=nexttile;
            if isfield(adcp,'bt_vel') && options.RemBTvel==1
                bv=permute(repmat(adcp.bt_vel,[1 1 adcp.config.n_cells]),[3 1 2]);
                pcolor(adcp.time,adcp.config.ranges,squeeze(adcp.vel(:,i,:)-bv(:,i,:)))
                note="bottom track velocity removed";
            else
                pcolor(adcp.time,adcp.config.ranges,squeeze(adcp.vel(:,i,:)))
            end
            axis ij; shading flat
            hold on
            nn=length(adcp.bt_dist(1,:));
            plot(adcp.time(1:nn),adcp.bt_dist(i,:),'Color',[1 .5 0],'LineWidth',2)
            cbar1=colorbar;
            colormap(ax(p),cmocean('balance'));
            caxis([-vmax vmax])
            cbar1.Label.String="Vel (m/s)";
            set(gca,'FontSize',14,'Color','k')
            datetick('x')
            xlim([adcp.time(1) adcp.time(end)])
            if i==5
                tt="Beam "+i+" (check time offset)";
            else
                tt="Beam "+i;
            end
            text(.5,1,tt,'Color','k','FontSize',18,'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','top','Units','normalized')
            if p==1
                if strcmp(adcp.config.sampling,"Avg_mux")
                    text(.98,1,"Multiplexed",'FontSize',14,'BackgroundColor','w','HorizontalAlignment','right','VerticalAlignment','top','Units','normalized')
                end
                if exist('note','var')
                    text(.01,1,note,'FontSize',14,'BackgroundColor','w','right','VerticalAlignment','top','Units','normalized')
                end
            end
            p=p+1;

            ax(p)=nexttile;
            pcolor(adcp.time,adcp.config.ranges,squeeze(adcp.echo_amp(:,i,:)))
            axis ij; shading flat
            hold on
            plot(adcp.time(1:nn),adcp.bt_dist(i,:),'Color',[1 .5 0],'LineWidth',2)
            cbar2=colorbar;
            cbar2.Label.String="Amp (dB)";
            set(gca,'FontSize',14,'Color','k')
            datetick('x')
            xlim([adcp.time(1) adcp.time(end)])  
            p=p+1;

            ax(p)=nexttile;
            pcolor(adcp.time,adcp.config.ranges,squeeze(adcp.corr(:,i,:)))
            axis ij; shading flat
            hold on
            plot(adcp.time(1:nn),adcp.bt_dist(i,:),'Color',[1 .5 0],'LineWidth',2)
            cbar3=colorbar;
            colormap(ax(p),parula)
            cbar3.Label.String="Corr (%)";
            set(gca,'FontSize',14,'Color','k')
            datetick('x')
            xlim([adcp.time(1) adcp.time(end)])
            p=p+1;
        end
    end
end 
    
ylabel(T,"Distance Range (m)",'FontSize',16);
xlabel(T,"Time",'FontSize',16);
linkaxes(ax)






