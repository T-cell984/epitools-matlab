function LoadEpiTools()
%SetWorkingDirectory Tells Matlab where to find EpiTools

%obtain absolute location on system
current_script_path = matlab.desktop.editor.getActive().Filename;
[file_path,~,~] = fileparts(current_script_path);

%define current working directory!
cd(file_path)

% set epitool script location
addpath([fileparts(file_path),'/MatlabScripts'])
addpath([fileparts(file_path),'/EpitoolComponents/'])
javaaddpath([fileparts(file_path),'/OME_LOCI_TOOLS/loci_tools.jar'])
addpath([fileparts(file_path),'/OME_LOCI_TOOLS'])

fprintf('Successfully loaded EpiTool functions from: %s\n',fileparts(file_path));

end

