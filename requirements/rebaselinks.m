function rebaselinks( textLinkFiles )
%REBASELINKS Rebase link sets to the current project.
%
% rebaselinks( textLinkFiles ) imports the flattened versions of the link
% sets stored in textLinkFiles, rebases the link paths (sources and
% artifacts) relative to the current project, then exports the rebased
% links to the same locations. The binary SLREQX and SLMX files
% representing the requirements and links sets, respectively, can then be 
% reconstructed using readreqs.
%
% See also readreqs, writereqs

arguments ( Input )
    % Collection of link sets to import. If this argument is not specified,
    % then the default behavior is to the import all of the flattened link
    % sets within the project.
    textLinkFiles(1, :) string {mustBeFile} = projectTextLinks()
end % arguments ( Input )

% Iterate over the collection of plain-text link sets and rebase each one.
for fileIdx = 1 : numel( textLinkFiles )
    rebase( textLinkFiles(fileIdx) )
end % for

end % rebaselinks

function linkFiles = projectTextLinks()
%PROJECTTEXTLINKS Return a list of flattened, plain-text link sets within
%the current project. This function assumes that the plain-text link sets
%are stored in the requirements folder of the project in CSV format, and
%that the filenames end with "Links".

% Write down a list of the plain-text link files within the project.
projectRoot = currentProject().RootFolder;
plainTextLinkFiles = struct2table( dir( fullfile( projectRoot, ...
    "requirements", "*Links.csv" ) ) );
linkFiles = string( fullfile( ...
    plainTextLinkFiles.folder, plainTextLinkFiles.name ) );

end % projectTextLinks

function rebase( textLinkFile )
%REBASE Given a plain-text link set stored in the CSV file given by
%textLinkFile, rebase the source and artifact file paths to the current
%project. This is needed if the project is moved to a new location (e.g.,
%when the project is transferred to a different folder on the same computer
%or when receiving a project from another user).

% Import the link set.
linksTable = readtable( textLinkFile, "FileType", "text", ...
    "TextType", "string", ...
    "VariableNamingRule", "preserve", ...
    "Delimiter", "," );

% Write down the unique binary SLMX files and corresponding code or test
% artifacts.
slmxFiles = unique( linksTable.Filename, "stable" );
artifacts = unique( linksTable.Artifact, "stable" );

% Check that the number of SLMX files is equal to the number of artifacts.
assert( numel( slmxFiles ) == numel( artifacts ), ...
    "rebaselinks:InconsistentCSVLinkSet", ...
    "The number of binary SLMX files does not match the number of " + ...
    "artifacts in the plain-text link set " + textLinkFile + "." )

% Obtain a list of all file paths within the project.
project = currentProject();
projectFilePaths = vertcat( project.Files.Path );
newProjectRoot = project.RootFolder;

% Separate the binary filename from the full path.
[~, slmxFile, slmx] = fileparts( slmxFiles(1) );
slmxFilename = slmxFile + slmx;

% Find where this file exists in the current project.
slmxIdx = endsWith( projectFilePaths, slmxFilename );
slmxFileInNewProject = projectFilePaths(slmxIdx);

% Error if multiple files with the same name are found.
assert( isscalar( slmxFileInNewProject ), ...
    "rebaselinks:NonUniqueFile", ...
    "Detected multiple project files named " + slmxFilename + "." )

% Determine the old project root.
oldProjectRoot = erase( slmxFiles(1), ...
    erase( slmxFileInNewProject, newProjectRoot ) );

% Replace the old project root with the new project root in the link set.
linksTable.Filename = replace( linksTable.Filename, ...
    oldProjectRoot, newProjectRoot );
linksTable.Artifact = replace( linksTable.Artifact, ...
    oldProjectRoot, newProjectRoot );

% Write the new link set to disk, replacing the old one.
writetable( linksTable, textLinkFile )

end % rebase