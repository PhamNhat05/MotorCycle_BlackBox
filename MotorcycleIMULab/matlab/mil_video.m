function mil_video(directory,C,M,variant)
% Full source-time coverage. A moving camera does not constrain world position.
if nargin<3,S=load(fullfile(directory,'MODEL.mat'),'M');M=S.M;end
isVariant=nargin>=4;
if isVariant
 r=variant.position_body_m;b=variant.bias;base=sprintf('VARIANT_%04d',variant.variant_index);
else
 r=M.K.nominal_position_body_m;b=M.K.bias;base='FULL_RECORD_SIMULATION';
 if isfile(fullfile(directory,'VIDEO_STATUS.json'))
  old=jsondecode(fileread(fullfile(directory,'VIDEO_STATUS.json')));if strcmp(old.status,'COMPLETE') && isfile(fullfile(directory,old.filename)),return;end
 end
end
fprintf('  Rendering %s | full %.3f to %.3f s | %.1fx playback\n',M.key,M.time_source_s(1),M.time_source_s(end),C.video.playback_speed);
frameT=(M.time_source_s(1):C.video.playback_speed/C.video.frame_rate:M.time_source_s(end))';
if frameT(end)<M.time_source_s(end)-1e-9,frameT(end+1)=M.time_source_s(end);end
Z=mil_query(M,frameT,r,b);N=numel(frameT);allQ=mil_query(M,M.time_source_s,r,b);
measured=M.measured_imu;
ids=mil_display_indices([measured allQ.imu],C.video.maximum_plot_bins);
f=figure('Visible','off','Color','w','Position',[20 20 C.video.width C.video.height]);cl=onCleanup(@()close(f));
ax=axes(f,'Position',[.035 .29 .43 .64]);hold(ax,'on');grid(ax,'on');axis(ax,'equal');view(ax,[125 20]);
xlim(ax,[-1.6 1.6]);ylim(ax,[-1.5 1.5]);zlim(ax,[-1.3 1.5]);xlabel(ax,'World X');ylabel(ax,'World Y');zlabel(ax,'World Z');
title(ax,{'Body-centered camera; orientation in world axes','Rigid rider illustration; no road/contact constraint'});
g=hgtransform('Parent',ax);mil_geometry(g,r);
plot3(ax,[0 .6],[0 0],[0 0],'r-');plot3(ax,[0 0],[0 .6],[0 0],'g-');plot3(ax,[0 0],[0 0],[0 .6],'b-');
pathax=axes(f,'Position',[.065 .065 .36 .15]);plot(pathax,allQ.body_position_world_m(ids,1),allQ.body_position_world_m(ids,2),'Color',[.6 .6 .6]);hold(pathax,'on');pathdot=plot(pathax,0,0,'ro','MarkerFaceColor','r');grid(pathax,'on');xlabel(pathax,'World X (m)');ylabel(pathax,'World Y (m)');title(pathax,'Integrated path: external 3D accuracy NOT validated');
units={'m/s^2','m/s^2','m/s^2','deg/s','deg/s','deg/s'};names={'Ax','Ay','Az','Gx','Gy','Gz'};cursors=gobjects(6,1);
for j=1:6
 col=mod(j-1,2);row=floor((j-1)/2);a=axes(f,'Position',[.54+.235*col .72-.285*row .205 .20]);
 plot(a,M.time_source_s(ids),measured(ids,j),'Color',[.25 .25 .25]);hold(a,'on');plot(a,M.time_source_s(ids),allQ.imu(ids,j),'Color',[.85 .18 .1]);grid(a,'on');xlim(a,M.time_source_s([1 end])');
 cursors(j)=xline(a,frameT(1),'b-');title(a,[names{j} ' (' units{j} ')']);xlabel(a,'Source time (s)');
 if ~isempty(M.item.reference_contact_start_s),xline(a,M.item.reference_contact_start_s,'k:');xline(a,M.item.reference_contact_end_s,'k:');end
 if j==1,legend(a,'Measured','Reconstructed','Location','best','FontSize',7);end
end
hud=annotation(f,'textbox',[.02 .945 .96 .05],'EdgeColor','none','FontSize',10,'Interpreter','none');
try,writer=VideoWriter(fullfile(directory,[base '.mp4']),'MPEG-4');writer.Quality=85;writer.FrameRate=C.video.frame_rate;open(writer);ext='.mp4';
catch,writer=VideoWriter(fullfile(directory,[base '.avi']),'Motion JPEG AVI');writer.Quality=80;writer.FrameRate=C.video.frame_rate;open(writer);ext='.avi';end
try
 for k=1:N
  q=Z.q(k,:);R=[mil_math('rotate',q,[1 0 0]);mil_math('rotate',q,[0 1 0]);mil_math('rotate',q,[0 0 1])]';
  H=eye(4);H(1:3,1:3)=R;set(g,'Matrix',H);
  set(pathdot,'XData',Z.body_position_world_m(k,1),'YData',Z.body_position_world_m(k,2));
  for j=1:6,cursors(j).Value=frameT(k);end
  hud.String=sprintf('%s | t = %.3f / %.3f s | %.1fx | world body p = [%.1f %.1f %.1f] m | IMU-driven kinematics',M.key,frameT(k),M.time_source_s(end),C.video.playback_speed,Z.body_position_world_m(k,:));
  drawnow;writeVideo(writer,getframe(f));
  if mod(k,200)==0,fprintf('  Video frame %d / %d\n',k,N);end
 end
 close(writer);
catch e
 try,close(writer);catch,end
 if ~isVariant,mil_json(fullfile(directory,'VIDEO_STATUS.json'),struct('status','FAILED','message',e.message));end
 rethrow(e);
end
if ~isVariant,mil_json(fullfile(directory,'VIDEO_STATUS.json'),struct('status','COMPLETE','filename',[base ext],'source_first_s',frameT(1),'source_last_s',frameT(end),'frames',N,'frame_rate',C.video.frame_rate,'playback_speed',C.video.playback_speed,'all_source_time_covered',true,'camera','BODY_CENTERED_WORLD_AXES','trajectory_accuracy','UNVALIDATED'));end
end
function mil_geometry(g,r)
% Illustrative dimensions are project choices, not measured geometry.
a=linspace(0,2*pi,70);
for x=[-.65 .65]
 line('Parent',g,'XData',x+.32*cos(a),'YData',zeros(size(a)),'ZData',-.35+.32*sin(a),'Color',[.12 .12 .12],'LineWidth',5);
 for ang=0:pi/3:2*pi,line('Parent',g,'XData',[x x+.30*cos(ang)],'YData',[0 0],'ZData',[-.35 -.35+.30*sin(ang)],'Color',[.4 .4 .4]);end
end
segments={[-.65 0 -.35;-.2 0 .05;.65 0 -.35;0 0 -.13;-.65 0 -.35],[-.2 0 .05;.35 0 .12;.65 0 -.35],[-.42 0 .14;.05 0 .14],[.34 -.23 .35;.34 .23 .35]};
for i=1:numel(segments),z=segments{i};line('Parent',g,'XData',z(:,1),'YData',z(:,2),'ZData',z(:,3),'Color',[.1 .35 .75],'LineWidth',5);end
for y=[-.12 .12]
 z=[-.22 y .30;-.37 y -.02;-.1 y -.18];line('Parent',g,'XData',z(:,1),'YData',z(:,2),'ZData',z(:,3),'Color',[.2 .2 .25],'LineWidth',7);
 z=[-.05 y .78;.13 y .52;.34 sign(y)*.23 .35];line('Parent',g,'XData',z(:,1),'YData',z(:,2),'ZData',z(:,3),'Color',[.75 .45 .2],'LineWidth',7);
end
line('Parent',g,'XData',[-.22 -.05],'YData',[0 0],'ZData',[.30 .78],'Color',[.2 .6 .35],'LineWidth',16);
[sx,sy,sz]=sphere(12);surface('Parent',g,'XData',.13*sx-.03,'YData',.13*sy,'ZData',.13*sz+.97,'FaceColor',[.9 .7 .45],'EdgeColor','none');
line('Parent',g,'XData',r(1),'YData',r(2),'ZData',r(3),'Marker','s','MarkerSize',9,'Color','r','MarkerFaceColor','r');
end
