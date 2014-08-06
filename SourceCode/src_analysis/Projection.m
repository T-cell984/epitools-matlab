function [varargout] = Projection(stgObj)
%SurfaceProjection Discover the surface of the highest intensity signal in
%the image stack and selectively project the signal lying on that surface
%
%   DataSpecificsPath - Path Data to analyze (See InspectData function)
%   SmoothingRadius - how much smoothing to apply to original data (1-5)
%   SurfSmoothness1 - 1st surface fitting, surface stiffness ~100
%   SurfSmoothness2 - 2nd surface fitting, stiffness ~50
%   ProjectionDepthThreshold - how much up/down to gather data from surface
%
% todo: need to convert to int8 in a rational way here!
% can use 95 or 99% quantile of the data and then scale


%initialize progressbar
progressbar('Projecting images...');

global_time_index = 0;
intProcessedFiles = 0;


% it is more convenient to recall the setting file with as shorter variable
% name: stgModule
stgModule = stgObj.analysis_modules.Projection.settings;

fprintf('Started projection at %s',datestr(now));


% if(stgObj.platform_units ~= 1)
%     %pbar = ProgressBarParLoops(length(intIMGFileidx),'hFPGui','PBarLoadFiles');
%     matlabpool('local',stgObj.platform_units);
% end

has_data_from_gui = stgObj.hasModule('Main');


% For loop for all files in the folder (lst) and second parfor for all timepoints
if(has_data_from_gui)
    no_of_images = size(stgObj.analysis_modules.Main.data,1);
else
    %temporary fix for gui-less test_case
    no_of_images = 1;
end

for i=1:no_of_images
    
    if(has_data_from_gui)
    
        %% Table readout from MAIN module
        % Discard files where exec property is 0
        if(logical(cell2mat(stgObj.analysis_modules.Main.data(i,8))) == false)
            continue;
        end
        
        % If the first file is being processed, then initialize variables
        % Surface, ProjIm
        if(intProcessedFiles == 0)
            Surfaces = zeros(cell2mat(stgObj.analysis_modules.Main.data(i,3)),...
                cell2mat(stgObj.analysis_modules.Main.data(i,2)),...
                cell2mat(stgObj.analysis_modules.Main.data(i,6)),...
                'uint8');
            ProjIm = zeros(cell2mat(stgObj.analysis_modules.Main.data(i,3)),...
                cell2mat(stgObj.analysis_modules.Main.data(i,2)),...
                cell2mat(stgObj.analysis_modules.Main.data(i,6)),...
                char(stgObj.analysis_modules.Main.data(i,7)));
        end
        
        idxTimePoints = [];
        % Prepare vector containing indexes of time points to consider:
        % all the ranges
        ans1 = regexp(regexp(char(stgObj.analysis_modules.Main.data(i,11)), '([0-9]*)-([0-9]*)', 'match'),'-','split');
        
        for o=1:length((ans1))
            
            idxTimePoints = [idxTimePoints,str2double(ans1{o}{1}):str2double(ans1{o}{2})];
            
        end
        
        % all the singles *ATT: it can generate NAN values (getting rid of
        % them with line>
        ans2 = regexp(char(stgObj.analysis_modules.Main.data(i,11)), '([0-9]*)-([0-9]*)', 'split');
        
        for o=1:length(ans2)
            
            idxTimePoints = [idxTimePoints,str2double(strsplit(ans2{o},','))];
            
        end
        
        idxTimePoints = idxTimePoints(~isnan(idxTimePoints));
        idxTimePoints = sort(idxTimePoints);
        
        current_file_name = char(stgObj.analysis_modules.Main.data(i,1));
        % Obtain image file full path
        strFullPathFile = [stgObj.data_imagepath,'/',current_file_name];
        
        % Read image file data
        Series = 1;
        Data = ReadMicroscopyData(strFullPathFile, Series);
        Data.images = squeeze(Data.images); % get rid of empty

    else
        %consider test file to be a single file
        strFullPathFile = stgObj.data_imagepath;
        [~,name,ext] = fileparts(strFullPathFile);
        current_file_name = [name,ext];
        
        % Read image file data
        Series = 1;
        Data = ReadMicroscopyData(strFullPathFile, Series);
        Data.images = squeeze(Data.images); % get rid of empty
        
        % Custom preallocation
        Surfaces = zeros(Data.NY,Data.NX,Data.NT,'uint8');
        ProjIm = zeros(Data.NY,Data.NX,Data.NT, Data.PixelType);
        idxTimePoints = 1:Data.NT;
    end
    
    %% Project data

    fprintf('Working on %s\n', current_file_name);
    
    if(stgObj.platform_units ~= 1)
        
        ppm = ParforProgressStarter2(['Parallel processing file',current_file_name],...
                                     length(idxTimePoints),...
                                     0.1,...
                                     0,...
                                     0,...
                                     1);
        
        parfor local_time_index = 1:length(idxTimePoints)
            
            
            ImStack = Data.images(:,:,:,idxTimePoints(local_time_index));
            
            [im,Surf] = createProjection(ImStack,...
                stgModule.SmoothingRadius,...
                stgModule.ProjectionDepthThreshold,...
                stgModule.SurfSmoothness1,...
                stgModule.SurfSmoothness2,...
                stgModule.InspectResults);
            
            ProjIm(:,:,local_time_index+global_time_index) = im;
            Surfaces(:,:,local_time_index+global_time_index) = Surf;
            ppm.increment(local_time_index)
            
        end
        delete(ppm)
    else % non parallel loop
        for local_time_index = 1:length(idxTimePoints)
            
            
            ImStack = Data.images(:,:,:,idxTimePoints(local_time_index));
            
            [im,Surf] = createProjection(ImStack,...
                stgModule.SmoothingRadius,...
                stgModule.ProjectionDepthThreshold,...
                stgModule.SurfSmoothness1,...
                stgModule.SurfSmoothness2,...
                stgModule.InspectResults);
            
            ProjIm(:,:,local_time_index+global_time_index) = im;
            Surfaces(:,:,local_time_index+global_time_index) = Surf;
            
            progressbar(((local_time_index-1)*length(idxTimePoints)+idxTimePoints(local_time_index))/length(idxTimePoints)/length(idxTimePoints));
            
        end
    end
    global_time_index=global_time_index+length(idxTimePoints);
    intProcessedFiles = intProcessedFiles+1;
    
end

stgObj.AddResult('Projection','projection_path',strcat(stgObj.data_analysisdir,'/ProjIm'));
stgObj.AddResult('Projection','surface_path',strcat(stgObj.data_analysisdir,'/ProjIm'));

save([stgObj.data_analysisdir,'/ProjIm'],'ProjIm')
save([stgObj.data_analysisdir,'/Surfaces'],'Surfaces')

progressbar(1);
fprintf('Finished projection at %s\n',datestr(now));


% if(stgObj.platform_units ~= 1)
%     %pbar = ProgressBarParLoops(length(intIMGFileidx),'hFPGui','PBarLoadFiles');
%     matlabpool close
% end

if(has_data_from_gui)
    if(stgObj.icy_is_used)
        icy_vidshow(ProjIm,'Projected Sequence');
    else
        StackView(ProjIm,'hMainGui','figureA');
    end
else
    StackView(ProjIm)
end

