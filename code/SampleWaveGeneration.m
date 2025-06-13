%% Sample wave generation code.
A = 2;
f = 500;
ph = -pi/2;
dr = 5;
r = 4;
d = 30;
fs = 2000;

[wave, time] = generateWave(A, f, ph, dr, r, d, fs);