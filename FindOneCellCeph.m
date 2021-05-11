function [Threshold]=FindOneCellCeph(CellAreas)
%FINDONECELL
%Plots KDE of cell areas in a concatenated output file. Finds the primary
%peak, and fits a Gaussian to it, constrained to have mean at the max value
%of KDE. Sets a threshold area 1 sigma from the gaussian peak as the limit
%on single cell size. Returns the threshold. This version has bigger area
%limits for cephalexin treated cells.
%
% INPUTS
% CellAreas  - column vector of cell areas to find a threshold in
%
% OUTPUTS
% Threshold - A scalar; max area of a cell that is attributable to a
%                    single cell
%
% Example code
% [CephS_OneCellThreshold]=FindOneCellCeph(Ceph_S(:,8));
%
% Helen Miller April 2021

%% plot the data and use find peaks to find the tallest peak
figure; 
[dens1,x1]=ksdensity(CellAreas,0:5:1800);
plot(x1,dens1,'k'); hold on
[peaks1,locs1]=findpeaks(dens1);
OneCellPeak=x1(locs1(1));
close

%% fit the tallest peak with a Gaussian and define a 2 sigma Gaussian
[xData, yData] = prepareCurveData(x1,dens1);
ft = fittype( 'gauss1' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Lower = [-Inf OneCellPeak 0];
opts.Upper=[Inf OneCellPeak Inf];
opts.StartPoint = [0.005 OneCellPeak 300];
[fitresult, ~] = fit( xData, yData, ft, opts );
Threshold=fitresult.b1+fitresult.c1./sqrt(2); %this is 1 sigma limit (95%) with the Matlab Gaussian definition
Xthresh=[Threshold; Threshold];
Ythresh=[0; 1.1*peaks1(1)];

%% Make a plot showing the threshold on the graph
figure( 'Name', 'Cell Area Threshold' );
h = plot( fitresult,'b', xData, yData,'k' ); hold on
plot(Xthresh,Ythresh,'r'); %add line for the threshold
legend( 'Cell Areas', 'Gaussian fit to peak', 'One cell threshold','Location', 'NorthEast', 'Interpreter', 'none' );
xlabel( 'Cell Area (pixels)', 'Interpreter', 'none' );
ylabel( 'Frequency density', 'Interpreter', 'none' );
grid on

end
