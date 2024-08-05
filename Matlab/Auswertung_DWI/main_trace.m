% Ordnerpfade definieren
inputFolder = 'C:\Users\essjud01\Desktop\Messung_single_b_030724\DICOM\00002B00\AAA0DB34\AA4B36F2_translated_as_nifti\MRT2-test_Phantom-NNLS_GAPF88804\20240703_1637\Trace';
outputFolder = 'C:\Users\essjud01\Desktop\Messung_single_b_030724\DICOM\00002B00\AAA0DB34\AA4B36F2_translated_as_nifti\MRT2-test_Phantom-NNLS_GAPF88804\20240703_1637\Trace';
toolboxPath = 'C:\Users\essjud01\Downloads\NIfTI_20140122';
radius1 = 20;
innerRadius2 = 50;
outerRadius2 = 55;
fitStartBValue = 300;
% createMasks Funktion aufrufen
createMasks(inputFolder, outputFolder, toolboxPath, radius1, innerRadius2, outerRadius2);

% Boxplots zeichnen und SNR berechnen
processNiftiFiles(outputFolder, toolboxPath, fitStartBValue);
