classdef sandbox < handle
    %SANDBOX is a class containing methods and properties associated with sandbox evironment
    % ------------------------------------------------------------------------------
    % PREAMBLE
    %
    % Sandox is an object class containing the specifics of a sandbox object
    % which is declared when a module of the analysis is run twice by the user. It
    % allows the execution to store specific parts of the analysis in a safe
    % environment where the analysis execution does not affect the already obtained
    % results.
    %
    % REFERENCES
    %
    % AUTHOR:   Lorenzo Gatti (lorenzo.gatti@alumni.ethz.ch)
    %
    % DATE:     10.08.14 V0.1 for EpiTools 0.1 beta
    %
    % LICENCE:
    % License to use and modify this code is granted freely without warranty to all, as long as the
    % original author is referenced and attributed as such. The original author maintains the right
    % to be solely associated with this work.
    
    % Copyright by A.Tournier, A. Hoppe, D. Heller, L.Gatti
    % ------------------------------------------------------------------------------
    properties (SetAccess = private)
        sandbox_status = 0;
    end
    
    properties
        module_name = '';
        analysis_settings = struct();
        analysis_tmpdirpath = '';
        results_validity = true;
        results_overrite = false;
        results_backup = false;
        backup_directory = '';
        backup_validity = false;
    end
    
    methods
        % -------------------------------------------------------------------------
        function sdb = sandbox()
            %  SANDBOX  sandbox initialises the	object sandbox setting its status
            %  to 1 (open)
            sdb.sandbox_status = 1;
            sdb.module_name = '';
            sdb.analysis_tmpdirpath = strcat('tmp_',randChar(10,1, char(['a':'z' '0':'9'])));
            sdb.analysis_settings = struct();
            sdb.results_validity = true;
            sdb.results_overrite = false;
            sdb.results_backup = false;
            sdb.backup_directory = strcat('backup_',randChar(10,1, char(['a':'z' '0':'9'])));
            sdb.backup_validity = false;
            % -------------------------------------------------------------------------
            % Log status of current application status
            log2dev(sprintf('Sanbox environment | status: %i ', sdb.sandbox_status), 'DEBUG');
            log2dev(sprintf('Sanbox environment | analysis_tmpdirpath: %s',sdb.analysis_tmpdirpath ), 'VERBOSE');
            log2dev(sprintf('Sanbox environment | results_validity: %i', sdb.results_validity), 'VERBOSE');
            log2dev(sprintf('Sanbox environment | results_overrite: %i',sdb.results_overrite), 'VERBOSE');
            log2dev(sprintf('Sanbox environment | results_backup: %i',sdb.results_backup), 'VERBOSE');
            log2dev(sprintf('Sanbox environment | backup_directory: %s',sdb.backup_directory), 'VERBOSE');
            log2dev(sprintf('Sanbox environment | backup_validity: %i',sdb.backup_validity), 'VERBOSE');
            % -------------------------------------------------------------------------
            
        end
        % -------------------------------------------------------------------------
        function setSandBox(sdb, mdname, mdsett)
            %  CREATESANDBOX CreateSandbox initialises the sandbox object for a
            % 	specific module of the current analysis. The user has to specify
            % 	the following parameters:
            %	mdname =  name of the module the user wants to re-run
            %	mdsett =  struct object containing the specifics of the
            %			  module
            if (nargin == 3)
                if (sdb.sandbox_status == 0);
                    log2dev(sprintf('Your sandbox has not been opened.'), 'WARN');
                    return;
                end
                if (isa(mdname, 'char') && isa(mdsett, 'settings'))
                    % Duplicate settings file and initialize a new instance of the module 
                    % Duplicate setting objects and save content
                    int = settings();
                    int.inheritSettings(mdsett);
                    int.DestroyModule(mdname);
                    int.initialiseModule(mdname);
                    sdb.module_name = mdname;
                    sdb.analysis_settings = int;
                    log2dev(sprintf('Sanbox environment | module_name: %s',sdb.module_name), 'VERBOSE');
                    return;
                else
                    %% trown matlab exception for class parameters not allowed
                    return;
                end
            else
                %% trown matlab exception for number parameters below expectances
                return;
            end
        end
        % -------------------------------------------------------------------------
        function getSandbox(sdb)
            if (sdb.sandbox_status == 0);
                log2dev(sprintf('Your sandbox has not been opened.'), 'WARN');
                return;
            end
            % If a module hame has been specified, then call the executor file
            if (~isempty(sdb.module_name) && ~isempty(sdb.analysis_settings))
                % When a new sandbox is instantiated it will redirect the new results in a
                % temporary directory.
                if ((sdb.results_validity) && (~sdb.results_overrite))
                    % Indicate an alternative directory to store the objects computed as
                    % outputs from the analysis.
                    sdb.analysis_settings.data_analysisoutdir = [sdb.analysis_settings.data_fullpath,'/', sdb.analysis_tmpdirpath];
                    log2dev(sprintf('Sanbox environment has set the analysis-dir-out path to: %s',sdb.analysis_settings.data_analysisoutdir), 'VERBOSE');
                    % Create the temporary directory where the files will be stored
                    mkdir([sdb.analysis_settings.data_fullpath,'/', sdb.analysis_tmpdirpath]);
                    log2dev(sprintf('Sanbox environment has created the analysis-dir-out path in: %s',sdb.analysis_settings.data_analysisoutdir), 'VERBOSE');
                end
                log2dev(sprintf('Sanbox environment is going to execute the module: %s',sdb.module_name), 'VERBOSE');
            end
        end
        % -------------------------------------------------------------------------
        function destroySandbox(sdb)
            boolean = true;
            % Evaluate boolean specifics in order to save/destroy/redirect files & directories.
            % -------------------------------------------------------------------------
            % Log status of current application status
            log2dev(sprintf('Sanbox environment | status: %i ', sdb.sandbox_status), 'DEBUG');
            log2dev(sprintf('Sanbox environment | analysis_tmpdirpath: %s',sdb.analysis_tmpdirpath ), 'VERBOSE');
            log2dev(sprintf('Sanbox environment | results_validity: %i', sdb.results_validity), 'VERBOSE');
            log2dev(sprintf('Sanbox environment | results_overrite: %i',sdb.results_overrite), 'VERBOSE');
            log2dev(sprintf('Sanbox environment | results_backup: %i',sdb.results_backup), 'VERBOSE');
            log2dev(sprintf('Sanbox environment | backup_directory: %s',sdb.backup_directory), 'VERBOSE');
            log2dev(sprintf('Sanbox environment | backup_validity: %i',sdb.backup_validity), 'VERBOSE');
            % -------------------------------------------------------------------------
            % Should I keep new execution results?
            if(sdb.results_validity)
                % Do the new results have to ovverite the old ones?
                if(sdb.results_overrite)
                    % Do I want to backup the old results?
                    if(sdb.results_backup)
                        % Create the backup directory where the files will be moved
                        mkdir([sdb.analysis_settings.data_fullpath,'/', sdb.backup_directory]);
                        log2dev(sprintf('Sanbox environment has created a backup directory in: %s',[sdb.analysis_settings.data_fullpath,'/', sdb.backup_directory]), 'VERBOSE');
                        % Copy files from the old analysis folder to the new one
                        copyfile(sdb.analysis_settings.data_analysisindir,...
                            [sdb.analysis_settings.data_fullpath,'/', sdb.backup_directory]);
                        log2dev(sprintf('Sanbox environment has copied files from %s to %s',...
                            sdb.analysis_settings.data_analysisindir,...
                            [sdb.analysis_settings.data_fullpath,'/', sdb.backup_directory]),...
                            'VERBOSE');
                    end
                    % Delete all the files contained in the old analysis directory
                    %delete(strcat(sdb.analysis_settings.data_analysisindir,'/*'));
                    % Copy the newly-generated result files into the analysis folder
                    copyfile([sdb.analysis_settings.data_fullpath,'/', sdb.analysis_tmpdirpath],...
                        sdb.analysis_settings.data_analysisindir, 'f');
                    log2dev(sprintf('Sanbox environment has copied new generated files from %s to %s',...
                        [sdb.analysis_settings.data_fullpath,'/', sdb.analysis_tmpdirpath],...
                        sdb.analysis_settings.data_analysisindir),...
                        'VERBOSE');
                    % Remove temporary directory
                    rmdir([sdb.analysis_settings.data_fullpath,'/', sdb.analysis_tmpdirpath], 's');
                    log2dev(sprintf('Sanbox environment has removed the temporary folder in %s',...
                        [sdb.analysis_settings.data_fullpath,'/', sdb.analysis_tmpdirpath]),...
                        'VERBOSE');
                    % Reassign correct location to results saved during the
                    % module execution
                    arrayResults = fields(sdb.analysis_settings.analysis_modules.(char(sdb.module_name)).results);
                    log2dev(sprintf('Sanbox environment has found %i entry/entries to remap',...
                        numel(arrayResults)),...
                        'VERBOSE');
                    % In case the new results are not going to ovverite the previous results
                else
                    % IMPLEMENTATION IS DUE HERE
                end
                % I discard the second-run-generated results
            else
                % Remove temporary directory
                rmdir([sdb.analysis_settings.data_fullpath,'/', sdb.analysis_tmpdirpath],'s');
                
                log2dev(sprintf('Sanbox environment has removed the discarded results in %s ',...
                    [sdb.analysis_settings.data_fullpath,'/', sdb.analysis_tmpdirpath]),...
                    'VERBOSE');
            end
            
        end
        % -------------------------------------------------------------------------
        function createBackups(sdb)
        end
        % -------------------------------------------------------------------------
        function getAccessPaths(sdb)
        end
    end
end
