% ============================================
% Author: Alex Chen
% email: alextpf@gmail.com
% 2014
% ============================================
function [ chords, newTri, verts, entryRow,entryCol, chordSpine ] = constructChord ( tri, verts, DEBUG )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Construct Chordal axis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% debug flags:
    % draw 3 kinds of triangle: terminal (Blue), junction (Red), sleeve (White). 
    % Use this flag to check if the 1st step of classifying the triangle
    % correctly
    DRAW_THREE_KINDS_TRI =  false;
    DEBUG_DRAW_CIRCLE =     false; % debug flag: draw circles
    DEBUG_DRAW_CHORD =      false; % debug flag: draw chrodal axis
    DRAW_CURR_JUN_TRI =     false;
    DEBUG_DRAW_NEW_TRI =    false;
    DEBUG_SHOW_NEW_TRI =    false;
    DRAW_NEW_TRI =          false; % draw the new triangulation
    DRAW_CHORDAL_AXIS =     false; % draw the chordal axis
    DRAW_PRUNED_CHORDS =    false; % draw the pruned chordal axis
    FILL_TRIANGLUES =       false; %==> This is very expensive. Caution if you turn this on.  check if every triangles is filled
    DEBUG_CHECK_GRAPH =     false;
    DEBUG_DRAW_VERT_LABEL = false;
    
    TO_PRESENT =            DEBUG; % use to generate fancy picture only
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find 3 kinds of tris: 
% a. terminal tri, b. sleeve tri, c. junction tri
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numVert = size ( verts, 1 );

% a data structure: N x 3. 
% based on the observation of Delaunay Triangulation, for each row (x,y,z), if x == 1 or x == numVert - 2: is an outer edge between vert 1 and vert 2, if y == 1: vert2 & vert 3, if z == 1: vert 1 & vert 3
triDif = abs ( [ tri(:,1)-tri(:,2), tri(:,2)-tri(:,3), tri(:,1)-tri(:,3) ] );
triDif ( triDif ~= 1 & triDif ~= numVert - 2 ) = 0;
triDif ( triDif ~= 0 ) = 1;

triType = sum ( triDif, 2); % sum the row; 0: junction tri, 1: sleeve tri, 2: terminal tri
 
%%%%%%%%%%%%%%%%%%%%%
% Declare earlier to prevent exception when early bailout
chordSpine = [];
entryRow = [];
entryCol = [];
%%%%%%%%%%%%%%%%%%%%%
chords = []; % a collection of 'chorAxis'
chordAxis = []; % first 2 columns denote (x,y) of the vertex, the 3rd column denotes the idx in verts
poly = [];
newTri = []; % new triangle list

junTriIdx = find ( triType == 0 ); % junction tri idx
sleTriIdx = find ( triType == 1 ); % sleeve tri idx
terTriIdx = find ( triType == 2 ); % terminal tri idx

junTri = tri ( junTriIdx, : );
sleTri = tri ( sleTriIdx, : );
terTri = tri ( terTriIdx, : );

if (DRAW_THREE_KINDS_TRI)
    figure;
    triplot( tri,verts(:,1),verts(:,2),'b');
    title('Triangle Classifycation: terminal (Blue), junction (Red), sleeve (White)');
    hold on;
    axis equal;
    
    numJunTri = size(junTri,1);
    numTerTri = size(terTri,1);
    
    % junction triangle, red
    for i = 1 : numJunTri
        idx = junTri(i,:);
        v = verts ( idx, : );
        fill(v(:,1),v(:,2),'r');
        alpha(0.5);
    end
    
    % terminal triangle, blue
    for i = 1 : numTerTri
        idx = terTri(i,:);
        v = verts ( idx, : );
        fill(v(:,1),v(:,2),'b');
        alpha(0.5);
    end
end

junChordIdx = ones ( size ( junTri, 1 ), 1 ) * -1;

% find the tips of the terminal tri's
difOfTer = triDif ( terTriIdx, : );

junTriEdge = triDif ( junTriIdx, : );
sleTriEdge = triDif ( sleTriIdx, : );
terTriEdge = triDif ( terTriIdx, : );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1st pass: start from terminal tri
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (DEBUG_DRAW_VERT_LABEL | DEBUG_DRAW_NEW_TRI | DEBUG_DRAW_VERT_LABEL )
    figure;
    hold on;
    triplot( tri,verts(:,1),verts(:,2),'k');
    title('debug use');
    hold on;
    axis equal;
end

for i = 1:size ( terTri, 1 )
    % allocat space for a polygon
    % start from the tip of a terminal tri
    curTri = terTri ( i, : );
    curDif = difOfTer ( i, : );
    tipAt = find ( curDif == 0) + 2;
        
    if ( tipAt > 3 )
        tipAt = tipAt - 3;
    end
    
    v1v2At = zeros ( 1, 3 );
    v1v2At ( tipAt ) = 1;
    v1v2At = find ( v1v2At ~= 1 );
    
    % 3 verts of the tri
    tipIdx = curTri ( tipAt );
    v1Idx = curTri ( v1v2At(1) );
    v2Idx = curTri ( v1v2At(2) );
    
    tip = verts ( tipIdx, : );
    v1 =  verts ( v1Idx, : );
    v2 =  verts ( v2Idx, : );
    
    % center of the edge(v1,v2)
    center = ( v1 + v2 ) / 2;
      
    % record chordal axis
    chordAxis = [ chordAxis; tip, -1 ];
    
    % enter the current branch
    keepGoinInBranch = true;
    isPruned = false; % flag: if the branch has been pruned
    
    while ( keepGoinInBranch )

        if ( isPruned )
            idx = size ( verts, 1 );
        else
            idx = -1;
        end
        
        % record chordal axis
        chordAxis = [ chordAxis; center, idx];

        
        needDoFanTri = false;
        if ( ~isPruned )  
            
            % create the polygon            
            poly = [ poly; tipIdx ];
    
            % test if the semi circle covers the polygon
            dif = center - v1;
            rSqr = sum ( dif.^2 );

            % debug: draw the circle centered at 'center'
            if ( DEBUG_DRAW_CIRCLE )
                drawCircle ( center, v1 );
            end 
            
            for j = 1:size(poly,1)
                dif = verts ( poly ( j ), : ) - center;
                vSqr = sum ( dif.^2 );

                if ( vSqr > rSqr )
                    isPruned = true;                    
                    needDoFanTri = true;
                    break;
                end        
            end            
        end
        
        % find the adjacent sleeve tri
        [adj,res] = FindAdjTri ( curTri, sleTri);

        if ( length ( adj ) == 1 )
            % record the adjacent verts
            [ center, curTriVerts, v1v2Idx, nbhrIdx] = FindAdjTriCenter ( res, adj, sleTri, verts );
            
            if ( needDoFanTri )
                adjIdx = curTriVerts ( v1v2Idx );
                
                poly = [ poly; adjIdx(1) ; adjIdx(2) ];
                poly = sortPoly ( poly );
                
                % construct the new tri
                numVerts = size ( verts, 1 );

                % add the new vert ( center of junTri )
                verts = [ verts; center ];
                
                if ( DEBUG_DRAW_VERT_LABEL )
                   u = size(verts,1);
                   str = sprintf ('%d', u);
                   x = verts(u,1);
                   y = verts(u,2);
                   text(x,y,str);
                end
                
                for fanIdx = 1 : length ( poly ) - 1
                    i1 = poly (fanIdx);
                    i2 = poly (fanIdx + 1);
                    
                    % use normal to check which direction to use
                    tmpTri = TriDir (numVerts + 1, i1, i2, verts);
                    
                    newTri = [ newTri; tmpTri ];
                end
                
                % modify chordAxis
                chordAxis ( end, 3) = numVerts + 1;
                
                % reset poly
                poly = [];                
                
                if ( DEBUG_DRAW_NEW_TRI )
                    triplot(newTri,verts(:,1),verts(:,2),'b','LineWidth',2);   
                end                
            end
            
            [ center, tip, tipIdx, v1, tipSideIdx, v2, singleIdx ] = FindAdjTriangulation ( sleTriEdge, verts, curTriVerts, adj, nbhrIdx );

            % replace the current tri by the adjacent tri
            curTri = sleTri ( adj, : );

            if ( isPruned )
                
                numVerts = size ( verts, 1 );
                verts = [ verts; center ];
                
                if ( DEBUG_DRAW_VERT_LABEL )
                   u = size(verts,1);
                   str = sprintf ('%d', u);
                   x = verts(u,1);
                   y = verts(u,2);
                   text(x,y,str);
                end
                
                % determine how we triangulate
                preCenter = verts ( numVerts, : );
                
                preCenter2TipSide = preCenter - v1;
                nextCenter2Tip = center - tip;
                
                if ( sum ( preCenter2TipSide.^2 ) < sum ( nextCenter2Tip.^2 )  )
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % take preCenter2TipSide
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    % use normal to check which direction to use
                    tmpTri = TriDir (numVerts + 1, numVerts, tipSideIdx, verts);                    
                    newTri = [ newTri; tmpTri ];
                    
                    % use normal to check which direction to use
                    tmpTri = TriDir (numVerts, tipIdx, tipSideIdx, verts);                    
                    newTri = [ newTri; tmpTri ];
                    
                    % use normal to check which direction to use
                    tmpTri = TriDir (numVerts + 1, numVerts, singleIdx, verts);                    
                    newTri = [ newTri; tmpTri ];
                    
                else
                    %%%%%%%%%%%%%%%%%%%%%%%%
                    % take nextCenter2Tip
                    %%%%%%%%%%%%%%%%%%%%%%%%
                    
                    % use normal to check which direction to use
                    tmpTri = TriDir (numVerts + 1, numVerts, tipIdx, verts);                    
                    newTri = [ newTri; tmpTri ];
                    
                    % use normal to check which direction to use
                    tmpTri = TriDir (numVerts + 1, tipIdx, tipSideIdx, verts);
                    newTri = [ newTri; tmpTri ];
                    
                    % use normal to check which direction to use
                    tmpTri = TriDir (numVerts + 1, numVerts, singleIdx, verts);
                    newTri = [ newTri; tmpTri ];
                    
                end
                 
                if ( DEBUG_DRAW_NEW_TRI )
                    triplot(newTri,verts(:,1),verts(:,2),'b','LineWidth',2); 
                end 
            end
            
            % take the found tri out of sleeve tri list
            sleTri ( adj, : ) = [];
            sleTriEdge ( adj, : ) = [];
            
        elseif ( isempty ( adj ) )            
            
            % we'v reached the junction tri list
            [adj,res] = FindAdjTri ( curTri, junTri);

            if ( length ( adj ) == 1 )
                if ( needDoFanTri )
                    [center, curTri, v1v2Idx, nbhrIdx] = FindAdjTriCenter ( res, adj, junTri, verts );
                    adjIdx = curTri ( v1v2Idx );

                    poly = [ poly; adjIdx(1) ; adjIdx(2) ];
                    poly = sortPoly ( poly );

                    % construct the new tri
                    numVerts = size ( verts, 1 );
                    verts = [ verts; center];
                    
                    if ( DEBUG_DRAW_VERT_LABEL )
                       u = size(verts,1);
                       str = sprintf ('%d', u);
                       x = verts(u,1);
                       y = verts(u,2);
                       text(x,y,str);
                    end
                
                    % revise chord axis
                    chordAxis ( end, 3 ) = size ( verts, 1 );

                    for fanIdx = 1 : length ( poly ) - 1
                        i1 = poly (fanIdx);
                        i2 = poly (fanIdx + 1);
                        
                        % use normal to check which direction to use
                        tmpTri = TriDir (numVerts + 1, i1, i2, verts);
                        newTri = [ newTri; tmpTri ];
                    end

                    % reset poly
                    poly = [];                

                    if ( DEBUG_DRAW_NEW_TRI )
                        triplot(newTri,verts(:,1),verts(:,2),'b','LineWidth',2);   
                    end    
                end
                % take the center of mass
                junc = junTri ( adj, : );
                
                c = GetCenter ( junc, verts );                

                if ( DEBUG_DRAW_CHORD )
                    plot ( chordAxis ( :, 1 ), chordAxis ( :, 2 ), 'r' );
                end

                adjIdx = res ( adj, : );
                adjIdx = junc ( adjIdx == 1 );
                
                % construct the fan
                if ( ~isPruned )
                    poly = [ poly; adjIdx(1) ; adjIdx(2) ];                    
                    poly = sortPoly ( poly );

                    % construct the new tri
                    numVerts = size ( verts, 1 );
                    
                    if ( junChordIdx ( adj ) == -1 )
                        tmpIdx = numVerts + 1;
                        
                        % add the new vert ( center of junTri )
                        verts = [ verts; c ];
                        
                        if ( DEBUG_DRAW_VERT_LABEL )
                           u = size(verts,1);
                           str = sprintf ('%d', u);
                           x = verts(u,1);
                           y = verts(u,2);
                           text(x,y,str);
                        end
                
                        % record the index
                        junChordIdx ( adj ) = numVerts+1;
                    else
                        tmpIdx = junChordIdx ( adj );
                    end
                    
                    for fanIdx = 1 : length ( poly ) - 1
                        i1 = poly (fanIdx);
                        i2 = poly (fanIdx + 1);
                        
                        % use normal to check which direction to use
                        tmpTri = TriDir (tmpIdx, i1, i2, verts);
                        newTri = [ newTri; tmpTri ];
                        
                    end
                    
                    % reset poly
                    poly = [];
                    
                    if ( DEBUG_DRAW_NEW_TRI )
                        triplot(newTri,verts(:,1),verts(:,2),'b','LineWidth',2);
                    end
                else
                    
                    % construct the new tri
                    numVerts = size ( verts, 1 );
                    
                    tmpIdx1 = adjIdx (1);
                    tmpIdx2 = adjIdx (2);
                        
                    if ( junChordIdx ( adj ) == -1 )                        
                        tmpIdx = numVerts +1;
                        
                        % add the new vert ( center of junTri )
                        verts = [ verts; c ];

                        if ( DEBUG_DRAW_VERT_LABEL )
                           u = size(verts,1);
                           str = sprintf ('%d', u);
                           x = verts(u,1);
                           y = verts(u,2);
                           text(x,y,str);
                        end
                
                        % record the index
                        junChordIdx ( adj ) = numVerts+1;
                    else
                        tmpIdx = junChordIdx ( adj );                        
                    end
                    
                    % use normal to check which direction to use
                    tmpTri = TriDir (tmpIdx, numVerts, tmpIdx1, verts);
                    newTri = [ newTri; tmpTri ];

                    % use normal to check which direction to use
                    tmpTri = TriDir (tmpIdx, numVerts, tmpIdx2, verts);
                    newTri = [ newTri; tmpTri ];
                    
                    if ( DEBUG_DRAW_NEW_TRI )
                        triplot(newTri,verts(:,1),verts(:,2),'b','LineWidth',2); 
                    end
                end % if ( ~isPruned )

                chordAxis = [ chordAxis; c, tmpIdx ];

                % push the current chord into the collection of chordal
                % axis
                chords = [ chords, {chordAxis} ];
                chordAxis = [];
                keepGoinInBranch = false;
            else          
                %  error
                disp("ROI region too small, or not having enough edges");
                return;
            end
        elseif ( length ( adj ) > 1 )
          %  error
          disp("ROI region too small, or not having enough edges");
          return;
        end % if ( length ( adj ) == 1 ); find the adjacent sleeve tri
    end % while ( keepGoinInBranch ); while going in the current branch
end % for i = 1:size ( terTri, 1 ); for each terminal triangle

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2nd pass: 
% go from juntion tri's and look for 
% leftover sleeve tri's, go from there 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%if ( size(sleTri,1) ~= 0 )
        
    junTriPair = [];
    
    for curJunIdx = 1 : size ( junTri, 1 )
        
        keepLookingCurrJunTri = true;        
        while (keepLookingCurrJunTri)
            
            curTri = junTri ( curJunIdx, : );
            centerIdx = junChordIdx ( curJunIdx );
            
            if ( centerIdx ~= -1 )
                c = verts ( centerIdx, : );
            else
                c = GetCenter ( curTri, verts );
                verts = [ verts; c ];
                
                if ( DEBUG_DRAW_VERT_LABEL )
                   u = size(verts,1);
                   str = sprintf ('%d', u);
                   x = verts(u,1);
                   y = verts(u,2);
                   text(x,y,str);
                end
                
                numVets = size ( verts, 1 );
                junChordIdx ( curJunIdx ) = numVets;
                centerIdx = numVets;
            end
            
            % push center point of the current juntion tri into chord axis
            chordAxis = [ chordAxis; c, centerIdx ];

            if (DRAW_CURR_JUN_TRI)
                v = verts ( curTri, : );
                fill(v(:,1),v(:,2),'c');
                alpha(0.2)
            end
            
            % check if the current junction tri has a adjacent leftover sleeve tri
            [adjSleIdx,res] = FindAdjTri ( curTri, sleTri);

            hasAdjSleTri =( ~ isempty ( adjSleIdx ) );
            if ( hasAdjSleTri )
                
                keepGoinInBranch = true;

                % choose an arbitrary adjacent sleeve tri
                selAdj = adjSleIdx(1);

                [center, curTri, v1v2Idx, nbhrIdx] = FindAdjTriCenter ( res, selAdj, sleTri, verts );
                
                % construct the new tri                
                verts = [ verts; center];
                
                if ( DEBUG_DRAW_VERT_LABEL )
                   u = size(verts,1);
                   str = sprintf ('%d', u);
                   x = verts(u,1);
                   y = verts(u,2);
                   text(x,y,str);
                end
                
                numVerts = size (verts,1);
                
                tmpV1 = curTri ( v1v2Idx (1) );
                tmpV2 = curTri ( v1v2Idx (2) );
                
                % use normal to check which direction to use
                tmpTri = TriDir (centerIdx, numVerts, tmpV1, verts);
                newTri = [ newTri; tmpTri ];
                
                % use normal to check which direction to use
                tmpTri = TriDir (centerIdx, numVerts, tmpV2, verts);
                newTri = [ newTri; tmpTri ];
                
                if ( DEBUG_DRAW_NEW_TRI )
                    triplot(newTri,verts(:,1),verts(:,2),'b','LineWidth',2); 
                end 
                
                while ( keepGoinInBranch )
                    [center, curTri, v1v2Idx, nbhrIdx] = FindAdjTriCenter ( res, selAdj, sleTri, verts );
                    
                    % avoid repetition of chords
                    lastChordPt = chordAxis(end,3);
                    
                    if (lastChordPt ~= numVerts)                        
                        % push the center into chord
                        chordAxis = [ chordAxis; center, numVerts ];                        
                    end
                    
                    [ nextCenter, tip, tipIdx, v1, tipSideIdx, v2, singleIdx ] = FindAdjTriangulation ( sleTriEdge, verts, curTri, selAdj, nbhrIdx );

                    numVerts = size ( verts, 1 );
                    verts = [ verts; nextCenter ];

                    if ( DEBUG_DRAW_VERT_LABEL )
                       u = size(verts,1);
                       str = sprintf ('%d', u);
                       x = verts(u,1);
                       y = verts(u,2);
                       text(x,y,str);
                    end
                
                    chordAxis = [ chordAxis; nextCenter, numVerts + 1 ];
                                        
                    % determine how we triangulate
                    preCenter = verts ( numVerts, : );

                    preCenter2TipSide = preCenter - v1;
                    nextCenter2Tip = center - tip;

                    if ( sum ( preCenter2TipSide.^2 ) < sum ( nextCenter2Tip.^2 )  )
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % take preCenter2TipSide
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%
                        
                        % use normal to check which direction to use
                        tmpTri = TriDir (numVerts + 1, numVerts, tipSideIdx, verts);
                        newTri = [ newTri; tmpTri ];
                        
                        % use normal to check which direction to use
                        tmpTri = TriDir (numVerts, tipIdx, tipSideIdx, verts);
                        newTri = [ newTri; tmpTri ];
                        
                        % use normal to check which direction to use
                        tmpTri = TriDir (numVerts + 1, numVerts, singleIdx, verts);
                        newTri = [ newTri; tmpTri ];
                    else
                        %%%%%%%%%%%%%%%%%%%%%%%
                        % take nextCenter2Tip
                        %%%%%%%%%%%%%%%%%%%%%%%
                        
                        % use normal to check which direction to use
                        tmpTri = TriDir (numVerts + 1, numVerts, tipIdx, verts);
                        newTri = [ newTri; tmpTri ];
                        
                        % use normal to check which direction to use
                        tmpTri = TriDir (numVerts + 1, tipSideIdx, tipIdx, verts);
                        newTri = [ newTri; tmpTri ];
                        
                        % use normal to check which direction to use
                        tmpTri = TriDir (numVerts + 1, numVerts, singleIdx, verts);
                        newTri = [ newTri; tmpTri ];
                        
                    end

                    if ( DEBUG_DRAW_NEW_TRI )
                        triplot(newTri,verts(:,1),verts(:,2),'b','LineWidth',2); 
                    end 

                    % update numVerts
                    numVerts = size (verts,1);
                    
                    % delete the entry
                    sleTri ( selAdj, : ) = [];
                    sleTriEdge ( selAdj, : ) = [];

                    [adjSleIdx,res] = FindAdjTri ( curTri, sleTri);
                    
                    numAdjSleTri = length(adjSleIdx);
                    if ( numAdjSleTri == 0 )
                        keepGoinInBranch = false;
                    elseif ( numAdjSleTri == 1 )
                        selAdj = adjSleIdx(1);
                    elseif ( numAdjSleTri > 1 )
                        % error
                        disp('error'); 
                        return;
                    end % if ( numAdjSleTri == 0 )
                end % while ( keepGoinInBranch )

                % search for the adjacent junction tri
                [adjJunIdx,res] = FindAdjTri ( curTri, junTri);

                numAdjJunTri = length(adjJunIdx);
                if ( numAdjJunTri == 1 )
                    if ( adjJunIdx ~= curJunIdx )
                        
                        curTri = junTri ( adjJunIdx, : );
                        numVerts = size ( verts, 1 );
                        tmp = junChordIdx ( adjJunIdx );
                        if ( tmp ~= -1 )
                            c = verts ( tmp, : );
                        else
                            c = GetCenter ( curTri, verts );

                            % add new vert
                            verts = [verts; c];
                            
                            if ( DEBUG_DRAW_VERT_LABEL )
                               u = size(verts,1);
                               str = sprintf ('%d', u);
                               x = verts(u,1);
                               y = verts(u,2);
                               text(x,y,str);
                            end
                
                            tmp = numVerts + 1;
                            junChordIdx ( adjJunIdx ) = tmp;
                        end
                        
                        % use normal to check which direction to use
                        tmpTri = TriDir (numVerts, tmp, tipSideIdx, verts);
                        newTri = [ newTri; tmpTri ];
                        
                        % use normal to check which direction to use
                        tmpTri = TriDir (numVerts, tmp, singleIdx, verts);
                        newTri = [ newTri; tmpTri ];
                        
                        chordAxis = [ chordAxis; c, tmp ];
                        
                        if ( DEBUG_DRAW_NEW_TRI )
                            triplot(newTri,verts(:,1),verts(:,2),'b','LineWidth',2); 
                        end 

                        if ( DEBUG_DRAW_CHORD )
                            plot ( chordAxis ( :, 1 ), chordAxis ( :, 2 ), 'r' );
                        end

                        chords = [ chords, {chordAxis} ];
                        chordAxis = [];
                        
                    else
                        disp('error');
                        return;
                    end
                elseif ( numAdjJunTri == 2 )
                    % this happens when 2 junction tris are adjacent
                    % or the sle tri has 2 adj jun tri's
                    for k = 1:2
                        junTriIdx = adjJunIdx(k);
                        if ( junTriIdx ~= curJunIdx )
                            
                            curTri = junTri ( junTriIdx, : );
                            numVerts = size ( verts, 1 );
                            tmp = junChordIdx ( junTriIdx );
                            if ( tmp ~= -1 )
                                c = verts ( tmp, : );
                            else
                                c = GetCenter ( curTri, verts );
                                verts = [ verts; c ];
                                
                                if ( DEBUG_DRAW_VERT_LABEL )
                                   u = size(verts,1);
                                   str = sprintf ('%d', u);
                                   x = verts(u,1);
                                   y = verts(u,2);
                                   text(x,y,str);
                                end
                
                                tmp = numVerts + 1;
                                junChordIdx ( junTriIdx ) = tmp;
                            end
                            
                            % construct new tri
                            tmp1 = res ( junTriIdx, : );
                            edgeIdx = curTri ( tmp1 == 1 );
                            
                            % use normal to check which direction to use
                            tmpTri = TriDir (edgeIdx(1), tmp, numVerts, verts);
                            newTri = [ newTri; tmpTri ];
                            
                            % use normal to check which direction to use
                            tmpTri = TriDir (edgeIdx(2), tmp, numVerts, verts);
                            newTri = [ newTri; tmpTri ];
                            
                            if ( DEBUG_DRAW_NEW_TRI )
                                triplot(newTri,verts(:,1),verts(:,2),'b','LineWidth',2); 
                            end 
                            
                            chordAxis = [ chordAxis; c, tmp ];

                            if ( DEBUG_DRAW_CHORD )
                                plot ( chordAxis ( :, 1 ), chordAxis ( :, 2 ), 'r' );
                            end

                            chords = [ chords, {chordAxis} ];
                            chordAxis = [];
                            
                        end
                    end
                elseif ( numAdjJunTri == 0 )
                    disp ('error');
                    return;
                end                
                
            else                
                % check if the current jun tri has a adjacent jun tri
                [adjJunIdx,res] = FindAdjTri ( curTri, junTri);                
                hasAdjJunTri = ~isempty(adjJunIdx);

                if ( hasAdjJunTri )
                    
                    for idx = 1 : length ( adjJunIdx )
                        pair = [curJunIdx, adjJunIdx(idx)];
                        
                        [adj1,res1] = FindAdjTri ( pair, junTriPair); % use the same function to serve a similar purpose

                        hasVisited = ~isempty(adj1);
                        if (~hasVisited)                            
                            junTriPair = [ junTriPair; pair ]; 
                            adjJunIdx = adjJunIdx(idx);

                            break;
                        end
                        
                        if (idx == length ( adjJunIdx ) )
                            keepLookingCurrJunTri = false;
                            hasAdjJunTri = false;
                            chordAxis = [];
                        end
                        
                    end % for idx = 1 : length ( adjJunIdx )

                    if ( ~hasAdjJunTri )
                        break;
                    end
                    
                    [center, curTri, v1v2Idx, nbhrIdx] = FindAdjTriCenter ( res, adjJunIdx, junTri, verts );
                
                    % triangulate current tri and the mid point of the adj
                    % edge
                    numVerts = size(verts,1);
                
                    verts = [verts; center];
                    
                    if ( DEBUG_DRAW_VERT_LABEL )
                       u = size(verts,1);
                       str = sprintf ('%d', u);
                       x = verts(u,1);
                       y = verts(u,2);
                       text(x,y,str);
                    end                
                       
                    % use normal to check which direction to use
                    tmpTri = TriDir (centerIdx, curTri(v1v2Idx(1)), numVerts+1, verts);
                    newTri = [ newTri; tmpTri ];

                    % use normal to check which direction to use
                    tmpTri = TriDir (centerIdx, curTri(v1v2Idx(2)), numVerts+1, verts);
                    newTri = [ newTri; tmpTri ];
                    
                    chordAxis = [ chordAxis; center, numVerts + 1 ];
                    
                    if ( DEBUG_DRAW_NEW_TRI )
                        triplot(newTri,verts(:,1),verts(:,2),'b','LineWidth',2); 
                    end
                    
                    adjTri = junTri ( adjJunIdx, : );

                    tmpIdx = junChordIdx ( adjJunIdx );
                    
                    if ( tmpIdx == -1 )
                        c = GetCenter ( adjTri, verts );
                        verts = [ verts; c ];
                        
                        if ( DEBUG_DRAW_VERT_LABEL )
                           u = size(verts,1);
                           str = sprintf ('%d', u);
                           x = verts(u,1);
                           y = verts(u,2);
                           text(x,y,str);
                        end
                
                        tmpIdx = size ( verts, 1 );
                        junChordIdx (adjJunIdx) = tmpIdx;
                    else
                        c = verts ( tmpIdx, : );
                    end

                    % push center point of the current juntion tri into chord axis
                    chordAxis = [ chordAxis; c, tmpIdx ];
                    chords = [ chords, {chordAxis} ];
                    
                    if ( DEBUG_DRAW_CHORD )
                        plot ( chordAxis ( :, 1 ), chordAxis ( :, 2 ), 'r' );
                    end
                    
                    % construct the new tri
                    tmpTri = TriDir (tmpIdx, curTri(v1v2Idx(1)), numVerts+1, verts);
                    newTri = [ newTri; tmpTri ];
                    tmpTri = TriDir (tmpIdx, curTri(v1v2Idx(2)), numVerts+1, verts);
                    newTri = [ newTri; tmpTri ];
                    
                    if ( DEBUG_DRAW_NEW_TRI )
                        triplot(newTri,verts(:,1),verts(:,2),'b','LineWidth',2); 
                    end
                    
                    % reset chord axis
                    chordAxis = [];
                else
                    keepLookingCurrJunTri = false;
                    chordAxis = [];
                end % if ( hasAdjJunTri )
            end % if ( hasAdjSleTri )
        end % while (keepLookingCurrJunTri)
    end % for curJunIdx = 1 : size ( junTri, 1 )
%end % if ( size(sleTri,1) ~= 0 )

% Sanity check:
if ( size(sleTri,1) > 0 )
    test(' % Sanity check: "size(sleTri,1) > 0" ');
    return;
end

if (DEBUG_SHOW_NEW_TRI)
    newVerts = verts;
    figure;
    triplot( newTri,newVerts(:,1),newVerts(:,2),'b');
    axis equal;
    hold on;
    
    for i=1:size(newVerts,1)
       str = sprintf ('%d',i);
       x = newVerts(i,1);
       y = newVerts(i,2);
       text(x,y,str,'FontSize',18);
    end 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. convert chordal spine to graph structure
%    use spare matrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:length(chords)
    chord = chords(i);
    chord = chord{1};
    
    prunedIdx = chord ( :, 3 );
    prunedIdx = prunedIdx ( prunedIdx ~= -1);
    
    % plot(chord(:,1),chord(:,2),'r');
    if ( length(prunedIdx) > 1 )
        
        res = ismember ( chordSpine, prunedIdx );
        pivotIdx = find(res~=0);
        pivot = chordSpine (pivotIdx); % the point where one piece of chord intersects with another
        
        % sanity check; only 1 pivot, pivot equals to front or end
        head = prunedIdx(1);
        tail = prunedIdx(end);
        
        headPivot =[];
        tailPivot =[];
        
        if ( ~isempty(pivot) )
            
            if ( length(pivot) > 2 )
                disp('error');
                return;
            end
            
            %find headPivot
            res = ismember (pivot,head);
            headPivotIdx = pivotIdx ( res == 1 );
            headPivot = pivot (res == 1);
            
            %find tailPivot
            res = ismember (pivot,tail);
            tailPivotIdx = pivotIdx ( res == 1 );
            tailPivot = pivot (res == 1);
            
            %sanity
            if ( isempty(headPivot) & isempty(tailPivot) )
                disp('error');
                return;
            end
            
            if ( headPivot == head )
                prunedIdx = prunedIdx (2:end);
            end
            
            if ( tailPivot == tail )
                prunedIdx = prunedIdx (1:end-1);            
            end
            
        end

        if ( ~isempty(prunedIdx) )
            startIdx = length(chordSpine) + 1;
            endIdx = startIdx + length(prunedIdx) - 1;

            chordSpine = [ chordSpine; prunedIdx];

            % the connections within the chord
            tmp1 = startIdx : endIdx - 1;
            tmp2 = tmp1 + 1;

            entryRow = [ entryRow, tmp1 ];
            entryCol = [ entryCol, tmp2 ];
        else
            startIdx = tailPivotIdx;
            endIdx = headPivotIdx;
        end

        % the connection between chord and pivot
        if ( headPivot == head )
            % pivot in the front of prunedIdx
            entryRow = [ entryRow, startIdx ];
            entryCol = [ entryCol, headPivotIdx ];
        end
        
        if ( tailPivot == tail )
            % pivot in the back of prunedIdx
            entryRow = [ entryRow, endIdx ];
            entryCol = [ entryCol, tailPivotIdx ];
        end
    end
end

% sanity check
if ( size(entryRow) ~= size(entryCol) )
    disp('error');                
    return;
end
% construct sparse matrix
graph = sparse( entryRow,entryCol,ones(1,length(entryRow)),length(chordSpine),length(chordSpine) );
graph = graph | graph';

% extract row & col
[entryRow,entryCol,val]=find(graph);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% debug
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (DRAW_CHORDAL_AXIS)
    % draw chordal axis on a separate figure

    figure;
    triplot(tri,verts(:,1),verts(:,2),'g');
    axis equal;

    hold on;

    for i=1:length(chords)
        chord = chords(i);
        chord = chord{1};
        plot(chord(:,1),chord(:,2),'r');
        if (DRAW_PRUNED_CHORDS)
            prunedIdx = chord ( :, 3 );
            prunedChord = chord ( prunedIdx ~= -1, :);

            plot(prunedChord(:,1),prunedChord(:,2),'b', 'LineWidth', 2);
        end
    end
% 
%     for i=1:size(verts,1)
%        str = sprintf ('%d',i);
%        x = verts(i,1);
%        y = verts(i,2);
%        text(x,y,str);
%     end 
end % if (DRAW_CHORDAL_AXIS)

if ( DRAW_NEW_TRI )
    figure;
    triplot( newTri,newVerts(:,1),newVerts(:,2),'b');
    axis equal;
    for i=1:size(newVerts,1)
       str = sprintf ('%d',i);
       x = newVerts(i,1);
       y = newVerts(i,2);
       text(x,y,str,'FontSize',18);
    end 
end

if ( FILL_TRIANGLUES )
    figure;
    triplot( newTri,newVerts(:,1),newVerts(:,2),'b');
    hold on;
    axis equal;
    for i = 1 : size (newTri,1)   
        curTri = newTri(i,:);
        v = newVerts ( curTri, : );
        fill(v(:,1),v(:,2),'c');
        alpha(0.2);
    end
end

% check the graph
if (DEBUG_CHECK_GRAPH)
    figure;
    triplot( newTri,newVerts(:,1),newVerts(:,2),'b');
    axis equal;
    hold on;
    for i = 1:length(entryRow)
        id1 = chordSpine (entryRow(i));
        id2 = chordSpine (entryCol(i));
        pt = newVerts([id1,id2],:);
        plot( pt(:,1), pt(:,2),'r','LineWidth',3);
    end
end

% for presentation
if (TO_PRESENT)
    figure;
    triplot( tri,verts(:,1),verts(:,2),'b');
    title({'Terminal (Blue), Junction (Red), Sleeve (White) Triangles',
           'Cordal Axis (Green)' });
    hold on;
    axis equal;
    
    numJunTri = size(junTri,1);
    numTerTri = size(terTri,1);
    
    % junction triangle, red
    for i = 1 : numJunTri
        idx = junTri(i,:);
        v = verts ( idx, : );
        fill(v(:,1),v(:,2),'r');
        alpha(0.5);
    end
    
    % terminal triangle, blue
    for i = 1 : numTerTri
        idx = terTri(i,:);
        v = verts ( idx, : );
        fill(v(:,1),v(:,2),'b');
        alpha(0.5);
    end    
    
    for i=1:length(chords)
        chord = chords(i);
        chord = chord{1};
        plot(chord(:,1),chord(:,2),'g', 'LineWidth', 2);
        if (DRAW_PRUNED_CHORDS)
            prunedIdx = chord ( :, 3 );
            prunedChord = chord ( prunedIdx ~= -1, :);

            plot(prunedChord(:,1),prunedChord(:,2),'g', 'LineWidth', 2);
        end
    end
end