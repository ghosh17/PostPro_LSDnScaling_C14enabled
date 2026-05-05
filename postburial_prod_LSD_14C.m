% Wrapper-enabled version of postburial_prod script
% This version allows choosing between CRONUS and LSD production schemes
%
% Modified from original postburial_prod.m to use production scheme wrapper
% Created 2026

clc
clear
close all

% 1. Add other dependencies first (or to the bottom)
addpath(genpath(fullfile(pwd, 'cronus-calc')), '-end');

addpath(genpath(pwd), '-end'); % This adds the whole project to the end

% 2. Add subroutines LAST with '-begin' to ensure they are at the very TOP
% This gives them higher priority than everything except the "Current Folder"
addpath('.\subroutines', '-begin');

%% USER CHOICE ----------------------------------------------------------- %

% Choose production scheme: 'cronus' or 'lsd'


% production_scheme = 'lsd';  % Options: 'cronus' (default) or 'lsd'

global scaling_model

scaling_model = 'lsd';   % choose your scaling model, nomenclature follows Cronus. lsd, lm, li, st, etc

sample = 9; % row of sample in input sheet

nuclide = '14C';       % Choose '10Be' or '36Cl' or '14C'

n = 5e2;                % number of runs

if strcmpi(scaling_model, 'lsd')
    production_scheme = 'lsd';
else
    production_scheme = 'cronus';
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOAD DATA

% Load sample data in Cronus excel format
if strcmp(nuclide, '10Be')
    [num,txt,~] = xlsread('10Be_data_CRONUS','Matlab Postburial');
    [burial,burialtxt,~] = xlsread('Burialmodels','10Be_Model1');
elseif strcmp(nuclide, '14C')
    [num,txt,~] = xlsread('14C_data_CRONUS','Matlab Postburial');
    [burial,burialtxt,~] = xlsread('Burialmodels','14C_Model1');
else
    [num,txt,~] = xlsread('36Cl_data_CRONUS.xlsx','Matlab Postburial');
    [burial,burialtxt,~] = xlsread('Burialmodels','36Cl_Model1');
end



Perr = Puncerts(nuclide); % load uncertainties for production parameters


[Model,Para] = assignData(num,txt,burial,burialtxt,nuclide,sample);

fprintf('Sample name selected: %s\n', Para.name{1});

%% PRODUCTION RATES ----------------------------------------------------- %

fprintf('\n========================================\n');
fprintf('Using production scheme: %s\n', upper(production_scheme));
fprintf('========================================\n\n');

% Use wrapper to calculate production rates
Prod = ProductionParas_wrapper(Para, nuclide, production_scheme);

fprintf('Production scheme: %s\n', Prod.scheme_full_name);
fprintf('Maximum age: %.0f years\n', Prod.max_age);

%% RUN FORWARD MODELS --------------------------------------------------- %

Model = postburial_calc(Perr,Para,Model,Prod,nuclide,n,'plot');

fprintf('\nForward models completed successfully.\n');
fprintf('Production scheme used: %s\n', Prod.scheme_full_name);
