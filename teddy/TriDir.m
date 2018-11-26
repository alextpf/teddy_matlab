% ============================================
% Author: Alex Chen
% email: alextpf@gmail.com
% 2014
% ============================================
function dir = TriDir (v1,v2,v3,verts)

% use normal to check which direction to use
vec1 = verts(v2,:) - verts(v1,:);
vec2 = verts(v3,:) - verts(v1,:);

if ( cross2(vec1, vec2) >0 )                       
    dir =  [v1, v2, v3];
else
    dir =  [v1, v3, v2];
end

function y = cross2(v1,v2)
y = v1(1)*v2(2)-v2(1)*v1(2);