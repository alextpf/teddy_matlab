function tri = Triangulation(verts)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Do Delaunay triangulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
verts = verts(1:end-1,:);
len = size(verts,1);
c = [ (1:len-1)', (2:len)'; len,1];

DT = delaunayTriangulation(verts,c);

insideIdx = isInterior(DT);
tri = DT.ConnectivityList;
tri = tri ( insideIdx, :);

% //==== debug =================//
% figure;
% 
% triplot(tri,verts(:,1),verts(:,2));
% title('Delaunay Triangulation');
% axis equal;
% //==== debug =================//