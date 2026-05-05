% Test script to verify wrapper installation and basic functionality
%
% This script tests:
% 1. Path setup
% 2. Function availability
% 3. Basic wrapper functionality
% 4. CRONUS scheme (should always work)
% 5. LSD scheme availability
%
% Created 2026

function test_wrapper_installation()

clc
fprintf('\n========================================\n');
fprintf('Testing Production Scheme Wrapper\n');
fprintf('========================================\n\n');

% Test counter
n_tests = 0;
n_passed = 0;

%% TEST 1: Path Setup
n_tests = n_tests + 1;
fprintf('[TEST %d] Checking path setup...\n', n_tests);
try
    addpath '.\subroutines'
    addpath '.\InputData'
    fprintf('  ✓ Paths added successfully\n');
    n_passed = n_passed + 1;
catch ME
    fprintf('  ✗ FAILED: %s\n', ME.message);
end

%% TEST 2: Core Function Availability
n_tests = n_tests + 1;
fprintf('[TEST %d] Checking core functions...\n', n_tests);

required_functions = {
    'ProductionParas_wrapper', ...
    'ProductionParas_CRONUS', ...
    'ProductionParas_LSD', ...
    'compare_production_schemes'
};

all_found = true;
for i = 1:length(required_functions)
    func_name = required_functions{i};
    if exist(func_name, 'file') == 2
        fprintf('  ✓ %s found\n', func_name);
    else
        fprintf('  ✗ %s NOT FOUND\n', func_name);
        all_found = false;
    end
end

if all_found
    n_passed = n_passed + 1;
end

%% TEST 3: LSD Code Availability
n_tests = n_tests + 1;
fprintf('[TEST %d] Checking LSD code availability...\n', n_tests);

lsd_path = fullfile('LSD MATLAB Code');
if exist(lsd_path, 'dir') == 7
    fprintf('  ✓ LSD MATLAB Code directory found\n');

    % Check for key LSD files
    lsd_files = {'LSDscaling.m', 'P_mu_totalLSD.m'};
    lsd_ok = true;
    for i = 1:length(lsd_files)
        file_path = fullfile(lsd_path, lsd_files{i});
        if exist(file_path, 'file') == 2
            fprintf('    ✓ %s found\n', lsd_files{i});
        else
            fprintf('    ✗ %s NOT FOUND\n', lsd_files{i});
            lsd_ok = false;
        end
    end

    % Check for consts_LSD.mat
    consts_path = fullfile(lsd_path, 'Shared Files', 'consts_LSD.mat');
    if exist(consts_path, 'file') == 2
        fprintf('    ✓ consts_LSD.mat found\n');
    else
        fprintf('    ✗ consts_LSD.mat NOT FOUND\n');
        lsd_ok = false;
    end

    if lsd_ok
        n_passed = n_passed + 1;
    end
else
    fprintf('  ✗ LSD MATLAB Code directory NOT FOUND\n');
    fprintf('    (LSD scheme will not be available)\n');
end

%% TEST 4: Wrapper Basic Functionality
n_tests = n_tests + 1;
fprintf('[TEST %d] Testing wrapper basic functionality...\n', n_tests);

try
    % Create minimal test parameters
    para = create_test_parameters();

    % Test wrapper accepts valid scheme names
    try
        Prod_test = ProductionParas_wrapper(para, '10Be', 'cronus');
        fprintf('  ✓ Wrapper accepts ''cronus'' scheme\n');

        if isfield(Prod_test, 'scheme') && strcmp(Prod_test.scheme, 'cronus')
            fprintf('  ✓ Scheme metadata correctly set\n');
            n_passed = n_passed + 1;
        else
            fprintf('  ✗ Scheme metadata not set correctly\n');
        end
    catch ME
        fprintf('  ✗ FAILED: %s\n', ME.message);
    end
catch ME
    fprintf('  ✗ FAILED to create test parameters: %s\n', ME.message);
end

%% TEST 5: Data File Availability
n_tests = n_tests + 1;
fprintf('[TEST %d] Checking for input data files...\n', n_tests);

data_files = {
    fullfile('InputData', '10Be_data_CRONUS.xlsx'), ...
    fullfile('InputData', 'Burialmodels.xlsx')
};

data_ok = true;
for i = 1:length(data_files)
    if exist(data_files{i}, 'file') == 2
        fprintf('  ✓ %s found\n', data_files{i});
    else
        fprintf('  ✗ %s NOT FOUND\n', data_files{i});
        data_ok = false;
    end
end

if data_ok
    n_passed = n_passed + 1;
end

%% SUMMARY
fprintf('\n========================================\n');
fprintf('Test Summary: %d/%d tests passed\n', n_passed, n_tests);
fprintf('========================================\n\n');

if n_passed == n_tests
    fprintf('✓ All tests passed! Installation successful.\n');
    fprintf('  You can now use:\n');
    fprintf('    - postburial_prod_wrapper.m (for single scheme)\n');
    fprintf('    - run_parallel_production_test.m (for comparison)\n\n');
elseif n_passed >= 4
    fprintf('⚠ Most tests passed. System should work with some limitations.\n');
    if ~exist(lsd_path, 'dir')
        fprintf('  Note: LSD scheme not available (directory not found)\n');
    end
    fprintf('  CRONUS scheme should work normally.\n\n');
else
    fprintf('✗ Installation incomplete. Please check:\n');
    fprintf('  1. All files are in correct locations\n');
    fprintf('  2. Paths are set up correctly\n');
    fprintf('  3. Required data files are present\n\n');
end

end

function para = create_test_parameters()
    % Create minimal parameter structure for testing

    para.latitude = 45.0;      % degrees N
    para.longitude = -110.0;   % degrees E
    para.altitude = 1500;      % meters
    para.depth = [0; 10; 20];  % cm
    para.depth_uncert = [1; 1; 1];
    para.age = [1000; 2000; 3000];  % years
    para.age_uncert = [100; 200; 300];
    para.rho = 2.7;  % g/cm³

    % Mock num array with enough elements for CRONUS functions
    para.num = zeros(1, 60);
    para.num(1) = para.latitude;
    para.num(2) = para.longitude;
    para.num(3) = para.altitude;

end
