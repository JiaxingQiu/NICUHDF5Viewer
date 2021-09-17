function [masteralgmask,algs_to_include,resultname] = algmask
% This is a register of all possible algorithms that can be loaded into the
% BAP and the HDF5 Viewer. To change which algorithms are called in the BAP
% or the viewer, simply alter the algs_to_include matrix at the bottom of
% this script. The order of the algorithms in this script must match the
% order of the algorithms in run_all_tagging_algs.m.
%
% OUTPUT:
%   masteralgmask: a cell array containing the algorithm display name and version number
%   algs_to_include: an array containing the numerical indexes of the algorithms to be run
%   resultname: a cell array containing the algorithm names and version numbers stored in the results files

% Column 1: display name (what is shown to the user in the BAP)
% Column 2: result file algorithm name (how it is stored)
% Column 3: algorithm version number
% Commented number to the right of the columns: this matches with the algnum case number in run_all_tagging_algs
fullalgorithmlist = {...
        'QRS Detection: ECG I',                         '',                                                      2;...% 1
        'QRS Detection: ECG II',                        '',                                                      2;...% 2
        'QRS Detection: ECG III',                       '',                                                      2;...% 3
        'CU Artifact',                                  '/Results/CUartifact',                                   2;...% 4
        'WUSTL Artifact',                               '/Results/WUSTLartifact',                                2;...% 5
        'Brady Detection <100',                         '/Results/Brady<100',                                    4;...% 6
        'Apnea Detection with ECG Lead I',              '/Results/Apnea-I',                                      4;...% 7
        'Apnea Detection with ECG Lead II',             '/Results/Apnea-II',                                     4;...% 8
        'Apnea Detection with ECG Lead III',            '/Results/Apnea-III',                                    4;...% 9
        'Apnea Detection with No ECG Lead',             '/Results/Apnea-NoECG',                                  4;...% 10
        'Apnea Detection',                              '/Results/Apnea',                                        3;...% 11
        'Periodic Breathing with ECG Lead I',           '/Results/PeriodicBreathing-I',                          3;...% 12
        'Periodic Breathing with ECG Lead II',          '/Results/PeriodicBreathing-II',                         3;...% 13
        'Periodic Breathing with ECG Lead III',         '/Results/PeriodicBreathing-III',                        3;...% 14
        'Periodic Breathing with No ECG Lead',          '/Results/PeriodicBreathing-NoECG',                      3;...% 15
        'Periodic Breathing',                           '/Results/PeriodicBreathing',                            3;...% 16
        'Brady Detection Pete',                         '/Results/Brady<100-Pete',                               4;...% 17
        'Desat Detection Pete',                         '/Results/Desat<80-Pete',                                4;...% 18
        'Brady Desat',                                  '/Results/BradyDesat',                                   4;...% 19
        'Brady Desat Pete',                             '/Results/BradyDesatPete',                               4;...% 20
        'ABD No ECG',                                   '/Results/ABD-NoECG',                                    3;...% 21
        'ABD',                                          '/Results/ABD',                                          3;...% 22
        'Save HR in Results',                           '/Results/HR',                                           2;...% 23
        'Data Available: Pulse',                        '/Results/DataAvailable:Pulse',                          4;...% 24
        'Data Available: HR',                           '/Results/DataAvailable:HR',                             4;...% 25
        'Data Available: SPO2_pct',                     '/Results/DataAvailable:SPO2_pct',                       4;...% 26
        'Data Available: Resp',                         '/Results/DataAvailable:Resp',                           3;...% 27
        'Data Available: ECG I',                        '/Results/DataAvailable:ECGI',                           3;...% 28
        'Data Available: ECG II',                       '/Results/DataAvailable:ECGII',                          3;...% 29
        'Data Available: ECG III',                      '/Results/DataAvailable:ECGIII',                         3;...% 30
        'Desat Detection <75',                          '/Results/Desat<75',                                     4;...% 31
        'Desat Detection <76',                          '/Results/Desat<76',                                     4;...% 32
        'Desat Detection <77',                          '/Results/Desat<77',                                     4;...% 33
        'Desat Detection <78',                          '/Results/Desat<78',                                     4;...% 34
        'Desat Detection <79',                          '/Results/Desat<79',                                     4;...% 35
        'Desat Detection <80',                          '/Results/Desat<80',                                     4;...% 36
        'Desat Detection <81',                          '/Results/Desat<81',                                     4;...% 37
        'Desat Detection <82',                          '/Results/Desat<82',                                     4;...% 38
        'Desat Detection <83',                          '/Results/Desat<83',                                     4;...% 39
        'Desat Detection <84',                          '/Results/Desat<84',                                     4;...% 40
        'Desat Detection <85',                          '/Results/Desat<85',                                     4;...% 41
        'Desat Detection <86',                          '/Results/Desat<86',                                     4;...% 42
        'Desat Detection <87',                          '/Results/Desat<87',                                     4;...% 43
        'Desat Detection <88',                          '/Results/Desat<88',                                     4;...% 44
        'Desat Detection <89',                          '/Results/Desat<89',                                     4;...% 45
        'Desat Detection <90',                          '/Results/Desat<90',                                     4;...% 46
        'Desat Detection <91',                          '/Results/Desat<91',                                     4;...% 47
        'Desat Detection <92',                          '/Results/Desat<92',                                     4;...% 48
        'Desat Detection <93',                          '/Results/Desat<93',                                     4;...% 49
        'Desat Detection <94',                          '/Results/Desat<94',                                     4;...% 50
        'Desat Detection <95',                          '/Results/Desat<95',                                     4;...% 51
        'HR Mean',                                      '/Results/HRMean',                                       3;...% 52
        'Pulse Mean',                                   '/Results/PulseMean',                                    3;...% 53
        'SPO2_pct Mean',                                '/Results/SPO2_pctMean',                                 3;...% 54
        'HR Std',                                       '/Results/HRStd',                                        3;...% 55
        'Pulse Std',                                    '/Results/PulseStd',                                     3;...% 56
        'SPO2_pct Std',                                 '/Results/SPO2_pctStd',                                  3;...% 57
        'HR Skewness',                                  '/Results/HRSkewness',                                   3;...% 58
        'Pulse Skewness',                               '/Results/PulseSkewness',                                3;...% 59
        'SPO2_pct Skewness',                            '/Results/SPO2_pctSkewness',                             3;...% 60
        'HR Kurtosis',                                  '/Results/HRKurtosis',                                   3;...% 61
        'Pulse Kurtosis',                               '/Results/PulseKurtosis',                                3;...% 62
        'SPO2_pct Kurtosis',                            '/Results/SPO2_pctKurtosis',                             3;...% 63
        'Max Cross Correlation HR SPO2_pct',            '/Results/MaxCrossCorrHR_SPO2_pct',                      3;...% 64
        'Max Cross Correlation Pulse SPO2_pct',         '/Results/MaxCrossCorrPulse_SPO2_pct',                   3;...% 65
        'HCTSA FC_Surprise HR How Surprised',           '/Results/HCTSA_FC_Surprise_HR_HowSurprised',            2;...% 66
        'HCTSA SB_MotifTwo HR Prob Increases',          '/Results/HCTSA_SB_MotifTwo_HR_ProbIncreases',           2;...% 67
        'HCTSA PH_Walker SPO2 Std Rand Walk',           '/Results/HCTSA_PH_Walker_SPO2_StdRandWalk',             2;...% 68
        'HCTSA EX_MovingThreshold HR Avg Thresh',       '/Results/HCTSA_EX_MovingThreshold_HR_AvgThresh',        2;...% 69
        'HCTSA EX_MovingThreshold SPO2 Avg Thresh',     '/Results/HCTSA_EX_MovingThreshold_SPO2_AvgThres',       2;...% 70
        'HCTSA DN_cv HR Std Dist',                      '/Results/HCTSA_DN_cv_HR_StdDist',                       2;...% 71
        'HCTSA DN_Cumulants HR Skew Dist',              '/Results/HCTSA_DN_Cumulants_HR_SkewDist',               2;...% 72
        'HCTSA DN_Quantile HR Max Dist',                '/Results/HCTSA_DN_Quantile_HR_MaxDist',                 2;...% 73
        'HCTSA SB_TransitionMatrix3 HR Sym Autocorr'    '/Results/HCTSA_SB_TransitionMatrix3_HR_SymAutocorr',    2;...% 74
        'HCTSA SB_MotifThree HR Sym Entropy'            '/Results/HCTSA_SB_MotifThree_HR_SymEntropy',            2;...% 75
        'HCTSA MF_arfit HR Wavelet Autoregress'         '/Results/HCTSA_MF_arfit_HR_WaveletAutoregress',         2;...% 76
        'HCTSA SB_MotifThree HR Sym Diffs'              '/Results/HCTSA_SB_MotifThree_HR_SymDiffs',              2;...% 77
        'HCTSA SY_StdNthDer HR 17thDeriv',              '/Results/HCTSA_SY_StdNthDer_HR_17thDeriv',              2;...% 78
        'HCTSA DN_RemovePoints SPO2 Mean Dist',         '/Results/HCTSA_DN_RemovePoints_SPO2_MeanDist',          2;...% 79
        'HCTSA SB_BinaryStats SPO2 Sym IQR',            '/Results/HCTSA_SB_BinaryStats_SPO2_SymIQR',             2;...% 80
        'HCTSA MF_arfit SPO2 Wavelet Autoregress',      '/Results/HCTSA_MF_arfit_SPO2_WaveletAutoregress',       2;...% 81
        'HCTSA SB_TransitionMatrix2 SPO2 Sym Eigen',    '/Results/HCTSA_SB_TransitionMatrix2_SPO2_SymEigen',     2;...% 82
        'HCTSA CO_AutoCorr SPO2',                       '/Results/HCTSA_CO_AutoCorr_SPO2',                       2;...% 83
        'HCTSA SB_MotifThree SPO2 Sym Entropy',         '/Results/HCTSA_SB_MotifThree_SPO2_SymEntropy',          2;...% 84
        'HCTSA SB_TransitionMatrix1 SPO2 Sym Bin',      '/Results/HCTSA_SB_TransitionMatrix1_SPO2_SymBin',       2;...% 85
        'HCTSA ST_LocalExtrema SPO2 Stationarity Min',  '/Results/HCTSA_ST_LocalExtrema_SPO2_StationMin',        2;...% 86
        'HCTSA ST_LocalExtrema HR Stationarity Min',    '/Results/HCTSA_ST_LocalExtrema_HR_StationMin',          2;...% 87
        'HCTSA CO_tc3 HR Correlaton Mean',              '/Results/HCTSA_CO_tc3_HR_CorrMean',                     2;...% 88
        'HCTSA CO_tc3 SPO2 Correlaton Mean',            '/Results/HCTSA_CO_tc3_SPO2_CorrMean',                   2;...% 89
        'Brady Detection <90',                          '/Results/Brady<90',                                     4;...% 90
        'Brady Detection <80',                          '/Results/Brady<80',                                     4;...% 91
        'Brady Detection <70',                          '/Results/Brady<70',                                     4;...% 92
        'Hyperoxemia Detection >95',                    '/Results/Hyperoxemia>95',                               1;...% 93
        'Hyperoxemia Detection >98',                    '/Results/Hyperoxemia>98',                               1;...% 94
        'Flat Detection Resp >10s',                     '/Results/FlatResp>10s',                                 1};% 95
    
    
   
    
masteralgmask = fullalgorithmlist(:,[1,3]);
resultname = fullalgorithmlist(:,[2,3]);

algs_to_include = [1:3,6,90:92,11,16:20,22,24:31,36,41,46,51,93:95,52:89];
