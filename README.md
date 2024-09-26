# Teddy - Matlab
This repo implements Dr. Igarashi's ["Teddy"](https://www-ui.is.s.u-tokyo.ac.jp/~takeo/teddy/teddy.htm) published in SIGGRAPH 1999, by Maltab. However, it only implements the "inflation" feature, without other functionalities. That is, the input has to be a single closed contour with "sphere topololy".

## How To Run
1. If you have Matlab installed on your pc: under the "teddy" directory, one can either:
  - Run the script `teddy.m`. Read the script to modify the flags, for example, whether to hand draw the contour, or to feed in a binary image with pre-drawn contour.
  - Run the app `teddy_app.mlapp` to run the app with an UI.
2. If you don't have Matlab: 
  - Under ["teddy/Teddy_matlab/for_redistribution" folder](https://github.com/alextpf/teddy_matlab/tree/master/teddy/Teddy_matlab/for_redistribution), there's a MyAppInstaller_web.exe. If you already cloned the repos, you should have it under your local folder, but if you don't know how to clone the repos, simply [download the exe](https://github.com/alextpf/teddy_matlab/blob/master/teddy/Teddy_matlab/for_redistribution/MyAppInstaller_web.exe) from github website. 
  - Execute the exe by double clicking on it.
  - It will download the necessary contents from Matlab website (Matlab Runtime), which will take some time (a few hundred MB).
  - Once the contents has been downloaded and installed, you can then run the executable.
  - Currently, only Windows is supported.

## Functionalities
This software implements the "inflation" of a single closed contour from 2D to 3D model, from Dr. Igarashi's algorithm. It has 3 steps:
1. Sketch
2. Generate 3D model
3. Export *.stl (for 3D print)


### Sketch 
The sketch step has 3 modes:
1. Plain sketch:
  - it allows the user to draw a closed contour on a blank canvas freely.
  - The user can press the left mouse button, and move the mouse, and the program will trace and draw the path the mouse undergoes.
  - Once the left mouse button is released, it automatically closes the contour by connecting the last point before the button is released and the initial point.
  - Once the contour is drawn, several "waypoints" are automatically generated. The user may manually drag and move those waypoints to change the shape of the contour. The user may as well add extra waypoints by right-clicking when the cursor is on the contour.
2. Load an overlay image and sketch:
  - The user can choose to load an image as the background, and then sketch on top of the background image. The sketch process is the same as the "Plain sketch" mode, and the background image assists the user in tracing the feature/outline of the image.
3. Load a "binary" image:
  - The user may prepare a "binary" (i.e. black and white) image by using other image editing software (e.g. GIMP, Photoshop...etc).
  - The binary image has to have black content and a white background.

### Generate 3D Model
This button generates the 3D model from the sketch or the binary image.

### Export STL
This button exports the generated 3D model to a *.stl file, for 3D printing purposes.