% NIfTI-Toolbox laden
addpath(''); % Richtigen Pfad angeben!

% NIfTI-Datei einlesen
niftiFileName = ''; % Richtigen Pfad angeben!
niftiData = load_nii(niftiFileName);

% NIfTI-Maske einlesen
maskFileName = ''; % Richtigen Pfad angeben!
maskData = load_nii(maskFileName);

% Daten extrahieren
imgData = niftiData.img;
mask = maskData.img;

% Überprüfen, ob die Maske 4D ist und sie auf 3D reduzieren
if ndims(mask) == 4
    mask = mask(:, :, :, 1); % Nehme die erste Schicht der Maske
end

% Überprüfen, ob die Dimensionen der Maske mit den Bilddaten übereinstimmen
[nx, ny, nz, nb] = size(imgData);
if ~isequal(size(mask), [nx, ny, nz])
    error('Die Dimensionen der Maske stimmen nicht mit den Bilddaten überein.');
end

% b-Werte anpassen!
bValues = [0, 80, 160, 240, 320, 400, 480, 560, 640, 720, 800, 880, 960, 1040, 1120, 1200]; 

% Überprüfen, ob die Anzahl der b-Werte korrekt ist
if length(bValues) ~= nb
    error('Die Anzahl der b-Werte in bValues stimmt nicht mit der vierten Dimension der NIfTI-Daten überein.');
end

% Vorbereitung der Daten für den Boxplot und linearen Fit
boxplotData = cell(nb, 1);
allData = [];
allBValues = [];

for b = 1:nb
    % Daten für den aktuellen b-Wert extrahieren
    bData = imgData(:,:,:,b);
    
    % Nur Werte innerhalb der Maske verwenden
    bDataMasked = bData(mask > 0);
    
    % Null-, Negativwerte sowie Inf und NaN herausfiltern
    validData = bDataMasked(bDataMasked > 0 & isfinite(bDataMasked));
    
    % Ausgabe der Anzahl der gültigen Daten
    fprintf('Anzahl der gültigen Daten für b-Wert %d: %d\n', bValues(b), length(validData));
    
    % Sicherstellen, dass validData ein Vektor ist und nur gültige numerische Werte enthält
    if ~isvector(validData) || ~isnumeric(validData)
        error('validData für b-Wert %d ist kein gültiger numerischer Vektor.', bValues(b));
    end
    
    % Daten in double konvertieren
    validData = double(validData);
    
    % Logarithmierte Intensitätswerte
    try
        if ~isempty(validData)
            logDataMasked = log(validData);
        else
            logDataMasked = [];
        end
    catch ME
        fprintf('Fehler beim Berechnen des Logarithmus für b-Wert %d: %s\n', bValues(b), ME.message);
        logDataMasked = [];
    end
    
    % Boxplot-Daten aktualisieren
    boxplotData{b} = logDataMasked;
    
    % Daten für den linearen Fit sammeln
    allData = [allData; logDataMasked];
    allBValues = [allBValues; bValues(b) * ones(size(logDataMasked))];
end

% Manuelles Zeichnen der Boxplots
figure;
hold on;

for b = 1:nb
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
fitStartBValue = 400;

% Filter für den linearen Fit
fitIndices = bValues >= fitStartBValue;

% Daten für den Fit auswählen
fitBValues = allBValues(ismember(allBValues, bValues(fitIndices)));
fitData = allData(ismember(allBValues, bValues(fitIndices)));

% Linearen Fit durchführen
if ~isempty(fitData) && ~isempty(fitBValues)
    coeffs = polyfit(fitBValues, fitData, 1);
    fitLine = polyval(coeffs, bValues);
    
    % Fit-Linie zeichnen
    plot(find(fitIndices), fitLine(fitIndices), 'g-', 'LineWidth', 2);
end

set(gca, 'XTick', 1:nb, 'XTickLabel', bValues);
xlabel('b-Werte');
ylabel('Logarithmierte Intensität');
title('Boxplot der logarithmierten Intensitäten für verschiedene b-Werte innerhalb der Maske');
hold off;
