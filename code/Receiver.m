classdef Receiver
    %RECEIVER Simulate a signal receiver.
    % Modify the input signal by reducing its power via an attenuation
    % factor, introducing a delay, and adding noise.

    properties
        % Attenuation (loss of power) factor.
        AttenuationFactor(1, 1) double ...
            {mustBeInRange( AttenuationFactor, 0, 1 )} = 0.8
        % Delay (number of samples).
        Delay(1, 1) double {mustBePositive, mustBeFinite} = 23
        % Target signal-to-noise ratio (dB).
        TargetSNR(1, 1) double {mustBeNonnegative, mustBeFinite} = 20
        % Assumed carrier frequency of the received waveform (Hz).
        CarrierFrequency(1, 1) double {mustBePositive, mustBeFinite} = 6e5
        % Downsampling factor.
        DownsamplingFactor(1, 1) double ...
            {mustBePositive, mustBeInteger} = 250
        % Downsampling method ("downsample"|"decimate").
        DownsamplingMethod(1, 1) string {mustBeMember( ...
            DownsamplingMethod, ["downsample", "decimate"])} = "downsample"
    end % properties

    methods

        function obj = Receiver( namedArgs )
            %RECEIVER Construct a receiver object.

            arguments ( Input )
                namedArgs.?Receiver
            end % arguments ( Input )

            namedArgs = namedargs2cell( namedArgs );
            for k = 1 : 2 : numel( namedArgs )
                obj.(namedArgs{k}) = namedArgs{k+1};
            end % for

        end % constructor

        function tt = receive( obj, tt )
            %RECEIVE Receive a signal.

            arguments ( Input )
                obj(1, 1) Receiver
                tt(:, 1) timetable
            end % arguments ( Input )

            % Extract the signal name, time, signal, and sample rate.
            name = tt.Properties.VariableNames;
            t = tt.Properties.RowTimes;
            w = tt{:, 1};
            fs = tt.Properties.SampleRate;

            % Introduce the delay.
            w = [zeros( obj.Delay * obj.DownsamplingFactor, 1 ); w];

            % Attenuate.
            w = obj.AttenuationFactor * w;

            % Compute the required standard deviation of the noise.
            targetSNR = db2pow( obj.TargetSNR );
            noiseStd = sqrt( mean( w.^2 ) / targetSNR );

            % Generate and add the noise.
            w = w + noiseStd * randn( size( w ) );

            % Demodulate the signal.
            w = demod( w, obj.CarrierFrequency, fs, "am" );

            % Downsample the signal.
            switch obj.DownsamplingMethod
                case "decimate"
                    w = decimate( w, obj.DownsamplingFactor, "fir" );
                case "downsample"
                    w = downsample( w, obj.DownsamplingFactor );
            end % switch

            % Assemble the output timetable.
            Time = linspace( min( t ), max( t ), numel( w ) ).';
            tt = timetable( Time, w );
            tt.Properties.VariableNames = name;

        end % receive

    end % methods

end % classdef