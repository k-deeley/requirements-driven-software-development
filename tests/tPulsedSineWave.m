classdef tPulsedSineWave < matlabtest.coder.TestCase
    %TPULSEDSINEWAVE Unit tests for the PulsedSineWave class.

    properties ( Access = private )
        % Wave generator.
        WaveGenerator(:, 1) PulsedSineWave {mustBeScalarOrEmpty}
    end % properties ( Access = private )

    methods ( TestClassSetup )

        function tConstructorIsWarningFree( testCase )

            testCase.fatalAssertWarningFree( @PulsedSineWave, ...
                "The 'PulsedSineWave' constructor was not warning-free." )

        end % tConstructorIsWarningFree

    end % methods ( TestClassSetup )

    methods ( TestMethodSetup )
        
        function setupWaveGenerator( testCase )

            testCase.WaveGenerator = PulsedSineWave();

        end % setupWaveGenerator

    end % methods ( TestMethodSetup )

   methods ( Test )

       function tEquivalenceOfGeneratedCode( testCase )

           % Generate C code.           
           buildResults = testCase.build( "generateWave", ...
               "Inputs", {1, 1, 1, 1, 1, 1, 1} );

           % Execute the generated code via a MEX-function.
           executionResults = testCase.execute( buildResults );

           % Verify the equivalence of the generated code and the original
           % algorithm.
           testCase.verifyExecutionMatchesMATLAB( executionResults )

       end % tEquivalenceOfGeneratedCode   

    end % methods ( Test )    

end % classdef