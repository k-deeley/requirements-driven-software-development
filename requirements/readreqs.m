function readreqs( textRequirementsFiles )
    %READREQS Read requirements and links from disk.
    %
    % readreqs( textRequirementsFiles ) imports the flattened versions of the
    % requirements sets stored in textRequirementsFiles, together with their
    % associated link sets, then reconstructs the binary SLREQX and SLMX files
    % representing the requirements set and link sets, respectively.
    %
    % See also writereqs, rebaselinks
    
    arguments ( Input )
        textRequirementsFiles(1, :) string ...
            {mustBeFileOrEmpty} = projectTextRequirements()
    end % arguments ( Input )
    
    % Iterate over the collection of plain-text requirements sets and
    % deserialize each one.
    for fileIdx = 1 : numel( textRequirementsFiles )
        deserialize( textRequirementsFiles(fileIdx) )
    end % for
end % readreqs

function requirementsFiles = projectTextRequirements()
    %PROJECTTEXTREQUIREMENTS Return a list of flattened, plain-text
    %requirements sets within the current project. This function assumes that
    %the plain-text requirements sets are stored in the requirements folder of
    %the project in CSV format, and that the filenames end with "Requirements".
    
    % Write down a list of the plain-text requirements files within the
    % project.
    projectRoot = currentProject().RootFolder;
    plainTextRequirementsFiles = struct2table( dir( fullfile( projectRoot, ...
        "requirements", "*Requirements.csv" ) ) );
    if ~isempty(plainTextRequirementsFiles)
        requirementsFiles = string( fullfile( ...
            plainTextRequirementsFiles.folder, plainTextRequirementsFiles.name ) );
    else
        requirementsFiles = [];
    end
end % projectTextRequirements

function deserialize( textRequirementsFile )
    %DESERIALIZE Given a plain-text requirements set stored in the CSV file
    %given by textRequirementsFile, deserialize the requirements and associated
    %links. Recreate the binary SLREQX and SLMX files corresponding to the
    %requirements set and associated links, respectively.
    
    arguments ( Input )
        textRequirementsFile(1, 1) string {mustBeFile}
    end % arguments ( Input )
    
    % Import the requirements and associated links from the plain-text files.
    reqsTable = readtable( textRequirementsFile, "TextType", "string", ...
        "Format", join( repelem( "%q", 6 ) ) );
    [folder, filename] = fileparts( textRequirementsFile );
    linksFile = fullfile( folder, filename + "Links.csv" );
    linksTable = readtable( linksFile, ...
        "TextType", "string", "Delimiter", "," );
    
    % Clear.
    slreq.clear()
    
    % Create the new requirements set, deleting the old one if necessary.
    slreqxFile = fullfile( folder, filename + ".slreqx" );
    if isfile( slreqxFile )
        delete( slreqxFile )
    end % if
    reqSet = slreq.new( slreqxFile );
    
    % Iterate over the rows of the requirements table to add the individual
    % requirements.
    for reqIdx = 1 : height( reqsTable )
        % Extract the data for the current requirement.
        currentReqData = reqsTable(reqIdx, :);
        % Add a new requirement.
        req = reqSet.add();
        % Populate its properties.
        req.Id = currentReqData.Id;
        req.Type = currentReqData.Type;
        req.Description = regexprep(currentReqData.Description, '\\n', '<br>');
        req.Summary = regexprep(currentReqData.Summary, '\\n', '<br>');
        req.Rationale = regexprep(currentReqData.Rationale, '\\n', '<br>');
        % Position it within the hierarchy using its index value.
        reqLevel = count( currentReqData.Index, "." );
        for level = 1 : reqLevel
            req.demote();
        end % for
    end % for
    
    % Delete the old link set files, if necessary.
    linkFiles = unique( linksTable.Filename );
    for fileIdx = 1 : numel( linkFiles )
        if isfile( linkFiles(fileIdx) )
            delete( linkFiles(fileIdx) )
        end % if
    end % for
    
    % Iterate over the rows of the links table to add the individual links.
    proj = currentProject;
    rf = proj.RootFolder;
    for linkIdx = 1 : height( linksTable )
        % Extract the data for the current link.
        currentLinkData = linksTable(linkIdx, :);
        currentLinkData.Filename = fullfile(rf, currentLinkData.Filename);
        currentLinkData.Artifact = fullfile(rf, currentLinkData.Artifact);
        % Extract the start and end line numbers. If they coincide then the
        % line range is a single number, namely the start line number.
        startLineNumber = currentLinkData.StartLineNumber;
        endLineNumber = currentLinkData.EndLineNumber;
        if startLineNumber == endLineNumber
            lineRange = startLineNumber;
        else
            lineRange = [startLineNumber, endLineNumber];
        end % if
        % Retrieve the existing text range if it already exists.
        textRange = slreq.getTextRange( ...
            currentLinkData.Artifact, lineRange );
        if isempty( textRange )
            % Create a new text range.
            textRange = slreq.createTextRange( ...
                currentLinkData.Artifact, lineRange );
        end % if
        % Find the requirement associated with the link.
        req = reqSet.find( "Type", "Requirement", ...
            "ID", currentLinkData.RequirementID );
        if isempty( req )
            warning( "readreqs:RequirementNotFound", ...
                "Unable to find the requirement with ID " + ...
                currentLinkData.RequirementID + "." )
        else
            % Create the link and set its type.
            link = slreq.createLink( textRange, req );
            link.Type = currentLinkData.Type;
        end % if
    end % for
    
    % Save the link sets.
    linkSets = slreq.find( "Type", "LinkSet" );
    for linkSetIdx = 1 : numel( linkSets )
        linkSets(linkSetIdx).save();
    end % for
    
    % Save and close the requirements set.
    reqSet.save()
    reqSet.close()
    
    % Clear.
    slreq.clear()

end % deserialize

function isvalid = mustBeFileOrEmpty(a)
    if isempty(a)
        isvalid = true; 
        return
    end
    if isfile(a)
        isvalid = true;
        return
    end
    isvalid = false;
end