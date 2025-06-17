classdef tPulsedSineWave < matlabtest.coder.TestCase
    %TPULSEDSINEWAVE Unit tests for the PulsedSineWave class.

    properties ( TestParameter )
        % Wave parameter names.
        WaveParameter = {"Amplitude", "Frequency", "Phase", "Duration", ...
            "PulseRate", "Duty", "SampleRate"}
    end % properties ( TestParameter )

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

        function tWaveParametersAreSettable( testCase, WaveParameter )

            % Ensure that setting each configurable wave parameter is
            % warning-free.
            f = @() setWaveParameter( WaveParameter );
            testCase.verifyWarningFree( f, "Setting the " + ...
                WaveParameter + " parameter was not warning-free." )

            function setWaveParameter( WaveParameter )

                testCase.WaveGenerator.(WaveParameter) = 1;

            end % setWaveParameter

        end % tWaveParametersAreSettable

        function tTimeStepIsComputedCorrectly( testCase )

            % Compare the reciprocal of the sample rate with the actual time
            % step.
            fs = testCase.WaveGenerator.SampleRate;
            actualTimeStep = testCase.WaveGenerator.TimeStep;
            expectedTimeStep = seconds( 1 / fs );
            testCase.verifyEqual( actualTimeStep, expectedTimeStep, ...
                "The time step was not computed correctly.", ...
                "AbsTol", 1e-6 )

        end % tTimeStepIsComputedCorrectly

        function tSignalIsGeneratedCorrectly( testCase )

            % Create a simple wave comprising a point with value 0.
            testCase.WaveGenerator.Amplitude = 0;
            testCase.WaveGenerator.Duration = 0;
            expectedSignal = timetable( seconds( 0 ), 0 );
            expectedSignal.Properties.VariableNames = "PulsedSineWave";
            expectedSignal.Properties.DimensionNames(1) = "Time";

            % Generate the signal based on the current wave parameters.
            actualSignal = testCase.WaveGenerator.Signal;
            testCase.verifyEqual( actualSignal, expectedSignal, ...
                "The generated signal does not match the " + ...
                "expected signal.", "AbsTol", 1e-6 )

        end % tSignalIsGeneratedCorrectly

        function tConstructorSetsNameValuePairs( testCase, WaveParameter )

            % Construct the pulsed sine wave with the given parameter and a
            % value of 1.
            PSW = PulsedSineWave( WaveParameter, 1 );
            actualParameter = PSW.(WaveParameter);
            testCase.verifyEqual( actualParameter, 1, ...
                "The PulsedSineWave constructor did not set the " + ...
                "value of the " + WaveParameter + " property.", ...
                "AbsTol", 1e-6 )

        end % tConstructorSetsNameValuePairs

        function tEquivalenceOfGeneratedCode( testCase )

            % Filter.
            tf = getenv( "GITHUB_ACTIONS" ) == "true";
            testCase.assumeFalse( tf, "This test is not supported " + ...
                "when running from GitHub Actions." )

            % Generate C code.    
            waveParams = num2cell( ones( 1, 7 ) );
            buildResults = testCase.build( "generateWave", ...
                "Configuration", coderConfiguration(), ...
                "Inputs", waveParams );

            % Execute the generated code via a MEX-function.
            executionResults = testCase.execute( buildResults, ...
                "Inputs", waveParams );

            % Verify the equivalence of the generated code and the original
            % algorithm.
            testCase.verifyExecutionMatchesMATLAB( executionResults, ...
                "AbsTol", 1e-6 )

        end % tEquivalenceOfGeneratedCode

    end % methods ( Test )

end % classdef