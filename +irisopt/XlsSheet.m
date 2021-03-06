function def = XlsSheet( )
% XlsSheet  Default options for IRIS XlsSheet class.
%
% Backend IRIS function.
% No help provided.

% -IRIS Macroeconomic Modeling Toolbox.
% -Copyright (c) 2007-2017 IRIS Solutions Team.

%--------------------------------------------------------------------------

dates = irisopt.dates( );

def = struct( );

def.retrieveDbase = [
    dates.str2dat
    ];

end
