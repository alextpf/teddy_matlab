function [ avgLen, vecLen ] = getAvgLength ( curIdx, outerIdx, verts )
pivot = verts ( curIdx, 1:2 );
outers = verts ( outerIdx, 1:2 );

numOuters = size ( outers, 1 );

pivots = ones ( numOuters, 1 );
pivots = pivots * pivot;
SqrtDif = pivots - outers;
SqrtDif = SqrtDif.^2;
vecLen = sqrt ( sum (SqrtDif, 2) );
avgLen = sum ( vecLen );
avgLen = avgLen / numOuters;
