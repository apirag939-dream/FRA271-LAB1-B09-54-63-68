function Results = MagneticSensorComparison()
% ============================================================
% MAGNETIC SENSOR COMPARISON
% ============================================================
%
% INPUT FILES
%   11.mat
%   2.mat
%   3.mat
%
% การทำงาน
%   1. อ่าน A0 และ A4 จาก MAT file
%   2. A4 > 3000 ถือเป็น HIGH
%   3. HIGH ต้องมีระยะเวลามากกว่า 3 วินาที
%   4. ใช้ข้อมูล A0 ตั้งแต่เริ่ม HIGH ถึง 10 วินาที
%   5. แปลง ADC 12-bit -> Voltage
%   6. คำนวณ Mean และ Standard Deviation
%   7. กำหนดมุม 0,10,20,30,...
%   8. แสดงข้อมูล 3 ไฟล์ในกราฟเดียว
%
% รองรับข้อมูล:
%   - Simulink.SimulationData.Dataset
%   - Simulink.SimulationData.Signal
%   - timeseries
%   - struct
%   - A0/A4 ที่อยู่โดยตรงใน MAT file
%
% ============================================================


%% ============================================================
% 1. FILES
% ============================================================

fileNames = [
    "loadcell1_ren1.mat"
    "loadcell2_ren.mat"
    "loadcell3_ren.mat"
];

numFiles = length(fileNames);


%% ============================================================
% 2. SETTINGS
% ============================================================

threshold = 3000;       % A4 HIGH threshold

minHighTime = 10;        % HIGH ต้อง > 3 sec

measureTime = 10;       % ใช้ A0 10 sec แรก

startAngle = 4.90335;         % องศาเริ่มต้น

angleStep = 0.5*9.8067;         % เพิ่มทีละ 10 องศา

ADC_Max = 4095;         % 12-bit ADC

Vref = 3.3;             % ADC reference voltage


%% ============================================================
% 3. COLORS
% ============================================================

plotColors = [
    0.0000 0.4470 0.7410     % Blue
    0.8500 0.3250 0.0980     % Orange
    0.4660 0.6740 0.1880     % Green
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
    fprintf('Processing: %s\n', fileNames(fileNumber));
    fprintf('========================================\n');


    %% --------------------------------------------------------
    % CHECK FILE
    % ---------------------------------------------------------

    if ~isfile(fileNames(fileNumber))

        error( ...
            'ไม่พบไฟล์ %s ใน Current Folder', ...
            fileNames(fileNumber));

    end


    %% --------------------------------------------------------
    % LOAD MAT FILE
    % ---------------------------------------------------------

    loadedData = load(fileNames(fileNumber));


    fprintf('\nตัวแปรในไฟล์:\n');
    disp(fieldnames(loadedData));


    %% ========================================================
    % FIND A0 / A4
    % ========================================================

    [A0, A4] = findA0A4(loadedData);


    fprintf('\nพบ A0 และ A4 แล้ว\n');

    fprintf('A0 class = %s\n',class(A0));
    fprintf('A4 class = %s\n',class(A4));


    %% ========================================================
    % CONVERT A0 TO TIME / DATA
    % ========================================================

    [t0,a0] = signalToVector(A0);


    %% ========================================================
    % CONVERT A4 TO TIME / DATA
    % ========================================================

    [t4,a4] = signalToVector(A4);


    %% ========================================================
    % CHECK DATA
    % ========================================================

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
    % MAKE COLUMN VECTOR
    % ========================================================

    t0 = double(t0(:));
    a0 = double(a0(:));

    t4 = double(t4(:));
    a4 = double(a4(:));


    %% ========================================================
    % ADC -> VOLTAGE
    % ========================================================

    a0 = a0 / ADC_Max * Vref;


    %% ========================================================
    % REMOVE NaN / INF
    % ========================================================

    valid0 = isfinite(t0) & isfinite(a0);

    t0 = t0(valid0);
    a0 = a0(valid0);


    valid4 = isfinite(t4) & isfinite(a4);

    t4 = t4(valid4);
    a4 = a4(valid4);


    %% ========================================================
    % SORT BY TIME
    % ========================================================

    [t0,idx0] = sort(t0);
    a0 = a0(idx0);

    [t4,idx4] = sort(t4);
    a4 = a4(idx4);


    %% ========================================================
    % A4 HIGH
    % ========================================================

    isHigh = a4 > threshold;


    %% ========================================================
    % FIND HIGH SECTIONS
    % ========================================================

    edge = diff([
        false
        isHigh
        false
    ]);


    startIndex = find(edge == 1);

    endIndex = find(edge == -1) - 1;


    %% ========================================================
    % STORAGE FOR THIS FILE
    % ========================================================

    Mean = [];
    SD = [];
    Angle = [];
    Duration = [];

    resultNumber = 0;


    %% ========================================================
    % PROCESS EACH HIGH SECTION
    % ========================================================

    for section = 1:length(startIndex)


        %% ----------------------------------------------------
        % START / END TIME
        % -----------------------------------------------------

        tStart = t4(startIndex(section));

        tEnd = t4(endIndex(section));


        %% ----------------------------------------------------
        % HIGH DURATION
        % -----------------------------------------------------

        highDuration = tEnd - tStart;


        fprintf( ...
            'HIGH section %d: %.3f -> %.3f sec (%.3f sec)\n', ...
            section, ...
            tStart, ...
            tEnd, ...
            highDuration);


        %% ----------------------------------------------------
        % HIGH MUST > 3 SEC
        % -----------------------------------------------------

        if highDuration <= minHighTime

            fprintf('   -> ข้าม เพราะ HIGH <= 3 sec\n');

            continue;

        end


        %% ----------------------------------------------------
        % MEASUREMENT END
        % -----------------------------------------------------

        measureEnd = tStart + measureTime;


        %% ----------------------------------------------------
        % ถ้า HIGH หมดก่อน 10 sec
        % ใช้เท่าที่มี
        % -----------------------------------------------------

        actualEnd = min(measureEnd,tEnd);


        %% ----------------------------------------------------
        % GET A0 DATA
        % -----------------------------------------------------

        idxA0_segment = ...
            t0 >= tStart & ...
            t0 <= actualEnd;


        if ~any(idxA0_segment)

            fprintf('   -> ข้าม เพราะไม่มี A0 ในช่วงนี้\n');

            continue;

        end


        segment = a0(idxA0_segment);


        %% ----------------------------------------------------
        % REMOVE NaN
        % -----------------------------------------------------

        segment = segment(isfinite(segment));


        if isempty(segment)

            fprintf('   -> ข้าม เพราะ A0 ไม่มีข้อมูล\n');

            continue;

        end


        %% ----------------------------------------------------
        % RESULT NUMBER
        % -----------------------------------------------------

        resultNumber = resultNumber + 1;


        %% ----------------------------------------------------
        % MEAN
        % -----------------------------------------------------

        Mean(resultNumber,1) = mean(segment);


        %% ----------------------------------------------------
        % STANDARD DEVIATION
        % -----------------------------------------------------

        SD(resultNumber,1) = std(segment);


        %% ----------------------------------------------------
        % ACTUAL TIME
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
        % PRINT RESULT
        % -----------------------------------------------------

        fprintf( ...
            '   Angle = %3.0f deg | Mean = %.4f V | SD = %.4f | Time = %.2f s\n', ...
            Angle(resultNumber), ...
            Mean(resultNumber), ...
            SD(resultNumber), ...
            Duration(resultNumber));

    end


    %% ========================================================
    % SAVE RESULTS
    % ========================================================

    All_Mean{fileNumber} = Mean;

    All_SD{fileNumber} = SD;

    All_Angle{fileNumber} = Angle;

    All_Duration{fileNumber} = Duration;


    fprintf('\n');

    fprintf( ...
        'พบข้อมูลที่ผ่านเงื่อนไขทั้งหมด %d จุด\n', ...
        resultNumber);

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
% 9. LABEL SETTINGS
% ============================================================

valueSpacing = 0.10;

sdSpacing = 0.16;

valueOffset = 0.15;

sdOffset = 0.15;


%% ============================================================
% 10. LABELS
% ============================================================

for angleIndex = 1:length(allAngles)


    currentAngle = allAngles(angleIndex);


    meanValues = nan(numFiles,1);

    sdValues = nan(numFiles,1);


    %% --------------------------------------------------------
    % GET VALUES
    % ---------------------------------------------------------

    for fileNumber = 1:numFiles


        currentAngleData = All_Angle{fileNumber};

        currentMeanData = All_Mean{fileNumber};

        currentSDData = All_SD{fileNumber};


        if isempty(currentAngleData)

            continue;

        end


        idx = find( ...
            currentAngleData == currentAngle, ...
            1);


        if ~isempty(idx)

            meanValues(fileNumber) = ...
                currentMeanData(idx);

            sdValues(fileNumber) = ...
                currentSDData(idx);

        end

    end


    %% --------------------------------------------------------
    % VALID DATA
    % ---------------------------------------------------------

    validMean = ~isnan(meanValues);

    validSD = ~isnan(sdValues);


    if ~any(validMean)

        continue;

    end


    %% --------------------------------------------------------
    % ERROR BAR BOUNDARY
    % ---------------------------------------------------------

    upperValues = ...
        meanValues(validMean) + ...
        sdValues(validMean);


    lowerValues = ...
        meanValues(validMean) - ...
        sdValues(validMean);


    topY = max(upperValues);

    bottomY = min(lowerValues);


    %% ========================================================
    % MEAN LABELS
    % ========================================================

    validFiles = find(validMean);

    numberOfValues = length(validFiles);


    for n = 1:numberOfValues


        fileNumber = validFiles(n);


        % จากบนลงล่าง

        yText = ...
            topY + ...
            valueOffset + ...
            (numberOfValues-n)*valueSpacing;


        text( ...
            currentAngle, ...
            yText, ...
            sprintf('%.3f V', ...
            meanValues(fileNumber)), ...
            'Color',plotColors(fileNumber,:), ...
            'FontSize',8, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom', ...
            'BackgroundColor','w', ...
            'Margin',2, ...
            'Clipping','off');

    end


    %% ========================================================
    % SD LABELS
    % ========================================================

    validSDFiles = find(validSD);

    numberOfSD = length(validSDFiles);


    for n = 1:numberOfSD


        fileNumber = validSDFiles(n);


        yText = ...
            bottomY - ...
            sdOffset - ...
            (n-1)*sdSpacing;


        text( ...
            currentAngle, ...
            yText, ...
            sprintf('SD %.4f', ...
            sdValues(fileNumber)), ...
            'Color',plotColors(fileNumber,:), ...
            'FontSize',8, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','top', ...
            'BackgroundColor','w', ...
            'Margin',3, ...
            'Clipping','off');

    end

end


%% ============================================================
% 11. AXIS
% ============================================================

xlabel( ...
    'Force (N)', ...
    'FontSize',13);


ylabel( ...
    'A0 Voltage (V)', ...
    'FontSize',13);


title( ...
    'Loadcell: Output Voltage vs Force (3 Trials)', ...
    'FontSize',15, ...
    'FontWeight','bold');


set(gca,'FontSize',11);


%% ============================================================
% 12. X LIMIT
% ============================================================

if ~isempty(allAngles)

    xlim([
        min(allAngles)-5 ...
        max(allAngles)+5
    ]);

end


%% ============================================================
% 13. Y LIMIT
% ============================================================

ylim([-0.70 3.95]);


%% ============================================================
% 14. LEGEND
% ============================================================

validHandles = isgraphics(hMean);

legendLabels = strings(numFiles,1);


for fileNumber = 1:numFiles

    legendLabels(fileNumber) = ...
        sprintf('round %d',fileNumber);

end


if any(validHandles)

    legend( ...
        hMean(validHandles), ...
        legendLabels(validHandles), ...
        'Location','northeast');

end


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
% 17. DONE
% ============================================================

fprintf('\n');
fprintf('========================================\n');
fprintf('Analysis completed successfully.\n');
fprintf('========================================\n');

fprintf('Graph saved:\n');
fprintf('MagneticSensor_Comparison.png\n');

fprintf('========================================\n');


end



%% ============================================================
% LOCAL FUNCTION: FIND A0 AND A4
% ============================================================

function [A0,A4] = findA0A4(loadedData)

A0 = [];
A4 = [];


%% ============================================================
% 1. ตรวจตัวแปรระดับบนก่อน
% ============================================================

variableNames = fieldnames(loadedData);


for k = 1:length(variableNames)

    name = variableNames{k};

    value = loadedData.(name);


    % ---------------------------------------------
    % ชื่อ A0
    % ---------------------------------------------

    if strcmpi(name,'A0')

        A0 = value;

    end


    % ---------------------------------------------
    % ชื่อ A4
    % ---------------------------------------------

    if strcmpi(name,'A4')

        A4 = value;

    end

end


if ~isempty(A0) && ~isempty(A4)

    return;

end


%% ============================================================
% 2. หาใน Dataset
% ============================================================

for k = 1:length(variableNames)

    value = loadedData.(variableNames{k});


    if isa(value,'Simulink.SimulationData.Dataset')


        for n = 1:value.numElements


            element = value{n};


            if isprop(element,'Name')

                name = string(element.Name);


                if name == "A0"

                    A0 = element;

                elseif name == "A4"

                    A4 = element;

                end

            end

        end

    end

end


if ~isempty(A0) && ~isempty(A4)

    return;

end


%% ============================================================
% 3. หาใน struct
% ============================================================

for k = 1:length(variableNames)

    value = loadedData.(variableNames{k});


    if isstruct(value)


        fields = fieldnames(value);


        for n = 1:length(fields)


            fieldName = fields{n};


            if strcmpi(fieldName,'A0')

                A0 = value.(fieldName);

            elseif strcmpi(fieldName,'A4')

                A4 = value.(fieldName);

            end

        end

    end

end


if ~isempty(A0) && ~isempty(A4)

    return;

end


%% ============================================================
% 4. ถ้ายังหาไม่เจอ
% ============================================================

fprintf('\n');
fprintf('========================================\n');
fprintf('ไม่สามารถหา A0 และ A4 ได้\n');
fprintf('========================================\n');

fprintf('ตัวแปรที่พบใน MAT file:\n');

for k = 1:length(variableNames)

    value = loadedData.(variableNames{k});

    fprintf( ...
        '  %s : %s\n', ...
        variableNames{k}, ...
        class(value));

end


fprintf('\n');


%% ============================================================
% กรณี data เป็น timeseries โดยตรง
% ============================================================

if isfield(loadedData,'data') && ...
        isa(loadedData.data,'timeseries')


    error([ ...
        'MAT file นี้มีตัวแปร "data" เป็น timeseries โดยตรง\n' ...
        'แต่ไม่มีตัวแปร A4 ให้ใช้เป็นตัวกำหนดช่วง HIGH\n\n' ...
        'ดังนั้นไฟล์นี้ยังไม่สามารถคำนวณตามเงื่อนไข A4 > 3000 ได้\n' ...
        ]);

end


error( ...
    'ไม่พบ A0 และ A4 ใน MAT file');


end



%% ============================================================
% LOCAL FUNCTION: SIGNAL TO VECTOR
% ============================================================

function [t,x] = signalToVector(signal)

t = [];
x = [];


%% ============================================================
% CASE 1: timeseries
% ============================================================

if isa(signal,'timeseries')

    t = signal.Time;

    x = signal.Data;

    return;

end


%% ============================================================
% CASE 2: Simulink.SimulationData.Signal
% ============================================================

if isa(signal,'Simulink.SimulationData.Signal')

    values = signal.Values;

    [t,x] = signalToVector(values);

    return;

end


%% ============================================================
% CASE 3: Dataset element
% ============================================================

if isprop(signal,'Values')

    values = signal.Values;

    [t,x] = signalToVector(values);

    return;

end


%% ============================================================
% CASE 4: struct
% ============================================================

if isstruct(signal)


    if isfield(signal,'Time') && ...
            isfield(signal,'Data')

        t = signal.Time;

        x = signal.Data;

        return;

    end


    if isfield(signal,'Values')

        [t,x] = signalToVector(signal.Values);

        return;

    end

end


%% ============================================================
% CASE 5: timetable
% ============================================================

if istimetable(signal)

    t = seconds(signal.Time - signal.Time(1));

    x = signal.Variables;

    return;

end


%% ============================================================
% ERROR
% ============================================================

error( ...
    'ไม่สามารถแปลงข้อมูลชนิด %s เป็น Time/Data ได้', ...
    class(signal));


end