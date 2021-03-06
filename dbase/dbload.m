function d = dbload(varargin)
% dbload  Create database by loading CSV file.
%
% Syntax
% =======
%
%     d = dbload(fileName, ...)
%     d = dbload(d, fileName, ...)
%
%
% Input arguments
% ================
%
% * `fileName` [ char | cellstr ] - Name of the Input CSV data file or a cell
% array of CSV file names that will be combined.
%
% * `d` [ struct ] - An existing database (struct) to which the new entries
% from the input CSV data file entries will be added.
%
%
% Output arguments
% =================
%
% * `d` [ struct ] - Database created from the input CSV file(s).
%
%
% Options
% ========
%
% * `'Case='` [ `'lower'` | `'upper'` | *empty* ] - Change case of variable
% names.
%
% * `'CommentRow='` [ char | cellstr | *`{'comment', 'comments'}`* ] - Label
% at the start of row that will be used to create Series object comments.
%
% * `'DateFormat='` [ char | *`'YYYYFP'`* ] - Format of dates in first
% column.
%
% * `'Delimiter='` [ char | *`', '`* ] - Delimiter separating the individual
% values (cells) in the CSV file; if different from a comma, all occurences
% of the delimiter will replaced with commas -- note that this will also
% affect text in comments.
%
% * `'FirstDateOnly='` [ `true` | *`false`* ] - Read and parse only the
% first date string, and fill in the remaining dates assuming a range of
% consecutive dates.
%
% * `'Freq='` [ `0` | `1` | `2` | `4` | `6` | `12` | `365` | `'daily'` |
% *empty* ] - Advise frequency of dates; if empty, frequency will be
% automatically recognised.
%
% * `'FreqLetters='` [ char | *`'YHQBM'`* ] - Letters representing frequency
% of dates in date column.
%
% * `'InputFormat='` [ *`'auto'`* | `'csv'` | `'xls'` ] - Format of input
% data file; `'auto'` means the format will be determined by the file
% extension.
%
% * `'NameRow='` [ char | numeric | *`{'', 'Variables'}`* ] - String, or
% cell array of possible strings, that is found at the beginning (in the
% first cell) of the row with variable names, or the line number at which
% the row with variable names appears (first row is numbered 1).
%
% * `'NameFunc='` [ cell | function_handle | *empty* ] - Function used to
% change or transform the variable names. If a cell array of function
% handles, each function will be applied in the given order.
%
% * `'Nan='` [ char | *`NaN`* ] - String representing missing observations
% (case insensitive).
%
% * `'PreProcess='` [ function_handle | cell | *empty* ] - Apply this
% function, or cell array of functions, to the raw text file before
% parsing the data.
%
% * `'Select='` [ char | cellstr | *empty* ] - Only database entries
% included on this list will be read in and returned in the output database
% `D`; entries not on this list will be discarded.
%
% * `'SkipRows='` [ char | cellstr | numeric | *empty* ] - Skip rows whose
% first cell matches the string or strings (regular expressions);
% or, skip a vector of row numbers.
%
% * `'UserData='` [ char | *`Inf`* ] - Field name under which the database
% userdata loaded from the CSV file (if they exist) will be stored in the
% output database; `Inf` means the field name will be read from the CSV
% file (and will be thus identical to the originally saved database).
%
% * `'UserDataField='` [ char | *`'.'`* ] - A leading character denoting
% userdata fields for individual time series; if empty, no userdata fields
% will be read in and created.
%
% * `'UserDataFieldList='` [ cellstr | numeric | empty ] - List of row
% headers, or vector of row numbers, that will be included as user data in
% each time series.
%
%
% Description
% ============
%
% Use the `'freq='` option whenever there is ambiguity in intepreting
% the date strings, and IRIS is not able to determine the frequency
% correctly (see Example).
%
% Structure of CSV database files
% --------------------------------
%
% The minimalist structure of a CSV database file has a leading row with
% variables names, a leading column with dates in the basic IRIS format, 
% and individual columns with numeric data:
%
%     +---------+---------+---------+--
%     |         |       Y |       P |
%     +---------+---------+---------+--
%     |  2010Q1 |       1 |      10 |
%     +---------+---------+---------+--
%     |  2010Q2 |       2 |      20 |
%     +---------+---------+---------+--
%     |         |         |         |
%
% You can add a comment row (must be placed before the data part, and start
% with a label 'Comment' in the first cell) that will also be read in and
% assigned as comments to the individual Series objects created in the
% output database.
%
%     +---------+---------+---------+--
%     |         |       Y |       P |
%     +---------+---------+---------+--
%     | Comment |  Output |  Prices |
%     +---------+---------+---------+--
%     |  2010Q1 |       1 |      10 |
%     +---------+---------+---------+--
%     |  2010Q2 |       2 |      20 |
%     +---------+---------+---------+--
%     |         |         |         |
%
% You can use a different label in the first cell to denote a comment row;
% in that case you need to set the option `'commentRow='` accordingly.
%
% All CSV rows whose names start with a character specified in the option
% `'userdataField='` (a dot by default) will be added to output Series
% objects as fields of their userdata.
%
%     +---------+---------+---------+--
%     |         |       Y |       P |
%     +---------+---------+---------+--
%     | Comment |  Output |  Prices |
%     +---------+---------+---------+--
%     | .Source |   Stat  |  IMFIFS |
%     +---------+---------+---------+--
%     | .Update | 17Feb11 | 01Feb11 |
%     +---------+---------+---------+--
%     | .Units  | Bil USD |  2010=1 |
%     +---------+---------+---------+--
%     |  2010Q1 |       1 |      10 |
%     +---------+---------+---------+--
%     |  2010Q2 |       2 |      20 |
%     +---------+---------+---------+--
%     |         |         |         |
%
%
% Example
% ========
%
% Typical example of using the `'freq='` option is a quarterly database
% with dates represented by the corresponding months, such as a sequence
% 2000-01-01, 2000-04-01, 2000-07-01, 2000-10-01, etc. In this case, you
% can use the following options:
%
%     d = dbload('filename.csv', 'dateFormat', 'YYYY-MM-01', 'freq', 4);
%

% -IRIS Macroeconomic Modeling Toolbox.
% -Copyright (c) 2007-2017 IRIS Solutions Team.

if isstruct(varargin{1})
    d = varargin{1};
    varargin(1) = [ ];
else
    d = struct( );
end

FName = varargin{1};
varargin(1) = [ ];

P = inputParser( );
P.addRequired('d', @isstruct);
P.addRequired('fname', @(x) ischar(x) || iscellstr(x));
P.parse(d, FName);

% Loop over all input databases subcontracting `dbload` and merging the
% resulting databases in one.
if iscellstr(FName)
    nFName = length(FName);
    for i = 1 : nFName
        d = dbload(d, FName{i}, varargin{:});
        return
    end
end

opt = passvalopt('dbase.dbload', varargin{1:end});
opt = datdefaults(opt);

% Pre-process options.
processOptions( );

%--------------------------------------------------------------------------

% Read the CSV file, and apply user-supplied function(s) to pre-process the
% raw text file.
file = '';
readFile( );

% Replace non-comma delimiter with comma; applies only to CSV files.
if ~strcmp(opt.delimiter, ',')
    file = strrep(file, sprintf(opt.delimiter), ',');
end

% Read headers
%--------------
nameRow = { };
classRow = { };
cmtRow = { };
start = 1;
dbUserdata = '';
dbUserdataFieldName = '';
isUserData = false;
seriesUserdata = struct( );
readHeaders( );

% Trim the headers.
if start>1
    file = file(start:end);
end

classRow = strtrim(classRow);
cmtRow = strtrim(cmtRow);
if length(classRow)<length(nameRow)
    classRow(length(classRow)+1:length(nameRow)) = {''};
end
if length(cmtRow)<length(nameRow)
    cmtRow(length(cmtRow)+1:length(nameRow)) = {''};
end

% Apply user selection, white out all names that user did not select.
if ~isequal(opt.select, @all)
    if ischar(opt.select)
        opt.select = regexp(opt.select, '\w+', 'match');
    end
    for i = 1 : length(nameRow)
        if ~any(strcmp(nameRow{i}, opt.select))
            nameRow{i} = ''; %#ok<AGROW>
        end
    end
end

% Read numeric data from CSV string
%-----------------------------------
dates = [ ];
data = [ ];
ixMissing = [ ];
ixNanDate = [ ];
dateCol = { };
if ~isempty(file)
    readNumericData( );
end

% Parse dates
%-------------
dates = nan(1, length(dateCol));
parseDates( );

if ~isempty(dates)
    maxDate = max(dates);
    minDate = min(dates);
    nPer = 1 + round(maxDate - minDate);
    dateInx = 1 + round(dates - minDate);
else
    nPer = 0;
    dateInx = [ ];
    minDate = NaN;
end

% Change variable names.
% * Apply user function to variables names.
% * Convert variable name case.
chgNames( );

% Make sure the database entry names are all valid and unique Matlab names.
chkNames( );

% Populated the userdata field; this is NOT Series userdata, but a
% separate entry in the output database.
if ~isempty(opt.userdata) && isUserData
    createUserdataField( );
end

% Create database
%------------------
% Populate the output database with Series and numeric data.
populateDatabase( );

return




    function readFile( )
        % Read CSV file to char.
        file = file2char(FName);
        file = textfun.converteols(file);
        if isempty(opt.preprocess)
            return
        end
        % Preprocess raw text using user-supplied functions.
        func = opt.preprocess;
        if ~iscell(func)
            func = {func};
        end
        for ii = 1 : length(func)
            file = func{ii}(file);
        end
    end




    function processOptions( )
        % Headers for rows to be skipped.
        if ischar(opt.skiprows)
            opt.skiprows = {opt.skiprows};
        end
        if ~isempty(opt.skiprows) && ~isnumeric(opt.skiprows)
            for ii = 1 : length(opt.skiprows)
                if isempty(opt.skiprows{ii})
                    continue
                end
                if opt.skiprows{ii}(1)~='^'
                    opt.skiprows{ii} = ['^', opt.skiprows{ii}];
                end
                if opt.skiprows{ii}(end)~='$'
                    opt.skiprows{ii} = [opt.skiprows{ii}, '$'];
                end
            end
        end
        % Headers for comment rows.
        if ischar(opt.commentrow)
            opt.commentrow = {opt.commentrow};
        end
    end 




    function readHeaders( )
        strFindFunc = @(x, y) ~isempty(strfind(lower(x), y));
        isDate = false;
        isNameRowDone = false;
        ident = '';
        rowCount = 0;
        while ~isempty(file) && ~isDate
            rowCount = rowCount + 1;
            eol = regexp(file, '\n', 'start', 'once');
            if isempty(eol)
                line = file;
            else
                line = file(start:eol-1);
            end
            if isnumericscalar(opt.namerow) && rowCount<opt.namerow
                moveToNextEol( );
                continue
            end
            
            % Read individual comma-separated cells on the current line. Capture the
            % entire match (including separating commas and double quotes), not only
            % tokens -- this is a workaround for a bug in Octave.
            % @@@@@ MOSW
            tkn = regexp(line, ...
                '[^",]*,|[^",]*$|"[^"]*",|"[^"]*"$', 'match');
            % Remove separating commas from the end of cells.
            tkn = regexprep(tkn, ',$', '', 'once');
            % Remove double quotes from beginning and end of each cell.
            tkn = regexprep(tkn, '^"', '', 'once');
            tkn = regexprep(tkn, '"$', '', 'once');
            
            if isempty(tkn) || all(cellfun(@isempty, tkn))
                ident = '%';
            else
                ident = strrep(tkn{1}, '->', '');
                ident = strtrim(ident);
            end
            
            if isnumeric(opt.skiprows) && any(rowCount==opt.skiprows)
                moveToNextEol( );
                continue
            end
            
            if isThisNameRow( )
                nameRow = tkn(2:end);
                isNameRowDone = true;
                moveToNextEol( );
                continue
            end
            

            isDate = true;
            
            % Userdata fields
            %-----------------
            % Some of the userdata fields can be reused as comments, hence do this
            % before anything else.
            if strncmp(ident, opt.userdatafield, 1) ...
                    ...
                    || ( ...
                    iscellstr(opt.userdatafieldlist) ...
                    && ~isempty(opt.userdatafieldlist) ...
                    && any(strcmpi(ident, opt.userdatafieldlist)) ...
                    ) ...
                    ...
                    || ( ...
                    isnumeric(opt.userdatafieldlist) ...
                    && ~isempty(opt.userdatafieldlist) ...
                    && any(rowCount==opt.userdatafieldlist(:).') ...
                    )
                fieldName = regexprep(ident, '\W', '');
                fieldName = matlab.lang.makeUniqueStrings(fieldName);
                try %#ok<TRYNC>
                    seriesUserdata.(fieldName) = tkn(2:end);
                end
                isDate = false;
            end

            if strncmp(ident, '%', 1) || isempty(ident)
                isDate = false;
            elseif strFindFunc(ident, 'userdata')
                dbUserdataFieldName = getUserdataFieldName(tkn{1});
                dbUserdata = tkn{2};
                isUserData = true;
                isDate = false;
            elseif strFindFunc(ident, 'class[size]')
                classRow = tkn(2:end);
                isDate = false;
            elseif any(strcmpi(ident, opt.commentrow))
                cmtRow = tkn(2:end);
                isDate = false;
            elseif ~isempty(strfind(lower(ident), 'units'))
                isDate = false;
            elseif ~isnumeric(opt.skiprows) ...
                    && any(~cellfun(@isempty, regexp(ident, opt.skiprows)))
                isDate = false;
            end
            
            if ~isDate
                moveToNextEol( );
            end 
        end
        
        return

        
        

        function moveToNextEol( )
            if ~isempty(eol)
                file(eol) = ' ';
                start = eol + 1;
            else
                file = '';
            end
        end

        
        
        
        function Flag = isThisNameRow( )
            if isNameRowDone
                Flag = false;
                return
            end
            if isnumeric(opt.namerow)
                Flag = rowCount==opt.namerow;
            else
                Flag = any(strcmpi(ident, opt.namerow));
            end
        end
    end 




    function readNumericData( )
        % Read date column (first column).
        dateCol = regexp(file, '^[^,\n]*', 'match', 'lineanchors');
        dateCol = strtrim(dateCol);
        
        % Remove leading or trailing single or double quotes.
        % Some programs save any text cells with single or double quotes.
        dateCol = regexprep(dateCol, '^["'']', '');
        dateCol = regexprep(dateCol, '["'']$', '');
        
        % Replace user-supplied NaN strings with 'NaN'. The user-supplied NaN
        % strings must not contain commas.
        file = lower(file);
        file = strrep(file, ' ', '');
        opt.nan = strtrim(lower(opt.nan));
        
        % When replacing user-defined NaNs, there can be in theory conflict with
        % date strings. We do not resolve this conflict because it is not very
        % likely.
        if strcmp(opt.nan, 'nan')
            % Remove quotes from quoted NaNs.
            file = strrep(file, '"nan"', 'nan');
        else
            % We cannot have multiple NaN strings because of the way `strrep` handles
            % repeated patterns and because `strrep` is not able to detect word
            % boundaries. Handle quoted NaNs first.
            file = strrep(file, ['"', opt.nan, '"'], 'NaN');
			if strcmp('.', opt.nan)
				file = regexprep(file, ...
                    ['(?<=,)(\', opt.nan, ')(?=(,|\n|\r))'], ...
                    'NaN');
			else
				file = strrep(file, opt.nan, 'NaN');
			end
        end
        
        % Replace empty character cells with numeric NaNs.
        file = strrep(file, '""', 'NaN');
        % Replace date highlights with numeric NaNs.
        file = strrep(file, '"***"', 'NaN');
        % Define white spaces.
        whiteSpace = sprintf(' \b\r\t');
        
        % Read numeric data; empty cells will be treated either as `NaN` or
        % `NaN+NaNi` depending on the presence or absence of complex
        % numbers in the rest of that particular row.
        data = textscan(file, '', -1, ...
            'Delimiter', ',', 'WhiteSpace', whiteSpace, ...
            'HeaderLines', 0, 'HeaderColumns', 1, 'EmptyValue', -Inf, ...
            'CommentStyle', 'Matlab', 'CollectOutput', true);
        if isempty(data)
            throw( ...
                exception.Base('Dbase:InvalidLoadFormat', 'error'), ...
                FName ...
                ); %#ok<GTARG>
        end
        data = data{1};
        ixMissing = false(size(data));
        % The value `-Inf` indicates a possible missing value (but may be a
        % genuine `-Inf`, too). Re-read the table again, with missing
        % values represented by `NaN` this time to pin down missing values.
        isMaybeMissing = real(data)==-Inf;
        if any(isMaybeMissing(:))
            data1 = textscan(file, '', -1, ...
                'Delimiter', ',', 'WhiteSpace', whiteSpace, ...
                'HeaderLines', 0, 'HeaderColumns', 1, 'EmptyValue', NaN, ...
                'CommentStyle', 'Matlab', 'CollectOutput', true);
            data1 = data1{1};
            isMaybeMissing1 = isnan(real(data1));
            ixMissing(isMaybeMissing & isMaybeMissing1) = true;
        end
    end 




    function parseDates( )
        dateCol = dateCol(1:min(end, size(data, 1)));
        if ~isempty(dateCol)
            if opt.firstdateonly
                dateCol(2:end) = {''};
            end
            % Rows with empty dates.
            emptyDate = cellfun(@isempty, dateCol);
        end
        % Convert date strings.
        if ~isempty(dateCol) && ~all(emptyDate)
            dates(~emptyDate) = str2dat(dateCol(~emptyDate), ...
                'DateFormat=', opt.dateformat, ...
                'Freq=', opt.freq, ...
                'FreqLetters=', opt.freqletters);
            if opt.firstdateonly
                dates(2:end) = dates(1) + (1 : length(dates)-1);
            end
        end
        % Exclude NaN dates (that includes also empty dates), but keep all data
        % rows. This is because of non-Series data.
        ixNanDate = isnan(dates);
        dates(ixNanDate) = [ ];
        
        % Check for mixed frequencies.
        if ~isempty(dates)
            x = datfreq(dates);
            if any(x(1)~=x)
                throw( ...
                    exception.Base('Dbase:LoadMixedFrequency', 'error'), ...
                    FName ...
                    ); %#ok<GTARG>
            end
        end
    end 




    function populateDatabase( )
        TEMPLATE_SERIES = Series( );
        count = 0;
        nName = length(nameRow);
        seriesUserdataList = fieldnames(seriesUserdata);
        nSeriesUserdata = length(seriesUserdataList);
        while count<nName
            name = nameRow{count+1};
            if nSeriesUserdata>0
                thisUserData = createSeriesUserdata( );
            end
            if isempty(name)
                % Skip columns with empty names.
                count = count + 1;
                continue
            end
            tokens = regexp(classRow{count+1}, ...
                '^(\w+)((\[.*\])?)', 'tokens', 'once');
            if isempty(tokens)
                cls = '';
                tmpSize = [ ];
            else
                cls = tokens{1};
                tmpSize = getSize(tokens{2});
            end
            if isempty(cls)
                cls = 'Series';
            end
            if strcmpi(cls, 'Series') || strcmpi(cls, 'tseries')
                % Series data.
                if isempty(tmpSize)
                    tmpSize = [Inf, 1];
                end
                nCol = prod(tmpSize(2:end));
                if ~isempty(data)
                    if isreal(data(~ixNanDate, count+(1:nCol)))
                        unit = 1;
                    else
                        unit = 1 + 1i;
                    end
                    iData = nan(nPer, nCol)*unit;
                    iMiss = false(nPer, nCol);
                    iData(dateInx, :) = data(~ixNanDate, count+(1:nCol));
                    iMiss(dateInx, :) = ixMissing(~ixNanDate, count+(1:nCol));
                    iData(iMiss) = NaN*unit;
                    iData = reshape(iData, [nPer, tmpSize(2:end)]);
                    cmt = cmtRow(count+(1:nCol));
                    cmt = reshape(cmt, [1, tmpSize(2:end)]);
                    d.(name) = replace(TEMPLATE_SERIES, iData, minDate, cmt);
                else
                    % Create an empty Series object with proper 2nd and higher
                    % dimensions.
                    iData = zeros([0, tmpSize(2:end)]);
                    d.(name) = replace(TEMPLATE_SERIES, iData, NaN, '');
                end
                if nSeriesUserdata>0
                    d.(name) = userdata(d.(name), thisUserData);
                end
                % Convert the series to requested frequency if it isn't it yet.
%                 if ~isempty(opt.convert) ...
%                         && ~isnan(D.(name).start) ...
%                         && datfreq(D.(name).start)~=opt.convert{1}
%                     D.(name) = convert(D.(name), opt.convert{:});
%                 end
            elseif ~isempty(tmpSize)
                % Numeric data.
                nCol = prod(tmpSize(2:end));
                iData = reshape(data(1:tmpSize(1), count+(1:nCol)), tmpSize);
                iMiss = reshape(ixMissing(1:tmpSize(1), count+(1:nCol)), tmpSize);
                iData(iMiss) = NaN;
                % Convert to the right numeric class.
                if true % ##### MOSW
                    fnClass = str2func(cls);
                else
                    fnClass = mosw.str2func(cls); %#ok<UNRCH>
                end
                d.(name) = fnClass(iData);
            end
            count = count + nCol;
        end
        
        return
        
        
        
        
        function userData = createSeriesUserdata( )
            userData = struct( );
            for ii = 1 : nSeriesUserdata
                try
                    userData.(seriesUserdataList{ii}) = ...
                        seriesUserdata.(seriesUserdataList{ii}){count+1};
                catch %#ok<CTCH>
                    userData.(seriesUserdataList{ii}) = '';
                end
            end
        end
    end




    function chgNames( )
        % Apply user function(s) to each name.
        if ~isempty(opt.namefunc)
            func = opt.namefunc;
            if ~iscell(func)
                func = {func};
            end
            for iname = 1 : length(nameRow)
                for ifunc = 1 : length(func)
                    nameRow{iname} = func{ifunc}(nameRow{iname});
                end
            end
        end
        if ~iscellstr(nameRow)
            throw( ...
                exception.Base('Dbase:InvalidOptionNameFunc', 'error') ...
                );
        end
        % Switch lower/upper case.
        switch lower(opt.case)
            case 'lower'
                nameRow = lower(nameRow);
            case 'upper'
                nameRow = upper(nameRow);
        end
    end 




    function chkNames( )
        ixEmpty = cellfun(@isempty, nameRow);
        ixValid = cellfun(@isvarname, nameRow);
        % Index of non-empty, invalid names that need to be regenerated.
        ixGen = ~ixEmpty & ~ixValid;
        % Index of valid names that will be protected.
        ixProtect = ~ixEmpty & ixValid;
        % `genvarname` now guarantees uniqueness of names by appending `1`, `2`, 
        % etc. at the end of the string; did not use to be the case in older
        % versions of Matlab.
        nameRow(ixGen) = genvarname(nameRow(ixGen), nameRow(ixProtect)); %#ok<DEPGENAM>
    end 




    function createUserdataField( )
        if ischar(opt.userdata) || isempty(dbUserdataFieldName)
            dbUserdataFieldName = opt.userdata;
        end
        try
            d.(dbUserdataFieldName) = eval(dbUserdata);
        catch err
            throw( ...
                exception.Base('Dbase:ErrorLoadingUserData', 'error'), ...
                FName, err.message ...
                ); %#ok<GTARG>
        end
    end
end




function s = getSize(c)
% Read the size string 1-by-1-by-1 etc. as a vector.
% New style of saving size: [1-by-1-by-1].
% Old style of saving size: [1][1][1].
c = strrep(c(2:end-1), '][', '-by-');
s = sscanf(c, '%g-by-');
s = s(:).';
end 




function name = getUserdataFieldName(c)
name = regexp(c, '\[([^\]]+)\]', 'once', 'tokens');
if ~isempty(name)
    name = name{1};
else
    name = '';
end
end
