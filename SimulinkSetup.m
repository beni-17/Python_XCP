%% setup simulink model with its signals and parameters
mdl = 'Teensy_Model';
load_system(mdl);
mws = get_param(mdl, 'ModelWorkspace');

ts = 1e-3;
pwmFreq = 20e3;

%% Signals
MDCurrent = Simulink.Signal;
MDCurrent.Description = "MD_Current";
MDCurrent.DataType = "uint16";
MDCurrent.Complexity = "real";

actSpeed_Motor = Simulink.Signal;
actSpeed_Motor.Description = "actSpeed_Motor";
actSpeed_Motor.DataType = "single";
actSpeed_Motor.Complexity = "real";

actSpeed_Torq = Simulink.Signal;
actSpeed_Torq.Description = "actSpeed_Torq";
actSpeed_Torq.DataType = "single";
actSpeed_Torq.Complexity = "real";

Torq_Signal = Simulink.Signal;
Torq_Signal.Description = "Torq_Signal";
Torq_Signal.DataType = "uint16";
Torq_Signal.Complexity = "real";

actTemp_48 = Simulink.Signal;
actTemp_48.Description = "actTemp_48";
actTemp_48.DataType = "single";
actTemp_48.Complexity = "real";

actTemp_49 = Simulink.Signal;
actTemp_49.Description = "actTemp_49";
actTemp_49.DataType = "single";
actTemp_49.Complexity = "real";

% Assign to model workspace
assignin(mws, MDCurrent.Description,        MDCurrent);
assignin(mws, actSpeed_Motor.Description,   actSpeed_Motor);
assignin(mws, actSpeed_Torq.Description,    actSpeed_Torq);
assignin(mws, Torq_Signal.Description,      Torq_Signal);  
assignin(mws, actTemp_48.Description,       actTemp_48);
assignin(mws, actTemp_49.Description,       actTemp_49);

%% Parameters
% I2C_Adress = Simulink.Parameter;
% I2C_Adress.Description = "I2C_Adress";
% I2C_Adress.DataType = "uint8";
% I2C_Adress.Value = 0x48;
% 
% I2C_Register = Simulink.Parameter;
% I2C_Register.Description = "I2C_Register";
% I2C_Register.DataType = "uint8";
% I2C_Register.Value = 0x00; % 0x00 = temperaure register

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
% assignin(mws, I2C_Adress.Description,       I2C_Adress);
% assignin(mws, I2C_Register.Description,     I2C_Register);
assignin(mws, Status_LED.Description,       Status_LED);
assignin(mws, Torq_Out.Description,         Torq_Out);
assignin(mws, Speed_Out.Description,        Speed_Out);
assignin(mws, Motor_Enable.Description,     Motor_Enable);
assignin(mws, Motor_Stop.Description,       Motor_Stop);
assignin(mws, Footcontrol.Description,      Footcontrol);

%%
save_system(mdl); % save simulink model with updated workspace
varNamesStruct = mws.whos; % read variable names back from model workspace
entries = writeA2LAddresses({varNamesStruct.name, "bla"}, "Teensy_Model.a2l", "Teensy_ModelAddr.py");

%%
% function entries = writeA2LAddresses(names, a2lFilename, pythonFilename)
% writeA2LAddresses  Read selected symbols from an A2L and write Python ADDR_* constants.
%
% ex:
%   writeA2LAddresses(["CONST_AMPLITUDE","Counter"], "file.a2l", "config.py")
%
% Input:
%   names           string/cellstr of names to search, e.g. "CONST_AMPLITUDE", "Counter"
%   a2lFilename     path to .a2l file
%   pythonFilename  output .py file
%
% Output:
%   entries         struct array with fields: QueryName, A2LName, AddressHex, Type, Kind, PyName
function entries = writeA2LAddresses(names, a2lFilename, pythonFilename)

    if ischar(names)
        names = string({names});
    elseif iscell(names)
        names = string(names);
    else
        names = string(names);
    end

    txt = fileread(a2lFilename);

    charBlocks = extractA2LBlocks(txt, 'CHARACTERISTIC');
    measBlocks = extractA2LBlocks(txt, 'MEASUREMENT');

    entries = struct('QueryName', {}, 'A2LName', {}, 'AddressHex', {}, ...
                     'Type', {}, 'Kind', {}, 'PyName', {});

    for i = 1:numel(names)
        query = strtrim(names(i));
        found = false;

        for k = 1:numel(charBlocks)
            info = parseCharacteristicBlock(charBlocks{k});
            if isMatchName(info.Name, query)
                entries(end+1) = makeEntry(query, info.Name, info.AddressHex, info.Type, "CHARACTERISTIC"); %#ok<AGROW>
                found = true;
                break;
            end
        end
        if found, continue; end

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
        lhs = char(pad(entries(i).PyName, maxLen));
        fprintf(fid, '%s = %s  # %s (%s)\n', lhs, entries(i).AddressHex, entries(i).Type, entries(i).Kind);
    end

    fclose(fid);
end

function blocks = extractA2LBlocks(txt, blockName)
    lines = splitlines(string(txt));
    blocks = {};
    inside = false;
    buf = strings(0,1);

    beginPat = "/begin " + blockName;
    endPat   = "/end " + blockName;

    for i = 1:numel(lines)
        line = strtrim(lines(i));

        if ~inside
            if startsWith(line, beginPat)
                inside = true;
                buf = lines(i);
            end
        else
            buf(end+1,1) = lines(i); %#ok<AGROW>
            if startsWith(line, endPat)
                blocks{end+1} = strjoin(buf, newline); %#ok<AGROW>
                inside = false;
                buf = strings(0,1);
            end
        end
    end
end

function out = parseCharacteristicBlock(block)
    lines = splitlines(string(block));
    lines = strtrim(lines);

    out.Name = "";
    out.AddressHex = "";
    out.Type = "UNKNOWN";

    % Name: first useful line after /begin CHARACTERISTIC
    for i = 2:numel(lines)
        line = lines(i);
        if strlength(line) == 0
            continue
        end
        if startsWith(line, '/*')
            tokens = regexp(line, '\*/\s*(\S+)', 'tokens', 'once');
            if ~isempty(tokens)
                out.Name = string(tokens{1});
                break
            end
        else
            tokens = regexp(line, '^(\S+)', 'tokens', 'once');
            if ~isempty(tokens)
                out.Name = string(tokens{1});
                break
            end
        end
    end

    % ECU Address
    for i = 1:numel(lines)
        line = lines(i);
        tok = regexp(line, '0x[0-9A-Fa-f]+', 'match', 'once');
        if contains(line, 'ECU Address') && ~isempty(tok)
            out.AddressHex = upper(string(tok));
            break
        end
    end

    % Record layout -> type
    for i = 1:numel(lines)
        line = lines(i);
        if contains(line, 'Record Layout')
            tok = regexp(line, '\*/\s*(\S+)', 'tokens', 'once');
            if ~isempty(tok)
                out.Type = erase(string(tok{1}), "Record_");
            end
            break
        end
    end
end

function out = parseMeasurementBlock(block)
    lines = splitlines(string(block));
    lines = strtrim(lines);

    out.Name = "";
    out.AddressHex = "";
    out.Type = "UNKNOWN";

    % Name: first useful line after /begin MEASUREMENT
    for i = 2:numel(lines)
        line = lines(i);
        if strlength(line) == 0
            continue
        end
        if startsWith(line, '/*')
            tokens = regexp(line, '\*/\s*(\S+)', 'tokens', 'once');
            if ~isempty(tokens)
                out.Name = string(tokens{1});
                break
            end
        else
            tokens = regexp(line, '^(\S+)', 'tokens', 'once');
            if ~isempty(tokens)
                out.Name = string(tokens{1});
                break
            end
        end
    end

    % Data type
    for i = 1:numel(lines)
        line = lines(i);
        if contains(line, 'Data type')
            tok = regexp(line, '\*/\s*(\S+)', 'tokens', 'once');
            if ~isempty(tok)
                out.Type = string(tok{1});
            end
            break
        end
    end

    % ECU_ADDRESS line
    for i = 1:numel(lines)
        line = lines(i);
        tok = regexp(line, 'ECU_ADDRESS\s+(0x[0-9A-Fa-f]+)', 'tokens', 'once');
        if ~isempty(tok)
            out.AddressHex = upper(string(tok{1}));
            break
        end
    end
end

function tf = isMatchName(fullA2LName, query)
    fullA2LName = string(strtrim(fullA2LName));
    query = string(strtrim(query));

    parts = split(fullA2LName, '.');
    lastPart = parts(end);

    tf = strcmpi(fullA2LName, query) || strcmpi(lastPart, query);
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