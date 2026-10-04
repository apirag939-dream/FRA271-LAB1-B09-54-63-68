%% FRA271 Lab 1.3 - Effect of Rotational Speed
% BOURNS + AMT103-V

clear;
clc;
close all;

%% =========================================================
% FILE NAMES
% ==========================================================

% BOURNS
fileBournsSlow = 'slow90bourns.mat';   % แก้ให้ตรงไฟล์จริง
fileBournsFast = 'fast90bourns.mat';   % แก้ให้ตรงไฟล์จริง

% AMT
fileAmtSlow = 'slow90amt.mat';
fileAmtFast = 'fast90amt.mat';

%% Counts per revolution ใน Mode X4
countsPerRev_BOURNS = 96;
countsPerRev_AMT    = 8192;

% Counter ของชุดข้อมูลที่เก็บ
wrapMax = 65536;

%% Colors
cVel = [0.0000 0.4470 0.7410];
cAng = [0.8500 0.3250 0.0980];
cRel = [0.4660 0.6740 0.1880];

%% Process
[t_bs,rel_bs,ang_bs,vel_bs] = processSpeedFile(...
    fileBournsSlow,...
    countsPerRev_BOURNS,...
    wrapMax);

[t_bf,rel_bf,ang_bf,vel_bf] = processSpeedFile(...
    fileBournsFast,...
    countsPerRev_BOURNS,...
    wrapMax);

[t_as,rel_as,ang_as,vel_as] = processSpeedFile(...
    fileAmtSlow,...
    countsPerRev_AMT,...
    wrapMax);

[t_af,rel_af,ang_af,vel_af] = processSpeedFile(...
    fileAmtFast,...
    countsPerRev_AMT,...
    wrapMax);

%% Plot
figure('Color','w','Position',[100 100 1450 850]);

tiledlayout(2,2,...
    'TileSpacing','compact',...
    'Padding','compact');

%% BOURNS Slow
nexttile;

plot(t_bs,vel_bs,...
    'Color',cVel,...
    'LineWidth',1.2);
hold on;

plot(t_bs,ang_bs,...
    'Color',cAng,...
    'LineWidth',1.8);

plot(t_bs,rel_bs,...
    'Color',cRel,...
    'LineWidth',1.8);

styleAxes(gca);

title('PEC11R-4220F-N0024 - Slow Rotation',...
    'FontWeight','bold');

ylabel('Value');

legend('Angular Velocity (rad/s)',...
       'Angular Position (rad)',...
       'Relative Position (pulses)',...
       'Location','best');

%% BOURNS Fast
nexttile;

plot(t_bf,vel_bf,...
    'Color',cVel,...
    'LineWidth',1.2);
hold on;

plot(t_bf,ang_bf,...
    'Color',cAng,...
    'LineWidth',1.8);

plot(t_bf,rel_bf,...
    'Color',cRel,...
    'LineWidth',1.8);

styleAxes(gca);

title('PEC11R-4220F-N0024 - Fast Rotation',...
    'FontWeight','bold');

ylabel('Value');

legend('Angular Velocity (rad/s)',...
       'Angular Position (rad)',...
       'Relative Position (pulses)',...
       'Location','best');

%% AMT Slow
nexttile;

plot(t_as,vel_as,...
    'Color',cVel,...
    'LineWidth',1.2);
hold on;

plot(t_as,ang_as,...
    'Color',cAng,...
    'LineWidth',1.8);

plot(t_as,rel_as,...
    'Color',cRel,...
    'LineWidth',1.8);

styleAxes(gca);

title('AMT103-V - Slow Rotation',...
    'FontWeight','bold');

xlabel('Time (s)');
ylabel('Value');

legend('Angular Velocity (rad/s)',...
       'Angular Position (rad)',...
       'Relative Position (pulses)',...
       'Location','best');

%% AMT Fast
nexttile;

plot(t_af,vel_af,...
    'Color',cVel,...
    'LineWidth',1.2);
hold on;

plot(t_af,ang_af,...
    'Color',cAng,...
    'LineWidth',1.8);

plot(t_af,rel_af,...
    'Color',cRel,...
    'LineWidth',1.8);

styleAxes(gca);

title('AMT103-V - Fast Rotation',...
    'FontWeight','bold');

xlabel('Time (s)');
ylabel('Value');

legend('Angular Velocity (rad/s)',...
       'Angular Position (rad)',...
       'Relative Position (pulses)',...
       'Location','best');

sgtitle('Effect of Rotational Speed on Encoder Output',...
    'FontSize',14,...
    'FontWeight','bold');

exportgraphics(gcf,...
    'Encoder_Speed_Comparison_4Plots.png',...
    'Resolution',300);

%% =========================================================
% PROCESS FILE
% ==========================================================

function [tPlot,relCount,angleRad,omega] = ...
    processSpeedFile(fileName,countsPerRev,wrapMax)

S = load(fileName);
ds = S.data;

sig = ds.getElement("EncoderX4").Values;

t   = double(sig.Time);
raw = double(squeeze(sig.Data));

%% Unwrap
count = unwrapCounter(raw,wrapMax);

%% Relative Count
relCount = count-count(1);

%% Angular Position
angleRad = relCount*(2*pi/countsPerRev);

%% Angular Velocity
omega = gradient(angleRad,t);

if length(omega)>15
    omega = movmean(omega,15);
end

%% ตัดเฉพาะช่วงมีการเคลื่อนที่
idxMove = find(abs(diff(relCount))>0);

if isempty(idxMove)

    i1 = 1;
    i2 = length(t);

else

    pad = 800;

    i1 = max(idxMove(1)-pad,1);
    i2 = min(idxMove(end)+pad,length(t));

end

tPlot = t(i1:i2)-t(i1);

relCount = relCount(i1:i2);
angleRad = angleRad(i1:i2);
omega    = omega(i1:i2);

end

%% =========================================================
% UNWRAP COUNTER
% ==========================================================

function y = unwrapCounter(raw,wrapMax)

halfWrap = wrapMax/2;

y = zeros(size(raw));
y(1) = raw(1);

offset = 0;

for k = 2:length(raw)

    diffVal = raw(k)-raw(k-1);

    if diffVal < -halfWrap

        offset = offset+wrapMax;

    elseif diffVal > halfWrap

        offset = offset-wrapMax;

    end

    y(k) = raw(k)+offset;

end

end

%% =========================================================
% STYLE
% ==========================================================

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