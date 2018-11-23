function [center, curTri, v1v2Idx, nbhrIdx] = FindAdjTriCenter ( res, adjIdx, triType, verts )

nbhrIdx = res ( adjIdx, : );
v1v2Idx = find ( nbhrIdx ~= 0 );
curTri = triType ( adjIdx, : );

v1 = verts ( curTri ( v1v2Idx ( 1 ) ), : );
v2 = verts ( curTri ( v1v2Idx ( 2 ) ), : );

center = ( v1 + v2 ) / 2;