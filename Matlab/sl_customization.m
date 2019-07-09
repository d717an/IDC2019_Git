function sl_customization(cm)
% Applies customizations to the Simulink user interface
% Created by: Michael Connor (S34060) 7-11-2011
%
% R2013b Updates (1/2014)
%   -added 'InportShadow' blocktype
%   -changed "Userdata" to "userdata"
%   -various optimizations

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Install:    -Place sl_customization.m in the startup dir
%             -Restart Matlab or run "sl_refresh_customizations"
%
% Uninstall:  -Remove "sl_customization.m" from the startup dir
%             -Restart Matlab or run "sl_refresh_customizations"
%
% Usage:      -Access functions in simulink toolbar menu
%             -Right-click in models to access parts in context-menu
%             -Right-click on outports or bus_creator blocks to refresh or 
%              create bus creator structures with tags.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Register menu functions
cm.addCustomMenuFcn('Simulink:PreContextMenu', @getContextTools);
cm.addCustomMenuFcn('Simulink:PreContextMenu', @getPartsLib);
% cm.addCustomMenuFcn('Simulink:ToolsMenu', @Menu_Sikorsky);
cm.addCustomMenuFcn('Simulink:MenuBar', @Menu_Sikorsky);
end


%% Define Global Vars
function [out] = define(inarg)
switch inarg
    
    case'mousePos' % Get mouse position
        out = get(0,'PointerLocation');
        
    case'PartLibList' % Get blocks from the Available Parts Libraries

        prtlist = {'Sikorsky','UH60M','CH53K','S97','ST4586','Nav','X76','DXP'};
        prts = prtlist;
        % Look for additional Parts Libraries in SIkMatlabEnv
        if exist('project_state.mat','file') && exist('getproject.m','file')
            prts  = strrep(cellstr(ls([getproject('root'), ...
                'SikMatlabEnv',getproject('slsh'),'*Parts'])),'Parts','');
            prts = unique([prtlist,prts{:}]);
        end
        
        % Check if Parts Library Model files exist
        out = [];     
        for i=1:length(prts)
            if exist([prts{i},'Parts'],'file')==4
                out{end+1} = [prts{i},'Parts']; %#ok<*AGROW>
            end
        end
end
end


%% Add Tool Menu Items
 function schemaFcns = Menu_Sikorsky
 warning off all;
  schemaFcns = {@Menu_Items}; 
 end
 
function schema = Menu_Items(callbackInfo) 
% Adds "Sikorsky" menu to toolbar
schema = sl_container_schema;
schema.label = 'Sikorsky';
schema.tag = 'Simulink:SikorskyMenu';
childFunc = {};

if sscanf(version('-release'),'%d') >= 2013
    schema.autoDisableWhen = 'Busy'; %Enable Menu for Library Figures (R2013b & later)
end

if ~isempty(define('PartLibList'))
    childFunc(end+1) = {@Menu_OpenPartsLib};
end

if exist('set_borders','file')==2
    childFunc(end+1) = {@Menu_Set_Borders}; 
end

if exist('tidy_model','file')==2
    childFunc(end+1) = {{@addToolbarMenu,{'Tidy_Model','tidy_model'}}};
end

if exist('addgoto','file')==2
    childFunc(end+1) = {{@addToolbarMenu,{'AddGoto','addgoto'}}}; 
end

if exist('check_model','file')==2
    childFunc(end+1) = {{@addToolbarMenu,{'Check_Model','check_model'}}}; 
end

% To add menu items, add childFunc X with "LABEL" and "FUNCTION" (see below)
% childFunc(X) = {{@addToolbarMenu,{'LABEL','FUNCTION'}}}; 

if any(size(childFunc))
    schema.childrenFcns = childFunc;
end

end 

function schema = Menu_OpenPartsLib(callbackInfo) 
% Open Parts Library models
schema = sl_container_schema;
schema.label  = 'Parts Library';
schema.tag  = 'Simulink:SikPartsModel';

[LibList] = define('PartLibList');  % Find Available Parts Libraries
for i=1:length(LibList)
    childFunc(i) = {{@addToolbarMenu,{LibList{i},['open_system(''',LibList{i},''')']}}}; 
end

schema.childrenFcns = childFunc;
end 

function schema = Menu_Set_Borders(callbackInfo)
schema = sl_container_schema;
schema.label  = 'Set_Borders';
schema.tag  = 'Simulink:SikSetBorders';
childFunc(1) = {{@addToolbarMenu,{'8.5"x11"','set_borders(''8x11'')'}}};
childFunc(2) = {{@addToolbarMenu,{'11"x17"','set_borders(''11x17'')'}}};
childFunc(3) = {{@addToolbarMenu,{'17"x22"','set_borders(''17x22'')'}}};
childFunc(4) = {{@addToolbarMenu,{'22"x34"','set_borders(''22x34'')'}}};
childFunc(5) = {{@addToolbarMenu,{'None"','set_borders(''none'')'}}};
schema.childrenFcns = childFunc;
end 

 %% Add conditional context menu items
 function schemaFcns = getContextTools
menu_list = [];

 % Add "add_io" context menu item if gcb is subsystem
if exist('add_io','file')==2
    if strcmp(get(gcbh,'Name'),get(gcbh,'Parent')) && strcmp(get(gcbh,'BlockType'),'SubSystem')
        menu_list = [menu_list,'{@addToolbarMenu,{''Add_IO'',[''add_io'']}},'];
    end
end

 % Add "AddGoto" context item if gcb is supported
if exist('addgoto','file')==2
     if any(strcmp(get_param(gcb,'BlockType'), ...
             {'ModelReference';'Goto';'From';'Inport';'InportShadow';'Outport';'SubSystem';'BusCreator';'BusSelector'})) 
         menu_list = [menu_list,'{@addToolbarMenu,{''AddGoto'',[''addgoto(''''auto'''')'']}},'];
     end     
end

schemaFcns = eval(['{',menu_list(1:end-1),'}']);
 end


 function schema = addToolbarMenu(callbackInfo) 
schema = sl_action_schema;
schema.label  = callbackInfo.userdata{1};
schema.userdata = callbackInfo.userdata{2};	
schema.callback = @FcnRun;
 end

 function FcnRun(callbackInfo)
  eval(['',callbackInfo.userdata,'']); 
 end
 

%% Parts Library Fetch

function schemaFcns = getPartsLib
% Buld Context Menu list of the Available Parts Libraries
[LibList] = define('PartLibList');

menu_list = [];
for i=1:length(LibList)
    menu_list = [menu_list,'{@addPartMenu,{''',LibList{i},'''}},'];
end

schemaFcns = eval(['{',menu_list(1:end-1),'}']);
end

% Populate Context Menu with Parts List
function schema = addPartMenu(callbackInfo)
warning off all;
part_mdl = callbackInfo.userdata{1};
schema = sl_container_schema;
schema.label  = part_mdl;
schema.tag  = 'Simulink:SikPartsMenu';

try
    if  ~bdIsLoaded(part_mdl)
        load_system(part_mdl);
    end
catch
    load_system(part_mdl);
end

% Get mouse position
[mousePos] = define('mousePos');

% Get available blocks from the Sikorsky library
availableBlocks = find_system(part_mdl,'SearchDepth',1,'DropShadow','on');
if ~isempty(availableBlocks) 
    for iBlock=1:length(availableBlocks),
        blockPath = availableBlocks{iBlock};
        blockName = blockPath(max(strfind(blockPath,'/'))+1:end);
        childFunc(iBlock) = {{@addSimulinkBlock,{part_mdl,blockName,blockPath,mousePos}}};
    end 
else 
    availableBlocks = find_system(part_mdl,'SearchDepth',1);
    for iBlock=1:length(availableBlocks),
        blockPath = availableBlocks{iBlock};
        blockName = blockPath(max(strfind(blockPath,'/'))+1:end);
        childFunc(iBlock) = {{@addLibraryBlock,{part_mdl,blockName,blockPath,mousePos}}};
    end 
end
schema.childrenFcns = childFunc;
end

function schema = addSimulinkBlock(callbackInfo)   
PartModel     = callbackInfo.userdata{3};
blockName     = callbackInfo.userdata{2};
mousePos      = callbackInfo.userdata{4};

schema = sl_container_schema;
schema.label  = blockName;

availableBlocks = find_system(PartModel,'SearchDepth',1,'DropShadow','off');
if length(availableBlocks)>1
    for iBlock=1:length(availableBlocks),
        blockPath = availableBlocks{iBlock};
        blockName = blockPath(max(strfind(blockPath,'/'))+1:end);
        childFunc(iBlock) = {{@addLibraryBlock,{PartModel,blockName,blockPath,mousePos}}};
    end
else
    blockPath = availableBlocks{1};
    blockName = blockPath(max(strfind(blockPath,'/'))+1:end);
    childFunc(1) = {{@addLibraryBlock,{PartModel,blockName,blockPath,mousePos}}};
end
schema.childrenFcns = childFunc;
end

function schema = addLibraryBlock(callbackInfo)
  schema = sl_action_schema;
  schema.label = callbackInfo.userdata{2};	
  schema.userdata = callbackInfo.userdata;
  schema.callback = @slAddLibraryBlock; 
end

function slAddLibraryBlock(inArgs)
PartModel     = inArgs.userdata{1};
blockName     = inArgs.userdata{2};
blockPath     = inArgs.userdata{3};
mousePos      = inArgs.userdata{4};

% Calculate new position
blk_size = get_param(blockPath, 'Position');
locBase = get_param(gcs,'Location');
scrollOffset = get_param(gcs,'ScrollbarOffset');
screenSize   = get(0,'ScreenSize');
zoom = get_param(gcs,'ZoomFactor');
p_X = (mousePos(1) - locBase(1) + scrollOffset(1))*1/(str2double(zoom)*.01);
p_Y = (screenSize(4) - mousePos(2) - locBase(2) + scrollOffset(2))*1/(str2double(zoom)*.01);
location = [p_X p_Y p_X+blk_size(3) - blk_size(1) p_Y+blk_size(4) - blk_size(2)];

% Add block
block = add_block(blockPath,[gcs '/' blockName],'MakeNameUnique','on','Position',location);

% Hide block name if appropriate
try
    if ~any(strmatch(blockName,{'In1';'Out1';'NamedOutput';'Subsystem';'License';})) ...
            && ~strcmp(get(block,'MaskType'),'Stateflow') && ~any(findstr('Subsystems',blockPath)) ...
            && any(findstr('SikorskyParts',PartModel));
        set(block,'ShowName','off')
    end
end
close_system(PartModel);
end
 


