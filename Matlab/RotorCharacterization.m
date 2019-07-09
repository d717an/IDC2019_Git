%% Clean Up, Define Params
clc;

% LOAD VEHICLE PARAMS
VehicleParams

% ROTOR PARAMETERS
I = [0.25*I_rotor,I_rotor,4*I_rotor];

% STARTING CONDITIONS
h_0 = 1000.0;   % m, starting height
v_0 = 0;    % m/s, starting vehicle velocity
w_0 = 100;  % rpm, starting rotor angular velocity

% LOOP PARAMETERS
del_t = 0.01;    % time step for each iternation
t_tot = 110.0;   % total time for the analysis

%% Set Up Time Analysis
t = 0:del_t:t_tot;  % time vector
pts = length(t);    % number of discrete time points
ii_5ft = 0;         % will catch the time index the vehicle crosses 5 ft
ii_gnd = 0;         % will catch the time index the vehicle hits ground
h = zeros(length(I),pts);   % height vs time, m
AOA = h;            % commanded rotor Angle of Attack vs time, deg
v = h;              % vehicle velocity vs time, rad/s (pos = down)
a = h;              % vehicle accel vs time, rad/s (pos = down)
w = h;              % rotor angular velocity vs time, rad/s (pos = CCW from top)
alpha = h;          % rotor angular acceleration vs time, rad/s^2 (pos = CCW from top)
Tnet = h;           % in-plane torque vs time, Nm
fL = h;             % perpendicular-to-plane lift vs time, N
fZnet = h;          % net vertical force vs time, N (pos = down)

%% Time Analysis

for jj = 1:length(I)

    for ii = 1:pts

        % set ICs for params that need it
        if ii == 1
            h(jj,ii) = h_0;
            v(jj,ii) = v_0;
            a(jj,ii) = 0;
            w(jj,ii) = rpm2rad(w_0);
            alpha(jj,ii) = 0;
            fZnet(jj,ii) = 0;

            % Temporary: Set Starting AOA (deg)
            AOA(jj,ii) = -20;

            % calculate rotor forces for t0
            [Tnet(jj,ii),fL(jj,ii)] = bladeForces(AOA(jj,ii),v(jj,ii),w(jj,ii),Rc,c,Tw,dens);

        elseif ii>=2

            % Catch 5 ft Time Index
            if h(jj,ii-1) > (5/3.281)
                ii_5ft = ii; % update the 5 ft time index
            end

            % Characterize Steady-State RPMs vs AOA
            if t(ii) <5 
                AOA(jj,ii) = -20;
                %AOA(jj,ii) = -10;
            elseif t(ii) < 10
                AOA(jj,ii) = -17.5;
                %AOA(jj,ii) = -10;
            elseif t(ii) < 15
                AOA(jj,ii) = -15;
                %AOA(jj,ii) = -10;
            elseif t(ii) < 20
                AOA(jj,ii) = -12.5;
                %AOA(jj,ii) = -10;
            elseif t(ii) < 25
                AOA(jj,ii) = -10;
            elseif t(ii) < 30
                AOA(jj,ii) = -7.5;
            elseif t(ii) < 35
                AOA(jj,ii) = -5;
            elseif t(ii) < 40
                AOA(jj,ii) = -2.5;
            elseif t(ii) < 45
                AOA(jj,ii) = 0;
            elseif t(ii) < 50
                AOA(jj,ii) = 2.5;
            elseif t(ii) < 55
                AOA(jj,ii) = 5;
            elseif t(ii) < 75
                AOA(jj,ii) = 7.5;
            elseif t(ii) < 80
                AOA(jj,ii) = 10;
            elseif t(ii) < 85
                AOA(jj,ii) = 12.5;
            elseif t(ii) < 90
                AOA(jj,ii) = 15;
            elseif t(ii) < 95
                AOA(jj,ii) = 17.5;
            elseif t(ii) < 100
                AOA(jj,ii) = 20;
            else
                AOA(jj,ii) = 20; % deg, Rotor AOA
            end

            % Calculate Rotor Torque and Lift for Current Time
            [Tnet(jj,ii),fL(jj,ii)] = bladeForces(AOA(jj,ii),v(jj,ii-1),w(jj,ii-1),Rc,c,Tw,dens);

            % Calculate Kinematics
            if h(jj,ii-1) > 0  % vectors initialize to zero otherwise

                ii_gnd = ii; % update the ground time index

                % Linear Kinematics (Vehicle)
                fZnet(jj,ii) = m_veh*g - n_blades*fL(jj,ii);   % net force
                a(jj,ii) = fZnet(jj,ii)/m_veh;    % vertical acceleration
                v(jj,ii) = v(jj,ii-1) + a(jj,ii)*del_t;  % velocity
                h(jj,ii) = max(h(jj,ii-1) - 0.5*(v(jj,ii)+v(jj,ii-1))*del_t,0); % height               

                % Rotational Kinematics (Rotor)
                % - alpha = Torque / Moment of Inertia of Rotor in kg-m^2, http://www.softschools.com/formulas/physics/torque_formula/59/
                alpha(jj,ii) = n_blades * Tnet(jj,ii) / I(jj); % angular acceleration (rad/s^2)
                w(jj,ii) = w(jj,ii-1) + alpha(jj,ii)*del_t;  % angular velocity (rad/s)
            end 
        end     
    end
end

%% Visualization
if 1
    % Rotor Kinematics
    figure;
    subplot(3,1,1);grid on;hold on;
    plot(t(1:ii_gnd),AOA(1,1:ii_gnd))
    title('Commanded AOA');ylabel('[deg]');
    xticks([0:5:t_tot]);yticks([-20:5:20]); 
    
    subplot(3,1,2);grid on;hold on;
    plot(t(1:ii_gnd),rad2rpm(w(1,1:ii_gnd)))
    plot(t(1:ii_gnd),rad2rpm(w(2,1:ii_gnd)))
    plot(t(1:ii_gnd),rad2rpm(w(3,1:ii_gnd)))
    title('Rotor RPM');ylabel('\omega [rpm]');
    legend('0.25*I','I','4*I')
    xticks([0:5:t_tot]);
    yticks([0:100:1200]);
    
    subplot(3,1,3);grid on;hold on;
    plot(t(1:ii_gnd),v(1,1:ii_gnd)*3.281)
    plot(t(1:ii_gnd),v(2,1:ii_gnd)*3.281)
    plot(t(1:ii_gnd),v(3,1:ii_gnd)*3.281)
    title('Vertical Speed (Down is Positive)');ylabel('v [ft/s]');xlabel('time [s]');
    legend('0.25*I','I','4*I')
    xticks([0:5:t_tot]);
    yticks([-5:5:50]);
    
end
