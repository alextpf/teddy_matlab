# Teddy - Matlab
This repo implements Dr. Igarashi's ["Teddy"](https://www-ui.is.s.u-tokyo.ac.jp/~takeo/teddy/teddy.htm) published in SIGGRAPH 1999, by Maltab. However, it only implements the "inflation" feature, without other functionalities. That is, the input has to be a single closed contour with "sphere topololy".

## How To Run
1. If you have Matlab installed on your pc: under the "teddy" directory, one can either:
  - Run the script `teddy.m`. Read the script to modify the flags, for example, whether to hand draw the contour, or to feed in a binary image with pre-drawn contour.
  - Run the app `teddy_app.mlapp` to run the app with an UI.
2. If you don't have Matlab: 
  - Under executable folder, download teddy_app.exe and execute it (double click).
  - It will download the necessary contents from Matlab website (Matlab Runtime), which will take some time (a few hundred MB).
  - Once the contents has been downloaded and installed, you can then run the executable.
  - Currently, only Windows is supported.

## Functionalities
This software implements the "inflation" of a single closed contour from 2D to 3D model, from Dr. Igarashi's algorithm. It has 3 steps:
1. Sketch
2. Generate 3D model
3. Export *.stl (for 3D print)

### Sketch 
Te sketch step has 3 modes: 
1. Plain sketch: 
  - it allows the user to freely draw a closed contour on a blank canvas. 
  - The user can use press the left mouse button, move the mouse, and the program will trace and draw the path the mouse undergoes. 
  - Once the left mouse button is released, it automatically close the contour by connecting the last point before the button is release and the initial point.
  - Once the contour is drawn, several "way points" are automatically generated. The user may manually drag and move those way points to change the shape of the contour. The user may as well add extra way points by right click when the cursor is on the contour.
2. Load an overlay image and sketch:
  - The user can choose to load an image as the background, and then sketch on top of the background image. The sketch process is exactly the same as the "Plain sketch" mode, and the background image is to assist the user to trace the feature/outline of the image.
3. Load a "binary" image: 
 - The user may prepare a "binary" (i.e. black and white, with black content and white background) image by usi other image editing so 
### Generate 3D Model
This button generate the 3D model from the scratch or the binary image. 
   


