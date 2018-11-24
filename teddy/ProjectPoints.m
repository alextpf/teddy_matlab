% ============================================
% Author: Alex Chen
% email: alextpf@gmail.com
% 2014
% ============================================
function [projPts,dist] = ProjectPoints(pts,starTri,verts)
% project pts onto star
DEBUG_DRAW_PROJ = false;

if (DEBUG_DRAW_PROJ)
    figure; axis equal;hold on;
    trisurf(starTri,verts(:,1),verts(:,2),verts(:,3));
end

projPts = zeros(size(pts));
dist = zeros(size(pts,1),1);

% loop through each points
for i = 1:size(pts,1)
    
    pt = pts(i,:);
    
    % loop through each tri
    minDist = 100000000;
    
    for j = 1:size(starTri,1)    
        tri = starTri(j,:);
        normal = calNormal(tri,verts);
        
        a = ( pt - verts(tri(1),:)).*normal;
        a = sum(a);    
        
        if ( abs(a) < minDist )
            minDist = abs(a);
            t = a;
        end
        
        % the projection point is a * normal        
    end
    
    projPts(i,:) = pt + t * normal;
    dist(i) = minDist;
    
    if (DEBUG_DRAW_PROJ)
        tmp = [pt;projPts(i,:)];
        plot3(tmp(:,1),tmp(:,2),tmp(:,3),'r.-','LineWidth',3);
    end
end