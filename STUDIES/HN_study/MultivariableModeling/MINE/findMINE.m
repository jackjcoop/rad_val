function [pathMINE] = findMINE(OS)
% -------------------------------------------------------------------------
% function [pathMINE] = findMINE(OS)
% -------------------------------------------------------------------------
% DESCRIPTION: 
% This function finds the full path to the MINE.jar executable on 
% Windows and Linux. The executable can be downloaded from:
% <http://www.exploredata.net/>.
% -------------------------------------------------------------------------
% INPUTS:
% - OS: String specifying the type of operating system. 
%       --> Supports 'Linux' and 'Windows'
% -------------------------------------------------------------------------
% OUTPUTS:
% - pathMINE: Full path to the directory containing MINE.jar.
% -------------------------------------------------------------------------

pathMINE = '';  % Default output if not found

if strcmpi(OS, 'Linux')
    % Search for MINE.jar in common directories (avoiding full system search)
    [status, ~] = system('find /usr/local /opt /home -name "MINE.jar" > temp.txt');
    
elseif strcmpi(OS, 'Windows')
    % Search for MINE.jar in common locations on Windows
    [status, ~] = system('where /r C:\ "MINE.jar" > temp.txt');
    
else
    error('Unsupported OS. Use ''Linux'' or ''Windows''.');
end

% Read search results
fid = fopen('temp.txt', 'r');
if fid == -1
    warning('Could not open temp.txt. Returning empty path.');
    return;
end
temp = fgetl(fid);
fclose(fid);
delete('temp.txt');

% Handle case where MINE.jar is not found
if isempty(temp) || status ~= 0
    warning('MINE.jar not found on the system.');
else
    pathMINE = fileparts(temp); % Extract directory path
end

end
