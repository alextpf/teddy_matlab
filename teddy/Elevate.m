% ============================================
% Author: Alex Chen
% email: alextpf@gmail.com
% 2014
% ============================================
function [verts3D, tri3D, figHandle] = Elevate ( numSeg, elevScale, verts, newVerts, newTri, chordSpine, entryRow,entryCol, ax, DEBUG )

    DEBUG_DRAW_ELEVATION = DEBUG;
    DEBUG_DRAW_CONNECTED_VERTS = DEBUG;
    DEBUG_DRAW_ARC = DEBUG;
    DEBUG_DRAW_3D_TRI_REALTIME = false;    
    DEBUG_DRAW_FLAT = DEBUG;
    
    DEBUG_DRAW_LABEL = false;    
    DEBUG_DRAW_3D_TRI = true;

% draw triPlot in 3D
tmpZ = zeros ( size ( newVerts, 1 ), 1 );
verts3D = [ newVerts , tmpZ ];

if ( DEBUG_DRAW_FLAT )
    trisurf( newTri, verts3D(:,1), verts3D(:,2), verts3D(:,3) );
    alpha(0.2);
end

if ( DEBUG_DRAW_LABEL )
    for i=1:size(verts3D,1)
       str = sprintf ('%d',i);
       x = verts3D(i,1);
       y = verts3D(i,2);
       z = verts3D(i,3);
       text(x,y,z,str,'FontSize',18);
    end 
end


% init the verts & tri in 3D
tri3D = [];

% number of outer vertex
numOuterVerts = size (verts, 1);

% do elevation
spineStruct = [];
for i=1:length(chordSpine)
    
    spineIdx = chordSpine(i);

    % find the connected verts
    res = ismember ( newTri, spineIdx );
    tmp = sum ( res, 2 );
    tris = newTri ( tmp > 0, : );
    outerVerts = tris ( tris <= numOuterVerts );
    outerVerts = unique ( outerVerts );
    numConnectedVerts = length (outerVerts);
    
    if ( DEBUG_DRAW_CONNECTED_VERTS )
        pivot = verts3D ( spineIdx, :);
        plot3 ( pivot(1), pivot(2), pivot(3), 'o','LineWidth',2);
        for j = 1 : numConnectedVerts
            tmp = verts3D (outerVerts(j),:);
            vec = [pivot;tmp];
            plot3 (vec(:,1), vec(:,2), vec(:,3), 'r','LineWidth',1);
        end
    end % if ( DEBUG_DRAW_CONNECTED_VERTS )

    % get the averaged length
    [ avgLen, vecLen ] = getAvgLength ( spineIdx, outerVerts, verts3D );

    elev = avgLen * elevScale;

    % change pivot's height
    verts3D ( spineIdx, 3 ) = elev;
    
    % add the negative vertex
    tmpVert = verts3D ( spineIdx, : );
    tmpVert (3) = -tmpVert (3);
    verts3D = [ verts3D; tmpVert ];
    negativePivotIdx = size(verts3D, 1);

    if (DEBUG_DRAW_ELEVATION)
        groundPivot = verts3D ( spineIdx, :);
        endPivot = groundPivot;
        groundPivot(3) = 0;
        vec = [groundPivot;endPivot];
        plot3 (vec(:,1), vec(:,2), vec(:,3), 'g','LineWidth',2);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % contruct an elliptical arc
    % Equation: in 2D: (x/a)^2 + (y/b)^2 = 1
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    yVec = elev / (numSeg+1) : elev / (numSeg+1) : elev - elev / (numSeg+1);
    verticalVec = ones ( numConnectedVerts, 1) * yVec;

    b = ones ( numConnectedVerts, numSeg ) * elev;
    a = vecLen * ones ( 1, numSeg );

    horizontalVec = ( 1 - verticalVec.^ 2 ./ b.^2 );
    horizontalVec = horizontalVec .* a.^2;
    horizontalVec = sqrt ( horizontalVec );

    % create unit vector
    pivot = verts3D ( spineIdx, 1:2 );
    pivot = ones ( numConnectedVerts, 1 ) * pivot;
    outers = verts3D ( outerVerts, 1:2 );

    unitVec = outers - pivot;
    norm = sqrt ( sum ( unitVec.^2, 2 ) );
    norm = norm * ones ( 1, 2 );
    unitVec = unitVec ./ norm;

    arcBranches = [];
    for outerVertIdx = 1 : numConnectedVerts
        xVec = transpose( horizontalVec ( outerVertIdx, : ) );
        xVec = xVec * unitVec ( outerVertIdx, :);

        pivotAtGround = verts3D ( spineIdx, : );
        pivotAtGround (3) = 0;
        pivots = ones ( length(yVec), 1 ) * pivotAtGround;
        arcVec = [ xVec, yVec'];
        arcVec = arcVec + pivots;

        if ( DEBUG_DRAW_ARC )
            plot3( arcVec( :, 1), arcVec( :, 2), arcVec( :, 3),'b' );
        end % if ( DEBUG_DRAW_ARC )

        % put the arc starting index, length and the end point index into an structure
        startVertIdx = size ( verts3D, 1 ) + 1;
        len = size ( arcVec, 1 );
        s = struct ( 'startVertIdx', startVertIdx,'arcLength',len, 'endPtIdx',outerVerts(outerVertIdx) );
        arcBranches = [ arcBranches; s ];

        % push positive verts
        verts3D = [ verts3D; arcVec ];
        
        % push negative verts
        arcVec(:,3) = -arcVec(:,3);
        verts3D = [ verts3D; arcVec ];
    end
    
    currSpinePt = struct ( 'pivotIdx', spineIdx, 'arcBranches', arcBranches, 'negativePivotIdx', negativePivotIdx );

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Triangulate the triangles from current chordal point
    % to the connected chordal point
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    entries = entryCol(entryRow==i);
    for id = 1 : length (entries)
        currId = entries(id);
        entry = chordSpine(currId);
        
        % look up the connected arc from spineStruct
        if ( length(spineStruct) >= currId )
            prevSpinePt = spineStruct(currId);
            currVert = currSpinePt.pivotIdx;
            prevVert = prevSpinePt.pivotIdx;
            
            currNegativeVert = currSpinePt.negativePivotIdx;
            prevNegativeVert = prevSpinePt.negativePivotIdx;
            
            for k = 1 : size ( outerVerts, 1 )
                tmpVerts = [ currVert, prevVert, outerVerts(k) ];
                res = ismember ( newTri, tmpVerts );
                tmp = sum ( res, 2 );
                isValid = find ( tmp == 3 );
                if ( isempty( isValid ) )
                    continue;
                end

                sameOrder = CheckOrder ( tmpVerts, newTri(isValid,:) );
                
                prevArcBranches = prevSpinePt.arcBranches;
                currArcBranches = currSpinePt.arcBranches;

                % loop through previous spine pt struct                
                for j = 1 : size ( prevArcBranches, 1 )
                    if ( prevArcBranches(j).endPtIdx == tmpVerts(3) )
                        prevVertIdx = prevArcBranches(j).startVertIdx;
                        prevArcLength = prevArcBranches(j).arcLength;
                        break;
                    end
                end

                % loop through previous spine pt struct
                for j = 1 : size ( currArcBranches, 1 )
                    if ( currArcBranches(j).endPtIdx == tmpVerts(3) )
                        currVertIdx = currArcBranches(j).startVertIdx;
                        currArcLength = currArcBranches(j).arcLength;
                        break;
                    end
                end

                % sanity check
                if ( prevArcLength ~= currArcLength )
                    dispy ('error');
                    return;
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % triangulate z=0 index
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if ( sameOrder )
                    tmp = [ currVertIdx, prevVertIdx, tmpVerts(3)];
                else
                    tmp = [ prevVertIdx, currVertIdx, tmpVerts(3)];
                end                
                
                tri3D = [ tri3D; tmp ];
                
                if (DEBUG_DRAW_3D_TRI_REALTIME)                
                   trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
                   alpha(0.2);
                end
                
                % negative side
                if ( sameOrder )
                    tmp = [ currVertIdx + currArcLength, prevVertIdx + currArcLength, tmpVerts(3)];
                else
                    tmp = [ prevVertIdx + currArcLength, currVertIdx + currArcLength, tmpVerts(3)];
                end
                
                % swap column 2 & 3 for correct normal
                tmpCol = tmp (:,2);
                tmp (:,2) = tmp (:,3);
                tmp (:,3) = tmpCol;
                
                tri3D = [ tri3D; tmp ];

                if (DEBUG_DRAW_3D_TRI_REALTIME)                
                   trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
                   alpha(0.2);
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % triangulate middle segment
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if ( sameOrder )
                    tmp = [ prevVertIdx, currVertIdx, currVertIdx + 1];
                else
                    tmp = [ prevVertIdx, currVertIdx + 1, currVertIdx ];
                end
                
                tmp = ones ( prevArcLength-1, 1) * tmp;

                tmp2 = 0 : prevArcLength-2;
                tmp2 = tmp2' * ones(1,3);
                tmp = tmp + tmp2;

                tri3D = [ tri3D; tmp ];
                
                if (DEBUG_DRAW_3D_TRI_REALTIME)                
                   trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
                   alpha(0.2);
                end
                
                % negative side
                tmp = tmp +  currArcLength;
                
                % swap column 2 & 3 for correct normal
                tmpCol = tmp (:,2);
                tmp (:,2) = tmp (:,3);
                tmp (:,3) = tmpCol;
                
                tri3D = [ tri3D; tmp ];                
                
                if (DEBUG_DRAW_3D_TRI_REALTIME)                
                   trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
                   alpha(0.2);
                end
                
                if ( sameOrder )
                    tmp = [ prevVertIdx + 1, prevVertIdx, currVertIdx + 1 ]; 
                else
                    tmp = [ prevVertIdx, prevVertIdx + 1, currVertIdx + 1 ]; 
                end                
                
                tmp = ones ( prevArcLength - 1, 1) * tmp;

                tmp = tmp + tmp2;
                tri3D = [ tri3D; tmp ];
                
                if (DEBUG_DRAW_3D_TRI_REALTIME)                
                   trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
                   alpha(0.2);
                end
                
                % negative side
                tmp = tmp +  currArcLength;
                
                % swap column 2 & 3 for correct normal
                tmpCol = tmp (:,2);
                tmp (:,2) = tmp (:,3);
                tmp (:,3) = tmpCol;
                
                tri3D = [ tri3D; tmp ];

                if (DEBUG_DRAW_3D_TRI_REALTIME)                
                   trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
                   alpha(0.2);
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % triangulate pivot triangle
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if ( sameOrder )
                    tmp = [ currVert, prevVert, prevVertIdx + prevArcLength - 1;
                            currVertIdx + prevArcLength - 1, currVert, prevVertIdx + prevArcLength - 1 ];
                else
                    tmp = [ prevVert, currVert, prevVertIdx + prevArcLength - 1;
                            currVert, currVertIdx + prevArcLength - 1, prevVertIdx + prevArcLength - 1 ];                    
                end
                
                tri3D = [ tri3D; tmp ];
                
                if (DEBUG_DRAW_3D_TRI_REALTIME)                
                   trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
                   alpha(0.2);
                end
                
                % negative side
                if ( sameOrder )
                    tmp = [ prevNegativeVert, currNegativeVert, prevVertIdx + 2 * prevArcLength - 1;
                            currNegativeVert, currVertIdx + 2 * prevArcLength - 1, prevVertIdx + 2 * prevArcLength - 1 ];                    
                else
                    tmp = [ currNegativeVert, prevNegativeVert, prevVertIdx + 2 * prevArcLength - 1;
                            currVertIdx + 2 * prevArcLength - 1, currNegativeVert, prevVertIdx + 2 * prevArcLength - 1 ];                    
                end  
                
                tri3D = [ tri3D; tmp ];
               
                if (DEBUG_DRAW_3D_TRI_REALTIME)                
                   trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
                   alpha(0.2);
                end
            end

        end % if (~isempty(spineStruct))
    end% for id = 1 : length (entries)

    % push the struct
    spineStruct = [ spineStruct; currSpinePt ];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % triangulate those branches from the same chordal point
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    candidates = [ outerVerts; spineIdx ];
    res = ismember ( tris, candidates );
    tmp = sum ( res, 2);
    triToConnect = tris ( tmp == 3, : );

    for idx = 1 : size ( triToConnect, 1 )
       curTri =  triToConnect ( idx, : );
       endPts = curTri ( curTri ~= spineIdx );
       branches = currSpinePt.arcBranches;

       found1 = false;
       found2 = false;

       % find the corresponding 2 branches
       for branchIdx = 1 : size ( branches, 1 )
           tmpBranch = branches( branchIdx );
           endPtIdx = tmpBranch.endPtIdx;

           if ( ~found1 & endPtIdx == endPts(1) )
               found1 = true;
               startIdx1 = tmpBranch.startVertIdx;
               arcLen1 = tmpBranch.arcLength;
               endPtIdx1 = endPtIdx;
           end

           if ( ~found2 & endPtIdx == endPts(2) )
               found2 = true;
               startIdx2 = tmpBranch.startVertIdx;
               arcLen2 = tmpBranch.arcLength;
               endPtIdx2 = endPtIdx;
           end

           if ( found1 & found2 )
               break;
           end
       end

       if ( arcLen1 ~= arcLen2 )
           disp ('error');
           return;
       end

       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       % triangulate 2 z=0 index
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       tmp = [ endPtIdx1, endPtIdx2, startIdx1;
               endPtIdx2, startIdx2, startIdx1 ];
       tri3D = [ tri3D; tmp ];
          
       if (DEBUG_DRAW_3D_TRI_REALTIME)                
           trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
           alpha(0.2);
       end
       
       % negative side
       tmp = [ endPtIdx1, endPtIdx2, startIdx1 + arcLen1;
               endPtIdx2, startIdx2 + arcLen1, startIdx1 + arcLen1 ];
       
       % swap column 2 & 3 for correct normal
        tmpCol = tmp (:,2);
        tmp (:,2) = tmp (:,3);
        tmp (:,3) = tmpCol;

       tri3D = [ tri3D; tmp ];
          
       if (DEBUG_DRAW_3D_TRI_REALTIME)                
           trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
           alpha(0.2);
       end
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       % do the arc triangulation
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       tmp = [ startIdx1, startIdx2, startIdx1 + 1 ];
       tmp = ones ( arcLen1-1, 1) * tmp;

       tmp2 = 0 : arcLen1-2;
       tmp2 = tmp2' * ones(1,3);
       tmp = tmp + tmp2;

       tri3D = [ tri3D; tmp ];
       
       if (DEBUG_DRAW_3D_TRI_REALTIME)                
           trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
           alpha(0.2);
       end
       
       % negative side
       tmp = tmp + arcLen1;
       % swap column 2 & 3 for correct normal
        tmpCol = tmp (:,2);
        tmp (:,2) = tmp (:,3);
        tmp (:,3) = tmpCol;
        
       tri3D = [ tri3D; tmp ];
       
       if (DEBUG_DRAW_3D_TRI_REALTIME)                
           trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
           alpha(0.2);
       end
       
       tmp = [ startIdx2, startIdx2 + 1, startIdx1 + 1 ]; 
       tmp = ones ( arcLen1 - 1, 1) * tmp;

       tmp = tmp + tmp2;
       tri3D = [ tri3D; tmp ];
       
       if (DEBUG_DRAW_3D_TRI_REALTIME)                
           trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
           alpha(0.2);
       end
       
       % negative side
       tmp = tmp + arcLen1;
       
       % swap column 2 & 3 for correct normal
        tmpCol = tmp (:,2);
        tmp (:,2) = tmp (:,3);
        tmp (:,3) = tmpCol;
        
       tri3D = [ tri3D; tmp ];
             
       if (DEBUG_DRAW_3D_TRI_REALTIME)                
           trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
           alpha(0.2);
       end
       
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       %triangulate the pivot index
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       tmp = [ startIdx1 + arcLen1 - 1, startIdx2 + arcLen1 - 1, spineIdx ];
       tri3D = [ tri3D; tmp ];
                     
       if (DEBUG_DRAW_3D_TRI_REALTIME)                
           trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
           alpha(0.2);
       end
       
       % negative side
       tmp = [ startIdx1 + 2 * arcLen1 - 1, startIdx2 + 2 * arcLen1 - 1, negativePivotIdx ];
       
       % swap column 2 & 3 for correct normal
        tmpCol = tmp (:,2);
        tmp (:,2) = tmp (:,3);
        tmp (:,3) = tmpCol;
        
       tri3D = [ tri3D; tmp ];

       if (DEBUG_DRAW_3D_TRI_REALTIME)                
           trisurf( tmp, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
           alpha(0.2);
       end
    end % for idx = 1 : size ( triToConnect, 1 )
end % for i=1:length(chordSpine)


if (DEBUG_DRAW_3D_TRI)
    %figHandle = figure;
    % erase earlier plot    
    figHandle = clf;
    
    trisurf( tri3D, verts3D(:,1), verts3D(:,2), verts3D(:,3) );                
    alpha(0.2);
    %shading interp;                   % other options are shading face / shading faceted
    shading faceted;
    
    colormap summer;
    %vrml(figHandle, 'out.wrl');
end
axis equal;
