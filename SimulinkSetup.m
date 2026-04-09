%% setup simulink model with its signals and parameters
mdl = 'Teensy_Model';

mws = get_param(mdl, 'ModelWorkspace');

ts = 1e-3;
pwmFreq = 20e3;

%% Signals
MDCurrent = Simulink.Signal;
MDCurrent.Description = "MD_Current";
MDCurrent.DataType = "single";
MDCurrent.Complexity = "real";

MotorSpeed_In = Simulink.Signal;
MotorSpeed_In.Description = "MotorSpeed_In";
MotorSpeed_In.DataType = "single";
MotorSpeed_In.Complexity = "real";

TorqSpeed_In = Simulink.Signal;
TorqSpeed_In.Description = "TorqSpeed_In";
TorqSpeed_In.DataType = "single";
TorqSpeed_In.Complexity = "real";

Torq_Signal = Simulink.Signal;
Torq_Signal.Description = "Torq_Signal";
Torq_Signal.DataType = "single";
Torq_Signal.Complexity = "real";

% Assign to model workspace
assignin(mws, MDCurrent.Description,        MDCurrent);
assignin(mws, MotorSpeed_In.Description,    MotorSpeed_In);
assignin(mws, TorqSpeed_In.Description,     TorqSpeed_In);
assignin(mws, Torq_Signal.Description,      Torq_Signal);  

%% Parameters
Status_LED = Simulink.Parameter;
Status_LED.Description = "Status_LED";
Status_LED.DataType = "boolean";
Status_LED.Value = 0;
% Status_LED.CoderInfo.StorageClass = "ExportedGlobal";

Torq_Out = Simulink.Parameter;
Torq_Out.Description = "Torq_Out";
Torq_Out.DataType = "uint8";
Torq_Out.Value = 0;

Speed_Out = Simulink.Parameter;
Speed_Out.Description = "Speed_Out";
Speed_Out.DataType = "uint8";
Speed_Out.Value = 0;

Motor_Enable = Simulink.Parameter;
Motor_Enable.Description = "Motor_Enable";
Motor_Enable.DataType = "boolean";
Motor_Enable.Value = 0;

Motor_Stop = Simulink.Parameter;
Motor_Stop.Description = "Motor_Stop";
Motor_Stop.DataType = "boolean";
Motor_Stop.Value = 0;

Footcontrol = Simulink.Parameter;
Footcontrol.Description = "Footcontrol";
Footcontrol.DataType = "uint8";
Footcontrol.Value = 0;

% Assign to model workspace
assignin(mws, Status_LED.Description,       Status_LED);
assignin(mws, Torq_Out.Description,         Torq_Out);
assignin(mws, Speed_Out.Description,        Speed_Out);
assignin(mws, Motor_Enable.Description,     Motor_Enable);
assignin(mws, Motor_Stop.Description,       Motor_Stop);
assignin(mws, Footcontrol.Description,      Footcontrol);

%%
 % entries = writeA2LAddresses([MDCurrent.Description, Speed_Out.Description], a2lFilename, pythonFilename)
entries = writeA2LAddresses( ["CONST_AMPLITUDE","Counter","sine_wave","pulse"], 'arduino_xcponserial_Teensy_2025b.a2l', 'pytestfile.py');

%%
function entries = writeA2LAddresses(names, a2lFilename, pythonFilename)
% writeA2LAddresses  Read selected symbols from an A2L and write Python ADDR_* constants.
%
% Usage:
%   writeA2LAddresses(["CONST_AMPLITUDE","Counter"], "file.a2l", "addr_map.py")
%
% Input:
%   names           string/cellstr of short names to search, e.g. "CONST_AMPLITUDE", "Counter"
%   a2lFilename     path to .a2l file
%   pythonFilename  output .py file
%
% Output:
%   entries         struct array with fields: QueryName, A2LName, AddressHex, Type, Kind, PyName

    if ischar(names)
        names = string({names});
    elseif iscell(names)
        names = string(names);
    else
        names = string(names);
    end

    txt = fileread(a2lFilename);

    % Find all CHARACTERISTIC and MEASUREMENT blocks
    charBlocks = regexp(txt, '/begin\s+CHARACTERISTIC\b[\s\S]*?/end\s+CHARACTERISTIC', 'match');
    measBlocks = regexp(txt, '/begin\s+MEASUREMENT\b[\s\S]*?/end\s+MEASUREMENT', 'match');

    entries = struct('QueryName', {}, 'A2LName', {}, 'AddressHex', {}, ...
                     'Type', {}, 'Kind', {}, 'PyName', {});

    for i = 1:numel(names)
        query = strtrim(names(i));
        found = false;

        % Search CHARACTERISTIC
        for k = 1:numel(charBlocks)
            info = parseCharacteristicBlock(charBlocks{k});
            if isMatchName(info.Name, query)
                entries(end+1) = makeEntry(query, info.Name, info.AddressHex, info.Type, "CHARACTERISTIC"); %#ok<AGROW>
                found = true;
                break;
            end
        end
        if found
            continue;
        end

        % Search MEASUREMENT
        for k = 1:numel(measBlocks)
            info = parseMeasurementBlock(measBlocks{k});
            if isMatchName(info.Name, query)
                entries(end+1) = makeEntry(query, info.Name, info.AddressHex, info.Type, "MEASUREMENT"); %#ok<AGROW>
                found = true;
                break;
            end
        end

        if ~found
            warning('Name not found in A2L: %s', query);
        end
    end

    % Write Python file
    fid = fopen(pythonFilename, 'w');
    if fid < 0
        error('Cannot open output file: %s', pythonFilename);
    end

    [~, a2lBase, a2lExt] = fileparts(a2lFilename);
    fprintf(fid, '# Addresses from A2L (%s%s)\n', a2lBase, a2lExt);

    maxLen = 0;
    for i = 1:numel(entries)
        maxLen = max(maxLen, strlength(entries(i).PyName));
    end

    for i = 1:numel(entries)
        lhs = pad(entries(i).PyName, maxLen);
        fprintf(fid, '%s = %s  # %s\n', lhs, entries(i).AddressHex, entries(i).Type);
    end

    fclose(fid);
end

function out = parseCharacteristicBlock(block)
    out.Name = extractFirst(block, '/begin\s+CHARACTERISTIC\s+([^\s\r\n]+)');
    out.AddressHex = upper(extractFirst(block, '\/\*\s*ECU Address\s*\*\/\s*(0x[0-9A-Fa-f]+)'));

    recLayout = extractFirst(block, '\/\*\s*Record Layout\s*\*\/\s*([^\s\r\n]+)');
    out.Type = erase(recLayout, 'Record_');
    if strlength(out.Type) == 0
        out.Type = "UNKNOWN";
    end
end

function out = parseMeasurementBlock(block)
    out.Name = extractFirst(block, '/begin\s+MEASUREMENT\s+([^\s\r\n]+)');
    out.Type = extractFirst(block, '\/\*\s*Data type\s*\*\/\s*([^\s\r\n]+)');
    out.AddressHex = upper(extractFirst(block, 'ECU_ADDRESS\s+(0x[0-9A-Fa-f]+)'));

    if strlength(out.Type) == 0
        out.Type = "UNKNOWN";
    end
end

function tf = isMatchName(fullA2LName, query)
    fullA2LName = string(strtrim(fullA2LName));
    query = string(strtrim(query));

    if fullA2LName == query
        tf = true;
        return;
    end

    parts = split(fullA2LName, '.');
    lastPart = parts(end);

    tf = strcmpi(lastPart, query) || endsWith(fullA2LName, "." + query, 'IgnoreCase', true);
end

function s = extractFirst(txt, pattern)
    tok = regexp(txt, pattern, 'tokens', 'once');
    if isempty(tok)
        s = "";
    else
        s = string(strtrim(tok{1}));
    end
end

function entry = makeEntry(query, a2lName, addrHex, typ, kind)
    entry.QueryName = string(query);
    entry.A2LName = string(a2lName);
    entry.AddressHex = string(addrHex);
    entry.Type = string(typ);
    entry.Kind = string(kind);
    entry.PyName = "ADDR_" + sanitizePythonName(query);
end

function s = sanitizePythonName(name)
    s = upper(string(name));
    s = regexprep(s, '[^A-Z0-9]+', '_');
    s = regexprep(s, '_+', '_');
    s = regexprep(s, '^_|_$', '');
end