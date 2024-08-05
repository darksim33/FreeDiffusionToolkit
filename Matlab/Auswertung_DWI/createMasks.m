function createMasks(niftiDir, resultDir, toolboxPath, radius1, innerRadius2, outerRadius2)
    % NIfTI-Toolbox laden
    addpath(toolboxPath);

    % NIfTI-Dateien im Verzeichnis suchen
    niftiFiles = dir(fullfile(niftiDir, '*.nii.gz'));

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

        % Speichern der Maske im resultDir
        maskFileName = fullfile(resultDir, [niftiFiles(i).name(1:end-7) '_mask.nii']);
        maskNifti = make_nii(mask4D);
        save_nii(maskNifti, maskFileName);

        fprintf('Maske für Datei %s erstellt und als %s gespeichert.\n', niftiFiles(i).name, maskFileName);
    end
end
