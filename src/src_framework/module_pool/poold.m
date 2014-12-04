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
            % ClientOutMessage.uid = client process code
            % ClientOutMessage.path = client relative location path
            % ClientOutMessage.tagstruct = tag structure to exported
            % ClientOutMessage.execvalues = values exported from command execution
            %% Extract tag structure from clientRequest
            tagstruct = clientProcess.tagstruct;
            %% Substitute variables with values from command execution
            % Check if a tag.xml file exists in the client process directory 
            if(exist([clientProcess.path,'/tags.xml'],'file'))
                % Read the file
                tag_template = xml_read([clientProcess.path,'/tags.xml']);
                % Recursively process every TAG in the exported tag list           
                for i=1:numel(clientProcess.tagstruct)
                    for o = 1:numel(tag_template.tag(strcmp({tag_template.tag.uid},...
                                    clientProcess.tagstruct(i).tag)).attributes.attribute)     
                        if (isa(tag_template.tag(strcmp({tag_template.tag.uid},...
                             clientProcess.tagstruct(i).tag)).attributes.attribute(o).path,'double'))
                             exp = regexp(num2str(tag_template.tag(strcmp({tag_template.tag.uid},...
                             clientProcess.tagstruct(i).tag)).attributes.attribute(o).path),...
                             '\$(.*?)\$',...
                             'match');
                        else
                             exp = regexp(tag_template.tag(strcmp({tag_template.tag.uid},...
                             clientProcess.tagstruct(i).tag)).attributes.attribute(o).path,...
                             '\$(.*?)\$',...
                             'match');
                        end
                        if(~isempty(exp))
                            exp2 = strrep(exp, '$', '');
                            c = clientProcess.execvalues.ref;
                            if(~strcmp(exp2,c) == 0)
                                newval = clientProcess.execvalues(strcmp(exp2,c)).object;
                                if isa(newval,'double');newval = num2str(newval); end
                                tag_template.tag(strcmp({tag_template.tag.uid},...
                                    clientProcess.tagstruct(i).tag)).attributes.attribute(o).path = strrep(tag_template.tag(strcmp({tag_template.tag.uid},...
                                    clientProcess.tagstruct(i).tag)).attributes.attribute(o).path,...
                                    exp{1},...
                                    newval);
                            end
                        end %if
                    end %for
                end %for
                % Write back to file
                tags = struct(); tags.tag = tag_template.tag;
                current_pool = xml_read(['tmp/',pool.file]);
                fields = fieldnames(current_pool);
                nstruct = struct();
                % If none of the tags are already present in the pool, then merge the structures.
                if(~isempty(find(strcmp({current_pool.tag.uid},{tags.tag.uid}))))
                    
                else
                    id = find(strcmp({current_pool.tag.uid},{tags.tag.uid}));
                    for i = 1:numel(id)
                    % If the tag is already present in the pool file, then overwrite it
                        if(sum(strcmp(current_pool.tag(i).uid,{tags.tag.uid}))~=0)

                            nstruct.tag(i).class      = tags.tag(id(i)).class;
                            nstruct.tag(i).uid        = tags.tag(id(i)).uid;
                            nstruct.tag(i).attributes = tags.tag(id(i)).attributes;
                            nstruct.tag(i).timestamp  = now();
                            nstruct.tag(i).validity   = tags.tag(id(i)).validity;

                        end
                    end
                end
                Pref.StructItem = false;
                xml_write(['tmp/',pool.file], tags, 'tags', Pref);
            end %if
            %% Add pointer to pool list (pool.tags)
            for i=1:numel(tagstruct) 
                if(sum(strcmp(tagstruct(i).tag,pool.tags))>=1)
                    idx = find(strcmp(tagstruct(i).tag,pool.tags),1,'first');
                    pool.tags{idx} = tagstruct(i).tag;
                else
                    pool.tags{end+1} = tagstruct(i).tag;
                end
            end
            %% Append structure to xml definition file  (pool.file)
            
            
            
            %% Send notification for added tag and modified pool
            notify(pool, 'AddedTag');
            notify(pool, 'PoolModified');
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
        function tag = retrieveTag(pool,tagcode)
        
            tags = xml_read(['tmp/',pool.file]);
            level = find(strcmp(tagcode,pool.tags));
            tag = tags.tag(level);

        end
        % --------------------------------------------------------------------
        % Print all tag in the pool
        function getTagList(pool)
        
        end
        % --------------------------------------------------------------------
        % This funciton loads tags stored in xml pool file
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
            notify(pool,'PoolInstance');
        end
        % --------------------------------------------------------------------
        function deactivatePool(pool)
            pool.active = false;
            notify(pool,'PoolInstance');
        end
        % --------------------------------------------------------------------
    end
    
end

