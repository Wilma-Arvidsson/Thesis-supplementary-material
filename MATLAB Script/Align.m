function [cropped1, cropped2] = Align(image1_path, image2_path)

    % Aligns two images and crops the overlapping region

    % Inputs: 
    % Image1_path - [will be fixed] Insert an image name, i.e '2026-03-20/2026-03-20 HG VISNIR 1035.tiff'
    % Image2_path - [will be warped] Insert an image name, i.e '2026-03-20/2026-03-20 HG SWIR 1028.tiff'  

    %Make sure to write the right path for each image as inputs 
    % i.e folder/file or folder/folder/file etc

    % Outputs: 
    % Cropped1 - cropped version of image1
    % Cropped2 - cropped version of image2

    % Read the images that you want to align
    % image1 = imread(image1_path);
    % image2 = imread(image2_path);

    image1 = image1_path;
    image2 = image2_path;


    figure(1)
    imshow(image1)
    title('Original image1');
    
    figure(2)
    imshow(image2)
    title('Original image2');

    % Convert to double [0–1] so contrast measure is consistent
    image1_disp =image1;
    image2_disp = image2;
    
    % Compute global contrast (standard deviation)
    contrast1 = std(image1_disp(:));
    contrast2 = std(image2_disp(:));
    
    % Set a reasonable threshold for "usable contrast"
    % (0.05 is a good starting point for normalized images)
    threshold = 0.05;

    % Limit how many times we enhance (VERY important to avoid over-processing)
    max_iter = 5;

    iter1 = 0;

    while contrast1 < threshold && iter1 < max_iter
        
        image1_disp = adapthisteq(image1_disp, 'ClipLimit', 0.01);
        
        % Recompute contrast after enhancement
        contrast1 = std(image1_disp(:));
        
        % Increase iteration counter
        iter1 = iter1 + 1;
    end

    % Show result if enhancement was applied
    if iter1 > 0
        %figure(3)
        %imshow(image1_disp)
        %title(['Enhanced image 1 (', num2str(iter1), ' iterations)'])
        fprintf('Image 1 enhanced %d times\n', iter1);
    else
        fprintf('No enhancement needed for image 1.\n');
    end
    
    iter2 = 0;

    while contrast2 < threshold && iter2 < max_iter
        
        image2_disp = adapthisteq(image2_disp, 'ClipLimit', 0.01);
        
        contrast2 = std(image2_disp(:));
        
        iter2 = iter2 + 1;
    end
    
    if iter2 > 0
        %figure(4)
        %imshow(image2_disp)
        %title(['Enhanced image 2 (', num2str(iter2), ' iterations)'])
        fprintf('Image 2 enhanced %d times \n', iter2);
    else
        fprintf('No enhancement needed for image 2.\n');
    end


    %Select corresponding points in both images
    %mp = moving points from image2
    %fp = fixed points from image1
    [mp,fp] = cpselect(image2_disp, image1_disp, Wait = true); 

    %Create a geometric transformation2d object using projective transformation
    t = fitgeotform2d(mp,fp,'projective');
    
    %Define the refrence view for the first image
    Rfixed = imref2d(size(image1)); %this gives the output image the same coordinate system as image1
    
    %Warp the second image to match the first image's coordinate system
    registered = imwarp(image2, t, OutputView = Rfixed);
    
    %Show the blended image
    %figure(5)
    %imshowpair(image1,registered, 'blend')
    %title('Blended Image')
    
    %create a mask of valid pixels
    mask2 = imwarp(true(size(image2,1), size(image2,2)), t, ...
                   'OutputView', Rfixed);
    
    mask1 = true(size(image1,1), size(image1,2));
    
    %compute overlap
    overlapMask = mask1 & mask2; %pixels valid in both images
    
    %overlapMask gives us a binary image that say 1 if overlap exist and 0 if
    %no overlap
    
    %find connected regions of overlap
    props = regionprops(overlapMask, 'Area', 'BoundingBox');
    
    %chooses the largest region of overlao
    [~,idx] = max([props.Area]);
    
    %extract a rectangle around the largest region
    bbox = props(idx).BoundingBox;
    
    shrinkFactor = 0.02; % 2% shrink (adjust 0.01–0.05)
    
    w = bbox(3);
    h = bbox(4);
    
    dx = w * shrinkFactor;
    dy = h * shrinkFactor;
    
    bbox(1) = bbox(1) + dx;
    bbox(2) = bbox(2) + dy;
    bbox(3) = bbox(3) - 2*dx;
    bbox(4) = bbox(4) - 2*dy;
    
    cropped1 = imcrop(image1, bbox);
    cropped2 = imcrop(registered, bbox);
    
    figure(6)
    imshow(cropped1);
    title('Cropped image1');
    
    figure(7)
    imshow(cropped2);
    title('Cropped image2');
end

