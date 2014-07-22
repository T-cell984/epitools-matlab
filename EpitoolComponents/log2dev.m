function log2dev( strLogContent, pntDevice, pntHandle, intLogCode, intOutputDev )
%LOG2DEV Summary of this function goes here
%   Detailed explanation goes here

switch intOutputDev
    
    %% Log to GUI device
    case 0
        
        tmpDeviceContenitor = getappdata(0,pntDevice);
        tmpHandleContenitor = guidata(tmpDeviceContenitor);
        
        set(tmpHandleContenitor.(pntHandle), 'String', strcat(datestr(now,0),' | [',intLogCode,'] | ',strLogContent));
        
        
        %% Log to FILE device
    case 1
        
        
        %% Example
        
        % log2dev( getappdata(hMainGui, 'status_application'), 'hMainGui', 'statusbar', 0 );
end

end

