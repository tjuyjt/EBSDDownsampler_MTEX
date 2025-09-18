%% ===========================
% 初始化
%% ===========================
clear; clc; close all;

%% 输入输出文件路径
inputFile  = '718_SS.ang';                 % 原始文件
outputFile = '718_SS_downsampled.ang';    % 下采样后的文件

%% ===========================
% Step 1: 读取 EBSD 数据
%% ===========================
try
    ebsd = loadEBSD(inputFile,'interface','ang');
    disp('✅ 文件读取成功！');
catch ME
    disp('❌ 文件读取失败，请检查文件路径或格式');
    rethrow(ME);
end

%% ===========================
% Step 2: 检查数据并选择有效相
%% ===========================
disp('识别到的相:');
disp(ebsd.mineralList);

% 排除 notIndexed
validPhases = ebsd.mineralList(~strcmpi(ebsd.mineralList,'notIndexed'));

if isempty(validPhases)
    error('❌ 没有检测到有效的晶体相，可能是 .ang 文件没有包含完整的相位信息。');
else
    phaseName = validPhases{1};
    disp(['选择的相为: ', phaseName]);
end

%% ===========================
% Step 3: 原始 EBSD 已索引点
%% ===========================
ebsd_indexed = ebsd(phaseName);
ebsd_indexed = ebsd_indexed(ebsd_indexed.isIndexed);  % 保留已索引点

if isempty(ebsd_indexed)
    error('❌ 没有已索引点可以绘图');
end

%% ===========================
% Step 4: 绘制原始 EBSD IPF-Z 图
%% ===========================
oM = ipfHSVKey(ebsd_indexed);
oM.inversePoleFigureDirection = vector3d.Z;

figure;
plot(ebsd_indexed, oM.orientation2color(ebsd_indexed.orientations));
title(['Original EBSD IPF-Z Map (' phaseName ')']);
colorbar off;

%% ===========================
% Step 5: 转换为规则网格
%% ===========================
ebsd_grid = gridify(ebsd_indexed);

%% Step 6: 计算原始步长
dx = median(diff(unique(ebsd_grid.prop.x))); % X方向步长
dy = median(diff(unique(ebsd_grid.prop.y))); % Y方向步长
disp(['原始步长: dx = ' num2str(dx) ', dy = ' num2str(dy)]);

%% ===========================
% Step 7: 下采样
%% ===========================
factor = 5;  % 下采样倍数
ebsd_down = reduce(ebsd_grid, factor);  % 下采样后保留 orientation

%% Step 8: 计算新步长
dx2 = median(diff(unique(ebsd_down.prop.x)));
dy2 = median(diff(unique(ebsd_down.prop.y)));
disp(['下采样后的步长: dx = ' num2str(dx2) ', dy = ' num2str(dy2)]);

%% ===========================
% Step 9: 导出下采样后的 EBSD 文件
%% ===========================
export(ebsd_down, outputFile, 'ang');
disp(['✅ 导出完成，新文件为: ', outputFile]);

%% ===========================
% Step 10: 绘制下采样后的 IPF-Z 图
%% ===========================
% 对 EBSDsquare，不要用 phaseName 索引，直接绘制
oM_down = ipfHSVKey(ebsd_down);
oM_down.inversePoleFigureDirection = vector3d.Z;

figure;
plot(ebsd_down, oM_down.orientation2color(ebsd_down.orientations));
title('Downsampled EBSD IPF-Z Map');
colorbar off;

%% ===========================
% 可选：原始与下采样并排对比
%% ===========================
figure;
subplot(1,2,1);
plot(ebsd_indexed, oM.orientation2color(ebsd_indexed.orientations));
title('Original EBSD IPF-Z');
colorbar off;

subplot(1,2,2);
plot(ebsd_down, oM_down.orientation2color(ebsd_down.orientations));
title('Downsampled EBSD IPF-Z');
colorbar off;
