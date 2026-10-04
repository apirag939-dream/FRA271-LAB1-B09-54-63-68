%% FRA271 Lab 1.3 - Homing / Reset Observation
% AMT103-V

clear;
clc;
close all;

%% Load
fileName = "C:\LAB1\Encoder\AMT103-V\wh.mat";

S = load(fileName);
ds0 = S.data;

%% หา Dataset
ds = findEncoderDataset(ds0);

disp("Signals found:");
disp(getElementNames(ds));

%% Read Signals
sigX1 = getElement(ds,"EncoderX1").Values;
sigX2 = getElement(ds,"EncoderX2").Values;
sigX4 = getElement(ds,"EncoderX4").Values;

t = double(sigX1.Time(:));

X1 = double(squeeze(sigX1.Data));
X2 = double(squeeze(sigX2.Data));
X4 = double(squeeze(sigX4.Data));

X1 = X1(:);
X2 = X2(:);
X4 = X4(:);

%% Detect Reset
dX1 = diff(X1);
dX2 = diff(X2);
dX4 = diff(X4);

resetCandidate = ...
    (dX1 < -100) & ...
    (dX2 < -200) & ...
    (dX4 < -400) & ...
    (X1(2:end) < 100) & ...
    (X2(2:end) < 200) & ...
    (X4(2:end) < 400);

idxReset = find(resetCandidate)+1;

%% รวม Candidate เดียวกัน
if ~isempty(idxReset)

    dt = median(diff(t));

    minGap = max(round(0.1/dt),1);

    keep = [true; diff(idxReset)>minGap];

    idxReset = idxReset(keep);

end

resetTime = t(idxReset);

disp("Detected reset times (s):");
disp(resetTime);

%% Colors
blue   = [0.0000 0.4470 0.7410];
orange = [0.8500 0.3250 0.0980];
green  = [0.4660 0.6740 0.1880];

%% Full Plot
figure('Color','w','Position',[100 100 1250 650]);

plot(t,X1,...
    'Color',blue,...
    'LineWidth',1.5);
hold on;

plot(t,X2,...
    'Color',orange,...
    'LineWidth',1.5);

plot(t,X4,...
    'Color',green,...
    'LineWidth',1.5);

for k = 1:length(resetTime)

    xline(resetTime(k),...
        '--k',...
        sprintf('Reset %.3f s',resetTime(k)),...
        'LineWidth',1.5,...
        'LabelVerticalAlignment','top',...
        'LabelHorizontalAlignment','left');

end

styleAxes(gca);

xlabel('Time (s)');
ylabel('Raw Count');

title('AMT103-V Encoder Count and Reset Events',...
    'FontSize',14,...
    'FontWeight','bold');

legend('X1','X2','X4',...
    'Location','best');

exportgraphics(gcf,...
    'AMT103_Reset_Full.png',...
    'Resolution',300);

%% Zoom รอบ Reset แรก
if ~isempty(idxReset)

    firstReset = idxReset(1);

    tBefore = 3;
    tAfter  = 5;

    idx1 = find(t >= t(firstReset)-tBefore,1,'first');
    idx2 = find(t <= t(firstReset)+tAfter,1,'last');

    figure('Color','w','Position',[100 100 1200 650]);

    plot(t(idx1:idx2),X1(idx1:idx2),...
        'Color',blue,...
        'LineWidth',1.8);
    hold on;

    plot(t(idx1:idx2),X2(idx1:idx2),...
        'Color',orange,...
        'LineWidth',1.8);

    plot(t(idx1:idx2),X4(idx1:idx2),...
        'Color',green,...
        'LineWidth',1.8);

    xline(t(firstReset),...
        '--k',...
        'Reset / Home Reference',...
        'LineWidth',2,...
        'LabelVerticalAlignment','top');

    styleAxes(gca);

    xlabel('Time (s)');
    ylabel('Raw Count');

    title('AMT103-V Encoder Count Before and After Reset',...
        'FontSize',14,...
        'FontWeight','bold');

    legend('X1','X2','X4',...
        'Location','best');

    exportgraphics(gcf,...
        'AMT103_Reset_Zoom.png',...
        'Resolution',300);

end

%% หา Dataset
function dsOut = findEncoderDataset(dsIn)

requiredNames = ["EncoderX1","EncoderX2","EncoderX4"];

queue = {dsIn};

while ~isempty(queue)

    current = queue{1};
    queue(1) = [];

    if ~isa(current,'Simulink.SimulationData.Dataset')
        continue;
    end

    names = string(getElementNames(current));

    if all(ismember(requiredNames,names))

        dsOut = current;
        return;

    end

    for k = 1:current.numElements

        element = getElement(current,k);

        if isa(element,'Simulink.SimulationData.Dataset')

            queue{end+1} = element;

        elseif isa(element,'Simulink.SimulationData.Signal')

            try

                val = element.Values;

                if isa(val,'Simulink.SimulationData.Dataset')

                    queue{end+1} = val;

                end

            catch
            end

        end

    end

end

error('ไม่พบ Dataset ที่มี EncoderX1, EncoderX2 และ EncoderX4');

end

%% Style
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