function plan = buildfile()
%BUILDFILE Build file for the requirements-driven testing with MATLAB
%project.

% Create the build plan - this is a sequence of tasks executed by the build
% automation.
%
% Notes:
% * localfunctions returns a cell array of function handles to all local
%   functions.
% * buildplan filters this list for functions ending in "Task".
plan = buildplan( localfunctions() );

% Use a MATLAB-provided task to check for any code issues within the
% project.
rootFolder = plan.RootFolder;
plan("assertNoCodeIssues") = matlab.buildtool.tasks.CodeIssuesTask( ...
    rootFolder, ...
    "Description", ...
    "Check that we have no Code Analyzer warnings or errors.", ...
    "IncludeSubfolders", true, ... % Check recursively
    "ErrorThreshold", 0, ... % Enforce no Code Analyzer error messages
    "WarningThreshold", 0 ); % Same, but for warnings

% Use a MATLAB-provided task to run the unit tests within the project.
codeFolder = fullfile( rootFolder, "code" );
coveragePath = fullfile( rootFolder, "reports", "Coverage.html" );
plan("assertTestSuccess") = matlab.buildtool.tasks.TestTask( ...
    rootFolder, ...
    "Description", "Run all project tests and assert that they pass.", ...
    "Strict", true, ...
    "SourceFiles", codeFolder, ...
    "CodeCoverageResults", coveragePath, ...
    "OutputDetail", "none" );

% Set the dependencies between the tasks.
coreTasks = ["verifyProjectIntegrity", "assertNoCodeIssues", ...
    "assertTestSuccess"];
plan("assertNoCodeIssues").Dependencies = "verifyProjectIntegrity";
plan("assertTestSuccess").Dependencies = "assertNoCodeIssues";
plan("serializeRequirements").Dependencies = coreTasks;
plan("deserializeRequirements").Dependencies = coreTasks;
plan("generateRequirementsReport").Dependencies = coreTasks;

% Set the default tasks in the plan.
plan.DefaultTasks = ["verifyProjectIntegrity", ...
    "assertNoCodeIssues", "assertTestSuccess"];

end % buildfile

function serializeRequirementsTask( ~ )
%Convert binary requirements sets and link sets to CSV files.

% See writereqs for further details.
writereqs()

end % serializeRequirementsTask

function deserializeRequirementsTask( ~ )
%Convert CSV files containing requirements sets and link sets to binary
%files (.SLREQX and .SLMX).

% See readreqs for further details.
readreqs()

end % deserializeRequirementsTask

function verifyProjectIntegrityTask( context )
%Verify the integrity of the current MATLAB project.

% Obtain a reference to the current project.
rootFolder = context.Plan.RootFolder;
prj = openProject( rootFolder );

% Update any project dependencies (some checks rely on the Dependency
% Analysis being complete).
prj.updateDependencies()

% Run the project checks.
results = prj.runChecks();

% Assert that all checks have passed.
passed = [results.Passed];
assert( all( passed ), "buildfile:ProjectCheckFailed", ...
    "At least one project integrity check failed." )

end % verifyProjectIntegrityTask

function generateRequirementsReportTask( context )
%Generate a report covering the project requirements and links.

% Load the necessary requirements sets (needed for report generation).
rootFolder = context.Plan.RootFolder;
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
reportOptions.reportPath = char( fullfile( rootFolder, ...
    "reports", "RequirementsStatus.docx" ) ); % Can be a string in R2024a
reportOptions.includes.emptySections = true;

% Generate the report and tidy up.
slreq.generateReport( requirementsSets, reportOptions );
slreq.clear() % Unload requirements sets from memory

end % generateRequirementsReportTask