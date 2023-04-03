unit PGLMath;

interface

uses
  System.SysUtils, System.Variants, System.VarConv, System.VarUtils, Types, Classes, Math, PGLTypes;

  function ClampF(AValue: Single): Single; register;
  function ClampI(AValue: Single): Integer; register;
  function Rnd(Low: Single; High: Single): Single; overload; register; inline;
  function Rnd(High: Single = 1): Single; overload; register; inline;
  function PosOrNeg(): Integer; register; inline;
  procedure IncF(var X: Single; N: Single = 1); register; inline;
  procedure DecF(var X: Single; N: Single = 1); register; inline;
  procedure IncRange(var X: Integer; N: Integer; Low: Integer; High: Integer); overload; register; inline;
  procedure IncRange(var X: Single; N: Single; Low: Single; High: Single); overload; register; inline;
  function RoundF(X: Single): Integer; register; inline;
  function RoundUp(X: Single): Integer; register; inline;
  function Distance(X1,Y1,X2,Y2: Single): Single; register; inline;
  function Radians(ADegrees: Single): Single; register; inline;
  function Degrees(ARadians: Single): Single; register; inline;
  procedure ClampRadians(var ARadians: Single); register; inline;
  procedure ClampDegrees(var ADegrees: Single); register; inline;
  function Biggest(Values: TArray<Single>): Single; register; inline;
  function BiggestIndex(Values: TArray<Single>): Integer; register; inline;
  function Smallest(Values: TArray<Single>): Single; register; inline;
  function SmallestIndex(Values: TArray<Single>): Integer; register; inline;
  function InRange(AValue: Single; ALow,AHigh: Single): Boolean; register; inline;
  procedure ClampRange(var AValue: Integer; ALow,AHigh: Integer); overload; register; inline;
  procedure ClampRange(var AValue: Single; ALow,AHigh: Single); overload; register; inline;
  function ZeroBelow(var AVar: Single; ALowLimit: Single): Boolean; register; inline;
  function RotateTo(ACurrentAngle, ATargetAngle: Single): Integer; register; inline;
  procedure DeleteIndex(AArray: TArray<Variant>; AIndex: Cardinal); register;
  procedure AssignConvert(var AOrgValue: Byte; const AAssignValue: Variant); overload; register;
  procedure AssignConvert(var AOrgValue: Integer; const AAssignValue: Variant); overload; register;
  procedure AssignConvert(var AOrgValue: Cardinal; const AAssignValue: Variant); overload; register;
  procedure AssignConvert(var AOrgValue: Single; const AAssignValue: Variant); overload; register;
  procedure AssignConvert(var AOrgValue: Double; const AAssignValue: Variant); overload; register;
  procedure AssignConvert(var AOrgValue: Int64; const AAssignValue: Variant); overload; register;
  procedure AssignConvert(var AOrgValue: UInt64; const AAssignValue: Variant); overload; register;
  procedure AssignConvert(var AOrgValue: Char; const AAssignValue: Variant); overload; register;
  procedure AssignConvert(var AOrgValue: AnsiChar; const AAssignValue: Variant); overload; register;
  procedure AssignConvert(var AOrgValue: String; const AAssignValue: Variant); overload; register;
  procedure AssignConvert(var AOrgValue: AnsiString; const AAssignValue: Variant); overload; register;
  procedure AssignConvert(var AOrgValue: Boolean; const AAssignValue: Variant); overload; register;
  function Point(X,Y: Single): TPoint; overload; register; inline;
  function AngularDiameter(AObjectSize, ADistToObject: Single): Single; register; inline;

implementation

function ClampF(AValue: Single): Single;
// clamp single to between 0 and 1 inclusive
  begin
    if AValue < 0 then Result := 0
    else if AValue > 1 then Result := 1
    else Result := AValue;
  end;

function ClampI(AValue: Single): Integer;
// clamp Integer to between 0 and 255 inclusive
  begin
    if AValue < 0 then Result := 0
    else if AValue > 255 then Result := 255
    else Result := trunc(AValue);
  end;


function Rnd(Low: Single; High: Single): Single;
// return random float between low and high inclusive
  begin
    Result := Low + ((High - Low) * Random);
  end;

function Rnd(High: Single = 1): Single;
// return random float between 0 and high inclusive
  begin
    Result := (High * Random);
  end;

function PosOrNeg(): Integer;
  begin
    Result := Random(2);

    if Result = 0 then begin
      Result := -1;
    end;
  end;


procedure IncF(var X: Single; N: Single = 1);
  begin
    X := X + N;
  end;

procedure DecF(var X: Single; N: Single = 1);
  begin
    X := X - N;
  end;

procedure IncRange(var X: Integer; N: Integer; Low: Integer; High: Integer);
  begin
    X := X + N;

    if N > 0 then begin
      if X > High then X := Low + (X - High);
    end else begin
      if X < Low then X := High - (Low - X);
    end;
  end;

procedure IncRange(var X: Single; N: Single; Low: Single; High: Single);
  begin
    X := X + N;

    if N > 0 then begin
      if X > High then X := Low + (X - High);
    end else begin
      if X < Low then X := High - (Low - X);
    end;
  end;

function RoundF(X: Single): Integer;
var
Rem: Single;
  begin
    Rem := X - trunc(X);

    if Rem < 0.5 then begin
      Result := trunc(X);
    end else begin
      Result := trunc(X) + 1;
    end;
  end;

function RoundUp(X: Single): Integer;
var
Rem: Single;
  begin
    Rem := X - trunc(X);
    if Rem = 0 then begin
      Result := trunc(X);
    end else begin
      Result := trunc(X) + 1;
    end;
  end;

function Distance(X1,Y1,X2,Y2: Single): Single;
  begin
    Result := Sqrt( ((X1 - X2) * (X1 - X2)) + ((Y1 - Y2) * (Y1 - Y2)) );
  end;

function Radians(ADegrees: Single): Single;
  begin
    Result := ADegrees * (pi / 180);
  end;

function Degrees(ARadians: Single): Single;
  begin
    Result := ARadians * (180 / pi);
  end;

procedure ClampRadians(var ARadians: Single);
  begin
    if ARadians > Pi then begin
      IncF(ARadians, -(Pi * 2));
    end;
    if ARadians < -Pi then begin
      IncF(ARadians, (Pi * 2));
    end;
  end;

procedure ClampDegrees(var ADegrees: Single);
  begin
    if ADegrees > 360 then begin
      IncF(ADegrees, 360);
    end;
    if ADegrees < 0 then begin
      IncF(ADegrees, 360);
    end;
  end;


function Biggest(Values: TArray<Single>): Single;
var
I: Integer;
  begin
    Result := Values[0];
    for I := 1 to High(Values) do begin
      if Values[i] > Result then begin
        Result := Values[i];
      end;
    end;
  end;

function BiggestIndex(Values: TArray<Single>): Integer;
var
I: Integer;
B: Single;
  begin
    Result := 0;
    B := 0;
    for I := 1 to High(Values) do begin
      if Values[i] > B then begin
        B := Values[i];
        Result := I;
      end;
    end;
  end;

function Smallest(Values: TArray<Single>): Single;
var
I: Integer;
  begin
    Result := Values[0];
    for I := 1 to High(Values) do begin
      if Values[i] < Result then begin
        Result := Values[i];
      end;
    end;
  end;

function SmallestIndex(Values: TArray<Single>): Integer;
var
I: Integer;
B: Single;
  begin
    Result := 0;
    B := Values[0];
    for I := 1 to High(Values) do begin
      if Values[i] < B then begin
        B := Values[i];
        Result := I;
      end;
    end;
  end;

function InRange(AValue: Single; ALow,AHigh: Single): Boolean;
  begin
    result := False;
    if (AValue >= ALow) and (AValue <= AHigh) then begin
      Result := True;
    end;
  end;

procedure ClampRange(var AValue: Integer; ALow,AHigh: Integer);
  begin
    if AValue < ALow then AValue := ALow;
    if AValue > AHigh then AValue := AHigh;
  end;

procedure ClampRange(var AValue: Single; ALow,AHigh: Single);
  begin
    if AValue < ALow then AValue := ALow;
    if AValue > AHigh then AValue := AHigh;
  end;

function ZeroBelow(var AVar: Single; ALowLimit: Single): Boolean;
  begin
    Result := False;
    if AVar < ALowLimit then begin
      AVar := 0;
      Exit(True);
    end;
  end;

function RotateTo(ACurrentAngle, ATargetAngle: Single): Integer; register; inline;
var
a,b,c,d: Single;
  begin
    a := ATargetAngle - ACurrentAngle;
    b := ATargetAngle - ACurrentAngle + (Pi * 2);
    c := ATargetAngle - ACurrentAngle - (Pi * 2);

    if (abs(a) < abs(b)) and (abs(a) < abs(c)) then begin
      Result := sign(a);
    end else if (abs(b) < abs(a)) and (abs(b) < abs(c)) then begin
      Result := sign(b);
    end else begin
      Result := sign(c);
    end;

  end;

procedure DeleteIndex(AArray: TArray<Variant>; AIndex: Cardinal);
var
I: Integer;
  begin
    if AIndex > Cardinal(High(AArray)) then Exit;

    For I := AIndex to High(AArray) - 1 do begin
      AArray[i] := AArray[i + 1];
    end;

    SetLength(AArray, length(AArray) - 1);
  end;


procedure AssignConvert(var AOrgValue: Byte; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := 0;
    end;
  end;

procedure AssignConvert(var AOrgValue: Integer; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := 0;
    end;
  end;

procedure AssignConvert(var AOrgValue: Cardinal; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := 0;
    end;
  end;

procedure AssignConvert(var AOrgValue: Single; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := 0;
    end;
  end;

procedure AssignConvert(var AOrgValue: Double; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := 0;
    end;
  end;

procedure AssignConvert(var AOrgValue: Int64; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := 0;
    end;
  end;

procedure AssignConvert(var AOrgValue: UInt64; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := 0;
    end;
  end;

procedure AssignConvert(var AOrgValue: Char; const AAssignValue: Variant);
  begin
    try
      AOrgValue := VarConvert.ToString(AAssignValue).ToCharArray[0];
    except
      AorgValue := Char(0);
    end;
  end;

procedure AssignConvert(var AOrgValue: AnsiChar; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AnsiChar(VarConvert.ToString(AAssignValue).ToCharArray[0]);
    except
      AorgValue := AnsiChar(0);
    end;
  end;

procedure AssignConvert(var AOrgValue: String; const AAssignValue: Variant);
  begin
    try
      AOrgValue := String(AAssignValue);
    except
      AorgValue := '';
    end;
  end;

procedure AssignConvert(var AOrgValue: AnsiString; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AnsiString(AAssignValue);
    except
      AorgValue := '';
    end;
  end;

procedure AssignConvert(var AOrgValue: Boolean; const AAssignValue: Variant); overload; register;
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := False;
    end;
  end;

function Point(X,Y: Single): TPoint;
  begin
    Result.X := trunc(X);
    Result.Y := trunc(Y);
  end;

function AngularDiameter(AObjectSize, ADistToObject: Single): Single;
  begin
    Result := Degrees(2 * ArcTan(AObjectSize / (2 * ADistToObject)));
  end;

end.
