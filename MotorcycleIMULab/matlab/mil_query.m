function Q=mil_query(M,t,positionBody,bias)
% One C2 attitude / C2 position model drives both video and forward IMU.
% Quaternion Hermite coefficients are derived from endpoint constraints [R6].
if nargin<3 || isempty(positionBody),positionBody=M.K.nominal_position_body_m;end
if nargin<4 || isempty(bias),bias=M.K.bias;end
t=t(:);assert(all(t>=M.time_source_s(1)-1e-9 & t<=M.time_source_s(end)+1e-9),'Query outside full record.');
h=M.dt_s;u=(t-M.time_source_s(1))/h;nearest=round(u);snap=abs(u-nearest)<1e-7;u(snap)=nearest(snap);k=min(numel(M.time_source_s)-1,max(1,floor(u)+1));s=max(0,min(1,u-(k-1)));tau=s*h;
c0=M.q(k,:);c1=h*M.qd(k,:);c2=0.5*h^2*M.qdd(k,:);
a=M.q(k+1,:)-c0-c1-c2;b=h*M.qd(k+1,:)-c1-2*c2;d=h^2*M.qdd(k+1,:)-2*c2;
c3=10*a-4*b+0.5*d;c4=-15*a+7*b-d;c5=6*a-3*b+0.5*d;
p=c0+s.*(c1+s.*(c2+s.*(c3+s.*(c4+s.*c5))));
pd=(c1+s.*(2*c2+s.*(3*c3+s.*(4*c4+s.*5.*c5))))/h;
pdd=(2*c2+s.*(6*c3+s.*(12*c4+s.*20.*c5)))/h^2;
rn=sqrt(sum(p.^2,2));sp=sum(p.*pd,2);
q=p./rn;qd=pd./rn-p.*(sp./rn.^3);
qdd=pdd./rn-2*pd.*(sp./rn.^3)-p.*((sum(pd.^2,2)+sum(p.*pdd,2))./rn.^3)+3*p.*(sp.^2./rn.^5);
wq=2*mil_math('multiply',mil_math('conjugate',q),qd);aq=2*mil_math('multiply',mil_math('conjugate',q),qdd);
w=wq(:,2:4);alpha=aq(:,2:4);N=numel(t);
a0=M.sensor_acceleration_world_m_s2(k,:);da=M.sensor_acceleration_world_m_s2(k+1,:)-a0;
pS=M.sensor_position_world_m(k,:)+tau.*M.sensor_velocity_world_m_s(k,:)+0.5*tau.^2.*a0+tau.^3.*da/(6*h);
vS=M.sensor_velocity_world_m_s(k,:)+tau.*a0+tau.^2.*da/(2*h);aS=a0+s.*da;
r0=repmat(M.K.nominal_position_body_m,N,1);r1=repmat(reshape(positionBody,1,3),N,1);
lever0=cross(alpha,r0,2)+cross(w,cross(w,r0,2),2);
Q.body_position_world_m=pS-mil_math('rotate',q,r0);
Q.body_velocity_world_m_s=vS-mil_math('rotate',q,cross(w,r0,2));
Q.body_acceleration_world_m_s2=aS-mil_math('rotate',q,lever0);
fB=mil_math('rotate',mil_math('conjugate',q),Q.body_acceleration_world_m_s2-M.K.gravity_world_m_s2)+cross(alpha,r1,2)+cross(w,cross(w,r1,2),2);
Q.imu=[fB*M.K.sensor_to_body (w*M.K.sensor_to_body)*180/pi]+reshape(bias,1,6);
Q.q=q;Q.omega_body_rad_s=w;Q.alpha_body_rad_s2=alpha;
Q.sensor_position_world_m=Q.body_position_world_m+mil_math('rotate',q,r1);
end
