% ============================================
% Author: Alex Chen
% email: alextpf@gmail.com
% 2014
% ============================================
function normal = calNormal(tri,verts)
v1 = verts(tri(2),:) - verts(tri(1),:);
v2 = verts(tri(3),:) - verts(tri(1),:);
normal = cross ( v1, v2);
normal = normal / sqrt(sum(normal.^2));