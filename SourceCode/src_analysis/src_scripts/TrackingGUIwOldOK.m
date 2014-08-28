function fig = TrackingGUI(ImageSeries,Ilabel,Clabel,ColLabels,Ilabelsout,params, oldOKs, FramesToRegrow_old)

%print_GUI_explanation();

%% Reconversion input parameters

Ilabel = uint8(Ilabel);
Clabel = uint16(Clabel);                                                   %unit16 because more than 256 labels possible!


%% Check on image dimensions
ImSize = size(ImageSeries);
% ImSize = [x, y, t];
% check for single frame
if numel(ImSize) == 2 % of got a single frame here
    SingleFrame = true;
    NFrames = 1;
else
    SingleFrame = false;
    NFrames = ImSize(3);
end

% this typecasting is still necessary?
ImageSeries = double(ImageSeries);
ImageSeries = uint8(ImageSeries/max(ImageSeries(:))*255);                  %todo : check casting!

%% Initialization of the variables

fs=fspecial('laplacian',0.9);

CColors = [];
Itracks = [];
tracklength=[];
trackstarts = [];
trackstartX = [];
trackstartY = [];
oktrajs = oldOKs;

% Seed maker is white
SeedMarker = 255;
% Count user clicks
NClicks = 0;
% Start from the first frame
CurrentFrame = 1;

% Zoom in the area of the seed
zoommode = false;

% Unknown parameter
WindowSize = 100;

% Check final tracking
Ch1On = false;

Cpt = [0 0];
CCellNum = 0;

% Application status
okeydown = false;
deleteMode = false;
delabelMode = false;
showCells = true;
RemoveTrack = false;
AddDummyPt = false;
InspectPt = false;
NeedToRetrack = false;
FramesToRegrow = [];

cellBoundaries = zeros(ImSize,'int8');

%% Gui Preparation 

    % Create a new figure
    fig = figure;
    set(fig,'WindowButtonDownFcn',@wbmFcn)
    set(fig,'KeyPressFcn',@keyPrsFcn)
    if ~SingleFrame
        slider = uicontrol( fig ...
            ,'style'    ,'slider'   ...
            ,'units'    ,'normalized' ...
            ,'position' ,[0.17 0.05 0.80 0.04] ...
            );

        % sliderListener = addlistener(slider,'ContinuousValueChange',@sliderActionEventCb);
        set(slider,'Callback',@sliderActionEventCb);

        set(fig,'WindowScrollWheelFcn',@figScroll);

        set(slider,'max', NFrames);
        set(slider,'min', 1);
        set(slider,'Value', 1);
    end

    cbh1 = uicontrol(fig,'Style','checkbox',...
        'String','Final check',...
        'Value',0, ...
        'units'    ,'normalized', ...
        'Position',[0.04 0.1 0.1 0.04],...
        'Callback',@cb1Callback);

    framenum = uicontrol(fig ...
        ,'style'    ,'edit' ...
        ,'units'    ,'normalized' ...
        ,'position' ,[0.04 0.05 0.1 0.04] ...
        ,'string'   ,1 ...
        );

    
%% First run executions
Retrack();
RecalculateCellBoundaries();
%Retrack();
img = Update();


%% Support functions
% Evaluate the final check
    function cb1Callback(src,evt)
        Ch1On = get(cbh1,'Value');
        img = Update();
    end

    function figScroll(src,evt)
        clicks = evt.VerticalScrollCount;
        CurrentFrame = CurrentFrame - clicks;
        CurrentFrame = max(1,CurrentFrame);
        CurrentFrame = min(NFrames,CurrentFrame);
        set(slider,'Value', CurrentFrame);
        img = Update();
    end

    function sliderActionEventCb(src,evt)
        newi = round(get(src,'Value'));
        if newi == CurrentFrame
            return
        end
        CurrentFrame = newi;
        set(src,'Value',CurrentFrame);
        img = Update();
    end

    function img = Update()
        
        % implicit pass of fig obj
        %figure(fig);
        
        if zoommode
            Irgb = gray2rgb(ImageSeries(:,:,CurrentFrame));
            PaddedIm = zeros(ImSize(1)+200,ImSize(2)+200,3);
            PaddedIm(100:99+ImSize(1), 100:99+ImSize(2),:) = squeeze(Irgb(:, :,:));
            
            % 251 marks the threshold for a seed pixel!
            [cpy cpx]=find(Ilabel(:,:,CurrentFrame) > 251);
            for n =1:length(cpy)
                y = cpy(n); x = cpx(n);
                if (y > Cpt(1)-WindowSize && y < Cpt(1)+WindowSize && x > Cpt(2)-WindowSize && x < Cpt(2)+WindowSize )
                    CelN = Itracks(y,x,CurrentFrame);
                    if CelN ==0
                        col = [1 1 1];
                        TrackL = 0;
                    else
                        col = CColors(CelN,:);
                        col = col*.8;
                        TrackL = tracklength(CelN);
                    end
                    
                    %assuming full tracking is marked here
                    if TrackL == NFrames-1
                        PaddedIm(y-2+100:y+2+100,x-2+100:x+2+100,1) = col(1);
                        PaddedIm(y-2+100:y+2+100,x-2+100:x+2+100,2) = col(2);
                        PaddedIm(y-2+100:y+2+100,x-2+100:x+2+100,3) = col(3);
                        
                        
                        %and incomplete tracking here
                    else
                        %base is a 1px smaller cube
                        PaddedIm(y-1+100:y+1+100,x-1+100:x+1+100,1) = col(1);
                        PaddedIm(y-1+100:y+1+100,x-1+100:x+1+100,2) = col(2);
                        PaddedIm(y-1+100:y+1+100,x-1+100:x+1+100,3) = col(3);
                        
                        if CelN~=0 & ~SingleFrame
                            %if track-problem is due to late start, e.g.
                            %correctly tracked daughter cell, left pixel
                            %is added
                            first_frame_no = trackstarts(CelN);
                            movie_start = 1;
                            if first_frame_no ~= movie_start
                                PaddedIm(y+100,x-2+100:x+100,1) = col(1);
                                PaddedIm(y+100,x-2+100:x+100,2) = col(2);
                                PaddedIm(y+100,x-2+100:x+100,3) = col(3);
                            end
                            
                            %if track-problem is due to premature end, e.g.
                            %eliminated cell, right pixel is added
                            final_frame_no = trackstarts(CelN) + TrackL;
                            movie_length = NFrames;
                            if final_frame_no ~= movie_length
                                PaddedIm(y+100,x+100:x+2+100,1) = col(1);
                                PaddedIm(y+100,x+100:x+2+100,2) = col(2);
                                PaddedIm(y+100,x+100:x+2+100,3) = col(3);
                            end
                            
                            %if trajectory key is found in oktrajs,
                            %a vertical band is added
                            trajectory_key = TrajKey(...
                                trackstartX(CelN), trackstartY(CelN) ,trackstarts(CelN));
                            if ~isempty(find(oktrajs == trajectory_key, 1))
                                PaddedIm(y-2+100:y+2+100,x+100,1) = col(1);
                                PaddedIm(y-2+100:y+2+100,x+100,2) = col(2);
                                PaddedIm(y-2+100:y+2+100,x+100,3) = col(3);
                            end
                        end
                    end
                end
            end
            if showCells
                PaddedIm(100:end-101,100:end-101,1) = .5*double(cellBoundaries(:,:,CurrentFrame)) + PaddedIm(100:end-101,100:end-101,1).*(1-double(cellBoundaries(:,:,CurrentFrame)));
                PaddedIm(100:end-101,100:end-101,2) = .2*double(cellBoundaries(:,:,CurrentFrame)) + PaddedIm(100:end-101,100:end-101,2).*(1-double(cellBoundaries(:,:,CurrentFrame)));
                PaddedIm(100:end-101,100:end-101,3) = .2*double(cellBoundaries(:,:,CurrentFrame)) + PaddedIm(100:end-101,100:end-101,3).*(1-double(cellBoundaries(:,:,CurrentFrame)));
            end
            
            img = imshow(PaddedIm(Cpt(1)-WindowSize+100:Cpt(1)+WindowSize+100,Cpt(2)-WindowSize+100:Cpt(2)+WindowSize+100,:));
            
        else
            
            Irgb = gray2rgb(ImageSeries(:,:,CurrentFrame));
            
            [cpy cpx]=find(Ilabel(:,:,CurrentFrame) > 253);
            for n =1:length(cpy)
                y = cpy(n); x = cpx(n);
                CelN = Itracks(y,x,CurrentFrame);
                if CelN ==0
                    col = [1 1 1];
                else
                    col = CColors(CelN,:);
                    col = col*.8;
                    TrackL = tracklength(CelN);
                end
                
                ymin = max(y-2,1); ymax = min(y+2,ImSize(1));
                xmin = max(x-2,1); xmax = min(x+2,ImSize(2));
                if ~SingleFrame &&  CelN ~=0 && tracklength(CelN) ~= NFrames-1 && isempty(find(oktrajs == TrajKey(trackstartX(CelN), trackstartY(CelN) ,trackstarts(CelN))))
                    Irgb(ymin:ymax,xmin:xmax,:) = 1;
                else
                    if CelN ==0
                        Irgb(ymin:ymax,xmin:xmax,:) = 1;
                    end
                end
                
                if ~Ch1On
                    Irgb(ymin+1:ymax-1,xmin+1:xmax-1,1) = col(1);
                    Irgb(ymin+1:ymax-1,xmin+1:xmax-1,2) = col(2);
                    Irgb(ymin+1:ymax-1,xmin+1:xmax-1,3) = col(3);
                end
            end
            
            if showCells
                Irgb(:,:,1) = .5*double(cellBoundaries(:,:,CurrentFrame)) + Irgb(:,:,1).*(1-double(cellBoundaries(:,:,CurrentFrame)));
            end
            
            img = imshow(Irgb);
            
        end
        
        
        set(img,'ButtonDownFcn',@wbmFcn)
        
        set(framenum,'String',CurrentFrame);
        drawnow
    end

%deletion of a point, intensity 25 is assigned
    function deletePt(x,y,Frame)
        Ilabel(y, x,Frame) = 25;
        Itracks(y,x,Frame) = 0;
    end

    function neutralisePt(x,y,Frame)
        Ilabel(y, x,Frame) = 253;
        Itracks(y,x,Frame) = 0;
    end

    function deletePtsAround(pt)
        [cpy cpx]=find(Ilabel(:,:,CurrentFrame) > 251);
        for n =1:length(cpy)
            y = cpy(n); x = cpx(n);
            dist = sqrt((y-pt(2))^2 + (x-pt(1))^2);
            if dist < 20
                deletePt(x,y,CurrentFrame);
            end
        end
    end

    function k = TrajKey(cpx,cpy,strt)
        k = 1000000*strt + 1000*cpx + cpy;
    end

% WBMFCN or WindowButtonMotionFunCtioN
% i.e. what happens for MOUSE events
    function wbmFcn(src,evt)
        pt = get(gca,'Currentpoint');
        pt = round([pt(1,1), pt(1,2)]);
        
        % -----------------------------------------------------------------
        % in order to get rid of the click outside the image frame
        xlim = get(img,'XData');
        ylim = get(img,'YData');
             
        if(isempty(find([xlim(1):xlim(2)] == pt(1),1))); return;end
        if(isempty(find([ylim(1):ylim(2)] == pt(2),1))); return;end
        % -----------------------------------------------------------------
        
        mouseuse  = get(gcf,'SelectionType');
        %PropsOfCell(pt)
        
        %LEFT MOUSE BUTTON
        if strcmp(mouseuse ,'normal')
            NClicks = NClicks + 1;
            if zoommode
                % Any modification requires the frame to be resegmented
                if isempty(find(FramesToRegrow==CurrentFrame) )
                    FramesToRegrow(length(FramesToRegrow)+1) = CurrentFrame;
                end
                
                % NORMAL ACTION, i.e. not delete mode
                if ~delabelMode
                    
                    if InspectPt && NeedToRetrack
                        Retrack();
                        NeedToRetrack = true;
                    end
                    
                    % find all known seeds
                    [cpy cpx]=find(Ilabel(:,:,CurrentFrame) > 251);
                    OnASeed = false;
                    
                    % loop through all seeds
                    for n =1:length(cpy)
                        y = cpy(n); x = cpx(n);
                        
                        %check whether the user hit the seed square
                        if (y > pt(2)-3 + Cpt(1)-WindowSize && y < pt(2)+1 + Cpt(1)-WindowSize && x > pt(1)-3 + Cpt(2)-WindowSize && x < pt(1)+1 + Cpt(2)-WindowSize)
                            n = Itracks(y,x,CurrentFrame);
                            
                            % INSPECT
                            if InspectPt && n ~=0
                                fprintf('Track starts at %i and finishes at %i \n',trackstarts(n),trackstarts(n)+tracklength(n));
                                if trackstarts(n) ~= 1
                                    CurrentFrame = trackstarts(n)-1;
                                end
                                if trackstarts(n)+tracklength(n) ~= NFrames
                                    CurrentFrame = trackstarts(n)+tracklength(n)+1;
                                end
                            end
                            
                            % OK
                            if okeydown  && n ~=0 % mark this traj as ok even (delaminating cell or cell created during traj)
                                oktrajs = [oktrajs , TrajKey(trackstartX(n),trackstartY(n),trackstarts(n))];
                            end
                            
                            % REMOVE
                            if ~RemoveTrack
                                if ~InspectPt && ~okeydown deletePt(x,y,CurrentFrame); end
                                
                                % ADD-PARTICLE
                            else
                                N = Itracks(y,x,CurrentFrame);
                                Ilabel(Itracks==N) = 253;
                                Itracks(Itracks==N) = 0;
                                RemoveTrack = false;
                            end
                            
                            OnASeed = true;
                            break;
                        end
                    end
                    if InspectPt InspectPt = false; end
                    if okeydown okeydown = false; end
                    if ~OnASeed
                        if ~AddDummyPt
                            Ilabel(Cpt(1)-WindowSize+pt(2)-1, Cpt(2)-WindowSize+pt(1)-1,CurrentFrame) = SeedMarker;
                        else
                            Ilabel(Cpt(1)-WindowSize+pt(2)-1, Cpt(2)-WindowSize+pt(1)-1,CurrentFrame) = 253;
                            AddDummyPt = false;
                        end
                    end
                    Retrack();
                    NeedToRetrack = true;
                    
                else
                    % delete Label here!
                    lbl = Clabel(pt(2) + Cpt(1)-WindowSize,pt(1) + Cpt(2)-WindowSize,CurrentFrame);
                    if lbl ~=0
                        F = Ilabel(:,:,CurrentFrame);
                        C = Clabel(:,:,CurrentFrame);
                        Cnum = C(Cpt(1)-WindowSize+pt(2)-1,Cpt(2)-WindowSize+pt(1)-1)
                        Clabel(:,:,CurrentFrame) = C.*int16(C~=Cnum);
                        
                        F = F.*uint8(C==Cnum);
                        [cpy cpx]=find(F > 252)
                        neutralisePt(cpx,cpy,CurrentFrame);
                        
                        cellBoundaries(:,:,CurrentFrame) = filter2(fs,Clabel(:,:,CurrentFrame)) >.5;
                    end
                end
            else
                if deleteMode
                    deletePtsAround(pt)
                    set(src,'WindowButtonMotionFcn',@wbmcbDel);
                    set(src,'WindowButtonUpFcn',@wbucbDel);
                else
                    zoommode = true;
                    Cpt = [pt(2) pt(1)];
                    CCellNum = 0;
                end
            end
        end
        
        %RIGHT MOUSE BUTTON
        if strcmp(mouseuse ,'alt')
            if zoommode
                [cpy cpx]=find(Ilabel(:,:,CurrentFrame) > 251);
                for n =1:length(cpy)
                    y = cpy(n); x = cpx(n);
                    if (y > pt(2)-3 + Cpt(1)-WindowSize && y < pt(2)+1 + Cpt(1)-WindowSize && x > pt(1)-3 + Cpt(2)-WindowSize && x < pt(1)+1 + Cpt(2)-WindowSize)
                        cnum = Itracks(y,x,CurrentFrame);
                        if cnum ~= 0
                            fprintf('label=%i x=%i y=%i cellnum=%i tracklen=%i trackStart=%i\n' ,Ilabel(y, x,CurrentFrame),x,y,cnum,tracklength(cnum),trackstarts(cnum))
                        else
                            fprintf('label=%i x=%i y=%i \n' ,Ilabel(y, x,CurrentFrame),x,y);
                        end
                        break
                    end
                end
                xinit = pt(1); yinit = pt(2);
                Cptinit = Cpt;
                set(src,'WindowButtonMotionFcn',@wbmcb);
                set(src,'WindowButtonUpFcn',@wbucb);
            else
                if deleteMode
                    % delete label of this cell
                    F = Ilabel(:,:,CurrentFrame);
                    C = Clabel(:,:,CurrentFrame);
                    Cnum = C(pt(2),pt(2));
                    Clabel(:,:,CurrentFrame) = C.*int16(C~=Cnum);
                    F = F.*int16(C~=Cnum);
                    [cpy cpx]=find(F > 252)
                    deletePt(cpy,cpx,CurrentFrame);
                end
            end
        end
        
        img = Update();
        
        % CallBack funtions for NORMAL mode
        function wbmcb(src,evnt)
            cp = get(gca,'CurrentPoint');
            xdat = [xinit,cp(1,1)];
            ydat = [yinit,cp(1,2)];
            Cpt(1) = round(Cptinit(1)-cp(1,2)+yinit);
            Cpt(2) = round(Cptinit(2)-cp(1,1)+xinit);
            img = Update();
        end
        
        function wbucb(src,evnt)
            set(src,'Pointer','arrow')
            set(src,'WindowButtonMotionFcn','')
            set(src,'WindowButtonUpFcn','')
        end
        
        % CallBack funtions for DELETE mode
        function wbmcbDel(src,evnt)
            cp = get(gca,'CurrentPoint');
            cp = round([cp(1,1), cp(1,2)]);
            deletePtsAround(cp)
            img = Update();
        end
        
        function wbucbDel(src,evnt)
            set(src,'WindowButtonMotionFcn','')
            set(src,'WindowButtonUpFcn','')
        end
        
    end

% KEY PRESS FUNCTION
    function keyPrsFcn(src,evt)
        ch = get(gcf,'CurrentCharacter');
        switch ch
            case {29} %RIGHT ARROW
                if CurrentFrame < size(Ilabel,3)
                    CurrentFrame = CurrentFrame+1;
                end
                set(slider,'Value', CurrentFrame);
                img = Update();
            case {28} %LEFT ARROW
                if CurrentFrame > 1
                    CurrentFrame = CurrentFrame-1;
                end
                set(slider,'Value', CurrentFrame);
                img = Update();
            case {'n'}
                GotoNextProbPt();
                img = Update();
            case {' '} %SPACE BAR
                zoommode = false;
                Retrack();
                img = Update();
            case {'r'}
                Retrack();
                img = Update();
            case {'s'}
                fprintf('Saving ... ');
                ILabels = Ilabel;
                FramesToRegrow = union(FramesToRegrow,FramesToRegrow_old);
                save(Ilabelsout,'ILabels','FramesToRegrow','oktrajs');
                fprintf('done\n');
                close(gcf);
            case {'o'}
                okeydown = true;
            case {'d'}
                if ~deleteMode
                    disp('delete mode!')
                    deleteMode = true;
                else
                    disp('delete mode OFF!')
                    deleteMode = false;
                end
            case {'h'}
                if showCells
                    showCells = false;
                else
                    showCells = true;
                end
                Update();
            case {'t'}
                RemoveTrack = true;
            case {'a'}
                AddDummyPt = true;
            case {'i'}
                InspectPt = true;
        end
    end

    function Retrack()
        fprintf('Retracking!')
        tic
        %output vectors
        % Itracks       - 3D information with seed information (255)
        % pTracks       - position of the track (max 100K) for each time point
        %                 (track_id, frame_no, (x,y))
        % trackstarts   - frame no where the track starts
        % trackstartX   - initial position X
        % trackstartY   - initial position Y
        
        if ~SingleFrame
            [Itracks, pTracks, tracklength, trackstarts, trackstartX, trackstartY]= ....
                cellTracking4(Ilabel,params.TrackingRadius);
            NC=max(Itracks(:));
            CColors = double(squeeze(label2rgb([1:NC],'jet','k','shuffle')))/255.;
        else
            
            Itracks = Clabel.*uint16(Ilabel > 253);
            NC = max(Clabel(:));
            tracklength = ones(NC);
            CColors = double(squeeze(label2rgb([1:NC],'jet','k','shuffle')))/255.;
            
        end
        
        
        fprintf('Done! %i Clicks', NClicks)
        toc
        
    end

    function RecalculateCellBoundaries()
        for ff = 1:NFrames
            cellBoundaries(:,:,ff) = filter2(fs,Clabel(:,:,ff)) >.5;
        end
    end

%     function print_GUI_explanation()
%
%         disp('This GUI allows the user to see the tracks automatically build by');
%         disp(' celltracking4.cc');
%         disp(' celltracking4 is C code which needs to be compiled for matlab:');
%
%         fprintf('\n');
%
%         disp(' >>mex celltracking4.cc');
%
%         fprintf('\n');
%
%         disp(' The GUI show the seeds as given by ILabels');
%         disp('              the boundaries as given by ColLabels');
%         disp('              the registered images RegIm as background image');
%
%         fprintf('\n');
%
%         disp(' You can scroll through the time-trajectory using the scroll on the mouse');
%         disp(' or the slider or the left/rigth arrows');
%
%         fprintf('\n');
%
%         disp(' You can zoom into the picure by right-clicking into it, you get out of');
%         disp(' zoom-mode by pressing the <space> bar');
%
%         fprintf('\n');
%
%         disp(' In zomm-mode the trajectories which go all the was through the stack are');
%         disp(' larger, the other are potential problems');
%
%         fprintf('\n');
%
%         disp(' You can delete a seed by clicking on it and place another one by clicking');
%         disp(' in a free space. The algo will automatically recalculate the');
%         disp(' trajectories.');
%
%         fprintf('\n');
%
%         disp(' by pressing ''i'' (for ''inspect'') before clicking on such a potential problem seed, the');
%         disp(' software will take you to the timeframe where it thinks the problem is');
%         disp(' (might be just after / before!)');
%
%         fprintf('\n');
%
%         disp(' by pressing ''o'' (for ''ok'') before clicking on such a potential problem seed you');
%         disp(' indicate that you have checked this trajectory and altough it does not go');
%         disp(' through the whole stack, it will not be flagged as a problem anymore');
%         disp(' (could be due to a delamination or a cell division event)');
%
%         fprintf('\n');
%
%         disp(' You can toggle showing the segmentation on/off using ''h'' (for ''hide'')');
%
%         fprintf('\n');
%
%         disp(' if you click the ''final check'' button, you will only be shown the');
%         disp(' remaining problem areas');
%
%         fprintf('\n');
%
%         disp(' pressing ''s'' (for ''save'') saves your new seeding into the file specified in ''output''');
%
%         fprintf('\n');
%         fprintf('\n');
%
%         disp(' parameters');
%
%         disp(' TrackingRadius: the algo performs a search of the seeds in the next');
%         disp(' frame, assigning those that are closest to their former position first');
%         disp(' and progressively searching further up to the distance specified in TrackingRadius');
%
%         fprintf('\n');
%
%         disp(' ''t'' to delete an entire track');
%
%         fprintf('\n');
%
%         disp(' ''d'' to ''wipe'' out whole areas of seed, when you want to get rid of lots');
%         disp(' of seeds');
%
%         fprintf('\n');
%
%         disp(' You can pan the view using the right mouse button');
%
%     end

end