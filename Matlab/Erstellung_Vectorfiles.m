% b_values = [0, 50, 100, 150, 200, 300, 400, 500, 600, 700, 800, 1000, 1200, 1400, 1600, 1800];
% b_comment = 'aktuell';
b_values = [0, 80, 160, 240, 320, 400, 480, 560, 640, 720, 800, 880, 960, 1040, 1120, 1200];
b_comment = 'symmetrisch';
% b_values = [0, 30, 60, 90, 120, 150, 200, 250, 300, 375, 450, 600, 750, 900, 1050, 1200];
% b_comment = 'front';
% b_values = [0, 150, 300, 450, 600, 750, 825, 900, 950, 1000, 1050, 1080, 1110, 1140, 1170, 1200];
% b_comment = 'back';

num_b_values = length(b_values);

% Anzahl Richtungen
dir = 64;

% Größter b-Wert
max_b_value = max(b_values);

% Dateiname .dvs-Datei
dvs_filename = sprintf('%s_%d_none.dvs', b_comment, dir);

% Öffnen der .dvs-Datei zum Schreiben
fileID = fopen(dvs_filename, 'w');

% Erstellen eines Strings für die benutzten b-Werte
b_values_str = sprintf('%d ', b_values);

% Schreiben des Kopfblocks
fprintf(fileID, '# -----------------------------------------------------------------------------\r\n');
fprintf(fileID, '# File: c:\\Medcom\\MriCustomer\\seq\\DiffusionVectorSets\\%s\r\n', dvs_filename);
fprintf(fileID, '# Date: %s\r\n', datestr(now, 'ddd mmm dd HH:MM:SS yyyy'));
fprintf(fileID, '# Comment = b values: %s\r\n', b_values_str);
fprintf(fileID, '# -----------------------------------------------------------------------------\r\n');
fprintf(fileID, '[directions=%d]\r\n', dir * num_b_values);
fprintf(fileID, 'CoordinateSystem = xyz\r\n');
fprintf(fileID, 'Normalisation = none\r\n');

% Schleife über b-Werte
for b = 1:num_b_values
    % Berechnung der normierten Länge des Vektors
    if max_b_value == 0
        length_b = 0;
    else
        length_b = b_values(b) / max_b_value;
    end
    % Erstellen der Vektoren
    result_vector = zeros(dir, 3);
    % Berechnung der Richtungen
    phi_values = linspace(0, 2*pi, dir);
    theta_values = linspace(0, pi/2, dir);
    % Berechnung der Vektoren für alle Richtungen
    for i = 1:dir
        % Berechnung der Winkel
        phi = phi_values(i);
        theta = theta_values(i);
        % Umrechnung in kartesische Koordinaten
        x = sin(theta) * cos(phi);
        y = sin(theta) * sin(phi);
        z = cos(theta);
        % Normierung der Länge
        if b_values(b) == 0
            result_vector(i, :) = [0, 0, 0];
        else
            norm_factor = sqrt(x^2 + y^2 + z^2);
            result_vector(i, :) = [x, y, z] / norm_factor * length_b;
        end
    end
    
    % Ausgabe der Vektoren in die .dvs-Datei
    for i = 1:dir
        fprintf(fileID, 'Vector[%d] = ( %.6f, %.6f, %.6f )\r\n', (b-1) * dir + i - 1, result_vector(i, 1), result_vector(i, 2), result_vector(i, 3));
    end
end
% Schließen der .dvs-Datei
fclose(fileID);
