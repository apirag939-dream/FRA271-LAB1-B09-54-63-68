%% FRA271 Lab 1.3 - Incremental Encoder
% PPR Counting: X1, X2, X4
% BOURNS PEC11R-4220F-N0024

clear;
clc;
close all;

%% โหลดไฟล์
filePPR = fullfile("Encoder", ...
    "BOURNS PEC11R-4220F-N0024", ...
    "Find_PPR1.mat");

S = load(filePPR);
ds = S.data;

%% ดึงข้อมูล
sigX1 = ds.getElement("EncoderX1").Values;
sigX2 = ds.getElement("EncoderX2").Values;
sigX4 = ds.getElement("EncoderX4").Values;

t  = double(sigX1.Time);
X1 = double(squeeze(sigX1.Data));
X2 = double(squeeze(sigX2.Data));
X4 = double(squeeze(sigX4.Data));

%% ตัดช่วงที่ Encoder มีการหมุน
idx = find(diff(X4) ~= 0);

i1 = max(idx(1)-300,1);
i2 = min(idx(end)+500,length(t));

tPlot = t(i1:i2);
tPlot = tPlot - tPlot(1);

X1Plot = X1(i1:i2);
X2Plot = X2(i1:i2);
X4Plot = X4(i1:i2);

%% สี
blue   = [0.0000 0.4470 0.7410];
orange = [0.8500 0.3250 0.0980];
green  = [0.4660 0.6740 0.1880];

%% Plot
figure('Color','w','Position',[100 100 1100 650]);

stairs(tPlot,X1Plot,...
    'Color',blue,...
    'LineWidth',2);
hold on;

stairs(tPlot,X2Plot,...
    'Color',orange,...
    'LineWidth',2);

stairs(tPlot,X4Plot,...
    'Color',green,...
    'LineWidth',2);

%% ตั้งค่ากราฟ
ax = gca;
ax.Color = 'w';
ax.XColor = 'k';
ax.YColor = 'k';
ax.FontSize = 12;
ax.LineWidth = 1;
ax.GridColor = [0.8 0.8 0.8];
ax.GridAlpha = 0.5;

grid on;
box on;

xlabel('Time (s)','FontSize',13);
ylabel('Count','FontSize',13);

title('Comparison of Encoder Counting Modes X1, X2 and X4',...
    'FontSize',14,...
    'FontWeight','bold');

legend('X1','X2','X4',...
    'Location','northwest');

%% ใส่ค่าปลายกราฟ
text(tPlot(end),X1Plot(end),...
    sprintf('  X1 = %.0f',X1Plot(end)),...
    'Color',blue,...
    'FontSize',11,...
    'FontWeight','bold');

text(tPlot(end),X2Plot(end),...
    sprintf('  X2 = %.0f',X2Plot(end)),...
    'Color',orange,...
    'FontSize',11,...
    'FontWeight','bold');

text(tPlot(end),X4Plot(end),...
    sprintf('  X4 = %.0f',X4Plot(end)),...
    'Color',green,...
    'FontSize',11,...
    'FontWeight','bold');

xlim([tPlot(1) tPlot(end)+0.8]);
ylim([0 max(X4Plot)*1.10]);

%% Save
exportgraphics(gcf,...
    'BOURNS_PPR_X1_X2_X4.png',...
    'Resolution',300);