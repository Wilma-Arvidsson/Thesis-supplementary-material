clear all;
close all;
clc;

%% -------------------- Select Images -----------------------------------
% Import images (as many images as wanted)
Im = 2;
images = cell(1, Im);

for i = 1:Im
    
    [file, path] = uigetfile({'*.tif;*.tiff;*.png;*.jpg', 'Image Files'}, ...
        sprintf('Select image %d', i));
    
    if isequal(file,0)
        error('No file selected.');
    end

    filePath = fullfile(path, file);
    filenames{i} = filePath;

    images{i} = im2double(imread(filePath));

    fprintf('Loaded image %d: %s\n', i, filePath);
end

filename1 = filenames{1};
filename2 = filenames{2};

Image1 = images{1};
Image2 = images{2};


%% -------------------- Sensor Detection of Image 1------------------------

if contains(filename1, 'VISNIR')
    
    pixel_size1 = 2.74e-6; %[m] H x V
    f1 = 100e-3; %[m]
    sensorName1 = 'VISNIR';

elseif contains(filename1, 'SWIR')
    
    pixel_size1 = 15e-6;  %[m]
    f1 = 500e-3; %[m]
    sensorName1 = 'SWIR';

else
    error('Sensor type not recognized in image 1');
end

%% -------------------- Sensor Detection of Image 2------------------------

if contains(filename2, 'VISNIR')
    
    pixel_size2 = 2.74e-6; %[m]
    f2 = 100e-3; %[m]
    sensorName2 = 'VISNIR';

elseif contains(filename2, 'SWIR')
    
    pixel_size2 = 15e-6; %[m]
    f2 = 500e-3; % [m]
    sensorName2 = 'SWIR';

else
    error('Sensor type not recognized in image 2');
end

%% ---------------- ALIGN IMAGES --------------------------
% Call the function to crop the images
[cropped1, cropped2] = Align(Image1, Image2);

fusionImages = {cropped1, cropped2};

%% -------------------- Resize Pixels ------------------------------------

% If the size (amount of pixels) of the images don't match, then it
    % resizes the smaller images (adding pixels to match the bigger image)
    if size(cropped1,1) ~= size(cropped2,1) || size(cropped1,2) ~= size(cropped2,2)
        cropped2 = imresize(cropped2, [size(cropped1,1), size(cropped1,2)]);
    end

%% ------------------- IMAGE FUSION --------------------------------------

% the coe will still be running as long as the user wants to do image
% fusion

% this enables the user to do multiple fusions on the same alignment,
% mittigating the repeating process of alignment. 
still_imagefusion = 1;
while still_imagefusion == 1

% Type of fusion method selection 
fusion_method = questdlg( ...
    'Select fusion method:', ...
    'Fusion Method', ...
    'DWT', 'LP', 'PCA', 'DWT');

if isempty(fusion_method)
    error('No fusion method selected.');
end

% Image fusion method
switch fusion_method
    case 'DWT' % Discrete Wavelet transform (DWT)
        % Choose what kind of image fusion method is to be used and specifications (max, mean or min)
        coeffOptions = {'max', 'mean', 'min'};

        [idx, tf] = listdlg( ...
            'PromptString', 'Select approximation coefficient:', ...
            'SelectionMode', 'single', ...
            'ListString', coeffOptions);
        
        if ~tf
            error('No approximation coefficient selected.');
        end
        
        approx_coe = idx;
        
        [idx, tf] = listdlg( ...
            'PromptString', 'Select detail coefficient:', ...
            'SelectionMode', 'single', ...
            'ListString', coeffOptions);
        
        if ~tf
            error('No detail coefficient selected.');
        end
        
        detail_coe = idx;
        wtype = 'db2';
        outimage = Wavelet_fusion(fusionImages, approx_coe, detail_coe, wtype);
        
        % Display the fused image 
        figure;
        imshow(outimage);
        title('Fused Image - Discrete Wavelet Transform fusion');

    case 'LP' % Laplacian Pyramid (LP)
        ruleOptions = {'max', 'mean', 'min'};

        [idx, tf] = listdlg( ...
            'PromptString', 'Select fusion rule:', ...
            'SelectionMode', 'single', ...
            'ListString', ruleOptions);
        
        if ~tf
            error('No fusion rule selected.');
        end
        
        fusion_rule = idx;
        outimage = Laplacian_fusion(fusionImages, fusion_rule);
        
        % Display the fused image 
        figure;
        imshow(outimage);
        title('Fused Image - Laplacian Pyramid fusion');

    case 'PCA' % Principal Component Analysis (PCA)
        outimage = PCA_fusion(fusionImages);
        
        % Display the fused image 
        figure;
        imshow(outimage);
        title('Fused Image - PCA Fusion');
        
    otherwise
        error('Invalid Fusion Method')
end

%% -----------------------Save Results------------------------------------
saveChoice = questdlg( ...
    'Save fused image?', ...
    'Save Image', ...
    'Yes', 'No', 'Yes');

saveImage = strcmp(saveChoice, 'Yes');

if saveImage

    answer = inputdlg( ...
        'Enter filename (without extension):', ...
        'Save Filename', ...
        [1 50]);

    if isempty(answer)
        error('No filename entered.');
    end

    filename = answer{1};

    % Choose save location
    [file, path] = uiputfile('*.tiff', ...
        'Save fused image as', ...
        [filename '.tiff']);

    if isequal(file,0)
        disp('User canceled save.');
    else

        fullSavePath = fullfile(path, file);

        % Save as TIFF
        imwrite(outimage, fullSavePath, 'tiff');

        fprintf('Image saved to:\n%s\n', fullSavePath);
    end
end

%% ----------------- Intensity Profile ----------------------------------


% % Generate the intensity profile of image 1
% [theta1, profile1, peaksy1, peaks_theta1, dipsy1, dipsx1] = IntensityProfile(cropped1, filename1, pixel_size1, f1);
% 
% % Generate the intensity profile of image 2
% [theta2, profile2, peaksy2, peaks_theta2, dipsy2, dipsx2] = IntensityProfile(cropped2, filename2, pixel_size2, f2);
% 


% Hidden metadata added after |
% The visible title will still only show "The Fused Image"

ImageFusionName = ['The Fused Image|' filename1];

% Generate the intensity profile of the fused image
[theta_fused, profile_fused, peaksy_fused, peaksx_fused, dipsy_fused, dipsx_fused] = IntensityProfile(outimage, ImageFusionName, pixel_size1, f1); 


fprintf('Maxima [theta, intensity]:\n');

for i = 1:length(peaksx_fused)
    fprintf('[%.3f, %.3f]\n', peaksx_fused(i), peaksy_fused(i));
end

fprintf('\nMinima [theta, intensity]:\n');

for i = 1:length(dipsx_fused)
    fprintf('[%.3f, %.3f]\n', dipsx_fused(i), dipsy_fused(i));
end




%% ----------------- Continue? ---------------------------------------

% Enabaling multiple fusion methods without having to choose and align new images
continueChoice = questdlg( ...
    'Do you want to perform another image fusion?', ...
    'Continue?', ...
    'Yes', 'No', 'Yes');

still_imagefusion = strcmp(continueChoice, 'Yes');

close all force;
end


