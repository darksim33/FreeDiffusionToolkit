function processNiftiFiles(resultsFolder, toolboxPath, fitStartBValue)
    % NIfTI-Toolbox hinzufügen
    addpath(toolboxPath);

    % Dateien im Ergebnisordner auflisten
    resultFiles = dir(fullfile(resultsFolder, '*.nii.gz'));

    % Anzahl der gefundenen Dateien
    numFiles = length(resultFiles);

    % Tabelle für SNR-Ergebnisse initialisieren
    snrTable = table();

    % Variablennamen initialisieren
    varNames = {'Filename', 'Total_SNR'};

    % Schleife über alle gefundenen Dateien
    for f = 1:numFiles
        % Dateinamen der aktuellen Datei
        filename = resultFiles(f).name;
        dotIdx = strfind(filename, '.');  % Findet den Punkt vor der Dateiendung
        baseName = filename(1:dotIdx-1);  % Extrahiert den Basisnamen ohne die Endung

        % Konstruiere den Dateinamen für die .bval Datei
        bValuesFile = fullfile(resultsFolder, [baseName '.bval']);
        
        % Konstruiere den Dateinamen für die Masken-Datei
        maskFile = fullfile(resultsFolder, [baseName '_mask.nii']);
        
        % Überprüfen, ob die .bval Datei existiert
        if exist(bValuesFile, 'file') ~= 2
            error('Die Datei %s konnte nicht gefunden werden.', bValuesFile);
        end
        
        % Überprüfen, ob die Masken-Datei existiert
        if exist(maskFile, 'file') ~= 2
            error('Die Masken-Datei %s konnte nicht gefunden werden.', maskFile);
        end
        
        % NIfTI-Datei einlesen
        niftiData = load_nii(fullfile(resultsFolder, filename));
        imgData = niftiData.img;
        
        % Masken-Datei einlesen
        maskData = load_nii(maskFile);
        mask = maskData.img;
        
        % Überprüfen, ob die Maske 4D ist und sie auf 3D reduzieren
        if ndims(mask) == 4
            mask = mask(:, :, :, 1); % Nehme die erste Schicht der Maske
        end

        % Masken für Signal (Wert 1) und Rauschen (Wert 2)
        maskSignal = mask == 1;
        maskNoise = mask == 2;

        % Überprüfen, ob die Dimensionen der Maske mit den Bilddaten übereinstimmen
        [nx, ny, nz, nb] = size(imgData);
        if ~isequal(size(mask), [nx, ny, nz])
            error('Die Dimensionen der Maske stimmen nicht mit den Bilddaten überein.');
        end

        % B-Werte aus der .bval Datei einlesen
        bValues = importdata(bValuesFile);
        uniqueBValues = unique(bValues);

        % Anzahl der b-Werte
        numBValues = length(uniqueBValues);

        % Vorbereitung der Daten für den Boxplot und linearen Fit
        boxplotData = cell(numBValues, 1);
        allData = [];
        allBValues = [];
        
        % Initialisierung für SNR-Berechnung
        snrAll = [];
        snrPerB = nan(1, numBValues);

        for b = 1:numBValues
            % Daten für den aktuellen b-Wert extrahieren
            bData = imgData(:,:,:,b);
            
            % Nur Werte innerhalb der Signal- und Rauschmasken verwenden
            bDataSignal = bData(maskSignal);
            bDataNoise = bData(maskNoise);
            
            % Null-, Negativwerte sowie Inf und NaN herausfiltern
            validSignalData = bDataSignal(bDataSignal > 0 & isfinite(bDataSignal));
            validNoiseData = bDataNoise(bDataNoise > 0 & isfinite(bDataNoise));
            
            % Sicherstellen, dass validData Vektoren sind und nur gültige numerische Werte enthalten
            if ~isvector(validSignalData) || ~isnumeric(validSignalData)
                error('validSignalData für b-Wert %d ist kein gültiger numerischer Vektor.', uniqueBValues(b));
            end
            
            if ~isvector(validNoiseData) || ~isnumeric(validNoiseData)
                error('validNoiseData für b-Wert %d ist kein gültiger numerischer Vektor.', uniqueBValues(b));
            end
            
            % Daten in double konvertieren
            validSignalData = double(validSignalData);
            validNoiseData = double(validNoiseData);
            
            % Berechnung des SNR für den aktuellen b-Wert
            meanSignal = mean(validSignalData);
            noiseStd = std(validNoiseData);
            snrPerB(b) = meanSignal / noiseStd;
            
            % Zusammenführen der Daten für gesamte SNR-Berechnung
            snrAll = [snrAll; validSignalData];
            
            % Logarithmierte Intensitätswerte
            logDataMasked = log(validSignalData);
            
            % Boxplot-Daten aktualisieren
            boxplotData{b} = logDataMasked;
            
            % Daten für den linearen Fit sammeln
            allData = [allData; logDataMasked];
            allBValues = [allBValues; uniqueBValues(b) * ones(size(logDataMasked))];
        end

        % Berechnung des gesamten SNR
        meanSignalAll = mean(snrAll);
        noiseStdAll = std(validNoiseData);
        snrTotal = meanSignalAll / noiseStdAll;

        % Ausgabe des SNRs
        fprintf('SNR für die gesamte Datei %s: %.2f\n', filename, snrTotal);
        for b = 1:numBValues
            fprintf('SNR für b-Wert %d: %.2f\n', uniqueBValues(b), snrPerB(b));
        end

        % SNR-Werte in Tabelle speichern
        data = [{baseName}, num2cell(snrTotal), num2cell(snrPerB)];
        currentVarNames = [{'Filename', 'Total_SNR'}, arrayfun(@(x) sprintf('SNR_b_%d', x), uniqueBValues, 'UniformOutput', false)];
        
        if isempty(snrTable)
            snrTable = cell2table(data, 'VariableNames', currentVarNames);
            varNames = currentVarNames;
        else
            % Überprüfen, ob aktuelle Variablennamen neue Spalten benötigen
            newVars = setdiff(currentVarNames, varNames);
            for newVar = newVars
                snrTable.(newVar{1}) = nan(height(snrTable), 1);
            end
            varNames = [varNames, newVars];  % Aktualisiere die vollständige Liste der Variablennamen
            
            % Neue Zeile mit NaNs für nicht existierende Spalten
            newRow = cell2table(data, 'VariableNames', currentVarNames);
            missingVars = setdiff(varNames, currentVarNames);
            for missingVar = missingVars
                newRow.(missingVar{1}) = nan(height(newRow), 1);
            end
            snrTable = [snrTable; newRow];
        end
        
        % Manuelles Zeichnen der Boxplots
        figure;
        hold on;

        for b = 1:numBValues
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
       
        
        % Filter für den linearen Fit
        fitIndices = uniqueBValues >= fitStartBValue;
        
        % Daten für den Fit auswählen
        fitBValues = allBValues(ismember(allBValues, uniqueBValues(fitIndices)));
        fitData = allData(ismember(allBValues, uniqueBValues(fitIndices)));
        
        % Linearen Fit durchführen
        if ~isempty(fitData) && ~isempty(fitBValues)
            coeffs = polyfit(fitBValues, fitData, 1);
            fitLine = polyval(coeffs, unique(allBValues));
        
            % Fit-Linie zeichnen
            plot(find(fitIndices), fitLine(fitIndices), 'g-', 'LineWidth', 2);
        end
        
        set(gca, 'XTick', 1:numBValues, 'XTickLabel', uniqueBValues);
        xlabel('b-Werte [s/mm^2]');
        ylabel('Logarithmierte Intensität [a.u.]');
        hold off;
        
        % Speichern als Bild (PNG)
        imgFilename = fullfile(resultsFolder, [baseName '_boxplot.png']);
        saveas(gcf, imgFilename);
        
        % Schließen der aktuellen Figur, falls nicht mehr benötigt
        close(gcf);
    end

    % Speichern der SNR-Tabelle als Excel-Datei
    excelFilename = fullfile(resultsFolder, 'snr_results.xlsx');
    writetable(snrTable, excelFilename);
end
