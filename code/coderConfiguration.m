function config = coderConfiguration()
%CODERCONFIGURATION Define custom code generation configuration.

arguments ( Output )
    config(1, 1) coder.EmbeddedCodeConfig
end % arguments ( Output )

config = coder.config( "lib", "ecoder", true );
config.EnableOpenMP = false;
config.InstructionSetExtensions = "None";
config.ReqsInCode = true;

end % coderConfiguration