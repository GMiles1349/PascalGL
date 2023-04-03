unit PGLAudio;

{$HINTS OFF}
{$POINTERMATH ON}

interface

uses
  OpenAl, PGLTypes,
  classes, SysUtils, Math;

  Const ALBUFFER = (0);
  Const ALSOURCE = (1);
  Const ALLISTERN = (2);

  type TPGLSoundState = (pgl_initial = AL_INITIAL, pgl_stopped = AL_STOPPED, pgl_playing = AL_PLAYING, pgl_paused = AL_PAUSED);


  type
    PPGLSoundBuffer = ^TPGLSoundBuffer;
    TPGLSoundBuffer = class(TObject)
    private
      fIsValid: Boolean;
      fBuffer: TALUint;
      fLength: TALFloat;
      fName: String;

      constructor Create(); register;

    public
      property IsValid: Boolean read fIsValid;
      property Buffer: TALUint read fBuffer;
      property Length: TALFloat read fLength;
      property Name: String read fName;

      procedure LoadDataFromFile(FileName: String; NameBuffer: String); register; inline;
  end;


  type
    PPGLMusicBuffer = ^TPGLMusicBuffer;
    TPGLMusicBuffer = class(TObject)
      private
        fState: TPGLSoundState;
        fIsValid: Boolean;
        fBuffers: Array [0..4] of TALUint;
        fQueued: Array [0..4] of Boolean;
        fSource: TALUint;
        fData: Pointer;
        fDataPos: Cardinal;
        fDataSize: Cardinal;
        fFormat: Integer;
        fFrequency: Cardinal;
        fBitsPerSample: TALInt;
        fChannels: TALInt;
        fPeriod: TALInt;
        fLength: TALFloat;
        fName: String;
        fSpeed: TALFloat;

        procedure Stream(); register;

      public
        property IsValid: Boolean read fIsValid;
        property Data: Pointer read fData;
        property DataPos: Cardinal read fDataPos;
        property Length: TALFloat read fLength;
        property Name: String read fName;
        property Speed: TALFloat read fSpeed;

        constructor Create(); register;

        procedure LoadDataFromFile(FileName: String; NameBuffer: String); register; inline;

        procedure Play(); register;
        procedure Pause(); register;
        procedure Stop(); register;
        procedure Resume(); register;
  end;

  type
    PPGLSoundSource = ^TPGLSoundSource;
    TPGLSoundSource = record
    private
      Source: TALUInt;
      fState: TPGLSoundState;

      fHasBuffer: Boolean; // is the buffer assigned?
      fBuffer: TPGLSoundBuffer;

      fisDynamic: Boolean;
      fGain: Single;
      fPosition: TPGLVec2;

      fHasPositionPointers: Boolean; // Are position pointer values set?
      fXPointer,fYPointer: PSingle; // Pointers to values to update from dynamically

      fHasVariablePitch: Boolean;
      fPitchRange: Array [0..1] of Single;
      fBaseFrequency: TALFloat;
      fCurrentFrequency: TALFLoat;

      fDirection: Single;
      fRadius: Single;
      fConeAngle: Single;
      fConeOuterGain: Single;
      fLooping: Boolean;
      fisPlaying: Boolean;

      procedure UpdateBufferPosition(); register;
      procedure CheckHasBuffer(); register; inline;

    public
      Name: String;

      class operator Initialize(Out Dest: TPGLSoundSource); register;

      // Properties
      property HasBuffer: Boolean read fHasBuffer;
      property Buffer: TPGLSoundBuffer read fBuffer;
      property isDynamic: Boolean read fisDynamic;
      property Gain: Single read fGain;
      property Position: TPGLVec2 read fPosition;
      property HasVariablePitch: Boolean read fHasVariablePitch;
      property Looping: Boolean read fLooping;
      property Direction: Single read fDirection;
      property Radius: Single read fRadius;
      property ConeAngle: Single read fConeAngle;
      property ConeOuterGain: Single read fConeOuterGain;
      property State: TPGLSoundState read fState;
      property isPlaying: Boolean read fisPlaying;

      // Setters
      procedure AssignBuffer(Buffer: TPGLSoundBuffer); overload; register; inline;
      procedure AssignBuffer(ABufferName: String); overload; register; inline;
      procedure SetGain(Value: Single); register; inline;
      procedure SetPosition(APosition: TPGLVec2); register; inline;
      procedure SetPositionPointers(pX,pY: Pointer); register; inline;
      procedure SetVariablePitch(LowRange,HighRange: Single); register; inline;
      procedure SetFixedPitch(Value: Single); register; inline;
      procedure SetLooping(Value: Boolean = True); register; inline;
      procedure SetDirection(Angle: Single); register; inline;
      procedure SetRadius(Distance: Single); register; inline;
      procedure SetCone(Angle,ConeOuterGain: Single); register; inline;
      procedure SetConeAngle(Angle: Single); register; inline;
      procedure SetConeOuterGain(Gain: Single); register; inline;
      procedure SetDynamic(Enable: Boolean = True); register; inline;

      // Actions
      procedure ReleasePositionPointers(); register; inline;
      procedure UpdatePosition(); register; inline;
      procedure Play(); register; inline;
      procedure Stop(); register; inline;
      procedure Pause(); register;
      procedure Resume(); register;
  end;


  type
    PPGLSoundSlot = ^TPGLSoundSlot;
    TPGLSoundSlot = record
    private
      SoundSource: ^TPGLSoundSource;
      Source: TALUint;
  end;

  type
    TPGLListener = class
    private
      fDirection: Single;
      fPosition: TPGLVec2;
      fVolume: TALFloat;

      listenerpos: array [0..2] of TALfloat;
      listenervel: array [0..2] of TALfloat;
      listenerdir: array [0..2] of TALfloat;

      constructor Create();

    public
      property Direction: TALFloat read fDirection;
      property Position: TPGLVec2 read fPosition;
      property Volume: TALFloat read fVolume;

      procedure SetPosition(APosition: TPGLVec2); register;
      procedure SetDirection(Angle: Single); register;
      procedure SetVolume(Value: Single); register;
  end;


  type
    TSourceTemp = class
    public
      Name: String;
      source : TALuint;
      sourcepos: array [0..2] of TALfloat;
      sourcevel: array [0..2] of TALfloat;
      State: Paluint;
      Buffer: TALUint;
      SFreq: TALSizeI;

      constructor Create();
  end;


  type
    TPGLSoundInstance = class
    private
      fVorbisSupport: Boolean;
      fEAXSupport: Boolean;
      fGlobalVolume: Single;
      fListener: TPGLListener;
      fDynamicSound: Boolean;

      BufferCount: Integer;
      Buffers: Array of TPGLSoundBuffer;
      SourceCount: Integer;
      Sources: Array of ^TPGLSoundSource;
      Sounds: Array [0..100] of TPGLSoundSlot;
      CurrentSound: TALUint;
      CurrentMusic: TPGLMusicBuffer;
      TempSource: TPGLSoundSource;

      PauseCount: TALUInt;
      PauseList: Array of PPGLSoundSource;

      procedure PlaySound(var From: TPGLSoundSource); register; inline;
      procedure StopSound(var From: TPGLSoundSource); register; inline;

    public
      // Properties
      property VorbisSupport: Boolean read fVorbisSupport;
      property EAXSupport: Boolean read fEAXSupport;
      property GlobalVolume: Single read fGlobalVolume;
      property Listener: TPGLListener read fListener;
      property DyanmicSound: Boolean read fDynamicSound;

      constructor Create(); register;
      Destructor Destroy(); override; register;
      procedure Update(); register;

      // factories
      function GenSoundBuffer(var ABuffer: TPGLSoundBuffer; AName: String; AFileName: String): Boolean; register;

      // Setters
      procedure SetGlobalVolume(Value: Single); register; inline;
      procedure SetDynamicSound(Enable: Boolean = True); register; inline;
      procedure PlayFromBuffer(Buffer: TPGLSoundBuffer); Overload; register;
      procedure PlayFromBuffer(Buffer: TPGLSoundBuffer; APosition: TPGLVec2; Radius,Direction,Gain,Pitch,ConeAngle,ConeOuterGain: Single); Overload; register;
      procedure PauseAllPlaying(); register;
      procedure ResumeAllPaused(); register;

      // Getters
      function GetSoundBufferByName(ABufferName: String): TPGLSoundBuffer; register;
  end;

  procedure AlGetErrorState();
  procedure ALClearErrors();
  function AlReturnError(): String;

  procedure pglBufferi(Target: TALUint; Enum: TALEnum; Value: TALUint); register; inline;
  procedure pglBuffer3i(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALuint); register; inline;
  procedure pglBufferiv(Target: TALUint; Enum: TALEnum; Value: PALint); register; inline;
  procedure pglBufferf(Target: TALUint; Enum: TALEnum; Value: TALfloat); register; inline;
  procedure pglBuffer3f(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALfloat); register; inline;
  procedure pglBufferfv(Target: TALUint; Enum: TALEnum; Value: PALFloat); register; inline;

  procedure pglSourcei(Target: TALUint; Enum: TALEnum; Value: TALUint); register; inline;
  procedure pglSource3i(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALuint); register; inline;
  procedure pglSourceiv(Target: TALUint; Enum: TALEnum; Value: PALint); register; inline;
  procedure pglSourcef(Target: TALUint; Enum: TALEnum; Value: TALfloat); register; inline;
  procedure pglSource3f(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALfloat); register; inline;
  procedure pglSourcefv(Target: TALUint; Enum: TALEnum; Value: PALFloat); register; inline;

var
OpenALRunning: Boolean;
argv: array of PalByte;

ErrorState: TALuint;

format: TALEnum;
size: TALSizei;
freq: TALSizei;
loop: TALInt;
data: TALVoid;

SoundCount: NativeInt;
UtilitySource: TSourceTemp;

pglSound: TPGLSoundInstance;

implementation

constructor TPGLListener.Create();
Var
I: NativeInt;
  begin

    for I := 0 to 2 do begin
    self.listenerpos[i] := 0.0;
    self.listenervel[i] := 0.0;
    end;

    Self.fPosition := Vec2(0,0);
    Self.fDirection := 0;
    self.fVolume := 0;
  end;

constructor TSourceTemp.Create();
Var
I: NativeInt;

  begin

    Inherited Create();

    for i := 0 to 2 do
    begin

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


constructor TPGLSoundInstance.Create();
Var
I: Integer;

  begin

    Inherited;

    pglSound := Self;

    InitOpenAL;
    AlutInit(nil,argv);
    OpenALRunning := True;

    SoundCount := 0;

    alDistanceModel(AL_INVERSE_DISTANCE_CLAMPED);

    Self.fListener := TPGLListener.Create();

    UtilitySource := TSourceTemp.Create();

    for I := 0 to 100 do begin
      AlGenSources(1, @Self.Sounds[i].Source);
      AlSourcei(Self.Sounds[i].Source, AL_LOOPING, AL_FALSE);
    end;

    Self.CurrentSound := 0;
    Self.BufferCount := 0;
    Self.SourceCount := 0;

    Self.fVorbisSupport := alIsExtensionPresent('AL_EXT_vorbis');
    Self.fEAXSupport := alIsExtensionPresent('EAX2.0');
    EAXSet := alGetProcAddress('EAXSet');
    EAXGet := alGetProcAddress('EAXGet');
  end;


destructor TPGLSoundInstance.Destroy();
  begin
    Inherited;
  end;

function TPGLSoundInstance.GenSoundBuffer(var ABuffer: TPGLSoundBuffer; AName: string; AFileName: string): Boolean;
var
I: Integer;
  begin

    Result := False;

    if Assigned(ABuffer) = True then Exit;

    // check to see if other buffers have the same name
    for I := 0 to High(Self.Buffers) do begin
      if Self.Buffers[i].Name = AName then begin
        Exit;
      end;
    end;

    ABuffer := TPGLSoundBuffer.Create();
    ABuffer.LoadDataFromFile(AFileName, AName);

    // add to buffer list
    SetLength(Self.Buffers, Length(Self.Buffers) + 1);
    I := High(Self.Buffers);
    Self.Buffers[i] := ABuffer;
  end;


procedure TPGLSoundInstance.SetGlobalVolume(Value: Single);
  begin

    if Value > 1 then begin
      Value := 1;
    end Else if Value < 0 then begin
      Value := 0;
    end;

    Self.Listener.SetVolume(Value);
  end;


procedure TPGLSoundInstance.SetDynamicSound(Enable: Boolean = True);
  begin
    Self.fDynamicSound := Enable;
    if Enable = True then begin
      alDistanceModel(AL_INVERSE_DISTANCE_CLAMPED);
    end Else begin
      alDistanceModel(AL_NONE);
    end;
  end;


procedure TPGLSoundInstance.PlayFromBuffer(Buffer: TPGLSoundBuffer);
  begin
    Self.TempSource.AssignBuffer(Buffer);
    Self.TempSource.SetGain(1);
    Self.TempSource.SetPosition(Self.Listener.Position);
    Self.TempSource.SetFixedPitch(1);
    Self.TempSource.SetLooping(False);
    Self.TempSource.SetDirection(0);
    self.TempSource.SetRadius(0);
    Self.TempSource.SetCone(Pi*2,1);
    Self.TempSource.Play();
  end;


procedure TPGLSoundInstance.PlayFromBuffer(Buffer: TPGLSoundBuffer; APosition: TPGLVec2; Radius,Direction,Gain,Pitch,ConeAngle,ConeOuterGain: Single);
  begin
    Self.TempSource.AssignBuffer(Buffer);
    Self.TempSource.SetGain(Gain);
    Self.TempSource.SetPosition(APosition);
    Self.TempSource.SetFixedPitch(Pitch);
    Self.TempSource.SetLooping(False);
    Self.TempSource.SetDirection(Direction);
    Self.TempSource.SetRadius(Radius);
    Self.TempSource.SetCone(ConeAngle,ConeOuterGain);
    Self.Playsound(Self.TempSource);
  end;


procedure TPGLSoundInstance.PauseAllPlaying();
// pause all sounds that are currently playing and add to resume list
var
I,R: TALUint;
  begin
    for I := 0 to High(Self.Sources) do begin
      if Self.Sources[i].fState = pgl_playing then begin

        R := Self.PauseCount;
        if R + 1 > Length(Self.PauseList) then begin
          SetLength(Self.PauseList, R + 1);
        end;

        Self.PauseList[R] := @Self.Sources[i].Source;
        Self.Sources[r].Pause();

        Inc(Self.PauseCount);

      end;
    end;
  end;


procedure TPGLSoundInstance.ResumeAllPaused();
// resume all sounds from pause list, clear pause list
var
I,R: TALUint;
  begin
    for I := 0 to Self.PauseCount - 1 do begin
      Self.PauseList[i].Play;
      Self.PauseList[i] := nil;
    end;

    Self.PauseCount := 0;
  end;


function TPGLSoundInstance.GetSoundBufferByName(ABufferName: String): TPGLSoundBuffer;
var
I: Integer;
  begin
    Result := nil;
    for I := 0 to High(Self.Buffers) do begin
      if Self.Buffers[i].Name = ABufferName then begin
        Result := Self.Buffers[i];
      end;
    end;
  end;

procedure TPGLSoundInstance.PlaySound(Var From: TPGLSoundSource);
Var
CurSound: ^TPGLSoundSlot;
Dist: Single;
Angle: Single;
GainChange: Single;
DX,DY: Single;

  begin

    CurSound := @Self.Sounds[Self.CurrentSound];
    CurSound.SoundSource := @From;
    alSourceStop(CurSound.Source);

    pglSourcei(CurSound.Source, AL_BUFFER, From.Buffer.Buffer);

    // use source properties if dynamic sound is enabled
    if (From.isDynamic = True) and (Self.DyanmicSound = True) then begin

      pglSource3f(CurSound.Source,AL_POSITION, From.Position.X, From.Position.Y, 0);
      pglSourceF(CurSound.Source, AL_MAX_DISTANCE, From.Radius);
      pglSourceF(CurSound.Source, AL_REFERENCE_DISTANCE, From.Radius / 4);
      pglSourceF(CurSound.Source, AL_ROLLOFF_FACTOR, 5);

      DX := 1 * Cos(From.Direction);
      DY := 1 * Sin(From.Direction);

      alSource3f(CurSound.Source, AL_DIRECTION, DX,DY,0);

      alSourcef(CurSound.Source, AL_CONE_OUTER_ANGLE,From.ConeAngle);
      alSourcef(CurSound.Source, AL_CONE_INNER_ANGLE,0);
      alSourcef(Cursound.Source, AL_CONE_OUTER_GAIN,From.ConeOuterGain);

    end Else begin

      pglSource3f(CurSound.Source, AL_POSITION, Self.Listener.Position.X, Self.Listener.Position.Y, 0);
      pglSourceF(CurSound.Source, AL_MAX_DISTANCE, 0);
      pglSourceF(CurSound.Source, AL_REFERENCE_DISTANCE, 0);
      pglSourceF(CurSound.Source, AL_ROLLOFF_FACTOR, 1);

      alSourcef(CurSound.Source, AL_CONE_OUTER_ANGLE, 360);
      alSourcef(CurSound.Source, AL_CONE_INNER_ANGLE, 260);
      alSourcef(CurSound.Source, AL_CONE_OUTER_GAIN, 1);

    end;

    if From.HasVariablePitch = False then begin
      AlSourcef(CurSound.Source, AL_PITCH,From.fPitchRange[0]);
    end Else begin
      AlSourcef(CurSound.Source, AL_PITCH, From.fPitchRange[1] * Random());
    end;

    if From.Looping = True then begin
      AlSourceI(CurSound.Source,AL_LOOPING, AL_TRUE);
    end Else begin
      AlSourceI(CurSound.Source,AL_LOOPING, AL_FALSE);
    end;

    AlSourcePlay(CurSound.Source);

    Self.CurrentSound := Self.CurrentSound + 1;
      if Self.CurrentSound > 100 then begin
        Self.CurrentSound := 0;
      end;

    Exit
  end;


procedure TPGLSoundInstance.StopSound(var From: TPGLSoundSource);

Var
CurSound: ^TPGLSoundSlot;
I: Integer;
ReturnVal: TALint;

  begin

    for I := 0 to 100 do begin

      CurSound := @Self.Sounds[i];
      AlGetSourcei(Cursound.Source,AL_SOURCE_STATE,@ReturnVal);

      if ReturnVal = AL_PLAYING then begin
        if CurSound.SoundSource = @From then begin
          AlSourceStop(CurSound.Source);
        end;
      end;

    end;

  end;


procedure TPGLSoundInstance.Update();
var
I: Integer;
P: TALInt;
  begin

    for I := 0 to High(pglSound.Sources) do begin

      alGetSourceI(pglSound.Sources[i]^.Source, AL_SOURCE_STATE, @pglSound.Sources[i].fState);

      if pglSound.Sources[i].fState = TPGLSoundState.pgl_playing then begin
        pglSound.Sources[i].fisPlaying := True;
      end else begin
        pglSound.Sources[i].fisPlaying := False;
      end;

      // update position for pointers
      if pglSound.Sources[i].fHasPositionPointers then begin
        pglSound.Sources[i].UpdatePosition();
      end;

    end;

    if Self.CurrentMusic <> nil then begin
      alGetSourceI(Self.CurrentMusic.fSource, AL_SOURCE_STATE, @pglSound.CurrentMusic.fState);
      alSource3f(Self.CurrentMusic.fSource, AL_POSITION, Self.Listener.Position.X, Self.Listener.Position.Y, 0);
      Self.CurrentMusic.Stream();
    end;

  end;

procedure ALClearErrors();
  begin
    AlGetError();
    ErrorState := 0;
  end;

procedure AlGetErrorState();
  begin
    ErrorState := AlGetError();
      if ErrorState <> AL_NO_ERROR then begin
        AlReturnError();
      end;
  end;


function AlReturnError(): String;
  begin

    Case ErrorState of

      AL_NO_ERROR : Result := 'No Error!';

      AL_INVALID_NAME : Result := 'Invalid Name';

      AL_INVALID_ENUM : Result := 'Invalid Enum Value';

      AL_INVALID_VALUE : Result := 'Invalid Value Passed';

      AL_INVALID_OPERATION : Result := 'Invalid Operation';

      AL_OUT_OF_MEMORY : Result := 'Out Of Memory';

    end;

  end;


procedure TPGLListener.SetPosition(APosition: TPGLVec2);
Var
Orr: Array [0..5] of Single;
I: Integer;
  begin
    Self.fPosition := APosition;
    Self.listenerpos[0] := APosition.X;
    Self.listenerpos[1] := APosition.Y;
    Self.listenerpos[2] := 0;
    AlListenerfv(AL_POSITION,@Self.listenerpos);

    Orr[0] := 0;
    Orr[1] := 1;
    Orr[2] := 1;
    Orr[3] := 0;
    Orr[4] := 0;
    Orr[5] := 1;

    alListenerfv(AL_ORIENTATION,@Orr);

    // move music source with listener
    if pglSound.CurrentMusic <> nil then begin
      alSource3f(pglSound.CurrentMusic.fSource, AL_POSITION, APosition.X, APosition.Y, 0);
    end;

    // move non-dynamic sounds with listener
    for I := 0 to High(pglSound.Sources) do begin
      if pglSound.Sources[i].State = TPGLSoundState.pgl_playing then begin
        if pglSound.Sources[i].isDynamic = False then begin
          alSource3f(pglSound.Sources[i].Source, AL_POSITION, APosition.X, APosition.Y, 0);
        end;
      end;
    end;

  end;

procedure TPGLListener.SetDirection(Angle: Single);
Var
X,Y: Single;
  begin
    X := 1 * Cos(Angle);
    Y := 1 * Sin(Angle);
    Self.listenerdir[0] := X;
    Self.listenerdir[1] := Y;
  end;


procedure TPGLListener.SetVolume(Value: Single);
  begin
    Self.fVolume := Value;
    if Self.Volume < 0 then Self.fVolume := 0;
    if Self.Volume > 1 then Self.fVolume := 1;
    alListenerf(AL_GAIN,Self.Volume);
  end;


constructor TPGLSoundBuffer.Create();
  begin
    Self.fIsValid := False;
    Self.fBuffer := 0;
    Self.fLength := 0;
    Self.fName := '';
  end;

procedure TPGLSoundBuffer.LoadDataFromFile(FileName: string; NameBuffer: String);
  begin

    if FileExists(FileName) = False then Exit;

    Self.fIsValid := True;

    Self.fName := NameBuffer;

    AlGenBuffers(1, @Self.fBuffer);
    AlutLoadWavFile(FileName, format, data, size, freq, loop);
    AlBufferData(Self.fBuffer, format, data, size, freq);
    AlutUnloadWav(format, data, size, freq);

      if (format = AL_FORMAT_MONO8) or (format = AL_FORMAT_STEREO8) then begin
        Self.fLength := (Size / 2) / Freq;
      end Else begin
        Self.fLength := (Size / 4) / Freq;
      end;
  end;


constructor TPGLMusicBuffer.Create();
var
I: Integer;
Env: TALUInt;
  begin
    inherited;
    alGenSources(1,@Self.fSource);
    alSourcef(Self.fSource, AL_GAIN, 1);
    alSource3f(Self.fSource, AL_DIRECTION, 0, 0, 0);
    alSourcef(Self.fSource, AL_MAX_DISTANCE, 0);
    alSourcef(Self.fSource, AL_REFERENCE_DISTANCE, 0);
    alSourcef(Self.fSource, AL_ROLLOFF_FACTOR,0);
    alSourcef(Self.fSource, AL_CONE_OUTER_ANGLE, 0);
    alSourcef(Self.fSource, AL_CONE_INNER_ANGLE, 0);
    alSourcef(Self.fSource, AL_CONE_OUTER_GAIN, 1);

    Self.fState := TPGLSoundState.pgl_initial;
    Self.fSpeed := 1;
  end;

procedure TPGLMusicBuffer.LoadDataFromFile(FileName: string; NameBuffer: string);
var
TempBuffer: TALUInt;
  begin
    if FileExists(FileName) = False then Exit;

    Self.fIsValid := True;

    Self.fName := NameBuffer;
    Self.fSpeed := 0.5;

    AlGenBuffers(5, @Self.fBuffers);
    AlutLoadWavFile(FileName, Self.fFormat, Self.fData, Self.fDataSize, Self.fFrequency, loop);

    alGenBuffers(1,@Tempbuffer);
    alBufferData(Tempbuffer, Self.fFormat, Self.fData, Self.fDataSize, trunc(Self.fFrequency / Self.Speed));
    alGetBufferI(Tempbuffer, AL_BITS, @Self.fBitsPerSample);
    alGetBufferI(TempBuffer, AL_CHANNELS, @Self.fChannels);
    alDeleteBuffers(1,@TempBuffer);


      if (format = AL_forMAT_MONO8) or (format = AL_forMAT_STEREO8) then begin
        Self.fLength := (Self.fDataSize / 2) / Self.fFrequency;
      end Else begin
        Self.fLength := (Self.fDataSize / 4) / Self.fFrequency;
      end;

  end;


procedure TPGLMusicBuffer.Play();
var
I,R: TALUint;
BufferSize: TALUint;
DataPointer: PByte;
DoBreak: Boolean;
QueueCount: Integer;
BuffersQueued: TALInt;
Bytes: TArray<Byte>;
BytePos: TALFloat;
  begin

    if Self.fState = pgl_playing then Exit;

    Self.fDataPos := 0;
    QueueCount := 0;

    for I := 0 to 4 do begin

      DataPointer := Self.fData;
      DataPointer := DataPointer + Self.fDataPos;

      DoBreak := False;

      if Self.fDataSize - Self.fDataPos < (Self.fFrequency * 2) then begin
        BufferSize := Self.fDataSize - Self.fDataPos;
        DoBreak := True;
      end else begin
        BufferSize := Self.fFrequency;
      end;


      alBufferData(Self.fBuffers[i], Self.fFormat, PByte(Self.fData) + Self.fDataPos, BufferSize, Self.fFrequency);
      alSourceQueueBuffers(Self.fSource, 1, @Self.fBuffers[i]);
      Self.fQueued[i] := True;
      Inc(Self.fDataPos, BufferSize);

      if Self.fDataPos >= Self.fDataSize then begin
        Self.fDataPos := 0;
      end;

      if DoBreak then Break;

    end;

    alGetSourceI(Self.fSource, AL_BUFFERS_QUEUED, @BuffersQueued);
    alSource3f(Self.fSource, AL_POSITION, pglSound.Listener.Position.X + 10, pglSound.Listener.Position.Y, -100);
    alSourcePlay(self.fSource);

    Self.fState := TPGLSoundState.pgl_playing;

    pglSound.CurrentMusic := Self;
  end;


procedure TPGLMusicbuffer.Pause();
  begin

  end;

procedure TPGLMusicBuffer.Stop();
  begin

  end;

procedure TPGLMusicBuffer.Resume();
  begin

  end;

procedure TPGLMusicBuffer.Stream();
var
I,R: Integer;
BuffersProcessed: TALInt;
BuffersQueued: TALInt;
CurBuffer: TALUInt;
BufferSize: Integer;
DataPointer: PByte;
BytePos: TALFloat;
Bytes: TArray<Byte>;
IterCount: TALInt;
ChunkSize: TALInt;
MoveSize: TALInt;
ByteCount: TALInt;
  begin

    if Self.fState <> pgl_playing then begin
      I := 1;
      Exit;
    end;

    BuffersProcessed := 0;

    alGetSourceI(Self.fSource, AL_BUFFERS_QUEUED, @BuffersQueued);
    alGetSourceI(Self.fSource, AL_BUFFERS_PROCESSED, @BuffersProcessed);
    DataPointer := Self.fData;
    DataPointer := DataPointer + Self.fDataPos;


    while BuffersProcessed > 0 do begin
      CurBuffer := 0;
      alSourceUnqueueBuffers(Self.fSource, 1, @CurBuffer);

      if Self.fDataSize - Self.fDataPos < (Self.fFrequency) then begin
        BufferSize := Self.fDataSize - Self.fDataPos;
      end else begin
        BufferSize := Self.fFrequency;
      end;


      alBufferData(CurBuffer, Self.fFormat, PByte(Self.fData) + Self.fDataPos, BufferSize, Self.fFrequency);

      Inc(Self.fDataPos, BufferSize);

      for I := 0 to 4 do begin
        if CurBuffer = Self.fBuffers[i] then begin
          Self.fQueued[i] := True;
          Break;
        end;
      end;

      if Self.fDataPos >= Self.fDataSize then begin
        Self.fDataPos := 0;
      end;

      alSourceQueueBuffers(Self.fSource, 1, @CurBuffer);

      Dec(BuffersProcessed);

    end;

  end;


class operator TPGLSoundSource.Initialize(Out Dest: TPGLSoundSource);
  begin
    Dest.fRadius := 100;
    Dest.fHasBuffer := False;
    Dest.fGain := 1;
    Dest.fPosition := Vec2(0,0);
    Dest.fHasPositionPointers := False;
    Dest.fXPointer := Nil;
    Dest.fYPointer := Nil;
    Dest.fHasVariablePitch := False;
    Dest.fPitchRange[0] := 1;
    Dest.fPitchRange[1] := 1;
    Dest.fDirection := 0;
    Dest.fConeAngle := 360;
    Dest.fConeOuterGain := 1;
    Dest.fLooping := False;
    Dest.fisDynamic := False;
    Dest.Source := 0;
  end;


procedure TPGLSoundSource.CheckHasBuffer();
  begin

    // if doesn't have buffer, then create source, add to pglSound source array
    if Self.fHasBuffer = False then begin
      Inc(pglSound.SourceCount);
      SetLength(pglSound.Sources, pglSound.SourceCount);
      pglSound.Sources[pglSound.SourceCount - 1] := @Self;
      Self.fHasBuffer := true;
    end;

  end;

procedure TPGLSoundSource.AssignBuffer(Buffer: TPGLSoundBuffer);
  begin

    // Gen source if has none
    if Self.Source = 0 then begin
      alGenSources(1,@Self.Source);
    end;

    if Buffer = Self.fBuffer then Exit;
    if Buffer.IsValid = False then Exit;

    // Make sure the source is created first
    Self.CheckHasBuffer();
    Self.fBuffer := Buffer;
    Self.fHasBuffer := True;
    alSourcei(Self.Source, AL_BUFFER, Self.fBuffer.Buffer);
  end;


procedure TPGLSoundsource.AssignBuffer(ABufferName: String);
var
I: Integer;
  begin
    for I := 0 to High(pglSound.Buffers) do begin
      if pglSound.Buffers[i].Name = ABufferName then begin
        Self.AssignBuffer(pglSound.Buffers[i]);
      end;
    end;
  end;


procedure TPGLSoundSource.SetGain(Value: Single);
  begin
    if Value < 0 then Value := 0;
    if Value > 1 then Value := 1;

    Self.fGain := Value;
  end;


procedure TPGLSoundSource.UpdateBufferPosition();
  begin
    alSource3F(Self.Source, AL_POSITION, Self.Position.X, Self.Position.Y, 0);
  end;


procedure TPGLSoundSource.SetPosition(APosition: TPGLVec2);
  begin
    Self.fHasPositionPointers := False;
    Self.fPosition := APosition;
    Self.UpdateBufferPosition();
  end;


procedure TPGLSoundSource.SetPositionPointers(pX: Pointer; pY: Pointer);
  begin
    Self.fHasPositionPointers := True;
    Self.fXPointer := pX;
    Self.fYPointer := pY;
  end;


procedure TPGLSoundSource.SetVariablePitch(LowRange: Single; HighRange: Single);
  begin
    Self.fHasVariablePitch := True;
    Self.fPitchRange[0] := LowRange;
    Self.fPitchRange[1] := HighRange;
  end;


procedure TPGLSoundSource.SetFixedPitch(Value: Single);
  begin
    Self.fHasVariablePitch := False;
    Self.fPitchRange[0] := Value;
    Self.fPitchRange[1] := Value;
    alSourceF(Self.Source, AL_PITCH, Value);
  end;

procedure TPGLSoundSource.SetLooping(Value: Boolean = True);
  begin
    Self.fLooping := Value;
    alSourceI(Self.Source, AL_LOOPING, Value.ToInteger);
  end;

procedure TPGLSoundSource.SetDirection(Angle: Single);
Var
I,R: Integer;
DX,DY: Single;
  begin
    Self.fDirection := Angle;

    R := -1;

    for I := 0 to High(pglSound.Sounds) do begin
      if (pglSound.Sounds[i].SoundSource = @Self) then begin
        R := I;
        Break;
      end;
    end;

    if R = -1 then Exit;

    DX := 1 * Cos(Self.Direction);
    DY := 1 * Sin(Self.Direction);

    alSource3f(pglSound.Sounds[r].Source, AL_DIRECTION, DX, DY, 0);

  end;

procedure TPGLSoundSource.SetRadius(Distance: Single);
  begin
    Self.fRadius := Distance;
  end;

procedure TPGLSoundSource.SetCone(Angle: Single; ConeOuterGain: Single);
  begin
    Self.fConeAngle := Angle * (180 / Pi);
    Self.fConeOuterGain := ConeOuterGain;
  end;

procedure TPGLSoundSource.SetConeAngle(Angle: Single);
  begin
    Self.fConeAngle := Angle * (180 / Pi);
  end;

procedure TPGLSoundSource.SetConeOuterGain(Gain: Single);
  begin
    Self.fConeOuterGain := Gain;
  end;

procedure TPGLSoundSource.ReleasePositionPointers();
  begin
    Self.fHasPositionPointers := False;
    Self.fXPointer := nil;
    Self.fYPointer := nil;
  end;

procedure TPGLSoundSource.SetDynamic(Enable: Boolean = True);
  begin
    Self.fisDynamic := Enable;
  end;

procedure TPGLSoundSource.UpdatePosition();
  begin
    if Self.fHasPositionPointers = False then Exit;

//    Self.fPosition.X := Self.fXPointer^;
//    Self.fPosition.Y := Self.fYPointer^;
    Self.UpdateBufferPosition();
  end;


procedure TPGLSoundSource.Play();
var
Dist: Double;
  begin

    if Self.fBuffer = nil then Exit;
    if Self.fBuffer.fIsValid = False then Exit;
    if Self.fisPlaying then Exit;

    if Self.fHasPositionPointers then begin
      Self.UpdatePosition();
    end;


    Dist := Sqrt( IntPower(pglSound.Listener.Position.X - Self.Position.X, 2) + IntPower(pglSound.Listener.Position.Y - Self.Position.Y, 2));

    If Dist > Self.Radius then Exit;

    alSourcef(Self.Source, AL_GAIN, Self.Gain * ( Self.Radius / Dist) );
    alSource3f(Self.Source, AL_POSITION, Self.Position.X, Self.Position.Y,0 );
    alSource3f(Self.Source, AL_DIRECTION, Cos(Self.Direction), Sin(Self.Direction), 0);
    alSourcef(Self.Source, AL_MAX_DISTANCE, Self.Radius);
    alSourcef(Self.Source, AL_REFERENCE_DISTANCE, 10);
    alSourcef(Self.Source, AL_ROLLOFF_FACTOR,2);
    alSourcef(Self.Source, AL_CONE_OUTER_ANGLE, Self.ConeAngle);
    alSourcef(Self.Source, AL_CONE_INNER_ANGLE, 0);
    alSourcef(Self.Source, AL_CONE_OUTER_GAIN, Self.ConeOuterGain);

    alSourcePlay(Self.Source);

    Self.fState := pgl_playing;
    Self.fisPlaying := True;
  end;


procedure TPGLSoundSource.Stop();
  begin
    if Self.fState <> pgl_playing then Exit;
    alSourceStop(Self.Source);
    Self.fState := pgl_stopped;
  end;


procedure TPGLSoundSource.Pause();
  begin
    if Self.fState <> pgl_playing then Exit;
    alSourcePause(Self.Source);
    Self.fState := pgl_paused;
  end;

procedure TPGLSoundSource.Resume();
  begin
    if Self.fState <> pgl_paused then Exit;
    alSourcePlay(Self.Source);
    Self.fState := pgl_playing;
  end;


function Rnd(Val1,Val2: Single): Single;
Var
Diff: Single;
Return: Single;
  begin
    Val1 := Val1 * 100000;
    Val2 := Val2 * 100000;
    Diff := Val2 - Val1;
    Return := Random(trunc(Diff)) + Val1;
    Return := Return / 100000;
    Result := Return;
  end;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure pglBufferi(Target: TALUint; Enum: TALEnum; Value: TALUint);
  begin
    ALGetError();
    ALBufferi(Target,Enum,Value);
    AlGetErrorState();
  end;

procedure pglBuffer3i(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALuint);
  begin
    ALGetError();
    ALBuffer3i(Target,Enum,Value2, Value2, Value3);
    AlGetErrorState();
  end;

procedure pglBufferiv(Target: TALUint; Enum: TALEnum; Value: PALint);
  begin
    ALGetError();
    ALBufferiv(Target,Enum,Value);
    AlGetErrorState();
  end;

procedure pglBufferf(Target: TALUint; Enum: TALEnum; Value: TALfloat);
  begin
    ALGetError();
    ALBufferf(Target,Enum,Value);
    AlGetErrorState();
  end;

procedure pglBuffer3f(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALfloat);
  begin
    ALGetError();
    ALBuffer3f(Target,Enum,Value1,Value2,Value3);
    AlGetErrorState();
  end;

procedure pglBufferfv(Target: TALUint; Enum: TALEnum; Value: PALFloat);
  begin
    ALGetError();
    ALBufferfv(Target,Enum,Value);
    AlGetErrorState();
  end;

{------------------------------------------------------------------------------}

procedure pglSourcei(Target: TALUint; Enum: TALEnum; Value: TALUint);
  begin
    ALGetError();
    AlSourcei(Target,Enum,Value);
    AlGetErrorState();
  end;

procedure pglSource3i(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALuint);
  begin
    ALGetError();
    AlSource3i(Target,Enum,Value2,Value2,Value3);
    AlGetErrorState();
  end;

procedure pglSourceiv(Target: TALUint; Enum: TALEnum; Value: PALint);
  begin
    ALGetError();
    AlSourceiv(Target,Enum,Value);
    AlGetErrorState();
  end;

procedure pglSourcef(Target: TALUint; Enum: TALEnum; Value: TALfloat);
  begin
    ALGetError();
    AlSourcef(Target,Enum,Value);
    AlGetErrorState();
  end;

procedure pglSource3f(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALfloat);
  begin
    ALGetError();
    AlSource3f(Target,Enum,Value1,Value2,Value3);
    AlGetErrorState();
  end;

procedure pglSourcefv(Target: TALUint; Enum: TALEnum; Value: PALFloat);
  begin
    ALGetError();
    AlSourcefv(Target,Enum,Value);
    AlGetErrorState();
  end;


end.
