function [Tnet,fL,Rcavg,Thwind,AOA_tot,Fperp,Fplane] = bladeForces(AOA,Vvert,w,Rc,c,Tw,dens)
% Inputs:
%   - AOA: Angle of attack between relative wind and chord, deg
%   - Vvert: speed of vertical descent, m/s
%   - w: angular velocity of the rotor, rad/s
%   - Rc: vector of radial positions of spars, m
%   - c: vector of chord lengths for each spar, m
%   - Tw: vector of twist relative to horizontal of each spar, deg (up = pos)
% Outputs:
%   - Tnet: net in-plane torque about center of vehicle
%   - fL: net lift force perpendicular to rotor plane
%   OPTIONAL
%   - Rcavg: radial location of each panel
%   - Thwind: relative wind at each panel
%   - AOA_tot: total AOA (for calculating Lift) at each panel
%   - Fperp: perpendicular force at each panel
%   - Fplane: planar force at each panel

% Define Values for Each Panel (count is n_chords-1)
Savg = zeros(1,length(Rc)-1);
cavg = Savg;
Twavg = Savg;
Rcavg = Savg;
Vwind = Savg;
Thwind = Savg;
AOA_tot = Savg;
L = Savg;
D = Savg;
Fplane = Savg;
Fperp = Savg;

for ii = 1:length(Savg)
   cavg(ii) = (c(ii)+c(ii+1))/2; % m, avg chord for a panel
   Savg(ii) = cavg(ii)*(Rc(ii+1)-Rc(ii)); % m^2, surface area of each panel
   Twavg(ii) = (Tw(ii)+Tw(ii+1))/2; % deg, average twist of a panel
   Rcavg(ii) = (Rc(ii)+Rc(ii+1))/2; % m, radial location of panel centers
   
   % Calculate Resultant Wind Speed
   Vwind(ii) = sqrt(Vvert^2 + (Rcavg(ii)*w)^2); % m/s
   
   % Calculate Resultant Wind Angle w.r.t Horizontal
   Thwind(ii) = atan(Vvert/(Rcavg(ii)*w))*180/pi; % deg
   
   % Calculate Total AOA for Each Panel
   AOA_tot(ii) = Thwind(ii) + Tw(ii) + AOA; % deg, relative wind + twist + servo AOA
      
   % Calculate Lift and Drag
   [Cl,Cd] = ClarkY(AOA_tot(ii),1); 
   L(ii) = Cl*0.5*dens*Savg(ii)*Vwind(ii)^2; % N, lift normal to free stream
   D(ii) = Cd*0.5*dens*Savg(ii)*Vwind(ii)^2; % N, drag parallel to free stream
   
   % Translate Lift and Drag into Planar and Perpendicular Forces Based on Rel Wind
   Fperp(ii) = L(ii)*cos(Thwind(ii)*pi/180) + D(ii)*sin(Thwind(ii)*pi/180); % positive = up
   Fplane(ii) = L(ii)*sin(Thwind(ii)*pi/180) - D(ii)*cos(Thwind(ii)*pi/180); % positive = in direction of increasing RPM
      
end

% Calculate Planar Torque and Lift
Tnet = dot(Fplane,Rcavg); % Nm
fL = sum(Fperp); % N

if ~exist('Rcavg','var')
    Rcavg = Rcavg;
end

if ~exist('Thwind','var')
    Thwind = Thwind;
end

if ~exist('AOA_tot','var')
    AOA_tot = AOA_tot;
end

if ~exist('Fperp','var')
    Fperp = Fperp;
end

if ~exist('Fplane','var')
    Fplane = Fplane;
end
 


% Debugging: Printing Values When Function Called
% Inputs
%AOA
%Vvert
%w

% Calculations
%Savg
%cavg
%Twavg
%Rcavg
%Vwind
%Thwind
%AOA_tot
%L = L*0.2248
%L_tot = sum(L)
%Fperp = Fperp*0.2248
% Fperp_tot = sum(Fperp)
% D = D*0.2248
% D_tot = sum(D)
% Fplane = Fplane*0.2248
% Fplane_tot = sum(Fplane)
%Tnet = Tnet*0.2248*3.281*12 % in-lbs   
    
end  