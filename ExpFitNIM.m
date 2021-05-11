function [fitparams,goodness]=ExpFitNIM(time,Intensity,bgfitresult,FitFigOutput)
%EXPFITNIM
%returns the fit parameters for a fit of the form 
%(1-b*exp(-PowerUp*x))*(A+D*exp(-E*x))
%to a time and intensity trace
%
%inputs 
%time       time values (frame numbers)
%Intensity  Intensity values
%bgfitresult   the results of the exponential fit to the background per
%pixel
% FitFigOutput switch -1 to output graph, 0 otherwise
%
%OUTPUTS
%fitparams  The values of the constants;
%           (1-b*exp(-PowerUp*x))*(A+D*exp(-E*x))
%           [fitresult.A fitresult.D fitresult.E fitresult.b fitresult.c]
%goodness   The r^2 values
%
% Helen Miller April 2021
 
[fitresult, gof] = createFitSam(time, Intensity, bgfitresult,FitFigOutput) ;   
fitparams(:)=[fitresult.A fitresult.D fitresult.E fitresult.b fitresult.c];
goodness(:)=gof.rsquare;
end

function [fitresult, gof] = createFitSam(time, xfit,bgfitresult,FitFigOutput) 
% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( time, xfit );

% Set up fittype and options.
ft = fittype( '(1-b*exp(-c*x))*(A+D*exp(-E*x))', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Lower = [0.5*bgfitresult.a 0 0 0.2*bgfitresult.b/bgfitresult.a bgfitresult.c];
%opts.StartPoint = [xfit(end) max(xfit)-xfit(end) 0.01 0.4 PowerUp];
opts.StartPoint = [bgfitresult.a 0 0.01 bgfitresult.b/bgfitresult.a bgfitresult.c];
if max(xfit)==xfit(end)
    lim=(max(xfit)-min(xfit));
else
    lim=3*(max(xfit)-xfit(end));
end
if max(xfit)>10^5
    factor=5;
else
    factor=2;
end
opts.Upper = [factor*bgfitresult.a lim 0.05 5*bgfitresult.b/bgfitresult.a bgfitresult.c];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

FlagLow=[fitresult.A  fitresult.D  fitresult.E  fitresult.b ]-opts.Lower(1:4);
FlagHi=opts.Upper(1:4)-[fitresult.A  fitresult.D  fitresult.E  fitresult.b ];
test1=find(FlagHi==0);
test2=find(FlagLow==0);
Test=vertcat(test1,test2);
if length(Test)>0
    disp('Error - Fitting has hit bounds');
    pause
    pause
    
end

% Create a figure for the plots.
if FitFigOutput==1
    figure( 'Name', 'Fitting' );
    % Plot fit with data.
    subplot( 2, 1, 1 );
    h = plot( fitresult, xData, yData );hold on
    plot(xData,(fitresult.A+fitresult.D*exp(-fitresult.E*xData)),'k');
    plot(xData,(fitresult.A*(1-(fitresult.b*exp(-fitresult.c*xData)))),'g');
    legend( 'Total cellular intensity vs. time', 'Full Fit','Fit of signal without laser turn on','laser turn on only', 'Location', 'NorthEast', 'Interpreter', 'none' );
    xlabel( 'Frame number', 'Interpreter', 'none' );ylabel( 'Total cellular intensity', 'Interpreter', 'none' ); % Label axes
    % Plot residuals.
    subplot( 2, 1, 2 );
    h = plot( fitresult, xData, yData, 'residuals' );
    legend( h, 'Residuals', 'Zero Line', 'Location', 'NorthEast', 'Interpreter', 'none' );
    xlabel( 'Frame number', 'Interpreter', 'none' ); ylabel( 'Total cellular intensity', 'Interpreter', 'none' );% Label axes
end
end