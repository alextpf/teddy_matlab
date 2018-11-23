function EDif = GetEnergyDifferenceForSplit( oldTri, newTri, verts )

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
ERepNew = Crep;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% E_spring
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% use ContructEdgeStrcut() to get un-repeated edges
edgeStruct = ContructEdgeStrcut(verts,oldTri);

% old star
ESpringOld = 0;

for i = 1 : length (edgeStruct)
    edgeS = edgeStruct(i);
    edgeIdx = edgeS.Edge;
    
    v1 = verts(edgeIdx(1),:);
    v2 = verts(edgeIdx(2),:);    
    
    ESpringOld = ESpringOld + sum(( v1 - v2 ).^2);
end

ESpringOld = K * ESpringOld;

% new star
newEdgeStruct = ContructEdgeStrcut(verts,newTri);

ESpringNew = 0;

for i = 1 : length (newEdgeStruct)
    edgeS = newEdgeStruct(i);
    edgeIdx = edgeS.Edge;
    
    v1 = verts(edgeIdx(1),:);
    v2 = verts(edgeIdx(2),:);    
    
    ESpringNew = ESpringNew + sum(( v1 - v2 ).^2);
end

ESpringNew = K * ESpringNew;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% total energy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EOld = EDistOld + ERepOld + ESpringOld;
ENew = EDistNew + ERepNew + ESpringNew;

EDif = EOld - ENew;