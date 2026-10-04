clc;
clear;
close all;

% 1. โหลดไฟล์ข้อมูล
a = load('C:\rmx\lab1_potentio\schmitt trigger\Potentiometer\sch3.mat');

% 2. ดึงสัญญาณจาก Simulink Dataset
ts_gain = a.data.getElement('Gain:1');
ts_ps   = a.data.getElement('PS-Simulink Converter:1');

% 3. สร้างกราฟแสดงผล
figure;

% พล็อตกราฟด้านล่าง (พล็อตเปรียบเทียบทั้งสองสัญญาณ)
plot(ts_gain.Values.Time, ts_gain.Values.Data, 'g-', 'LineWidth', 1.5); hold on;
plot(ts_ps.Values.Time, ts_ps.Values.Data, 'm-', 'LineWidth', 1.5);
title('analog vs digital');
xlabel('Time (s)');
ylabel('V_out');
legend('analog', 'digital');
grid on;
grid minor

xticks(floor(min(xlim)) : 0.5 : ceil(max(xlim)));
yticks(floor(min(ylim)) : 0.5 : ceil(max(ylim)))