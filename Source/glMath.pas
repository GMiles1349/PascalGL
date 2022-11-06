unit glMath;

interface

Uses
  Math,Classes,WinAPI.Windows;

  Type FloatHelper = Record Helper for Float32
    Function ToInteger(): Int32; Register; Inline;
  End;

  // General
  Function RandomFloat(Low,High: Float32): Float32; Register; Inline;
  Function RandomFloat64(Low,High: Float64): Float64; Register; Inline;
  Function Rnd(Var Value: Float32): Int32; Register; Inline;

  // Angles and Distance
  Function Distance(X1,Y1,X2,Y2: Float32): Float32; Register; Inline;
  Function Angle(FromX,FromY,ToX,ToY: Float32): Float32; Register; Inline;
  Function Degree(FromX,FromY,ToX,ToY: Float32): Float32; Register; Inline;
  Function AngleToRad(Angle: Float32): Float32; Register; Inline;
  Function RadToAngle(Radians: Float32): Float32; Register; Inline;
  Function FixAngle(Var Angle: Float32): Float32; Register; Inline;
  Function FixRad(Var Radians: Float32): Float32; Register; Inline;
  Function PointFromOrigin(OX,OY,Dist,Rad: Float32): TPointFloat; Register; Inline;

Const
  PI2: Float32 = (Pi * 2);
  HalfPI: Float32 = (Pi / 2);
  QuarterPI: Float32 = (Pi / 4);

implementation

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
                            {* Types *}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Function FloatHelper.ToInteger: Integer;
  Begin
    Result := Trunc(Self);
  End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
                            {* Functions *}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


Function RandomFloat(Low,High: Float32): Float32;
  Begin
    Result := Low + ((High-Low)*Random);
  End;

Function RandomFloat64(Low,High: Float64): Float64;
  Begin
    Result := Low + ((High-Low)*Random);
  End;

Function Rnd(Var Value: Float32): Int32;
Var
Rem: Float32;
  Begin
    Rem := Frac(Value);
    If Rem < 0.5 Then Begin
      Value := Trunc(Value);
    End Else Begin
      Value := Trunc(Value) + 1;
    End;
    Result := Value.ToInteger;
  End;

Function Distance(X1,Y1,X2,Y2: Float32): Float32;
  Begin
    Result := Sqrt( IntPower(X2 - X1,2) + IntPower(Y2 - Y1,2) );
  End;

Function Angle(FromX,FromY,ToX,ToY: Float32): Float32;
  Begin
    Result := ArcTan2(ToY - FromY, ToX - FromX);
  End;

Function Degree(FromX,FromY,ToX,ToY: Float32): Float32;
  Begin
    Result := RadToAngle(Angle(FromX,FromY,ToX,ToY));
  End;

Function AngleToRad(Angle: Float32): Float32;
  Begin
    Result := Angle * (PI / 180);
  End;

Function RadToAngle(Radians: Float32): Float32;
  Begin
    Result := Radians * (180 / Pi);
  End;

Function FixAngle(Var Angle: Float32): Float32;
  Begin

    If (Angle >= 0) and (Angle >= 360) Then Begin
      Result := Angle;
      Exit;
    End;

    If Angle < 0 Then Begin
      While Angle < 0 Do Begin
        Angle := Angle + 360;
      End;
      Result := Angle;
      Exit;
    End Else Begin
      While Angle > 360 Do Begin
        Angle := Angle - 360;
      End;
      Result := Angle;
      Exit;
    End;

  End;

Function FixRad(Var Radians: Float32): Float32;
  Begin

    If (Radians >= 0) And (Radians <= PI2) Then Begin
      Result := Radians;
      Exit;
    End;

    If Radians < 0 Then Begin
      While Radians < 0 Do Begin
        Radians := Radians + PI2;
      End;
      Result := Radians;
      Exit;
    End Else Begin
      While Radians > PI2 Do Begin
        Radians := Radians - PI2;
      End;
      Result := Radians;
      Exit;
    End;

  End;


Function PointFromOrigin(OX,OY,Dist,Rad: Float32): TPointFloat; Register; Inline;
  Begin
    Result.X := OX + (Dist * Cos(Rad));
    Result.Y := OY + (Dist * Sin(Rad));
  End;


end.
