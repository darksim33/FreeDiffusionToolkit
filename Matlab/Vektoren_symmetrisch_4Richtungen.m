% Anzahl b-Werte
num_b_values = 64;

% Begrenzung 0 und 1200
b_values = linspace(0, 1200, num_b_values);

% Normalisieren der b-Werte
max_b_value = max(b_values);
norm_b_values = b_values / max_b_value;

% Anzahl Richtungen
R = 4;

% Richtungen definieren
directions = [
    1, 1, 1;
    -1, -1, 1;
    -1, 1, -1;
    1, -1, -1
];

% Richtungen normieren (Einheitsvektoren)
for k = 1:R
    directions(k, :) = directions(k, :) / norm(directions(k, :));
end

% Öffnen der .dvs-Datei zum Schreiben
dvs_filename = 'output.dvs'; % Dateiname anpassen, falls nötig
fileID = fopen(dvs_filename, 'w');

% Schreiben des Kopfblocks
fprintf(fileID, '# -----------------------------------------------------------------------------\r\n');
fprintf(fileID, '# File: c:\\Medcom\\MriCustomer\\seq\\DiffusionVectorSets\\%s\r\n', dvs_filename);
fprintf(fileID, '# Date: %s\r\n', datestr(now, 'ddd mmm dd HH:MM:SS yyyy'));
fprintf(fileID, '# Comment = b values: %s\r\n', num2str(b_values)); % b_values als String
fprintf(fileID, '# -----------------------------------------------------------------------------\r\n');
fprintf(fileID, '[directions=%d]\r\n', R * num_b_values);
fprintf(fileID, 'CoordinateSystem = xyz\r\n');
fprintf(fileID, 'Normalisation = none\r\n');

% Schreiben der Richtungen für jeden normierten b-Wert
vector_count = 0;
for i = 1:num_b_values
    for j = 1:R
        vector = norm_b_values(i) * directions(j, :);
        fprintf(fileID, 'Vector[%d] = ( %.6f, %.6f, %.6f )\r\n', vector_count, vector(1), vector(2), vector(3));
        vector_count = vector_count + 1;
    end
end

% Schließen der Datei
fclose(fileID);
