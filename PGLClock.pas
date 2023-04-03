unit PGLClock;

interface

uses
  System.SysUtils, Types, Classes, WinAPI.Windows;


  type
    TPGLTriggerType = (pgl_trigger_on_time = 0, pgl_trigger_on_interval = 1);
    TPGLClockEvent = procedure;

    TPGLClock = Class;
    TPGLEvent = Class;


    TPGLClock = Class
      private
        Freq: Int64;
        InTime: Int64;
        fRunning: Boolean;
        fInitTime: Double;
        fInterval: Double;
        fCurrentTime: Double;
        fLastTime: Double;
        fCycleTime: Double;
        fTargetTime: Double;
        fElapsedTime: Double;
        fFPS: Double;
        fAverageFPS: Double;
        fFPSCount: Integer;
        fFPSTotal: Double;
        fFrames: Integer;
        fFrameTime: Double;
        fCatchUpEnabled: Boolean;
        fTicks: Int64;
        fExpectedTicks: Int64;

        fEvents: TArray<TPGLEvent>;
        fEventCount: Integer;

        procedure Init(); register;
        procedure Update(); register;
        procedure AddEvent(AEvent: TPGLEvent); register;
        procedure RemoveEvent(AEvent: TPGLEvent); register;
        procedure HandleEvents(); register;

        procedure SetCatchUp(Enable: Boolean = True); register;

      public
        property Running: Boolean read fRunning;
        property Ticks: Int64 read fTicks;
        property ExpectedTicks: Int64 read fExpectedTicks;
        property Interval: Double read fInterval;
        property CurrentTime: Double read fCurrentTime;
        property LastTime: Double read fLastTime;
        property CycleTime: Double read fCycleTime;
        property TargetTime: Double read fTargetTime;
        property ElapsedTime: Double read fElapsedTime;
        property FPS: Double read fFPS;
        property AverageFPS: Double read fAverageFPS;
        property CatchUpEnabled: Boolean read fCatchUpEnabled write SetCatchUp;

        constructor Create(AFPS: Integer = 60); overload;
        constructor Create(AInterval: Double = 0.0166666); overload;

        procedure Start(); register;
        procedure Stop(); register;
        procedure Wait(); register;
        procedure WaitForStableFrame(); register;
        procedure SetIntervalInSeconds(AInterval: Double); register;
        procedure SetIntervalInFPS(AInterval: Double); register;
        Function GetTime(): Double; register;
    end;


    TPGLEvent = Class
      private
        fActive: Boolean;
        fRepeating: Boolean;
        fOwner: TPGLClock;
        fEventProc: TPGLClockEvent;
        fTriggerType: TPGLTriggerType;
        fTriggerTime: Double;
        fNextTriggerTime: Double;

        procedure SetRepeating(const Value: Boolean);
        procedure SetEventProc(const Value: TPGLClockEvent);

        // fTriggerTime is used for TriggerTime and TriggerInterval
        // if trigger type is on time, then setting interval or getting interval will fail or return 0
        // if trigger type is on interval, then setting time or getting time with fail or return 0

        function GetTriggerInterval: Double;
        function GetTriggerTime: Double;
        procedure SetTriggerInterval(const Value: Double);
        procedure SetTriggerTime(const Value: Double);
        procedure SetActive(const Value: Boolean);

      public
        property Owner: TPGLClock read fOwner;
        property Active: Boolean read fActive write SetActive;
        property Repeating: Boolean read fRepeating write SetRepeating;
        property EventProc: TPGLClockEvent read fEventProc write SetEventProc;
        property TriggerType: TPGLTriggerType read fTriggerType;
        property TriggerTime: Double read GetTriggerTime write SetTriggerTime;
        property TriggerInterval: Double read GetTriggerInterval write SetTriggerInterval;

        constructor Create(); overload; register;
        constructor Create(AOwner: TPGLClock; AActive: Boolean; ATriggerAtTime: Double); overload; register;
        constructor Create(AOwner: TPGLClock; AActive: Boolean; ATriggerAtInterval: Double; ARepeating: Boolean = False); overload; register;

        destructor Destroy(); override; register;

        procedure AssignToOwner(AOwner: TPGLClock; AActive: Boolean = True); register;
        procedure RemoveFromOwner(); register;

end;

implementation

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLClock
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLClock.Create(AFPS: Integer = 60);
  begin
    Self.Init();
    Self.SetIntervalInFPS(AFPS);
  end;

procedure TPGLClock.AddEvent(AEvent: TPGLEvent);
var
I: Integer;
  begin

    for I := 0 to High(Self.fEvents) do begin
      if Self.fEvents[i] = AEvent then Exit;
    end;

    Inc(Self.fEventCount);
    SetLength(Self.fEvents, Self.fEventCount);
    Self.fEvents[High(Self.fEvents)] := AEvent;
  end;

procedure TPGLClock.RemoveEvent(AEvent: TPGLEvent);
var
I: Integer;
Index: Integer;
  begin

    Index := -1;
    for I := 0 to High(Self.fEvents) do begin
      if Self.fEvents[i] = AEvent then begin
        Index := I;
        Break;
      end;
    end;

    if Index = -1 then Exit;

    Dec(Self.fEventCount);
    Delete(Self.fEvents,Index,1);

  end;

procedure TPGLClock.HandleEvents();
var
I: Integer;
  begin

    for I := 0 to High(Self.fEvents) do begin

      if Self.fEvents[i].Active = False then Continue;

      case Ord(Self.fEvents[i].TriggerType) of

        Ord(TPGLTriggerType.pgl_trigger_on_time):
          begin

            if Self.fCurrentTime >= Self.fEvents[i].fTriggerTime then begin
              if Assigned(Self.fEvents[i].fEventProc) then begin
                Self.fEvents[i].fEventProc();
              end;

              Self.fEvents[i].SetActive(False);
            end;

          end;

        Ord(TPGLTriggerType.pgl_trigger_on_interval):
          begin

            if Self.fCurrentTime >= Self.fEvents[i].fNextTriggerTime then begin
              if Assigned(Self.fEvents[i].fEventProc) then begin
                Self.fEvents[i].fEventProc();
              end;

              if Self.fEvents[i].Repeating then begin
                Self.fEvents[i].fNextTriggerTime := Self.CurrentTime + Self.fEvents[i].fTriggerTime;
              end else begin
                Self.fEvents[i].SetActive(False);
              end;

            end;

          end;

      end;

    end;

  end;

constructor TPGLClock.Create(AInterval: Double = 0.0166666);
  begin
    Self.Init();
    Self.SetIntervalInSeconds(AInterval);
  end;

procedure TPGLClock.Init();
  begin
    Self.fRunning := False;
    Self.fCurrentTime := 0;
    Self.fLastTime := 0;
    Self.fCycleTime := 0;
    Self.fTargetTime := 0;
    Self.fElapsedTime := 0;
    self.fFPS := 0;
    Self.fAverageFPS := 0;
    Self.fFPSCount := 0;
    Self.fFPSTotal := 0;
    Self.fFrames := 0;
    Self.fFrameTime := 0;
    Self.fTicks := 0;
    QueryPerformanceFrequency(Self.Freq);
  end;

function TPGLClock.GetTime(): Double;
  begin
    QueryPerformanceCounter(Self.InTime);
    Result := Self.InTime / Self.Freq;
  end;

procedure TPGLClock.Update();
var
CalcTarget: Double;
CalcTicks: Double;
  begin
    Inc(Self.fTicks);
    Self.fLastTime := Self.fCurrentTime;
    Self.fCurrentTime := Self.GetTime();
    Self.fCycleTime := Self.CurrentTime - Self.LastTime;
    Self.fElapsedTime := Self.fElapsedTime + Self.fCycleTime;

    if Self.fCatchUpEnabled = False then begin
      Self.fTargetTime := Self.CurrentTime + Self.Interval;
    end else begin
      CalcTicks := (Self.ElapsedTime / Self.Interval);
      CalcTarget := Self.fInitTime + (CalcTicks * Self.Interval);
      Self.fTargetTime := CalcTarget;
      Self.fExpectedTicks := trunc(CalcTicks);
    end;

    // Update FPS
    Self.fFrameTime := Self.fFrameTime + Self.fCycleTime;
    Inc(Self.fFrames);
    if Self.fFrameTime >= 1 then begin
      Self.fFPS := Self.fFrames / Self.fFrameTime;
      Self.fFrameTime := 0;
      Self.fFrames := 0;

      // Update Average FPS
      Self.fFPSTotal := Self.fFPSTotal + Self.fFPS;
      Inc(self.fFPSCount);
      Self.fAverageFPS := Self.fFPSTotal / Self.fFPSCount;

      // reset the FPS total and count at 10,000
      if Self.fFPSCount > 10000 then begin
        Self.fFPSCount := 0;
        Self.fFPSTotal := 0;
      end;
    end;

    // Events
    Self.HandleEvents();

  end;

procedure TPGLClock.SetCatchUp(Enable: Boolean = True);
  begin
    Self.fCatchUpEnabled := Enable;
  end;

procedure TPGLClock.Start();
  begin
    Self.fCurrentTime := Self.GetTime();
    Self.fTargetTime := Self.fCurrentTime + Self.fInterval;
    Self.fRunning := True;
    Self.fInitTime := Self.fCurrentTime;
  end;

procedure TPGLClock.Stop();
  begin

  end;

procedure TPGLClock.Wait();
var
CheckTime: Double;
  begin

    repeat
      CheckTime := Self.GetTime();
    until (CheckTime >= Self.fTargetTime) or (CheckTime = 0);

    Self.Update();
  end;

procedure TPGLClock.WaitForStableFrame();
  begin
    Repeat
      Self.Wait();
    Until Self.FPS >= Self.Interval * 0.99;
  end;

procedure TPGLClock.SetIntervalInSeconds(AInterval: Double);
  begin
    Self.fInterval := AInterval;
  end;

procedure TPGLClock.SetIntervalInFPS(AInterval: Double);
  begin
    Self.fInterval := 1 / AInterval;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLEvent
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLEvent.Create;
  begin

  end;

constructor TPGLEvent.Create(AOwner: TPGLClock; AActive: Boolean; ATriggerAtTime: Double);
  begin
    Self.fTriggerType := TPGLTriggerType.pgl_trigger_on_time;
    Self.fTriggerTime := ATriggerAtTime;
    Self.fActive := AActive;
    Self.fOwner := AOwner;
    Self.fOwner.AddEvent(Self);
  end;

constructor TPGLEvent.Create(AOwner: TPGLClock; AActive: Boolean; ATriggerAtInterval: Double; ARepeating: Boolean);
  begin
    Self.fTriggerType := TPGLTriggerType.pgl_trigger_on_interval;
    Self.fTriggerTime := ATriggerAtInterval;
    Self.fOwner := AOwner;
    Self.fOwner.AddEvent(Self);
    Self.fActive := AActive;
    Self.fRepeating := ARepeating;
  end;

destructor TPGLEvent.Destroy;
  begin
    Self.RemoveFromOwner();
    inherited;
  end;

procedure TPGLEvent.AssignToOwner(AOwner: TPGLClock; AActive: Boolean = True);
  begin
    if AOwner = nil then Exit;

    Self.fOwner := AOwner;
    Self.fOwner.AddEvent(Self);
    Self.SetActive(AActive);

    if Self.fTriggerType = TPGLTriggerType.pgl_trigger_on_interval then begin
      Self.fNextTriggerTime := Self.fOwner.CurrentTime + Self.fTriggerTime;
    end;
  end;

procedure TPGLEvent.RemoveFromOwner();
  begin
    if Self.fOwner <> nil then begin
      Self.fOwner.RemoveEvent(Self);
      Self.SetActive(False);
    end;
  end;

function TPGLEvent.GetTriggerInterval: Double;
  begin
    if Self.fTriggerType = TPGLTriggerType.pgl_trigger_on_time then begin
      Result := 0;
    end else begin
      Result := Self.fTriggerTime;
    end;
  end;

function TPGLEvent.GetTriggerTime: Double;
  begin
    if Self.fTriggerType = TPGLTriggerType.pgl_trigger_on_interval then begin
      Result := 0;
    end else begin
      Result := Self.fTriggerTime;
    end;
  end;

procedure TPGLEvent.SetTriggerInterval(const Value: Double);
  begin
    if Self.fTriggerType = TPGLTriggerType.pgl_trigger_on_time then Exit;

    Self.fTriggerTime := Value;
    if Self.fOwner <> nil then begin
      Self.fNextTriggerTime := Self.fOwner.CurrentTime + Self.fTriggerTime;
    end;
  end;

procedure TPGLEvent.SetTriggerTime(const Value: Double);
  begin
    if Self.fTriggerType = TPGLTriggerType.pgl_trigger_on_interval then Exit;

    Self.fTriggerTime := Value;
  end;

procedure TPGLEvent.SetActive(const Value: Boolean);
  begin
    Self.fActive := Value;
    if Value = True then begin

      if Self.fOwner = nil then begin
        Self.fActive := False;
        Exit;
      end;

      if Self.fTriggerType = TPGLTriggerType.pgl_trigger_on_interval then begin
        Self.fNextTriggerTime := Self.fOwner.CurrentTime + Self.fTriggerTime;
      end;

    end;
  end;

procedure TPGLEvent.SetEventProc(const Value: TPGLClockEvent);
  begin
    fEventProc := Value;
  end;

procedure TPGLEvent.SetRepeating(const Value: Boolean);
  begin
    fRepeating := Value;
  end;




end.
