% Pfad zur NIfTI-Datei
pfad = '';

% Dateinamen extrahieren
[~, filename, ext] = fileparts(pfad);

% NIfTI-Datei einlesen
v = niftiread(pfad);
info = niftiinfo(pfad);

% b-Werte und Richtungen definieren
b_values = [0, 80, 160, 240, 320, 400, 480, 560, 640, 720, 800, 880, 960, 1040, 1120, 1200];
R = 3; % Anzahl Richtungen

% Dimensionen der eingelesenen NIfTI-Daten
[nx, ny, nz, nt] = size(v);

% Anzahl der b-Werte
num_b_values = length(b_values);

% Überprüfen, ob die Anzahl der Zeitpunkte mit den b-Werten und Richtungen übereinstimmt
if nt ~= num_b_values * R
    error('Die Anzahl der Zeitpunkte in der NIfTI-Datei stimmt nicht mit der Anzahl der b-Werte und Richtungen überein.');
end

% Initialisiere eine Liste, um die geometrischen Mittelwerte zu speichern
geom_means = zeros(nx, ny, nz, num_b_values, 'like', v); % Verwende den gleichen Datentyp wie das Eingangsbild

% Schleife über die b-Werte
for b = 1:num_b_values
    % Schleife über die Pixel
    for i = 1:nx
        for j = 1:ny
            for k = 1:nz
                % Extrahieren der Pixelwerte für den aktuellen Pixel und b-Wert
                pixel_values = zeros(1, R);
                for r = 1:R
                    pixel_values(r) = v(i, j, k, (b - 1) * R + r);
                end
                
                % Berechnung des geometrischen Mittels über die Wurzel des Produkts
                positive_values = pixel_values(pixel_values > 0);
                if isempty(positive_values)
                    geom_mean = NaN; % Kein Wert im Bild
                else
                    geom_mean = nthroot(prod(positive_values), numel(positive_values));
                end
                geom_means(i, j, k, b) = geom_mean;
            end
        end
    end
end

% Neuen Dateinamen erstellen
new_filename = [filename '_geometric_mean_combined.nii'];

% Erstellen des NIfTI-Infos für die neue Datei
new_info = info;
new_info.Filename = new_filename;
new_info.ImageSize = [nx, ny, nz, num_b_values];
new_info.PixelDimensions = [info.PixelDimensions(1:3), num_b_values];

% Schreiben der neuen NIfTI-Datei
niftiwrite(geom_means, new_info.Filename, new_info);

disp('Geometrisches Mittel für jeden b-Wert berechnet und in einer einzigen NIfTI-Datei gespeichert.');
