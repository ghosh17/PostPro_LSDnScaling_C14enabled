% Script to run parallel testing of CRONUS vs LSD production schemes
%
% This script:
% 1. Loads sample data
% 2. Runs production calculations with both schemes
% 3. Compares results and generates diagnostics
% 4. Saves comparison report
%
% Created 2026

clc
clear
close all

addpath '.\subroutines'
addpath '.\InputData'

fprintf('========================================\n');
fprintf('Parallel Production Scheme Testing Tool\n');
fprintf('========================================\n\n');

%% USER CONFIGURATION

% Choose nuclide
nuclide = '10Be';       % Choose '10Be' or '36Cl'

% Choose scaling model for CRONUS
global scaling_model
scaling_model = 'lm';   % choose your scaling model, nomenclature follows Cronus

% Load sample data
fprintf('Loading sample data...\n');
if strcmp(nuclide, '10Be')
    [num,txt,~] = xlsread('10Be_data_CRONUS','Matlab Postburial');
    [burial,burialtxt,~] = xlsread('Burialmodels','10Be_Model1');
else
    [num,txt,~] = xlsread('36Cl_data_CRONUS.xlsx','Matlab Postburial');
    [burial,burialtxt,~] = xlsread('Burialmodels','36Cl_Model1');
end

% Choose sample
sample = 5; % row of sample in input sheet

fprintf('Assigning data for sample %d...\n', sample);
[Model,Para] = assignData(num,txt,burial,burialtxt,nuclide,sample);

fprintf('Sample loaded successfully.\n\n');

%% RUN PARALLEL COMPARISON

% Set up comparison options
options = struct();
options.plot = true;              % Generate comparison plots
options.save_results = true;       % Save results to file
options.output_file = sprintf('comparison_%s_sample%d_%s.mat', ...
    nuclide, sample, datestr(now,'yyyymmdd_HHMMSS'));

% Run the comparison
fprintf('Starting parallel production scheme comparison...\n\n');
comparison = compare_production_schemes(Para, nuclide, options);

%% GENERATE REPORT

fprintf('\n========================================\n');
fprintf('Generating Comparison Report\n');
fprintf('========================================\n\n');

% Create text report
report_file = sprintf('comparison_report_%s_sample%d_%s.txt', ...
    nuclide, sample, datestr(now,'yyyymmdd_HHMMSS'));

fid = fopen(report_file, 'w');

fprintf(fid, 'Production Scheme Comparison Report\n');
fprintf(fid, '===================================\n\n');
fprintf(fid, 'Date: %s\n', datestr(now));
fprintf(fid, 'Nuclide: %s\n', nuclide);
fprintf(fid, 'Sample: %d\n', sample);
fprintf(fid, 'CRONUS Scaling Model: %s\n\n', scaling_model);

fprintf(fid, 'Schemes Compared:\n');
fprintf(fid, '  1. %s\n', comparison.cronus.scheme_full_name);
fprintf(fid, '  2. %s\n\n', comparison.lsd.scheme_full_name);

fprintf(fid, 'Computation Time:\n');
fprintf(fid, '  CRONUS: %.2f seconds\n', comparison.timing.cronus);
fprintf(fid, '  LSD:    %.2f seconds\n', comparison.timing.lsd);
fprintf(fid, '  Speedup: %.2fx\n\n', comparison.timing.cronus/comparison.timing.lsd);

if ~isempty(comparison.statistics)
    fprintf(fid, 'Statistical Comparison:\n');
    fprintf(fid, '-----------------------\n\n');

    field_names = fieldnames(comparison.statistics);
    for i = 1:length(field_names)
        field = field_names{i};
        if isstruct(comparison.statistics.(field))
            s = comparison.statistics.(field);
            fprintf(fid, '%s Production:\n', s.name);
            fprintf(fid, '  Mean Ratio (CRONUS/LSD):  %.6f\n', s.mean_ratio);
            fprintf(fid, '  Median Ratio:             %.6f\n', s.median_ratio);
            fprintf(fid, '  Ratio Range:              [%.6f, %.6f]\n', s.min_ratio, s.max_ratio);
            fprintf(fid, '  Mean %% Difference:        %.3f%%\n', s.mean_pct_diff);
            fprintf(fid, '  Median %% Difference:      %.3f%%\n', s.median_pct_diff);
            fprintf(fid, '  Correlation:              %.6f\n', s.correlation);
            fprintf(fid, '  RMS Error:                %.6e\n\n', s.rms_error);
        end
    end
end

fprintf(fid, '\nInterpretation Guidelines:\n');
fprintf(fid, '--------------------------\n');
fprintf(fid, '  - Ratio close to 1.0: schemes agree well\n');
fprintf(fid, '  - Correlation close to 1.0: similar spatial/temporal patterns\n');
fprintf(fid, '  - %% Difference: quantifies average disagreement\n');
fprintf(fid, '  - RMS Error: overall magnitude of differences\n\n');

fprintf(fid, 'Recommendations:\n');
fprintf(fid, '----------------\n');
if ~isempty(comparison.statistics) && isfield(comparison.statistics, 'total')
    if abs(comparison.statistics.total.mean_pct_diff) < 5
        fprintf(fid, '  Schemes show GOOD AGREEMENT (<%5%% difference)\n');
        fprintf(fid, '  Either scheme can be used with confidence.\n');
    elseif abs(comparison.statistics.total.mean_pct_diff) < 15
        fprintf(fid, '  Schemes show MODERATE AGREEMENT (5-15%% difference)\n');
        fprintf(fid, '  Consider impact on your specific application.\n');
    else
        fprintf(fid, '  Schemes show SIGNIFICANT DIFFERENCES (>15%%)\n');
        fprintf(fid, '  Carefully evaluate which scheme is more appropriate.\n');
        fprintf(fid, '  Consider sensitivity analysis with both schemes.\n');
    end
end

fclose(fid);

fprintf('Report saved to: %s\n', report_file);
fprintf('\nComparison complete!\n');
fprintf('========================================\n\n');

%% HELPER: Display key findings

if ~isempty(comparison.statistics) && isfield(comparison.statistics, 'total')
    fprintf('\nKEY FINDINGS:\n');
    fprintf('-------------\n');
    fprintf('Overall production rate ratio: %.3f (CRONUS/LSD)\n', ...
        comparison.statistics.total.mean_ratio);
    fprintf('Average difference: %.2f%%\n', comparison.statistics.total.mean_pct_diff);
    fprintf('Correlation: %.4f\n', comparison.statistics.total.correlation);

    if comparison.statistics.total.correlation > 0.95
        fprintf('=> Strong correlation: schemes follow similar patterns\n');
    end

    if abs(comparison.statistics.total.mean_pct_diff) < 10
        fprintf('=> Good agreement: less than 10%% average difference\n');
    else
        fprintf('=> Notable differences: consider implications for your analysis\n');
    end
end
