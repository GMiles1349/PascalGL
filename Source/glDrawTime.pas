unit glDrawTime;

interface

Uses
  SysUtils, Classes, WinAPI.Windows, System.SyncObjs;

////////////////////////////////////////////////////////////////////////////////
                               {Types and Classes}
////////////////////////////////////////////////////////////////////////////////


  Type pglClockEvent = Procedure();


  Type TPGLTimeStruct = Record
    Seconds: Double;
    Minutes: Int32;
    Hours: Int32;

    Class Operator Initialize(Out Dest: TPGLTimeStruct); Register;
    Procedure AddTime(Time: Double); Register;
    Function ToString(): String; Register;
  End;

  Type TPGLTimer = Class

    Private
      pEvent: pglClockEvent;
      pDuration: Double;
      pTimeRemaining: Double;
      pRepeating: Boolean;
      pisAssigned: Boolean;
      pActive: Boolean;
      pSignalUnAssign: Boolean;

      Function Update(InTime: Double): Boolean; Register;

    Public

      Property Event: pglClockEvent read pEvent;
      Property Duration: Double read pDuration;
      Property TimeRemaining: Double read pTimeRemaining;
      Property isRepeating: Boolean read pRepeating;
      Property isActive: Boolean read pActive;
      Property isAssigned: Boolean read pisAssigned;

      Function TimePassed(): TPGLTimeStruct; Register;

      Constructor Create(sEvent: pglClockEvent; sDuration: Double; sRepeat: Boolean); Overload;
      Constructor Create(sEvent: pglClockEvent; sDuration: TPGLTimeStruct; sRepeat: Boolean); Overload;
      Procedure SetEvent(sEvent: pglClockEvent); Register;
      Procedure SetDuration(sDuration: Double); Overload;
      Procedure SetDuration(sDuration: TPGLTimeStruct); Overload;
      Procedure SetRepeating(sRepeat: Boolean = True); Register;
      Procedure UnAssign(); Register;
      Procedure Activate(); Register;
      Procedure DeActivate(); Register;
      Procedure ResetTime(); Register;
  End;


  Type TPGLTimeTrigger = Class
    Private
      pEvent: pglClockEvent;
      pTriggerTime: TPGLTimeStruct;
      pTriggerOnNow: Boolean;
      pisActive: Boolean;
      pisAssigned: Boolean;
      pUnAssignSignal: Boolean;

      Function Update(sTime: TPGLTimeStruct): Boolean; Register;

    Public

      Constructor Create(sEvent: pglClockEvent; sTriggerTime: TPGLTimeStruct; sTriggerOnNow: Boolean = False);
      Procedure Activate(); Register;
      Procedure Deactivate(); Register;
      Procedure UnAssign(); Register;

      Property Event: pglClockEvent read pEvent;
      Property TriggerTime: TPGLTimeStruct read pTriggerTime;
      Property TriggerOnNow: Boolean read pTriggerOnNow;
      Property isActive: Boolean read pisActive;
      Property isAssigned: Boolean read pisAssigned;

  End;

  Type TPGLClock = Class(TPersistent)

    Private
      TimeFreq: Int64;
      InTime: Int64;
      TotalTime: Double;
      pElapsedTime: TPGLTimeStruct;
      pNow: TPGLTimeStruct;
      pareTimersPaused: Boolean;
      TempTimer: Array of TPGLTimer;
      TimerList: Array of TPGLTimer;
      TempTrigger: Array of TPGLTimeTrigger;
      TriggerList: Array of TPGLTimeTrigger;

      Procedure AddTimer(Timer: TPGLTimer); Register;
      Procedure RemoveTimer(Timer: TPGLTimer); Register;
      Procedure HandleTimers(); Register;

    Public

    Running: Boolean;
    Interval: Double;
    WaitCount: Int32;
    FPS: Double;
    FPSLow,FPSHigh: Double;
    FPSTotal: Double;
    AverageFPS: Double;
    FPSCount: Int64;
    Frames: Int32;
    CurrentTime,TargetTime,LastTime,CycleTime: Double;
    FrameTime: Double;
    SyncInterval: UInt32;
    SyncCount: UInt32;
    InSync: Boolean;

    Constructor Create(); Register;

    Function GetCurrentTime(): Double; register;
    Procedure Start(); Register;
    Procedure Stop(); Register;
    Procedure Toggle(); Register;
    Procedure Wait(); Register;
    Procedure ResetElapsedTime(); Register;
    Procedure SetIntervalInSeconds(inSeconds: Double); Register;
    Procedure SetintervalInFPS(inFPS: Double); register;
    Procedure UpdateCycle(); Register;
    Procedure ResetAverageFPS(); Register;
    Procedure SetSyncInterval(InTicks: UInt32); Register;
    Procedure AssignTimer(Timer: TPGLTimer); Register;
    Procedure SetSingleTimer(sEvent: pglClockEvent; sDuration: Double); Overload; Register;
    Procedure SetSingleTimer(sEvent: pglClockEvent; sDuration: TPGLTimeStruct); Overload; Register;
    Procedure UnAssignAllTimers(); Register;
    Procedure PauseTimers(); Register;
    Procedure ResumeTimers(ResetTimers: Boolean = False); Register;

    Procedure AddTrigger(Trigger: TPGLTimeTrigger); Register;
    Procedure RemoveTrigger(Trigger: TPGLTimeTrigger); Register;
    Procedure HandleTriggers(); Register;

    Function GetTotalSeconds(): Double; Register;
    Function GetTotalMinutes(): Double; Register;
    Function GetTotalHours(): Double; Register;

    Property ElapsedTime: TPGLTimeStruct read pElapsedTime;
    Property Now: TPGLTimeStruct read pNow;
    Property areTimersPaused: Boolean read pareTimersPaused;

  End;

  Type TPGLTimeThread = Class(TThread)

    Private
      Clock: TPGLClock;
      Constructor Create();
      Procedure Execute(); OverRide;

    Public

  End;


  Type TPGLTimeInstance = Class
    Private
      TimeThread: TPGLTimeThread;
      Constructor Create();
  End;

////////////////////////////////////////////////////////////////////////////////
                               {Procedures and Functions}
////////////////////////////////////////////////////////////////////////////////


  Function TimeStruct(H,M: Int32; S: Double): TPGLTimeStruct; Register;

  Procedure CreateTimeThread(); Register;
  Procedure DestroyTimeThread(); Register;
  Procedure AssignTimeThreadTimer(sTimer: TPGLTimer); Register;
  Procedure SetTimeThreadSingleTimer(sEvent: pglClockEvent; sDuration: Double); Register;
  Procedure PauseTimeThreadTimers(); Register;
  Procedure ResumeTimeThreadTimers(ResetTimers: Boolean = False); Register;

////////////////////////////////////////////////////////////////////////////////
                               {Global Variables}
////////////////////////////////////////////////////////////////////////////////

Var
  TimeInstance: TPGLTimeInstance;

implementation

Uses
  glDrawMain;

////////////////////////////////////////////////////////////////////////////////
                               {Procedures and Functions}
////////////////////////////////////////////////////////////////////////////////


Function TimeStruct(H,M: Int32; S: Double): TPGLTimeStruct; Register;
  Begin
    Result.Seconds := S;
    Result.Minutes := M;
    Result.Hours := H;
  End;

Procedure CreateTimeThread();
  Begin
    If Assigned(TimeInstance.TimeThread) = False Then Begin
      TimeInstance.TimeThread := TPGLTimeThread.Create();
    End;
  End;

Procedure DestroyTimeThread();
  Begin
    If Assigned(TimeInstance.TimeThread) Then Begin
      TimeInstance.TimeThread.Terminate();
    End;
  End;

Procedure AssignTimeThreadTimer(sTimer: TPGLTimer);
  Begin
    If Assigned(TimeInstance.TimeThread) Then Begin
      TimeInstance.TimeThread.Clock.AddTimer(sTimer);
    End;
  End;

Procedure SetTimeThreadSingletimer(sEvent: pglClockEvent; sDuration: Double);
  Begin
    If Assigned(TimeInstance.TimeThread) Then Begin
      TimeInstance.TimeThread.Clock.SetSingletimer(sEvent,sDuration);
    End;
  End;

Procedure PauseTimeThreadTimers();
  Begin
    If Assigned(TimeInstance.TimeThread) Then Begin
      TimeInstance.TimeThread.Clock.PauseTimers();
    End;
  End;

Procedure ResumeTimeThreadTimers(ResetTimers: Boolean = False);
  Begin
    If Assigned(TimeInstance.TimeThread) Then Begin
      TimeInstance.TimeThread.Clock.ResumeTimers(ResetTimers);
    End;
  End;


////////////////////////////////////////////////////////////////////////////////
                               {TPGLTimeInstance}
////////////////////////////////////////////////////////////////////////////////

Constructor TPGLTimeInstance.Create();
  Begin

  End;

////////////////////////////////////////////////////////////////////////////////
                               {TPGLTimeThread}
////////////////////////////////////////////////////////////////////////////////


Constructor TPGLTimeThread.Create();
  Begin
    Inherited Create(False);
    Self.NameThreadForDebugging('Time Thread');
    Self.SetFreeOnTerminate(True);
    Self.Priority := tpLower;
    Self.Clock := TPGLClock.Create();
    Self.Clock.SetintervalInFPS(120);
  End;


Procedure TPGLTimeThread.Execute();
  Begin

    Self.Clock.Start();

    While Self.clock.Running = True Do Begin
      Self.Clock.HandleTimers();
      Self.Clock.Wait();
    End;

  End;


////////////////////////////////////////////////////////////////////////////////
                               {plgClock}
////////////////////////////////////////////////////////////////////////////////

Constructor TPGLClock.Create();
  Begin

  End;

Procedure TPGLClock.Start();
  Begin
    QueryPerformanceFrequency(Self.TimeFreq);
    Self.LastTime := Self.GetCurrentTime();
    Self.TargetTime := Self.CurrentTime + Self.Interval;
    Self.Running := True;
  End;

Procedure TPGLClock.Stop();
  Begin
    Self.Running := False;
  End;

Procedure TPGLClock.Toggle();
  Begin
    Self.Running := Not Self.Running;
  End;

Procedure TPGLClock.Wait();
  Begin

    If Self.Running = False Then Exit;

    Repeat
//      Inc(Self.WaitCount);
    Until Self.GetCurrentTime() >= Self.TargetTime;

    Self.UpdateCycle();

  End;

Procedure TPGLClock.ResetElapsedTime();
  Begin
    Self.pElapsedTime.Seconds := 0;
    Self.pElapsedTime.Hours := 0;
    Self.pElapsedTime.Minutes := 0;
  End;

Procedure TPGLClock.SetIntervalInSeconds(inSeconds: Double);
  Begin
    Interval := inSeconds;
  End;

Procedure TPGLClock.SetintervalInFPS(inFPS: Double);
  Begin
    Interval := 1/inFps;
  End;

Function TPGLClock.GetCurrentTime: Double;
Var
NowTime: SYSTEMTIME;
  Begin
    QueryPerformanceCounter(Self.InTime);
    Self.CurrentTime := Self.InTime / Self.TimeFreq;
    Result := Self.CurrentTime;

    GetLocalTime(NowTime);
    Self.pNow.Seconds := NowTime.wSecond;
    Self.pNow.Hours := NowTime.wHour;
    Self.pNow.Minutes := NowTime.wMinute;
  End;

Procedure TPGLClock.UpdateCycle();
  Begin

    If Self.Running = False Then Begin
      Exit;
    End;

    Self.CycleTime := Self.CurrentTime - Self.LastTime;
    Self.TargetTime := Self.CurrentTime + Self.Interval;
    Self.LastTime := Self.CurrentTime;

    Self.Frametime := Self.Frametime + Self.CycleTime;
    inc(Self.Frames);

    If self.FrameTime >= 1 Then Begin

      Self.FPS := Frames / Self.Frametime;
      Self.Frames := 0;
      Self.FrameTime := 0;

      Self.FPSTotal := Self.FPSTotal + Self.FPS;
      inc(Self.FPSCount);
      Self.AverageFPS := Self.FPSTotal / Self.FPSCount;

      If Self.FPSLow = 0 then Self.FPSLow := Self.FPS;

      If Self.FPS < Self.FPSLow Then Self.FPSLow := Self.FPS;
      If Self.FPS > Self.FPSHigh Then Self.FPSHigh := Self.FPS;

    End;

    Self.pElapsedTime.Addtime(Self.CycleTime);
    Self.HandleTimers();
    Self.HandleTriggers();

  End;


Procedure TPGLClock.ResetAverageFPS();
  Begin
    Self.FPSTotal := 0;
    Self.AverageFPS := 0;
    Self.FPSCount := 0;
    Self.FPSLow := 0;
    Self.FPSHigh := 0;
  End;


Procedure TPGLClock.SetSyncInterval(InTicks: Cardinal);
  Begin
    Self.SyncInterval := InTicks;
    Self.SyncCount := 0;
    Self.InSync := False;
  End;


Procedure TPGLClock.AssignTimer(Timer: TPGLTimer);
  Begin
    Self.AddTimer(Timer);
  End;

Procedure TPGLClock.SetSingleTimer(sEvent: pglClockEvent; sDuration: Double);
Var
I: Int32;
  Begin
    SetLength(Self.TempTimer, Length(Self.TempTimer) + 1);
    I := High(Self.TempTimer);
    Self.TempTimer[i] := TPGLTimer.Create(sEvent,sDuration,False);
    Self.AddTimer(Self.TempTimer[i]);
    Self.TempTimer[i].Activate();
  End;

Procedure TPGLClock.SetSingleTimer(sEvent: pglClockEvent; sDuration: TPGLTimeStruct);
Var
I: Int32;
  Begin
    SetLength(Self.TempTimer, Length(Self.TempTimer) + 1);
    I := High(Self.TempTimer);
    Self.TempTimer[i] := TPGLTimer.Create(sEvent,sDuration,False);
    Self.AddTimer(Self.TempTimer[i]);
    Self.TempTimer[i].Activate();
  End;

Procedure TPGLClock.UnAssignAllTimers();
Var
I: Int32;
  Begin
    // Unassign all user created timers, reset them, delete list
    If Length(Self.TimerList) = 0 Then Exit;

    For I := 0 to High(Self.TimerList) Do Begin
      Self.TimerList[i].pTimeRemaining := 0;
      Self.TimerList[i].pisAssigned := False;
      Self.TimerList[i].pActive := False;
      Self.TimerList[i].pSignalUnAssign := False;
    End;

    SetLength(Self.TimerList,0);

    // Delete all Single timers
    If Length(Self.TempTimer) = 0 Then Exit;

    For I := 0 to High(Self.TempTimer) Do Begin
      Self.TempTimer[i].Free();
    End;

    SetLength(Self.TempTimer, 0);
  End;

Procedure TPGLClock.PauseTimers();
  Begin
    Self.pareTimersPaused := True;
  End;

Procedure TPGLClock.ResumeTimers(ResetTimers: Boolean = False);
Var
I: Int32;
  Begin
    If Self.pareTimersPaused = False Then Exit;

    Self.pareTimersPaused := False;

    If ResetTimers = True Then Begin
      // Reset Assigned Timers
      For I := 0 to High(Self.TimerList) Do Begin
        If Self.TimerList[i].isActive = True Then Begin
          Self.TimerList[i].pTimeRemaining := Self.TimerList[i].pDuration;
        End;
      End;

      // Reset Temporary single timers
      For I := 0 to High(Self.TempTimer) do Begin
        If Self.TempTimer[i].isActive = True Then Begin
          Self.TempTimer[i].pTimeRemaining := Self.TempTimer[i].pDuration;
        End;
      End;
    End;
  End;


Procedure TPGLClock.AddTrigger(Trigger: TPGLTimeTrigger);
Var
I: Int32;
  Begin
    For I := 0 to High(Self.TriggerList) Do Begin
      If Self.TriggerList[i] = Trigger Then Exit;
    End;

    SetLength(Self.TriggerList, Length(Self.TriggerList) + 1);
    I := High(Self.TriggerList);
    Self.TriggerList[i] := Trigger;
  End;

Procedure TPGLClock.RemoveTrigger(Trigger: TPGLTimeTrigger);
Var
I,R: Int32;
  Begin
    If Length(Self.TriggerList) = 0 Then Exit;

    R := -1;

    For I := 0 to High(Self.TriggerList) Do Begin
      If Self.TriggerList[i] = Trigger Then Begin
        R := I;
        Break;
      End;
    End;

    If R = -1 Then Exit;

    For I := R to High(Self.TriggerList) - 1 Do Begin
      Self.TriggerList[i] := Self.TriggerList[i+1];
    End;

    SetLength(Self.TriggerList, Length(Self.TriggerList) - 1);
  End;

Procedure TPGLClock.HandleTriggers();
Var
I: Int32;
  Begin

    If Length(Self.TriggerList) = 0 Then Exit;

    For I := 0 to High(Self.TriggerList) Do Begin
      If Self.TriggerList[i].pisActive = True Then Begin

        If Self.TriggerList[i].pTriggerOnNow = False Then Begin
          Self.TriggerList[i].Update(Self.ElapsedTime);
        End Else Begin
          Self.TriggerList[i].Update(Self.Now);
        End;

      End;
    End;

  End;


Function TPGLClock.GetTotalSeconds: Double;
  Begin
    Result := Self.TotalTime;
  End;

Function TPGLClock.GetTotalMinutes: Double;
  Begin
    Result := TotalTime / 60;
  End;

Function TPGLClock.GetTotalHours: Double;
  Begin
    Result := (TotalTime / 60) / 60;
  End;

Procedure TPGLClock.AddTimer(Timer: TPGLTimer);
Var
I: Int32;
  Begin

    For I := 0 to High(Self.TimerList) Do Begin
      If Self.TimerList[i] = Timer Then Begin
        Exit;
      End;
    End;

    SetLength(Self.TimerList,Length(Self.TimerList) + 1);
    I := High(Self.TimerList);
    Self.TimerList[i] := Timer;
    Timer.pIsAssigned := True;
  End;

Procedure TPGLClock.RemoveTimer(Timer: TPGLTimer);
Var
I,R: Int32;

  Begin
    If Length(Self.TimerList) = 0 Then Exit;

    R := -1;

    // Look for timer in list, then cache Index in R
    For I := 0 to High(Self.TimerList) Do Begin
      If Self.TimerList[i] = Timer Then Begin
        R := I;
        Break;
      End;
    End;

    // Exit if not found in list
    If R = -1 Then Exit;

    For I := R to High(Self.TimerList) - 1 Do Begin
      Self.TimerList[I] := Self.TimerList[I+1];
    End;

    SetLength(Self.TimerList, Length(Self.TimerList) - 1);

  End;


Procedure TPGLClock.HandleTimers();
Var
I,R,T: Int32;
  Begin
    If Length(Self.TimerList) = 0 Then Exit;

    For I := 0 to High(Self.TimerList) Do Begin

      // Check for unassign
      If Self.TimerList[i].pSignalUnAssign = True Then Begin
        Self.TimerList[i].pSignalUnAssign := False;
        Self.Removetimer(Self.TimerList[i]);
        Continue;
      End;

      If Self.TimerList[i].pActive = True Then Begin
        If Self.TimerList[i].Update(Self.CycleTime) = True Then Begin

          For R := 0 to High(Self.TempTimer) Do Begin
            If Self.TempTimer[r] = Self.TimerList[i] Then Begin

              Self.RemoveTimer(Self.TimerList[i]);
              Self.TempTimer[R].Free();

              For T := R to High(Self.TempTimer) - 1 Do Begin
                Self.TempTimer[R] := Self.TempTimer[R+1];
              End;

              SetLength(Self.TempTimer, Length(Self.TempTimer) - 1);

            End;
          End;

        End;
      End;
    End;

  End;


////////////////////////////////////////////////////////////////////////////////
                           {plgTimeStruct}
////////////////////////////////////////////////////////////////////////////////

Class Operator TPGLTimeStruct.Initialize(Out Dest: TPGLTimeStruct);
  Begin
    Dest.Seconds := 0;
    Dest.Minutes := 0;
    Dest.Hours := 0;
  End;

Procedure TPGLTimeStruct.AddTime(Time: Double);
  Begin

    Self.Seconds := Self.Seconds + Time;

    While Self.Seconds >= 60 Do Begin
      Self.Seconds := Self.Seconds - 60;
      Self.Minutes := Self.Minutes + 1;
    End;

    While Self.Minutes >= 60 Do Begin
      Self.Minutes := Self.Minutes - 60;
      Self.Hours := Self.Hours + 1;
    End;

  End;

Function TPGLTimeStruct.ToString(): String;
  Begin
    Result := Self.Hours.ToString + ':' + Self.Minutes.ToString + ':' + Self.Seconds.ToString(ffFixed,4,2);
  End;


////////////////////////////////////////////////////////////////////////////////
                              {TPGLTimer}
////////////////////////////////////////////////////////////////////////////////

Constructor TPGLTimer.Create(sEvent: pglClockEvent; sDuration: Double; sRepeat: Boolean);
  Begin
    Self.pEvent := sEvent;
    Self.pDuration := sDuration;
    Self.pRepeating := sRepeat;
    Self.pActive := False;
  End;

Constructor TPGLTimer.Create(sEvent: pglClockEvent; sDuration: TPGLTimeStruct; sRepeat: Boolean);
  Begin
    Self.pEvent := sEvent;
    Self.pRepeating := sRepeat;
    Self.pActive := False;

    Self.pDuration := sDuration.Seconds;
    Self.pDuration := Self.pDuration + (sDuration.Minutes * 60);
    Self.pDuration := Self.pDuration + ((sDuration.Hours * 60) * 60);
  End;

Function TPGLTimer.Update(InTime: Double): Boolean;
  Begin
    Result := False;

    Self.pTimeRemaining := Self.pTimeRemaining - InTime;
    If Self.pTimeRemaining <= 0 Then Begin

      Result := True;

      If Assigned(Self.pEvent) Then Begin
        Self.pEvent();
      End;

      If Self.pRepeating = True Then Begin
        Self.pTimeRemaining := Self.pDuration;
        Self.pActive := True;

      End Else Begin
        Self.pTimeRemaining := 0;
        Self.pActive := False;

      End;
    End;
  End;

Procedure TPGLTimer.SetEvent(sEvent: pglClockEvent);
  Begin
    Self.pEvent := sEvent;
  End;

Procedure TPGLTimer.SetDuration(sDuration: Double);
  Begin
    Self.pDuration := sDuration;
  end;

Procedure TPGLTimer.SetDuration(sDuration: TPGLTimeStruct);
  Begin
    Self.pDuration := sDuration.Seconds;
    Self.pDuration := Self.pDuration + (sDuration.Minutes * 60);
    Self.pDuration := Self.pDuration + ((sDuration.Hours * 60) * 60);
  End;

Procedure TPGLTimer.SetRepeating(sRepeat: Boolean = True);
  Begin
    Self.pRepeating := sRepeat;
  End;


Procedure TPGLTimer.UnAssign();
  Begin
    Self.pisAssigned := False;
    Self.pActive := False;
    Self.pTimeRemaining := 0;
    Self.pSignalUnAssign := True;
  End;

Procedure TPGLTimer.Activate();
  Begin
    Self.pActive := True;
    Self.pTimeRemaining := Self.pDuration;
  End;

Procedure TPGLTimer.DeActivate();
  Begin
    If Self.pisAssigned = False Then Exit;

    Self.pActive := False;
  End;

Procedure TPGLTimer.ResetTime();
  Begin
    Self.pTimeRemaining := Self.pDuration;
  End;

Function TPGLTimer.TimePassed(): TPGLTimeStruct;
  Begin
    Result.AddTime(Self.pDuration - Self.pTimeRemaining);
  End;

////////////////////////////////////////////////////////////////////////////////
                           {TPGLTimeTrigger}
////////////////////////////////////////////////////////////////////////////////

Constructor TPGLTimeTrigger.Create(sEvent: pglClockEvent; sTriggerTime: TPGLTimeStruct; sTriggerOnNow: Boolean = False);
  Begin
    Self.pEvent := sEvent;
    Self.pTriggerTime := sTriggerTime;
    Self.pTriggerOnNow := sTriggerOnNow;
  End;

Procedure TPGLTimeTrigger.Activate();
  Begin
    Self.pisActive := True;
  End;

Procedure TPGLTimeTrigger.Deactivate();
  Begin
    Self.pisActive := False;
  End;

Procedure TPGLTimeTrigger.UnAssign();
  Begin
    Self.pisActive := False;
    Self.pUnAssignSignal := True;
  End;

Function TPGLTimeTrigger.Update(sTime: TPGLTimeStruct): Boolean;
  Begin
    Result := False;

    If Self.pTriggerTime.Seconds <= sTime.Seconds Then Begin
      If Self.pTriggerTime.Minutes <= sTime.Minutes Then Begin
        If Self.pTriggerTime.Hours <= sTime.Hours Then Begin

          If Assigned(Self.pEvent) Then Begin
            Self.pEvent();
          End;

          Self.UnAssign();
        End;
      End;
    End;

  End;


////////////////////////////////////////////////////////////////////////////////
                               {Unit Initialization}
////////////////////////////////////////////////////////////////////////////////

Initialization
  Begin
    TimeInstance := TPGLTimeInstance.Create();
  End;

end.
