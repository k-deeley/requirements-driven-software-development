classdef tPulsedSineWave < matlab.unittest.TestCase

    properties
        SUT
    end % properties

    properties (Constant)
        DefaultPSWProperties = struct( ...
            "Amplitude", 1.1, ...
            "Frequency", 1000, ...
            "Duration", 2, ...
            "PulseRate", 4, ...
            "Duty", 30, ...
            "SampleRate", 8000);
    end % properties (Constant)

    properties (TestParameter)
        numericProperties = {"Amplitude", "Frequency", "Phase", ...
            "Duration", "PulseRate", "Duty", "SampleRate"}
    end % properties (TestParameter)

    methods (TestClassSetup)
        function smokeTest(testCase)
            fatalAssertWarningFree(testCase, @PulsedSineWave)
        end % function smokeTest
    end % methods (TestClassSetup)

    methods (TestMethodSetup)
        function createSUT(testCase)
            testCase.SUT = PulsedSineWave;
        end % function createSUT
    end % methods (TestMethodSetup)

    methods (Test, ParameterCombination = "sequential")

        function tDefaultPSWIsCorrect(testCase)

            % Setup
            % expectedAmplitude = 1.1;
            % expectedFrequenct .....
            %
            % DefaultPSWProperties = struct( ...
            %     "Amplitude", 1.1, ...
            %     "Frequency", 1000, ...
            %     "Duration", 2, ...
            %     "PulseRate", 4, ...
            %     "Duty", 30, ...
            %     "SampleRate", 8000);

            % Execute
            %SUT = PulsedSineWave;

            % Qualify
            % props = string(fieldnames(testCase.DefaultPSWProperties))';
            % for p = props
            %     expected = testCase.DefaultPSWProperties.(p);
            %     verifyEqual(testCase, testCase.SUT.(p), ...
            %         expected, ...
            %         p, ...
            %         AbsTol = 30*eps(expected));
            % end % for
            checkPropertiesMatchDefaults(testCase);

        end % function tDefaultPSWIsCorrect

        function tChangingNumericPropertiesWorks(testCase, numericProperties)

            % Setup 
            %SUT = PulsedSineWave;
            expected = 2;

            % Execute
            testCase.SUT.(numericProperties) = expected;

            % Qualify
            verifyEqual(testCase, testCase.SUT.(numericProperties), ...
                expected);
            checkPropertiesMatchDefaults(testCase, numericProperties)

        end % function tChangingAmplitudeWorks

        function tNonfiniteAmplitudeIsProhibited(testCase)

            % Setup
            %SUT = PulsedSineWave;
            invalidAmplitude = NaN;

            % Execute
            %SUT.Amplitude = invalidAmplitude;

            % Qualify
            verifyError(testCase, @setValue, ...
                "MATLAB:validators:mustBeFinite")

            function setValue
                testCase.SUT.Amplitude = invalidAmplitude;
            end % function setValue

        end % function tNonfiniteAmplitudeIsProhibited

        function tNegativeSamplerateIsProhibited(testCase)

            % Setup
            %SUT = PulsedSineWave;
            invalidSampleRate = -1;

            % Execute
            %SUT.Amplitude = invalidAmplitude;

            % Qualify
            verifyError(testCase, @setValue2, ...
                "MATLAB:validators:mustBePositive")

            function setValue2
                testCase.SUT.SampleRate = invalidSampleRate;
            end % function setValue

        end % function tNonfiniteAmplitudeIsProhibited

        function tWritingToFileWorks(testCase)

            % Setup
            fx = matlab.unittest.fixtures.TemporaryFolderFixture;
            applyFixture(testCase, fx);
            fname = fullfile(fx.Folder, "output.xlsx");

            % Execute
            writeToFile(testCase.SUT, fname);

            % Qualify
            isFile = matlab.unittest.constraints.IsFile;
            assertThat(testCase, fname, isFile);

            % dat = assertWarningFree(@() readtimetable(fname))
            % ... some code using verify to qualify the contents of dat

        end % function tWritingToFileWorks
    end % methods (Test)

    methods (Test, TestTags = "App")

        function tPlotReturnsAPlotHandle(testCase)

            % Setup
            f = figure(Visible = "off");
            addTeardown(testCase, @delete, f)
            ax = axes(f, NextPlot = "add");

            % Execute
            ph = verifyWarningFree(testCase, @() plot(testCase.SUT, ax));

            % Qualify
            verifyClass(testCase, ph, ...
                "matlab.graphics.chart.primitive.Line")

        end % function tPlotReturnsAPlotHandle

    end % methods (Test)

    methods 
        function checkPropertiesMatchDefaults(testCase, skip)
            arguments (Input)
                testCase
                skip(1, 1) string = missing
            end % arguments (Input)

            props = string(fieldnames(testCase.DefaultPSWProperties))';
            props = props(props ~= skip);

            for p = props
                expected = testCase.DefaultPSWProperties.(p);
                verifyEqual(testCase, testCase.SUT.(p), ...
                    expected, ...
                    p, ...
                    AbsTol = 30*eps(expected));
            end % for
        end % function checkPropertiesMatchDefaults
    end % methods

end % classdef