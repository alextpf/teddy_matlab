function Write2Stl(verts,tri,FILE_NAME)
fid = fopen(FILE_NAME,'w');

headerSize = 80;
header = zeros(headerSize,1);

numTri = size(tri,1);

% write header
fwrite(fid,header,'uint8');

% write number of triangles
fwrite(fid,numTri,'uint32');

for i = 1:numTri
    
    % calculate normal
    v1 = verts(tri(i,1),:);
    v2 = verts(tri(i,2),:);
    v3 = verts(tri(i,3),:);

    vec1 = v2 - v1;
    tmp = sqrt ( sum ( vec1.^2 ) );
    vec1 = vec1 / tmp;
    
    vec2 = v3 - v1;
    tmp = sqrt ( sum ( vec2.^2 ) );
    vec2 = vec2 / tmp;
    
    normal = cross (vec1,vec2);
    
    % write normal
    fwrite(fid, normal,'float32');
    
    % write triangles
    fwrite(fid, v1,'float32');
    fwrite(fid, v2,'float32');
    fwrite(fid, v3,'float32');
    
    % write 
    tmp = 0;
    fwrite(fid, tmp,'uint16');
    
end

fclose(fid);


