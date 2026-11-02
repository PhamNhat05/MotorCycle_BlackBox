function R=mil_selfcheck()
% Synthetic mathematics checks. No measured record is fitted here.
C=PROJECT_CONFIG();
t=linspace(0,1,501)';p=5;B=mil_basis(t,[zeros(1,6) ones(1,6)],p);
bern=zeros(numel(t),6);for j=0:5,bern(:,j+1)=nchoosek(5,j)*t.^j.*(1-t).^(5-j);end
basisError=max(abs(full(B)-bern),[],'all');assert(basisError<1e-12,'B-spline/Bernstein equivalence failed.');
knots=[zeros(1,6) .1:.1:.9 ones(1,6)];B=mil_basis(t,knots,5);partitionError=max(abs(full(sum(B,2))-1));assert(partitionError<1e-12 && min(nonzeros(B))>=-1e-14);
h=.001;t=(0:h:1)';derivativeError=max(abs(mil_derivative([t.^3 t.^4],h)-[3*t.^2 4*t.^3]),[],'all');assert(derivativeError<1e-9);
q=mil_math('exp',[.1 -.2 .3]);v=[2 -3 4];rotationError=norm(mil_math('rotate',mil_math('conjugate',q),mil_math('rotate',q,v))-v);assert(rotationError<1e-12);
K=struct('bias',[.01 -.02 .03 .1 -.1 .2],'sensor_to_body',mil_math('rpy',[3 -4 5]),'nominal_position_body_m',[.05 .01 -.05],'gravity_world_m_s2',[0 0 -9.81]);
N=numel(t);angle=.3*t+.4*t.^2;omega=[zeros(N,2) .3+.8*t];alpha=repmat([0 0 .8],N,1);
M.K=K;M.time_source_s=t;M.dt_s=h;M.q=[cos(angle/2) zeros(N,2) sin(angle/2)];
M.qd=.5*mil_math('multiply',M.q,[zeros(N,1) omega]);M.qdd=.5*mil_math('multiply',M.qd,[zeros(N,1) omega])+.5*mil_math('multiply',M.q,[zeros(N,1) alpha]);
M.sensor_acceleration_world_m_s2=[.2*sin(t) .3*cos(t) .1*t];a=M.sensor_acceleration_world_m_s2;
M.sensor_velocity_world_m_s=[zeros(1,3);cumsum(.5*h*(a(1:end-1,:)+a(2:end,:)),1)];
M.sensor_position_world_m=[zeros(1,3);cumsum(h*M.sensor_velocity_world_m_s(1:end-1,:)+h^2*(a(1:end-1,:)/3+a(2:end,:)/6),1)];
Q=mil_query(M,t);rateError=max(abs(Q.omega_body_rad_s-omega),[],'all');alphaError=max(abs(Q.alpha_body_rad_s2-alpha),[],'all');assert(rateError<1e-8 && alphaError<1e-6);
newR=K.nominal_position_body_m+[.012 -.017 .009];newB=K.bias+[.05 -.05 .03 .1 .05 -.07];tc=.3335;e=2e-5;
Z=mil_query(M,[tc-e;tc;tc+e],newR,newB);aFD=(Z.sensor_position_world_m(1,:)-2*Z.sensor_position_world_m(2,:)+Z.sensor_position_world_m(3,:))/e^2;
fFD=mil_math('rotate',mil_math('conjugate',Z.q(2,:)),aFD-K.gravity_world_m_s2)*K.sensor_to_body+newB(1:3);
leverDerivativeError=max(abs(fFD-Z.imu(2,1:3)));assert(leverDerivativeError<2e-4,'Off-center forward model failed independent position differentiation.');
% Boundary continuity is checked on the interpolated derivatives, not rendered pixels.
u=[.4-1e-9;.4;.4+1e-9];Z=mil_query(M,u);positionJump=max(abs(Z.body_position_world_m(3,:)-Z.body_position_world_m(1,:)));assert(positionJump<1e-7);
t=(.001:.001:2.201)';X=[sin(2*pi*70*t) .4*cos(2*pi*13*t) 9.81+.2*sin(2*pi*3*t) 3*sin(2*pi*70*t) 2*cos(2*pi*7*t) sin(2*pi*11*t)];
[Y,coverage]=mil_condition(t,X,C.conditioning);conditioningRmse=sqrt(mean((Y-X).^2,1));assert(all(conditioningRmse<.1) && coverage.covered_samples==numel(t));
item=struct('key','synthetic','split','build','record_contains_fall',false,'reference_contact_start_s',[],'reference_contact_end_s',[]);
A=[t X];MM=mil_reconstruct(A,C,K,item);[T,D]=mil_metrics(A,MM,C);assert(D.pass && all(T.ScoredSamples==numel(t)) && D.excluded_samples==0 && MM.coverage.state_resets==0);
assert(max(abs(MM.time_source_s-t))==0);
R=struct('status','PASS','synthetic_only',true,'basis_bernstein_max_error',basisError,'partition_max_error',partitionError,'polynomial_derivative_max_error',derivativeError,'rotation_roundtrip_error',rotationError,'quaternion_rate_node_error',rateError,'quaternion_alpha_node_error',alphaError,'lever_independent_second_derivative_error',leverDerivativeError,'interpolation_position_jump_over_2ns_m',positionJump,'conditioning_rmse',conditioningRmse,'full_record_synthetic_rows',numel(t),'end_to_end_forward_roundtrip_error',MM.forward_roundtrip_max_abs,'measured_data_pass_claimed',false);
end
