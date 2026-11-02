function mil_plot(directory,A,Y,T,C)
v='off';if C.export.figure_visible,v='on';end
f=figure('Visible',v,'Color','w','Position',[50 50 1400 950]);cl=onCleanup(@()close(f));
ids=mil_display_indices([A(:,2:7) Y],C.video.maximum_plot_bins);
for j=1:6
 ax=subplot(3,2,j,'Parent',f);plot(ax,A(ids,1),A(ids,j+1),'Color',[.2 .2 .2]);hold(ax,'on');plot(ax,A(ids,1),Y(ids,j),'Color',[.85 .18 .1]);grid(ax,'on');xlim(ax,A([1 end],1)');
 title(ax,sprintf('%s | RMSE %.4g | r %.4f | NRMSE fit %.2f%% | %s',T.Axis{j},T.RMSE(j),T.PearsonR(j),T.NRMSEFit_percent(j),mil_pass(T.Pass(j))),'Interpreter','none');
 xlabel(ax,'Source time (s)');ylabel(ax,T.Unit{j});if j==1,legend(ax,'Measured','Reconstructed','Location','best');end
end
sgtitle(f,sprintf('%s | FULL RECORD | %d scored samples per axis | IMU fit, 3D accuracy unvalidated',strrep(MIL_KEY(directory),'_',' '),size(A,1)));
exportgraphics(f,fullfile(directory,'FULL_RECORD_FIT.png'),'Resolution',130);
end
function x=MIL_KEY(d)
[~,x]=fileparts(d);
end
function x=mil_pass(b)
if b,x='PASS';else,x='FAIL';end
end
