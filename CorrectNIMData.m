function []=CorrectNIMData(Input,imfile,FitFigOutput)
%CorrectNIMData
%Takes in .csv files from microbeJ and corrects the bg for laser turn
%on as it is collected on the NanoImager (ONI).
%
% INPUTS
% INPUT  - 8 column microbeJ output files with columns 1)Image.name	
%          2)Mean.intensity	3) Corrected.mean.intensity	4)Frame	5)Cell.area	
%          6)Cell.length	7)Mean.cell.width	8)Cell.ID
% IMFILE - string to indentify the fluorescence image the MicrobeJ output 
%          goes with
% FITFIGOUTPUT - switch to save individual frame fits
%
% No outputs to workspace, everything is saved to the current folder. 
% Saved output columns are :
% (1-b*exp(-PowerUp*x))*(A+D*exp(-E*x)) fitted function, fit params:
% 1) fitresult.A 2) fitresult.D 3) fitresult.E 4)fitresult.b 
% 5)fitresult.c 6)cell area 7) cell length 8)cell width 9) volume 10)
% FLuorescence counts per volume.
% SECOND COLUMN IS CORRECTED INITIAL INTENSITY ABOVE BACKGROUND = PARAMETER
% OF INTEREST.
% 
% EXAMPLE CODE
% CorrectSamsData(F5,'f5',1)
%
% Helen Miller April 2021

sizeRect=40; %dimension of rectangle used to analyse background

close all %get rid of any open figures
    
OriginFolder = pwd;
TiffString=strcat('*',imfile,'*.tif');
TifFiles=dir(TiffString);
    
Im_name=TifFiles.name;
FileName = Im_name(1:end-4);
    
%create a folder to put the analysis into
mkdir(FileName);
cd(FileName);
Outputfolderpath=pwd;
cd(OriginFolder);
    
%extract all the images from the .tif
[~, ~,~, image_data, ~] = ExtractImageSequence4(FileName, 1, 1, 250);
%make the time variable for fitting
time=1:1:length(image_data(1,1,:));
smoothMax=image_data(:,:,1);    
% 1. Identify the bg on the image
disp('Please identify a background region to use, press any key once selected');
figure; imshow(smoothMax,[min(min(smoothMax)) max(max(smoothMax))/100]);title('Smoothed maximum projection, high contrast');
roi = drawrectangle('Position',[0,0,sizeRect,sizeRect],'StripeColor','r');
pause
disp('Background selected');
BGpos=floor(roi.Position); % this defines xmin ymin xsize ysize
BGVert=roi.Vertices;
%now make the pixel list for this area
Listbg=zeros(sizeRect*sizeRect,2);
counter=1;
for iip=1:sizeRect
   for iiq=1:sizeRect 
        Listbg(counter,:)=[BGpos(1,1)+iip,BGpos(1,2)+iiq];
        counter=counter+1;
   end
end
clear counter
%find the intensity for these pixels
for pp=1:length(Listbg) %find the values of the pixels in each frame
    t2(pp,:)=image_data(Listbg(pp,2),Listbg(pp,1),:); %flip of axes for picture representation
end
bgIpF=sum(t2,1); %this is the total I for the bg in each frame
Avbg=bgIpF./(sizeRect*sizeRect);

%plot things to do with the background
figure;
subplot(1,2,1); histogram(t2(:,1),256); title('Histogram of background intensity values in first frame');xlabel('Intensity value');ylabel('Frequency');
subplot(1,2,2); scatter(time, Avbg); xlabel('Frame number');ylabel('Average bg intensity per pixel');
pause
% now fit this curve to determine the laser power up time 
[fitresultbg, gofbg] = ExpOnFit(time, Avbg);
%y=a-b*exp(-c*time)

PowerUp=fitresultbg.c; %this is the value of the exponential -fit this

%4. Get the laser turn-on corrected intensity profile for each cell and
%total intensity
%fit the decay for each cell's intensity trace
%initialise the output variable
Output=zeros(max(Input(:,8)),10);
for ki=1:max(Input(:,8)) %looping over the cells
    rowscell=find(Input(:,8)==ki);
    IpF(ki,:)=Input(rowscell,2).*Input(rowscell,5); %this is the total I for the cell in each frame
    fitresulttemp.c=fitresultbg.c;
    fitresulttemp.a=fitresultbg.a*Input(rowscell(1),5); %(multiply fit results by area of cell in pixels for use as start values for data fitting)
    fitresulttemp.b=fitresultbg.b*Input(rowscell(1),5); %(multiply fit results by area of cell in pixels for use as start values for data fitting)
    [fitparams(ki,:),goodness(ki)]=ExpFitNIM(time,IpF(ki,:),fitresulttemp,FitFigOutput);
%   (1-b*exp(-PowerUp*x))*(A+D*exp(-E*x)) fitted function, fit params:
%   [fitresult.A fitresult.D fitresult.E fitresult.b fitresult.c]
    Volume=(pi/12)*(Input(rowscell(1),7).^2).*((3*Input(rowscell(1),6))-Input(rowscell(1),7));
    IperV=fitparams(ki,2)./Volume;
    Output(ki,:)=horzcat(fitparams(ki,:), Input(rowscell(1),5),Input(rowscell(1),6),Input(rowscell(1),7), Volume, IperV);
    % first 5 columns are fit parms, 6= cell area, 7 cell length, 8 cell
    % width,9 volume, 10 IperV
    clear List  Volume IperV fitresulttemp
end

rowFlag=find(Output(:,3)==0.5);
if length(rowFlag)>0
    disp('RowFlag triggered - at least one fit has hit the bound on fluorescence decay time')
end
% go into the analysis folder and save things:
cd(FileName)
    FigList = findobj(allchild(0), 'flat', 'Type', 'figure');
    for iFig = 1:length(FigList)
      FigHandle = FigList(iFig);
      FigName   = get(FigHandle, 'Number');
      figfilename1=strcat(Outputfolderpath, '\',FileName,'_Figure',num2str(FigName),'.fig');
      pngfilename1=strcat(Outputfolderpath, '\',FileName,'_Figure', num2str(FigName),'.png');
     % savefig(FigHandle,figfilename1);
      saveas(FigHandle,pngfilename1);
    end
close all
datafilename=strcat(Outputfolderpath, '\', 'OUTPUTS_',FileName,'.mat');
save(datafilename,'image_data','fitparams','goodness','fitresultbg', 'gofbg','PowerUp','IpF','Listbg','Avbg','fitresultbg','Output');
cd(OriginFolder) %save the output in the original folder for ease too
datafilename2=strcat(OriginFolder, '\', 'OUTPUTS_',FileName,'.mat');
save(datafilename2,'image_data','fitparams','goodness','fitresultbg', 'gofbg','PowerUp','IpF','Listbg','Avbg','fitresultbg','Output');
clear image_data stats fitparams goodness PowerUp IpF Listbg Avbg fitresultbg gofbg

end