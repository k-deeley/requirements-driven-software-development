%% Determine input argument types.
generateWaveTypes = coder.getArgTypes( ...
    "SampleWaveGeneration.m", "generateWave.m" );

%% Define configuration object for code generation.
config = coderConfiguration();

%% Generate code.
codegen generateWave -config config -args generateWaveTypes -c ...
    -d code\codegen\ -launchreport