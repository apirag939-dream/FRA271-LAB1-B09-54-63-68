function Results = PlotSandBagsComparison()
% ============================================================
% SAND BAGS VS WEIGHT COMPARISON PLOT
% ============================================================

%% 1. INPUT DATA
% แกน Y: จำนวนถุงทราย (1 - 20 ถุง)
Y_bags = (1:20)';

% แกน X เส้นที่ 1: น้ำหนักจาก Loadcell (kg)
X1_loadcell = [ ...
    0.5872807018; 0.7364035088; 1.161842105;  1.69254386; ...
    2.205701754;  2.705701754;  3.139912281;  3.582894737; ...
    4.196929825;  4.710087719;  5.227631579;  5.68377193; ...
    6.096052632;  6.828508772;  7.319736842;  8.052192982; ...
    8.188157895;  8.705701754;  9.271491228;  9.626754386 ...
];

% แกน X เส้นที่ 2: น้ำหนักรวมจากเครื่องชั่ง (kg) [ค่า Y เก่า]
X2_totalWeight = [ ...
    0.508; 1.008; 1.516; 2.001; 2.495; ...
    2.991; 3.464; 3.962; 4.462; 4.943; ...
    5.443; 5.937; 6.429; 6.916; 7.411; ...
    7.909; 8.423; 8.942; 9.416; 9.906 ...
];

%% 2. CREATE FIGURE
figure( ...
    'Position', [100 100 1000 700], ...
    'Color', 'w');
hold on;
grid on;
box on;

%% 3. PLOT BOTH LINES
% เส้นที่ 1: น้ำหนักจาก Loadcell (สีน้ำเงิน)
plot(X1_loadcell, Y_bags, 'o-', ...
    'Color', [0.0000 0.4470 0.7410], ...
    'LineWidth', 1.8, ...
    'MarkerSize', 6, ...
    'MarkerFaceColor', [0.0000 0.4470 0.7410], ...
    'DisplayName', 'น้ำหนักจาก Loadcell (kg)');

% เส้นที่ 2: น้ำหนักรวม (สีส้ม)
plot(X2_totalWeight, Y_bags, 's--', ...
    'Color', [0.8500 0.3250 0.0980], ...
    'LineWidth', 1.8, ...
    'MarkerSize', 6, ...
    'MarkerFaceColor', [0.8500 0.3250 0.0980], ...
    'DisplayName', 'น้ำหนักจริงที่ชั่งได้จริง (kg)');

%% 4. LABELS & TITLE
xlabel('น้ำหนัก (kg)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('จำนวนถุงทราย (ถุง)', 'FontSize', 12, 'FontWeight', 'bold');
title('เปรียบเทียบน้ำหนักกับจำนวนถุงทราย (1 - 20 ถุง)', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'FontSize', 10);

%% 5. SET AXIS LIMITS AND TICKS (แบ่งช่องตารางห่างกันทีละ 0.5)
xlim([0, 10.5]);
ylim([0, 20.5]);

% กำหนดสเกลแกน X (ทีละ 0.5 kg) และ แกน Y (ทีละ 0.5 ถุง)
xticks(0:0.5:10.5);
yticks(0:0.5:20.5);

legend('Location', 'southeast');

%% 6. EXPORT GRAPH
exportgraphics(gcf, 'SandBags_vs_Weight_Comparison.png', 'Resolution', 300);

%% 7. RETURN STRUCT
Results = struct();
Results.Y_bags = Y_bags;
Results.X1_Loadcell = X1_loadcell;
Results.X2_TotalWeight = X2_totalWeight;

fprintf('========================================\n');
fprintf('สร้างกราฟเปรียบเทียบน้ำหนักกับถุงทรายสำเร็จเรียบร้อย\n');
fprintf('บันทึกรูปภาพ: SandBags_vs_Weight_Comparison.png\n');
fprintf('========================================\n');

end