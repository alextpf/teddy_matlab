% ============================================
% Author: Alex Chen
% email: alextpf@gmail.com
% 2014
% ============================================
function ok = checkDihedralAngle(tri,verts,MAX_ANGLE)
THRESH = cos(MAX_ANGLE * 3.1415926/180);

normals= zeros(size(tri)); % init to 0

numTri = size(tri,1);
visited = zeros (numTri,1);

DEBUG_DRAW_TRI = false;

if (DEBUG_DRAW_TRI)
    figure;
    hold on;
    axis equal;
end

for i = 1 : numTri
    if (visited(i))
        continue;
    end
    
    visited(i) = true;
    
    currTri = tri(i,:);
    
    % current normal
    if (normals(i,:) == [0,0,0])
        normals(i,:) = calNormal(currTri,verts);
    end
    
    currNormal = normals(i,:);
    
    % find the tris that have 2 verts that are adjacent
    res = ismember (tri,currTri);
    tmp = sum(res,2);
    idx = find ( tmp == 2 );
    
    for j = 1 : length(idx)
    
        nextIdx = idx(j);
        
        if (visited(nextIdx))
            continue;
        end
        
        nextTri = tri(nextIdx,:);        

        % next tri normal
        if (normals(nextIdx,:) == [0,0,0])
            normals(nextIdx,:) = calNormal(nextTri,verts);
        end

        nextNormal = normals(nextIdx,:);

        cosAngle = sum(  currNormal.*nextNormal); % inner product ( = cos(theta))

        if (DEBUG_DRAW_TRI)        
            trisurf(currTri, verts(:,1),verts(:,2),verts(:,3));
            trisurf(nextTri, verts(:,1),verts(:,2),verts(:,3));
        end

        if ( cosAngle < THRESH )
            ok = false;
            return;
        end
    end
end

ok = true;