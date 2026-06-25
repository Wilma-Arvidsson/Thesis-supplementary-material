%%  VARIABLES
% Inputs:
%   images - Cell array of input images to fuse (at least 2 images
%   required) (grayscale or RGB)
%   levels - Number of pyramid levels (recommended 4–6 levels)
%   fusion_rule - 1 = max, 2 = mean, 3 = min
% Outputs:
%   outimage - The fused image

%% FUNCTION
% Performs image fusion through Laplacian pyramid
function outimage = Laplacian_fusion(images, levels, fusion_rule)

    % Validate input
    if length(images) < 2
        error('At least 2 images are required for fusion');
    end
    
    if levels < 2
        error('Levels have to be at least 2');
    end
    
    % Generate Laplacian pyramids for all images
    lp_all = cell(1, length(images));
    for i = 1:length(images)
        lp_all{i} = genLaplacianPyramid(images{i}, levels);
    end
    
    %% Fuse Images Across Levels
    lp_fused = cell(1, levels);
    
    for l = 1:levels
        
        fused_layer = lp_all{1}{l};
        
        switch fusion_rule
            case 1 % max (absolute value selection for details)
                for i = 2:length(images)
                    current_layer = lp_all{i}{l};
                    
                    mask = abs(current_layer) > abs(fused_layer);
                    fused_layer(mask) = current_layer(mask);
                end
                
            case 2 % mean
                fused_layer = zeros(size(fused_layer));
                for i = 1:length(images)
                    fused_layer = fused_layer + lp_all{i}{l};
                end
                fused_layer = fused_layer / length(images);
                
            case 3 % min
                for i = 2:length(images)
                    fused_layer = min(fused_layer, lp_all{i}{l});
                end
                
            otherwise
                error('Invalid fusion rule (1=max, 2=mean, 3=min)');
        end
        
        lp_fused{l} = fused_layer;
    end
    
    %% Reconstruct Final Image
    % Reconstruct fused image from fused Laplacian pyramid
    outimage = reconstructLaplacianPyramid(lp_fused);
    
    % Clip to valid range to [0, 1]
    outimage = max(min(outimage, 1), 0);
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PYRAMID FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to build a Laplacian pyramid from an image
function lp = genLaplacianPyramid(img, levels)

    % Preallocate arrays for Gaussian and Laplacian pyramids
    gp = cell(1, levels);
    lp = cell(1, levels);
    
    % Level 1 is the original image
    gp{1} = img;
    
    % Gaussian pyramid (lowpass + downsample)
    for l = 2:levels
        gp{l} = pyr_reduce(gp{l-1});
    end
    
    % Laplacian pyramid: difference between levels
    for l = 1:levels-1
        expanded = pyr_expand(gp{l+1}, size(gp{l}));
        lp{l} = gp{l} - expanded;
    end
    
    % Last level is the coarsest Gaussian approximation
    lp{levels} = gp{levels};

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to reconstruct an image from its Laplacian pyramid
function img = reconstructLaplacianPyramid(lp)

    % Get number of levels in pyramid
    levels = length(lp);
    
    % Start reconstruction with the top level of the pyramid
    img = lp{levels};
    
    % Work backwards through the pyramid levels
    for l = levels-1:-1:1
        img = pyr_expand(img, size(lp{l})) + lp{l};
    end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to reduce image resolution by half using Gaussian filtering
function imgout = pyr_reduce(img)
    
    % Generate Gaussian kernel
    cw = 0.375;
    ker1d = [0.25-cw/2, 0.25, cw, 0.25, 0.25-cw/2];
    % Separable 2D Gaussian approximation kernel
    kernel = ker1d' * ker1d;
    
    img = im2double(img);
    [M, N, C] = size(img);
    
    imgout = zeros(ceil(M/2), ceil(N/2), C);
    
    % Process each color channel separately
    for c = 1:C
        % Apply Gaussian filter and downsample
        filtered = imfilter(img(:,:,c), kernel, 'replicate', 'same');
        imgout(:,:,c) = filtered(1:2:end, 1:2:end);
    end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to expand image resolution by doubling using Gaussian filtering
function imgout = pyr_expand(img, targetSize)
    
    % Generate Gaussian kernel scaled for expansion
    cw = 0.375;
    ker1d = [0.25-cw/2, 0.25, cw, 0.25, 0.25-cw/2];
    % Separable 2D Gaussian approximation kernel
    kernel = (ker1d' * ker1d) * 4;
    
    img = im2double(img);
    [M, N, C] = size(img);
    
    % Upsample by inserting zeros
    up = zeros(2*M, 2*N, C);
    up(1:2:end, 1:2:end, :) = img;
    
    % Filter
    imgout = zeros(size(up));
    

    % Process each color channel separately
    for c = 1:C
        % Apply Gaussian filter to smooth upscaled image
        imgout(:,:,c) = imfilter(up(:,:,c), kernel, 'replicate', 'same');
    end
    
    % Crop to match the required target size
    imgout = imgout(1:targetSize(1), 1:targetSize(2), :);

end

