function Results = MagneticSensorComparison()
% ============================================================
% MAGNETIC SENSOR COMPARISON
% ============================================================
%
% Files:
%   11.mat
%   2.mat
%   3.mat
%
% A4 > 3000
% HIGH ต้องมากกว่า 3 วินาที
% ใช้ A0 10 วินาทีแรก
% ADC 12-bit, Vref = 3.3 V
%
% Angle:
%   0, 10, 20, 30, ...
%
% ============================================================


%% ============================================================
% 1. FILES
% ============================================================

fileNames = [
    "new1.mat"
    "new2.mat"
    "new3.mat"
];

numFiles = length(fileNames);


%% ============================================================
% 2. SETTINGS
% ============================================================

threshold = 3000;

minHighTime = 3;

measureTime = 10;

startAngle = 0;

angleStep = 10;

ADC_Max = 4095;

Vref = 3.3;


%% ============================================================
% 3. COLORS
% ============================================================

plotColors = [
    0.0000 0.4470 0.7410    % File 1 = Blue
    0.8500 0.3250 0.0980    % File 2 = Orange
    0.4660 0.6740 0.1880    % File 3 = Green
];


%% ============================================================
% 4. STORAGE
% ============================================================

All_Mean = cell(numFiles,1);

All_SD = cell(numFiles,1);

All_Angle = cell(numFiles,1);

All_Duration = cell(numFiles,1);


%% ============================================================
% 5. PROCESS FILES
% ============================================================

for fileNumber = 1:numFiles

    fprintf('\n');
    fprintf('========================================\n');
    fprintf('Processing: %s\n',fileNames(fileNumber));
    fprintf('========================================\n');


    %% --------------------------------------------------------
    % LOAD
    % ---------------------------------------------------------

    loadedData = load(fileNames(fileNumber));


    if ~isfield(loadedData,'data')

        error( ...
            'ไม่พบตัวแปร "data" ในไฟล์ %s', ...
            fileNames(fileNumber));

    end


    data = loadedData.data;


    %% --------------------------------------------------------
    % FIND A0 AND A4
    % ---------------------------------------------------------

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


    if isempty(idxA0)

        error( ...
            'ไม่พบ A0 ในไฟล์ %s', ...
            fileNames(fileNumber));

    end


    if isempty(idxA4)

        error( ...
            'ไม่พบ A4 ในไฟล์ %s', ...
            fileNames(fileNumber));

    end


    %% --------------------------------------------------------
    % GET SIGNAL
    % ---------------------------------------------------------

    A0 = data{idxA0};

    A4 = data{idxA4};


    %% ========================================================
    % IMPORTANT:
    % A0 / A4 เป็น Simulink.SimulationData.Signal
    % ต้องใช้ .Values ก่อน
    % =========================================================


    % A0 Timeseries
    A0_values = A0.Values;


    % A4 Timeseries
    A4_values = A4.Values;


    %% --------------------------------------------------------
    % A0 TIME / DATA
    % ---------------------------------------------------------

    t0 = double(A0_values.Time(:));

    a0 = double(A0_values.Data(:));


    %% --------------------------------------------------------
    % ADC -> VOLTAGE
    % ---------------------------------------------------------

    a0 = ...
        a0 / ADC_Max * Vref;


    %% --------------------------------------------------------
    % A4 TIME / DATA
    % ---------------------------------------------------------

    t4 = double(A4_values.Time(:));

    a4 = double(A4_values.Data(:));


    %% ========================================================
    % CHECK SIZE
    % =========================================================

    if isempty(t0) || isempty(a0)

        error( ...
            'A0 ในไฟล์ %s ไม่มีข้อมูล', ...
            fileNames(fileNumber));

    end


    if isempty(t4) || isempty(a4)

        error( ...
            'A4 ในไฟล์ %s ไม่มีข้อมูล', ...
            fileNames(fileNumber));

    end


    %% ========================================================
    % A4 HIGH
    % =========================================================

    isHigh = a4 > threshold;


    %% --------------------------------------------------------
    % FIND HIGH EDGES
    % ---------------------------------------------------------

    edge = diff([
        false
        isHigh
        false
    ]);


    startIndex = find(edge == 1);

    endIndex = find(edge == -1) - 1;


    %% ========================================================
    % RESULT FOR THIS FILE
    % =========================================================

    Mean = [];

    SD = [];

    Angle = [];

    Duration = [];


    resultNumber = 0;


    %% ========================================================
    % PROCESS EACH HIGH SECTION
    % =========================================================

    for section = 1:length(startIndex)


        %% ----------------------------------------------------
        % START / END TIME
        % -----------------------------------------------------

        tStart = ...
            t4(startIndex(section));


        tEnd = ...
            t4(endIndex(section));


        highDuration = ...
            tEnd - tStart;


        %% ----------------------------------------------------
        % HIGH MUST > 3 SEC
        % -----------------------------------------------------

        if highDuration <= minHighTime

            continue;

        end


        %% ----------------------------------------------------
        % FIRST 10 SEC
        % -----------------------------------------------------

        measureEnd = ...
            tStart + measureTime;


        actualEnd = ...
            min(measureEnd,tEnd);


        %% ----------------------------------------------------
        % GET A0 DATA
        % -----------------------------------------------------

        idxA0_segment = ...
            t0 >= tStart & ...
            t0 <= actualEnd;


        if ~any(idxA0_segment)

            continue;

        end


        segment = ...
            a0(idxA0_segment);


        %% ----------------------------------------------------
        % MEAN
        % -----------------------------------------------------

        resultNumber = ...
            resultNumber + 1;


        Mean(resultNumber,1) = ...
            mean(segment);


        %% ----------------------------------------------------
        % STANDARD DEVIATION
        % -----------------------------------------------------

        SD(resultNumber,1) = ...
            std(segment);


        %% ----------------------------------------------------
        % ACTUAL MEASUREMENT TIME
        % -----------------------------------------------------

        Duration(resultNumber,1) = ...
            actualEnd - tStart;


        %% ----------------------------------------------------
        % ANGLE
        % -----------------------------------------------------

        Angle(resultNumber,1) = ...
            startAngle + ...
            (resultNumber-1)*angleStep;


        %% ----------------------------------------------------
        % PRINT
        % -----------------------------------------------------

        fprintf( ...
            'Angle = %3.0f deg | Mean = %.4f V | SD = %.4f | Time = %.2f s\n', ...
            Angle(resultNumber), ...
            Mean(resultNumber), ...
            SD(resultNumber), ...
            Duration(resultNumber));

    end


    %% --------------------------------------------------------
    % SAVE
    % ---------------------------------------------------------

    All_Mean{fileNumber} = Mean;

    All_SD{fileNumber} = SD;

    All_Angle{fileNumber} = Angle;

    All_Duration{fileNumber} = Duration;


end


%% ============================================================
% 6. CREATE FIGURE
% ============================================================

figure( ...
    'Position',[30 30 1800 1100], ...
    'Color','w');


hold on;

grid on;

box on;


%% ============================================================
% 7. PLOT
% ============================================================

hMean = gobjects(numFiles,1);


for fileNumber = 1:numFiles


    Angle = All_Angle{fileNumber};

    Mean = All_Mean{fileNumber};

    SD = All_SD{fileNumber};


    if isempty(Angle)

        continue;

    end


    %% --------------------------------------------------------
    % ERROR BAR
    % ---------------------------------------------------------

    errorbar( ...
        Angle, ...
        Mean, ...
        SD, ...
        'o', ...
        'Color',plotColors(fileNumber,:), ...
        'LineWidth',1.2, ...
        'CapSize',10, ...
        'MarkerSize',6);


    %% --------------------------------------------------------
    % LINE
    % ---------------------------------------------------------

    hMean(fileNumber) = ...
        plot( ...
            Angle, ...
            Mean, ...
            'o-', ...
            'Color',plotColors(fileNumber,:), ...
            'LineWidth',1.8, ...
            'MarkerSize',6, ...
            'MarkerFaceColor','w');

end


%% ============================================================
% 8. ALL ANGLES
% ============================================================

allAngles = [];


for fileNumber = 1:numFiles

    allAngles = [
        allAngles
        All_Angle{fileNumber}
    ];

end


allAngles = unique(allAngles);

%% ============================================================
% LABEL SETTINGS
% ============================================================
%% ============================================================
% 8.5 THEORETICAL CALCULATION & PLOT (จากบนลงล่าง 3.3V -> 0V)
% ============================================================

b = 3.4738;
Vin = Vref; % 3.3 V

% สร้างจุดสำหรับวาดเส้นประทางทฤษฎีเรียบๆ
theta_theory = linspace(0, 100, 10);
k_theory = theta_theory / 100;

% คำนวณ V_out จากบนลงล่าง (เริ่มต้นที่ Vin แล้วลดลงมาที่ 0V)
% 1. เปลี่ยนบรรทัดคำนวณเส้นประทางทฤษฎีเป็นสมการ Linear (จากบนลงล่าง)
V_theory_line = Vin * ((exp(b * (1 - k_theory)) - 1) / (exp(b) - 1));

% วาดเส้นทฤษฎี (เส้นประสีดำ)
hTheory = plot( ...
    theta_theory, ...
    V_theory_line, ...
    '--', ...                 % เส้นประ
    'Color', [0 0 0], ...     % สีดำ
    'LineWidth', 1.8);

% คำนวณค่าทางทฤษฎีเฉพาะจุดองศาที่มีในการทดลอง (allAngles) เพื่อนำไปโชว์ Label
k_angles = allAngles / 100;
All_Theory_Mean = Vin * ((exp(b * (1 - k_angles)) - 1) / (exp(b) - 1));

valueSpacing = 0.10;     % ระยะ V แต่ละบรรทัด
sdSpacing    = 0.12;     % ระยะ SD แต่ละบรรทัด

valueOffset  = 0.15;     % ระยะจาก error bar ขึ้นไป
sdOffset     = 0.15;     % ระยะจาก error bar ลงมา


%% ============================================================
% LABELS
% ============================================================

%% ============================================================
% LABELS (แสดงค่า V จริง + ค่าทฤษฎีเรียงจากบนลงล่าง)
% ============================================================

for angleIndex = 1:length(allAngles)

    currentAngle = allAngles(angleIndex);

    meanValues = nan(numFiles,1);
    sdValues   = nan(numFiles,1);


    %% --------------------------------------------------------
    % GET VALUES
    % --------------------------------------------------------

    for fileNumber = 1:numFiles

        currentAngleData = All_Angle{fileNumber};
        currentMeanData  = All_Mean{fileNumber};
        currentSDData    = All_SD{fileNumber};

        if isempty(currentAngleData)
            continue;
        end

        idx = find(currentAngleData == currentAngle, 1);

        if ~isempty(idx)
            meanValues(fileNumber) = currentMeanData(idx);
            sdValues(fileNumber)   = currentSDData(idx);
        end

    end


    validMean = ~isnan(meanValues);
    validSD   = ~isnan(sdValues);

    if ~any(validMean)
        continue;
    end


    %% --------------------------------------------------------
    % ERROR BAR BOUNDARY
    % --------------------------------------------------------

    upperValues = meanValues(validMean) + sdValues(validMean);
    lowerValues = meanValues(validMean) - sdValues(validMean);

    topY    = max(upperValues);
    bottomY = min(lowerValues);


    %% ========================================================
    % MEAN VALUES ( round 1, 2, 3 )
    % ========================================================

    validFiles = find(validMean);
    numberOfValues = length(validFiles);

    % พิมพ์ค่าของการทดลองแต่ละรอบ
    for n = 1:numberOfValues
        fileNumber = validFiles(n);

        yText = topY + valueOffset + (numberOfValues - n + 1) * valueSpacing;

        text( ...
            currentAngle, ...
            yText, ...
            sprintf('%.3f V', meanValues(fileNumber)), ...
            'Color', plotColors(fileNumber,:), ...
            'FontSize', 8, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'BackgroundColor', 'w', ...
            'Margin', 1, ...
            'Clipping', 'off');
    end

    % พิมพ์ค่าทางทฤษฎี (ตามการคำนวณ) เป็นบรรทัดล่างสุดของกลุ่ม V
    yTextTheory = topY + valueOffset;
    text( ...
        currentAngle, ...
        yTextTheory, ...
        sprintf('%.3f V', All_Theory_Mean(angleIndex)), ...
        'Color', [0 0 0], ... % สีดำ
        'FontSize', 8, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'BackgroundColor', 'w', ...
        'Margin', 1, ...
        'Clipping', 'off');


    %% ========================================================
    % SD
    % ========================================================

    validSDFiles = find(validSD);
    numberOfSD = length(validSDFiles);

    for n = 1:numberOfSD
        fileNumber = validSDFiles(n);

        yText = bottomY - sdOffset - (n-1)*sdSpacing;

        text( ...
            currentAngle, ...
            yText, ...
            sprintf('SD %.4f', sdValues(fileNumber)), ...
            'Color', plotColors(fileNumber,:), ...
            'FontSize', 8, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'top', ...
            'BackgroundColor', 'w', ...
            'Margin', 2, ...
            'Clipping', 'off');
    end

end

%% ============================================================
% 11. AXIS
% ============================================================

xlabel( ...
    'Angle (degree)', ...
    'FontSize',13);


ylabel( ...
    'A0 Voltage (V)', ...
    'FontSize',13);


title( ...
    'Rotary Potentiometer: Output Voltage vs. Angular Position (3 Trials)', ...
    'FontSize',15, ...
    'FontWeight','bold');


set(gca,'FontSize',11);


%% ============================================================
% 12. X LIMIT
% ============================================================

if ~isempty(allAngles)

    xlim([
        min(allAngles)-8 ...
        max(allAngles)+8
    ]);

end


%% ============================================================
% 13. Y LIMIT
% ============================================================

ylim([-0.70 3.95]);


%% ============================================================
% 14. LEGEND
% ============================================================

%% ============================================================
% 14. LEGEND
% ============================================================

validHandles = isgraphics(hMean);
handlesToPlot = hMean(validHandles);

legendLabels = strings(sum(validHandles), 1);
validIdx = find(validHandles);

for fileNumber = 1:length(validIdx)
    legendLabels(fileNumber) = sprintf('round %d', validIdx(fileNumber));
end

% เพิ่ม "ตามการคำนวณ" ต่อท้ายใน Legend
if exist('hTheory', 'var') && isgraphics(hTheory)
    handlesToPlot = [handlesToPlot; hTheory];
    legendLabels  = [legendLabels; "ตามการคำนวณ"];
end

legend( ...
    handlesToPlot, ...
    legendLabels, ...
    'Location', 'northeast');

%% ============================================================
% 15. EXPORT
% ============================================================

exportgraphics( ...
    gcf, ...
    'MagneticSensor_Comparison.png', ...
    'Resolution',300);


%% ============================================================
% 16. RETURN RESULTS
% ============================================================

Results = struct();


Results.FileNames = fileNames;

Results.Mean = All_Mean;

Results.SD = All_SD;

Results.Angle = All_Angle;

Results.Duration = All_Duration;


%% ============================================================
% DONE
% ============================================================

fprintf('\n');
fprintf('========================================\n');
fprintf('Analysis completed successfully.\n');
fprintf('========================================\n');
fprintf('Graph saved:\n');
fprintf('MagneticSensor_Comparison.png\n');
fprintf('========================================\n');

end