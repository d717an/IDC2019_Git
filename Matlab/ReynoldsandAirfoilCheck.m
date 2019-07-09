%% Reynolds Number Approximation

if 1
    % Calculate Reynolds Number
    %   - using 0.75R for speed
    R = 18/12/3.281;    % m, using max radius of 18" converted to m
    L = 0.15;   % m, characteristic length
    kinVisc = 1.511*10^-5;  % m^2/s, kinematic viscosity SL 68F (airfoiltools.com)
    w_reynold = [50 100 150 200 250 300]; % rad/s, range of values to test for different reynolds number
    Vr = 0.75*R*rpm2rad(w_reynold);   % m/s, radial velocity at 0.75R

    disp('for 1 m/s descent:')
    Vvert = 1.0;   % m/s, 6 lbs dropped from 60 ft with no lift reaches about 18 m/s
    V = sqrt(Vr.^2+Vvert^2);   % m/s, approximate resultant velocity at 0.75R
    Re = L*V/kinVisc;
    format shortG
    RPMvsRe = [w_reynold',Re']

    disp('for 5 m/s descent:')
    Vvert = 5.0;   % m/s, 6 lbs dropped from 60 ft with no lift reaches about 18 m/s
    V = sqrt(Vr.^2+Vvert^2);   % m/s, approximate resultant velocity at 0.75R
    Re = L*V/kinVisc;
    format shortG
    RPMvsRe = [w_reynold',Re']

    disp('for 10 m/s descent:')
    Vvert = 10.0;   % m/s, 6 lbs dropped from 60 ft with no lift reaches about 18 m/s
    V = sqrt(Vr.^2+Vvert^2);   % m/s, approximate resultant velocity at 0.75R
    Re = L*V/kinVisc;
    format shortG
    RPMvsRe = [w_reynold',Re']

    disp('for 15 m/s descent:')
    Vvert = 15.0;   % m/s, 6 lbs dropped from 60 ft with no lift reaches about 18 m/s
    V = sqrt(Vr.^2+Vvert^2);   % m/s, approximate resultant velocity at 0.75R
    Re = L*V/kinVisc;
    RPMvsRe = [w_reynold',Re']
end

% Output suggests a reynolds number range of 50,000 to 100,000

%% Check Airfoil Fits

if 1
    AOA_test = -15:1:30;
    [Cl_test1, Cd_test1] = ClarkY(AOA_test,1);
    [Cl_test2, Cd_test2] = ClarkY(AOA_test,2);
    
    figure; hold on; grid on;
    plot(AOA_test, Cl_test1); plot(AOA_test, Cl_test2);
    figure; hold on; grid on;
    plot(AOA_test, Cd_test1); plot(AOA_test, Cd_test2);
end