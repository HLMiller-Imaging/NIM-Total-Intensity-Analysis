function [Peaks, StDev]=FindOneCell2(CellOutputs)
%FINDONECELL2
%Plots KDE of fluorescence intensity per volumes for cells in a concatenated 
%output file. Finds the primary peak, and fits a Gaussian to it, constrained
%to have mean at the max value of KDE. FInds the standard deviation from the 
% Gaussian fit.
%
% INPUTS
% CellOutputs  - 12 column numeric array of outputs for one condition. e.g.
%                  DADE Sereds
%
% OUTPUTS
% Peaks - list of the found peak location for each repeat
% StDev - list of found standard Deviations from the Gaussian fit (check
% figure to see if sensible)
%
% Example code
% [Peaks, StDev]=FindOneCell2(BW25113dmscLSereds);
%
% Helen Miller June 2021

%% Loop through the repeats
for ii=1:max(CellOutputs(:,1))
    RepeatRows=find(CellOutputs(:,1)==ii);
    TempData=CellOutputs(RepeatRows,:);
    

% plot the data and use find peaks to find the tallest peak
figure;
MaxVal=max(TempData(:,12));
[dens1,x1]=ksdensity(TempData(:,12),0:MaxVal./100:MaxVal);
plot(x1,dens1,'k'); hold on
[peaks1,locs1]=findpeaks(dens1, 'SortStr','descend','NPeaks',1 ); %finds highest peak
OneCellPeak=x1(locs1(1));
close

% fit the tallest peak with a Gaussian and define a 1 sigma Gaussian
[xData, yData] = prepareCurveData(x1,dens1);
ft = fittype( 'gauss1' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Lower = [-Inf OneCellPeak 0];
opts.Upper=[Inf OneCellPeak Inf];
opts.StartPoint = [0.005 OneCellPeak 200];
[fitresult, ~] = fit( xData, yData, ft, opts );
Peaks(ii)=OneCellPeak;
StDev(ii)=fitresult.c1./sqrt(2);
%Threshold=fitresult.b1+fitresult.c1./sqrt(2); %this is 1 sigma limit with the Matlab Gaussian definition
%Xthresh=[Threshold; Threshold];
%Ythresh=[0; 1.1*peaks1(1)];

% Make a plot showing the threshold on the graph
figure( 'Name', 'Fluorescence per volume' );
h = plot( fitresult,'b', xData, yData,'k' ); hold on
%plot(Xthresh,Ythresh,'r'); %add line for the threshold
legend( 'Fluorescence Intensity per Volume for cells', 'Gaussian fit to peak','Location', 'NorthEast', 'Interpreter', 'none' );
xlabel( 'Fluorescence Intensity per volume', 'Interpreter', 'none' );
ylabel( 'Frequency density', 'Interpreter', 'none' );
titlestr=strcat('Repeat ', num2str(ii),'; peak at; ',num2str(OneCellPeak), ' Standard deviation of Gaussian fit; ' , num2str(StDev(ii)));
title(titlestr);
grid on

end
end
