classdef asRoiClass < handle
    properties (Access = private)
        parentAxesHandle   = 0;     % parent axes handle
        parentImageHandle  = 0;     % parent image handle
        parentFigureHandle = 0;
        
        textHandle            = [];
        textContextMenuHandle = [];        
        precision = '%g';      % standard notation is compact
       
        filterStr = ''      % WARNING: test
        
        guiHandle    = struct('figure','text')   
        cmenuHandle  = struct('sendPosition', 0,'ignoreZeros', 0);
        
        sendPositionCallback = [];
        sendPositionCallbackId = [];
        
        fullStrToggle = true;  % show full string or just compact form
        txtbg = true;
    end
    
    properties (Access = public)
        objPoly = images.roi.Polygon.empty;
    end
    
    methods
        function obj = asRoiClass(parentAxesHandle, roiPos, sendPositionCallback)
            if nargin < 2
                roiPos = [];
                if nargin < 1
                    parentAxesHandle = gca;
                end                
            end
            
%             obj.objPoly = images.roi.Polygon(parentAxesHandle, 'Color', 'green');
            if isempty(roiPos)
                obj.objPoly = drawpolygon(parentAxesHandle, 'Color', 'green');
            elseif isstruct(roiPos) && isfield(roiPos,'type')
                switch lower(roiPos.type)
                    case 'circle'
                        obj.objPoly = drawcircle(parentAxesHandle, ...
                            'Center', roiPos.center, ...
                            'Radius', roiPos.radius, ...
                            'Color', 'green');
                    otherwise
                        obj.objPoly = drawpolygon(parentAxesHandle, ...
                            'Position', roiPos.position, ...
                            'Color', 'green');
                end
            elseif numel(roiPos) == 4
                obj.objPoly = drawcircle(parentAxesHandle, 'Center', roiPos(1,:),...
                    'Radius', roiPos(2,1), 'Color', 'green');
            else
                obj.objPoly = drawpolygon(parentAxesHandle, 'Position', roiPos, 'Color', 'green');
            end
%             obj     = obj@impoly(parentAxesHandle, roiPos);
%             obj.setColor('green')
            obj.parentAxesHandle   = parentAxesHandle;
            obj.parentImageHandle  = findall(get(parentAxesHandle,'Children'),'Type','image');
            obj.parentFigureHandle = get(get(obj.parentAxesHandle,'Parent'),'Parent');
            
            if nargin == 3
                obj.sendPositionCallback = sendPositionCallback;                
            end

            obj.updateImpolyContextMenu;
            obj.createTextContextMenu;
            
%             addNewPositionCallback(obj,@(pos)obj.showRoiGui);
%             obj.showRoiGui;
%             addNewPositionCallback(obj.objPoly,@(pos)obj.updateRoiString);
            addlistener(obj.objPoly,'MovingROI',@obj.allevents);
            obj.updateRoiString;


        end

            
        function allevents(obj, src, evt, ~)
            evname = evt.EventName;

            switch(evname)
                case{'MovingROI'}
%                     disp(['ROI moving previous position: ' mat2str(evt.PreviousPosition)]);
%                     disp(['ROI moving current position: ' mat2str(evt.CurrentPosition)]);
                    obj.updateRoiString();
                    if obj.getSendPositionToggle
                        obj.callSendPositionCallback();
                    end
                case{'ROIMoved'}
%                     disp(['ROI moved previous position: ' mat2str(evt.PreviousPosition)]);
                    disp(['ROI moved current position: ' mat2str(evt.CurrentPosition)]);
            end
        end
                       
        function roi = getRoiData(obj)
            ud = get(obj.parentAxesHandle,'UserData');
            if isempty(ud)
                refImg = get(obj.parentImageHandle,'CData');
            else
                if isfield(ud,'isComplex') && ud.isComplex
                    refImg = ud.cplxImg;
                else
                    refImg = get(obj.parentImageHandle,'CData');
                    if isfield(ud,'isRgbImage') && ud.isRgbImage
                        refImg = mean(double(refImg),3);
                    end
                end
            end
            mask   = obj.objPoly.createMask;
            roi    = refImg(mask == 1);
            if obj.getIgnoreZerosToggle
                roi = roi(roi~=0);
            end
            if ~isempty(obj.filterStr)
                eval(['roi = roi(roi',obj.filterStr,');']);
            end
            
        end
        
        function pos = getPosition(obj)
            pos = obj.objPoly.Position;
        end
        
        function type = getType(obj)
            if isa(obj.objPoly,'images.roi.Circle')
                type = 'circle';
            else
                type = 'polygon';
            end
        end
        
        function payload = getPositionPayload(obj)
            switch obj.getType()
                case 'circle'
                    payload = struct(...
                        'type','circle',...
                        'center',obj.objPoly.Center,...
                        'radius',obj.objPoly.Radius);
                otherwise
                    payload = struct(...
                        'type','polygon',...
                        'position',obj.objPoly.Position);
            end
        end

        function pos = setPosition(obj, pos)
           if isstruct(pos) && isfield(pos,'type')
               switch lower(pos.type)
                   case 'circle'
                       if isa(obj.objPoly,'images.roi.Circle')
                           obj.objPoly.Center = pos.center;
                           obj.objPoly.Radius = pos.radius;
                       elseif isfield(pos,'position')
                           obj.objPoly.Position = pos.position;
                       else
                           obj.objPoly.Position = [pos.center; pos.radius .* [1 1]];
                       end
                   otherwise
                       obj.objPoly.Position = pos.position;
               end
           else
               obj.objPoly.Position = pos;
           end
           obj.updateRoiString;
        end

        function copyPosition(obj)
            clipboard('copy',asRoiClass.pos2lineStr(obj.getPosition()));
        end
        
        function [m, s] = getMeanAndStd(obj)
           roi = obj.getRoiData;
           if ~isempty(roi)
               m = mean(roi);
               s = std(roi);
           else
               m = 0;
               s = 0;
           end
        end
        
        function N = getN(obj)
           roi = obj.getRoiData;
           N = numel(roi);               
        end   
        function mini = getMin(obj)
            mini = min(obj.getRoiData);
        end
        function maxi = getMax(obj)
            maxi = max(obj.getRoiData);
        end
            
        function updateRoiString(obj)
            if obj.fullStrToggle            
                obj.drawFullString;
            else
                obj.drawMeanAndStdString;
            end
        end
        
        function str = getMeanAndStdString(obj)
            [m, s] = obj.getMeanAndStd;           
%             str = [num2str(m,obj.precision), ' +- ', num2str(s,obj.precision)];
            str = sprintf('\\mu \\pm \\sigma = %g \\pm %g', m, s);

        end

        function drawMeanAndStdString(obj)
            % writes roi statistics as a text in the image window
            if ~isempty(obj.textHandle)
                delete(obj.textHandle);
            end
            obj.textHandle = text(.015,.99,obj.getMeanAndStdString,'Units','normalized','parent',obj.parentAxesHandle,...
                'Color','green','BackgroundColor','Black',...
                'VerticalAlignment','top',...
                'UIContextMenu',obj.textContextMenuHandle, 'Interpreter', 'latex', ...
                'FontSize', 18);            
        end

        function drawFullString(obj)
            % writes roi statistics as a text in the image window
            if ~isempty(obj.textHandle)
                delete(obj.textHandle);
            end
            minmax_str = sprintf('(min, max) = (%g, %g)', obj.getMin, obj.getMax);
            str = char(obj.getMeanAndStdString, ...
                ['N = ', num2str(obj.getN)], minmax_str);
            obj.textHandle = text(.015,.98,str,'Units','normalized','parent',obj.parentAxesHandle,...
                'Color',obj.objPoly.Color(),'BackgroundColor','Black',...
                'VerticalAlignment','top',...
                'UIContextMenu',obj.textContextMenuHandle, 'FontSize', 14);  
        end
        
        function h = getTextHandle(obj)
            h = obj.textHandle;
        end
        
        
        function bool = guiIsPresent(obj)
            bool = false;
            if ishandle(obj.guiHandle.figure)
                if strcmp(get(obj.guiHandle.figure,'Tag') ,'roiGui')
                    bool = true;
                end
            end
        end
        
        function showRoiGui(obj)         
            if obj.guiIsPresent
                set(obj.guiHandle.text,'String',obj.getMeanAndStdString);                
            else
                pos = [800, 800, 40, 40];
                str = obj.getMeanAndStdString;
                
                obj.guiHandle.figure = figure('MenuBar','none','Toolbar','none',...
                    'Position',pos, 'Tag', 'roiGui');
                obj.guiHandle.text = uicontrol('Style','Text','String',str,'HorizontalAlignment','left',...
                    'Units','normalized','pos',[0 0 1 1],...
                    'parent',obj.guiHandle.figure,'HandleVisibility','on',...
                    'FontUnits','normalized','FontSize',.35);                
            end           
        end
            
        function delete(obj)
            if obj.guiIsPresent
                close(obj.guiHandle.figure);
            end
            if ~isempty(obj.textHandle) && ishandle(obj.textHandle)
                delete(obj.textHandle);
            end
            obj.objPoly.delete();
        end
            
        function toggle = getSendPositionToggle(obj)
            switch get(obj.cmenuHandle.sendPosition,'Checked')
                case 'on'
                    toggle = true;
                case 'off'
                    toggle = false;
            end
        end

        function toggle = getIgnoreZerosToggle(obj)
            switch get(obj.cmenuHandle.ignoreZeros,'Checked')
                case 'on'
                    toggle = true;
                case 'off'
                    toggle = false;
            end
        end
        
        function setSendPositionToggle(obj, toggle)
            if nargin < 2
                toggle = ~obj.getSendPositionToggle;
            end
            
            switch toggle
                case 1
                    set(obj.cmenuHandle.sendPosition,'Checked','on');                    
%                     obj.sendPositionCallbackId = addNewPositionCallback(obj,obj.sendPositionCallback);
%                     obj.sendPositionCallbackId = addlistener(obj.objPoly,'MovingROI', @obj.sendPositionCallback);
%                     addlistener(obj.objPoly,'MovingROI',@obj.allevents);


                    obj.callSendPositionCallback(); % execute callback once
                case 0
                    set(obj.cmenuHandle.sendPosition,'Checked','off');
%                     removeNewPositionCallback(obj,obj.sendPositionCallbackId);                                        
            end
        end
        
        function addFilterString(obj,str)
            % WARNING, INCOMPLETE IMPLEMENTATION
            obj.filterStr = str;
            obj.updateRoiString;
        end
            
        function callSendPositionCallback(obj)
            obj.sendPositionCallback(obj.getPositionPayload());
        end
        
        function setIgnoreZerosToggle(obj, toggle)
            if nargin < 2
                toggle = ~obj.getIgnoreZerosToggle;
            end
            
            switch toggle
                case 1
                    set(obj.cmenuHandle.ignoreZeros,'Checked','on');                    
                case 0
                    set(obj.cmenuHandle.ignoreZeros,'Checked','off');
            end
            obj.updateRoiString;
        end
        
    end
    
    methods (Access = private)
        function updateImpolyContextMenu(obj)
            % add some features to the impoly context menu
            cmh = obj.objPoly.ContextMenu;

            uimenu(cmh,'Label','Delete ROI'   ,...
                'callback',@(src,evnt)obj.delete);
            
            uimenu(cmh,'Label','Delete all ROIs'   ,...
                'callback',@(src,evnt)evalin('base','asDeleteAllRois'));            

            if ~isempty(obj.sendPositionCallback)
                obj.cmenuHandle.sendPosition = uimenu(cmh,'Label','Send Position'   ,...
                    'callback',@(src,evnt)obj.setSendPositionToggle);
            end
            
            obj.cmenuHandle.ignoreZeros = uimenu(cmh,'Label','Ignore Zeros'   ,...
                'callback',@(src,evnt)obj.setIgnoreZerosToggle,...
                'Checked','on');
           
        end

        function createTextContextMenu(obj)
            % create a context menu to choose between different notations
            % in the image text 
            
            if isempty(obj.textContextMenuHandle)
                obj.textContextMenuHandle = uicontextmenu('Parent',obj.parentFigureHandle);
                
                uimenu(obj.textContextMenuHandle,'Label','Decimal notation'   ,...
                    'callback',@(src,evnt)obj.setNotation('%d'));
                uimenu(obj.textContextMenuHandle,'Label','Fixed-point notation'   ,...
                    'callback',@(src,evnt)obj.setNotation('%2.2f'));
                uimenu(obj.textContextMenuHandle,'Label','Exponential notation'   ,...
                    'callback',@(src,evnt)obj.setNotation('%2.2e'));
                uimenu(obj.textContextMenuHandle,'Label','Compact exponential notation'   ,...
                    'callback',@(src,evnt)obj.setNotation('%g'));
                uimenu(obj.textContextMenuHandle,'Label','Toggle background'   ,...
                    'callback',@(src,evnt)obj.toggleBackground());
                
            end                                    
        end
        
        function setNotation(obj, precision)
            obj.precision = precision;
            obj.updateRoiString % update text
        end

        function toggleBackground(obj)

            if obj.txtbg
                set(obj.textHandle, 'BackgroundColor', 'black')
            else
                set(obj.textHandle, 'BackgroundColor', 'none')
            end
            obj.txtbg = ~obj.txtbg;

        end
                    
    end
    
    methods (Static, Access = private)

        function str = pos2lineStr(pos)
            % needed to copy the position array to clipboard
            ncols = size(pos,1);
            str = num2str(pos(1,:));
            for i = 2 : ncols
                curr = num2str(pos(i,:));
                str = [str,';',curr];
            end
        
        end
    end
end
