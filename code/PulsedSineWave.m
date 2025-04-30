classdef PulsedSineWave
    %PULSEDSINEWAVE Represents a pulsed sine wave.
    % This is an example of a real-valued discretely-sampled signal over
    % time.

    properties % Configurable wave parameters
        % Amplitude of the sine wave.
        Amplitude(1, 1) double {mustBeFinite, mustBeNonnegative} = 1.1
        % Frequency of the sine wave (Hz).
        Frequency(1, 1) double {mustBeFinite, mustBeNonnegative} = 1000
        % Phase of the sine wave (radians).
        Phase(1, 1) double {mustBeReal, mustBeFinite} = 0
        % Signal duration (s).
        Duration(1, 1) double {mustBeFinite, mustBePositive} = 2
        % Pulse rate (Hz), used to create a pulsed signal.
        PulseRate(1, 1) double {mustBeFinite, mustBePositive} = 4
        % Duty cycle period (%), used to create a pulsed signal.
        Duty(1, 1) double {mustBeFinite, mustBeInRange( Duty, 0, 100 )} = 30
        % Signal sampling frequency (Hz).
        SampleRate(1, 1) double {mustBeFinite, mustBePositive} = 8000
    end % properties

    properties ( Dependent, SetAccess = private )
        % Signal time step (s).
        TimeStep
        % Timetable comprising the time base and the signal values.
        Signal
    end % properties ( Dependent, SetAccess = private )

    methods

        function obj = PulsedSineWave( namedArgs )
            %SIGNAL Construct a pulsed sine wave object.

            arguments ( Input )
                namedArgs.?PulsedSineWave
            end % arguments ( Input )

            namedArgs = namedargs2cell( namedArgs );
            for k = 1 : 2 : numel( namedArgs )
                obj.(namedArgs{k}) = namedArgs{k+1};
            end % for

        end % constructor

        function value = get.TimeStep( obj )

            value = obj.Signal.Properties.TimeStep;

        end % get.TimeStep

        function value = get.Signal( obj )

            % Compute the sine wave, pulses, and the pulsed sine wave.
            time = transpose( 0 : 1/obj.SampleRate : obj.Duration );
            Time = seconds( time );
            sineWave = obj.Amplitude * sin( ...
                2 * pi * obj.Frequency * time + obj.Phase );
            pulses = rescale( square( 2 * pi * obj.PulseRate * ...
                time + obj.Phase ) );
            PulsedSineWave = sineWave .* pulses;

            % Assemble the timetable.
            value = timetable( Time, PulsedSineWave );

        end % get.Signal

        function sound( obj )
            %SOUND Play the signal using the system audio device.

            arguments ( Input )
                obj(1, 1) PulsedSineWave
            end % arguments ( Input )

            sound( obj.Signal.PulsedSineWave, obj.SampleRate )

        end % sound

        function writeToFile( obj, varargin )
            %WRITETOFILE Export the signal timetable to a file.

            arguments ( Input )
                obj(1, 1) PulsedSineWave
            end % arguments ( Input )

            arguments ( Input, Repeating )
                varargin
            end % arguments ( Input, Repeating )

            writetimetable( obj.Signal, varargin{:} )

        end % writeToFile

        function varargout = plot( obj, ax, lineProps )
            %PLOT Plot the pulsed sine wave over time.

            arguments ( Input )
                obj(1, :) PulsedSineWave
                ax(1, 1) matlab.graphics.axis.Axes = gca()
                lineProps.?matlab.graphics.primitive.Line
            end % arguments ( Input )

            nargoutchk( 0, 1 )

            % Handle empty object arrays separately.
            if isempty( obj ), return, end

            lineProps = namedargs2cell( lineProps );
            funct = @(c) plot( ax, c.Signal, ...
                "Time", "PulsedSineWave", lineProps{:} );
            ph = arrayfun( funct, obj );

            if nargout == 1
                varargout{1} = ph;
            end % if

        end % plot

    end % methods

end % classdef