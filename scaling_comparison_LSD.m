% scaling_comparison_LSD.m
% Compare cosmogenic nuclide scaling factors using LSD (Lifton-Sato-Dunai)
% scaling between modern and historical time periods
%
% This script calculates how production rates differ due to geomagnetic
% field variations through time for 10Be and 14C using LSD scaling
%
% Adapted from scaling_comparison.m for LSD scaling, 2026

clc
clear
close all

% Add paths
addpath '.\subroutines'
addpath '.\InputData'
addpath(genpath(pwd));
addpath(genpath(fullfile(pwd,'cronus-calc')));

% Add LSD path (now inside PostPro folder)
lsd_path = fullfile(pwd, 'LSD MATLAB Code');
addpath(lsd_path);
addpath(fullfile(lsd_path, 'Shared Files'));
addpath(fullfile(lsd_path, 'Shared Files', 'Spectra'));

%% USER SETTINGS

excel_file = '10Be_data_CRONUS.xlsx';
age_col = 33;  % Column containing ages in ka

% Read from Excel file
fprintf('Reading data from: %s\n', excel_file);
[num, txt, ~] = xlsread(excel_file, 'Matlab Postburial');

% Extract location data for all samples
sample_lats = num(:, 1);
sample_lons = num(:, 2);
sample_elvs = num(:, 3);
sample_names = txt(2:end, 1);  % Skip header row

fprintf('Processing %d samples with individual locations\n', length(sample_lats));

%% TIME PERIODS TO COMPARE
% Dynamically extract ages from Excel file
% Read ages from all samples in the Excel file

% Extract ages from column 33 (in ka), convert to years BP
ages_ka = num(:, age_col);  % All ages in ka

years_BP = 1000*ages_ka;
n_times = length(years_BP);

% Generate time labels
time_labels = cell(n_times, 1);
for i = 1:n_times
    if years_BP(i) == 0
        time_labels{i} = 'Modern (2010 AD)';
    elseif years_BP(i) < 1000
        time_labels{i} = sprintf('%.0f BP', years_BP(i));
    else
        time_labels{i} = sprintf('%.2f ka BP', years_BP(i)/1000);
    end
end

%% SET UP SAMPLE PARAMETERS
fprintf('\n=== LSD Scaling Factor Comparison ===\n');
fprintf('Processing %d samples with individual locations\n', n_times);
fprintf('Scaling model: LSDn (Lifton-Sato-Dunai)\n\n');

% LSD parameters
w = 0.066;          % Gravimetric water content
atm_model = 0;      % 0 = ERA-40, 1 = Standard Atmosphere

%% CALCULATE LSD SCALING FACTORS
% Strategy: Call LSD separately for each age (total: n_times × 2 calls)

fprintf('Calculating LSD scaling factors...\n');
fprintf('  Will make %d LSD calls (%d ages × 2 nuclides)\n', n_times*2, n_times);

% Create folder for LSD output files
lsd_output_folder = fullfile(pwd, 'LSD_Scaling_OutputFiles');
if ~exist(lsd_output_folder, 'dir')
    mkdir(lsd_output_folder);
    fprintf('Created folder: %s\n', lsd_output_folder);
else
    fprintf('Using existing folder: %s\n', lsd_output_folder);
end

% Load LSD constants
load(fullfile(lsd_path, 'Shared Files', 'consts_LSD.mat'));

% Storage arrays
Sel10_values = zeros(1, n_times);      % 10Be scaling at burial age
Sel14_values = zeros(1, n_times);      % 14C scaling at burial age
Sel10_modern = zeros(1, n_times);      % 10Be scaling at modern (age=0)
Sel14_modern = zeros(1, n_times);      % 14C scaling at modern (age=0)
Sel10_correction = zeros(1, n_times);  % Time-dependent correction factor for 10Be
Sel14_correction = zeros(1, n_times);  % Time-dependent correction factor for 14C

fprintf('\nCalculating scaling factors for each sample...\n');
fprintf('%-20s %10s %10s %10s %10s\n', 'Sample', '10Be Corr', '14C Corr', '10Be Scal', '14C Scal');
fprintf('%s\n', repmat('-', 1, 65));

for i = 1:n_times
    age = years_BP(i);

    % Get this sample's location and elevation
    sample_lat = sample_lats(i);
    sample_lon = sample_lons(i);
    sample_elv = sample_elvs(i);
    sample_name = sample_names{i};

    fprintf('  [%d/%d] Sample: %s (%.2f°N, %.2f°E, %d m) at %.0f years...\n', ...
        i, n_times, sample_name, sample_lat, sample_lon, sample_elv, age);

    % Calculate modern (age=0) scaling for this sample's location
    LSDout_10Be_modern = call_LSD_nointeractive(sample_lat, sample_lon, sample_elv, ...
        atm_model, 0, w, 10, fullfile(lsd_output_folder, sprintf('LSD_temp_10Be_modern_%d', i)));

    LSDout_14C_modern = call_LSD_nointeractive(sample_lat, sample_lon, sample_elv, ...
        atm_model, 0, w, 14, fullfile(lsd_output_folder, sprintf('LSD_temp_14C_modern_%d', i)));

    % Get modern scaling factors
    if isfield(LSDout_10Be_modern, 'Be')
        Sel10_modern(i) = LSDout_10Be_modern.Be(end);
    else
        error('LSDout does not contain Be scaling factors');
    end

    if isfield(LSDout_14C_modern, 'C')
        Sel14_modern(i) = LSDout_14C_modern.C(end);
    else
        error('LSDout does not contain C scaling factors');
    end

    % Calculate scaling for 10Be at burial age
    LSDout_10Be = call_LSD_nointeractive(sample_lat, sample_lon, sample_elv, ...
        atm_model, age, w, 10, fullfile(lsd_output_folder, sprintf('LSD_temp_10Be_%d', i)));

    % Get 10Be scaling factor at burial age
    if isfield(LSDout_10Be, 'Be')
        Sel10_values(i) = LSDout_10Be.Be(end);
    else
        error('LSDout does not contain Be scaling factors');
    end

    % Calculate scaling for 14C at burial age
    LSDout_14C = call_LSD_nointeractive(sample_lat, sample_lon, sample_elv, ...
        atm_model, age, w, 14, fullfile(lsd_output_folder, sprintf('LSD_temp_14C_%d', i)));

    % Get 14C scaling factor at burial age
    if isfield(LSDout_14C, 'C')
        Sel14_values(i) = LSDout_14C.C(end);
    else
        error('LSDout does not contain C scaling factors');
    end

    % Calculate time-dependent correction factor (burial age / modern)
    Sel10_correction(i) = Sel10_values(i) / Sel10_modern(i);
    Sel14_correction(i) = Sel14_values(i) / Sel14_modern(i);

    % Print results
    fprintf('%-20s %10.4f %10.4f %10.4f %10.4f\n', ...
        sample_name, Sel10_correction(i), Sel14_correction(i), ...
        Sel10_values(i), Sel14_values(i));
end

%% CALCULATE RELATIVE DIFFERENCES
fprintf('\n10Be (Age, Correction): ');
fprintf('%.0f\t%.4f\n', [years_BP(:)'; Sel10_correction(:)']);

fprintf('\n14C (Age, Correction): ');
fprintf('%.0f\t%.4f\n', [years_BP(:)'; Sel14_correction(:)']);

fprintf('\n=== Time-Dependent Correction Factors ===\n');
fprintf('%-20s %-20s %12s %12s\n', 'Sample', 'Age', '10Be Corr', '14C Corr');
fprintf('%s\n', repmat('-', 1, 70));

for i = 1:n_times
    fprintf('%-20s %-20s %12.4f %12.4f\n', sample_names{i}, time_labels{i}, ...
        Sel10_correction(i), Sel14_correction(i));
end

fprintf('\n=== Percentage Difference from Modern (at same location) ===\n');
fprintf('%-20s %-20s %12s %12s\n', 'Sample', 'Age', '10Be Diff(%)', '14C Diff(%)');
fprintf('%s\n', repmat('-', 1, 70));

for i = 1:n_times
    diff_10Be = (Sel10_correction(i) - 1.0) * 100;
    diff_14C = (Sel14_correction(i) - 1.0) * 100;

    fprintf('%-20s %-20s %+12.2f %+12.2f\n', sample_names{i}, time_labels{i}, ...
        diff_10Be, diff_14C);
end

%% SUMMARY STATISTICS
fprintf('\n=== Summary Statistics ===\n');
fprintf('10Be time correction range: %.4f to %.4f (%.1f%% variation from modern)\n', ...
    min(Sel10_correction), max(Sel10_correction), ...
    (max(Sel10_correction) - min(Sel10_correction)) / mean(Sel10_correction) * 100);
fprintf('14C time correction range:  %.4f to %.4f (%.1f%% variation from modern)\n', ...
    min(Sel14_correction), max(Sel14_correction), ...
    (max(Sel14_correction) - min(Sel14_correction)) / mean(Sel14_correction) * 100);

%% PLOTTING
figure('Position', [100, 100, 1200, 500]);

% Plot 1: Time-dependent correction factors vs time
subplot(1, 2, 1);
plot(years_BP, Sel10_correction, 'b-o', 'LineWidth', 2, 'MarkerSize', 8, ...
    'MarkerFaceColor', 'b', 'DisplayName', '^{10}Be');
hold on;
plot(years_BP, Sel14_correction, 'r-s', 'LineWidth', 2, 'MarkerSize', 8, ...
    'MarkerFaceColor', 'r', 'DisplayName', '^{14}C');
yline(1.0, 'k--', 'LineWidth', 1, 'DisplayName', 'Modern (no correction)');
hold off;

xlabel('Years Before Present (BP, relative to 2010 AD)', 'FontSize', 12);
ylabel('Time-Dependent Correction Factor', 'FontSize', 12);
title(sprintf('LSD Time Correction Factors\n%d Samples (each normalized to its own modern)', ...
    n_times), 'FontSize', 14);
legend('Location', 'best', 'FontSize', 11);
grid on;
set(gca, 'XDir', 'reverse');  % Oldest on left
xlim([0, max(years_BP) * 1.05]);

% Add sample labels
for i = 1:n_times
    if years_BP(i) > 0  % Don't label modern samples
        text(years_BP(i), Sel10_correction(i) + 0.01, sample_names{i}, ...
            'FontSize', 7, 'HorizontalAlignment', 'center', 'Rotation', 45);
    end
end

% Plot 2: Relative difference from modern (at same location)
subplot(1, 2, 2);
rel_diff_10Be = (Sel10_correction - 1.0) * 100;
rel_diff_14C = (Sel14_correction - 1.0) * 100;

% Only plot non-modern samples
non_modern_idx = years_BP > 0;
if any(non_modern_idx)
    bar_data = [rel_diff_10Be(non_modern_idx)', rel_diff_14C(non_modern_idx)'];
    bar_labels = sample_names(non_modern_idx);
    bar_x = categorical(bar_labels);
    bar_x = reordercats(bar_x, bar_labels);
else
    % If all samples are modern, show all
    bar_data = [rel_diff_10Be', rel_diff_14C'];
    bar_x = categorical(sample_names);
    bar_x = reordercats(bar_x, sample_names);
end

b = bar(bar_x, bar_data);
b(1).FaceColor = 'b';
b(2).FaceColor = 'r';

xlabel('Sample', 'FontSize', 12);
ylabel('Difference from Modern (%)', 'FontSize', 12);
title('Time-Dependent Correction (relative to modern at same location)', 'FontSize', 14);
legend({'^{10}Be', '^{14}C'}, 'Location', 'best', 'FontSize', 11);
grid on;
xtickangle(45);

% Add horizontal line at 0
hold on;
yline(0, 'k--', 'LineWidth', 1);
hold off;

sgtitle(sprintf('Time-Dependent Production Rate Corrections (LSD Scaling)\n%d Samples - Each Normalized to Its Own Modern Value', ...
    n_times), 'FontSize', 14, 'FontWeight', 'bold');



% Optionally save to file
% writetable(results_table, 'scaling_comparison_LSD_results.csv');

%% INTERPRETATION
fprintf('\n=== Interpretation ===\n');
fprintf('The time-dependent correction factors show how production rates at burial age\n');
fprintf('compare to modern production rates at THE SAME LOCATION. A correction factor:\n');
fprintf('  > 1.0 means HIGHER production at burial (weaker geomagnetic field)\n');
fprintf('  < 1.0 means LOWER production at burial (stronger geomagnetic field)\n');
fprintf('  = 1.0 means no change (modern samples or no field variation)\n\n');

if max(abs(rel_diff_10Be)) > 5
    fprintf('WARNING: Time corrections exceed 5%% for some samples.\n');
    fprintf('Time-dependent scaling corrections are important for these samples!\n');
else
    fprintf('Time corrections are relatively small (<5%%) for all samples.\n');
end

fprintf('\nNote: Each sample is normalized to its OWN modern value at its location.\n');
fprintf('This isolates the pure TIME effect (geomagnetic field changes) from\n');
fprintf('spatial effects (latitude, elevation). LSD scaling is nuclide-dependent:\n');
fprintf('  - 10Be and 14C have different energy thresholds and cross-sections\n');
fprintf('  - Correction factors will differ between nuclides\n');
fprintf('  - This is physically more accurate than single-nuclide models\n');

% Clean up temporary files (optional - comment out to keep files)
fprintf('\nNote: LSD output files are stored in: %s\n', lsd_output_folder);
fprintf('To clean up temporary files, delete this folder when no longer needed.\n');
% Uncomment the following lines to automatically delete temporary files:
% fprintf('Cleaning up temporary files...\n');
% for i = 1:n_times
%     temp_file_10Be = fullfile(lsd_output_folder, sprintf('LSD_temp_10Be_%d.mat', i));
%     temp_file_14C = fullfile(lsd_output_folder, sprintf('LSD_temp_14C_%d.mat', i));
%     temp_file_10Be_modern = fullfile(lsd_output_folder, sprintf('LSD_temp_10Be_modern_%d.mat', i));
%     temp_file_14C_modern = fullfile(lsd_output_folder, sprintf('LSD_temp_14C_modern_%d.mat', i));
%
%     if exist(temp_file_10Be, 'file')
%         delete(temp_file_10Be);
%     end
%     if exist(temp_file_14C, 'file')
%         delete(temp_file_14C);
%     end
%     if exist(temp_file_10Be_modern, 'file')
%         delete(temp_file_10Be_modern);
%     end
%     if exist(temp_file_14C_modern, 'file')
%         delete(temp_file_14C_modern);
%     end
% end

fprintf('\n=== Script Complete ===\n');

%% HELPER FUNCTION: Core LSD logic without interactive input
% This is the same as in ProductionParas_LSD.m
function LSDout = call_LSD_nointeractive(lat, lon, alt, atm, age, w, nuclide, save_name)
% Core LSD logic extracted from LSD.m without interactive input prompt

load consts_LSD;

is14 = 0;
is10 = 0;
is26 = 0;
is3 = 0;
isflux = 0;

sample.lat = lat;
sample.lon = lon;
sample.alt = alt;
sample.atm = atm;
sample.age = age;
sample.nuclide = nuclide;

if nuclide == 14
    is14 = 1;
elseif nuclide == 10
    is10 = 1;
elseif nuclide == 26
    is26 = 1;
elseif nuclide == 3
    is3 = 1;
else
    isflux = 1;
end

if sample.atm == 1
    stdatm = 1;
    gmr = -0.03417;
    dtdz = 0.0065;
else
    stdatm = 0;
end

% Make the time vector
calFlag = 0;

% Age Relative to t0=2010
tv = [0:10:50 60:100:50060 51060:1000:2000060 logspace(log10(2001060),7,200)];
LSDRc = zeros(1,length(tv));

% Need solar modulation parameter
this_SPhi = zeros(size(tv)) + consts.SPhiInf;
this_SPhi(1:120) = consts.SPhi;

if w < 0
    w = 0.066;
end

% interpolate an M for tv > 7000...
temp_M = interp1(consts.t_M, consts.M, tv(77:end));

% Pressure correction
if stdatm == 1
    sample.pressure = 1013.25 .* exp( (gmr./dtdz) .* ( log(288.15) - log(288.15 - (alt.*dtdz)) ) );
else
    sample.pressure = ERA40atm(sample.lat, sample.lon, sample.alt);
end

% catch for negative longitudes before Rc interpolation
if sample.lon < 0; sample.lon = sample.lon + 360; end

% Make up the Rc vectors.
[loni,lati,tvi] = meshgrid(sample.lon, sample.lat, tv(1:76));
LSDRc(1:76) = interp3(consts.lon_Rc, consts.lat_Rc, consts.t_Rc, consts.TTRc, loni, lati, tvi);

% Fit to Trajectory-traced GAD dipole field as f(M/M0)
dd = [6.89901,-103.241,522.061,-1152.15,1189.18,-448.004;];
LSDRc(77:end) = temp_M.*(dd(1)*cosd(sample.lat) + ...
   dd(2)*(cosd(sample.lat)).^2 + ...
   dd(3)*(cosd(sample.lat)).^3 + ...
   dd(4)*(cosd(sample.lat)).^4 + ...
   dd(5)*(cosd(sample.lat)).^5 + ...
   dd(6)*(cosd(sample.lat)).^6);

% Next, chop off tv
clipindex = find(tv <= sample.age, 1, 'last' );
tv2 = tv(1:clipindex);
if tv2(end) < sample.age
    tv2 = [tv2 sample.age];
end
% Now shorten the Rc's commensurately
LSDRc = interp1(tv, LSDRc, tv2);
LSDSPhi = interp1(tv, this_SPhi, tv2);

LSDout = LSDscaling(sample.pressure, LSDRc(:), LSDSPhi, w, consts, nuclide);
LSDout.tv = tv2;
LSDout.Rc = LSDRc;
LSDout.pressure = sample.pressure;
LSDout.alt = sample.alt;

% Save results
save(save_name, 'LSDout');

end
