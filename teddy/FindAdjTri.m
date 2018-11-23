function [adj,res] = FindAdjTri ( curTri, TriList)
res = ismember ( TriList, curTri );
sumRes = sum ( res, 2 );
adj = find ( sumRes == 2 );