function [masteralgmask,algmask_newqrs,resultname] = algmask
% Column 1: display name (what is shown to the user in the BAP)
% Column 2: result file algorithm name (how it is stored)
% Column 3: algorithm version number
% Commented number to the right of the columns: this matches with the algnum case number in run_all_tagging_algs
fullalgorithmlist = {...
        'QRS Detection: ECG I',                  '',                                    2;...% 1
        'QRS Detection: ECG II',                 '',                                    2;...% 2
        'QRS Detection: ECG III',                '',                                    2;...% 3
        'CU Artifact',                           '/Results/CUartifact',                 1;...% 4
        'WUSTL Artifact',                        '/Results/WUSTLartifact',              1;...% 5
        'Brady Detection <100',                  '/Results/Brady<100',                  2;...% 6
        'Apnea Detection with ECG Lead I',       '/Results/Apnea-I',                    3;...% 7
        'Apnea Detection with ECG Lead II',      '/Results/Apnea-II',                   3;...% 8
        'Apnea Detection with ECG Lead III',     '/Results/Apnea-III',                  3;...% 9
        'Apnea Detection with No ECG Lead',      '/Results/Apnea-NoECG',                3;...% 10
        'Apnea Detection',                       '/Results/Apnea',                      2;...% 11
        'Periodic Breathing with ECG Lead I',    '/Results/PeriodicBreathing-I',        2;...% 12
        'Periodic Breathing with ECG Lead II',   '/Results/PeriodicBreathing-II',       2;...% 13
        'Periodic Breathing with ECG Lead III',  '/Results/PeriodicBreathing-III',      2;...% 14
        'Periodic Breathing with No ECG Lead',   '/Results/PeriodicBreathing-NoECG',    2;...% 15
        'Periodic Breathing',                    '/Results/PeriodicBreathing',          1;...% 16
        'Brady Detection Pete',                  '/Results/Brady<100-Pete',             2;...% 17
        'Desat Detection Pete',                  '/Results/Desat<80-Pete',              2;...% 18
        'Brady Desat',                           '/Results/BradyDesat',                 2;...% 19
        'Brady Desat Pete',                      '/Results/BradyDesatPete',             2;...% 20
        'ABD Pete No ECG',                       '/Results/ABDPete-NoECG',              3;...% 21
        'ABD Pete',                              '/Results/ABDPete',                    2;...% 22
        'Save HR in Results',                    '/Results/HR',                         1;...% 23
        'Data Available: Pulse',                 '/Results/DataAvailable:Pulse',        2;...% 24
        'Data Available: HR',                    '/Results/DataAvailable:HR',           2;...% 25
        'Data Available: SPO2_pct',              '/Results/DataAvailable:SPO2_pct',     2;...% 26
        'Data Available: Resp',                  '/Results/DataAvailable:Resp',         2;...% 27
        'Data Available: ECG I',                 '/Results/DataAvailable:ECGI',         2;...% 28
        'Data Available: ECG II',                '/Results/DataAvailable:ECGII',        2;...% 29
        'Data Available: ECG III',               '/Results/DataAvailable:ECGIII',       2;...% 30
        'Desat Detection <75',                   '/Results/Desat<75',                   1;...% 31
        'Desat Detection <76',                   '/Results/Desat<76',                   1;...% 32
        'Desat Detection <77',                   '/Results/Desat<77',                   1;...% 33
        'Desat Detection <78',                   '/Results/Desat<78',                   1;...% 34
        'Desat Detection <79',                   '/Results/Desat<79',                   1;...% 35
        'Desat Detection <80',                   '/Results/Desat<80',                   2;...% 36
        'Desat Detection <81',                   '/Results/Desat<81',                   1;...% 37
        'Desat Detection <82',                   '/Results/Desat<82',                   1;...% 38
        'Desat Detection <83',                   '/Results/Desat<83',                   1;...% 39
        'Desat Detection <84',                   '/Results/Desat<84',                   1;...% 40
        'Desat Detection <85',                   '/Results/Desat<85',                   1;...% 41
        'Desat Detection <86',                   '/Results/Desat<86',                   1;...% 42
        'Desat Detection <87',                   '/Results/Desat<87',                   1;...% 43
        'Desat Detection <88',                   '/Results/Desat<88',                   1;...% 44
        'Desat Detection <89',                   '/Results/Desat<89',                   1;...% 45
        'Desat Detection <90',                   '/Results/Desat<90',                   1;...% 46
        'Desat Detection <91',                   '/Results/Desat<91',                   1;...% 47
        'Desat Detection <92',                   '/Results/Desat<92',                   1;...% 48
        'Desat Detection <93',                   '/Results/Desat<93',                   1;...% 49
        'Desat Detection <94',                   '/Results/Desat<94',                   1;...% 50
        'Desat Detection <95',                   '/Results/Desat<95',                   1;...% 51
        'Hourly HR Mean',                        '/Results/HourlyHRMean',               1;...% 52
        'Hourly Pulse Mean',                     '/Results/HourlyPulseMean',            1;...% 53
        'Hourly SPO2_pct Mean',                  '/Results/HourlySPO2_pctMean',         1;...% 54
        'Hourly HR Std',                         '/Results/HourlyHRStd',                1;...% 55
        'Hourly Pulse Std',                      '/Results/HourlyPulseStd',             1;...% 56
        'Hourly SPO2_pct Std',                   '/Results/HourlySPO2_pctStd',          1;...% 57
        'Hourly HR Skewness',                    '/Results/HourlyHRSkewness',           1;...% 58
        'Hourly Pulse Skewness',                 '/Results/HourlyPulseSkewness',        1;...% 59
        'Hourly SPO2_pct Skewness',              '/Results/HourlySPO2_pctSkewness',     1;...% 60
        'Hourly HR Kurtosis',                    '/Results/HourlyHRKurtosis',           1;...% 61
        'Hourly Pulse Kurtosis',                 '/Results/HourlyPulseKurtosis',        1;...% 62
        'Hourly SPO2_pct Kurtosis',              '/Results/HourlySPO2_pctKurtosis',     1;...% 63
        'Max Cross Correlation HR SPO2_pct',     '/Results/MaxCrossCorrHR_SPO2_pct',    1;...% 64
        'Max Cross Correlation Pulse SPO2_pct',  '/Results/MaxCrossCorrPulse_SPO2_pct', 1};  % 65
    
masteralgmask = fullalgorithmlist(:,[1,3]);
resultname = fullalgorithmlist(:,[2,3]);

algmask_newqrs = [1:3,6,11,16:20,24:65];
