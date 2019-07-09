function sikstartup(varargin) 
% Configures MATLAB environment for a specified Sikorsky project
% 
% SIKSTARTUP() prompts the user to select a project from a list of
% discovered project directories in the CVS ROOT folder, and then assigns
% the appropriate environment configuration for the selected project.
%
% SIKSTARTUP('update'), checks for updates to Sikorsky utilities and
% then prompts the user to install discovered updates.
%
% SIKSTARTUP('project'), where 'project' matches a valid project root name,
% assigns the appropriate environment configuration for the project.
%
%   $Revision: 1.1 $  $Date: 2013/07/15 $
%   $Revision: 1.2 $  $Date: 2014/02/07 $


%Define cvs_work directory path
setenv('CVS_ROOT','C:/cvs_work/')

%Call Sikorsky Environment startup script in <cvs_root>/common/startup/sikstartup.m
run(fullfile(getenv('CVS_ROOT'),'common','startup','sikstartup.m'))

end
























