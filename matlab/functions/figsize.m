%% code for TF-SPES figures
% author: Michelle van der Stoel
% date: Sep2017-Sep2018

set(gcf,'PaperUnits','centimeters')
%This sets the units of the current figure (gcf = get current figure) on paper to centimeters.

xSize = 14; ySize = 12;
%These are my size variables, width of 8 and a height of 12, will be used a lot later.

xLeft =0;%(21-xSize)/2; 
yTop =0;%(30-ySize)/2;
%Additional coordinates to center the figure on A4-paper

set(gcf,'PaperPosition',[xLeft yTop xSize ySize]);
set(gcf, 'PaperSize', [xSize ySize]);
%This command sets the position and size of the figure on the paper to the desired values.

set(gcf,'Position',[300 300 xSize*50 ySize*50]);