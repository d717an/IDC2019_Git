function [Cl,Cd] = ClarkY(AOA,Re_Curve)
% Inputs:
%   - AOA: Angle of attack between relative wind and chord, deg
%   - Re: number 1 or 2
%     -- 1: fit for Re of 50,000 <-- more likely, use this
%     -- 2: fit for Re of 100,000 
% Outputs:
%   - Cl: airfoil coefficient of lift
%   - Cd: airfoil coefficient of drag

x = AOA; % because I'm lazy

% calculate based on curves fit to airfoil sections
if Re_Curve == 1
    Cl = 0.12235.*x + 0.29106;
    Cd = 3.6057*10^-6.*x.^4 - 5.2677*10^-5.*x.^3 + 4.0093*10^-4.*x.^2 - 1.0004*10^-3.*x + 3.5709*10^-2;    
elseif Re_Curve == 2
    Cl = 0.12516.*x + 0.10570;
    Cd = 3.2243*10^-6.*x.^4 - 5.0788*10^-5.*x.^3 + 3.6283*10^-4.*x.^2 - 1.5067*10^-3.*x + 2.1494*10^-2;    
end

% Impose some limits to stop silly results
Cd = min(0.2,Cd);
%Cd = min(0.4,Cd);

for ii = 1:length(AOA)
    if AOA(ii) > 25
       Cl(ii) = 0.5;
    elseif AOA(ii) > 20
       Cl(ii) = 0.6;
    elseif AOA(ii) > 15
       Cl(ii) = 0.8;  
    elseif AOA(ii) > 10
       Cl(ii) = 1; 
    elseif AOA(ii) < -6
       Cl(ii) = -0.4;
    end
end

end
