classdef poold < handle
    %POOLD Pool daemon contains the properties and methods for instantiate
    %a pool class. A pool class is responsible to keep track of server and
    %client tag architecture, to push and pull tag changes from xml pool
    %definition file. 
    
    properties (SetAccess = private)
        file = [];
        directory = '';
        name = '';
        tags = {};
        active = false;
        handleGraphics = '';
        handleJTreeTable = '';
    end
    
    events
        AddedTag
        RemovedTag
        PoolModified
        PoolInstance
    end
    
    methods
        function pool = poold(filename)
            % This function instanziate the pool object which will trigger its
            % announcement to the calling environment
            %
            % If no file name has been specified, then assigned one randomly
            if (~nargin==1); filename = strcat('unknown',num2str(randi(1000)));end
            pool.file = strcat('pool_',filename,'.xml');
            pool.name = filename;
            pool.directory = filename;
            pool.tags = {};
            pool.active = false;
            pool.handleGraphics = '';
            pool.handleJTreeTable = '';
            % Listeners
            poold_manager.listenerEvents(pool);
            % Announce to environment
            notify(pool,'PoolInstance');
        end
        % ====================================================================
        % Tag functions
        function appendTag(pool,clientProcess)
            %% Load tag file associated with the process id
            % clientProcess.uid = client process code
            % clientProcess.path = client relative location path
            % clientProcess.tagstruct = tag structure to exported
            % clientProcess.execvalues = values exported from command execution
            %% Extract tag structure from clientRequest
            if ~isa(clientProcess.tagstruct.tag,'cell')
                clientProcess.tagstruct.tag = {clientProcess.tagstruct.tag};
            end
            %tagstruct = clientProcess.tagstruct;
            %% Substitute variables with values from command execution
            % Check if a tag.xml file exists in the client process directory 
            if(exist([clientProcess.path,'/tags.xml'],'file'))
                % Read the file
                tag_template = xml_read([clientProcess.path,'/tags.xml']);
                % Recursively process every TAG in the exported tag list          
                id = false(1,numel(tag_template.tag));
                for i=1:numel(clientProcess.tagstruct.tag)
                    for o = 1:numel(tag_template.tag(strcmp({tag_template.tag.uid},...
                                    clientProcess.tagstruct.tag(i))).attributes.attribute)     
                        % Store id tag that is going to be used. Discard the others.         
                        id(strcmp({tag_template.tag.uid},clientProcess.tagstruct.tag(i))) = true;        
                        if (isa(tag_template.tag(strcmp({tag_template.tag.uid},...
                             clientProcess.tagstruct.tag(i))).attributes.attribute(o).path,'double'))
                             exp = regexp(num2str(tag_template.tag(strcmp({tag_template.tag.uid},...
                             clientProcess.tagstruct.tag(i))).attributes.attribute(o).path),...
                             '\$(.*?)\$',...
                             'match');
                             log2dev(sprintf('Found 1 variable to export %s',exp{1}),'DEBUG');
                        else
                             exp = regexp(tag_template.tag(strcmp({tag_template.tag.uid},...
                             clientProcess.tagstruct.tag(i))).attributes.attribute(o).path,...
                             '\$(.*?)\$',...
                             'match');
                             log2dev(sprintf('Found 1 variable to export %s',exp{1}),'DEBUG');
                        end  
                        if(~isempty(exp))
                            exp2 = strrep(exp, '$', '');
                            c = [clientProcess.execvalues.ref];
                            if~(sum(strcmp(exp2,c)) == 0)
                                newval = clientProcess.execvalues(strcmp(exp2,c)).object;
                                if isa(newval,'double');newval = num2str(newval); end
                                tag_template.tag(strcmp({tag_template.tag.uid},...
                                    clientProcess.tagstruct.tag(i))).attributes.attribute(o).path = strrep(tag_template.tag(strcmp({tag_template.tag.uid},...
                                    clientProcess.tagstruct.tag(i))).attributes.attribute(o).path,...
                                    exp{1},...
                                    newval);
                                log2dev(sprintf('Substituted with %s',tag_template.tag(strcmp({tag_template.tag.uid},...
                                    clientProcess.tagstruct.tag(i))).attributes.attribute(o).path),'DEBUG');
                            end
                        end %if
                    end %for
                end %for
                %% Purge unused tags from template
                if ~isempty(find(~id))
                    for i = find(~id)
                        tag_template.tag(i) = [];
                    end
                end
                %% Append structure to xml definition file  (pool.file)
                % Write back to file
                if(exist(['tmp/',pool.file],'file'))
                    current_pool = xml_read(['tmp/',pool.file]);
                    id = false(1,numel(tag_template.tag));
                    % Loop along the current_pool.tags and check for any correspondences with the local tag.
                    % In case the tag to append is already present in the current structure, then
                    % overwrite it, otherwise append it. 
                    for i = 1:numel(current_pool.tag)
                        if ~isempty(tag_template.tag(strcmp(current_pool.tag(i).uid,{tag_template.tag.uid})))
                            current_pool.tag(i).class = tag_template.tag(strcmp(current_pool.tag(i).uid,{tag_template.tag.uid})).class;
                            current_pool.tag(i).uid = tag_template.tag(strcmp(current_pool.tag(i).uid,{tag_template.tag.uid})).uid;
                            current_pool.tag(i).attributes = tag_template.tag(strcmp(current_pool.tag(i).uid,{tag_template.tag.uid})).attributes;
                            current_pool.tag(i).timestamp = now();
                            current_pool.tag(i).validity = tag_template.tag(strcmp(current_pool.tag(i).uid,{tag_template.tag.uid})).validity;
                            id(strcmp(current_pool.tag(i).uid,{tag_template.tag.uid})) = true;
                        end
                    end
                    % Check if there are any tag to append 
                    if sum(~id)>0
                        for i = find(~id)
                            nextid = numel(current_pool.tag) + 1;
                            current_pool.tag(nextid).class       =   tag_template.tag(i).class;
                            current_pool.tag(nextid).uid         =   tag_template.tag(i).uid;
                            current_pool.tag(nextid).attributes  =   tag_template.tag(i).attributes;
                            current_pool.tag(nextid).timestamp   =   now();
                            current_pool.tag(nextid).validity    =   tag_template.tag(i).validity;
                        end
                    end
                    % Set preferences for xml_write procedure
                    Pref.StructItem = false;
                    % Write to xml pool file
                    xml_write(['tmp/',pool.file], current_pool, 'tags', Pref);
                else
                    % Set preferences for xml_write procedure
                    Pref.StructItem = false;
                    % Write to xml pool file
                    xml_write(['tmp/',pool.file], tag_template, 'tags', Pref);
                end   
            end %if
            %% Send notification for added tag and modified pool
            notify(pool, 'PoolModified');
            notify(pool, 'AddedTag');
        end
        % --------------------------------------------------------------------
        function removeTag(pool,tagcode)
        
            % Remove structure from xml definition file  (pool.file)    
            % Delete pointer from pool list (pool.tags)
            notify(pool, 'RemovedTag');
            notify(pool, 'PoolModified');
        end
        % --------------------------------------------------------------------
        % Check if a certain tag is present in the avail tag list
        function boolean = existsTag(pool,tagcode)
            boolean = false;
            if(sum(strcmp(pool.tags, tagcode)>=1));
                boolean = true;
            end
        end
        % --------------------------------------------------------------------      
        % Retrieve tag association between tag and pool file
        function out = getTag(pool,tagcode,varargin)
            if nargin < 3
                varargin = {};
            end
            out = struct();
            % Read associated tag file
            tags = xml_read(['tmp/',pool.file]);
            level = find(strcmp(tagcode,pool.tags));
            % If the level required (varargin) is empty, then export all tag structure
            if isempty(varargin)
                out = tags.tag(char(level));
            else
                for i=1:numel(varargin)
                    try
                       out.(char(varargin(i))) = tags.tag(char(level)).(char(varargin(i)));
                    catch err
                        log2dev(sprintf('EPITOOLS:poold:method:getTag:RequiredLevelNotRetrieved| %s',...
                                        err.message),...
                                'ERR');
                    end
                end    
            end

        end
        % --------------------------------------------------------------------
        % Print all tag in the pool
        function getTagList(pool)
        
        end
        % --------------------------------------------------------------------
        % This function loads tags stored in xml pool file
        function loadPool(pool)
            if exist(['tmp/',pool.file], 'file');
                tags = xml_read(['tmp/',pool.file]);
                for i=1:numel(tags.tag)
                    pool.tags{i} = tags.tag(i).uid;
                end
            end
        end
        % --------------------------------------------------------------------
         % This function save in a xml files tags stored in pool object
        function savePool(pool)
            xml_write(['tmp/',pool.file], pool);
        end
        % --------------------------------------------------------------------
        % Save reference in session available resources.
        function announceToFramework(pool, callerID)
            pool_instances = getappdata(callerID, 'pool_instances');
            if isempty(pool_instances)
               pool_instances(1).ref = pool;
            else
               pool_instances(end+1).ref = pool;
            end
            % Set pool directory according to analysis folder
            settings_objectname = getappdata(callerID, 'settings_objectname');
            pool.directory = strcat(settings_objectname.data_analysisindir,'/',pool.directory);
            % Store pool reference collector into
            % session environment
            setappdata(callerID, 'pool_instances', pool_instances);
        end
        % --------------------------------------------------------------------
        function buildGUInterface(pool, GraphicHandle, globalHandle)
            if nargin >= 2
                pool.handleGraphics = GraphicHandle;
            elseif nargin == 1
                hMainGui = getappdata(0, 'hMainGui');
                pool_instances = getappdata(hMainGui, 'pool_instances');
                globalHandle = pool_instances;
            end
            
            pool.handleJTreeTable   = uitreetable_serverpool(pool.handleGraphics, globalHandle);
        end
        % --------------------------------------------------------------------
        function activatePool(pool)
            pool.active = true;
            notify(pool,'PoolModified');
        end
        % --------------------------------------------------------------------
        function deactivatePool(pool)
            pool.active = false;
            notify(pool,'PoolModified');
        end
        % --------------------------------------------------------------------
    end
    
end

