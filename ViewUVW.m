function ax=ViewUVW(adcp,options)

arguments
    adcp struct % data structure as output from GatherData()
    options.vmax (1,1) double=NaN % set max (-min) value for horizontal velocity colormap
    options.wmax (1,1) double=NaN % set max (-min) value for vertical velocity colormap
    options.title string=""
end

if ~isnan(options.vmax)
    vmax=options.vmax;
else
    vmax=max(abs(adcp.enu(:,1:2,:)),[],'all','omitnan'); 
end
if ~isnan(options.wmax)
    wmax=options.wmax;
else
    wmax=max(abs(adcp.enu(:,3,:)),[],'all','omitnan');
end

clabel=["u (m/s)" "v (m/s)" "w (m/s)" "error"];

fig=figure('Position',[10 10 2000 1000]);
T=tiledlayout(4,1,'tilespacing','tight','padding','compact');

for p=1:4
    ax(p)=nexttile;
    pcolor(adcp.time,adcp.config.ranges,squeeze(adcp.enu(:,p,:)))
    axis ij; shading flat
    cbar=colorbar;
    if p<4
        colormap(ax(p),cmocean('balance'));
        if p<3
            caxis([-vmax vmax])
        elseif p==3
            caxis([-wmax wmax])
        end
    end
    cbar.Label.String=clabel(p);
    set(gca,'FontSize',14,'Color','k')
    datetick('x')
    xlim([adcp.time(1) adcp.time(end)])
    if p==1 
        if strcmp(adcp.config.sampling,"Avg_mux")
            text(.98,1,"Multiplexed",'FontSize',14,'BackgroundColor','w','HorizontalAlignment','right','VerticalAlignment','top','Units','normalized')
        end
    end
end

sgtitle(options.title,'FontSize',16,'FontWeight','bold')


