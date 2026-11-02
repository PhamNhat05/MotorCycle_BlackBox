function [db,dr]=tga_draw(stream,groupName,count,A)
b=[A.acc_bias_delta_bound_m_s2 A.gyro_bias_delta_bound_deg_s A.position_delta_bound_body_m];
z=(2*rand(stream,count,9)-1).*b;db=z(:,1:6);dr=z(:,7:9);
switch groupName
 case 'bias_only',dr(:)=0;
 case 'position_only',db(:)=0;
 case 'bias_and_position'
 otherwise,error('Unknown augmentation group.');
end
end
