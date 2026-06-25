%% VARIBLES
% INPUTS:
%   images   - Cell array of input images (minimum 2 images)
%              Can be grayscale (MxN) or RGB (MxNx3)
% OUTPUT:
%   outimage - Fused output image (same size as input)

%% FUNCTION
% Performs image fusion using Principal Component Analysis (PCA)
function outimage = PCA_fusion(images)

outimage = zeros(size(images{1}));

    %% INPUT VALIDATION
    if length(images) < 2
        error('At least 2 images are required for PCA fusion.');
    end

    %% DETERMINE IMAGE TYPE (GRAYSCALE OR RGB)
    if ismatrix(images{1}) 
        num_channels = 1;
    else
        num_channels = size(images{1}, 3);
    end

    num_images = length(images);

    %% PCA FUSION (CHANNEL-WISE)
    % PCA fusion is applied separately for each channel (R,G,B)
    for ch = 1:num_channels

        %% BUILD DATA MATRIX
        % Each image is reshaped into a column vector
        % X will be of size: (rows*cols) x num_images
        [rows, cols, ~] = size(images{1});
        X = zeros(rows*cols, num_images);

        for i = 1:num_images
            
            % Extract correct channel (grayscale or RGB)
            if num_channels == 1
                img_channel = images{i};
            else
                img_channel = images{i}(:,:,ch);
            end

            % Convert image into vector form
            X(:,i) = img_channel(:);
        end

        %% CENTER DATA (MEAN REMOVAL)
        % PCA requires mean-centered data to compute correct covariance
        X_mean = mean(X, 1);          % Mean of each image column
        X_centered = X - X_mean;      % Subtract mean from each column

        %% COMPUTE COVARIANCE MATRIX
        % Covariance matrix describes correlation between images
        % Output size: num_images x num_images
        C = cov(X_centered);

        %% EIGENVALUE DECOMPOSITION
        % Eigenvectors give PCA directions
        % Largest eigenvalue corresponds to strongest principal component
        [V, D] = eig(C);

        % Extract eigenvalues from diagonal matrix
        eigenvalues = diag(D);

        % Find index of maximum eigenvalue
        [~, idx] = max(eigenvalues);

        % Select eigenvector belonging to the largest eigenvalue
        pc1 = V(:, idx);

        %% PCA WEIGHTS
        % Convert principal eigenvector into fusion weights
        % abs() avoids negative contributions
        % normalization ensures sum(weights) = 1
        weights = abs(pc1);
        weights = weights / sum(weights);

        %% IMAGE FUSION (WEIGHTED SUM)
        % The fused image is a weighted combination of input images
        fused_vec = X * weights;

        % Convert fused vector back to image format
        fused_img = reshape(fused_vec, rows, cols);

        %% STORE OUTPUT CHANNEL
        if num_channels == 1
            outimage = fused_img;
        else
            outimage(:,:,ch) = fused_img;
        end
    end

    %% POST-PROCESSING
    % Clamp output intensity values to valid range [0,1]
    outimage = min(max(outimage, 0), 1);

end

