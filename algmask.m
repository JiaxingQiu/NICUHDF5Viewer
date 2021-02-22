function [masteralgmask,algmask_newqrs,resultname] = algmask
masteralgmask = {...
        'QRS Detection: ECG I',2;... % 1
        'QRS Detection: ECG II',2;... % 2
        'QRS Detection: ECG III',2;... % 3
        'CU Artifact',1;... % 4
        'WUSTL Artifact',1;... % 5
        'Brady Detection',2;... % 6
        'Desat Detection <80',2;... % 7
        'Apnea Detection with ECG Lead I',3;... % 8
        'Apnea Detection with ECG Lead II',3;... % 9
        'Apnea Detection with ECG Lead III',3;... % 10
        'Apnea Detection with No ECG Lead',3;... % 11
        'Apnea Detection',2;... % 12
        'Periodic Breathing with ECG Lead I',2;... % 13
        'Periodic Breathing with ECG Lead II',2;... % 14
        'Periodic Breathing with ECG Lead III',2;... % 15
        'Periodic Breathing with No ECG Lead',2;... % 16
        'Periodic Breathing',1;... % 17
        'Brady Detection Pete',2;... % 18
        'Desat Detection Pete',2;... % 19
        'Brady Desat',2;... % 20
        'Brady Desat Pete',2;... % 21
        'ABD Pete No ECG',3;... % 22
        'ABD Pete',2;... % 23
        'Save HR in Results',1;... % 24
        'Data Available: Pulse',2;... % 25
        'Data Available: HR',2;... % 26
        'Data Available: SPO2_pct',2;... % 27
        'Data Available: Resp',2;... % 28
        'Data Available: ECG I',2;... % 29
        'Data Available: ECG II',2;... % 30
        'Data Available: ECG III',2;... % 31
        'Desat Detection <85',1;... % 32
        'Desat Detection <90',1;... % 33
        'Hourly HR Mean',1;... % 34
        'Hourly Pulse Mean',1;... % 35
        'Hourly SPO2_pct Mean',1;... % 36
        'Hourly HR Std',1;... % 37
        'Hourly Pulse Std',1;... % 38
        'Hourly SPO2_pct Std',1;... % 39
        'Hourly HR Skewness',1;... % 40
        'Hourly Pulse Skewness',1;... % 41
        'Hourly SPO2_pct Skewness',1;... % 42
        'Hourly HR Kurtosis',1;... % 43
        'Hourly Pulse Kurtosis',1;... % 44
        'Hourly SPO2_pct Kurtosis',1}; % 45
    
resultname = {...
        '',2;... % 1
        '',2;... % 2
        '',2;... % 3
        '/Results/CUartifact',1;... % 4
        '/Results/WUSTLartifact',1;... % 5
        '/Results/Brady<100',2;... % 6
        '/Results/Desat<80',2;... % 7
        '/Results/Apnea-I',3;... % 8
        '/Results/Apnea-II',3;... % 9
        '/Results/Apnea-III',3;... % 10
        '/Results/Apnea-NoECG',3;... % 11
        '/Results/Apnea',2;... % 12
        '/Results/PeriodicBreathing-I',2;... % 13
        '/Results/PeriodicBreathing-II',2;... % 14
        '/Results/PeriodicBreathing-III',2;... % 15
        '/Results/PeriodicBreathing-NoECG',2;... % 16
        '/Results/PeriodicBreathing',1;... % 17
        '/Results/Brady<100-Pete',2;... % 18
        '/Results/Desat<80-Pete',2;... % 19
        '/Results/BradyDesat',2;... % 20
        '/Results/BradyDesatPete',2;... % 21
        '/Results/ABDPete-NoECG',3;... % 22
        '/Results/ABDPete',2;... % 23
        '/Results/HR',1;... % 24
        '/Results/DataAvailable:Pulse',2;... % 25
        '/Results/DataAvailable:HR',2;... % 26
        '/Results/DataAvailable:SPO2_pct',2;... % 27
        '/Results/DataAvailable:Resp',2;... % 28
        '/Results/DataAvailable:ECGI',2;... % 29
        '/Results/DataAvailable:ECGII',2;... % 30
        '/Results/DataAvailable:ECGIII',2;... % 31
        '/Results/Desat<85',1;... % 32
        '/Results/Desat<90',1;... % 33
        '/Results/HourlyHRMean',1;... % 34
        '/Results/HourlyPulseMean',1;... % 35
        '/Results/HourlySPO2_pctMean',1;... % 36
        '/Results/HourlyHRStd',1;... % 37
        '/Results/HourlyPulseStd',1;... % 38
        '/Results/HourlySPO2_pctStd',1;... % 39
        '/Results/HourlyHRSkewness',1;... % 40
        '/Results/HourlyPulseSkewness',1;... % 41
        '/Results/HourlySPO2_pctSkewness',1;... % 42
        '/Results/HourlyHRKurtosis',1;... % 43
        '/Results/HourlyPulseKurtosis',1;... % 44
        '/Results/HourlySPO2_pctKurtosis',1}; % 45

algmask_newqrs = [1:3,6:7,32:33,12,17:21,25:31,34:45];
