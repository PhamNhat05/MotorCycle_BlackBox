function [T,D]=mil_metrics(A,M,C)
Q=mil_query(M,A(:,1));Y=Q.imu;X=A(:,2:7);E=Y-X;
axisName={'Ax';'Ay';'Az';'Gx';'Gy';'Gz'};units={'m/s^2';'m/s^2';'m/s^2';'deg/s';'deg/s';'deg/s'};
rmse=sqrt(mean(E.^2,1))';mae=mean(abs(E),1)';mx=max(abs(E),[],1)';sx=std(X,0,1)';rngX=(max(X)-min(X))';rho=nan(6,1);fit=nan(6,1);
for j=1:6
 a=X(:,j)-mean(X(:,j));b=Y(:,j)-mean(Y(:,j));den=norm(a)*norm(b);
 if den>eps,rho(j)=sum(a.*b)/den;end
 if norm(a)>eps,fit(j)=100*(1-norm(E(:,j))/norm(a));end % [R8]
end
limit=max(C.quality.rmse_floor(:),C.quality.rmse_range_fraction*rngX);
correlationRequired=sx>=C.quality.correlation_std_floor(:);
pass=rmse<=limit & (~correlationRequired | rho>=C.quality.minimum_correlation);
rows=repmat(size(A,1),6,1);start=repmat(A(1,1),6,1);finish=repmat(A(end,1),6,1);
T=table(axisName,units,rows,start,finish,rmse,mae,mx,sx,rho,fit,limit,correlationRequired,pass,...
 'VariableNames',{'Axis','Unit','ScoredSamples','FirstSourceTime_s','LastSourceTime_s','RMSE','MAE','MaxAbsError','RealStd','PearsonR','NRMSEFit_percent','RMSELimit','CorrelationRequired','Pass'});
finiteState=all(isfinite([M.q(:);M.qd(:);M.qdd(:);M.sensor_position_world_m(:);Y(:)]));
zeroRows=all(X==0,2);first=find(~zeroRows,1);if isempty(first),leading=size(X,1);else,leading=first-1;end
D.pass=all(pass) && finiteState && M.quaternion_norm_max_error<=C.quality.maximum_quaternion_norm_error && M.forward_roundtrip_max_abs<=C.quality.maximum_forward_roundtrip_error;
D.full_record=true;D.scored_samples=size(A,1);D.excluded_samples=0;D.leading_all_zero_samples=leading;D.finite_state=finiteState;
D.quaternion_norm_max_error=M.quaternion_norm_max_error;D.forward_roundtrip_max_abs=M.forward_roundtrip_max_abs;
D.end_body_displacement_m=M.end_body_displacement_m;D.maximum_body_speed_m_s=M.maximum_body_speed_m_s;
D.trajectory_accuracy='UNVALIDATED_NO_EXTERNAL_POSITION_REFERENCE';D.fit_scope='CONDITIONAL_IN_SAMPLE_IMU_ROUNDTRIP';
D.saturation_detection='NOT_CLAIMED_WITHOUT_CONFIRMED_SENSOR_LIMITS';
end
