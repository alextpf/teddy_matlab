% ============================================
% Author: Alex Chen
% email: alextpf@gmail.com
% 2014
% ============================================
function drawCircle ( center, v )
    hold on; % draw on the current figure
    pi = 3.1415926;
    N = 16;
    
    dif = v - center;
    r = sqrt ( sum ( dif.^2 ) );
    
    theta1 = 0:2*pi/N:2*pi;
    
    x1 = r * cos ( theta1 ) + center(1);
    y1 = r * sin ( theta1 ) + center(2);
    
    plot (x1,y1,'g');
end
