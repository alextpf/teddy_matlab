function c = GetCenter ( curTri, verts )

v1 = verts ( curTri (1), : );
v2 = verts ( curTri (2), : );
v3 = verts ( curTri (3), : );

c = ( v1 + v2 + v3 ) / 3;