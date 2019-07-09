% CONSTANTS
g = 9.81;   % m/s^2, gravitational constant
dens = 1.117; % kg/m^3, SL 80 deg F

% VEHICLE PARAMETERS
m_veh = 2.5;  % kg, vehicle mass

% ROTOR PARAMETERS
n_blades = 6;
m_blade = 0.12;  % kg, blade mass
r_m_blade = 9/12/3.281; % m, radial location of blade cg
I_rotor = n_blades * m_blade * r_m_blade^2; % kg-mg^2, rotational inertia of rotor disk

% Define Blade "Panels" Radii
Rc = [4,7.5,10,13.5,17.8]/12/3.281; % m, Rc = radii of chords

% Define Chord at Each Location
c = [4,8,8,8,8]/12/3.281; % m, chords for each cross member

% Define Twist For Each Chord (delta from horizontal when servo AOA = 0)
Tw = [0,0,0,0,0]; % deg 