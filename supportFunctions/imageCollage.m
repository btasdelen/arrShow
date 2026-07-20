function [axesHandle, imageHandle] = imageCollage(...
    imgArr,...
    parentPanelH,...
    colorMap,...
    keepAspectRatio,...
    voxelAspectRatio,...
    keepTrueSize,...
    useQuiver,...
    forceComplex,...
    viewAsRgb)

if nargin < 9
    viewAsRgb = false;
end

% get size of the image array
if viewAsRgb
    dimY = size(imgArr,1);
    dimX = size(imgArr,2);
    noFrames = size(imgArr,4);
else
    [dimY, dimX, noFrames] = size(imgArr);
end

% delete all uiobjects from parentPanelH
oldHandles = get(parentPanelH,'Children');
if ~isempty(oldHandles)
    delete(oldHandles);
end

% units and window position
origUnits = get(parentPanelH,'Units');
set(parentPanelH,'Units','pixel');
fpos = get(parentPanelH,'position');
fWidth = fpos(3);
fHeight = fpos(4);

% width and height of every image
nCols = ceil(sqrt(noFrames));
nRows = ceil(noFrames / nCols);
colHeight = floor(fHeight/nRows);
colWidth  = floor(fWidth/nCols);

if keepAspectRatio % account for aspect ratio
    imgRatio = (voxelAspectRatio(1).*dimY) / (voxelAspectRatio(2).*dimX);
    colHeight = colWidth * imgRatio;
    if colHeight > floor(fHeight/nRows)
        colHeight = floor(fHeight/nRows);
        colWidth = colHeight / imgRatio;
    end
    yBorder2 = floor((fHeight - nRows * colHeight)/2);
    xBorder2 = floor((fWidth - nCols * colWidth)/2);
else
    yBorder2 = 0;
    xBorder2 = 0;
end

% display
imageHandle = zeros(noFrames,1);
axesHandle  = zeros(noFrames,1);
for n=1:noFrames
    
    % image position
    x0 = mod((n-1),nCols)  * colWidth + xBorder2;
    y0 = fHeight - colHeight - (floor((n-1)/nCols) * colHeight) - yBorder2;
    
    ah = axes('Parent',parentPanelH,'units','pixel'...
        ,'position',[x0, y0, colWidth, colHeight], ...
        'YDir','reverse');

    if keepTrueSize
        pixelPos = get(ah,'position');
        set(ah,'position',[pixelPos(1:2), dimY, dimX]);
    end
    if viewAsRgb
        currImg = imgArr(:,:,:,n);
    else
        currImg = imgArr(:,:,n);
    end
    
    if useQuiver              
        imageHandle(n) = quiver(real(currImg),imag(currImg),...
            'Parent',ah);
        set(ah,'YDir','reverse');        
        axis(ah,'tight');
        
        % store the original image in the axes handle's userData
        ud.selectedImage = currImg;
        set(ah,'UserData',ud);
    else
    
        if viewAsRgb
            isComplex = false;
        elseif forceComplex || ~isreal(currImg)
            isComplex = true;
            [currImg, CLim] = complex2rgb(currImg, 256, [], colormap(ah, colorMap));
            if any(~isfinite(CLim))
                error([mfilename,':ExpectedFinite'],'CLim has to be finite');
            end
        else                        
            isComplex = false;
            colormap(ah,colorMap);        
        end
        % sssr: matlab 2017b + version does not update colormap without next line 
        set(ah,'NextPlot','replacechildren');
        imageHandle(n) = imagesc(currImg,'Parent',ah);           

        if isComplex
            if (CLim(1) == CLim(2))
                if(CLim(1) == 0)
                    CLim(1) = 1;
                    CLim(2) = 1;
                end
                CLim(1) = CLim(1)/2;
            end
            set(ah,'CLim',CLim);
        end    
    end
    if keepAspectRatio
        set(ah,'DataAspectRatio', voxelAspectRatio);
    end
    
    axis(ah,'off');    
    axesHandle(n) = ah;
end
set(parentPanelH,'Units',origUnits);
end
