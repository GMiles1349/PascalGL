unit UnitSound;


{
TO-DO
- Impliment functionality for enabling/disabling dynamic sound at global and per-source levels
}


interface

uses
  OpenAl,
  Classes, SysUtils, Math, WinApi.windows;

  Const ALBUFFER = (0);
  Const ALSOURCE = (1);
  Const ALLISTERN = (2);

  Type pglSoundBuffer = Record

    Private
      pIsValid: Boolean;
      pBuffer: TALUint;
      pLength: TALFloat;
      pName: String;

    Public
      Property IsValid: Boolean Read pIsValid;
      Property Buffer: TALUint read pBuffer;
      Property Length: TALFloat read pLength;
      Property Name: String read pName;

      Procedure LoadDataFromFile(FileName: String; NameBuffer: String); Register; Inline;
  End;

  Type PpglSoundBuffer = ^pglSoundBuffer;


  Type pglSoundSource = Record

    Private
      Source: TALUInt;
      State: TALUInt;

      pHasBuffer: Boolean; // is the buffer assigned?
      pBuffer: pglSoundBuffer;

      pisDynamic: Boolean;
      pGain: Double;
      pPosX,pPosY: Double; // Current X and Y

      pHasPosPointers: Boolean; // Are position pointer values set?
      pXPointer,pYPointer: ^Double; // Pointers to values to update from dynamically

      pHasVariablePitch: Boolean;
      pPitchRange: Array [0..1] of Double;
      pBaseFrequency: TALFloat;
      pCurrentFrequency: TALFLoat;

      pDirection: Single;
      pRadius: Single;
      pConeAngle: Single;
      pConeOuterGain: Single;
      pLooping: Boolean;

      Procedure UpdateBufferPosition(); Register;

    Public
      Name: String;

      Class Operator Initialize(Out Dest: pglSoundSource); Register;

      // Properties
      Property HasBuffer: Boolean Read pHasBuffer;
      Property Buffer: pglSoundBuffer read pBuffer;
      Property isDynamic: Boolean Read pisDynamic;
      Property Gain: Double Read pGain;
      Property PosX: Double Read pPosX;
      Property PosY: Double Read pPosY;
      Property HasVariablePitch: Boolean Read pHasVariablePitch;
      Property Looping: Boolean Read pLooping;
      Property Direction: Single Read pDirection;
      Property Radius: Single Read pRadius;
      Property ConeAngle: Single Read pConeAngle;
      Property ConeOuterGain: Single Read pConeOuterGain;

      // Setters
      Procedure AssignBuffer(Var Buffer: pglSoundBuffer); Register; Inline;
      Procedure SetGain(Value: Double); Register; Inline;
      Procedure SetPosition(X,Y: Double); Register; Inline;
      Procedure SetXPosition(X: Double); Register; Inline;
      Procedure SetYPosition(Y: Double); Register; Inline;
      Procedure SetPositionPointers(pX,pY: Pointer); Register; Inline;
      Procedure SetVariablePitch(LowRange,HighRange: Double); Register; Inline;
      Procedure SetFixedPitch(Value: Double); Register; Inline;
      Procedure SetLooping(Value: Boolean = True); Register; Inline;
      Procedure SetDirection(Angle: Single); Register; Inline;
      Procedure SetRadius(Distance: Single); Register; Inline;
      Procedure SetCone(Angle,ConeOuterGain: Single); Register; Inline;
      Procedure SetConeAngle(Angle: Single); Register; Inline;
      Procedure SetConeOuterGain(Gain: Single); Register; Inline;
      Procedure SetDynamic(Enable: Boolean = True); Register; Inline;

      // Actions
      Procedure ReleasePositionPointers(); Register; Inline;
      Procedure UpdatePosition(); Register; Inline;
      Procedure Play(); Register; Inline;
      Procedure Stop(); Register; Inline;

    Private

      Procedure CheckHasBuffer(); Register; Inline;
  End;


  Type pglSoundSlot = Record

    Private
      SoundSource: ^pglSoundSource;
      Source: TALUint;

  End;


  Type SoundTemp = Class

    Public

    Name: String;
    SoundType: String;
    Length: TALFloat;
    Buffer: TALuint;
    SFreq: TALSizeI;

    Constructor Create();

  end; // SoundTemp

  Type pglListener = Class

    Private
      pDirection: Single;
      pX,pY: TALFloat;
      pVolume: TALFloat;

      listenerpos: array [0..2] of TALfloat;
      listenervel: array [0..2] of TALfloat;
      listenerdir: array [0..2] of TALfloat;

      Constructor Create();

    Public
      Property Direction: TALFloat read pDirection;
      Property X: TALfloat read pX;
      Property Y: TALFloat read pY;
      Property Volume: TALFloat read pVolume;

      Procedure SetPosition(X,Y: Single); Register;
      Procedure SetDirection(Angle: Single); Register;
      Procedure SetVolume(Value: Single); Register;

  end; // Listener Template

  Type SourceTemp = Class

    Public

    Name: String;
    source : TALuint;
    sourcepos: array [0..2] of TALfloat;
    sourcevel: array [0..2] of TALfloat;
    State: Paluint;
    Buffer: TALUint;
    SFreq: TALSizeI;

    Constructor Create();

  end; // Source Template





  Type QueueEntry = Record

    Used: Boolean;
    StartTime,EndTime: Double;
    NextSound: String;
    NextMusic: String;
  End;


  Type pglSoundInstance = Class

    Private
      pGlobalVolume: Double;
      pListener: pglListener;
      pDynamicSound: Boolean;

      BufferCount: Integer;
      Buffers: Array of pglSoundBuffer;

      SourceCount: Integer;
      Sources: Array of ^pglSoundSource;

      Sounds: Array [0..100] of pglSoundSlot;
      CurrentSound: TALUint;

      TempSource: pglSoundSource;

    Public

      // Properties
      Property GlobalVolume: Double Read pGlobalVolume;
      Property Listener: pglListener Read pListener;
      Property DyanmicSound: Boolean Read pDynamicSound;

      // Setters
      Constructor Create(); Register;
      Procedure SetGlobalVolume(Value: Double); Register; Inline;
      Procedure SetDynamicSound(Enable: Boolean = True); Register; Inline;
      Procedure PlayFromBuffer(Var Buffer: pglSoundBuffer); Overload; Register;
      Procedure PlayFromBuffer(Var Buffer: pglSoundBuffer; X,Y,Radius,Direction,Gain,Pitch,ConeAngle,ConeOuterGain: Single); Overload; Register;

    Private
      Procedure PlaySound(Var From: pglSoundSource); Register; Inline;
      Procedure StopSound(Var From: pglSoundSource); Register; Inline;

  End;

  Procedure StartOpenAL(); Register;
  Procedure AssignSound(InName, Path: String; InType: String = 'FX'); Register; InLine;
  Procedure UnloadSounds(); Register;
  Procedure AssignMusic(InName, Path: String); Register;
  Procedure PlayMusic(InName: String; NextMusic: String = ''; NextSound: String = ''); Register;
  Procedure StopMusic(); Register;
  Procedure PauseAllSounds(); Inline;
  Procedure ResumeAllSounds(); Inline;
  Procedure AlGetErrorState();
  Procedure ALClearErrors();
  Function AlReturnError(): String;
  Procedure PlayLoop(InName: String);
  Procedure LoopChangePitch(LoopName: String; Pitch: Double = 1); Register; Inline;
  Procedure StopLoop(InName: String);
  Procedure SetMusic(); Register; Inline;
  Procedure AddToSoundStop(InSource: TaluInt; InDuration: Double); REgister; Inline;
  Procedure CheckSoundStops(); REgister; Inline;

  Function SoundGetTime(): Double; Register; Inline;

  Function Rnd(Val1,Val2: Double): Double; Register; Inline;

  Procedure pglBufferi(Target: TALUint; Enum: TALEnum; Value: TALUint); Register; Inline;
  Procedure pglBuffer3i(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALuint); Register; Inline;
  Procedure pglBufferiv(Target: TALUint; Enum: TALEnum; Value: PALint); Register; Inline;
  Procedure pglBufferf(Target: TALUint; Enum: TALEnum; Value: TALfloat); Register; Inline;
  Procedure pglBuffer3f(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALfloat); Register; Inline;
  Procedure pglBufferfv(Target: TALUint; Enum: TALEnum; Value: PALFloat); Register; Inline;

  Procedure pglSourcei(Target: TALUint; Enum: TALEnum; Value: TALUint); Register; Inline;
  Procedure pglSource3i(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALuint); Register; Inline;
  Procedure pglSourceiv(Target: TALUint; Enum: TALEnum; Value: PALint); Register; Inline;
  Procedure pglSourcef(Target: TALUint; Enum: TALEnum; Value: TALfloat); Register; Inline;
  Procedure pglSource3f(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALfloat); Register; Inline;
  Procedure pglSourcefv(Target: TALUint; Enum: TALEnum; Value: PALFloat); Register; Inline;

var
OpenALRunning: Boolean;
argv: array of PalByte;

SoundTimeFreq: Int64;
SoundTime: Double;

ErrorState: TALuint;

format: TALEnum;
size: TALSizei;
freq: TALSizei;
loop: TALInt;
data: TALVoid;
buffer : TALuint;

SoundPath: String;
TotalSounds: NativeInt;
TotalMusic: NativeInt;

SoundCount: NativeInt;
Sound: Array [0..100] of SoundTemp; // Stored Sounds
CurrentSound: Array [0..100] of SourceTemp; // Actually playing sounds
UtilitySource: SourceTemp;


SoundLoop: Array [0..20] of SourceTemp; // LoopingSounds

Music: Array [0..20] of SoundTemp;
CurrentMusic: SourceTemp;

PauseArray: Array [0..200] Of NativeInt;
LoopPauseArray: Array [0..20] Of NativeInt;
NoteArray: Array [1..12] of String;

pglSound: pglSoundInstance;

MusicQueueList: Array [0..20] of QueueEntry;


implementation


Constructor SoundTemp.Create();


  Begin

    Inherited Create();

  end; // Sound Create


Constructor pglListener.Create();

Var
I: NativeInt;

  Begin

    For I := 0 to 2 Do Begin
    self.listenerpos[i] := 0.0;
    self.listenervel[i] := 0.0;
    end;

    Self.pX := 0;
    Self.pY := 0;
    Self.pDirection := 0;
    self.pVolume := 0;
  end;

Constructor SourceTemp.Create();
Var
I: NativeInt;

  Begin

    Inherited Create();

    For i := 0 to 2 do
    Begin

    self.sourcepos[i] := 0.0;
    self.sourcevel[i] := 0.0;

    end;

    AlGenSources(1,@Self.Source);
    AlSourcef ( self.source, AL_PITCH, 1.0 );
    AlSourcef ( self.source, AL_GAIN, 1.0 );
    AlSourcefv ( self.source, AL_POSITION, @self.sourcepos);
    AlSourcei ( self.source, AL_LOOPING, 0);
    AlSourcef(Self.Source, AL_MAX_GAIN,1);
    AlSourceF(Self.Source, AL_MIN_GAIN,0);

  end; // Create Source


Procedure AssignSound(InName, Path: String; InType: String = 'FX');

  Begin

    TotalSounds := TotalSounds + 1;

    With Sound[TotalSounds] do begin

    Name := InName;
    SoundType := Intype;

    AlGenBuffers(1, @Sound[TotalSounds].Buffer);
    AlutLoadWavFile(Path, format, data, size, freq, loop);
    AlBufferData(Sound[TotalSounds].Buffer, format, data, size, freq);
    AlutUnloadWav(format, data, size, freq);

      if (Format = AL_FORMAT_MONO8) or (Format = AL_FORMAT_STEREO8) Then Begin
        Sound[TotalSounds].Length := (Size / 2) / Freq;
      End Else Begin
        Sound[TotalSounds].Length := (Size / 4) / Freq;
      End;

    end; // end With

  end; // Assign Soung


Procedure AssignMusic(InName, Path: String);

  Begin

    TotalMusic := TotalMusic + 1;

    With Music[TotalMusic] do begin

    Name := InName;

    AlGenBuffers(1, @buffer);
    AlutLoadWavFile(Path, format, data, size, freq, loop);
    Music[TotalMusic].SFreq := Freq;
    AlBufferData(buffer, format, data, size, freq);
    AlutUnloadWav(format, data, size, freq);

      if (Format = AL_FORMAT_MONO8) or (Format = AL_FORMAT_STEREO8) Then Begin
        Music[TotalMusic].Length := (Size / 2) / Freq;
      End Else Begin
        Music[TotalMusic].Length := (Size / 4) / Freq;
      End;

    end; // end With

  end; // Assign Music


Procedure AddToSoundStop(InSource: TaluInt; InDuration: Double);

Var
I: NativeInt;

  Begin

//    For I := 1 to 20 Do Begin
//      If SoundStopList[i].EndTime = 0 Then Begin
//        SoundStopList[i].EndTime := GameTime + InDuration;
//        SoundStoplist[i].Source := InSource;
//        Break;
//      End;
//    End;

  End;


Procedure CheckSoundStops();

Var
I: NativeInt;
State: TALuint;

  Begin

//    For I := 1 to 20 Do Begin
//      If SoundStopList[i].EndTime <> 0 Then Begin
//        If GameTime >= SoundStopList[i].EndTime Then Begin
//
//          AlSourcePause(SoundStopList[i].Source);
//          AlSourceStop(SoundStopList[i].Source);
//
//          // Get source state and only remove from list if the sound has stopped playing
//          AlGetSourcei(SoundStopList[i].Source,AL_SOURCE_STATE,@State);
//
//          If State <> AL_PLAYING Then Begin
//            SoundStopList[i].EndTime := 0;
//            SoundStopList[i].Source := 0;
//          End;
//
//        End;
//      End;
//    End;

  End;


Procedure PlayLoop(InName: String);

Var
I: NativeInt;
Selected: NativeInt;

  Begin

    Selected := 0;

    If OpenALRunning = False Then Begin // Exit if OpenAL is not running
      Exit;
    end;

    For I := 1 to High(SoundLoop) Do Begin
      If SoundLoop[i].Name = InName Then Begin // Exit if another loop shares the loop name
        Exit;
      end;

      If (SoundLoop[i].Name = '') AND (Selected = 0) Then Begin // If an empty loop has not been selected, select it
        Selected := I;
      End;
    End;

    If Selected = 0 Then Begin // If no loop selected because all are used, Exit
      Exit;
    End;

    for I := 0 to TotalSounds Do Begin

      if Sound[i].Name = InName then Begin

          // Assign stored sound to next current sound, incriment soundcount, loop if over 100
          AlSourcei(SoundLoop[Selected].source, AL_BUFFER, Sound[i].Buffer);
          AlSourceI(SoundLoop[Selected].Source,AL_LOOPING, AL_TRUE);
          AlSourcePlay(SoundLoop[Selected].Source);

          SoundLoop[Selected].Name := InName;

          Exit

      end;

    end;

  end;


Procedure LoopChangePitch(LoopName: String; Pitch: Double = 1);

Var
I: NativeInt;

	Begin

    For I := 1 to High(SoundLoop) Do Begin
    	If SoundLoop[i].Name = LoopName Then Begin

        ALSourcef(SoundLoop[i].Source,AL_PITCH,Pitch);
        Exit;

      End;
    End;


 	End;


Procedure StopLoop(InName: string);

Var
I: NativeInt;

  Begin

    If OpenALrunning = false then begin
      Exit;
    End;

    For I := 0 to High(SoundLoop) Do Begin
      If SoundLoop[i].Name = InName Then Begin
        AlSourcePause(SoundLoop[i].Source);
        AlSourceI(SoundLoop[i].Source, AL_LOOPING, AL_FALSE);
        AlSourceStop(SoundLoop[i].Source);
        SoundLoop[i].Name := '';
      End;
    End;

  End;



Procedure SetMusic();

  Begin

  End;


Procedure PlayMusic(InName: String; NextMusic: String = ''; NextSound: String = '');

Var
I: NativeInt;

  Begin

    If OpenALRunning = False Then Begin
      Exit;
    end;

    for I := 0 to TotalMusic Do
    Begin

      if Music[i].Name = InName then
        Begin

          // Stop Music, Replace, Play
            AlSourceStop(CurrentMusic.Source);


          AlSourceI(CurrentMusic.source, AL_BUFFER, Music[i].Buffer);
          AlSourceF(CurrentMusic.Source, AL_GAIN, 1);
          AlSourcePlay(CurrentMusic.Source);

          Exit

        end;

      end;

  end;


Procedure StopMusic();

	Begin

    AlSourceStop(CurrentMusic.source);

  End;


Procedure PauseAllSounds();

Var
I:NativeInt;
State: Integer;

  Begin

    If OpenAlRunning = False Then Begin
      Exit;
    end;

    AlSourcePause(CurrentMusic.Source);

    // Sounds
    For I := 1 to High(Sound) Do Begin

      AlGetSourcei( CurrentSound[i].source, AL_SOURCE_STATE, @State);

      if State = AL_Playing Then Begin

        AlSourcePause(CurrentSound[i].Source);

      end;

    end;

    // Loops
    For I := 1 to High(SoundLoop) Do Begin

      AlGetSourcei( SoundLoop[i].source, AL_SOURCE_STATE, @State);

      if State = AL_Playing Then Begin

        AlSourcePause(SoundLoop[i].Source);

      end;

    end;

  End;


Procedure ResumeAllSounds();

Var
I:NativeInt;
State: Integer;

  Begin

    If OpenALRunning = False Then Begin
      Exit;
    end;

    //Music
    AlSourcePlay(CurrentMusic.Source);

    // Sounds
    For I := 1 to High(Sound) Do Begin

      AlGetSourcei( CurrentSound[i].source, AL_SOURCE_STATE, @State);

      if State = AL_PAUSED Then Begin

        AlSourcePlay(CurrentSound[i].Source);

      end;

    end;

    // Loops
    For I := 1 to High(SoundLoop) Do Begin

      AlGetSourcei( SoundLoop[i].source, AL_SOURCE_STATE, @State);

      if State = AL_PAUSED Then Begin

        AlSourcePlay(SoundLoop[i].Source);

      end;

    end;

  end;


Constructor pglSoundInstance.Create();
Var
I: Long;

  Begin

    Inherited;

    pglSound := Self;

    InitOpenAL;
    AlutInit(nil,argv);
    OpenALRunning := True;

    TotalSounds := 0;
    SoundCount := 0;

    alDistanceModel(AL_INVERSE_DISTANCE_CLAMPED);

    Self.pListener := pglListener.Create();

    For I := 0 to High(Music) Do Begin
      Music[i] := SoundTemp.Create();
    end;

    For I := 0 to high(SoundLoop) Do Begin
      SoundLoop[i] := SourceTemp.Create();
    End;

    CurrentMusic := SourceTemp.Create();
    AlSourcei(CurrentMusic.Source, AL_LOOPING, 1);

    UtilitySource := SourceTemp.Create();

    For I := 0 to 100 Do Begin
      AlGenSources(1, @Self.Sounds[i].Source);
      AlSourcei(Self.Sounds[i].Source, AL_LOOPING, AL_FALSE);
    End;

    Self.CurrentSound := 0;
    Self.BufferCount := 0;
    Self.SourceCount := 0;
  End;


Procedure pglSoundInstance.SetGlobalVolume(Value: Double);
  Begin

    If Value > 1 Then Begin
      Value := 1;
    End Else If Value < 0 Then Begin
      Value := 0;
    End;

    Self.Listener.SetVolume(Value);
  End;


Procedure pglSoundInstance.SetDynamicSound(Enable: Boolean = True);
  Begin
    Self.pDynamicSound := Enable;
    If Enable = True Then Begin
      alDistanceModel(AL_INVERSE_DISTANCE_CLAMPED);
    End Else Begin
      alDistanceModel(AL_NONE);
    End;
  End;


Procedure pglSoundInstance.PlayFromBuffer(Var Buffer: pglSoundBuffer);
  Begin
    Self.TempSource.AssignBuffer(Buffer);
    Self.TempSource.SetGain(1);
    Self.TempSource.SetPosition(Self.Listener.X,Self.Listener.Y);
    Self.TempSource.SetFixedPitch(1);
    Self.TempSource.SetLooping(False);
    Self.TempSource.SetDirection(0);
    self.TempSource.SetRadius(0);
    Self.TempSource.SetCone(Pi*2,1);
    Self.TempSource.Play();
  End;


Procedure pglSoundInstance.PlayFromBuffer(Var Buffer: pglSoundBuffer; X,Y,Radius,Direction,Gain,Pitch,ConeAngle,ConeOuterGain: Single);
  Begin
    Self.TempSource.AssignBuffer(Buffer);
    Self.TempSource.SetGain(Gain);
    Self.TempSource.SetPosition(X,Y);
    Self.TempSource.SetFixedPitch(Pitch);
    Self.TempSource.SetLooping(False);
    Self.TempSource.SetDirection(Direction);
    Self.TempSource.SetRadius(Radius);
    Self.TempSource.SetCone(ConeAngle,ConeOuterGain);
    Self.Playsound(Self.TempSource);
  End;

Procedure pglSoundInstance.PlaySound(Var From: pglSoundSource);
Var
CurSound: ^pglSoundSlot;
Dist: Single;
Angle: Single;
GainChange: Single;
DX,DY: Single;

  Begin

    CurSound := @Self.Sounds[Self.CurrentSound];
    CurSound.SoundSource := @From;
    alSourceStop(CurSound.Source);

    pglSourcei(CurSound.Source, AL_BUFFER, From.Buffer.Buffer);

    // use source properties if dynamic sound is enabled
    If (From.isDynamic = True) and (Self.DyanmicSound = True) Then Begin

      pglSource3f(CurSound.Source,AL_POSITION, From.PosX, From.PosY, 0);
      pglSourceF(CurSound.Source, AL_MAX_DISTANCE, From.Radius);
      pglSourceF(CurSound.Source, AL_REFERENCE_DISTANCE, From.Radius / 4);
      pglSourceF(CurSound.Source, AL_ROLLOFF_FACTOR, 5);

      DX := 1 * Cos(From.Direction);
      DY := 1 * Sin(From.Direction);

      alSource3f(CurSound.Source, AL_DIRECTION, DX,DY,0);

      alSourcef(CurSound.Source, AL_CONE_OUTER_ANGLE,From.ConeAngle);
      alSourcef(CurSound.Source, AL_CONE_INNER_ANGLE,0);
      alSourcef(Cursound.Source, AL_CONE_OUTER_GAIN,From.ConeOuterGain);

    End Else Begin

      pglSource3f(CurSound.Source, AL_POSITION, Self.Listener.X, Self.Listener.Y, 0);
      pglSourceF(CurSound.Source, AL_MAX_DISTANCE, 0);
      pglSourceF(CurSound.Source, AL_REFERENCE_DISTANCE, 0);
      pglSourceF(CurSound.Source, AL_ROLLOFF_FACTOR, 1);

      alSourcef(CurSound.Source, AL_CONE_OUTER_ANGLE, 360);
      alSourcef(CurSound.Source, AL_CONE_INNER_ANGLE, 260);
      alSourcef(CurSound.Source, AL_CONE_OUTER_GAIN, 1);

    End;

    If From.HasVariablePitch = False Then Begin
      AlSourcef(CurSound.Source, AL_PITCH,From.pPitchRange[0]);
    End Else Begin
      AlSourcef(CurSound.Source, AL_PITCH, Rnd(From.pPitchRange[0], From.pPitchRange[1]));
    End;

    If From.Looping = True Then Begin
      AlSourceI(CurSound.Source,AL_LOOPING, AL_TRUE);
    End Else Begin
      AlSourceI(CurSound.Source,AL_LOOPING, AL_FALSE);
    End;

    AlSourcePlay(CurSound.Source);

    Self.CurrentSound := Self.CurrentSound + 1;
      if Self.CurrentSound > 100 then Begin
        Self.CurrentSound := 0;
      end;

    Exit
  End;


Procedure pglSoundInstance.StopSound(var From: pglSoundSource);

Var
CurSound: ^pglSoundSlot;
I: Long;
ReturnVal: TALint;

  Begin

    For I := 0 to 100 Do Begin

      CurSound := @Self.Sounds[i];
      AlGetSourcei(Cursound.Source,AL_SOURCE_STATE,@ReturnVal);

      If ReturnVal = AL_PLAYING Then Begin
        If CurSound.SoundSource = @From Then Begin
          AlSourceStop(CurSound.Source);
        End;
      End;

    End;

  End;


Procedure StartOpenAL();

Var
I: NativeInt;


  Begin

    If OpenALRunning = True Then Exit;


  End; // OpenAL Init



Procedure UnloadSounds();

Var
I: NativeInt;
State: Integer;

  Begin

    If OpenALRunning = false Then Begin
      Exit;
    end;

    For i := 0 to high(sound) do begin

      If Assigned(Sound[i]) THen Begin

        AlSourceStop(CurrentSound[i].Source);
        AlDeleteBuffers(1, @sound[i].buffer);
        AlDeleteBuffers(1, @Currentsound[i].buffer);
        AlDeleteSources(1, @CurrentSound[i].source);
        Sound[i].Free;
        CurrentSound[i].Free;
      end;
    end;

    For I := 0 To high(SoundLoop) Do Begin
      AlSourceStop(SoundLoop[i].Source);
      AlDeleteBuffers(1,@SoundLoop[i].Buffer);
      AlDeleteSources(1,@Soundloop[i].Source);
      SoundLoop[i].Free;
    End;

    For I := 0 to High(Music) Do Begin
    AlDeleteBuffers(1, @Music[i].buffer);
    Music[i].Free;
    end;

    AlutExit();

    OpenALRunning := false;

  end;


Procedure ALClearErrors();

  Begin

  AlGetError();
  ErrorState := 0;

  end;

Procedure AlGetErrorState();

  Begin

    ErrorState := AlGetError();
      If ErrorState <> AL_NO_ERROR Then Begin
        AlReturnError();
      End;

  end;

Function AlReturnError(): String;

  Begin

    Case ErrorState of

      AL_NO_ERROR : Result := 'No Error!';

      AL_INVALID_NAME : Result := 'Invalid Name';

      AL_INVALID_ENUM : Result := 'Invalid Enum Value';

      AL_INVALID_VALUE : Result := 'Invalid Value Passed';

      AL_INVALID_OPERATION : Result := 'Invalid Operation';

      AL_OUT_OF_MEMORY : Result := 'Out Of Memory';

    end;

    MessageBox(0,PWideChar(Result),'AL ERROR', MB_OK);

  end;


Function SoundGetTime(): Double;

Var
Intime: Int64;

  Begin

    QueryPerformanceFrequency(SoundTimeFreq);
    QueryPerformanceCounter(InTime);
    SoundTime := InTime / SoundTimeFreq;
    Result := SoundTime;

  End;


Procedure pglListener.SetPosition(X,Y: single);
Var
Orr: Array [0..5] of Single;
  Begin
    Self.pX := X;
    Self.pY := Y;
    Self.listenerpos[0] := X;
    Self.listenerpos[1] := Y;
    Self.listenerpos[2] := 0;
    AlListenerfv(AL_POSITION,@Self.listenerpos);

    Orr[0] := 0;
    Orr[1] := 1;
    Orr[2] := 1;
    Orr[3] := 0;
    Orr[4] := 0;
    Orr[5] := 1;

    alListenerfv(AL_ORIENTATION,@Orr);

    AlSource3f(CurrentMusic.Source, AL_POSITION, X,Y,0);
  End;

Procedure pglListener.SetDirection(Angle: Single);
Var
X,Y: Single;
  Begin
    X := 1 * Cos(Angle);
    Y := 1 * Sin(Angle);
    Self.listenerdir[0] := X;
    Self.listenerdir[1] := Y;
  End;

Procedure pglListener.SetVolume(Value: Single);
  Begin
    Self.pVolume := Value;
    If Self.Volume < 0 Then Self.pVolume := 0;
    If Self.Volume > 1 Then Self.pVolume := 1;
    alListenerf(AL_GAIN,Self.Volume);
  End;


Procedure pglSoundBuffer.LoadDataFromFile(FileName: string; NameBuffer: String);
  Begin

    If FileExists(FileName) = False Then Exit;

    Self.pIsValid := True;

    Self.pName := NameBuffer;

    AlGenBuffers(1, @Self.pBuffer);
    AlutLoadWavFile(FileName, format, data, size, freq, loop);
    AlBufferData(Self.pBuffer, format, data, size, freq);
    AlutUnloadWav(format, data, size, freq);

      if (Format = AL_FORMAT_MONO8) or (Format = AL_FORMAT_STEREO8) Then Begin
        Self.pLength := (Size / 2) / Freq;
      End Else Begin
        Self.pLength := (Size / 4) / Freq;
      End;


  End;


Class Operator pglSoundSource.Initialize(Out Dest: pglSoundSource);
  Begin
    Dest.pRadius := 100;
    Dest.pHasBuffer := False;
    Dest.pGain := 1;
    Dest.pPosX := 0;
    Dest.pPosY := 0;
    Dest.pHasPosPointers := False;
    Dest.pXPointer := Nil;
    Dest.pYPointer := Nil;
    Dest.pHasVariablePitch := False;
    Dest.pPitchRange[0] := 1;
    Dest.pPitchRange[1] := 1;
    Dest.pDirection := 0;
    Dest.pConeAngle := 360;
    Dest.pConeOuterGain := 1;
    Dest.pLooping := False;
    Dest.pisDynamic := False;
    Dest.Source := 0;
  End;


Procedure pglSoundSource.CheckHasBuffer();
  Begin

    // if doesn't have buffer, then create source, add to pglSound source array
    If Self.pHasBuffer = False Then Begin
      Inc(pglSound.SourceCount);
      SetLength(pglSound.Sources, pglSound.SourceCount);
      pglSound.Sources[pglSound.SourceCount - 1] := @Self;
      Self.pHasBuffer := true;
    End;

  End;

Procedure pglSoundSource.AssignBuffer(Var Buffer: pglSoundBuffer);
  Begin

    // Gen source if has none
    If Self.Source = 0 Then Begin
      alGenSources(1,@Self.Source);
    End;

    // Make sure the source is created first
    Self.CheckHasBuffer();
    Self.pBuffer := Buffer;
    Self.pHasBuffer := True;
    alSourcei(Self.Source, AL_BUFFER, Self.pBuffer.Buffer);
  End;


Procedure pglSoundSource.SetGain(Value: Double);
  Begin
    If Value < 0 Then Value := 0;
    If Value > 1 Then Value := 1;

    Self.pGain := Value;
  End;


Procedure pglSoundSource.UpdateBufferPosition();
  Begin
    alSource3F(Self.Source, AL_POSITION, Self.PosX, Self.PosY, 0);
  End;


Procedure pglSoundSource.SetPosition(X: Double; Y: Double);
  Begin
    Self.pPosX := X;
    Self.pPosY := Y;
    Self.UpdateBufferPosition();
  End;


Procedure pglSoundSource.SetXPosition(X: Double);
  Begin
    Self.pPosX := X;
    Self.UpdateBufferPosition();
  End;


Procedure pglSoundSource.SetYPosition(Y: Double);
  Begin
    Self.pPosY := Y;
    Self.UpdateBufferPosition();
  End;


Procedure pglSoundSource.SetPositionPointers(pX: Pointer; pY: Pointer);
  Begin
    Self.pHasPosPointers := True;
    Self.pXPointer := pX;
    Self.pYPointer := pY;
  End;


Procedure pglSoundSource.SetVariablePitch(LowRange: Double; HighRange: Double);
  Begin
    Self.pHasVariablePitch := True;
    Self.pPitchRange[0] := LowRange;
    Self.pPitchRange[1] := HighRange;
  End;


Procedure pglSoundSource.SetFixedPitch(Value: Double);
  Begin
    Self.pHasVariablePitch := False;
    Self.pPitchRange[0] := Value;
    Self.pPitchRange[1] := Value;
    alSourceF(Self.Source, AL_PITCH, Value);
  End;

Procedure pglSoundSource.SetLooping(Value: Boolean = True);
  Begin
    Self.pLooping := Value;
    alSourceI(Self.Source, AL_LOOPING, Value.ToInteger);
  End;

Procedure pglSoundSource.SetDirection(Angle: Single);
Var
I,R: Long;
DX,DY: Single;
  Begin
    Self.pDirection := Angle;

    R := -1;

    For I := 0 to High(pglSound.Sounds) Do Begin
      If (pglSound.Sounds[i].SoundSource = @Self) Then Begin
        R := I;
        Break;
      End;
    End;

    If R = -1 Then Exit;

    DX := 1 * Cos(Self.Direction);
    DY := 1 * Sin(Self.Direction);

    alSource3f(pglSound.Sounds[r].Source, AL_DIRECTION, DX, DY, 0);

  End;

Procedure pglSoundSource.SetRadius(Distance: Single);
  Begin
    Self.pRadius := Distance;
  End;

Procedure pglSoundSource.SetCone(Angle: Single; ConeOuterGain: Single);
  Begin
    Self.pConeAngle := Angle * (180 / Pi);
    Self.pConeOuterGain := ConeOuterGain;
  End;

Procedure pglSoundSource.SetConeAngle(Angle: Single);
  Begin
    Self.pConeAngle := Angle * (180 / Pi);
  End;

Procedure pglSoundSource.SetConeOuterGain(Gain: Single);
  Begin
    Self.pConeOuterGain := Gain;
  End;

Procedure pglSoundSource.ReleasePositionPointers();
  Begin
    Self.pHasPosPointers := False;
    Self.pXPointer := nil;
    Self.pYPointer := nil;
  End;

Procedure pglSoundSource.SetDynamic(Enable: Boolean = True);
  Begin
    Self.pisDynamic := Enable;
  End;

Procedure pglSoundSource.UpdatePosition();
  Begin
    If Self.pHasPosPointers = False Then Exit;

    Self.pPosX := Self.pXPointer^;
    Self.pPosY := Self.pYPointer^;
  End;


Procedure pglSoundSource.Play();
  Begin

    If Self.pHasPosPointers Then Begin
      Self.UpdatePosition();
    End;

    alSourcef(Self.Source, AL_GAIN, Self.Gain);
    alSource3f(Self.Source, AL_POSITION, Self.PosX, Self.PosY, 0);
    alSource3f(Self.Source, AL_DIRECTION, Cos(Self.Direction), Sin(Self.Direction), 0);
    alSourcef(Self.Source, AL_MAX_DISTANCE, Self.Radius);
    alSourcef(Self.Source, AL_REFERENCE_DISTANCE, Self.Radius / 4);
    alSourcef(Self.Source, AL_ROLLOFF_FACTOR,5);
    alSourcef(Self.Source, AL_CONE_OUTER_ANGLE, Self.ConeAngle);
    alSourcef(Self.Source, AL_CONE_INNER_ANGLE, 0);
    alSourcef(Self.Source, AL_CONE_OUTER_GAIN, Self.ConeOuterGain);

    alSourcePlay(Self.Source);
  End;


Procedure pglSoundSource.Stop();

  Begin

  End;



Function Rnd(Val1,Val2: Double): Double;

Var
Diff: Double;
Return: Double;

  Begin

    Val1 := Val1 * 100000;
    Val2 := Val2 * 100000;
    Diff := Val2 - Val1;
    Return := Random(trunc(Diff)) + Val1;
    Return := Return / 100000;
    Result := Return;

  End;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Procedure pglBufferi(Target: TALUint; Enum: TALEnum; Value: TALUint);
  Begin
    ALGetError();
    ALBufferi(Target,Enum,Value);
    AlGetErrorState();
  End;

Procedure pglBuffer3i(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALuint);
  Begin
    ALGetError();
    ALBuffer3i(Target,Enum,Value2, Value2, Value3);
    AlGetErrorState();
  End;

Procedure pglBufferiv(Target: TALUint; Enum: TALEnum; Value: PALint);
  Begin
    ALGetError();
    ALBufferiv(Target,Enum,Value);
    AlGetErrorState();
  End;

Procedure pglBufferf(Target: TALUint; Enum: TALEnum; Value: TALfloat);
  Begin
    ALGetError();
    ALBufferf(Target,Enum,Value);
    AlGetErrorState();
  End;

Procedure pglBuffer3f(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALfloat);
  Begin
    ALGetError();
    ALBuffer3f(Target,Enum,Value1,Value2,Value3);
    AlGetErrorState();
  End;

Procedure pglBufferfv(Target: TALUint; Enum: TALEnum; Value: PALFloat);
  Begin
    ALGetError();
    ALBufferfv(Target,Enum,Value);
    AlGetErrorState();
  End;

{------------------------------------------------------------------------------}

Procedure pglSourcei(Target: TALUint; Enum: TALEnum; Value: TALUint);
  Begin
    ALGetError();
    AlSourcei(Target,Enum,Value);
    AlGetErrorState();
  End;

Procedure pglSource3i(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALuint);
  Begin
    ALGetError();
    AlSource3i(Target,Enum,Value2,Value2,Value3);
    AlGetErrorState();
  End;

Procedure pglSourceiv(Target: TALUint; Enum: TALEnum; Value: PALint);
  Begin
    ALGetError();
    AlSourceiv(Target,Enum,Value);
    AlGetErrorState();
  End;

Procedure pglSourcef(Target: TALUint; Enum: TALEnum; Value: TALfloat);
  Begin
    ALGetError();
    AlSourcef(Target,Enum,Value);
    AlGetErrorState();
  End;

Procedure pglSource3f(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALfloat);
  Begin
    ALGetError();
    AlSource3f(Target,Enum,Value1,Value2,Value3);
    AlGetErrorState();
  End;

Procedure pglSourcefv(Target: TALUint; Enum: TALEnum; Value: PALFloat);
  Begin
    ALGetError();
    AlSourcefv(Target,Enum,Value);
    AlGetErrorState();
  End;

end.
