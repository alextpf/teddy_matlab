% ============================================
% Author: Alex Chen
% email: alextpf@gmail.com
% 2014
% ============================================
function verts = TraceBdry(fileName)
% ==================================
% pre-requisite: input image has to be a black and white image, and single channel ( not rbg )
% with foreground black, background white. If foreground is white, background balck, simply change the line 15 &16
% ==================================
% Threshold and invert
img = imread(fileName);
if (size(img,3) ~= 1)
    img = img(:,:,1);
end

tmp = img;

tmp(find(img > 20 ))=0;
tmp(find(img <= 20 ))=255;
img = tmp;

% figure;
% imshow(img);

% ==================================
% trace bdry
B = bwboundaries(img);
verts = B{1};

% ==================================
% normalize
maxXY= max(verts(:));

verts = verts./maxXY;
verts = [verts(:,2),verts(:,1)]; 

% //==== debug =================//
% for i = 1: size(verts,1)
%  plot(verts(i,2), verts(i,1), '.b', 'LineWidth', 2);
%  hold on;
% end
% //==== debug =================//

% ==================================
% down-sample
DOWN_RATE = 2;

tmp = verts(1:DOWN_RATE:end,:);

verts=[];

% //==== debug =================//
% figure;
% for i = 1: size(tmp,1)
%  plot(tmp(i,2), tmp(i,1), '.b', 'LineWidth', 2);
%  hold on;
%  pause(0.01);
% end
% figure;
% plot(tmp(:,2), tmp(:,1), '.r', 'LineWidth', 2); hold on;
% plot(tmp(:,2), tmp(:,1), 'b', 'LineWidth', 1);
% //==== debug =================//

% ==================================
% sample vertex
ERR = 0.01;
LEN_SQR = ERR * ERR;
USE_ANGLE = false;

num = size(tmp,1);


if (USE_ANGLE)
    
    angleThresh = cos(40 * 3.1415926 / 180);

    prev = tmp(num,:);
    for i = 1: num - 1

        curr = tmp(i,:);
        next = tmp(i+1,:);

        vec1 = curr - prev;
        vec2 = next - curr;

        len1 = sqrt(sum(vec1.^2));
        len2 = sqrt(sum(vec2.^2));

        vec1 = vec1 / len1;
        vec2 = vec2 / len2;

        cosVec = sum( vec1 .* vec2 );

        p2 = tmp(i,:);
        dif = p2 - p1;
        err = sum(dif.^2);
        if ( cosVec < angleThresh || err > LEN_SQR)
            % keep
            verts = [verts;p2];
            p1 = p2;
        end

        prev = curr;   
    end
else
    
    p1 =tmp(1,:);
    for i = 2: num
        p2 = tmp(i,:);
        dif = p2 - p1;
        err = sum(dif.^2);
        if ( err > LEN_SQR)
            % keep
            verts = [verts;p2];
            p1 = p2;
        end
    end
end

verts=[verts;verts(1,:)];
% 
% //==== debug =================//
% figure;
% plot(verts(:,2), verts(:,1), '.r', 'LineWidth', 2); hold on;
% plot(verts(:,2), verts(:,1), 'b', 'LineWidth', 1);
% //==== debug =================//
