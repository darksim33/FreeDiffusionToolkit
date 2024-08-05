% Pfade und Parameter
niftiDir = 'C:\Users\essjud01\Desktop\Messung_single_b_030724\DICOM\00002B00\AAA0DB34\AA4B36F2_translated_as_nifti\MRT2-test_Phantom-NNLS_GAPF88804\20240703_1637\Boxplots\mit_bval';
toolboxPath = 'C:\Users\essjud01\Downloads\NIfTI_20140122';
resultsFolder = 'C:\Users\essjud01\Desktop\Messung_single_b_030724\Test_Ergebnisse';
radius1 = 20;
innerRadius2 = 50;
outerRadius2 = 55;

% Schritt 1: Erstellen von Masken
createMasks(niftiDir, resultsFolder, toolboxPath, radius1, innerRadius2, outerRadius2);

% Schritt 2: Berechnen des geometrischen Mittels
computeGeometricMean(niftiDir, resultsFolder, toolboxPath);

% Schritt 3: Erstellen von Boxplots und Berechnen des SNR
createBoxplotsAndCalculateSNR(resultsFolder, toolboxPath);
