function writereqs( requirementsSets )
%WRITEREQS Export project requirements sets to plain text files.
%
% writereqs( requirementsSets ) serializes the binary SLREQX files listed
% in requirementsSets, together with their associated link sets, to a
% collection of CSV files.
%
% Example: writereqs( "PulsedSineWaveRequirements.slreqx" ) serializes the
% requirements set PulsedSineWaveRequirements.slreqx with associated link
% sets PulsedSineWave~m.slmx and tPulsedSineWave~m.slmx into CSV files
% PulsedSineWaveRequirements.csv, PulsedSineWaveLinks.csv, and
% tPulsedSineWaveLinks.csv. The CSV files are saved adjacent to the .slreqx
% and .slmx files, respectively.
%
% See also readreqs, rebaselinks

arguments ( Input )
    % Collection of requirements sets to serialize. If this argument is not
    % specified, then the default behavior is to serialize all of the
    % requirements sets within the project.
    requirementsSets(1, :) string ...
        {mustBeRequirementsSet} = projectRequirementsFiles()
end % arguments ( Input )

% Iterate over the collection of requirements sets and serialize each one.
for requirementsSetIdx = 1 : numel( requirementsSets )
    serialize( requirementsSets(requirementsSetIdx) )
end % for

end % writereqs

function mustBeRequirementsSet( files )
%MUSTBEREQUIREMENTSSET Validate that the input string array, files,
%contains a list of existing files with the slreqx extension.

arguments ( Input )
    files(1, :) string {mustBeFile}
end % arguments ( Input )

[~, ~, ext] = fileparts( files );
assert( all( ext == ".slreqx" ), ...
    "mustBeRequirementsSets:InvalidExtension", ...
    "All files must be requirements sets with the extension slreqx." )

end % mustBeRequirementsSet

function requirementsFiles = projectRequirementsFiles()
%PROJECTREQUIREMENTSFILES Return a list of requirements sets (*.slreqx)
%within the current project. This function assumes that the requirements
%sets are stored in the requirements folder of the project.

% Write down a list of the binary requirements files within the project.
projectRoot = currentProject().RootFolder;
slreqxFiles = struct2table( dir( fullfile( projectRoot, ...
    "requirements", "*.slreqx" ) ) );
requirementsFiles = string( fullfile( slreqxFiles.folder, ...
    slreqxFiles.name ) );

end % projectRequirementsFiles

function serialize( requirementsSet )
%SERIALIZE Given a requirements set requirementsSet, serialize the
%requirements and associated links it contains to CSV files.

arguments ( Input )
    requirementsSet(1, 1) string {mustBeRequirementsSet}
end % arguments ( Input )

% Clear.
slreq.clear()

% Load the requirements set.
reqSet = slreq.load( requirementsSet );

% Extract a flat array containing the individual requirements.
allReqs = reqSet.find( "Type", "Requirement" );

% Temporarily disable the object to structure conversion warning.
warningID = "MATLAB:structOnObject";
warningState = warning( "query", warningID );
warning( "off", warningID )
warningCleanup = onCleanup( @() warning( warningState ) );

% Convert each requirement to a structure, saving the results in a
% structure array.
for reqIdx = numel( allReqs ) : -1 : 1
    reqsStruct(reqIdx) = struct( allReqs(reqIdx) );
end % for

% Convert the structure array to a table.
reqsTable = struct2table( reqsStruct, "AsArray", true );

% Extract only the required table variables.
reqsTable = reqsTable(:, ["Index", "Id", "Type", ...
    "Summary", "Description", "Rationale"]);

% Now clean out the RTF format if the user has made manual changes in the
% Requirements Editor
reqsTable.Summary = stripRTF (reqsTable.Summary);
reqsTable.Description = stripRTF (reqsTable.Description);
reqsTable.Rationale = stripRTF (reqsTable.Rationale);


% Serialize the requirement set using a plain text file.
[reqsPath, reqsFilename] = fileparts( requirementsSet );
reqsOutputFilename = fullfile( reqsPath, reqsFilename + ".csv" );
writetable( reqsTable, reqsOutputFilename )

% Repeat this process for the corresponding link sets. First, find the
% associated link sets for the requirements set. There should be two of
% these: one for the source code, and one for the corresponding tests.
linkSets = slreq.find( "Type", "LinkSet" );

% Preallocate space for a table to contain the results.
linksTable = table( 'Size', [0, 6], ...
    'VariableTypes', ...
    ["string", "string", "string", "string", "double", "double"], ...
    'VariableNames', ["Filename", "Artifact", "RequirementID", "Type", ...
    "StartLineNumber", "EndLineNumber"] );
for linkSetIdx = 1 : numel( linkSets )
    % Extract the current set of links.
    linkSet = linkSets(linkSetIdx);
    links = linkSet.getLinks();
    artifact = string( linkSet.Artifact);
    filename = string( linkSet.Filename );
    % Store the data for each link in one row of the table.
    for linkIdx = 1 : numel( links )
        % Identify the text range corresponding to the current link
        % within the source code file.
        link = links(linkIdx);
        linkSource = slreq.structToObj( link.source() );
        textRange = linkSource.getLineRange();
        % Append the data for the current link to the main table.
        linksTable(end+1, :) = {filename, artifact, ...
            string( link.destination().id ), ...
            string( link.Type ), ...
            textRange(1), textRange(2) }; %#ok<AGROW>
    end % for
end % for

% Serialize the link sets using a plain text file.
linksOutputFilename = fullfile( reqsPath, reqsFilename + "Links.csv" );
% Now make sure all file paths are relative to the project root folder
proj = currentProject;
if ~isempty(proj)
    rf = proj.RootFolder;
    linksTable.Filename = strrep(linksTable.Filename,rf,'.');
    linksTable.Artifact = strrep(linksTable.Artifact,rf,'.');
end
writetable( linksTable, linksOutputFilename )

% Ensure that the requirements set gets closed. This also closes the
% associated link sets.
reqSet.close()

% Clear.
slreq.clear()

end % serialize

function str = stripRTF(rtf)
    % Removes <br /> or <br> tags replace with \n
    tmpstr = regexprep(rtf,'<br />','\\n');
    tmpstr = regexprep(tmpstr,'<br>','\\n');
    % Removes HTML <> tags...
    tmpstr = regexprep(tmpstr,'<.*?>','');
    % Remove all between { }
    tmpstr = regexprep(tmpstr, '{.*?}', '');
    % Remove dangling p, li
    tmpstr = regexprep(tmpstr, 'p, li', '');
    % Replace newline with \n
    tmpstr = regexprep(tmpstr, '\n', '\\n');
    % Remove leading whitespace
    tmpstr = regexprep(tmpstr, '^[\s*|\\n]+', '');
    str = tmpstr;
end     