% CONCATOUTPUTS
% Script which opens all *.mat files in a folder with 'OUTPUTS' in the name 
% and concatenates them. The first column tells you which file they came
% from.
%
% Helen Miller April 2021

%Work out which folder you are in
OriginFolder = pwd;

%Find all the images in the folder you are in
TifFiles=dir('*OUTPUTS*');
NumberTifs=size(TifFiles); 

for ii=1:NumberTifs(1)  %Loop to analyse each file and save appropriate things
    
    Im_name=TifFiles(ii).name;
    FileName1 = Im_name(1:end-4); %this should give a single number
    FileName = Im_name(end-4:end-4); %this should give a single number
    load(FileName1,'Output');

    FileCol=str2double(FileName)*ones(length(Output(:,1)),1);
    if ii==1
        AllOutput=horzcat(FileCol,Output);
    else
        AllOutput=vertcat(AllOutput,horzcat(FileCol,Output));
    end
    
    clear Output FileCol
end

save('AllOutput.mat','AllOutput')
