function [verts, figHangle] = FreeHandDrawing (  )

  
figHangle = figure('units','normalized','outerposition',[0 0 1 1]); % maximize the figure
axis equal;

h = imfreehand(gca);

pos = getPosition(h);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract region
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ERR = 0.02;
LEN_SQR = ERR * ERR;

verts = pos(1,:);
p1 = pos(1,:);

for i = 2:size(pos,1)
    p2 = pos(i,:);
    dif = p2 - p1;
    if (sum(dif.^2) > LEN_SQR )
        verts = [verts;p2];
        p1 = p2;
    end    
end

verts=[verts;verts(1,:)];
% 
% x = verts(:,1);
% y = verts(:,2);

% plot(x,y);
% axis equal;
% 
