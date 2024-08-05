% NIfTI-Toolbox laden
addpath('C:\Users\essjud01\Downloads\NIfTI_20140122'); % Richtigen Pfad angeben!

% Verzeichnis mit NIfTI-Dateien
niftiDir = 'C:\Users\essjud01\Desktop\Messung_single_b_030724\DICOM\00002B00\AAA0DB34\AA4B36F2_translated_as_nifti\MRT2-test_Phantom-NNLS_GAPF88804\20240703_1637\Trace'; % Richtigen Pfad angeben!

% NIfTI-Dateien im Verzeichnis suchen
niftiFiles = dir(fullfile(niftiDir, '*.nii.gz'));

% Radien der Kreise für die Maske
radius1 = 20;
innerRadius2 = 50;
outerRadius2 = 55;

% Schleife über alle NIfTI-Dateien
for i = 1:length(niftiFiles)
    niftiFileName = fullfile(niftiDir, niftiFiles(i).name);
    niftiData = load_nii(niftiFileName);

    % Daten extrahieren
    imgData = niftiData.img;

    % Dimensionen der NIfTI-Daten
    [nx, ny, nz, nb] = size(imgData);

    % Maske initialisieren
    mask = zeros(nx, ny, nz);

    % Mittelpunkt des Kreises in x- und z-Richtung
    centerX = round(nx / 2);
    centerZ = round(nz / 2);
    
    % 2. Schicht in y-Richtung
    ySlice = 2;

    % Erstellen des ersten Kreises in der Maske (Wert 1)
    [X, Z] = meshgrid(1:nx, 1:nz);
    circleMask1 = (X - centerX).^2 + (Z - centerZ).^2 <= radius1^2;
    
    % Erstellen des zweiten Kreises (Ring) in der Maske (Wert 2)
    circleMask2 = (X - centerX).^2 + (Z - centerZ).^2 <= outerRadius2^2 & (X - centerX).^2 + (Z - centerZ).^2 >= innerRadius2^2;

    % Hinzufügen der Kreise zur Maske in der 2. Schicht in y-Richtung
    mask(:, ySlice, :) = circleMask1 * 1 + circleMask2 * 2;

    % Maske in 4D duplizieren (gleiche Maske für alle b-Werte)
    mask4D = repmat(mask, [1, 1, 1, nb]);

    % Speichern der Maske
    maskFileName = fullfile(niftiDir, [niftiFiles(i).name(1:end-7) '_mask.nii']);
    maskNifti = make_nii(mask4D);
    save_nii(maskNifti, maskFileName);

    fprintf('Maske für Datei %s erstellt und als %s gespeichert.\n', niftiFiles(i).name, maskFileName);
end
