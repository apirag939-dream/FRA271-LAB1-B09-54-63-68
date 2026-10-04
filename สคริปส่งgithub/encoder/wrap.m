%% FRA271 Lab 1.3 - Wrap-around
% AMT103-V

clear;
clc;
close all;

%% Load
fileName = "C:\LAB1\Encoder\AMT103-V\wpppppppppp.mat";

S = load(fileName);
ds0 = S.data;

%% หา Dataset
ds = findWrapDataset(ds0);

disp("Signals found:");
disp(getElementNames(ds));

%% Read Signals
sigRaw  = getElement(ds,"EncoderX4").Values;
sigWrap = getElement(ds,"MATLAB Function:1").Values;

tRaw = double(sigRaw.Time(:));
raw  = double(squeeze(sigRaw.Data));
raw  = raw(:);

tWrap = double(sigWrap.Time(:));
wrapped = double(squeeze(sigWrap.Data));
wrapped = wrapped(:);

%% Align Time
if length(tRaw) ~= length(tWrap) || any(tRaw ~= tWrap)

    wrapped = interp1(...
        tWrap,...
        wrapped,...
        tRaw,...
        'previous',...
        'extrap');

end

t = tRaw;

%% Detect Overflow
dRaw = diff(raw);

idxOverflow = find(dRaw < -30000)+1;

overflowTime = t(idxOverflow);

%% Colors
blue   = [0.0000 0.4470 0.7410];
orange = [0.8500 0.3250 0.0980];

%% Full Plot
figure('Color','w','Position',[100 100 1250 650]);

stairs(t,raw,...
    'Color',blue,...
    'LineWidth',1.5);
hold on;

stairs(t,wrapped,...
    'Color',orange,...
    'LineWidth',1.8);

for k = 1:length(overflowTime)

    xline(overflowTime(k),...
        '--',...
        'Color',[0.35 0.35 0.35],...
        'LineWidth',1);

end

styleAxes(gca);

xlabel('Time (s)');
ylabel('Count');

title('AMT103-V Raw Count and Count after Wrap-around',...
    'FontSize',14,...
    'FontWeight','bold');

legend('Raw EncoderX4',...
       'After Wrap-around',...
       'Location','northwest');

exportgraphics(gcf,...
    'AMT103_WrapAround.png',...
    'Resolution',300);

%% Zoom จุด Overflow แรก
if ~isempty(idxOverflow)

    firstOverflow = idxOverflow(1);

    tBefore = 2;
    tAfter  = 3;

    i1 = find(t >= t(firstOverflow)-tBefore,1,'first');
    i2 = find(t <= t(firstOverflow)+tAfter,1,'last');

    figure('Color','w','Position',[100 100 1150 620]);

    stairs(t(i1:i2),raw(i1:i2),...
        'Color',blue,...
        'LineWidth',1.8);
    hold on;

    stairs(t(i1:i2),wrapped(i1:i2),...
        'Color',orange,...
        'LineWidth',2);

    xline(t(firstOverflow),...
        '--k',...
        'Counter Overflow',...
        'LineWidth',1.5,...
        'LabelVerticalAlignment','top');

    styleAxes(gca);

    xlabel('Time (s)');
    ylabel('Count');

    title('AMT103-V Count Before and After Wrap-around',...
        'FontSize',14,...
        'FontWeight','bold');

    legend('Raw EncoderX4',...
           'After Wrap-around',...
           'Location','best');

    exportgraphics(gcf,...
        'AMT103_WrapAround_Zoom.png',...
        'Resolution',300);

end

%% Find Dataset
function dsOut = findWrapDataset(dsIn)

requiredNames = ["EncoderX4","MATLAB Function:1"];

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

error('ไม่พบ EncoderX4 และ MATLAB Function:1');

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