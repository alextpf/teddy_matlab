function [ chords, newTri, verts ] = constructChord ( tri, verts, DEBUG_DRAW_CIRCLE, DEBUG_DRAW_CHORD, DRAW_CURR_JUN_TRI, DEBUG_DRAW_NEW_TRI )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Construct Chordal axis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find 3 kinds of tris: 
% a. terminal tri, b. sleeve tri, c. junction tri
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numVert = size ( verts, 1 );
% a data structure: Nx3. for each row: (x,y,z) if x == 1: an outer edge between vert 1 and vert 2, if y == 1: vert2 & vert 3, if z == 1: vert 1 & vert 3
triDif = abs ( [ tri(:,1)-tri(:,2), tri(:,2)-tri(:,3), tri(:,1)-tri(:,3) ] );
triDif ( triDif ~= 1 & triDif ~= numVert - 1 ) = 0;
triDif ( triDif ~= 0 ) = 1;

triType = sum ( triDif, 2); % sum the row; 0: junction tri, 1: sleeve tri, 2: terminal tri
 
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

junChordIdx = ones ( size ( junTri, 1 ), 1 ) * -1;

% find the tips of the terminal tri's
difOfTer = triDif ( terTriIdx, : );

junTriEdge = triDif ( junTriIdx, : );
sleTriEdge = triDif ( sleTriIdx, : );
terTriEdge = triDif ( terTriIdx, : );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1st pass: start from terminal tri
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hold on;
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

                for fanIdx = 1 : length ( poly ) - 1
                    i1 = poly (fanIdx);
                    i2 = poly (fanIdx + 1);
                    newTri = [ newTri; numVerts + 1, i1, i2 ];
                end
                
                % add the new vert ( center of junTri )
                verts = [ verts; center ];

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
                
                % determine how we triangulate
                preCenter = verts ( numVerts, : );
                
                preCenter2TipSide = preCenter - v1;
                nextCenter2Tip = center - tip;
                
                if ( sum ( preCenter2TipSide.^2 ) < sum ( nextCenter2Tip.^2 )  )
                    % take preCenter2TipSide
                    newTri = [ newTri; numVerts + 1, numVerts, tipSideIdx ];
                    newTri = [ newTri; numVerts, tipSideIdx, tipIdx ];
                    newTri = [ newTri; numVerts + 1, numVerts, singleIdx ];
                else
                    % take nextCenter2Tip
                    newTri = [ newTri; numVerts + 1, numVerts, tipIdx ];
                    newTri = [ newTri; numVerts + 1, tipIdx, tipSideIdx ];
                    newTri = [ newTri; numVerts + 1, numVerts, singleIdx ];
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
                    
                    % revise chord axis
                    chordAxis ( end, 3 ) = size ( verts, 1 );

                    for fanIdx = 1 : length ( poly ) - 1
                        i1 = poly (fanIdx);
                        i2 = poly (fanIdx + 1);
                        newTri = [ newTri; numVerts + 1, i1, i2 ];
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
                        
                        % record the index
                        junChordIdx ( adj ) = numVerts+1;
                    else
                        tmpIdx = junChordIdx ( adj );
                    end
                    
                    for fanIdx = 1 : length ( poly ) - 1
                        i1 = poly (fanIdx);
                        i2 = poly (fanIdx + 1);
                        newTri = [ newTri; tmpIdx, i1, i2 ];
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

                        % record the index
                        junChordIdx ( adj ) = numVerts+1;
                    else
                        tmpIdx = junChordIdx ( adj );                        
                    end
                    
                    newTri = [ newTri; tmpIdx, numVerts, tmpIdx1 ];
                    newTri = [ newTri; tmpIdx, numVerts, tmpIdx2 ];
                    
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
                disp('error');
                return;
            end
        elseif ( length ( adj ) > 1 )
          %  error
          disp('error');
          return;
        end % if ( length ( adj ) == 1 ); find the adjacent sleeve tri
    end % while ( keepGoinInBranch ); while going in the current branch
end % for i = 1:size ( terTri, 1 ); for each terminal triangle

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2nd pass: 
% go from juntion tri's and look for 
% leftover sleeve tri's, go from there 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ( size(sleTri,1) ~= 0 )
        
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
                numVerts = size (verts,1);
                
                tmpV1 = curTri ( v1v2Idx (1) );
                tmpV2 = curTri ( v1v2Idx (2) );
                
                newTri = [ newTri; centerIdx, numVerts, tmpV1 ];
                newTri = [ newTri; centerIdx, numVerts, tmpV2 ];
                
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

                    chordAxis = [ chordAxis; nextCenter, numVerts + 1 ];
                                        
                    % determine how we triangulate
                    preCenter = verts ( numVerts, : );

                    preCenter2TipSide = preCenter - v1;
                    nextCenter2Tip = center - tip;

                    if ( sum ( preCenter2TipSide.^2 ) < sum ( nextCenter2Tip.^2 )  )
                        % take preCenter2TipSide
                        newTri = [ newTri; numVerts + 1, numVerts, tipSideIdx ];
                        newTri = [ newTri; numVerts, tipSideIdx, tipIdx ];
                        newTri = [ newTri; numVerts + 1, numVerts, singleIdx ];
                    else
                        % take nextCenter2Tip
                        newTri = [ newTri; numVerts + 1, numVerts, tipIdx ];
                        newTri = [ newTri; numVerts + 1, tipIdx, tipSideIdx ];
                        newTri = [ newTri; numVerts + 1, numVerts, singleIdx ];
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
                            tmp = numVerts + 1;
                            junChordIdx ( adjJunIdx ) = tmp;
                        end
                        
                        newTri = [ newTri; numVerts, tmp, tipSideIdx ];
                        newTri = [ newTri; numVerts, tmp, singleIdx ];
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
                                tmp = numVerts + 1;
                                junChordIdx ( junTriIdx ) = tmp;
                            end
                            
                            % construct new tri
                            tmp1 = res ( junTriIdx, : );
                            edgeIdx = curTri ( tmp1 == 1 );
                            
                            newTri = [ newTri; edgeIdx(1), numVerts, tmp ];
                            newTri = [ newTri; edgeIdx(2), numVerts, tmp ];
                            
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
                        
                    newTri = [ newTri; centerIdx, numVerts+1, curTri(v1v2Idx(1))];
                    newTri = [ newTri; centerIdx, numVerts+1, curTri(v1v2Idx(2))];
                    
                    chordAxis = [ chordAxis; center, numVerts + 1 ];
                    
                    if ( DEBUG_DRAW_NEW_TRI )
                        triplot(newTri,verts(:,1),verts(:,2),'b','LineWidth',2); 
                    end
                    
                    adjTri = junTri ( adjJunIdx, : );

                    tmpIdx = junChordIdx ( adjJunIdx );
                    
                    if ( tmpIdx == -1 )
                        c = GetCenter ( adjTri, verts );
                        verts = [ verts; c ];
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
                    newTri = [ newTri; numVerts+1, tmpIdx, curTri(v1v2Idx(1)) ];
                    newTri = [ newTri; numVerts+1, tmpIdx, curTri(v1v2Idx(2)) ];
                    
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
end % if ( size(sleTri,1) ~= 0 )

% Sanity check:
if ( size(sleTri,1) > 0 )
    test('error');
    return;
end
