function [numFrames, frame_Ysize, frame_Xsize, image_data, image_path] = ExtractImageSequence4(image_label, all, startFrame, endFrame)
% EXTRACTIMAGESEQUENCE4
% A function that extracts multipage tifs and outputs an array 
% Based on a function from Adam Wollman's code (ADEMS code) to extract
% multipage tifs, but simpler.
%
% INPUTS
% image_label    string for image to load
% all            switch; 1 =whole image is loaded, else loads from optional 
%                startFrame to endFrame
% startFrame     if all isn't set to one, this is the first frame loaded
% endFrame       if all isn't set to one, this is the last frame loaded 
% image_label is the number before the file extension of the tif
%
% OUTPUTS
% numFrames      the number of frames loaded
% frame_Ysize    The number of pixels on the y axis
% frame_Xsize    The number of pixels on the x axis
% image_data     The array of image files; image_data(:,:,1) is the first
%                frame
% image_path     The file path to the image
%
% EXAMPLE CODE
% To load an entire tif image called test.tif that is in the working folder
% and only retain the image as an array called image_data
% [~, ~, ~, image_data, image_path] = ExtractImageSequence4('test', 1, 0, 0)
% To load only frame 9 of test.tif
% [~, ~, ~, image_data, image_path] = ExtractImageSequence4('test', 0, 9, 9)
%
% Helen Miller

filePath=dir(strcat('*',image_label,'.tif'));
filePath.name
tifImagePath0 = dir(strcat(image_label,'.tif'));
% Error control - no .tif found
if isempty(tifImagePath0) % If there is no .tif image sequence file for such image_label, show error and exit function:
    error('Check you are in the correct directory and retry. The image file was not found.');
end
%otherwise:
image_path = tifImagePath0.name;
InfoImage=imfinfo(image_path);
frame_Ysize=InfoImage(1).Width;
frame_Xsize=InfoImage(1).Height;
numFrames=length(InfoImage);
if all==0 %extract only certain frames
    image_data=zeros(frame_Xsize,frame_Ysize,endFrame-startFrame+1,'uint16');
    for i=1:endFrame-startFrame+1
        image_data(:,:,i)=imread(image_path,i+startFrame-1);
    end
else %extract all the frames
    image_data=zeros(frame_Xsize,frame_Ysize,numFrames,'uint16');
    for i=1:numFrames
        image_data(:,:,i)=imread(image_path,i);
    end
end
end