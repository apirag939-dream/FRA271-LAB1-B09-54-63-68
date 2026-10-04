%% FRA271 Lab 1.3 - Incremental Encoder
% Phase Relationship and CW/CCW
% BOURNS PEC11R-4220F-N0024

clear;
clc;
close all;

%% โหลดไฟล์
fileAB = fullfile("Encoder", ...
    "BOURNS PEC11R-4220F-N0024", ...
    "RelationAB_90deg_cw-ccw_slow 1.mat");

S = load(fileAB);
ds = S.data;

%% ดึงข้อมูล
sigA  = ds.getElement("Gain 1:1").Values;
sigB  = ds.getElement("Gain 2:1").Values;
sigX4 = ds.getElement("EncoderX4").Values;

t  = double(sigA.Time);
A  = double(squeeze(sigA.Data));
B  = double(squeeze(sigB.Data));
X4 = double(squeeze(sigX4.Data));

%% แปลง A/B เป็น Logic 0/1
A = A > 0.5;
B = B > 0.5;

%% แยก CW และ CCW จากทิศทาง Count
dX4 = diff(X4);

idxCW  = find(dX4 > 0);
idxCCW = find(dX4 < 0);

%% เลือกช่วงกลาง
cwCenter  = idxCW(round(length(idxCW)/2));
ccwCenter = idxCCW(round(length(idxCCW)/2));

% ช่วงประมาณ 6 วินาที
window = 3000;

cw1  = max(cwCenter-window,1);
cw2  = min(cwCenter+window,length(t));

ccw1 = max(ccwCenter-window,1);
ccw2 = min(ccwCenter+window,length(t));

%% เตรียมข้อมูล
tCW  = t(cw1:cw2);
tCCW = t(ccw1:ccw2);

tCW  = tCW  - tCW(1);
tCCW = tCCW - tCCW(1);

ACW  = A(cw1:cw2);
BCW  = B(cw1:cw2);

ACCW = A(ccw1:ccw2);
BCCW = B(ccw1:ccw2);

%% สี
redA  = [0.8500 0.3250 0.0980];
blueB = [0.0000 0.4470 0.7410];

%% Plot
figure('Color','w','Position',[100 100 1200 700]);

tiledlayout(2,2,...
    'TileSpacing','compact',...
    'Padding','compact');

%% CW Channel A
nexttile(1);

stairs(tCW,ACW,...
    'Color',redA,...
    'LineWidth',2);

styleAxes(gca);

ylim([-0.2 1.2]);
yticks([0 1]);

title('CW','FontWeight','bold');
ylabel('Channel A');

%% CCW Channel A
nexttile(2);

stairs(tCCW,ACCW,...
    'Color',redA,...
    'LineWidth',2);

styleAxes(gca);

ylim([-0.2 1.2]);
yticks([0 1]);

title('CCW','FontWeight','bold');
ylabel('Channel A');

%% CW Channel B
nexttile(3);

stairs(tCW,BCW,...
    'Color',blueB,...
    'LineWidth',2);

styleAxes(gca);

ylim([-0.2 1.2]);
yticks([0 1]);

xlabel('Time (s)');
ylabel('Channel B');

%% CCW Channel B
nexttile(4);

stairs(tCCW,BCCW,...
    'Color',blueB,...
    'LineWidth',2);

styleAxes(gca);

ylim([-0.2 1.2]);
yticks([0 1]);

xlabel('Time (s)');
ylabel('Channel B');

sgtitle('Phase Relationship of Channel A and B for CW and CCW',...
    'FontSize',14,...
    'FontWeight','bold');

%% Save
exportgraphics(gcf,...
    'BOURNS_Phase_CW_CCW.png',...
    'Resolution',300);

%% ฟังก์ชันจัดหน้ากราฟ
function styleAxes(ax)

ax.Color = 'w';
ax.XColor = 'k';
ax.YColor = 'k';
ax.FontSize = 11;
ax.LineWidth = 1;
ax.GridColor = [0.8 0.8 0.8];
ax.GridAlpha = 0.5;

grid(ax,'on');
box(ax,'on');

end