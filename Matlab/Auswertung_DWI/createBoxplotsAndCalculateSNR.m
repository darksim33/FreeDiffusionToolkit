function createBoxplotsAndCalculateSNR(resultsFolder, toolboxPath)
    % NIfTI-Toolbox hinzufügen
    addpath(toolboxPath);

    % Verzeichnis mit den NIfTI-Dateien und Masken durchsuchen
    niftiFiles = dir(fullfile(resultsFolder, '*_geometric_mean_combined.nii'));
    
    % Vorläufige Speicherung der SNR-Werte zur späteren Verarbeitung
    tempSNRData = cell(length(niftiFiles), 1);
    allBValues = [];
    
    % Maximale Anzahl an b-Werten ermitteln
    maxBValues = 0;
    
    for i = 1:length(niftiFiles)
        % Pfad zur NIfTI-Datei
        niftiFileName = fullfile(resultsFolder, niftiFiles(i).name);
        
        % Dateiname ohne Erweiterung
        [~, baseName, ~] = fileparts(niftiFiles(i).name);
        
        % Korrektur des Basisnamens
        baseNameParts = strsplit(baseName, '_');
        baseNameCorrected = strjoin(baseNameParts(1:end-3), '_');
        
        % Pfad zur .bval Datei
        bValuesFileName = fullfile(resultsFolder, [baseNameCorrected '.bval']);
        
        % Pfad zur Masken-Datei
        maskFileName = fullfile(resultsFolder, [baseNameCorrected '_mask.nii']);
        
        % Überprüfen, ob die .bval Datei existiert
        if ~isfile(bValuesFileName)
            error('Die Datei %s konnte nicht gefunden werden.', bValuesFileName);
        end
        
        % Überprüfen, ob die Masken-Datei existiert
        if ~isfile(maskFileName)
            error('Die Masken-Datei %s konnte nicht gefunden werden.', maskFileName);
        end
        
        try
            % NIfTI-Datei einlesen
            niftiData = niftiread(niftiFileName);
            imgData = niftiData;
            
            % Masken-Datei einlesen
            mask = niftiread(maskFileName);
            
            % Überprüfen, ob die Maske 4D ist und sie auf 3D reduzieren
            if ndims(mask) == 4
                mask = mask(:,:,:,1); % Nehme die erste Schicht der Maske
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
            bValues = importdata(bValuesFileName);
            uniqueBValues = unique(bValues);

            % Anzahl der b-Werte
            numBValues = length(uniqueBValues);

            % Update der maximalen Anzahl von b-Werten
            maxBValues = max(maxBValues, numBValues);

            % Vorbereitung der Daten für den Boxplot und linearen Fit
            boxplotData = cell(numBValues, 1);
            allData = [];
            
            % Initialisierung für SNR-Berechnung
            snrAll = [];
            snrPerB = nan(1, numBValues); % Initialisierung mit NaN, falls kein Wert berechnet wird

            for b = 1:numBValues
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
                    error('validSignalData für b-Wert %d ist kein gültiger numerischer Vektor.', uniqueBValues(b));
                end
                
                if ~isvector(validNoiseData) || ~isnumeric(validNoiseData)
                    error('validNoiseData für b-Wert %d ist kein gültiger numerischer Vektor.', uniqueBValues(b));
                end
                
                % Daten in double konvertieren
                validSignalData = double(validSignalData);
                validNoiseData = double(validNoiseData);
                
                % Berechnung des SNR für den aktuellen b-Wert
                if ~isempty(validSignalData) && ~isempty(validNoiseData)
                    meanSignal = mean(validSignalData);
                    noiseStd = std(validNoiseData);
                    snrPerB(b) = meanSignal / noiseStd;
                end
                
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
            if ~isempty(snrAll) && ~isempty(validNoiseData)
                meanSignalAll = mean(snrAll);
                noiseStdAll = std(validNoiseData);
                snrTotal = meanSignalAll / noiseStdAll;
            else
                snrTotal = NaN;
            end

            % Ausgabe des SNRs
            fprintf('SNR für die gesamte Datei %s: %.2f\n', niftiFiles(i).name, snrTotal);
            for b = 1:numBValues
                fprintf('SNR für b-Wert %d: %.2f\n', uniqueBValues(b), snrPerB(b));
            end
            
            % Ergebnisse in der Tabelle speichern
            snrData = num2cell(snrPerB);
            if length(snrData) < maxBValues
                snrData = [snrData, num2cell(nan(1, maxBValues - length(snrData)))];
            end
            tempSNRData{i} = [{baseNameCorrected}, snrTotal, snrData{:}];
            
        catch ME
            warning('Fehler beim Verarbeiten der Datei %s: %s', niftiFiles(i).name, ME.message);
        end
    end
    
    % Tabelle initialisieren
    varNames = {'FileName', 'SNR_Total'};
    for b = 1:maxBValues
        varNames{end+1} = sprintf('SNR_B%d', b);
    end
    snrTable = cell2table(cell(0, length(varNames)), 'VariableNames', varNames);
    
    % Tabelle aus den vorläufigen SNR-Daten erstellen
    for i = 1:length(tempSNRData)
        if isempty(tempSNRData{i})
            continue;
        end
        data = tempSNRData{i};
        % Erstellen einer Zeile der Tabelle
        row = cell(1, length(varNames));
        row(1:length(data)) = data;
        % Hinzufügen der Zeile zur Tabelle
        snrTable = [snrTable; cell2table(row, 'VariableNames', varNames)];
    end
    
    % Speichern der SNR-Tabelle als Excel-Datei
    snrTableFileName = fullfile(resultsFolder, 'SNR_Results.xlsx');
    writetable(snrTable, snrTableFileName);
    fprintf('SNR-Tabelle gespeichert als %s\n', snrTableFileName);
end
