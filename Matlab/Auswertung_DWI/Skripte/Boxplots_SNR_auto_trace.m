% Pfad zum Ordner mit den Ergebnisdateien
results_folder = 'C:\Users\essjud01\Desktop\Messung_single_b_030724\DICOM\00002B00\AAA0DB34\AA4B36F2_translated_as_nifti\MRT2-test_Phantom-NNLS_GAPF88804\20240703_1637\Trace';

% NIfTI-Toolbox laden
addpath('C:\Users\essjud01\Downloads\NIfTI_20140122');

% Dateien im Ergebnisordner auflisten
result_files = dir(fullfile(results_folder, '*.nii.gz'));

% Anzahl der gefundenen Dateien
num_files = length(result_files);

% Schleife über alle gefundenen Dateien
for f = 1:num_files
    % Dateinamen der aktuellen Datei
  filename = result_files(f).name;
    dot_idx = strfind(filename, '.');  % Findet den Punkt vor der Dateiendung
    base_name = filename(1:dot_idx-1);  % Extrahiert den Basisnamen ohne die Endung

    % Konstruiere den Dateinamen für die .bval Datei
    b_values_file = fullfile(results_folder, [base_name '.bval']);
    
    % Konstruiere den Dateinamen für die Masken-Datei
    mask_file = fullfile(results_folder, [base_name '_mask.nii']);
    
    % Überprüfen, ob die .bval Datei existiert
    if exist(b_values_file, 'file') ~= 2
        error('Die Datei %s konnte nicht gefunden werden.', b_values_file);
    end
    
    % Überprüfen, ob die Masken-Datei existiert
    if exist(mask_file, 'file') ~= 2
        error('Die Masken-Datei %s konnte nicht gefunden werden.', mask_file);
    end
    
    % NIfTI-Datei einlesen
    niftiData = load_nii(fullfile(results_folder, filename));
    imgData = niftiData.img;
    
    % Masken-Datei einlesen
    maskData = load_nii(mask_file);
    mask = maskData.img;
    
    % Überprüfen, ob die Maske 4D ist und sie auf 3D reduzieren
    if ndims(mask) == 4
        mask = mask(:, :, :, 1); % Nehme die erste Schicht der Maske
    end

    % Masken für Signal (Wert 1) und Rauschen (Wert 2)
    mask_signal = mask == 1;
    mask_noise = mask == 2;

    % Überprüfen, ob die Dimensionen der Maske mit den Bilddaten übereinstimmen
    [nx, ny, nz, nb] = size(imgData);
    if ~isequal(size(mask), [nx, ny, nz])
        error('Die Dimensionen der Maske stimmen nicht mit den Bilddaten überein.');
    end

    % B-Werte aus der .bval Datei einlesen
    b_values = importdata(b_values_file);
    unique_b_values = unique(b_values);

    % Anzahl der b-Werte
    num_b_values = length(unique_b_values);

    % Vorbereitung der Daten für den Boxplot und linearen Fit
    boxplotData = cell(num_b_values, 1);
    allData = [];
    allBValues = [];
    
    % Initialisierung für SNR-Berechnung
    snr_all = [];
    snr_per_b = zeros(1, num_b_values);

    for b = 1:num_b_values
        % Daten für den aktuellen b-Wert extrahieren
        bData = imgData(:,:,:,b);
        
        % Nur Werte innerhalb der Signal- und Rauschmasken verwenden
        bDataSignal = bData(mask_signal);
        bDataNoise = bData(mask_noise);
        
        % Null-, Negativwerte sowie Inf und NaN herausfiltern
        validSignalData = bDataSignal(bDataSignal > 0 & isfinite(bDataSignal));
        validNoiseData = bDataNoise(bDataNoise > 0 & isfinite(bDataNoise));
        
        % Sicherstellen, dass validData Vektoren sind und nur gültige numerische Werte enthalten
        if ~isvector(validSignalData) || ~isnumeric(validSignalData)
            error('validSignalData für b-Wert %d ist kein gültiger numerischer Vektor.', unique_b_values(b));
        end
        
        if ~isvector(validNoiseData) || ~isnumeric(validNoiseData)
            error('validNoiseData für b-Wert %d ist kein gültiger numerischer Vektor.', unique_b_values(b));
        end
        
        % Daten in double konvertieren
        validSignalData = double(validSignalData);
        validNoiseData = double(validNoiseData);
        
        % Berechnung des SNR für den aktuellen b-Wert
        mean_signal = mean(validSignalData);
        noise_std = std(validNoiseData);
        snr_per_b(b) = mean_signal / noise_std;
        
        % Zusammenführen der Daten für gesamte SNR-Berechnung
        snr_all = [snr_all; validSignalData];
        
        % Logarithmierte Intensitätswerte
        logDataMasked = log(validSignalData);
        
        % Boxplot-Daten aktualisieren
        boxplotData{b} = logDataMasked;
        
        % Daten für den linearen Fit sammeln
        allData = [allData; logDataMasked];
        allBValues = [allBValues; unique_b_values(b) * ones(size(logDataMasked))];
    end

    % Berechnung des gesamten SNR
    mean_signal_all = mean(snr_all);
    noise_std_all = std(validNoiseData);
    snr_total = mean_signal_all / noise_std_all;

    % Ausgabe des SNRs
    fprintf('SNR für die gesamte Datei %s: %.2f\n', filename, snr_total);
    for b = 1:num_b_values
        fprintf('SNR für b-Wert %d: %.2f\n', unique_b_values(b), snr_per_b(b));
    end
    
    % Manuelles Zeichnen der Boxplots
    figure;
    hold on;

    for b = 1:num_b_values
        % Berechne die Statistiken für den Boxplot
        data = boxplotData{b};
        if isempty(data)
            continue; % Wenn keine Daten für diesen b-Wert vorhanden sind, überspringen
        end
        q1 = quantile(data, 0.25);
        q3 = quantile(data, 0.75);
        med = median(data);
        whiskerLow = min(data(data >= q1 - 1.5 * (q3 - q1)));
        whiskerHigh = max(data(data <= q3 + 1.5 * (q3 - q1)));
        
        % Box zeichnen
        fill([b - 0.2, b + 0.2, b + 0.2, b - 0.2], [q1, q1, q3, q3], 'b', 'FaceAlpha', 0.5);
        
        % Median zeichnen
        plot([b - 0.2, b + 0.2], [med, med], 'r', 'LineWidth', 2);
        
        % Whiskers zeichnen
        plot([b, b], [whiskerLow, q1], 'k');
        plot([b, b], [q3, whiskerHigh], 'k');
        plot([b - 0.1, b + 0.1], [whiskerLow, whiskerLow], 'k');
        plot([b - 0.1, b + 0.1], [whiskerHigh, whiskerHigh], 'k');
        
        % Datenpunkte zeichnen
        plot(b * ones(size(data)), data, 'k.', 'MarkerSize', 1);
    end
    
    % Start b-Wert für den Fit festlegen (z.B. ab 400)
    fitStartBValue = 300;
    
    % Filter für den linearen Fit
    fitIndices = unique_b_values >= fitStartBValue;
    
    % Daten für den Fit auswählen
    fitBValues = allBValues(ismember(allBValues, unique_b_values(fitIndices)));
    fitData = allData(ismember(allBValues, unique_b_values(fitIndices)));
    
    % Linearen Fit durchführen
    if ~isempty(fitData) && ~isempty(fitBValues)
        coeffs = polyfit(fitBValues, fitData, 1);
        fitLine = polyval(coeffs, unique(allBValues));
    
        % Fit-Linie zeichnen
        plot(find(fitIndices), fitLine(fitIndices), 'g-', 'LineWidth', 2);
    end
    
    set(gca, 'XTick', 1:num_b_values, 'XTickLabel', unique_b_values);
    xlabel('b-Werte [s/mm^2]');
    ylabel('Logarithmierte Intensität [a.u.]');
    % title('Boxplot der logarithmierten Intensitäten für verschiedene b-Werte');
    hold off;
    
    % Speichern als Bild (PNG)
    img_filename = fullfile(results_folder, [base_name '_boxplot.png']);
    saveas(gcf, img_filename);
    
    % Schließen der aktuellen Figur, falls nicht mehr benötigt
    close(gcf);
end
