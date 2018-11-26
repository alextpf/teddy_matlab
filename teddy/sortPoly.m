% ============================================
% Author: Alex Chen
% email: alextpf@gmail.com
% 2014
% ============================================
function poly = sortPoly ( poly )

poly = sort ( poly );

poly1 = poly(2:end);
poly2 = poly(1:end-1);

breakPoint = find ( poly1-poly2 ~= 1 );

if ( ~isempty (breakPoint) )
    poly1 = poly ( 1:breakPoint );
    poly2 = poly ( breakPoint+1:end );
    poly = [poly2;poly1];
end

end

