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
HAND_DRAW = true; % true: hand draw; false: load from binary image
fileName = '../lizard-filled.png'; % if HAND_DRAW = false, we have to proide file name 
DEBUG_DRAW_VERT_LABEL = true; % debug flag: draw vertex index
DEBUG_LOAD_FROM_FILE = false; % load the triangulated graph from file
DEBUG_LOAD_NEW_TRI_FROM_FILE = false; % load the chordal axis from file
FILE_NAME = 'shape01';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Free hand draw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (~DEBUG_LOAD_NEW_TRI_FROM_FILE)
    if (~DEBUG_LOAD_FROM_FILE)
        
        if (HAND_DRAW)
            [verts, figHandle] = FreeHandDrawing();
        else
            % load from img
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
DEBUG = false;

FILE_NAME2 = sprintf('%s-new-tri',FILE_NAME);
if (~DEBUG_LOAD_NEW_TRI_FROM_FILE)
    [ chords, newTri, newVerts, entryRow, entryCol, chordSpine ] = constructChord ( tri, verts, DEBUG );
    save (FILE_NAME2,'tri','verts','chords','newTri','newVerts', 'entryRow', 'entryCol', 'chordSpine');
else
    load (FILE_NAME2,'tri','verts','chords','newTri','newVerts', 'entryRow', 'entryCol', 'chordSpine');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Elevate the pruned axis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DEBUG = false;

% number of segments in an elliptical arc
numSeg = 10;

% elevation scale
elevScale = 1;

[ verts3D, tri3D, figHandle] = Elevate ( numSeg, elevScale, verts, newVerts, newTri, chordSpine, entryRow,entryCol, DEBUG );

DEBUG_WRITE_STL = true;

if (DEBUG_WRITE_STL)
    % write to *.stl file
    FILE_NAME3 = sprintf('%s.stl',FILE_NAME);
    Write2Stl(verts3D,tri3D,FILE_NAME3);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. Optimize the mesh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OptimizeMesh(verts3D,tri3D);



