clc;
clear;
close all;

%% STEP 1: Select the folder containing the leaf images

folder = uigetdir(pwd, 'Select the folder containing leaf images');

if folder == 0
    error('No folder was selected.');
end

files = dir(fullfile(folder, '*.jpg'));

% If there are no JPG images, look for PNG images
if isempty(files)
    files = dir(fullfile(folder, '*.png'));
end

% Check that images exist
if isempty(files)
    error('No JPG or PNG leaf images were found in the selected folder.');
end


%% STEP 2: Create the structure array

Leaf = struct();


%% STEP 3: Process every leaf image

for k = 1:length(files)

    % Read image
    filename = fullfile(folder, files(k).name);
    I = imread(filename);

    % Display original image
    figure;
    imshow(I);
    title(['Original Image - Leaf ', num2str(k)]);


    %% Convert image to grayscale

    if size(I,3) == 3
        Gray = im2gray(I);
    else
        Gray = I;
    end

    figure;
    imshow(Gray);
    title(['Grayscale Image - Leaf ', num2str(k)]);


    %% Segment the leaf from the background

    BW = imbinarize(Gray);

    % Automatically choose whether the object is dark or bright
    if mean(BW(:)) > 0.5
        BW = ~BW;
    end

    % Remove small unwanted objects
    BW = bwareaopen(BW, 100);

    % Fill holes inside the leaf
    BW = imfill(BW, 'holes');

    % Keep the largest object
    BW = bwareafilt(BW, 1);


    %% Display the binary/segmented image

    figure;
    imshow(BW);
    title(['Segmented Leaf - Leaf ', num2str(k)]);


    %% Extract geometric properties

    properties = regionprops(BW, ...
        'Area', ...
        'Perimeter', ...
        'BoundingBox', ...
        'MajorAxisLength', ...
        'MinorAxisLength', ...
        'Eccentricity', ...
        'Solidity', ...
        'Extent');

    % Make sure a leaf was detected
    if isempty(properties)
        warning(['No leaf detected in ', files(k).name]);
        continue;
    end

    P = properties(1);


    %% Calculate shape characteristics

    Area = P.Area;
    Perimeter = P.Perimeter;

    % Circularity
    Circularity = (4*pi*Area)/(Perimeter^2);

    % Length and width
    Length = P.MajorAxisLength;
    Width = P.MinorAxisLength;


    %% Calculate average colour of the leaf

    if size(I,3) == 3

        R = I(:,:,1);
        G = I(:,:,2);
        B = I(:,:,3);

        MeanRed = mean(double(R(BW)));
        MeanGreen = mean(double(G(BW)));
        MeanBlue = mean(double(B(BW)));

    else

        MeanRed = mean(double(I(BW)));
        MeanGreen = MeanRed;
        MeanBlue = MeanRed;

    end


    %% Calculate texture information

    % Entropy gives an indication of image texture
    Texture = entropy(Gray(BW));


    %% Store the information in the structure array

    Leaf(k).Name = files(k).name;

    Leaf(k).Image = I;

    Leaf(k).GrayImage = Gray;

    Leaf(k).BinaryImage = BW;

    Leaf(k).Area = Area;

    Leaf(k).Perimeter = Perimeter;

    Leaf(k).Length = Length;

    Leaf(k).Width = Width;

    Leaf(k).Circularity = Circularity;

    Leaf(k).Eccentricity = P.Eccentricity;

    Leaf(k).Solidity = P.Solidity;

    Leaf(k).Extent = P.Extent;

    Leaf(k).MeanRed = MeanRed;

    Leaf(k).MeanGreen = MeanGreen;

    Leaf(k).MeanBlue = MeanBlue;

    Leaf(k).Texture = Texture;

end


%% STEP 4: Display the structure array

disp('======================================');
disp('       LEAF STRUCTURE ARRAY');
disp('======================================');

disp(Leaf);


%% STEP 5: Display important properties in a table

for k = 1:length(Leaf)

    LeafTable(k).Name = Leaf(k).Name;
    LeafTable(k).Area = Leaf(k).Area;
    LeafTable(k).Perimeter = Leaf(k).Perimeter;
    LeafTable(k).Length = Leaf(k).Length;
    LeafTable(k).Width = Leaf(k).Width;
    LeafTable(k).Circularity = Leaf(k).Circularity;
    LeafTable(k).Eccentricity = Leaf(k).Eccentricity;
    LeafTable(k).Solidity = Leaf(k).Solidity;
    LeafTable(k).Texture = Leaf(k).Texture;

end

T = struct2table(LeafTable);

disp('======================================');
disp('          LEAF PROPERTIES');
disp('======================================');

disp(T);


%% STEP 6: Save the structure array

save('Leaf_Structure_Array.mat', 'Leaf');

writetable(T, 'Leaf_Properties.csv');

disp(' ');
disp('Leaf structure array saved as Leaf_Structure_Array.mat');
mkdir('Processed_Leaves');
figs = findall(0,'Type','figure');
[~,idx] = sort([figs.Number]);
figs = figs(idx);
for k = 1:length(figs)
filename = fullfile('Processed_Leaves', ...
sprintf('Leaf_Image_%02d.png',k));
exportgraphics(figs(k),filename,'Resolution',300);
end
disp('All leaf images have been saved.');