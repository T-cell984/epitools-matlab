function [ status, argout ] = dataindexing_func( input_args, varargin )
%DATAINDEXING_FUNC Creating indeces for selected files to load
% ------------------------------------------------------------------------------
% PREAMBLE
%
% This function will prepare your data to be loaded in Epitools. This allows the 
% programm to load only the files you previously set to be sent to further analysis 
% steps. Given the setting object populated with images metadata file, extract the
% list of files and fill a cell list containing all the informations regard
% accessing data files.
%
% INPUT 
%   1. input_args:  variable containing the analysis object
%   2. varargin:    variable containing extra parameters for ref association 
%                   during output formatting (might not be implemented)
%
% OUTPUT
%   1. status:  status elaboration (0  executed correctly; > 0 fatal error)
%   2. argout:  variable containing a structure with output objects, description 
%               and ref association
%
% REFERENCES
%
% AUTHOR:   Lorenzo Gatti (lorenzo.gatti@alumni.ethz.ch)
%
% DATE:     1.10.14 V0.1 for EpiTools 1.0 beta
%           5.12.14 V0.2 for EpiTools 2.0 beta
% 
% LICENCE:
% License to use and modify this code is granted freely without warranty to all, as long as the 
% original author is referenced and attributed as such. The original author maintains the right 
% to be solely associated with this work.
% 
% Copyright by A.Tournier, A. Hoppe, D. Heller, L.Gatti
% ------------------------------------------------------------------------------
%% Retrieve supplementary arguments (they are exported as reported in the tags.xml file)
if (nargin<2); varargin(1) = {'Indices_Structure'};varargin(2) = {'SETTINGS'}; end
%% Retrieve parameter data
% it is more convenient to recall the setting file with as shorter variable
% name: stgModule
% TODO: input_args{strcmp(input_args(:,1),'SmoothingRadius'),2}
handleSettings = input_args{strcmp(input_args(:,1),'ExecutionSettingsHandle'),2};
tmp = getappdata(getappdata(0,'hMainGui'),'execution_memory');
% Remapping
stgMain = tmp.(char(handleSettings));
%% Status initialization
status = 1;
%% Elaboration
% Prepare Planes (idx) ID images
idxPoints.I = convertInput2Mat(8);
% Prepare Planes (z) Z axis
idxPoints.Z = convertInput2Mat(9);
% Prepare Planes (c) Channels
idxPoints.C = convertInput2Mat(10);
% Prepare Planes (t) Time Points
idxPoints.T = convertInput2Mat(11);
% Set preferences for xml_write procedure
%Pref.StructItem = false;
% Write to xml pool file
%xml_write([stgMain.data_analysisoutdir,'/indices.xml'], idxPoints, 'idxPoints', Pref);
stgMain.AddResult('Indexing','indices',idxPoints);
%% Help functions
    function idxPoints = convertInput2Mat(intItem2Extract)
    % @convertInput2Mat
    % Function to convert user char inputs into single points to pass to
    % further analysis steps.
        % Prepare struct containing indexes of time points to consider:
        idxPoints = [];
        % Table readout from MAIN module
        for i=1:size(stgMain.analysis_modules.Main.data,1);
            tmpidxPoints = [];
            switch intItem2Extract 
                case 8
                    % Discard files where exec property is 0
                    if(logical(cell2mat(stgMain.analysis_modules.Main.data(i,8))) == false)
                        continue;
                    else
                        idxPoints = [idxPoints,i];
                    end
                otherwise                
                    % Discard files where exec property is 0
                    if(logical(cell2mat(stgMain.analysis_modules.Main.data(i,8))) == false)
                        continue;
                    end
                    % all the ranges
                    ans1 = regexp(regexp(char(stgMain.analysis_modules.Main.data(i,intItem2Extract)), '([0-9]*)-([0-9]*)', 'match'),'-','split');
                    for o=1:length((ans1))
                        %idxPoints(i,:) = [idxPoints(i,:),str2double(ans1{o}{1}):str2double(ans1{o}{2})];
                        tmpidxPoints = [tmpidxPoints,str2double(ans1{o}{1}):str2double(ans1{o}{2})]; 
                    end
                    % all the singles *ATT: it can generate NAN values (getting rid of
                    % them with line -> 87
                    ans2 = regexp(char(stgMain.analysis_modules.Main.data(i,intItem2Extract)), '([0-9]*)-([0-9]*)', 'split');
                    for o=1:length(ans2)
                        comma_separated_values = regexp (ans2{o}, ',', 'split');
                        tmpidxPoints = [tmpidxPoints,str2double(comma_separated_values)];
                    end
                    tmpidxPoints = tmpidxPoints(~isnan(tmpidxPoints));
                    tmpidxPoints = sort(tmpidxPoints);
                    idxPoints{i} = tmpidxPoints;
            end
        end
    end
%% Output formatting
% Each single output need to be described in order to be used for variable exportation.
% ARGOUT variable is a structure object
% argout(1...).description = char();
% argout(1...).ref = variable reference;
% argout(1...).object = undefined;
% First output variable
argout(1).description = 'Indices required to load image files';
argout(1).ref = varargin(1);
argout(1).object = 'analysis_modules.Indexing.results.indices';
argout(2).description = 'Settings associated module instance execution';
argout(2).ref = varargin(2);
argout(2).object = input_args{strcmp(input_args(:,1),'ExecutionSettingsHandle'),2};
%% Status execution update 
status = 0;
% TMP: Store idxPoints in settings_file
%input_args.analysis_modules.Main.indices = idxPoints;
%setappdata(getappdata(0,'hMainGui'),'settings_objectname',input_args);
end