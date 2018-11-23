function EDif = GetEnergyDifferenceForSwap( oldVertIdx, newVertIdx, verts )

Crep = 0.0001;
K = 0.01;

% Energy = E_dist + E_rep + E_spring
%        = |Xi-phi(bi)|^2 + Crep * m + K * |Vj-Vk|^2
% assume original energy is E, new energy is E'
% this function returns E-E'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% E_dist
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EDistOld = 0;
EDistNew = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% E_rep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ERepOld = 0;
ERepNew = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% E_spring
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% old star    
v1 = verts(oldVertIdx(1),:);
v2 = verts(oldVertIdx(2),:);    

ESpringOld = K * sum(( v1 - v2 ).^2);

% new star
v1 = verts(newVertIdx(1),:);
v2 = verts(newVertIdx(2),:);    

ESpringNew = K * sum(( v1 - v2 ).^2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% total energy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EOld = EDistOld + ERepOld + ESpringOld;
ENew = EDistNew + ERepNew + ESpringNew;

EDif = EOld - ENew;        