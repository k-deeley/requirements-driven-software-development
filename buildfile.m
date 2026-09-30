function plan = buildfile()
%BUILDFILE Build file for the "Best Practices for Requirements-Driven
% Software Development with MATLAB" project.

% Copyright 2025 The MathWorks, Inc.

% Define the build plan.
plan = buildplan( localfunctions() );

% Run code generation and requirements reporting by default.
plan.DefaultTasks = ["codegen", "reportreqs"];

% Add a test task to run the unit tests for the project. Generate and save
% a coverage report.
projectRoot = plan.RootFolder;
testsFolder = fullfile( projectRoot, "tests" );
codeFolder = fullfile( projectRoot, "code" );
reportsFolder = fullfile( projectRoot, "reports" );
if ~isfolder( reportsFolder )
    mkdir( reportsFolder )
end % if
coverageReport = matlabtest.plugins.codecoverage.StandaloneReport( ...
    fullfile( reportsFolder, "Coverage.html" ) );
testTask = matlab.buildtool.tasks.TestTask( testsFolder, ...
    "Strict", true, ...
    "Description", "Assert that all project tests pass.", ...
    "SourceFiles", codeFolder, ...
    "OutputDetail", "verbose" );
plan("test") = testTask.addCodeCoverage( coverageReport );

% The MEX-generation task depends on the check task.
plan("mex").Dependencies = "check";

% The test task depends on the MEX and report setup tasks.
plan("test").Dependencies = ["mex", "setupreports"];

% The code generation task depends on the test task.
plan("codegen").Dependencies = "test";

% The archive task depends on the test task.
plan("archive").Dependencies = "test";

% The requirements-related tasks depend on the test task.
plan("writereqs").Dependencies = "test";
plan("readreqs").Dependencies = "test";
plan("reportreqs").Dependencies = "test";

end % buildfile

function checkTask( context )
% Check the source code and project for any issues.

% Set the project root as the folder in which to check for any static code
% issues.
projectRoot = context.Plan.RootFolder;
codeIssuesTask = matlab.buildtool.tasks.CodeIssuesTask( projectRoot, ...
    "IncludeSubfolders", true, ...
    "Configuration", "factory", ...
    "Description", ...
    "Assert that there are no code issues in the project.", ...
    "WarningThreshold", 0 );
codeIssuesTask.analyze( context )

% Update the project dependencies.
prj = currentProject();
prj.updateDependencies()

% Run the checks.
checkResults = table( prj.runChecks() );

% Log any failed checks.
passed = checkResults.Passed;
notPassed = ~passed;
if any( notPassed )
    disp( checkResults(notPassed, :) )
else
    fprintf( "** All project checks passed.\n\n" )
end % if

% Check that all checks have passed.
assert( all( passed ), "buildfile:ProjectIssue", ...
    "At least one project check has failed. " + ...
    "Resolve the failures shown above to continue." )

end % checkTask

function setupreportsTask( context )
% Create the reports folder used by build tasks.

reportsFolder = fullfile( context.Plan.RootFolder, "reports" );
if ~isfolder( reportsFolder )
    mkdir( reportsFolder )
end % if

end % setupreportsTask

function writereqsTask( ~ )
%Serialize binary requirements sets and link sets to CSV files.

% See writereqs for further details.
writereqs()

end % writereqsTask

function readreqsTask( ~ )
% Create binary requirements and link sets from CSV files.

% See readreqs for further details.
readreqs()

end % readreqsTask

function reportreqsTask( context )
% Generate a report describing the project requirements and links.

% Load the necessary requirements sets (needed for report generation).
rootFolder = context.Plan.RootFolder;
reportsFolder = fullfile( rootFolder, "reports" );
requirementsFolder = fullfile( rootFolder, "requirements" );
requirementsInfo = struct2table( dir( fullfile( requirementsFolder, ...
    "*.slreqx" ) ) );
requirementsFilenames = fullfile( requirementsInfo.folder, ...
    requirementsInfo.name );
for k = 1 : numel( requirementsFilenames )
    requirementsSets(k) = slreq.load( requirementsFilenames{k} ); %#ok<AGROW>
end % for

% Configure the report options.
reportOptions = slreq.getReportOptions();
reportOptions.reportPath = char( fullfile( reportsFolder, ...
    "RequirementsStatus.docx" ) );
reportOptions.includes.emptySections = true;

% Generate the report and tidy up.
slreq.generateReport( requirementsSets, reportOptions );
slreq.clear() % Unload requirements sets from memory

end % reportreqsTask

function mexTask( context )
% Build a MEX-function from the signal processing algorithms.

outputFolder = fullfile( context.Plan.RootFolder, "code", "codegen" );
mexPath = fullfile( context.Plan.RootFolder, "code", "generateWave_mex" );
mexConfig = coder.config( "mex" );
mexConfig.GenerateReport = true;
codegen( "generateWave", "-config", mexConfig, ...
    "-args", num2cell( ones( 1, 7 ) ), ...
    "-d", outputFolder, ...
    "-o", mexPath )

end % mexTask

function codegenTask( context )
% Generate C code from the signal processing algorithms.

outputFolder = fullfile( context.Plan.RootFolder, "code", "codegen" );
codegen( "generateWave", "-config", coderConfiguration(), ...
   "-args", num2cell( ones( 1, 7 ) ), ...
   "-c", ...
   "-d", outputFolder )

end % codegenTask

function archiveTask( ~ )
% Archive the project.

proj = currentProject();
projectRoot = proj.RootFolder;
exportName = fullfile( projectRoot, "Requirements.mlproj" );
proj.export( exportName )

end % archiveTask
