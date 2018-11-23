function sameOrder = CheckOrder ( testTri, srcTri )
res = ismember(srcTri,testTri(1));
idx = find(res == 1);

sameOrder = true;
for i = 2:3
    srcIdx = idx + i - 1;
    if ( srcIdx > 3)
        srcIdx = srcIdx - 3;
    end
    if ( testTri(i) ~= srcTri(srcIdx) )
        sameOrder = false;
        break;
    end
end