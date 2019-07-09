%% Clean Up, Define Params
clc;

% LOAD VEHICLE PARAMS
VehicleParams

% ROTOR PARAMETERS
I = [I_rotor];

% STARTING CONDITIONS
h_0 = 18.0;   % m, starting height
v_0 = 0;    % m/s, starting vehicle velocity
w_0 = 100;  % rpm, starting rotor angular velocity
m_veh = 2.75;  % kg, vehicle mass

% LOOP PARAMETERS
del_t = 0.01;    % time step for each iternation
t_tot = 60;   % total time for the analysis

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

% TO DO
AOA_tot = zeros(length(I),pts,length(Rc)-1);  % deg, final AOA for each rotor panel
Rcavg = AOA_tot;    % m, radial location for each rotor panel
Thwind = AOA_tot;   % deg, relative wind at each rotor panel
Fperp = AOA_tot;    % N, perpendicular force for each rotor panel
Fplane = AOA_tot;   % N, planar force for each rotor panel

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
            AOA(jj,ii) = -10;

            % calculate rotor forces for t0
            [Tnet(jj,ii),fL(jj,ii),Rcavg(jj,ii,:),Thwind(jj,ii,:),AOA_tot(jj,ii,:),Fperp(jj,ii,:),Fplane(jj,ii,:)] = bladeForces(AOA(jj,ii),v(jj,ii),w(jj,ii),Rc,c,Tw,dens);

        elseif ii>=2

            % Catch 5 ft Time Index
            if h(jj,ii-1) > (5/3.281)
                ii_5ft = ii; % update the 5 ft time index
            end

            % Characterize Steady-State RPMs vs AOA
            if t(ii)<2
                AOA(jj,ii) = -12;
            elseif h(jj,ii-1) > (5/3.281)
                AOA(jj,ii) = 5;
            else
                AOA(jj,ii) = 5;
            end
            
%             if h(jj,ii-1) > (3/3.281)
%                 AOA(jj,ii) = -15;
%             else
%                 AOA(jj,ii) = 7;
%             end
            
            % Calculate Rotor Torque and Lift for Current Time
            [Tnet(jj,ii),fL(jj,ii),Rcavg(jj,ii,:),Thwind(jj,ii,:),AOA_tot(jj,ii,:),Fperp(jj,ii,:),Fplane(jj,ii,:)] = bladeForces(AOA(jj,ii),v(jj,ii-1),w(jj,ii-1),Rc,c,Tw,dens);

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

% Print Drop Times
Times = {'60-->5 ft',t(ii_5ft);'5-->0 ft',t(ii_gnd)-t(ii_5ft);'Total',t(ii_gnd)}

%% Visualization
if 1
    
    %temp, modify x axis for comparison
    %ii_gnd = 14/del_t;
    
    % Rotor Kinematics
    figure;
    subplot(4,1,1);grid on;hold on;
    plot(t(1:ii_gnd),AOA(1,1:ii_gnd))
    title('Commanded AOA');ylabel('[deg]');
    xticks(0:1:t_tot);yticks(-20:5:20); 
    
    subplot(4,1,2);grid on;hold on;
    plot(t(1:ii_gnd),rad2rpm(w(1,1:ii_gnd)))
    title('Rotor RPM');ylabel('\omega [rpm]');
    xticks(0:1:t_tot);yticks(0:100:1200);
    
    subplot(4,1,3);grid on;hold on;
    plot(t(1:ii_gnd),v(1,1:ii_gnd)*3.281)
    title('Vertical Speed (Down is Positive)');ylabel('v [ft/s]');
    xticks(0:1:t_tot);yticks(-10:5:50);
    
    subplot(4,1,4);grid on;hold on;
    plot(t(1:ii_gnd),h(1,1:ii_gnd)*3.281)
    title('Height');ylabel('h [ft]');xlabel('time [s]');
    xticks(0:1:t_tot);yticks(0:5:70);
     
end


%% Animation of Blade Forces
if 0
    
    %figure
    nchts = 6;
    
    % translate rotor arrays into two dimensions (limitation of plot())
    Rcavg_plt(:,:) = Rcavg(1,:,:);
    Thwind_plt(:,:) = Thwind(1,:,:);
    AOA_tot_plt(:,:) = AOA_tot(1,:,:);
    Fperp_plt(:,:) = Fperp(1,:,:);
    Fplane_plt(:,:) = Fplane(1,:,:);
    
    for ii = 1:1:ii_gnd
        
        % Height
        subplot(nchts,1,1); plot(t(1:ii_gnd),h(1:ii_gnd)*3.281);grid on;hold on;
        subplot(nchts,1,1); plot(t(ii),h(1,ii)*3.281,'ro'); hold off
        title('Height');ylabel('h [ft]');xlabel('time [s]');
        
        % RPM
        subplot(nchts,1,2); plot(t(1:ii_gnd),rad2rpm(w(1,1:ii_gnd)));grid on;hold on;
        subplot(nchts,1,2); plot(t(ii),rad2rpm(w(1,ii)),'ro');hold off;
        title('Rotor RPM');ylabel('\omega [rpm]');xlabel('time [s]');
        xticks(0:1:del_t*ii_gnd);yticks(0:100:1200);
        
        % Theta Wind
        subplot(nchts,1,3); plot(Rcavg_plt(ii,:)*3.281*12,Thwind_plt(ii,:),'-o');grid on;hold off;
        title('Blade Panel Relative Wind Angle');ylabel('[deg]');xlabel('Blade Radius [in]');
        xlim([0 18]);
        
        % AOA_Total
        subplot(nchts,1,4); plot(Rcavg_plt(ii,:)*3.281*12,AOA_tot_plt(ii,:),'-o');grid on;hold off;
        title('Blade Panel Total Angle of Attack');ylabel('[deg]');xlabel('Blade Radius [in]');
        xlim([0 18]);
                
        % Fperp
        subplot(nchts,1,5); plot(Rcavg_plt(ii,:)*3.281*12,Fperp_plt(ii,:)*0.2248,'-o');grid on;hold off;
        title('Blade Panel Perpendicular Forces');ylabel('[lb]');xlabel('Blade Radius [in]');
        xlim([0 18]);
        
        % Fplane (sums to torque)
        subplot(nchts,1,6); plot(Rcavg_plt(ii,:)*3.281*12,Fplane_plt(ii,:)*0.2248,'-o');grid on;hold off;
        title('Blade Panel Planar Forces');ylabel('[lb]');xlabel('Blade Radius [in]');
        xlim([0 18]);
        
        pause(0.2)     
    end
    
end



%% UI Control Test
if 0
    
    t_gnd = del_t*ii_gnd;
    time = t_gnd;
    
    index = round(time/del_t,0);
    
    f = figure;
    % ref: set(gcf,'position',[x0,y0,width,height])
    set(f,'position',[500,500,1200,400]);
    ax = axes('Parent',f,'position',[0.13 0.39  0.77 0.54]);
    
    plot_test(index,Rcavg_plt*3.281*12,Fperp_plt*0.2248,t)
   
    %title('Blade Panel Perpendicular Forces');ylabel('[lb]');xlabel('Blade Radius [in]');
        
    %https://www.mathworks.com/matlabcentral/answers/65402-how-to-set-graph-size
    b = uicontrol('Parent',f,'Style','slider','Position',[81,54,419,23],...
              'value',time, 'min',0, 'max',t_gnd);
    bgcolor = f.Color;
    bl1 = uicontrol('Parent',f,'Style','text','Position',[50,54,23,23],...
                    'String','0','BackgroundColor',bgcolor);
    bl2 = uicontrol('Parent',f,'Style','text','Position',[500,54,23,23],...
                    'String',num2str(t_gnd),'BackgroundColor',bgcolor);
    bl3 = uicontrol('Parent',f,'Style','text','Position',[240,25,100,23],...
                    'String','Time','BackgroundColor',bgcolor);
                
    b.Callback = {@myUpdateCB,del_t,Rcavg_plt*3.281*12,Fperp_plt*0.2248,t};

end

function plot_test(index,X,Y,t)
    % plot(Rcavg_plt(index,:)*3.281*12,Fperp_plt(index,:)*0.2248,'-o');
    plot(X(index,:),Y(index,:),'-o');
    xlim([0,18]);grid on;hold off;
    xlabel(['time = ',num2str(t(index)),'s']);
end

function myUpdateCB(hObject,Event,del_t,X,Y,t)
    t_new = get(hObject,'value');
    %disp(t_new)
    index = round(t_new/del_t,0);
    if index == 0
        index=1;
    end
    plot_test(index,X,Y,t);
end


