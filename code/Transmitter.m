classdef Transmitter
    %TRANSMITTER Modulate and demodulate signals.

    properties
        % Carrier frequency (Hz).
        CarrierFrequency(1, 1) double {mustBeFinite, mustBePositive} = 6e5
        % Upsampling rate (Hz).
        UpsamplingRate(1, 1) double {mustBeFinite, mustBePositive} = 2e6
        % Upsampling method ("upsample"|"interp"|"resample").
        UpsamplingMethod(1, 1) string {mustBeMember( UpsamplingMethod, ...
            ["upsample", "interp", "resample"] )} = "resample"
    end % properties

    methods

        function obj = Transmitter( namedArgs )

            arguments ( Input )
                namedArgs.?Transmitter
            end % arguments ( Input )

            namedArgs = namedargs2cell( namedArgs );
            for k = 1 : 2 : numel( namedArgs )
                obj.(namedArgs{k}) = namedArgs{k+1};
            end % for

        end % constructor

        function wave = transmit( obj, wave )
            %TRANSMIT Transmit a signal.

            arguments ( Input )
                obj(1, 1) Transmitter
                wave(1, 1) PulsedSineWave
            end % arguments ( Input )

            % Extract the signal name, times, values, and sample rate.
            signal = wave.Signal;
            name = signal.Properties.VariableNames;
            t = signal.Properties.RowTimes;
            w = signal{:, 1};
            fs = signal.Properties.SampleRate;

            % Upsample the signal.
            switch obj.UpsamplingMethod
                case "resample"
                    w = resample( w, obj.UpsamplingRate, fs );
                case {"upsample", "interp"}
                    upfactor = ceil( obj.UpsamplingRate / fs );
                    w = feval( obj.UpsamplingMethod, w, upfactor );
            end % switch/case

            % Create the new time base.
            Time = linspace( min( t ), max( t ), numel( w ) ).';

            % Create the new signal timetable.
            wave = timetable( Time );
            fs = wave.Properties.SampleRate;

            % Perform the modulation.
            w = modulate( w, obj.CarrierFrequency, fs, "am" );
            wave{:, 1} = w;
            wave.Properties.VariableNames = name;

        end % transmit

    end % methods

end % classdef
