function resegmentation_caller(varargin)
%ReSEGMENTATION_CALLER Function caller
% ------------------------------------------------------------------------------
% PREAMBLE
%
% This function will call a resegmentation function on the image data. This
% calling function will invoke the required function according to
% server-client standards.
%
% REFERENCES
%
% AUTHOR:   Lorenzo Gatti (lorenzo.gatti@alumni.ethz.ch)
%
% DATE:     29.01.15 V0.1 for EpiTools 2.0 beta
% 
% LICENCE:
% License to use and modify this code is granted freely without warranty to all, as long as the 
% original author is referenced and attributed as such. The original author maintains the right 
% to be solely associated with this work.
% 
% Copyright by A.Tournier, A. Hoppe, D. Heller, L.Gatti
% ------------------------------------------------------------------------------
%% Initialization
if nargin < 1 ; varargin = {} ; end
%% Elaboration
hMainGui = getappdata(0, 'hMainGui');
server_instances = getappdata(hMainGui, 'server_instances');
client_modules = getappdata(hMainGui, 'client_modules');
pool_instances = getappdata(hMainGui, 'pool_instances');
% Remapping
server = server_instances(2).ref;
clients = client_modules(2).ref;
% Storing execution variables into memory
for i=numel(varargin);handles{i} = addVariable2Memory(varargin{i});end
% Send message to all the active pools
for i = 1:size(pool_instances(2:end),2)
    if (pool_instances(i+1).ref.active)
        % Add variable memory handles to exe command
        var = {'ExecutionSettingsHandle',handles{1}};
        clients(strcmp({clients.uid},'Skeletons')).addArgv('SKEL01','argv',var);
        server.receiveMessage(clients(strcmp({clients.uid},'Skeletons')),...
                              pool_instances(i+1).ref, pool_instances(2).ref);
    end
end
end

