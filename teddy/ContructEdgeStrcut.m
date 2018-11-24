% ============================================
% Author: Alex Chen
% email: alextpf@gmail.com
% 2014
% ============================================
function edgeStruct = ContructEdgeStrcut(verts,tri)

DEBUG_EDGE_NBHR = false;

edgeVisited = zeros (size(tri));

% figure;
% axis equal;
% hold on;

edgeStruct = [];
edges = [1,2; 2,3; 1,3];

for i = 1 : size(tri,1)
    
    for j = 1 : 3 % each tri has 3 edges
        
        if ( edgeVisited(i,j) )
            continue;
        end
        
        edgeIdx = edges(j, :);
        edge = tri(i,edgeIdx);
        res = ismember(tri,edge);
        tmp = sum(res,2);

        % find the tri's that has this edge
        idx = find(tmp==2);            
        %idx = idx ( find ( idx ~= i ) );
        
        % Mark visited edges
        for k = 1 : size(idx)
            id = idx(k);
            v1v2Idx = find ( res (id,:) );
            switch ( sum(v1v2Idx) )
                case 3 % 1 + 2
                    edgeVisited(id,1) = true;
                case 5 % 2 + 3
                    edgeVisited(id,2) = true;
                case 4 % 1 + 3
                    edgeVisited(id,3) = true;
                otherwise
                    disp('error');
                    return;
            end
        end
        
%         doubleConnect = tri ( idx, : );

        % find the tri's that are connected with a vert of this edge
        idx2 = find(tmp==1);
%         singleConnect = tri ( idx2, : );

        % s = struct('Edge', edge, 'DoubleConnect', doubleConnect,'DoubleConnectIdx', idx, 'SingleConnect', singleConnect,'SingleConnectIdx',idx2 );
        s = struct('Edge', edge,'DoubleConnectIdx', idx, 'SingleConnectIdx',idx2 );
        edgeStruct = [edgeStruct; s];
%         
%         if (DEBUG_EDGE_NBHR)
%             trisurf( tri(i,:), verts(:,1), verts(:,2), verts(:,3),'LineWidth',2 );
%             trisurf( doubleConnect, verts(:,1), verts(:,2), verts(:,3));
%             trisurf( singleConnect, verts(:,1), verts(:,2), verts(:,3));
%             alpha(0.4);        
%         end
    end
end