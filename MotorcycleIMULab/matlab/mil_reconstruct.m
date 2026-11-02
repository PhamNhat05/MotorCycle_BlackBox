function M=mil_reconstruct(A,C,K,item)
% Conditional mechanization from the complete measured record [R3,R7].
t=A(:,1);h=round(median(diff(t))*1e9)/1e9;N=numel(t);[Y,coverage]=mil_condition(t,A(:,2:7)-K.bias,C.conditioning);
w=(Y(:,4:6)*pi/180)*K.sensor_to_body';alpha=mil_derivative(w,h);
use=t>=C.initial.tilt_prefix_s(1) & t<=C.initial.tilt_prefix_s(2) & vecnorm(A(:,2:4),2,2)>1;
assert(sum(use)>=10,'No usable initialization prefix.');
f=mean(Y(use,1:3),1)*K.sensor_to_body';qref=mil_math('tilt',f,C.initial.yaw_deg);
iref=find(use);iref=iref(round((numel(iref)+1)/2));q0=qref;
for k=iref-1:-1:1
 dq=mil_math('exp',-0.25*h*(w(k,:)+w(k+1,:)));q0=mil_math('multiply',q0,dq);q0=q0/norm(q0);
end
q=zeros(N,4);q(1,:)=q0;
for k=1:N-1
 dq=mil_math('exp',0.25*h*(w(k,:)+w(k+1,:)));q(k+1,:)=mil_math('multiply',q(k,:),dq);q(k+1,:)=q(k+1,:)/norm(q(k+1,:));
 if mod(k,20000)==0,fprintf('  Continuous integration: %d / %d samples\n',k,N);end
end
qd=0.5*mil_math('multiply',q,[zeros(N,1) w]);
qdd=0.5*mil_math('multiply',qd,[zeros(N,1) w])+0.5*mil_math('multiply',q,[zeros(N,1) alpha]);
aS=mil_math('rotate',q,Y(:,1:3)*K.sensor_to_body')+K.gravity_world_m_s2;
r=repmat(K.nominal_position_body_m,N,1);
v0=C.initial.body_velocity_world_m_s+mil_math('rotate',q(1,:),cross(w(1,:),r(1,:),2));
p0=C.initial.body_position_world_m+mil_math('rotate',q(1,:),r(1,:));
vS=[v0;v0+cumsum(0.5*h*(aS(1:end-1,:)+aS(2:end,:)),1)];
pS=[p0;p0+cumsum(h*vS(1:end-1,:)+h^2*(aS(1:end-1,:)/3+aS(2:end,:)/6),1)];
M.schema=1;M.key=item.key;M.item=item;M.time_source_s=t;M.dt_s=h;
M.q=q;M.qd=qd;M.qdd=qdd;M.sensor_position_world_m=pS;M.sensor_velocity_world_m_s=vS;M.sensor_acceleration_world_m_s2=aS;
M.K=K;M.coverage=coverage;M.initialization_reference_source_s=t(iref);
M.description='Full-record conditional kinematic model. IMU fit is an in-sample roundtrip, not independent 3D validation.';
Q=mil_query(M,t,K.nominal_position_body_m,K.bias);
M.forward_roundtrip_max_abs=max(abs(Q.imu-(Y+K.bias)),[],'all');
M.quaternion_norm_max_error=max(abs(vecnorm(q,2,2)-1));
M.end_body_displacement_m=norm(Q.body_position_world_m(end,:)-Q.body_position_world_m(1,:));
M.maximum_body_speed_m_s=max(vecnorm(Q.body_velocity_world_m_s,2,2));
M.conditioned_imu=Y+K.bias;M.measured_imu=A(:,2:7);
end
