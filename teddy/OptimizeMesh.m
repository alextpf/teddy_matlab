% ============================================
% Author: Alex Chen
% email: alextpf@gmail.com
% 2014
% ============================================
function OptimizeMesh(verts,tri)
edgeStruct = ContructEdgeStrcut(verts,tri);

newTri = tri;

% draw before and after
DEBUG_DRAW_PART = false;
DEBUG_COLLAPSE = false;
DEBUG_SWAP = false;
DEBUG_SPLIT = false;
DEBUG_SHOW_RESULT = true;
    
MAX_ANGLE = 60; % in degree
numVerts = size(verts,1);

% loop through each edge, try edge collapse -> swap -> split
toDeleteIdx = [];
for i = 1 : length (edgeStruct)
    edgeS = edgeStruct(i);
    edgeIdx = edgeS.Edge;
    
    doubleConnectIdx = edgeS.DoubleConnectIdx;
    singleConnectIdx = edgeS.SingleConnectIdx;    
    
    doubleTris = tri (doubleConnectIdx, :);
    singleTris = tri (singleConnectIdx, :);
    starTri = [ doubleTris; singleTris ];
    
    v1 = verts(edgeIdx(1),:);
    v2 = verts(edgeIdx(2),:); 
    
    if (DEBUG_DRAW_PART)
        figure;
        hold on;

        % copy the start part of tris
        testTri = tri (doubleConnectIdx, :);        
        trisurf(testTri,verts(:,1),verts(:,2),verts(:,3),'LineWidth',2);
        
        testTri = tri (singleConnectIdx, :);        
        trisurf(testTri,verts(:,1),verts(:,2),verts(:,3));
        alpha(0.4);
        
        v = [v1;v2];
        plot3(v(:,1),v(:,2),v(:,3),'b','LineWidth',3);        
        axis equal;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 1. try edge collapse
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % try 3 positions to collapse: v1, v2, (v1+v2)/2
    testPts = [v1;v2;(v1+v2)/2];
    doCollapse = false;
    
    for j = 1: size(testPts,1)        
        testPt = testPts(j,:);

        % collapes v1 & v2 to be testPt and modify edgeIdx(1) only in verts
        verts(edgeIdx(1),:)=testPt;

        % copy the star part of the new tri
        newStarTri = tri (singleConnectIdx, :);

        % among singleConnectIdx, find tris that are connected to edgeIdx(2)
        newStarTri ( newStarTri == edgeIdx(2) ) = edgeIdx(1);

        if (DEBUG_COLLAPSE) 
            figure;
            hold on;
            trisurf(newStarTri,verts(:,1),verts(:,2),verts(:,3));
            alpha(0.4);
            axis equal;
        end

        % calculate the dihedral angle among the tris in the star, if exceeds
        % the threshold, continue
        ok = checkDihedralAngle(newStarTri,verts,MAX_ANGLE);

        if (~ok)
            % revert verts
            verts(edgeIdx(1),:)=v1;
            continue;
        end

        % project the edge points to the new star
        [projPts,dist] = ProjectPoints([v1;v2],newStarTri,verts);
        
        % calculate the engergy difference: E_Old - E_New
        EDif = GetEnergyDifferenceForCollapse( dist, starTri, newStarTri, verts );
        
        if ( EDif > 0 )
            % record the idx to collapse
            toDeleteIdx = [toDeleteIdx; doubleConnectIdx];
            doCollapse = true;
            break;
        end        
    end    
    continue;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2. try edge swap
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if (doCollapse)
        continue;
    end
    
    doSwap = false;
    
    newStarTri = tri (singleConnectIdx, :);
    
    doubleTri = tri (doubleConnectIdx, :);
    doubleTri1 = doubleTri(1,:);
    doubleTri2 = doubleTri(2,:);
    
    res1 = ismember(doubleTri1,edgeIdx);
    w1Idx = find(res1==0);
    w1 = doubleTri1(w1Idx);
    
    res2 = ismember(doubleTri2,edgeIdx);
    w2Idx = find(res2==0);
    w2 = doubleTri2(w2Idx);
    
    res = ismember(doubleTri1,edgeIdx(1));
    v1Idx = find(res==1);
    
    if ( v1Idx == 3 )
        % construct tri (v1,w1,w2)
        if (w1Idx==2)
            tri1 = [w2,w1,edgeIdx(1)];
            tri2 = [edgeIdx(2),w1,w2];
        else
            tri1 = [w1,w2,edgeIdx(1)];
            tri2 = [w1,edgeIdx(2),w2];
        end
    else
        if (w1Idx-v1Idx == 1)
            tri1 = [ edgeIdx(1), w1, w2 ];
            tri2 = [ w1, edgeIdx(2), w2 ];
        else
            tri1 = [ w1, edgeIdx(1), w2 ];
            tri2 = [ edgeIdx(2), w1, w2 ];
        end
    end
    
    newStarTri = [ newStarTri; tri1; tri2 ];
    
    if (DEBUG_SWAP)
        figure;
        hold on;

        % copy the start part of tris
        testTri = tri (doubleConnectIdx, :);        
        trisurf(testTri,verts(:,1),verts(:,2),verts(:,3),'LineWidth',2);
        
        testTri = tri (singleConnectIdx, :);        
        trisurf(testTri,verts(:,1),verts(:,2),verts(:,3));
        alpha(0.4);
        
        v = [v1;v2];
        plot3(v(:,1),v(:,2),v(:,3),'b','LineWidth',3);        
        axis equal;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        figure;
        hold on;

        trisurf(newStarTri,verts(:,1),verts(:,2),verts(:,3));
        alpha(0.4);
        
        axis equal;
    end
    
    % calculate the dihedral angle among the tris in the star, if exceeds
    % the threshold, continue
    ok = checkDihedralAngle(newStarTri,verts,MAX_ANGLE);

    if (ok)
        % calculate the engergy difference: E_Old - E_New
        EDif = GetEnergyDifferenceForSwap( edgeIdx, [w1,w2], verts );
        
        if ( EDif > 0 )
            % execute the swap
            newTri(doubleConnectIdx,:)=[];
            newTri = [ newTri; tri1; tri2 ];
            doSwap = true;
        end   
    end

    if (doSwap)
        continue;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 3. try edge split
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    midPt = (v1 + v2)/2;
    
    % add the mid point into verts
    verts = [verts; midPt];    
    midPtIdx = size(verts,1);
    
    if ( v1Idx == 3 )
        % construct tri (v1,w1,mid) & tri (v2,w1,mid)
        if (w1Idx==2)
            tri1 = [midPtIdx,w1,edgeIdx(1)];
            tri2 = [edgeIdx(2),w1,midPtIdx];
        else
            tri1 = [w1,midPtIdx,edgeIdx(1)];
            tri2 = [w1,edgeIdx(2),midPtIdx];
        end
    else
        if (w1Idx-v1Idx == 1)
            tri1 = [ edgeIdx(1), w1, midPtIdx ];
            tri2 = [ w1, edgeIdx(2), midPtIdx ];
        else
            tri1 = [ w1, edgeIdx(1), midPtIdx ];
            tri2 = [ edgeIdx(2), w1, midPtIdx ];
        end
    end
    
    res = ismember(doubleTri2,edgeIdx(1));
    v1Idx = find(res==1);
    
    if ( v1Idx == 3 )
        % construct tri (v1,w2,mid) & tri (v2,w2,mid)
        if (w2Idx==2)
            tri3 = [midPtIdx,w2,edgeIdx(1)];
            tri4 = [edgeIdx(2),w2,midPtIdx];
        else
            tri3 = [w2,midPtIdx,edgeIdx(1)];
            tri4 = [w2,edgeIdx(2),midPtIdx];
        end
    else
        if (w2Idx-v1Idx == 1)
            tri3 = [ edgeIdx(1), w2, midPtIdx ];
            tri4 = [ w2, edgeIdx(2), midPtIdx ];
        else
            tri3 = [ w2, edgeIdx(1), midPtIdx ];
            tri4 = [ edgeIdx(2), w2, midPtIdx ];
        end
    end
    
    newStarTri = [tri1;tri2;tri3;tri4];
    
    if ( DEBUG_SPLIT)
        figure;
        hold on;

        % copy the start part of tris
        testTri = tri (doubleConnectIdx, :);        
        trisurf(testTri,verts(:,1),verts(:,2),verts(:,3),'LineWidth',2);
        
        testTri = tri (singleConnectIdx, :);        
        trisurf(testTri,verts(:,1),verts(:,2),verts(:,3));
        alpha(0.4);
        
        v = [v1;v2];
        plot3(v(:,1),v(:,2),v(:,3),'b','LineWidth',3);        
        axis equal;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        figure;
        hold on;

        trisurf(testTri,verts(:,1),verts(:,2),verts(:,3));
        trisurf(newStarTri,verts(:,1),verts(:,2),verts(:,3));
        alpha(0.4);
        
        axis equal;
    end
    
    EDif = GetEnergyDifferenceForSplit( doubleTri, newStarTri, verts );
        
    if ( EDif > 0 )
        % execute the split
        newTri(doubleConnectIdx,:)=[];
        newTri = [ newTri; newStarTri ];
        doSwap = true;
    else
        verts(midPtIdx,:) = [];
    end 
end
newTri(unique(toDeleteIdx),:) = [];

if ( DEBUG_SHOW_RESULT )
    trisurf( newTri, verts(:,1), verts(:,2), verts(:,3) );                
    alpha(0.2);
    %shading interp;                   % other options are shading face / shading faceted
    shading faceted;
    
    colormap summer;
end