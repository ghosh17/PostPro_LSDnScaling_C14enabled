% Cosmogenic_plotter.m
clc
clear all
close all

%% -------------------------
% Excel source
% --------------------------
fileName  = 'CosmogenicConcentrations.xlsx'; % same folder as this script
sheetName = 'Summary 14C 10Be';

%% -------------------------
% Period order
% --------------------------
periods = {'Pre/Early-chumash','Chumash','Pastoralism'};

%% -------------------------
% Fig 1: ONLY SC (rows 87–91, cols A–H)
% --------------------------
sc_block = readcell(fileName, 'Sheet', sheetName, 'Range', 'A87:H91');

[sc_10be, sc_10be_unc, sc_14c, sc_14c_unc] = parseSummaryBlock(sc_block, periods);

x = 1:numel(periods);
w = 0.35;

figure('Color','w'); hold on;
b1 = bar(x - w/2, sc_10be, w, 'FaceColor',[0 0.125 0.376], 'EdgeColor','none');
b2 = bar(x + w/2, sc_14c, w, 'FaceColor',[0.7 0 0], 'EdgeColor','none');

errorbar(x - w/2, sc_10be, sc_10be_unc, 'k', 'LineStyle','none', 'LineWidth',1, 'CapSize',6);
errorbar(x + w/2, sc_14c, sc_14c_unc, 'k', 'LineStyle','none', 'LineWidth',1, 'CapSize',6);

set(gca,'XTick',x,'XTickLabel',periods);
ylabel('Erosion rate (mm/ka)');
ylim([0 inf]);
title('Cosmogenic erosion rate estimates (only SC canyon, excluding Laguna modern catchment)');
legend([b1 b2], {'10Be erosion rate','14C erosion rate'}, 'Location','southoutside', 'Orientation','horizontal');
grid on; box on;

%% --------------------------
% Fig 2: Including Laguna (rows 82–86, cols A–H)
% --------------------------
lag_block = readcell(fileName, 'Sheet', sheetName, 'Range', 'A82:H86');

[laguna_10be, laguna_10be_unc, laguna_14c, laguna_14c_unc] = parseSummaryBlock(lag_block, periods);

figure('Color','w'); hold on;
b1 = bar(x - w/2, laguna_10be, w, 'FaceColor',[0 0.125 0.376], 'EdgeColor','none');
b2 = bar(x + w/2, laguna_14c, w, 'FaceColor',[0.7 0 0], 'EdgeColor','none');

errorbar(x - w/2, laguna_10be, laguna_10be_unc, 'k', 'LineStyle','none', 'LineWidth',1, 'CapSize',6);
errorbar(x + w/2, laguna_14c, laguna_14c_unc, 'k', 'LineStyle','none', 'LineWidth',1, 'CapSize',6);

set(gca,'XTick',x,'XTickLabel',periods);
ylabel('Erosion rate (mm/ka)');
ylim([0 inf]);
title('Cosmogenic erosion rate estimates (Including Laguna)');
legend([b1 b2], {'10Be erosion rate','14C erosion rate'}, 'Location','southoutside', 'Orientation','horizontal');
grid on; box on;

%% --------------------------
% Fig 3: Scatter (rows 1–10, cols A–K)
% --------------------------
tbl = readtable(fileName, 'Sheet', sheetName, 'Range', 'A1:K10', ...
    'VariableNamingRule','preserve');

sampleID = string(tbl{:,1});
ages     = tbl{:,2};
age_unc  = tbl{:,3};

eta14    = tbl{:,6};
eta14_int= tbl{:,7};
eta14_ext= tbl{:,8};

eta10    = tbl{:,9};
eta10_int= tbl{:,10};
eta10_ext= tbl{:,11};

isLaguna = contains(sampleID, 'Laguna', 'IgnoreCase', true);
isSC = ~isLaguna;

% Colors
c10_sc  = [0 0.44 0.75];
c10_lag = [0 0.6 0];     % green for Laguna 10Be
c14_sc  = [0.7 0 0];
c14_lag = [1 0.4 0.6];   % pink for Laguna 14C

% Marker / line styling
ms = 8;      % marker size
lw = 1.8;    % error bar line width
capInt = 4;  % internal cap size
capExt = 10; % external cap size (longer)

figure('Color','w'); hold on;

% 10Be SC (internal)
errorbar(ages(isSC), eta10(isSC), eta10_int(isSC), 'o', ...
    'Color',c10_sc, 'MarkerFaceColor',c10_sc, 'LineStyle','none', ...
    'CapSize',capInt, 'LineWidth', lw, 'MarkerSize', ms, ...
    'DisplayName','10Be SC (internal)');

% 10Be SC (external)
errorbar(ages(isSC), eta10(isSC), eta10_ext(isSC), 'o', ...
    'Color',c10_sc, 'MarkerFaceColor','none', 'LineStyle','none', ...
    'CapSize',capExt, 'LineWidth', lw, 'MarkerSize', ms, ...
    'DisplayName','10Be SC (external)');

% 10Be Laguna (internal)
errorbar(ages(isLaguna), eta10(isLaguna), eta10_int(isLaguna), 'o', ...
    'Color',c10_lag, 'MarkerFaceColor',c10_lag, 'LineStyle','none', ...
    'CapSize',capInt, 'LineWidth', lw, 'MarkerSize', ms, ...
    'DisplayName','10Be Laguna (internal)');

% 10Be Laguna (external)
errorbar(ages(isLaguna), eta10(isLaguna), eta10_ext(isLaguna), 'o', ...
    'Color',c10_lag, 'MarkerFaceColor','none', 'LineStyle','none', ...
    'CapSize',capExt, 'LineWidth', lw, 'MarkerSize', ms, ...
    'DisplayName','10Be Laguna (external)');

% 14C (only valid)
mask14 = ~isnan(eta14);

% 14C SC (internal)
mask14_sc = mask14 & isSC;
errorbar(ages(mask14_sc), eta14(mask14_sc), eta14_int(mask14_sc), 'o', ...
    'Color',c14_sc, 'MarkerFaceColor',c14_sc, 'LineStyle','none', ...
    'CapSize',capInt, 'LineWidth', lw, 'MarkerSize', ms, ...
    'DisplayName','14C SC (internal)');

% 14C SC (external)
errorbar(ages(mask14_sc), eta14(mask14_sc), eta14_ext(mask14_sc), 'o', ...
    'Color',c14_sc, 'MarkerFaceColor','none', 'LineStyle','none', ...
    'CapSize',capExt, 'LineWidth', lw, 'MarkerSize', ms, ...
    'DisplayName','14C SC (external)');

% 14C Laguna (internal)
mask14_lag = mask14 & isLaguna;
errorbar(ages(mask14_lag), eta14(mask14_lag), eta14_int(mask14_lag), 'o', ...
    'Color',c14_lag, 'MarkerFaceColor',c14_lag, 'LineStyle','none', ...
    'CapSize',capInt, 'LineWidth', lw, 'MarkerSize', ms, ...
    'DisplayName','14C Laguna (internal)');

% 14C Laguna (external)
errorbar(ages(mask14_lag), eta14(mask14_lag), eta14_ext(mask14_lag), 'o', ...
    'Color',c14_lag, 'MarkerFaceColor','none', 'LineStyle','none', ...
    'CapSize',capExt, 'LineWidth', lw, 'MarkerSize', ms, ...
    'DisplayName','14C Laguna (external)');

set(gca,'XDir','reverse');  % linear axis, reverse direction
xlabel('Age (ka)');
ylabel('Erosion rate (mm/kyr)');
ylim([0 inf]);
title('10Be + 14C erosion rate');
legend('Location','southoutside','Orientation','horizontal');
grid on; box on;

%% --------------------------
% Helper: parse summary block (A–H)
% --------------------------
function [avg10, unc10, avg14, unc14] = parseSummaryBlock(block, periodsOrder)
    % Extract columns
    p_col   = block(:,1);
    avg10_c = block(:,2);
    unc10_c = block(:,3);
    avg14_c = block(:,6);
    unc14_c = block(:,7);

    avg10_vec = cellfun(@convertToNumber, avg10_c);
    unc10_vec = cellfun(@convertToNumber, unc10_c);
    avg14_vec = cellfun(@convertToNumber, avg14_c);
    unc14_vec = cellfun(@convertToNumber, unc14_c);

    % Find actual data rows (where avg10 is numeric)
    isData = ~isnan(avg10_vec);

    p_names = string(p_col(isData));
    avg10_i = avg10_vec(isData);
    unc10_i = unc10_vec(isData);
    avg14_i = avg14_vec(isData);
    unc14_i = unc14_vec(isData);

    % Reorder into requested period order
    avg10 = nan(1, numel(periodsOrder));
    unc10 = nan(1, numel(periodsOrder));
    avg14 = nan(1, numel(periodsOrder));
    unc14 = nan(1, numel(periodsOrder));

    for i = 1:numel(periodsOrder)
        idx = find(strcmpi(p_names, periodsOrder{i}), 1);
        if ~isempty(idx)
            avg10(i) = avg10_i(idx);
            unc10(i) = unc10_i(idx);
            avg14(i) = avg14_i(idx);
            unc14(i) = unc14_i(idx);
        end
    end
end

function v = convertToNumber(x)
    % Robustly convert mixed cell values to numeric
    if iscell(x)
        x = x{1};
    end
    if isstring(x) && numel(x) > 1
        x = x(1);
    end
    if isnumeric(x) && numel(x) > 1
        x = x(1);
    end

    if isempty(x)
        v = NaN;
        return
    end

    if isstring(x) || ischar(x) || iscategorical(x)
        if any(ismissing(x))
            v = NaN;
        else
            v = str2double(string(x));
            if isnan(v)
                v = NaN;
            end
        end
        return
    end

    if ismissing(x)
        v = NaN;
    elseif isnumeric(x)
        v = x;
    else
        v = str2double(string(x));
        if isnan(v)
            v = NaN;
        end
    end
end