%% VARIABLES
% Inputs:
%   images - Cell array of input images to fuse (at least 2 images required)
%   approx_coe - Fusion method for approximation coefficients (1=max, 2=mean, 3=min)
%   detail_coe - Fusion method for detail coefficients (1=max, 2=mean, 3=min)
%   wtype - Wavelet type (e.g., 'db1', 'haar', 'db2')
%
% Outputs:
%   outimage - The fused image

%% FUNCTION
% Performs image fusion using single-level discrete wavelet transform (DWT)
function outimage = Wavelet_fusion(images, approx_coe, detail_coe, wtype)

% Validate inputs
if length(images) < 2
    error('At least 2 images are required for fusion');
end

%% DECOMPOSITION
% Initialize arrays to store coefficients from all images
cA_all = cell(1, length(images));
cH_all = cell(1, length(images));
cV_all = cell(1, length(images));
cD_all = cell(1, length(images));

% Extract DWT coefficients from all images
for i = 1:length(images)
    [cA_i, cH_i, cV_i, cD_i] = dwt2(images{i}, wtype, 'per');
    cA_all{i} = cA_i;
    cH_all{i} = cH_i;
    cV_all{i} = cV_i;
    cD_all{i} = cD_i;
end

%% FUSION RULE
% Apply fusion rules for approximation coefficients
switch approx_coe
    case 1  % Maximum
        cA_fused = cA_all{1};
        for i = 2:length(cA_all)
            cA_fused = max(cA_fused, cA_all{i});
        end
        
    case 2  % Mean
        cA_fused = cA_all{1};
        for i = 2:length(cA_all)
            cA_fused = cA_fused + cA_all{i};
        end
        cA_fused = cA_fused / length(cA_all);
        
    case 3  % Minimum
        cA_fused = cA_all{1};
        for i = 2:length(cA_all)
            cA_fused = min(cA_fused, cA_all{i});
        end
        
    otherwise
        error('Wrong input for Approximation coefficient');
end

% Apply fusion rules for detail coefficients
switch detail_coe
    case 1  % Maximum (absolute value)
        cH_fused = cH_all{1};
        cV_fused = cV_all{1};
        cD_fused = cD_all{1};
        
        for i = 2:length(cH_all)
            % Horizontal detail coefficient (cH)
            maskH = abs(cH_all{i}) > abs(cH_fused);
            cH_fused(maskH) = cH_all{i}(maskH);
            
            % Vertical detail coefficient (cV)
            maskV = abs(cV_all{i}) > abs(cV_fused);
            cV_fused(maskV) = cV_all{i}(maskV);
            
            % Diagonal detail coefficient (cD)
            maskD = abs(cD_all{i}) > abs(cD_fused);
            cD_fused(maskD) = cD_all{i}(maskD);
        end
        
    case 2  % Mean
        cH_fused = cH_all{1};
        cV_fused = cV_all{1};
        cD_fused = cD_all{1};
        
        for i = 2:length(cH_all)
            cH_fused = cH_fused + cH_all{i};
            cV_fused = cV_fused + cV_all{i};
            cD_fused = cD_fused + cD_all{i};
        end
        
        cH_fused = cH_fused / length(cH_all);
        cV_fused = cV_fused / length(cV_all);
        cD_fused = cD_fused / length(cD_all);
        
    case 3  % Minimum
        cH_fused = cH_all{1};
        cV_fused = cV_all{1};
        cD_fused = cD_all{1};
        
        for i = 2:length(cH_all)
            cH_fused = min(cH_fused, cH_all{i});
            cV_fused = min(cV_fused, cV_all{i});
            cD_fused = min(cD_fused, cD_all{i});
        end
        
    otherwise
        error('Wrong input for Detail coefficient');
end

%% RECONSTRUCTION (SINGLE LEVEL)
% Reconstruct fused image using inverse DWT
outimage = idwt2(cA_fused, cH_fused, cV_fused, cD_fused, wtype, 'per');

end


