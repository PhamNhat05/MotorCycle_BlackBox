function R=tga_selfcheck(A)
assert(all([A.counts.bias_only A.counts.position_only A.counts.bias_and_position]>=0));
groups={'bias_only','position_only','bias_and_position'};counts=[A.counts.bias_only A.counts.position_only A.counts.bias_and_position];
assert(all(counts==floor(counts)) && sum(counts)>0);
biasBound=[A.acc_bias_delta_bound_m_s2 A.gyro_bias_delta_bound_deg_s];posBound=A.position_delta_bound_body_m;
assert(all(biasBound>=0) && all(posBound>=0));
for g=1:3
 s1=RandStream('mt19937ar','Seed',A.seed+100+g);s2=RandStream('mt19937ar','Seed',A.seed+100+g);
 [b,r]=tga_draw(s1,groups{g},counts(g),A);[b2,r2]=tga_draw(s2,groups{g},counts(g),A);
 assert(isequal(b,b2) && isequal(r,r2));assert(all(abs(b)<=biasBound+eps,'all') && all(abs(r)<=posBound+eps,'all'));
 if g==1,assert(all(r==0,'all'));elseif g==2,assert(all(b==0,'all'));end
end
% Independent second derivative of a translated point on a rotating rigid body.
t=.37;h=1e-5;w=2;alpha=.7;r=[.03 -.02 .01];f=zeros(3,3);
for i=1:3
 u=t+(i-2)*h;theta=w*u+.5*alpha*u^2;Rz=[cos(theta) -sin(theta) 0;sin(theta) cos(theta) 0;0 0 1];f(i,:)=(Rz*r')';
end
theta=w*t+.5*alpha*t^2;Rz=[cos(theta) -sin(theta) 0;sin(theta) cos(theta) 0;0 0 1];
aFinite=(f(1,:)-2*f(2,:)+f(3,:))/h^2;
aCross=(Rz*(cross([0 0 alpha],r)+cross([0 0 w+alpha*t],cross([0 0 w+alpha*t],r)))')';
errorValue=max(abs(aFinite-aCross));assert(errorValue<1e-5);
allKeys=[A.ai_proposal.train A.ai_proposal.validation A.ai_proposal.test];assert(numel(allKeys)==10 && numel(unique(allKeys))==10);
R=struct('status','PASS','synthetic_only',true,'three_groups_isolated',true,'deterministic_draws',true,'variants_per_parent',sum(counts),'ten_parent_total',10*sum(counts),'independent_lever_second_derivative_error',errorValue,'real_result_inspected',false);
end
