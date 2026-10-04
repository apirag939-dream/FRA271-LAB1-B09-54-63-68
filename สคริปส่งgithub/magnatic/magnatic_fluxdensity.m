% ============================================================
% MAGNETIC SENSOR COMPARISON (B vs Distance - Clean & Professional)
% ============================================================
clear; clc; close all;

% 1. FILES
fileNames = [
    "1.mat"
    "2.mat"
    "3.mat"
];
numFiles = length(fileNames);

% 2. SETTINGS
threshold = 3000;
minHighTime = 3;
measureTime = 10;

% เริ่มต้นที่ 0.5 ซม. เพิ่มทีละ 0.3 ซม.
startDistance = 0.5; 
distanceStep = 0.3; 

ADC_Max = 4095;
Vref = 3.3;

% --- พารามิเตอร์สำหรับคำนวณค่า B ---
VQ = 1.65;                
Sensitivity_25C = 30; 
STC = 0.0012;             
TA = 25;                 

% 3. COLORS & STYLES (สีพาสเทลพรีเมียม สบายตา)
plotColors = [
    0.0000, 0.4470, 0.7410;    % Blue
    0.8500, 0.3250, 0.0980;    % Orange
    0.4660, 0.6740, 0.1880     % Green
];

% 4. STORAGE
All_Mean = cell(numFiles,1);
All_SD = cell(numFiles,1);
All_Distance = cell(numFiles,1);
All_Duration = cell(numFiles,1);

% 5. PROCESS FILES
for fileNumber = 1:numFiles
    fprintf('\n');
    fprintf('========================================\n');
    fprintf('Processing: %s\n',fileNames(fileNumber));
    fprintf('========================================\n');
    
    loadedData = load(fileNames(fileNumber));
    if ~isfield(loadedData,'data')
        error('ไม่พบตัวแปร "data" ในไฟล์ %s', fileNames(fileNumber));
    end
    data = loadedData.data;
    
    idxA0 = [];
    idxA4 = [];
    for k = 1:data.numElements
        name = string(data{k}.Name);
        if name == "A0"
            idxA0 = k;
        elseif name == "A4"
            idxA4 = k;
        end
    end
    
    if isempty(idxA0) || isempty(idxA4)
        error('ไม่พบ A0 หรือ A4 ในไฟล์ %s', fileNames(fileNumber));
    end
    
    A0 = data{idxA0};
    A4 = data{idxA4};
    
    A0_values = A0.Values;
    A4_values = A4.Values;
    
    t0 = double(A0_values.Time(:));
    a0 = double(A0_values.Data(:));
    
    t4 = double(A4_values.Time(:));
    a4 = double(A4_values.Data(:));
    
    if isempty(t0) || isempty(a0) || isempty(t4) || isempty(a4)
        error('ข้อมูลในไฟล์ %s ไม่ครบถ้วน', fileNames(fileNumber));
    end
    
    % ADC -> Voltage -> Magnetic Field (B)
    V_out = (a0 / ADC_Max) * Vref;
    b_signal = (V_out - VQ) / (Sensitivity_25C * (1 + STC * (TA - 25)));
    
    % A4 HIGH Detection
    isHigh = a4 > threshold;
    edge = diff([false; isHigh; false]);
    startIndex = find(edge == 1);
    endIndex = find(edge == -1) - 1;
    
    Mean = [];
    SD = [];
    Distance = [];
    Duration = [];
    resultNumber = 0;
    
    for section = 1:length(startIndex)
        tStart = t4(startIndex(section));
        tEnd = t4(endIndex(section));
        highDuration = tEnd - tStart;
        
        if highDuration <= minHighTime
            continue;
        end
        
        measureEnd = tStart + measureTime;
        actualEnd = min(measureEnd, tEnd);
        
        idxA0_segment = t0 >= tStart & t0 <= actualEnd;
        if ~any(idxA0_segment)
            continue;
        end
        
        segment = b_signal(idxA0_segment);
        
        resultNumber = resultNumber + 1;
        Mean(resultNumber,1) = mean(segment);
        SD(resultNumber,1) = std(segment);
        Duration(resultNumber,1) = actualEnd - tStart;
        
        % กำหนดระยะทางในหน่วย cm
        Distance(resultNumber,1) = startDistance + (resultNumber-1) * distanceStep;
        
        fprintf('Distance = %.1f cm | Mean B = %.4f | SD = %.4f | Time = %.2f s\n', ...
            Distance(resultNumber), Mean(resultNumber), SD(resultNumber), Duration(resultNumber));
    end
    
    All_Mean{fileNumber} = Mean;
    All_SD{fileNumber} = SD;
    All_Distance{fileNumber} = Distance;
    All_Duration{fileNumber} = Duration;
end

% 6. CREATE FIGURE (ปรับขนาดสัดส่วนให้เหมาะกับการนำไปใส่รายงาน)
figure('Position',[100 100 1200 700], 'Color','w');
hold on; 

% 7. PLOT (เส้นกราฟสมูท พร้อม Error Bar ที่โปร่งแสงและดูสะอาดตา)
hMean = gobjects(numFiles,1);
for fileNumber = 1:numFiles
    Distance = All_Distance{fileNumber};
    Mean = All_Mean{fileNumber};
    SD = All_SD{fileNumber};
    if isempty(Distance)
        continue;
    end
    
    % วาด Error Bar แบบโปร่งแสงเล็กน้อยเพื่อให้กราฟดูไม่รก
    eh = errorbar(Distance, Mean, SD, 'o', ...
        'Color', plotColors(fileNumber,:), ...
        'LineWidth', 1.2, 'CapSize', 6, 'MarkerSize', 5);
    % ปรับให้ Error Bar มีความโปร่งแสงสวยงาม (ถ้า MATLAB เวอร์ชั่นรองรับ)
    try
        eh.Color = [plotColors(fileNumber,:) 0.7];
    end
    
    % วาดเส้นกราฟหลัก
    hMean(fileNumber) = plot(Distance, Mean, '-o', ...
        'Color', plotColors(fileNumber,:), ...
        'LineWidth', 2.0, ...
        'MarkerSize', 6, ...
        'MarkerFaceColor', 'w', ...
        'MarkerEdgeColor', plotColors(fileNumber,:));
end

% 8. AXIS, GRID & LABELS
xlabel('Distance (cm)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);
ylabel(' Magnetic Flux Density (T)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);
title('Magnetic Flux Density VS Distance', 'FontSize', 14, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);

set(gca, ...
    'FontSize', 11, ...
    'LineWidth', 1.2, ...
    'Box', 'on', ...
    'XGrid', 'on', 'YGrid', 'on', ...
    'GridLineStyle', ':', ...
    'GridColor', [0.7 0.7 0.7], ...
    'GridAlpha', 0.6);

% 9. X & Y LIMITS
allDistances = [];
for fileNumber = 1:numFiles
    allDistances = [allDistances; All_Distance{fileNumber}];
end
if ~isempty(allDistances)
    xlim([min(allDistances)-0.2, max(allDistances)+0.2]);
end

% 10. LEGEND
validHandles = isgraphics(hMean);
legendLabels = strings(numFiles,1);
for fileNumber = 1:numFiles
    legendLabels(fileNumber) = sprintf('Measurement Round %d', fileNumber);
end
leg = legend(hMean(validHandles), legendLabels(validHandles), ...
    'Location', 'southeast', ...
    'FontSize', 10);
set(leg, 'Box', 'on', 'EdgeColor', [0.8 0.8 0.8]);

% 11. EXPORT HIGH RESOLUTION
exportgraphics(gcf, 'MagneticSensor_Clean_Comparison.png', 'Resolution', 300);

fprintf('\n');
fprintf('========================================\n');
fprintf('Analysis completed successfully.\n');
fprintf('Clean graph saved: MagneticSensor_Clean_Comparison.png\n');
fprintf('========================================\n');