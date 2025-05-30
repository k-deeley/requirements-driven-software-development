function [w, t] = generateWave( A, f, ph, dr, r, d, fs ) %#codegen
%GENERATEWAVE Generate a pulsed sine wave.

% Create the time vector, as a column, from 0 to dr seconds, where dr is 
% the specified duration.
t = transpose( 0 : 1/fs : dr );

% Generate the sine wave, using the amplitude (A), frequency (f), and phase
% offset (ph).
w = A * sin( 2 * pi * f * t + ph );

% Generate square waves using the pulse rate (r) and duty cycle (d), then
% rescale them to lie between 0 and 1 (the default will be between -1 and
% 1).
p = rescale( square( 2 * pi * r * t, d ) );

% Generate the pulsed sine wave by multiplying the sine wave by the partial
% square waves.
w = w .* p;

end % generateWave