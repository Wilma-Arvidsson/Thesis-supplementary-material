function [theta, profile, peaksy, peaks_theta, dipsy, dips_theta] = IntensityProfile(image, filename, pixel_size, f )

% The purpose of this function is to let the user select a region of
% interest in an image to extract a 1D intensity profile

% INPUT: 
% image - the image you want to make a intensity profile on
% filename - the name of the image so that the plots can be labeled
% pixel_size - the pxel size of the sensor that took the image (meters)
% f - the focal lenght of the optical system (meters)

% OUTPUT: 
% theta - angular position (micro rad)
% profile - intenisty valyes along selected line
% ypeaks - the peaks y-value (intensity)
% xpeaks - the peaks x-value (theta)
% ydips - the dip y-value (intensity)
% xdips - the dip x-value (theta)

%% ---------------------- SELECT ROI  -------------------------------------

% Show image so the user can manually select region of interest (ROI)

%figure;
imshow(image);
hold on

title('Draw a narrow rectangle across your target (double-click when done)');

% Let user draw a rectangle interactivly 
roi = drawrectangle('Color', 'r');


% Live coordinate display
coordText = text(20, 30, '', ...
    'Color', 'y', ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', 'k', ...
    'Margin', 5);



%% ---------------- CREATE AXIS FOR PLOT ----------------
% Split visible title from hidden metadata
parts = split(filename, '|');

visibleName = parts{1};

figure;
h = plot(nan, nan, 'LineWidth', 2);
xlabel('Angle (\mu rad)');
ylabel('Intensity');
title(sprintf('Live Intensity Profile\n%s', visibleName), 'Interpreter','none');
grid on;

%% ---------------- CALLBACK FUNCTION ----------------
% This function runs every time ROI changes

    function updateProfile(~, ~)

        % Get ROI position
        bbox = round(roi.Position); % [x y width height]


        x1 = bbox(1);
        y1 = bbox(2);
        w = bbox(3);
        hgt = bbox(4);
        x2 = x1 + w;
        y2 = y1 + hgt;

        
        % Update live coordinates
        coordText.String = sprintf([ ...
            'Top-left: (%d, %d)\n' ...
            'Bottom-right: (%d, %d)\n' ...
            'Width: %d   Height: %d'], ...
            x1, y1, x2, y2, w, hgt);

   
        % Extract sub-image
        subImg = image( ...
            bbox(2):bbox(2)+bbox(4), ...
            bbox(1):bbox(1)+bbox(3) ...
        );

        % Compute 1D intensity profile (average vertically)
        profile = mean(subImg, 1);

        % Pixel axis   
        x = 1:length(profile);

        if contains(filename, 'LGH')

            % Find the middle pipe
            start = 10;
            ending = length(profile) -10;
    
            % Check so that the profile ain't too short
            if ending <= start
                error('Profile too short for 300-pixel margin')
            end
    
            % The restricted search region for intenisty min
            search_region = profile(start:ending);
    
            [~,min_value] = min(search_region);
    
            % Find the postion of the min_value
            min_pos = min_value + start -1;
    
            % Convert axis so central dip = 0
            x_centered = x - min_pos; 

        elseif contains(filename, 'HG')

            % Find the middle pillar
            start = 10;
            ending = length(profile) -10;
    
            % Check so that the profile ain't too short
            if ending <= start
                error('Profile too short for 300-pixel margin')
            end
    
            % The restricted search region for intenisty max
            search_region = profile(start:ending);
    
            [~,max_value] = max(search_region);
    
            % Find the postion of the max_value
            max_pos = max_value + start -1;
    
            % Convert axis so central dip = 0
            x_centered = x - max_pos; 

        else 
            error('target name not recognized in image 1');

        end

       
   
        % Convert to angular units if useAngular is true
        rad_per_pixel = pixel_size / f;
        theta = x_centered * rad_per_pixel * 1e6;

    
        % find peaks - find local maxima 
        %[peaksy, peaksx]= findpeaks(profile, x);
        
        %find dips
        %[dipsy, dipsx] = findpeaks(-profile, x);
        
        %dipsy = - dipsy;

        %peaks_theta = theta(peaksx);
        %dips_theta = theta(dipsx);


        % Update plot
        h.XData = theta;
        h.YData = profile;

        drawnow;

    end

% Initialize shared variables
profile = [];
theta = [];

peaksy = [];
peaksx = [];
peaks_theta = [];

dipsy = [];
dipsx = [];
dips_theta = [];

%% ---------------- ATTACH LISTENER ----------------
% This makes ROI "live"

addlistener(roi, 'MovingROI', @updateProfile);
addlistener(roi, 'ROIMoved',  @updateProfile);

%% ---------------- INITIAL UPDATE ----------------
updateProfile();

wait(roi);

%% ------------------ ANALYSIS ---------------------------

amount = length(peaksx);

% Measure separation between peak to peak
for i = 1:(amount-1)
        
        delta_theta(i) = abs(peaks_theta(i+1) - peaks_theta(i));

        % Pixel indicies between peaks
        %region = peaksx(i):peaksx(i+1)

        % Find the intensity difference between peak i and dip i
        peak_dip_diff(i) = peaksy(i) - dipsy(i);
end

%disp(delta_theta);
%disp(peak_dip_diff);

end
