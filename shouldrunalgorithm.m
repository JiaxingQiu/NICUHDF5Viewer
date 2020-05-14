function [shouldrun] = shouldrunalgorithm(filename,algnum,resultname,algdispname,result_tagtitle,result_qrs)
% shouldrun == 1 -> run the algorithm as normal
% shouldrun == 0 -> don't need to run the algorithm

shouldrun = 1;
newversion = algdispname(algnum,2);

% Find the Result Filename
if contains(filename,'.hdf5')
    resultfilename = strrep(filename,'.hdf5','_results.mat');
elseif contains(filename,'.mat')
    resultfilename = strrep(filename,'.mat','_results.mat');
elseif contains(filename,'.dat')
    resultfilename = strrep(filename,'.dat','_results.mat');
end

% Load in the oldversion tagtitles even if they are already loaded in
if exist(resultfilename,'file')
    load(resultfilename,'result_tagtitle');
    try
        warning('off','MATLAB:load:variableNotFound') % remove this warning message - it will come up too often if someone is adding results to an old version of the files which does not store an empty result_qrs
        load(resultfilename,'result_qrs');
        warning('on','MATLAB:load:variableNotFound') % put the warning message back on for the rest of the program execution
    catch
        warning('on','MATLAB:load:variableNotFound') % put the warning message back on for the rest of the program execution
    end
else
    return
end

% If you are running a QRS Detection Algorithm
if contains(algdispname(algnum),'QRS Detection')
    if contains(algdispname(algnum),'III')
        lead = 3;
    elseif contains(algdispname(algnum),'II')
        lead = 2;
    else
        lead = 1;
    end
    if ~isempty(result_qrs)
        if length(fieldnames(result_qrs))>0 %#ok<ISMT> % must do this length command because structs with no fields do not show up as empty! CRAZY TALK!
            if size(result_qrs,2)>=lead
                if ~isempty(result_qrs(lead).qrs)
                    if isfield(result_qrs(lead).qrs,'version')
                        oldversion = result_qrs(lead).qrs.version;
                    else
                        oldversion = 1; % If it was run before versions were begun, it is version 1
                    end
                else
                    oldversion = [];
                end
            else
                oldversion = [];
            end
        else
            oldversion = [];
        end
    else
        oldversion = [];
    end
    
% If you are running a Data Available Tagging Algorithm    
elseif contains(algdispname(algnum),'Data Available')
    % Check to see if the algorithm name matches any of those in the results file
    if isempty(result_tagtitle)
        return
    end
    
    if sum(contains(result_tagtitle(:,1),algdispname(algnum)))
        % Find out which version number has previously been run
        index = strcmp(result_tagtitle(:,1),algdispname(algnum));
        if size(result_tagtitle,2)>1
            oldversion = result_tagtitle(index,2);
        else
            oldversion = 1;
        end
    else
        oldversion = [];
    end 
    
% If you are running an algorithm that generates a tagtitle
else
    % Check to see if the algorithm name matches any of those in the results file
    if isempty(result_tagtitle)
        return
    end
    
    if sum(contains(result_tagtitle(:,1),resultname(algnum-3)))
        % Find out which version number has previously been run
        index = strcmp(result_tagtitle(:,1), resultname(algnum-3));
        if size(result_tagtitle,2)>1
            oldversion = result_tagtitle(index,2);
        else
            oldversion = 1;
        end
    else
        oldversion = [];
    end    
end

% Find out if the newest version has been run
if iscell(oldversion)
    oldversion = cell2mat(oldversion);
end
if oldversion==cell2mat(newversion)
    shouldrun = 0;
end

