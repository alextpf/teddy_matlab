% ============================================
% Author: Alex Chen
% email: alextpf@gmail.com
% 2014
% ============================================
function [ nextCenter, tip, tipIdx, tipSide, tipSideIdx, single, singleIdx ] = FindAdjTriangulation ( sleTriEdge, verts, curTri, selAdj, nbhrIdx )

edgeIdx = sleTriEdge ( selAdj, : );
tmpIdx = find ( edgeIdx == 1 ) + 1;

if ( tmpIdx > 3 )
    tmpIdx = 1;
end

edgeIdx ( tmpIdx ) = 1;

tipIdxTmp = edgeIdx & nbhrIdx;
tipSideIdxTmp = xor ( edgeIdx, tipIdxTmp );

tipIdx = curTri ( find ( tipIdxTmp == 1 ) );
tipSideIdx = curTri ( find ( tipSideIdxTmp == 1 ) );                
singleIdx = curTri ( find ( edgeIdx == 0 ) );

tip = verts ( tipIdx, : );
tipSide = verts ( tipSideIdx, : );
single = verts ( singleIdx, : );
nextCenter = ( tipSide + single ) / 2;

