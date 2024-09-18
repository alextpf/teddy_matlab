% ============================================
% Author: Alex Chen
% email: alextpf@gmail.com
% 2014
% ============================================
clear all;
close all;
clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Program parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
HAND_DRAW = false; % true: hand draw; false: load from binary image
fileName = '../samples/lizard_binary.png'; % if HAND_DRAW = false, we have to proide file name 
DEBUG_DRAW_VERT_LABEL = false; % debug flag: draw vertex index
DEBUG_LOAD_FROM_FILE = false; % load the triangulated graph from file
DEBUG_LOAD_NEW_TRI_FROM_FILE = false; % load the chordal axis from file
FILE_NAME = 'tmp_verts_bug';
SHOW_FINAL_MESH = true;

% Advanced debug flags
DEBUG_CHORDAL_AXIS = false;
DEBUG_ELEVATION = false;
DEBUG_WRITE_STL = false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Free hand draw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (~DEBUG_LOAD_NEW_TRI_FROM_FILE)
    if (~DEBUG_LOAD_FROM_FILE)        
        figure('units','normalized','outerposition',[0 0 1 1]); % maximize the figure
        axis equal;
        
        if (HAND_DRAW)            
            % Old API
            % h = imfreehand(gca);
            % pos = getPosition(h);
            
            % New API
            roi = drawfreehand(gca);
            verts = ExtractVertices(roi);
        else
            % load from img
            imshow(fileName, 'Parent', gca);
            verts = TraceBdry(fileName);
        end
        
        tri = Triangulation(verts);
        
        if ( DEBUG_DRAW_VERT_LABEL )
           for i=1:size(verts,1)
               str = sprintf ('%d',i);
               x = verts(i,1);
               y = verts(i,2);
               text(x,y,str);
           end    
        end

        % save to file
        save (FILE_NAME,'tri','verts');
    else
        load (FILE_NAME,'tri','verts');

        figHandle = figure;
        triplot(tri,verts(:,1),verts(:,2),'c');
        axis equal;

        if ( DEBUG_DRAW_VERT_LABEL )
           for i=1:size(verts,1)
               str = sprintf ('%d',i);
               x = verts(i,1);
               y = verts(i,2);
               text(x,y,str,'FontSize',18);
           end    
        end
    end % if (~DEBUG_LOAD_FROM_FILE)
end % if (~DEBUG_LOAD_NEW_TRI_FROM_FILE)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Create chordal axis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FILE_NAME2 = sprintf('%s-new-tri',FILE_NAME);
DEBUG_CHORDAL_AXIS = true;

if (~DEBUG_LOAD_NEW_TRI_FROM_FILE)
    [ chords, newTri, newVerts, entryRow, entryCol, chordSpine ] = constructChord ( tri, verts, DEBUG_CHORDAL_AXIS );
    if (length(entryRow) < 1 || length(entryCol) < 1 )
        return;
    end
    save (FILE_NAME2,'tri','verts','chords','newTri','newVerts', 'entryRow', 'entryCol', 'chordSpine');
else
    load (FILE_NAME2,'tri','verts','chords','newTri','newVerts', 'entryRow', 'entryCol', 'chordSpine');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Elevate the pruned axis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% number of segments in an elliptical arc
numSeg = 10;

% elevation scale
elevScale = 1.3;

if (SHOW_FINAL_MESH)
    figure;
end

[ verts3D, tri3D] = Elevate ( numSeg, elevScale, verts, newVerts, newTri, chordSpine, entryRow,entryCol, gca, DEBUG_ELEVATION, SHOW_FINAL_MESH);
if (DEBUG_WRITE_STL)
    % write to *.stl file
    FILE_NAME3 = sprintf('%s.stl',FILE_NAME);
    Write2Stl(verts3D,tri3D,FILE_NAME3);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Optimize the mesh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OptimizeMesh(verts3D,tri3D);



