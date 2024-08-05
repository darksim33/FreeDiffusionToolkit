function computeGeometricMean(niftiDir, resultDir, toolboxPath)
    % NIfTI-Toolbox laden
    addpath(toolboxPath);

    % NIfTI-Dateien im Verzeichnis suchen
    niftiFiles = dir(fullfile(niftiDir, '*.nii.gz'));

    % Funktion zum Extrahieren der Zahl vor 'av' aus dem Dateinamen
    extractNumAverages = @(name) str2double(regexp(name, '(?<=_)\d+(?=av)', 'match', 'once'));

    % Schleife über alle NIfTI-Dateien
    for i = 1:length(niftiFiles)
        % Pfad zur aktuellen NIfTI-Datei
        niftiFileName = fullfile(niftiDir, niftiFiles(i).name);

        % Dateinamen ohne .nii.gz
        [~, filename, ~] = fileparts(niftiFiles(i).name);
        
        % .nii entfernen
        [~, filename, ~] = fileparts(filename);

        % Extrahieren der b-Werte aus der entsprechenden .bval-Datei
        bvalFileName = fullfile(niftiDir, [filename '.bval']);
        
        % Überprüfen, ob die .bval-Datei existiert
        if ~isfile(bvalFileName)
            warning('Die .bval-Datei %s existiert nicht. Überspringen...', bvalFileName);
            continue;
        end
        
        % b-Werte aus der .bval-Datei lesen
        b_values = dlmread(bvalFileName);
        disp(['b_values für Datei ', niftiFiles(i).name, ': ', num2str(b_values)]);

        % Anzahl der aufgenommenen Averages aus dem Dateinamen extrahieren
        num_averages = extractNumAverages(filename);
        
        % Anzahl der Richtungen bestimmen
        unique_b_values = unique(b_values);
        disp(['Eindeutige b-Werte: ', num2str(unique_b_values)]);
        unique_b_values(unique_b_values == 0) = []; % 0-B-Wert entfernen
        R = sum(b_values == unique_b_values(1)); % Anzahl der Wiederholungen des ersten nicht-0 b-Werts
        disp(['Anzahl der Richtungen (R): ', num2str(R)]);

        % NIfTI-Datei einlesen
        v = niftiread(niftiFileName);
        info = niftiinfo(niftiFileName);

        % Dimensionen der eingelesenen NIfTI-Daten
        [nx, ny, nz, nt] = size(v);

        % Anzahl der b-Werte
        num_b_values = length(unique(b_values));
        disp(['Anzahl der b-Werte: ', num2str(num_b_values)]);

        % Überprüfen, ob die Anzahl der Zeitpunkte mit den b-Werten, Richtungen und Averages übereinstimmt
        expected_nt = length(b_values);
        if nt ~= expected_nt
            error('Die Anzahl der Zeitpunkte in der NIfTI-Datei stimmt nicht mit der Anzahl der b-Werte, Richtungen und Averages überein.');
        end

        % Initialisiere eine Liste, um die geometrischen Mittelwerte zu speichern
        geom_means = zeros(nx, ny, nz, num_b_values, 'like', v); % Verwende den gleichen Datentyp wie das Eingangsbild

        % 0 b-Wert separat behandeln
        b_val_0_indices = find(b_values == 0);
        if ~isempty(b_val_0_indices)
            for x = 1:nx
                for y = 1:ny
                    for z = 1:nz
                        pixel_values = v(x, y, z, b_val_0_indices);
                        positive_values = pixel_values(pixel_values > 0);
                        if isempty(positive_values)
                            geom_mean = NaN; % Kein Wert im Bild
                        else
                            geom_mean = nthroot(prod(positive_values), numel(positive_values));
                        end
                        geom_means(x, y, z, 1) = geom_mean; % 0 b-Wert wird als erstes gespeichert
                    end
                end
            end
        end

        % Schleife über die restlichen b-Werte
        for b = 1:numel(unique_b_values)
            b_val = unique_b_values(b);
            disp(['Verarbeitung von b-Wert: ', num2str(b_val)]);
            indices = find(b_values == b_val);
            
            % Schleife über die Pixel
            for x = 1:nx
                for y = 1:ny
                    for z = 1:nz
                        % Extrahieren der Pixelwerte für den aktuellen Pixel und b-Wert
                        pixel_values = zeros(1, length(indices));
                        for idx = 1:length(indices)
                            pixel_values(idx) = v(x, y, z, indices(idx));
                        end

                        % Berechnung des geometrischen Mittels über die Wurzel des Produkts
                        positive_values = pixel_values(pixel_values > 0);
                        if isempty(positive_values)
                            geom_mean = NaN; % Kein Wert im Bild
                        else
                            geom_mean = nthroot(prod(positive_values), numel(positive_values));
                        end
                        geom_means(x, y, z, b + 1) = geom_mean; % +1, weil 0 b-Wert an erster Stelle ist
                    end
                end
            end
        end

        % Neuen Dateinamen mit Pfad erstellen
        new_filename = fullfile(resultDir, [filename '_geometric_mean_combined.nii']);

        % Erstellen des NIfTI-Infos für die neue Datei
        new_info = info;
        new_info.Filename = new_filename;
        new_info.ImageSize = [nx, ny, nz, num_b_values];
        new_info.PixelDimensions = [info.PixelDimensions(1:3), num_b_values];

        % Schreiben der neuen NIfTI-Datei
        niftiwrite(geom_means, new_info.Filename, new_info);

        disp(['Geometrisches Mittel für jeden b-Wert berechnet und in der Datei ', new_info.Filename, ' gespeichert.']);
    end
end
