function suite = createTestSuiteFromRequirements( links )
%CREATETESTSUITEFROMREQUIREMENTS Create a test suite from a set of
%requirements. The requirements are selected if they are impacted by
%changes to a link source or destination across the given set of links.
%
% See also matlab.unittest.TestSuite.fromRequirements

arguments ( Input )
    links(:, 1) slreq.Link
end % arguments ( Input )

% Identify all requirements that are impacted by changes to the link source
% or destination.
impactedRequirements = slreq.Requirement.empty( 0, 1 );
for n = 1 : length( links ) % Loop over all links
    link = links(n);        % Current link
    if link.hasChangedSource() % Has the link source changed?
        % Find and record the corresponding requirement.
        if isfield( link.source, "sid" )
            req = slreq.find( "Type", "Requirement", ...
                "SID", link.source.sid );
            impactedRequirements(end+1) = req; %#ok<*AGROW>
        end % if
    end % if
    if link.hasChangedDestination() % Has the link destination changed?
        % Find and record the corresponding requirement.
        if isfield( link.destination, "sid" )
            req = slreq.find( "Type", "Requirement", ...
                "SID", link.destination.sid );
            impactedRequirements(end+1) = req;
        end % if
    end % if
end % for

% Create and run a test suite from the impacted requirements.
suite = matlab.unittest.TestSuite.fromRequirements( impactedRequirements );

end % createTestSuiteFromRequirements