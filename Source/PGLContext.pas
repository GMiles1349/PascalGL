unit PGLContext;

interface

{$POINTERMATH ON}

Uses
  SysUtils, Classes, Messages, WinAPI.Windows, WinAPI.DwmApi, WinAPI.UxTheme,
  dglOpenGL, Neslib.stb.image, Neslib.stb.imagewrite, UnitXInput, Math, PGLMath;

  (* CallBack Types *)
  Type
    pglHookProc = Function(nCode: Integer; wParameter: NativeUInt; lParameter: NativeInt): LRESULT; stdcall;
    pglKeyCallBack = Procedure(Key: NativeUInt; Shift, Alt: Boolean); Register;
    pglMouseCallBack= Procedure(X,Y: Single; Button: Integer; Shift: Boolean; Alt: Boolean); Register;
    pglControllerButtonCallBack = Procedure(ButtonIndex: Byte); Register;
    pglControllerStateCallBack = Procedure(LeftStick,RightStick: TPointFloat; LeftTrigger,RightTrigger: Byte); Register;
    pglControllerStickCallBack = Procedure(LeftStick,RightStick: TPointFloat); Register;
    pglControllerStickReleaseCallBack = Procedure(LeftStick,RightStick: Byte); register;
    pglControllerTriggerCallBack = procedure(LeftTrigger, RightTrigger: Byte); register;
    pglCallBack = Procedure();
    pglWindowSizeCallBack = Procedure(X,Y,Width,Height: Integer); Register;
    pglWindowMoveCallBack = Procedure(X,Y: Integer); Register;
    pglKeyCharCallBack = Procedure(Char: String; BackSpace, Enter, Escape: Boolean); Register;
    pglDebugCallBack = Procedure(Source: GLenum; MessageType: GLenum; ID: GLuint; Severity: GLenum; MessageLength: GLsizei; const DebugMessage: PAnsiChar; const UserParam: Pointer); stdcall;


  (* Helper Types *)
  Type StringHelper = Record Helper for String
    Procedure Add(Val: String); Register;
  End;

  (* Structs *)

  type TPGLAttribs = Record

    Public
      Count: GLInt;
      Attribs: Array of GLInt;

      Class Operator Initialize(Out Dest: TPGLAttribs);
      Procedure AddAttribs(Values: Array of GLInt);
  End;

  Type TPGLWindowFormat = Record
      ColorBits: GLUint;
      DepthBits: GLUInt;
      StencilBits: GLUInt;
      Samples: GLUInt;
      VSync: GLBoolean;
      BufferCopy: GLBoolean;
      FullScreen: GLBoolean;
      TitleBar: Boolean;
      Maximize: Boolean;

      Class Operator Initialize( Out Dest: TPGLWindowFormat); Register;
  End;

  Type PPGLWindowFormat = ^TPGLWindowFormat;

  Type TPGLFeatureSettings = Record
    UseKeyBoardInput: Boolean;
    UseCharacterInput: Boolean;
    UseMouseInput: Boolean;
    UseController: Boolean;
    OpenGLMajorVersion: GLInt;
    OpenGLMinorVersion: GLint;
    OpenGLCompatibilityContext: Boolean;
    OpenGLDebugContext: Boolean;

    Class Operator Initialize (Out Dest: TPGLFeatureSettings); Register;
  End;

  Type PPGLFeatureSettings = ^TPGLFeatureSettings;


  (* Classes *)

  Type TPGLIcon = Record
    Private
      wIcon: HICON;
      wWidth,wHeight: GLUint;
      wHotSpot: TPOINT;

    Public

      Property Icon: HICON read wIcon;
      Property Width: GLUint read wWidth;
      Property Height: GLUint read wHeight;
      Property HotSpot: TPOINT read wHotSpot;

      Procedure SetTransparent(Color: WORD); Register;
      Procedure ChangeHotSpot(HotSpotX, HotSpotY: GLUint); Register;
      Procedure ChangeSize(Width,Height: GLUint); Register;
      Function Destroy(): Boolean; Register;
  End;

  Type TPGLKeyboard = Class(TObject)
    Private
      KeyDown: pglKeyCallBack;
      KeyUp: pglKeyCallBack;
      KeyPress: pglKeyCallBack;
      KeyHeld: pglKeyCallBack;
      CharCallBack: pglKeyCharCallBack;

      Key: Array [0..255] of Integer;
      wShift: Boolean;
      wAlt: Boolean;
      wCharCount: GLUInt;
      wWaitChars: String;
      wChars: String;

      Function GetKeyState(Index: Integer): Integer; Register;
      Procedure SwapChars(); Register;
      Function GetChars(): String; Register;

    Public

      Property Shift: Boolean read wShift;
      Property Alt: Boolean read wAlt;
      Property KeyState[Index: Integer]: Integer read GetKeyState;
      Property Chars: String read GetChars;

      Constructor Create();

      Function CheckKeyCombo(Keys: Array of NativeInt): Boolean ; Register;

      Procedure SendKeyPress(Key: NativeUInt); Register;
      Procedure SendKeyDown(Key: NativeUInt); Register;
      Procedure SendKeyUp(Key: NativeUInt); Register;
      Procedure RegisterKeyDownCallBack(Proc: pglKeyCallBack); Register;
      Procedure RegisterKeyUpCallBack(Proc: pglKeyCallBack); Register;
      Procedure RegisterKeyPressCallBack(Proc: pglKeyCallBack); Register;
      Procedure RegisterKeyHeldCallBack(Proc: pglKeyCallBack); Register;
      Procedure RegisterKeyCharCallBack(Proc: pglKeyCharCallBack); Register;

  End;

  Type TPGLMouse = Class(TObject)
    Private
      MouseDownCallBack: pglMouseCallBack;
      MouseHeldCallBack: pglMouseCallBack;
      MouseUpCallBack: pglMouseCallBack;
      MouseMoveCallBack: pglMouseCallBack;
      LeaveCallBack: pglCallBack;
      EnterCallBack: pglCallBack;
      DebugCallBack: pglDebugCallBack;

      wX,wY: Single;
      wLastX, wLastY: Single;
      wDistX, wDistY: Single;
      wDistance: Single;
      wScreenX, wScreenY: Single;
      wLastScreenX, wLastScreenY: Single;
      wLockX, wLockY: Single;
      wLocked: Boolean;
      wVisible: Boolean;
      wButton: Array [0..4] of Integer;
      wButtonHeldCount: Array [0..4] of Integer;
      wInWindow: Boolean;
      wScale: Boolean;

      Cursor: HICON;
      IconSource: ^TPGLIcon;

      Procedure ReturnToLock(); Register;

    Public
      Property X: Single read wX;
      Property Y: Single read wY;
      Property LastX: Single read wLastX;
      Property LastY: Single read wLastY;
      Property DistX: Single read wDistX;
      Property DistY: Single read wDistY;
      Property Distance: Single read wDistance;
      Property Visible: Boolean read wVisible;
      Property ScreenX: Single read wScreenX;
      Property LockX: Single read wLockX;
      Property LockY: Single read wLockY;
      Property Locked: Boolean read wLocked;
      Property ScreenY: Single read wScreenY;
      Property Button0: Integer read wButton[0];
      Property Button1: Integer read wButton[1];
      Property Button2: Integer read wButton[2];
      Property Button3: Integer read wButton[3];
      Property Button4: Integer read wButton[4];
      Property Button0HeldCount: Integer read wButtonHeldCount[0];
      Property Button1HeldCount: Integer read wButtonHeldCount[1];
      Property Button2HeldCount: Integer read wButtonHeldCount[2];
      Property Button3HeldCount: Integer read wButtonHeldCount[3];
      Property Button4HeldCount: Integer read wButtonHeldCount[4];


//      Class Operator Initialize(Out Dest: TPGLMouse); Register;
      Constructor Create();

      Procedure SetVisible(Enable: Boolean = True); Register;
      Procedure MovePosition(X,Y: Single); Register;
      Procedure SetPosition(X,Y: Single); Register;
      Procedure SendButtonClick(ButtonIndex: Byte); Register;
      Procedure ReleaseButton(ButtonIndex: Byte); Register;
      Procedure SetMouseLock(X,Y: Single; Locked: Boolean = True); Register;
      Procedure SetCursorFromFile(FileName: String; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0); Register;
      Procedure SetCursorFromBits(Source: Pointer; Width,Height,BPP: GLUint; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0); Register;
      Procedure SetCursorFromIcon(Var Source: TPGLIcon); Register;
      Procedure ScaleToResolution(Enable: Boolean = True); Register;

      Procedure RegisterLeaveCallBack(Proc: pglCallBack); Register;
      Procedure RegisterEnterCallBack(Proc: pglCallBack); Register;
      Procedure RegisterMouseDownCallBack(Proc: pglMouseCallBack); Register;
      Procedure RegisterMouseHeldCallBack(Proc: pglMouseCallBack); Register;
      Procedure RegisterMouseUpCallBack(Proc: pglMouseCallBack); Register;
      Procedure RegisterMouseMoveCallBack(Proc: pglMouseCallBack); Register;

      Function InWindow(): Boolean; Register;
  End;


  Type TPGLController = Class(TObject)

    Type
      PPGLControllerButton = ^TPGLControllerButton;
      TPGLControllerButton = Record
        ButtonIndex: Byte;
        Name: AnsiString;
        State: Byte;
        LastState: Byte;
    End;

    Private
      Enabled: Boolean;
      Connected: Array [0..3] of Boolean;
      State: TXInputState;
      BatteryState: TXInputBatteryInformation;
      wBatteryLevel: Single;
      DeviceType: Byte;

      LSX,LSY,RSX,RSY: ^Int16;
      wLeftStick,wRightStick: TPointFloat;
      wLastLeftStick, wLastRightStick: TPointFloat;
      wLeftTrigger, wRightTrigger: Byte;
      wLastLeftTrigger, wLastRightTrigger: Byte;
      LSDeadZone,RSDeadZone: DWORD;

      fButtons: Array [0..15] of TPGLControllerButton;
      wA,wB,wX,wY,wLeft,wRight,wUp,wDown,wStart,wBack: PPGLControllerButton;
      wLeftBumper, wRightBumper, wLeftStickButton, wRightStickButton: PPGLControllerButton;

      ButtonDownCallBack: pglControllerButtonCallBack;
      ButtonUpCallBack: pglControllerButtonCallBack;
      StateChangeCallBack: pglControllerStateCallBack;
      StickCallBack: pglControllerStickCallBack;
      StickReleaseCallBack: pglControllerStickReleaseCallBack;
      TriggerCallBack: pglControllerTriggerCallBack;

      Procedure HandleStateChange(sender:TObject;userIndex:uint32;newState:TXInputState);
      Procedure HandleConnect(sender:TObject;userIndex:uint32);
      Procedure HandleDisconnect(sender:TObject;userIndex:uint32);
      Procedure HandleButtonDown(sender:TObject;userIndex:uint32;buttons:word);
      Procedure HandleButtonUp(sender:TObject;userIndex:uint32;buttons:word);
      Procedure HandleButtonPress(sender:TObject;userIndex:uint32;buttons:word);
      Procedure HandleStickHeld();
      Procedure QueryState();

      Function GetButton(I: Integer): TPGLControllerButton;

    Public

      Property Buttons[Index: Integer]: TPGLControllerButton read GetButton;
      Property AButton: PPGLControllerButton read wA;
      Property BButton: PPGLControllerButton read wB;
      Property XButton: PPGLControllerButton read wX;
      Property YButton: PPGLControllerButton read wY;
      Property LeftButton: PPGLControllerButton read wLeft;
      Property RightButton: PPGLControllerButton read wRight;
      Property UpButton: PPGLControllerButton read wUp;
      Property DownButton: PPGLControllerButton read wDown;
      Property StartButton: PPGLControllerButton read wStart;
      Property BackButton: PPGLControllerButton read wBack;
      Property LeftBumper: PPGLControllerButton read wLeftBumper;
      Property RightBumper: PPGLControllerButton read wRightBumper;
      Property LeftStickButton: PPGLControllerButton read wLeftStickButton;
      Property RightStickbutton: PPGLControllerButton read wRightStickButton;
      Property LeftStick: TPointFloat read wLeftStick;
      Property RightStick: TPointFloat read wRightStick;
      Property LeftTrigger: Byte read wLeftTrigger;
      Property RightTrigger: Byte read wRightTrigger;
      Property BatteryLevel: Single read wBatteryLevel;

      Constructor Create();
      Procedure RegisterButtonDownCallBack(Proc: pglControllerButtonCallBack);
      Procedure RegisterButtonUpCallBack(Proc: pglControllerButtonCallBack);
      Procedure RegisterStateChangeCallBack(Proc: pglControllerStateCallBack);
      Procedure RegisterStickHeldCallBack(Proc: pglControllerStickCallBack);
      Procedure RegisterStickReleaseCallBack(Proc: pglControllerStickReleaseCallBack);
      Procedure RegisterTriggerCallBack(Proc: pglControllerTriggerCallBack);

  End;


  Type TPGLContext = Class(TObject)

    Private

      // Attributes and flags
      IsReady: Boolean;
      wUpdating: Boolean;
      wHandle: HWND;
      wDC: HDC;
      wMajVersion: GLInt;
      wMinVersion: GLint;
      wMultiSampled: Boolean;
      wFeatures: TPGLFeatureSettings;
      wDebugToConsole: Boolean;
      wDebugToLog: Boolean;
      wDebugToMsgBox: Boolean;
      wBreakOnDebug: Boolean;
      wDebugLog: Array of String;
      wDebugCount: Integer;
      wIgnoreDebug: Boolean;
      wIcon: HICON;
      wTitle: String;
      wMessageList: Array of Cardinal;
      wSizeChanged: Boolean;
      wDispChanging: Boolean;

      // Dimensions
      wWidth: GLUint;
      wHeight: GLUint;
      wMinWidth, wMinHeight: GLUInt;
      wX,wY: GLUint;
      wReturnX, wReturnY: GLUint;
      wCenterX, wCenterY: GLUint;
      wDPIX,wDPIY,wDPIScaleX,wDPIScaleY: GLInt;
      wWindowRect: TRECT;
      wClientRect: TRECT;
      wWindowRgn: HRGN;
      wMargins: TMargins;
      wBorderWidth: GLUint;
      wTitleBarHeight: GLUint;
      wShouldClose: Boolean;
      wNativeScreenWidth,wNativeScreenHeight: GLUInt;
      wScreenWidth, wScreenHeight: GLUint;
      wHasStencil: Boolean;
      wHasDepth: Boolean;
      wFormat: TPGLWindowFormat;

      // Status
      wIsMaxed: Boolean;
      wIsMinimized: Boolean;
      wHasCaption: Boolean;
      wHasMenu: Boolean;
      wHasMinimize: Boolean;
      wHasMaximize: Boolean;
      wCanSize: Boolean;
      wWin7Frame: Boolean;
      wFullScreen: Boolean;
      wHasFocus: Boolean;
      wStyleChanged: Boolean;

      // Message Flags
      wLBUTTONDOWN: Integer;
      wRBUTTONDOWN: Integer;
      wXBUTTONDOWN: Array [2..4] of Integer;

      // Functionality Flags
      wKeyBoard: TPGLKeyboard;
      wMouse: TPGLMouse;
      wController: TPGLController;
      wUseKeyInput: Boolean;
      wUseCharacterInput: Boolean;
      wUseMouseInput: Boolean;
      wUseController: Boolean;
      wNumDevices: PUINT;
      wDevicesSize: UINT;


      // Callbacks
      SizeCallBack: pglWindowSizeCallBack;
      MoveCallBack: pglWindowMoveCallBack;
      MaximizeCallBack: pglCallBack;
      MinimizeCallBack: pglCallBack;
      RestoreCallBack: pglCallBack;
      GotFocusCallBack: pglCallBack;
      LostFocusCallBack: pglCallBack;
      CloseCallBack: pglCallBack;

      OrgDevMode: DevMode;
      CurDevMode: DevMode;

      Procedure GetInputDevices(); Register;
      Procedure UpdateRects(); Register;
      Procedure RestoreStyleFlags(); Register;
      Procedure CleanUp(); Register;
      Function ProcessKeyBoardMessages(Var Handle: HWND; Var Messages: Cardinal; Var wParameter: WPARAM; Var lParameter: LPARAM): LRESULT;
      Function ProcessMouseMessages(Var Handle: HWND; Var Messages: Cardinal; Var wParameter: WPARAM; Var lParameter: LPARAM): LRESULT;
      Procedure CheckMouseHeld(); register;
      Function ProcessCharMessages(Var Handle: HWND; Var Messages: Cardinal; Var wParameter: WPARAM; Var lParameter: LPARAM): LRESULT;

    Public

      Property Handle: HWND read wHandle;
      Property DC: HDC read wDC;
      Property MajorVersion: GLInt read wMajVersion;
      Property MinorVersion: GLInt read wMinVersion;
      Property Title: String read wTitle;
      Property Width: GLUint read wWidth;
      Property Height: GLUint read wHeight;
      Property MinWidth: GLUint read wMinWidth;
      Property MinHeight: GLUint read wMinHeight;
      Property ClientRect: TRect read wClientRect;
      Property WindowRect: TRect read wWindowRect;
      Property X: GLUint read wX;
      Property Y: GLUint read wY;
      Property CenterX: GLUint read wCenterX;
      Property CenterY: GLUint read wCenterY;
      Property DPIX: GLInt read wDPIX;
      Property DPIY: GLInt read wDPIY;
      Property DPIScaleX: GLInt read wDPIScaleX;
      Property DPIScaleY: GLInt read wDPIScaleY;
      Property ShouldClose: Boolean read wShouldClose;
      Property ScreenWidth: GLUint read wScreenWidth;
      Property ScreenHeight: GLUint read wScreenHeight;
      Property NativeScreenWidth: GLUint read wNativeScreenWidth;
      Property NativeScreenHeight: GLUint read wNativeScreenHeight;
      Property Format: TPGLWindowFormat read wFormat;
      Property Settings: TPGLFeatureSettings read wFeatures;
      Property IsMaxed: Boolean read wIsMaxed;
      Property IsMinimized: Boolean read wIsMinimized;
      Property HasCaption: Boolean read wHasCaption;
      Property HasMenu: Boolean read wHasMenu;
      Property HasMinimize: Boolean read wHasMinimize;
      Property HasMaximize: Boolean read wHasMaximize;
      Property CanSize: Boolean read wCanSize;
      Property Win7Frame: Boolean read wWin7Frame;
      Property FullScreen: Boolean read wFullScreen;
      Property Margins: TMargins read wMargins;
      Property DebugLogMessageCount: GLInt read wDebugCount;
      Property DebugToConsole: Boolean read wDebugToConsole;
      property IgnoreDebug: Boolean read wIgnoreDebug;
      Property Keyboard: TPGLKeyboard read wKeyBoard;
      Property Mouse: TPGLMouse read wMouse;
      Property Controller: TPGLController read wController;
      Property UseController: Boolean read wUseController;
      Property DisplayMode: DEVMODE read CurDevMode;

      Constructor Create();

      Procedure PollEvents(); Register;
      Procedure Close(); Register;
      Procedure SetTitle(Text: String); Register;
      Procedure SetIconFromFile(FileName: String); Register;
      Procedure SetIconFromBits(Source: Pointer; Width,Height,BPP: GLUint); Register;
      Procedure SetPosition(X,Y: GLUint); Register;
      function SetSize(W,H: GLInt; KeepCentered: Boolean = True): Boolean; Register;
      Procedure Maximize(); Register;
      Procedure Restore(); Register;
      Procedure Minimize(); Register;
      Procedure SetHasCaption(Enable: Boolean = True); Register;
      Procedure SetHasMenu(Enable: Boolean = True); Register;
      Procedure SetHasMaximize(Enable: Boolean = True); Register;
      Procedure SetHasMinimize(Enable: Boolean = True); Register;
      Procedure SetCanSize(Enable: Boolean = True); Register;
      Procedure SetWin7Frame(Enable: Boolean = True); Register;
      Procedure SetFullScreen(Enable: Boolean = True); Register;
      function TestResolution(ATestRes: TPOINT): Boolean; register;
      function ChangeResolution(ANewRes: TPOINT): Boolean; register;

      Procedure RegisterSizeCallBack(Proc: pglWindowSizeCallBack); Register;
      Procedure RegisterMoveCallBack(Proc: pglWindowMoveCallBack); Register;
      Procedure RegisterMaximizeCallBack(Proc: pglCallBack); Register;
      Procedure RegisterMinimizeCallBack(Proc: pglCallBack); Register;
      Procedure RegisterRestoreCallBack(Proc: pglCallBack); Register;
      Procedure RegisterGotFocusCallBack(Proc: pglCallBack); Register;
      Procedure RegisterLostFocusCallBack(Proc: pglCallBack); Register;
      Procedure RegisterDebugCallBack(Proc: TglDebugProc); Register;
      Procedure RegisterWindowCloseCallBack(Proc: pglCallBack); Register;

      Procedure SetDebugToConsole(); Register;
      Procedure SetDebugToLog(); Register;
      Procedure SetDebugToMsgBox(); Register;
      Procedure SetBreakOnDebug(Enable: Boolean); Register;
      Procedure GetDebugLog(Out Buffer: Array of String);
      Procedure SetIgnoreDebug(AIgnore: Boolean = True); register;
      Procedure GetDisplayModes(out ADisplayList: TArray<TPoint>); register;

  end;


  (* HELPERS *)

  type TPointFloatHelper = record helper for TPointFloat
    public
      class operator NotEqual(A,B: TPointFloat): Boolean; register; inline;
  end;

  (* PROCEDURES *)

  Procedure pglStart(Width,Height: GLUint; Format: TPGLWindowFormat; Features: TPGLFeatureSettings; Title: String); stdcall; cdecl;
  Procedure CreateGLContext(); Register;
  Procedure CheckGLStatus(); Register;
  Function WindowProc(Handle: HWND; Messages: Cardinal; wParameter: WPARAM; lParameter: LPARAM): LRESULT; cdecl; stdcall;
  Procedure CreateDebugMessage(AMessage: String); register;
  Procedure Debug(Source: GLenum; MessageType: GLenum; ID: GLuint; Severity: GLUint; MessageLength: GLsizei; const DebugMessage: PGLCHar; const UserParam: PGLVoid); stdcall;
  Procedure ReturnDisplayMode(); Register;
  procedure CreateDEVMODE(out ADEVMODE: DEVMODE; AWidth,AHeight: NativeUInt); register;

  Function ReturnPFDFlags(): Integer; Register;
  Function ReturnARBPixelFormat(): TPGLAttribs; Register;
  function ConstructContextAttributes(Maj,Min: Integer): HGLRC; Register;
  Procedure UpdatePixelFormat(DC: HDC; PixelID: Integer); Register;

  Procedure GetKeyDown(Var Value: wParam); Register;
  Procedure GetKeyUp(Var Value: wParam); Register;


  Function pglCreateIcon(SourceIcon: HICON): TPGLIcon; Register;
  Function pglCreateIconFromFile(FileName: String; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0): TPGLIcon; Register;
  Function pglCreateIconFromPointer(Source: Pointer; Width,Height,BPP: GLUInt; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0): TPGLIcon; Register;

  function GET_X_LPARAM(lParam: NativeInt): Integer;
  function GET_Y_LPARAM(lParam: NativeInt): Integer;
  Function StringAdd(Source: String; Val: String): String ; Register;
  Procedure SetBit(Var TargetByte: Byte; Value: Byte; Index: Byte); Register;
  Function ReadBit(Var TargetByte: Byte; Index: Byte): Byte; Register;
  Function GetBitValue(Index: Byte): Long; Register; Inline;
  Function ClampToDeadZone(Value,DeadZone: Integer): Single;



Var
  Context: TPGLContext;
  EXEPath: String;
  RDC: HGLRC;
  WC: WNDCLASSEX;
  Freq: Int64;
  Intime: Int64;
  CurrentTime, LastTime, CycleTime, TargetTime: Double;
  Frames: Long;
  FrameTime: Double;
  FPS: Double;

Const
  USE_WNDPROC = 0;
  USE_HOOK = 1;
  screen_width = 1001;
  screen_height = 1002;


implementation


Uses
  PGLMain;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
(*                              Types and Structs                             *)
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

(*------------------------------String Helper---------------------------------*)

Procedure StringHelper.Add(Val: string);
  Begin
    Self := Self + StringAdd(Self,Val);
  End;


(*------------------------------TPGLAttribs------------------------------------*)

Class Operator TPGLAttribs.Initialize(Out Dest: TPGLAttribs);
  Begin
    Dest.Count := 0;
  End;

Procedure TPGLAttribs.AddAttribs(Values: Array of GLint);
Var
I: LongInt;
  Begin
    for I := 0 to High(Values) Do Begin
      SetLength(Self.Attribs,Length(Self.Attribs) + 1);
      Inc(Self.Count);
      Self.Attribs[Self.Count - 1] := Values[i];
    End;
  End;

(*------------------------------TPGLWindowFormat-------------------------------*)

Class Operator TPGLWindowFormat.Initialize( Out Dest: TPGLWindowFormat); Register;
  Begin
    Dest.ColorBits := 32;
    Dest.DepthBits := 24;
    Dest.StencilBits := 8;
    Dest.Samples := 24;
    Dest.VSync := False;
    Dest.BufferCopy := True;
    Dest.FullScreen := False;
    Dest.TitleBar := False;
    Dest.Maximize := False;
  End;

(*------------------------------TPGLFeatureSettings----------------------------*)

Class Operator TPGLFeatureSettings.Initialize( Out Dest: TPGLFeatureSettings);
  Begin
    Dest.UseKeyBoardInput := True;
    Dest.UseCharacterInput := False;
    Dest.UseMouseInput := True;
    Dest.UseController := False;
    Dest.OpenGLMajorVersion := 4;
    Dest.OpenGLMinorVersion := 6;
    Dest.OpenGLCompatibilityContext := True;
    Dest.OpenGLDebugContext := False;
  End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
(*                          Classes and Tangibles                             *)
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


Procedure TPGLIcon.SetTransparent(Color: WORD);
Var
ICINFO: ICONINFO;
NEWICON: ICONINFO;
BMap: HBITMAP;
MMAP: HBITMAP;
BM: BITMAP;
BITINFO: tagBITMAPINFO;
Bits: Array of Byte;
CheckBits: Array [0..3] of Byte;
CheckColor: WORD;
DC: HDC;
OldBitMap: HGDIOBJ;
RetVal: integer;
ErrorVar: Cardinal;
Pos: Integer;
I,Z: Integer;

  Begin

    DC := CreateCompatibleDC(0);

    GetIconInfo(Self.Icon,ICINFO);
    GetObject(ICINFO.hbmColor,SizeOf(BM),@BM);

    BMAP := CopyImage(ICINFO.hbmColor,IMAGE_BITMAP,BM.bmWidth,BM.bmHeight,LR_DEFAULTSIZE);
    MMAP := CopyImage(ICINFO.hbmColor,IMAGE_BITMAP,BM.bmWidth,BM.bmHeight,LR_DEFAULTSIZE);

    ZeroMemory(@BITINFO,SizeOf(BITINFO));
    BITINFO.bmiHeader.biSize := SizeOf(BITINFO);
    BITINFO.bmiHeader.biWidth := BM.bmWidth;
    BITINFO.bmiHeader.biHeight := BM.bmHeight;
    BITINFO.bmiHeader.biPlanes := 1;
    BITINFO.bmiHeader.biBitCount := 32;
    BITINFO.bmiHeader.biCompression := BI_RGB;

    SetLength(Bits, 4 * (BM.bmWidth * BM.bmHeight));
    RetVal := GetDIBits(DC,BMAP,0,BM.bmHeight,Bits,BITINFO,DIB_RGB_COLORS);

    Pos := 0;

    for I := 0 to (BM.bmWidth * BM.bmHeight) -1 Do Begin

      Move(Bits[I*4], CheckBits[0], 4);
      CheckColor := MAKEWPARAM(MAKEWORD(CheckBits[0],CheckBits[1]), MAKEWORD(CheckBits[2],CheckBits[3]));

      If CheckColor = Color Then Begin
        CheckBits[0] := 0;
        CheckBits[1] := 0;
        CheckBits[2] := 0;
        CheckBits[3] := 0;

      End Else Begin

        CheckBits[3] := 255;

      End;

       Move(CheckBits[0],Bits[I*4],4);

    End;

    RetVal := SetDIBIts(DC,BMAP,0,BM.bmHeight,Bits,BITINFO,DIB_RGB_COLORS);

    NEWICON.fIcon := False;
    NEWICON.xHotspot := ICINFO.xHotspot;
    NEWICON.yHotspot := ICINFO.yHotspot;
    NEWICON.hbmMask := BMAP;
    NEWICON.hbmColor := BMAP;

    DestroyIcon(Self.Icon);
    Self.wIcon := CreateIconIndirect(NEWICON);

    DeleteObject(BMAP);
    DeleteObject(MMAP);
    DeleteDC(DC);
  end;


Procedure TPGLIcon.ChangeHotSpot(HotSpotX: Cardinal; HotSpotY: Cardinal);
Var
ICINFO: ICONINFO;
NEWICON: ICONINFO;
BMap: HBITMAP;
MMAP: HBITMAP;
BM: BITMAP;

  Begin

    GetIconInfo(Self.Icon,ICINFO);
    GetObject(ICINFO.hbmColor,SizeOf(BM),@BM);

    BMAP := CopyImage(ICINFO.hbmColor,IMAGE_BITMAP,BM.bmWidth,BM.bmHeight,LR_DEFAULTSIZE);
    MMAP := CopyImage(ICINFO.hbmColor,IMAGE_BITMAP,BM.bmWidth,BM.bmHeight,LR_DEFAULTSIZE);

    NEWICON.fIcon := False;
    NEWICON.xHotspot := HotSpotX;
    NEWICON.yHotspot := HotSpotY;
    NEWICON.hbmMask := MMAP;
    NEWICON.hbmColor := BMAP;

    DestroyIcon(Self.Icon);
    Self.wIcon := CreateIconIndirect(NEWICON);

    DeleteObject(BMAP);
    DeleteObject(MMAP);

  End;


Procedure TPGLIcon.ChangeSize(Width: Cardinal; Height: Cardinal);
Var
ICINFO: ICONINFO;
NEWICON: ICONINFO;
BMap: HBITMAP;
MMAP: HBITMAP;
BM: BITMAP;

  Begin

    GetIconInfo(Self.Icon,ICINFO);
    GetObject(ICINFO.hbmColor,SizeOf(BM),@BM);

    BMAP := CopyImage(ICINFO.hbmColor,IMAGE_BITMAP,Width,Height,LR_DEFAULTSIZE);
    MMAP := CopyImage(ICINFO.hbmColor,IMAGE_BITMAP,Width,Height,LR_DEFAULTSIZE);

    NEWICON.fIcon := False;
    NEWICON.xHotspot := ICINFO.xHotspot;
    NEWICON.yHotspot := ICINFO.yHotspot;
    NEWICON.hbmMask := MMAP;
    NEWICON.hbmColor := BMAP;

    DestroyIcon(Self.Icon);
    Self.wIcon := CreateIconIndirect(NEWICON);

    DeleteObject(BMAP);
    DeleteObject(MMAP);
  End;


Function TPGLIcon.Destroy(): Boolean;
  Begin
    Result := False;
    Result := DestroyIcon(Self.wIcon);

    If Result = True Then Begin
      Self.wIcon := 0;
      Self.wWidth := 0;
      Self.wHeight := 0;
      Self.wHotSpot := POINT(0,0);

    End Else Begin

      If Context.Mouse.IconSource = @Self Then Begin

        // (RETURN TO) Context.Mouse.IconSource := nil;
        SetCursor(LOADCURSOR(0,IDC_ARROW));
        Self.Destroy();

      End;

    End;

  End;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
(*                          TPGLKeyboard                               *)
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


Constructor TPGLKeyboard.Create();
  Begin
    Inherited;
  End;

Function TPGLKeyboard.GetKeyState(Index: Integer): Integer;
  Begin
    Result := Context.KeyBoard.Key[Index];
  End;

Procedure TPGLKeyboard.SwapChars();
Var
I: Long;
  Begin
    Self.wChars := '';
    SetLength(Self.wChars,0);

    If Self.wCharCount = 0 Then Exit;

    Self.wChars := Self.wWaitChars;
    Self.wWaitChars := '';
    SetLength(Self.wWaitChars,0);
    Self.wCharCount := 0;
  End;

Function TPGLKeyboard.CheckKeyCombo(Keys: array of NativeInt): Boolean; Register;
Var
FoundCount: Long;
KeyVals: Array of NativeInt;
I: Long;

  Begin

    Result := False;

    If Length(Keys) < 2 Then Exit;

    SetLength(KeyVals, Length(Keys));
    FoundCount := 0;

    For I := 0 to Length(Keys) - 1 Do Begin

      KeyVals[i] := GetKeyState(Keys[i]);

      If KeyVals[i] = 1 Then Begin
        FoundCount := FoundCount + 1;
      End;

    End;

    If FoundCount = Length(Keys) Then Begin
      Result := True;
    End;
  End;

Function TPGLKeyboard.GetChars(): String;
  Begin
    Result := Self.wChars;
  End;

Procedure TPGLKeyboard.SendKeyPress(Key: NativeUInt);
  Begin
    if Assigned(Self.KeyPress) = False then Exit;

    If Key < 256 Then Begin
      Self.KeyPress(Key,Self.Shift,Self.Alt);
    End;
  End;

Procedure TPGLKeyboard.SendKeyDown(Key: NativeUInt);
  Begin
    if Assigned(Self.KeyDown) = False then Exit;

    If Key < 256 Then Begin
      Self.KeyDown(Key,Self.Shift,Self.Alt);
    End;
  End;

Procedure TPGLKeyboard.SendKeyUp(Key: NativeUInt);
  Begin
    if Assigned(Self.KeyUp) = False then Exit;

    If Key < 256 Then Begin
      Self.KeyUp(Key,Self.Shift,Self.Alt);
    End;
  End;

Procedure TPGLKeyboard.RegisterKeyDownCallBack(Proc: pglKeyCallBack);
  Begin
    If Context.wFeatures.UseKeyBoardInput = False Then Exit;
    Self.KeyDown := Proc;
  End;

Procedure TPGLKeyboard.RegisterKeyPressCallBack(Proc: pglKeyCallBack);
  Begin
    If Context.wFeatures.UseKeyBoardInput = False Then Exit;
    Self.KeyPress := Proc;
  End;

Procedure TPGLKeyboard.RegisterKeyHeldCallBack(Proc: pglKeyCallBack);
  Begin
    If Context.wFeatures.UseKeyBoardInput = False Then Exit;
    Self.KeyHeld := Proc;
  End;

Procedure TPGLKeyboard.RegisterKeyUpCallBack(Proc: pglKeyCallBack);
  Begin
    If Context.wFeatures.UseKeyBoardInput = False Then Exit;
    Self.KeyUp := Proc;
  End;

Procedure TPGLKeyboard.RegisterKeyCharCallBack(Proc: pglKeyCharCallBack);
  Begin
    If Context.wFeatures.UseCharacterInput = False Then Exit;
    Self.CharCallBack := Proc;
  End;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
(*                          TPGLMouse                                  *)
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


//Class Operator TPGLMouse.Initialize(Out Dest: TPGLMouse);
//  Begin
//    Dest.wVisible := True;
//    Dest.wInWindow := True;
//  End;

Constructor TPGLMouse.Create();
  Begin
    Self.wVisible := True;
    Self.wInWindow := True;
  End;

Procedure TPGLMouse.SetVisible(Enable: Boolean = True);
  Begin

    If Enable = Self.Visible Then Exit;

    If Enable = True Then Begin
      Self.wVisible := True;
      ShowCursor(true);
    End Else Begin
      Self.wVisible := False;
      ShowCursor(False);
    End;

  End;


Procedure TPGLMouse.MovePosition(X,Y: Single);
// Move the mouse position by X and Y
Var
wParVal: wParam;
XVal,YVal: Word;
  Begin

    wParVal := 0;
    If Self.Button0 <> 0 Then Begin
      wParVal := wParVal or MK_LBUTTON;
    End;

    If Self.Button1 <> 0 Then Begin
      wParVal := wParVal or MK_RBUTTON;
    End;

    XVal := trunc(Self.wX + X);
    YVal := trunc(Self.wY + Y);
    PostMessage(Context.Handle,WM_MOUSEMOVE,wParVal, MakeLParam(XVal,YVal));
  End;

Procedure TPGLMouse.SetPosition(X: Single; Y: Single);
// Set the mouse position to X and Y
Var
CP: TPOINT;
  Begin
    CP := Point(trunc(X), trunc(Y));
    ClientToScreen(Context.Handle, CP);
    Self.wX := trunc(X);
    Self.wY := trunc(Y);
    SetCursorPos(CP.X, CP.Y);
  End;

Procedure TPGLMouse.SendButtonClick(ButtonIndex: Byte);
//Use to send a button down callback without changing the value of the mouse button
  Begin
    If ButtonIndex < 4 Then Begin
      If Self.wButton[ButtonIndex] <> 1 Then Begin
        Self.MouseDownCallBack(Self.wX, Self.wY, ButtonIndex, Context.wKeyBoard.Shift, Context.wKeyBoard.Alt);
      End;
    End;
  End;

Procedure TPGLMouse.ReleaseButton(ButtonIndex: Byte);
//Use to send a button up callback without changing the value of the mouse button
  Begin
    If ButtonIndex < 4 Then Begin
      If Self.wButton[ButtonIndex] <> 1 Then Begin
        Self.MouseUpCallBack(Self.wX, Self.wY, ButtonIndex, Context.wKeyBoard.Shift, Context.wKeyBoard.Alt);
      End;
    End;
  End;

Function TPGLMouse.InWindow(): Boolean;
  Begin

    If wScreenX >= Context.wWindowRect.Left Then Begin
      If wScreenX <= Context.wWindowRect.Right Then Begin
        If wScreenY >= Context.wWindowRect.Top Then Begin
          If wScreenY <= Context.wWindowRect.Bottom Then Begin

            Result := True;

            If Assigned(Self.EnterCallBack) Then Begin
              If Self.wInWindow = False Then Begin
                Self.wInWindow := True;
                SetCursor(Self.Cursor);
                Self.EnterCallBack();
              End;
            End;

            Self.wInWindow := True;
            Exit;

          End;
        End;
      End;
    End;

    Result := False;

    If Assigned(Self.LeaveCallBack) Then Begin
      If Self.wInWindow = True Then Begin
        Self.wInWindow := False;
        Self.LeaveCallBack();
      End;
    End;

    Self.wInWindow := False;

  End;

Procedure TPGLMouse.SetMouseLock(X: Single; Y: Single; Locked: Boolean = True);
Var
MP: TPOINT;
  Begin
    Self.wLocked := Locked;
    Self.wLockX := trunc(X);
    Self.wLocky := trunc(Y);

    If Locked = True Then Begin
      Self.SetPosition(X,Y);
    End;
  End;

Procedure TPGLMouse.ReturnToLock();
Var
MP: TPOINT;
  Begin
    Self.SetPosition(Self.wLockX, Self.wLockY);
  End;

Procedure TPGLMouse.SetCursorFromFile(FileName: String; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0);
Var
Image: Pointer;
Width,Height,Channels: GLInt;
  Begin
    Image := stbi_load(PansiChar(AnsiString(FileName)),Width,Height,Channels,4);
    Self.SetCursorFromBits(Image,Width,Height,32, HotSpotX, HotSpotY);
    stbi_image_free(Image);
  End;


Procedure TPGLMouse.SetCursorFromBits(Source: Pointer; Width,Height,BPP: GLUint; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0);
Var
IconStruct: _ICONINFO;
Icon: HICON;
BitMap: HBITMAP;
I,Z: Longint;
SrcPtr: PByte;
UseBytes: Array of Byte;
TempRed, TempBlue: Byte;
MaskPos: Integer;
BitInfo: tagBITMAP;
UseLen: GLInt;

  Begin

    UseLen := trunc(BPP / 8);
    SrcPtr := Source;
    SetLength(UseBytes,UseLen);
    MaskPos := 0;

    For I := 0 to (Width * Height) Do Begin

      Move(SrcPtr[MaskPos],UseBytes[0],UseLen);

      // Swap blue and red bytes
      TempRed := UseBytes[2];
      TempBlue := Usebytes[0];
      UseBytes[0] := TempRed;
      UseBytes[2] := TempBlue;

      If (UseBytes[0] = 255) And
         (UseBytes[1] = 255) And
         (UseBytes[2] = 255) Then Begin

         For z := 0 to UseLen - 1 Do Begin
          UseBytes[z] := 0;
         End;

      End;

      Move(Usebytes[0],SrcPtr[MaskPos],UseLen);

      MaskPos := MaskPos + UseLen;

    End;

    BitInfo.bmType := 0;
    BitInfo.bmWidth := Width;
    BitInfo.bmHeight := Height;
    BitInfo.bmWidthBytes := (Integer(Width) * USeLen);
    BitInfo.bmPlanes := 1;
    BitInfo.bmBitsPixel := BPP;
    BitInfo.bmBits := @SrcPtr[0];

    BitMap := CreateBitMapIndirect(BitInfo);

    ZeroMemory(@IconStruct,SizeOf(IconStruct));
    IconStruct.fIcon := False;
    IconStruct.xHotspot := HotSpotX;
    IconStruct.yHotspot := HotSpotY;
    IconStruct.hbmMask := BitMap;
    IconStruct.hbmColor := BitMap;

    Self.Cursor := CreateIconIndirect(IconStruct);

    SetCursor(Self.Cursor);

    DeleteObject(BitMap);

    Self.IconSource := nil;

  End;

Procedure TPGLMouse.SetCursorFromIcon(Var Source: TPGLIcon);
  Begin
    Self.Cursor := Source.Icon;
    SetCursor(Self.Cursor);

    If Self.Cursor <> 0 Then Begin
      Self.IconSource := @Source;
    End;
  End;


Procedure TPGLMouse.ScaleToResolution(Enable: Boolean = True);
  Begin
    Self.wScale := Enable;
  End;

Procedure TPGLMouse.RegisterMouseDownCallBack(Proc: pglMouseCallBack);
  Begin
    If Context.wFeatures.UseMouseInput = False Then Exit;
    Context.wMouse.MouseDownCallBack := Proc;
  End;

Procedure TPGLMouse.RegisterMouseHeldCallBack(Proc: pglMouseCallBack);
  begin
    If Context.wFeatures.UseMouseInput = False Then Exit;
    Context.wMouse.MouseHeldCallBack := Proc;
  end;

Procedure TPGLMouse.RegisterMouseUpCallBack(Proc: pglMouseCallBack);
  Begin
    If Context.wFeatures.UseMouseInput = False Then Exit;
    Context.wMouse.MouseUpCallBack := Proc;
  End;

Procedure TPGLMouse.RegisterMouseMoveCallBack(Proc: pglMouseCallBack);
  Begin
    If Context.wFeatures.UseMouseInput = False Then Exit;
    Context.wMouse.MouseMoveCallBack := Proc;
  End;

Procedure TPGLMouse.RegisterLeaveCallBack(Proc: pglCallBack);
  Begin
    Self.LeaveCallBack := Proc;
  End;

procedure TPGLMouse.RegisterEnterCallBack(Proc: pglCallBack);
  Begin
    Self.EnterCallBack := Proc;
  End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
(*                          pglControllerInstan                               *)
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Constructor TPGLController.Create();
var
I: Integer;
  Begin
    Inherited;
    Self.Enabled := XInputAvailable();
    If Self.Enabled Then Begin
      Context.wUseController := True;
      XInput.onControllerConnect := Self.HandleConnect;
      XInput.onControllerDisconnect := Self.HandleDisconnect;
      XInput.onControllerStateChange := Self.HandleStateChange;
      XInput.onControllerButtonDown := Self.HandleButtonDown;
      XInput.onControllerButtonUp := Self.HandleButtonUp;
      XInput.onControllerButtonPress := Self.HandleButtonPress;
      XInput.refresh();

      for I := 0 to 15 do begin
        Self.fButtons[i].ButtonIndex := I;
      end;

      Self.wUp := @Self.fButtons[0];
      Self.fButtons[0].Name := 'Up';

      Self.wDown := @Self.fButtons[1];
      Self.fButtons[1].Name := 'Down';

      Self.wLeft := @Self.fButtons[2];
      Self.fButtons[2].Name := 'Left';

      Self.wRight := @Self.fButtons[3];
      Self.fButtons[3].Name := 'Right';

      Self.wStart := @Self.fButtons[4];
      Self.fButtons[4].Name := 'Start';

      Self.wBack := @Self.fButtons[5];
      Self.fButtons[5].Name := 'Back';

      Self.wLeftStickButton := @Self.fButtons[6];
      Self.fButtons[6].Name := 'Left Stick';

      Self.wRightStickButton := @Self.fButtons[7];
      Self.fButtons[7].Name := 'Right Stick';

      Self.wLeftBumper := @Self.fButtons[8];
      Self.fButtons[8].Name := 'Left Bumper';

      Self.wRightBumper := @Self.fButtons[9];
      Self.fButtons[9].Name := 'Right Bumper';

      Self.wA := @Self.fButtons[12];
      Self.fButtons[12].Name := 'A';

      Self.wB := @Self.fButtons[13];
      Self.fButtons[13].Name := 'B';

      Self.wX := @Self.fButtons[14];
      Self.fButtons[14].Name := 'X';

      Self.wY := @Self.fButtons[15];
      Self.fButtons[15].Name := 'Y';

      Self.LSX := @Self.State.stGamepad.gpThumbLX;
      Self.LSY := @Self.State.stGamepad.gpThumbLY;
      Self.RSX := @Self.State.stGamepad.gpThumbRX;
      Self.RSY := @Self.State.stGamepad.gpThumbRY;

      Self.QueryState();

    end;
  End;

Procedure TPGLController.HandleStateChange(sender:TObject;userIndex:uint32;newState:TXInputState);
  Begin
    If Assigned(Self.StateChangeCallBack) Then Begin
      Self.StateChangeCallBack(Self.LeftStick, Self.RightStick,
        newState.stGamepad.gpLeftTrigger, newState.stGamepad.gpRightTrigger);
    End;

  End;

Procedure TPGLController.HandleConnect(sender:TObject;userIndex:uint32);
  Begin

  End;

Procedure TPGLController.HandleDisconnect(sender:TObject;userIndex:uint32);
  Begin

  End;

Procedure TPGLController.HandleButtonDown(sender:TObject;userIndex:uint32;buttons:word);
Var
I: Long;
  Begin
    for I := 0 to 15 do begin
      if Self.fButtons[i].State = 1 then begin
        if Self.fButtons[i].LastState <> Self.fButtons[i].State then begin
          Self.ButtonDownCallBack(I);
        end;
      end;
    end;
  End;

Procedure TPGLController.HandleButtonUp(sender:TObject;userIndex:uint32;buttons:word);
Var
I: Long;
  Begin
    for I := 0 to 15 do begin
      if Self.fButtons[i].State = 0 then begin
        if Self.fButtons[i].LastState <> Self.fButtons[i].State then begin
          Self.ButtonUpCallBack(I);
        end;
      end;
    end;
  End;

Procedure TPGLController.HandleButtonPress(sender:TObject;userIndex:uint32;buttons:word);
  Begin

  End;

Procedure TPGLController.HandleStickHeld();
  Begin
    If Assigned(Self.StickCallBack) Then Begin
      Self.QueryState();
      Self.StickCallBack(Self.wLeftStick, Self.wRightStick);
    End;
  End;

Procedure TPGLController.RegisterButtonDownCallBack(Proc: pglControllerButtonCallBack);
  Begin
    Self.ButtonDownCallBack := Proc;
  End;

Procedure TPGLController.RegisterButtonUpCallBack(Proc: pglControllerButtonCallBack);
  Begin
    Self.ButtonUpCallBack := Proc;
  End;

Procedure TPGLController.RegisterStateChangeCallBack(Proc: pglControllerStateCallBack);
  Begin
    Self.StateChangeCallBack := Proc;
  End;

Procedure TPGLController.RegisterStickHeldCallBack(Proc: pglControllerStickCallBack);
  Begin
    Self.StickCallBack := Proc;
  End;

Procedure TPGLController.RegisterStickReleaseCallBack(Proc: pglControllerStickReleaseCallBack);
  begin
    Self.StickReleaseCallBack := Proc;
  end;

Procedure TPGLController.RegisterTriggerCallBack(Proc: pglControllerTriggerCallBack);
  begin
    Self.TriggerCallBack := Proc;
  end;


Procedure TPGLController.QueryState();
Var
I: Long;
Hi,Lo: Byte;
Value: LongBool;
  Begin
    XInput.refresh();
    XInput.llGetState(0,@Self.State);

    Self.wLastLeftStick := Self.wLeftStick;
    Self.wLastRightStick := Self.wRightStick;

    Self.wLeftStick.X := ClampToDeadZone(Self.LSX^, 0);
    Self.wLeftStick.Y := ClampToDeadZone(Self.LSY^, 0);
    Self.wRightStick.X := ClampToDeadZone(Self.RSX^, 0);
    Self.wRightStick.Y := ClampToDeadZone(Self.RSY^, 0);

    Self.wLastLeftTrigger := Self.wLeftTrigger;
    Self.wLastRightTrigger := Self.wRightTrigger;

    Self.wLeftTrigger := Self.State.stGamepad.gpLeftTrigger;
    Self.wRightTrigger := Self.State.stGamepad.gpRightTrigger;

    XInput.llGetBatteryInformation(0,2,@Self.BatteryState);
    Self.wBatteryLevel := Self.BatteryState.biBatteryLevel;



    If Assigned(Self.StickCallBack) then begin
      Self.StickCallBack(Self.LeftStick, Self.RightStick);
    end;

    if Assigned(Self.StickReleaseCallBack) then begin
      if (Self.wLeftStick.x = 0) and (Self.LeftStick.y = 0) and (Self.wLeftStick <> Self.wLastLeftStick) then begin
        Self.StickReleaseCallBack(1,0);
      end;

      if (Self.wRightStick.x = 0) and (Self.wRightStick.y = 0) and (Self.wRightStick <> Self.wLastRightStick) then begin
        Self.StickReleaseCallBack(0,1);
      end;
    end;

    if Assigned(Self.TriggerCallBack) then begin
      Self.TriggerCallBack(Self.LeftTrigger, Self.RightTrigger);
    end;

    Lo := LoByte(Self.State.stGamepad.gpButtons);
    Hi := HiByte(Self.State.stGamepad.gpButtons);

    for I := 0 to 7 do begin
      Self.fButtons[i].LastState := Self.fButtons[i].State;
      Self.fButtons[i].State := ReadBit(Lo,I);
    end;

    for I := 0 to 7 do begin
      Self.fButtons[i + 8].LastState := Self.fButtons[i + 8].State;
      Self.fButtons[i + 8].State := ReadBit(Hi,I);
    end;

    Self.HandleButtonDown(Self, 0, Self.State.stGamepad.gpButtons);
    Self.HandleButtonUp(Self, 0, Self.State.stGamepad.gpButtons);
  End;


Function TPGLController.GetButton(I: Integer): TPGLControllerButton;
  begin
    Result := Self.fButtons[I];
  end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
(*                                TPGLContext                                  *)
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


Constructor TPGLContext.Create();
  Begin

  End;

Procedure TPGLContext.PollEvents();
Var
Messages: MSG;
I: Long;
P: TPOINT;
  Begin

    If Self.UseController = True Then Begin
      Self.Controller.QueryState();
    End;

    If Context.wFeatures.UseMouseInput = True Then Begin
    // Handle mouse screen position and in/out of window
      Self.wMouse.wLastScreenX := Self.wMouse.wScreenX;
      Self.wMouse.wLastScreeny := Self.wMouse.wScreenY;

      GetCursorPos(P);
      Self.wMouse.wScreenX := P.X;
      Self.wMouse.wScreenY := P.Y;

      Self.wMouse.InWindow();
    End;

    If Context.wFeatures.UseCharacterInput = True Then Begin
    // Handle Keyboard Char Input
      Self.KeyBoard.SwapChars();
    End;

    If Self.wStyleChanged = True Then Begin
      Self.wStyleChanged := False;
      Self.RestoreStyleFlags();
    End;

    // Reset message flags
    Self.wLBUTTONDOWN := 0;
    Self.wRBUTTONDOWN := 0;
    Self.wXBUTTONDOWN[2] := 0;
    Self.wXBUTTONDOWN[3] := 0;
    Self.wXBUTTONDOWN[4] := 0;

    While PeekMessage(Messages,Context.wHandle,0,0,PM_REMOVE) do Begin
//        // Don't translate if character input wasn't requested
        If Context.wFeatures.UseCharacterInput = True Then Begin
          TranslateMessage(Messages);
        End;

        DispatchMessage(Messages);
    End;

    // check for mouse buttons held
    Self.CheckMouseHeld();

    // Execute Key Held CallBacks
    If Assigned(Self.KeyBoard.KeyHeld) Then Begin
      For I := 0 to 255 Do Begin
        If Self.KeyBoard.KeyState[I] <> 0 Then Begin
          Self.KeyBoard.KeyHeld(I,Self.KeyBoard.Shift,Self.KeyBoard.Alt);
        End;
      End;
    End;

    if Self.wSizeChanged then begin
      GetWindowRect(Self.Handle, Self.wWindowRect);
      GetClientRect(Self.Handle, Self.wClientRect);
    end;

  End;


Function TPGLContext.ProcessKeyBoardMessages(Var Handle: HWND; Var Messages: Cardinal; Var wParameter: WPARAM; Var lParameter: LPARAM): LRESULT;
  Begin

    Result := 0;

    Case Messages Of

      WM_KEYDOWN, WM_SYSKEYDOWN:
      Begin
        If Self.KeyBoard.Key[(wParameter)] = 0 Then Begin
          Self.wKeyBoard.Key[(wParameter)] := 1;
        End Else Begin
          Self.wKeyBoard.Key[(wParameter)] := 2;
        End;

        GetKeyDown(wParameter);
      End;

     WM_KEYUP, WM_SYSKEYUP:
      Begin
        Self.wKeyBoard.Key[wParameter] := 0;
        GetKeyUp(wParameter);
      End;

     Else
      Begin
        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

    End;

  End;


Function TPGLContext.ProcessMouseMessages(Var Handle: HWND; Var Messages: Cardinal; Var wParameter: WPARAM; Var lParameter: LPARAM): LRESULT;
Var
P1,P2: TPOINT;
ButtonVal: Integer;
I: Integer;
  Begin

    Case Messages of

       WM_MOUSEMOVE:
      Begin
        Self.wMouse.wLastX := Self.wMouse.wX;
        Self.wMouse.wLastY := Self.wMouse.wY;

        Self.wMouse.wX := GET_X_LPARAM(lParameter);
        Self.wMouse.wY := GET_Y_LPARAM(lParameter);

        Self.wMouse.wDistX := Self.wMouse.wX - Self.wMouse.wLastX;
        Self.wMouse.wDistY := Self.wMouse.wY - Self.wMouse.wLastY;

        If Self.wMouse.wScale = True Then Begin
          Self.wMouse.wDistX := Self.wMouse.wDistX * (Context.CurDevMode.dmPelsHeight / Context.OrgDevMode.dmPelsHeight);
          Self.wMouse.wDistY := Self.wMouse.wDistY * (Context.CurDevMode.dmPelsHeight / Context.OrgDevMode.dmPelsHeight);
        End;

        P1 := Point(trunc(Self.wMouse.LastX), trunc(Self.wMouse.LastY));
        P2 := Point(trunc(Self.wMouse.X), trunc(Self.wMouse.Y));
        Self.wMouse.wDistance := P1.Distance(P2);

        If Assigned(Self.wMouse.MouseMoveCallBack) Then Begin
          Self.wMouse.MouseMoveCallBack(Self.wMouse.X, Self.wMouse.Y,0,Self.wKeyBoard.Shift,Self.wKeyBoard.Alt);
        End;

        If Self.wMouse.Locked = True Then Begin
          If (Self.wMouse.X <> Self.wMouse.LockX) or (Self.wMouse.Y <> Self.wMouse.LockY) Then Begin
            Self.wMouse.ReturnToLock();
          End;
        End;



        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      end;

     WM_LBUTTONDOWN:
      Begin
        ButtonVal := HiWord(wParameter);
        Self.wMouse.wButton[ButtonVal] := 1;
        Self.wLBUTTONDOWN := 1;

          If Assigned(Self.wMouse.MouseDownCallBack) Then Begin
            Self.wMouse.MouseDownCallBack(Self.wMouse.X, Self.wMouse.Y,ButtonVal,Self.wKeyBoard.Shift,Self.wKeyBoard.Alt);
          End;

        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     WM_LBUTTONUP:
      Begin
        ButtonVal := HiWord(wParameter);
        Self.wMouse.wButton[ButtonVal] := 0;
        Self.wMouse.wButtonHeldCount[0] := 0;

          If Assigned(Self.wMouse.MouseUpCallBack) Then Begin
            Self.wMouse.MouseUpCallBack(Self.wMouse.X, Self.wMouse.Y,ButtonVal,Self.wKeyBoard.Shift,Self.wKeyBoard.Alt);
          End;

        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     WM_RBUTTONDOWN:
      Begin
        Self.wMouse.wButton[1] := 1;
        Self.wRBUTTONDOWN := 1;

          If Assigned(Self.wMouse.MouseDownCallBack) Then Begin
            Self.wMouse.MouseDownCallBack(Self.wMouse.X, Self.wMouse.Y,1,Self.wKeyBoard.Shift,Self.wKeyBoard.Alt);
          End;

        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     WM_RBUTTONUP:
      Begin
        Self.wMouse.wButton[1] := 0;
        Self.wMouse.wButtonHeldCount[1] := 0;

          If Assigned(Self.wMouse.MouseUpCallBack) Then Begin
            Self.wMouse.MouseUpCallBack(Self.wMouse.X, Self.wMouse.Y,1,Self.wKeyBoard.Shift,Self.wKeyBoard.Alt);
          End;

        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     WM_XBUTTONDOWN:
      Begin
        ButtonVal := HiWord(wParameter) + 1;
        Self.wMouse.wButton[ButtonVal] := 1;
        Self.wXBUTTONDOWN[ButtonVal] := 1;

          If Assigned(Self.wMouse.MouseDownCallBack) Then Begin
            Self.wMouse.MouseDownCallBack(Self.wMouse.X, Self.wMouse.Y,ButtonVal,Self.wKeyBoard.Shift,Self.wKeyBoard.Alt);
          End;

        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     WM_XBUTTONUP:
      Begin
        ButtonVal := HiWord(wParameter) + 1;
        Self.wMouse.wButton[ButtonVal] := 0;
        Self.wMouse.wButtonHeldCount[ButtonVal] := 0;

          If Assigned(Self.wMouse.MouseUpCallBack) Then Begin
            Self.wMouse.MouseUpCallBack(Self.wMouse.X, Self.wMouse.Y,ButtonVal,Self.wKeyBoard.Shift,Self.wKeyBoard.Alt);
          End;

        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     Else
      Result := DefWindowProc(Handle,Messages,wParameter,lParameter);

    End;



  End;


procedure TPGLContext.CheckMouseHeld();
  begin

    // Check for button held

    if (Self.wLBUTTONDOWN = 0) then begin
      if Self.wMouse.Button0 = 1 then begin
        if Assigned(Self.wMouse.MouseHeldCallBack) then begin
          Inc(Self.wMouse.wButtonHeldCount[0]);
          Self.wMouse.MouseHeldCallBack(Self.wMouse.X, Self.wMouse.Y, 0, Self.wKeyBoard.Shift, Self.wKeyBoard.Alt);
        end;
      end;
    end;

    if (Self.wRBUTTONDOWN = 0) then begin
      if Self.wMouse.Button1 = 1 then begin
        if Assigned(Self.wMouse.MouseHeldCallBack) then begin
          Inc(Self.wMouse.wButtonHeldCount[1]);
          Self.wMouse.MouseHeldCallBack(Self.wMouse.X, Self.wMouse.Y, 1, Self.wKeyBoard.Shift, Self.wKeyBoard.Alt);
        end;
      end;
    end;

    if (Self.wXBUTTONDOWN[2] = 0) then begin
      if Self.wMouse.Button2 = 1 then begin
        if Assigned(Self.wMouse.MouseHeldCallBack) then begin
          Inc(Self.wMouse.wButtonHeldCount[2]);
          Self.wMouse.MouseHeldCallBack(Self.wMouse.X, Self.wMouse.Y, 2, Self.wKeyBoard.Shift, Self.wKeyBoard.Alt);
        end;
      end;
    end;

    if (Self.wXBUTTONDOWN[3] = 0) then begin
      if Self.wMouse.Button3 = 1 then begin
        if Assigned(Self.wMouse.MouseHeldCallBack) then begin
          Inc(Self.wMouse.wButtonHeldCount[3]);
          Self.wMouse.MouseHeldCallBack(Self.wMouse.X, Self.wMouse.Y, 3, Self.wKeyBoard.Shift, Self.wKeyBoard.Alt);
        end;
      end;
    end;

    if (Self.wXBUTTONDOWN[4] = 0) then begin
      if Self.wMouse.Button4 = 1 then begin
        if Assigned(Self.wMouse.MouseHeldCallBack) then begin
          Inc(Self.wMouse.wButtonHeldCount[4]);
          Self.wMouse.MouseHeldCallBack(Self.wMouse.X, Self.wMouse.Y, 4, Self.wKeyBoard.Shift, Self.wKeyBoard.Alt);
        end;
      end;
    end;

  end;


Function TPGLContext.ProcessCharMessages(Var Handle: HWND; Var Messages: Cardinal; Var wParameter: WPARAM; Var lParameter: LPARAM): LRESULT;

Var
Chr: String;
BS,Ent,Esc: Boolean;

  Begin

    Chr := Char(wParameter);
    Self.wKeyBoard.wChars.Add(Chr);

    If Assigned(Self.wKeyBoard.CharCallBack) Then Begin

      BS := False;
      Ent := False;
      Esc := False;

      If Chr = Char(VK_BACK) Then Begin
        BS := True;
        Chr := '';
      End;

      If Chr = Char(VK_RETURN) Then Begin
        Ent := True;
        Chr := '';
      End;

      If Chr = Char(VK_ESCAPE) Then Begin
        Esc := True;
        Chr := '';
      End;

      Self.wKeyBoard.CharCallBack(Chr,BS,Ent,Esc);
    End;

    Result := 0;

  End;


Procedure TPGLContext.GetInputDevices();
  Begin

  End;


Procedure TPGLContext.UpdateRects();
Var
R: Integer;
wRect: TRECT;
Success: LongBool;

  Begin

    GetWindowRect(Self.Handle, Self.wWindowRect);
    GetClientRect(Self.Handle, Self.wClientRect);

    If (Self.FullScreen = False) or (Self.HasCaption = True) Then Begin
      Self.wBorderWidth := trunc((Self.wWindowRect.Width - Self.wClientRect.Width) / 2);
      Self.wTitleBarHeight := trunc( (Cardinal(Self.wWindowRect.Width) - Cardinal(Self.wClientRect.Width)) - Self.wBorderWidth);
    End Else Begin
      Self.wBorderWidth := 0;
      Self.wTitleBarHeight := 0;
    End;
  End;


Procedure TPGLContext.RestoreStyleFlags();
Var
Flags: NativeInt;
wRect: TRECT;

  Begin

    Flags := 0;

    If Self.HasCaption = True Then Begin
      Flags := Flags or WS_CAPTION;
    End;

    If Self.HasMenu = True Then Begin
      Flags := Flags or WS_SYSMENU;
    End;

    If Self.HasMinimize Then Begin
      Flags := Flags or WS_MINIMIZEBOX;
    End;

    If Self.HasMaximize Then Begin
      Flags := Flags or WS_MAXIMIZEBOX;
    End;

    If Self.CanSize Then Begin
      Flags := Flags or WS_SIZEBOX;
    End;

    SetWindowLongPtr(Self.Handle,GWL_STYLE,Flags);
    wRect := RECT(0,0,Context.wWidth, Context.wHeight);

    If Self.HasCaption = True Then Begin
      AdjustWindowRectEX(wRect,Cardinal(Flags),False,0);
    End;

    SetWindowPos(Self.Handle,HWND_TOP,0,0,wRect.Width,wRect.Height, SWP_NOMOVE or SWP_DRAWFRAME or SWP_FRAMECHANGED or SWP_SHOWWINDOW);
  End;

Procedure TPGLContext.Close();
  Begin
    if Assigned(Self.CloseCallBack) then begin
      Self.CloseCallBack();
    end;

    ChangeDisplaySettings(Self.OrgDevMode,CDS_UPDATEREGISTRY);
    Self.CleanUp();
    Self.wShouldClose := True;
    SendMessage(Self.Handle,WM_QUIT,0,0);
  End;

Procedure TPGLContext.SetTitle(Text: String);
  Begin
    Self.wTitle := Text;
    SetWindowText(Self.Handle,Self.wTitle);
  End;

Procedure TPGLContext.SetIconFromFile(FileName: String);
Var
Image: Pointer;
Width,Height, Channels: GLInt;
BPP: GLInt;
  Begin
    Image := stbi_load(PAnsiChar(AnsiString(FileName)),Width,Height,Channels,4);
    BPP := 4 * 8;
    Self.SetIconFromBits(Image,Width,Height,BPP);
    stbi_image_free(Image);
  End;

Procedure TPGLContext.SetIconFromBits(Source: Pointer; Width,Height,BPP: GLUint);
Var
IconStruct: _ICONINFO;
BitMap: HBITMAP;
I,Z: Longint;
SrcPtr: PByte;
UseBytes: Array of Byte;
TempRed, TempBlue: Byte;
MaskPos: Integer;
BitInfo: tagBITMAP;
UseLen: GLInt;

  Begin

    UseLen := trunc(BPP / 8);
    SrcPtr := Source;
    SetLength(UseBytes,UseLen);
    MaskPos := 0;

    For I := 0 to (Width * Height) Do Begin

      Move(SrcPtr[MaskPos],UseBytes[0],UseLen);

      // Swap blue and red bytes
      TempRed := UseBytes[2];
      TempBlue := Usebytes[0];
      UseBytes[0] := TempRed;
      UseBytes[2] := TempBlue;

      If (UseBytes[0] = 255) And
         (UseBytes[1] = 255) And
         (UseBytes[2] = 255) Then Begin

         For z := 0 to UseLen - 1 Do Begin
          UseBytes[z] := 0;
         End;

      End;

      Move(Usebytes[0],SrcPtr[MaskPos],UseLen);

      MaskPos := MaskPos + UseLen;

    End;

    BitInfo.bmType := 0;
    BitInfo.bmWidth := Width;
    BitInfo.bmHeight := Height;
    BitInfo.bmWidthBytes := (Integer(Width) * USeLen);
    BitInfo.bmPlanes := 1;
    BitInfo.bmBitsPixel := BPP;
    BitInfo.bmBits := @SrcPtr[0];

    BitMap := CreateBitMapIndirect(BitInfo);

    ZeroMemory(@IconStruct,SizeOf(IconStruct));
    IconStruct.fIcon := True;
    IconStruct.xHotspot := 0;
    IconStruct.yHotspot := 0;
    IconStruct.hbmMask := BitMap;
    IconStruct.hbmColor := BitMap;

    Context.wIcon := CreateIconIndirect(IconStruct);

    PostMessage(Context.Handle,WM_SETICON,1,Context.wIcon);

    DeleteObject(BitMap);

  End;

Procedure TPGLContext.SetPosition(X: Cardinal; Y: Cardinal);
  Begin
    If Self.FullScreen = True Then Exit;

    Context.wX := X;
    Context.wY := Y;
    SetWindowPos(Context.Handle, HWND_TOP, Context.X - Context.wBorderWidth, Context.Y, Context.Width, Context.Height,
      SWP_SHOWWINDOW);
  End;

function TPGLContext.SetSize(W: GLInt; H: GLInt; KeepCentered: Boolean = True): Boolean;
Var
NewX,NewY: GLInt;
CenterX,CenterY: GLInt;
Flags: GLUint;
wRect: TRECT;

  Begin

    Result := False;

    // if requesting same dimensions, exit
    if (W = Integer(Self.Width)) and (H = Integer(Self.Height)) then begin
      Result := False;
      Exit;
    end;

    // check if full screen, if so, check if resolution can change to requested size
    if Self.FullScreen  then begin
      if Self.TestResolution(Point(W,H)) = False then Exit;
    end;

    // if not fullscreen
    if Self.wFullScreen = False then begin

      If W < 0 Then Begin
        W := 0;
      End;

      If H < 0 Then Begin
        H := 0;
      End;

      NewX := 0;
      NewY := 0;
      Flags := SWP_NOMOVE or SWP_SHOWWINDOW or SWP_FRAMECHANGED;

      If KeepCentered = True Then Begin
        NewX := trunc((Context.wScreenWidth / 2) - (W / 2));
        NewY := trunc((Context.wScreenHeight / 2) - (H / 2));
        Flags := Flags xor SWP_NOMOVE;
      End;

      Self.wWidth := W;
      Self.wHeight := H;
      wRect := Rect(0,0,Self.Width, Self.Height);

      If Self.HasCaption = True Then Begin
        AdjustWindowRect(wRect,GetWindowLongPtr(Self.Handle, GWL_STYLE),False);
      End;

    end else begin

      NewX := 0;
      NewY := 0;
      Self.wWidth := W;
      Self.wHeight := H;
      Flags := SWP_NOMOVE or SWP_SHOWWINDOW;
      wRect := Rect(0,0,Self.Width,Self.Height);
      AdjustWindowRect(wRect,GetWindowLongPtr(Self.Handle, GWL_STYLE),False);

    end;

    if Self.FullScreen = True then begin
      Self.ChangeResolution(Point(W,H));
    end;

    SetWindowPos(Self.Handle,HWND_TOP,NewX,NewY,wRect.Width,wRect.Height,Flags);

    Result := True;

  End;

Procedure TPGLContext.Maximize();
  Begin
    If Self.FullScreen = True Then Exit;
    SendMessage(Self.Handle,WM_SYSCOMMAND,SC_MAXIMIZE,0);
  End;

Procedure TPGLContext.Restore();
  Begin
    SendMessage(Self.Handle,WM_SYSCOMMAND,SC_RESTORE,0);
  End;

Procedure TPGLContext.Minimize();
  Begin
    SendMessage(Self.Handle,WM_SYSCOMMAND,SC_MINIMIZE,0);
  End;

Procedure TPGLContext.SetHasCaption(Enable: Boolean = True);
  Begin
    Context.wHasCaption := Enable;
    Self.wStyleChanged := True;
  End;

Procedure TPGLContext.SetHasMenu(Enable: Boolean = True);
  Begin
    Context.wHasMenu := Enable;
    Self.wStyleChanged := True;
  End;

Procedure TPGLContext.SetHasMaximize(Enable: Boolean = True);
  Begin
    Context.wHasMaximize := Enable;
    Self.wStyleChanged := True;
  End;

Procedure TPGLContext.SetHasMinimize(Enable: Boolean = True);
  Begin
    Context.wHasMinimize := Enable;
    Self.wStyleChanged := True;
  End;

Procedure TPGLContext.SetCanSize(Enable: Boolean = True);
  Begin
    Context.wCanSize := Enable;
    Self.wStyleChanged := True;
  End;

Procedure TPGLContext.SetWin7Frame(Enable: Boolean = True);
Var
Flags: GLInt;
  Begin
    Self.wWin7Frame := Enable;
    Self.wStyleChanged := True;
  End;


Procedure TPGLContext.SetFullScreen(Enable: Boolean = True);
Var
ReturnVal: Integer;
Error: Cardinal;
  Begin

    if Enable = False then begin
      // revert back to native resolution if it is not the the current resolution
      if Self.wFullScreen <> False then begin
        Self.wFullScreen := False;
        Self.ChangeResolution(Point(Self.OrgDevMode.dmPelsWidth, Self.OrgDevMode.dmPelsHeight));
        Self.RestoreStyleFlags();
      end;

    end else if Enable = True then begin

      // if not already in fullscreen
      if Self.wFullScreen <> True then begin

        if Self.TestResolution(Point(Self.Width, Self.Height)) = True then begin
          Self.wFullScreen := True;
          SetWindowLongPtr(Self.Handle, GetWindowLongPtr(Self.Handle,GWL_STYLE), DWORD(0));
          SetWindowPos(Self.Handle, HWND_TOP,0, 0, Self.Width, Self.Height, SWP_DRAWFRAME);
          Self.ChangeResolution(Point(Self.Width, Self.Height));
        end;

      end;

    end;

  End;

function TPGLContext.TestResolution(ATestRes: TPOINT): Boolean;
var
RequestMode: DEVMODE;
RetVal: Integer;
  begin
    CreateDEVMODE(RequestMode,ATestRes.X, ATestRes.Y);
    RetVal := ChangeDisplaySettings(RequestMode, CDS_TEST);
    if RetVal = DISP_CHANGE_SUCCESSFUL then begin
      Result := True;
    end else begin
      Result := False;
    end;
  end;


function TPGLContext.ChangeResolution(ANewRes: TPOINT): Boolean;
var
RequestMode: DEVMODE;
RetVal: Integer;
CheckMessage: TagMSG;
  begin

    if (Self.Width = Self.ScreenWidth) and (Self.Height = Self.ScreenHeight) then begin
      Result := False;
      Exit;
    end;

    Self.wDispChanging := True;
    CreateDEVMODE(RequestMode,ANewRes.X, ANewRes.Y);
    RetVal := ChangeDisplaySettings(RequestMode, CDS_FULLSCREEN or CDS_UPDATEREGISTRY);

    if RetVal = DISP_CHANGE_SUCCESSFUL then begin

      Result := True;

      Self.CurDevMode := RequestMode;
      Self.wScreenWidth := ANewRes.X;
      Self.wScreenHeight := ANewRes.Y;
      Self.wDPIScaleX := trunc(Self.wDPIX * (Self.wScreenHeight / Self.wNativeScreenWidth));
      Self.wDPIScaleY := trunc(Self.wDPIY * (Self.wScreenWidth / Self.wNativeScreenHeight));
    end else begin
      Result := False;
    end;
  end;

Procedure TPGLContext.RegisterSizeCallBack(Proc: pglWindowSizeCallBack);
  Begin
    Self.SizeCallBack := Proc;
  End;

Procedure TPGLContext.RegisterMoveCallBack(Proc: pglWindowMoveCallBack);
  Begin
    Self.MoveCallBack := Proc;
  End;

Procedure TPGLContext.RegisterMaximizeCallBack(Proc: pglCallBack);
  Begin
    Self.MaximizeCallBack := Proc;
  End;

Procedure TPGLContext.RegisterMinimizeCallBack(Proc: pglCallBack);
  Begin
    Self.MinimizeCallBack := Proc;
  End;

Procedure TPGLContext.RegisterRestoreCallBack(Proc: pglCallBack);
  Begin
    Self.RestoreCallBack := Proc;
  End;

Procedure TPGLContext.RegisterGotFocusCallBack(Proc: pglCallBack);
  Begin
    Self.GotFocusCallBack := Proc;
  End;

Procedure TPGLContext.RegisterLostFocusCallBack(Proc: pglCallBack);
  Begin
    Self.LostFocusCallBack := Proc;
  End;

Procedure TPGLContext.RegisterDebugCallBack(Proc: TglDebugProc);
  Begin
    If Context.wFeatures.OpenGLDebugContext = False Then Exit;
    glDebugMessageCallBack(Proc,nil);
  End;

Procedure TPGLContext.RegisterWindowCloseCallBack(Proc: pglCallBack);
  begin
    Self.CloseCallBack := Proc;
  end;

Procedure TPGLContext.SetDebugToConsole();
  Begin
    Self.wDebugToConsole := True;
    Self.wDebugToLog := False;
    Self.wDebugToMsgBox := False;
  End;

Procedure TPGLContext.SetDebugToLog();
  Begin
    Self.wDebugToConsole := False;
    Self.wDebugToLog := True;
    Self.wDebugToMsgBox := False;
  End;

Procedure TPGLContext.SetDebugToMsgBox();
  Begin
    Self.wDebugToConsole := False;
    Self.wDebugToLog := False;
    Self.wDebugToMsgBox := True;
  End;

Procedure TPGLContext.SetBreakOnDebug(Enable: Boolean);
  Begin
    Self.wBreakOnDebug := Enable;
  End;

Procedure TPGLContext.GetDebugLog(out Buffer: array of string);
Var
Len: Integer;
Count: Integer;
I: Long;
CompString: String;

  Begin

    If Length(Buffer) = 0 Then Exit;

    Len := Context.wDebugCount;

    If Len = 0 Then Begin
      Buffer[0] := 'No Log Messages to Retrieve!';
      Exit;
    End;

    // Check if length buffer = 1 then compile all logs to one string
    If Length(Buffer) = 1 Then Begin

      For I := 0 to Len - 1 Do Begin
        CompString := CompString + Self.wDebugLog[I] + sLineBreak;
      End;

      Buffer[0] := CompString;
      Exit;
    End;

    // Only output to maximum length of buffer
    If Length(Buffer) >= Len Then Begin
      Count := Len - 1;
    End Else Begin
      Count := Length(Buffer) - 1;
    End;

    For I := 0 to Count Do Begin
      Buffer[i] := Self.wDebugLog[i];
    End;

  End;

Procedure TPGLContext.SetIgnoreDebug(AIgnore: Boolean = True);
  begin
    Self.wIgnoreDebug := AIgnore;
  end;

Procedure TPGLContext.GetDisplayModes(out ADisplayList: TArray<TPoint>);
var
DM: DEVMODE;
RetVal: LongBool;
Num: Integer;
Skip: Boolean;
I: Long;
TempList: TArray<TPOINT>;
  begin

    // get list of display mode resolutions. Do not allow repeated resolutions.

    Num := 0;

    repeat

      Skip := False;
      RetVal := EnumDisplaySettings(nil,Num,DM);

      if RetVal = True then begin
        if DM.dmBitsPerPel = 32 then begin

          if Length(ADisplayList) <> 0 then begin
            if (DM.dmPelsWidth = cardinal(ADisplayList[High(ADisplayList)].X)) and (DM.dmPelsHeight = cardinal(ADisplayList[High(ADisplayList)].Y)) then Skip := True;
          end;

          if Skip = False then begin
            SetLength(ADisplayList,Length(ADisplayList) + 1);
            ADisplayList[High(ADisplayList)].X := DM.dmPelsWidth;
            ADisplayList[High(ADisplayList)].Y := DM.dmPelsHeight;
          end;

        end;
      end;

      Inc(Num);

    until RetVal = False;

    if Length(ADisplaylist) > 1 then begin
    // flip them so they're largest to smallest
      SetLength(TempList, Length(ADisplayList));
      TempList[0] := ADisplayList[0];
      for I := 1 to High(TempList) do begin
        TempList[i] := ADisplayList[High(ADisplayList) - I + 1];
      end;
    end;

    ADisplayList := TempList;
  end;

Procedure TPGLContext.CleanUp();
Var
Success: LongBool;
  Begin
    Success := DeleteObject(Context.wWindowRgn);
  End;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
(*                            Helpers                                         *)
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class operator TPointFloatHelper.NotEqual(A,B: TPointFloat): Boolean;
  begin
    Result := False;
    if (A.X <> B.X) or (A.Y <> B.Y) then begin
      Exit(True);
    end;
  end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
(*                            Unit Functions                                  *)
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Procedure pglStart(Width,Height: GLUint; Format: TPGLWindowFormat; Features: TPGLFeatureSettings; Title: String);
Var
DC: HDC;

  Begin

    EXEPath := ExtractfilePath(ParamStr(0));

    Context := TPGLContext.Create();

    if Features.UseController  then begin
      Context.wController := TPGLController.Create();
    end;

    Context.wMouse := TPGLMouse.Create();
    Context.wKeyBoard := TPGLKeyboard.Create();

    Context.wFormat := Format;

    Context.wTitle := Title;

    if Width <> screen_width then begin
      Context.wWidth := Width;
    end else begin
      Context.wWidth := GetDeviceCaps(GetDC(0),HORZRES);
    end;

    if Height <> screen_height then begin
      Context.wHeight := Height;
    end else begin
      Context.wHeight := GetDeviceCaps(GetDC(0),VERTRES);
    end;

    If Context.Format.StencilBits <> 0 Then Begin
      Context.wHasStencil := True;
    End Else Begin
      Context.wHasStencil := False;
    End;

    If Context.Format.DepthBits <> 0 Then Begin
      Context.wHasDepth := True;
    End Else Begin
      Context.wHasDepth := False;
    End;


    ZeroMemory(@WC,SizeOf(WNDCLASSEX));

    WC.cbSize := SizeOf(WNDCLASSEX);
    WC.style := CS_OWNDC or CS_HREDRAW or CS_VREDRAW;
    WC.lpfnWndProc := @WindowProc;
    WC.cbClsExtra := 0;
    WC.cbWndExtra := 0;
    WC.hInstance := System.MainInstance;
    WC.hIcon := LoadIcon(0, IDI_APPLICATION);
    WC.hCursor := LoadCursor(0, IDC_ARROW);
    WC.hbrBackground := HBRUSH(COLOR_WINDOW+1);
    WC.lpszMenuName := nil;
    WC.lpszClassName := PWideChar('OpenGL Window');
    WC.hIconSm := LoadIcon(0, IDI_APPLICATION);

    DC := GetDC(0);

    Context.wScreenWidth := GetDeviceCaps(DC,HORZRES);
    Context.wScreenHeight := GetDeviceCaps(DC,VERTRES);
    Context.wNativeScreenWidth := Context.wScreenWidth;
    Context.wNativeScreenHeight := Context.wScreenHeight;
    Context.wDPIX := GetDeviceCaps(DC,LOGPIXELSX);
    Context.wDPIY := GetDeviceCaps(DC,LOGPIXELSY);
    Context.wDPIScaleX := Context.wDPIX;
    Context.wDPIScaleY := Context.wDPIY;

    Context.wX := trunc((Context.ScreenWidth / 2) - Context.Width / 2);
    Context.wY := trunc((Context.ScreenHeight / 2) - Context.Height / 2);

    ReleaseDC(0,DC);

    RegisterClassEX(WC);

    // Handle features, they initialize to all enabled and highest verion, so only need to be assigned if valid pointer
    Context.wFeatures := Features;

    CreateGLContext();

//    Context.SetSize(Context.Width, Context.Height,true);
    Context.SetFullScreen(Context.Format.FullScreen);
    SetCursorPos(trunc(Context.wWindowRect.Left + (Context.Width / 2)), trunc(Context.wWindowRect.Top + (Context.Height / 2)));
    Context.IsReady := True;
    Context.SetTitle(Title);


  End;


Function ReturnPFDFlags(): Integer;
Var
Flags: Integer;
  Begin
    Flags := PFD_SUPPORT_OPENGL or PFD_DRAW_TO_WINDOW;

    If Context.Format.BufferCopy = True Then Begin
      Flags := Flags or  PFD_SWAP_COPY;
    End Else Begin
      Flags := Flags or PFD_SWAP_EXCHANGE;
    End;

    Result := Flags;
  End;

Function ReturnARBPixelFormat(): TPGLAttribs;
Var
MaxSamples: GLUint;
  Begin

    glGetIntegerV(GL_MAX_SAMPLES,@MaxSamples);

    If Context.wFormat.Samples > MaxSamples Then Context.wFormat.Samples := MaxSamples;

    Result.AddAttribs([
    WGL_NUMBER_PIXEL_FORMATS_ARB, 1,
    WGL_PIXEL_TYPE_ARB, WGL_TYPE_RGBA_ARB,
    WGL_DRAW_TO_WINDOW_ARB, 1,
    WGL_ACCELERATION_ARB, WGL_FULL_ACCELERATION_ARB,
    WGL_DOUBLE_BUFFER_ARB, 1,
    WGL_SUPPORT_OPENGL_ARB, 1,
    WGL_COLOR_BITS_ARB, Context.wFormat.ColorBits,
    WGL_RED_BITS_ARB, 0,
    WGL_GREEN_BITS_ARB, 0,
    WGL_BLUE_BITS_ARB, 0,
    WGL_ALPHA_BITS_ARB, 0,
    WGL_DEPTH_BITS_ARB, Context.wFormat.DepthBits,
    WGL_STENCIL_BITS_ARB, Context.wFormat.StencilBits]);

    If Context.wFormat.BufferCopy = true Then Begin
      Result.AddAttribs([WGL_SWAP_METHOD_ARB, WGL_SWAP_COPY_ARB]);
    End Else Begin
      Result.AddAttribs([WGL_SWAP_METHOD_ARB, WGL_SWAP_EXCHANGE_ARB]);
    End;

    If Context.wFormat.Samples <> 0 Then Begin
      Result.AddAttribs([WGL_SAMPLE_BUFFERS_ARB, True.ToInteger,
                        WGL_SAMPLES_ARB, Context.wFormat.Samples]);
    End Else Begin
      Result.AddAttribs([WGL_SAMPLE_BUFFERS_ARB, False.ToInteger,
                        WGL_SAMPLES_ARB, 0]);
    End;

    Result.AddAttribs([0,0]);
  End;


function ConstructContextAttributes(Maj,Min: Integer): HGLRC;
Var
A: TPGLAttribs;

  Begin

    A.AddAttribs([WGL_CONTEXT_MAJOR_VERSION_ARB, Maj]);
    A.AddAttribs([WGL_CONTEXT_MINOR_VERSION_ARB, Min]);
    A.AddAttribs([WGL_CONTEXT_LAYER_PLANE_ARB, 0]);

    {$IFDEF DEBUG}
    If Context.wFeatures.OpenGLDebugContext = True Then Begin
      A.AddAttribs([WGL_CONTEXT_FLAGS_ARB, WGL_CONTEXT_DEBUG_BIT_ARB]);
    End;
    {$ENDIF}

    if Context.wFeatures.OpenGLCompatibilityContext then begin
      A.AddAttribs([WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB]);
    end else begin
      A.AddAttribs([WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_CORE_PROFILE_BIT_ARB]);
    end;

    A.AddAttribs([0,0]);

    Result := wglCreateContextAttribsARB(Context.DC,0,@A.Attribs[0]);
  End;


Procedure UpdatePixelFormat(DC: HDC; PixelID: Integer);
Var
PFD: PixelFormatDescriptor;
RetBool: LongBool;

  Begin
    RetBool := DescribePixelFormat(DC, PixelID, SizeOf(PIXELFORMATDESCRIPTOR), PFD);

    // Assign values to window format
    Context.wFormat.DepthBits := PFD.cDepthBits;
    Context.wFormat.StencilBits := PFD.cStencilBits;

  End;


Procedure CreateGLContext();
Var
TempWindow: HWND;
TempDC: HDC;
TempRDC: HGLRC;
PixelFormat: PIXELFORMATDESCRIPTOR;
TPF: PIXELFORMATDESCRIPTOR;
PFID: Integer;
PixelAttribs: TPGLAttribs;
ContextAttribs: TPGLAttribs;
PixelFormatID: GLInt;
numFormats: GLUint;
Status: BOOL;
Options: TRCOptions;
wRect: TRECT;
ContextMajor,ContextMinor: GLInt;
ReturnedFormats: Array [0..99] of Integer;
DescForms: Array [0..99] of PIXELFORMATDESCRIPTOR;
I: Long;
ErrVar: Cardinal;

  Begin

    Status := InitOpenGL();
    If Status = False Then Begin
      MessageBox(0,'Failed to Initialize OpenGL! Exiting Application!', 'Error', MB_OK or MB_ICONEXCLAMATION);
      Exit;
    End;

    // Create the temporary window to initialize the context with
    TempWindow := CreateWindowEX(0,'OpenGL Window','Temp',0,0,0,Context.Width,Context.Height,
      0,0,System.MainInstance,nil);

      If TempWindow = 0 Then Begin
        MessageBox(0,'Failed to Create Initial Temporary Window!', 'Error', MB_OK or MB_ICONEXCLAMATION);
        PostQuitMessage(0);
        Exit;
      End;

    TempDC := GetDC(TempWindow);

    // Zero then fill the requested pixel format
    ZeroMemory(@PixelFormat,SizeOf(PixelFormat));
    PixelFormat.nSize := SizeOf(PixelFormat);
    PixelFormat.nVersion := 1;
    PixelFormat.dwFlags := ReturnPFDFlags;
    PixelFormat.iPixelType := PFD_TYPE_RGBA;
    PixelFormat.cColorBits := Context.wFormat.ColorBits;
    PixelFormat.cRedBits := 0;
    PixelFormat.cGreenBits := 0;
    PixelFormat.cBlueBits := 0;
    PixelFormat.cAlphaBits := 0;
    PixelFormat.cStencilBits := Context.wFormat.StencilBits;
    PixelFormat.cDepthBits := Context.wFormat.DepthBits;
    PixelFormat.iLayerType := PFD_MAIN_PLANE;

    PFID := ChoosePixelFormat(TempDC,@PixelFormat);
    DescribePixelFormat(TempDC,PFID,SizeOf(PixelFormat),TPF);

    // Set Pixel Format to Window
      SetLastError(0);
    If SetPixelFormat(TempDC,PFID,@TPF) = False Then Begin
      ErrVar := GetLastError();
      Messagebox(0,'Failed to Set Pixel Format!', 'Error', MB_OK or MB_ICONEXCLAMATION);
      SendMessage(TempWindow,WM_QUIT,0,0);
      Exit;
    End;

    // Create the initial Context
    Options := [opDoubleBuffered,opGDI];
    TempRDC := wglCreateContext(TempDC);

      If TempRDC = 0 Then Begin
        MessageBox(0,'Failed to Create Rendering Context!','Error', MB_OK or MB_ICONEXCLAMATION);
        PostQuitMessage(0);
        Exit;
      End;


    // Make the initial Context current
    ActivateRenderingContext(TempDC,TempRDC,True);
    If wglMakeCurrent(TempDC,TempRDC) = False Then Begin
      MessageBox(0,'Failed to Make the Context Current!','Error', MB_OK or MB_ICONEXCLAMATION);
      PostQuitMessage(0);
      Exit;
    End;

    // Create the real window, make sure client area is sized to width and height
    wRect := Rect(0,0,Context.Width,Context.Height);

    If Context.wFormat.TitleBar = True Then Begin
      AdjustWindowRect(wRect,WS_CAPTION,false);
      Context.wWindowRect := wRect;
    End;

    Context.wHandle := CreateWindowEX(WS_EX_LEFT,'OpenGL Window',
      'OpenGL Window',WS_VISIBLE,0,0,wRect.Width,wRect.Height,0,0,System.MainInstance,nil);

    If Context.wHandle = 0 Then Begin
      MessageBox(0,'Failed to Create the Final Window!','Error', MB_OK or MB_ICONEXCLAMATION);
      PostQuitMessage(0);
      Exit;
    End;

    Context.SetHasCaption(Context.wFormat.TitleBar);
    Context.RestoreStyleFlags();

    GetClientRect(Context.wHandle, Context.wClientRect);
    GetWindowRect(Context.wHandle, Context.wWindowRect);

    ShowWindow(Context.Handle,1);

    Context.wDC := GetDC(Context.wHandle);
    Context.wMinWidth := 150;
    Context.wMinHeight := 150;

    ZeroMemory(@Context.OrgDevMode,SizeOf(DevMode));
    Context.OrgDevMode.dmBitsPerPel := 32;
    Context.OrgDevMode.dmPelsWidth := Context.ScreenWidth;
    Context.OrgDevMode.dmPelsHeight := Context.ScreenHeight;
    Context.OrgDevMode.dmSize := SizeOf(DevMode);
    Context.OrgDevMode.dmFields := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;

    Move(Context.OrgDevMode, Context.CurDevMode, SizeOf(DevMode));
    Context.CurDevMode.dmPelsWidth := Context.wWidth;
    Context.CurDevMode.dmPelsHeight := Context.wHeight;

    // Set ARB Pixel Attributes to Variable
    PixelAttribs.AddAttribs(ReturnARBPixelFormat.Attribs);

    // Attempt to get new pixel format ID
    ZeroMemory(@ReturnedFormats[0], SizeOf(Integer) * Length(ReturnedFormats));
    numFormats := 0;
    PixelFormatID := 0;
    Status := wglChoosePixelFormatARB(Context.DC,@PixelAttribs.Attribs[0],nil,100,@ReturnedFormats,@numFormats);

      If (Status = False) or (numFormats = 0) Then Begin
        MessageBox(0,'Failed to Get ID of new Pixel Format','Error', MB_OK or MB_ICONEXCLAMATION);
        SendMessage(TempWindow,WM_QUIT,0,0);
        SendMessage(Context.Handle,WM_QUIT,0,0);
        Exit;
      End;

    // just go ahead and describe all the returned formats for debugging purposes
    for I := 0 to numFormats - 1 do begin
      DescribePixelFormat(Context.DC,ReturnedFormats[i],SizeOf(PixelFormat),DescForms[i]);
    end;

    Status := False;
    For I := 0 to numFormats - 1 Do Begin
      DescribePixelFormat(Context.DC,ReturnedFormats[i],SizeOf(PixelFormat),PixelFormat);
      Status := SetPixelFormat(Context.Dc,ReturnedFormats[i],@PixelFormat);

      If Status = True Then Begin
        Break;
      End;

    End;

      If (Status = False) or (High(ReturnedFormats) = 0) Then Begin
        MessageBox(0,'FAILED TO SET NEW PIXEL FORMAT!','ERROR', MB_OK);
        Context.wShouldClose := True;
        SendMessage(Context.Handle,WM_DESTROY,0,0);
        AllocConsole();
        Exit;
      End;

    // Create New Context with Extensions
    ContextMajor := Context.wFeatures.OpenGLMajorVersion;
    ContextMinor := Context.wFeatures.OpenGLMinorVersion;
    RDC := 0;

    While RDC = 0 Do Begin
      RDC := ConstructContextAttributes(ContextMajor,ContextMinor);

      If RDC = 0 then Begin
        ContextMinor := ContextMinor - 1;
        If ContextMinor = -1 Then Begin
          ContextMinor := 9;
          ContextMajor := ContextMajor - 1;
        End;
      End;

      // If the context is too low, destroy the window and exit
      If (ContextMajor = 1) and (ContextMinor < 2) Then Begin
          MessageBox(0,'Failed To Create Extended Context!','Error',MB_OK);
          PostQuitMessage(0);
          Exit;
      End;

    End;


    // Clean Up Temporary Context and Window
    wglMakeCurrent(TempDC,0);
    wglDeleteContext(TempRDC);
    DestroyWindow(TempWindow);
    ReleaseDC(TempWindow,TempDC);

    // Make the Extended Context Current
    ActivateRenderingContext(Context.DC,RDC,True);

    If Context.wFeatures.OpenGLDebugContext = True Then Begin
      glEnable(GL_DEBUG_OUTPUT);
      glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
      Context.wDebugToConsole := True;
      Context.wDebugToLog := False;
      Context.wDebugToMsgBox := False;
      Context.RegisterDebugCallBack(@Debug);
    End;

    // Apply vSync Option
    If Context.Format.VSync = True Then Begin
      wglSwapIntervalEXT(1);
    End Else Begin
      wglSwapIntervalEXT(0);
    End;

    // Enable or Disable MultiSampling
    If Context.wFormat.Samples = 0 Then Begin
      glDisable(GL_MULTISAMPLE);
    End Else Begin
      glEnable(GL_MULTISAMPLE);
    End;

    glEnable(GL_TEXTURE_2D);
    glEnable(GL_PROGRAM_POINT_SIZE);
    glEnable(GL_POINT_SMOOTH);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    CheckGLStatus();
  End;


Procedure CheckGLStatus();
Var
DoubleBuffer: GLInt;
NumExt: GLint;
Samples: GLInt;
RedBits,GreenBits,Bluebits,AlphaBits: GLInt;
  Begin
    glGetIntegerV(GL_MAJOR_VERSION,@Context.wMajVersion);
    glGetIntegerV(GL_MINOR_VERSION,@Context.wMinVersion);
    glGetBooleanV(GL_MULTISAMPLE,@Context.wMultiSampled);
    glGetIntegerV(GL_SAMPLES,@Context.wFormat.Samples);
    glGetIntegerV(GL_NUM_EXTENSIONS, @NumExt);
    glGetIntegerV(GL_STENCIL_BITS, @Context.wFormat.StencilBits);
    glGetIntegerV(GL_DEPTH_BITS, @Context.wFormat.DepthBits);
    glGetintegerV(GL_RED_BITS, @RedBits);
    glGetintegerV(GL_GREEN_BITS, @GreenBits);
    glGetintegerV(GL_BLUE_BITS, @BlueBits);
    glGetintegerV(GL_ALPHA_BITS, @AlphaBits);
  End;


Function WindowProc(Handle: HWND; Messages: Cardinal; wParameter: WPARAM; lParameter: LPARAM): LRESULT;

Var
PtrWinPos: PWindowPos;
WinPos: WINDOWPOS;
PtrMinMax: PMINMAXINFO;
MinMax: MINMAXINFO;
PStruct: PaintStruct;
P1,P2: TPOINT;
wRect: TRECT;
ButtonVal: LongInt;
Focus: Integer;
Command: Integer;
HR: HRESULT;
Success: Boolean;

  Begin

    Result := 1;

    If Handle = Context.Handle Then Begin
      SetLength(Context.wMessageList, Length(Context.wMessageList) + 1);
      Context.wMessageList[High(Context.wMessageList)] := Messages;
    End;

    Context.wSizeChanged := False;

    Case Messages of


     // Handle any close or destroy messages
      WM_CLOSE:
        Begin

          If Handle = Context.wHandle Then Begin
            Context.Close();
          End;

        End;

      WM_CREATE:
        Begin
          GetWindowRect(Context.Handle, Context.wWindowRect);
          GetClientRect(Context.Handle, Context.wClientRect);
        End;

     // If keyboard functionality was requested, handle keyboard messages, else DefWindowProc
     WM_KEYDOWN, WM_KEYUP:
       If Context.wFeatures.UseKeyBoardInput = True Then Begin
        Result := Context.ProcessKeyBoardMessages(Handle,Messages,wParameter,lParameter);
       End Else Begin
        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
       End;

     // If Character functionality was requested, handle WM_CHAR, else DefWindowProc
     WM_CHAR:
      Begin
        If Context.wFeatures.UseCharacterInput = True Then Begin
          Result := Context.ProcessCharMessages(Handle,Messages,wParameter,lParameter);
        End Else Begin
          Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
        End;
      End;

     // If Mouse functionality was request, handle mouse messages, else DefWindowProc
     WM_MOUSEMOVE, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_RBUTTONDOWN, WM_RBUTTONUP, WM_XBUTTONDOWN, WM_XBUTTONUP:
      Begin
        If Context.wFeatures.UseMouseInput = True Then Begin
          Result := Context.ProcessMouseMessages(Handle,Messages,wParameter,lParameter);
        End Else Begin
          Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
        End;
      End;

     WM_ACTIVATE:
      Begin
          Focus := LoWord(wParameter);

          If Focus = 0 Then Begin

            Context.wHasFocus := False;

            If Context.FullScreen = True Then Begin
              ReturnDisplayMode();
            End;

            If Assigned(Context.LostFocusCallBack) Then Begin
              Context.LostFocusCallBack();
            End;

          End Else Begin

            Context.wHasFocus := True;

            If Context.FullScreen = True Then Begin
              Context.ChangeResolution(Point(Context.Width,Context.Height));
            End;

            If Assigned(Context.GotFocusCallBack) Then Begin
              Context.GotFocusCallBack();
            End;
          End;

      End;


     WM_SETCURSOR:
      Begin
        If Context.Mouse.Cursor <> 0 Then Begin
          Result := 1;
        End Else Begin
          Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
        End;
      End;

     WM_SIZE:
      Begin
        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     WM_MOVE:
      Begin
        If Assigned(Context.MoveCallBack) Then Context.MoveCallBack(Context.X,Context.Y);
        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     WM_WINDOWPOSCHANGING:
      Begin
        If Context.IsReady = True Then Begin

          Context.wSizeChanged := True;

          If Context.FullScreen = False Then Begin

            // Keep Minimum Width and Height
            If Context.Width < Context.MinWidth Then Begin
              Context.wWidth := Context.MinWidth;
              Context.SetSize(Context.Width,Context.Height,True);
            End;

            If Context.Height < Context.MinHeight Then Begin
              Context.wHeight := Context.MinHeight;
              Context.SetSize(Context.Width,Context.Height,True);
            End;

            Result := DefWindowProc(Handle,Messages,wParameter,lParameter);

          End Else Begin
            Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
          End;

        End Else Begin

          Result := DefWindowProc(Handle,Messages,wParameter,lParameter);

        End;

      End;

     WM_WINDOWPOSCHANGED:
      Begin
        PtrWinPos := PWindowPos(lParameter);
        WinPos := PtrWinPos^;

        Result := 0;

        If Assigned(Context.SizeCallBack) Then Begin
          Context.SizeCallBack(Context.X,Context.Y,Context.Width,Context.Height);
        End;

      End;

     WM_SYSCOMMAND:
      Begin

        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
        Command := HiWord(wParameter);

        If Command = SC_MAXIMIZE Then Begin
          Context.wIsMaxed := True;
          Context.wIsMinimized := false;
          If Assigned(Context.MaximizeCallBack) Then Context.MaximizeCallBack();

        End Else If Command = SC_MINIMIZE Then Begin
          Context.wIsMaxed := False;
          Context.wIsMinimized := True;
          If Assigned(Context.MinimizeCallBack) Then Context.MinimizeCallBack();

        End Else If Command = SC_RESTORE Then Begin
          Context.wIsMaxed := False;
          Context.wIsMinimized := False;
          If Assigned(Context.RestoreCallBack) Then Context.RestoreCallBack();

        End Else If Command = SC_MOVE Then Begin
          If Context.FullScreen = True Then Begin
            Result := 0;
          End;

        End;


      End;

     WM_PAINT:
      Begin
        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     WM_ERASEBKGND:
      Begin
        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     Else
      Result := DefWindowProc(Handle, Messages, wParameter, lParameter);

    End;

  End;


Procedure ReturnDisplayMode();
  Begin
    Context.ChangeResolution(Point(Context.OrgDevMode.dmPelsWidth, Context.OrgDevMode.dmPelsHeight));
  End;

procedure CreateDEVMODE(out ADEVMODE: DEVMODE; AWidth,AHeight: NativeUInt);
  begin
    ZeroMemory(@ADEVMODE, SizeOf(ADEVMODE));
    ADEVMODE.dmSize := SizeOf(ADEVMODE);
    ADEVMODE.dmBitsPerPel := 32;
    ADEVMODE.dmPelsWidth := AWidth;
    ADEVMODE.dmPelsHeight := AHeight;
    ADEVMODE.dmFields := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;
  end;


Procedure GetKeyDown(Var Value: wParam);
  Begin

    If (Assigned(Context.wKeyBoard.KeyDown)) or (Assigned(Context.wKeyBoard.KeyPress)) Then Begin

      If Value = VK_SHIFT Then Begin
        Context.wKeyBoard.wShift := True;
      End;

      If Value = VK_MENU Then Begin
        Context.wKeyBoard.wAlt := True;
      end;

      If Context.wKeyBoard.Key[Value] = 1 Then Begin

        If Assigned(Context.wKeyBoard.KeyPress) Then Begin
          Context.wKeyBoard.KeyPress(Value, Context.wKeyBoard.Shift, Context.wKeyBoard.Alt);
        End;

        if Assigned(Context.wKeyBoard.KeyDown) then begin
          Context.wKeyBoard.KeyDown(Value, Context.wKeyBoard.Shift, Context.wKeyBoard.Alt);
        end;
      End Else Begin

        if Assigned(Context.wKeyBoard.KeyDown) then begin
          Context.wKeyBoard.KeyDown(Value, Context.wKeyBoard.Shift, Context.wKeyBoard.Alt);
        end;
      End;

    End;

  End;


Procedure GetKeyUp(Var Value: wParam);
  Begin
    If Assigned(Context.wKeyBoard.KeyUp) Then Begin

      If Value = VK_SHIFT Then Begin
        Context.wKeyBoard.wShift := False;
      End;

      If Value = VK_MENU Then Begin
        Context.wKeyBoard.wAlt := False;
      end;

      Context.wKeyBoard.KeyUp(Value, Context.wKeyBoard.Shift, Context.wKeyBoard.Alt);
    End;
  End;



Function pglCreateIcon(SourceIcon: HICON): TPGLIcon;
Var
ICINFO: ICONINFOEXW;
BM: BITMAP;
  Begin
    GetIconInfoEX(SourceIcon,@ICInfo);
    GetObject(ICInfo.hbmColor,SizeOf(BM),@BM);
    Result.wIcon := CopyIcon(SourceIcon);
    Result.wWidth := BM.bmWidth;
    Result.wHeight := BM.bmHeight;
    Result.wHotSpot := POINT(ICINFO.xHotspot, ICINFO.yHotSpot);
  End;

Function pglCreateIconFromFile(FileName: String; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0): TPGLIcon;
Var
Image: Pointer;
Width,Height,Channels,BPP: GLInt;

  Begin

    Image := stbi_load(PAnsiChar(AnsiString(FileName)),Width,Height,Channels,4);

    Result := pglCreateIconFromPointer(Image,Width,Height,32,HotSpotX,HotSpotY);

    stbi_image_free(Image);

  End;


Function pglCreateIconFromPointer(Source: Pointer; Width,Height,BPP: GLUInt; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0): TPGLIcon;
Var
IconStruct: _ICONINFO;
BitMap: HBITMAP;
I,Z: Longint;
SrcPtr: PByte;
UseBytes: Array of Byte;
TempRed, TempBlue: Byte;
MaskPos: Integer;
BitInfo: tagBITMAP;
UseLen: GLInt;

  Begin

    UseLen := trunc(BPP / 8);
    SrcPtr := Source;
    SetLength(UseBytes,UseLen);
    MaskPos := 0;

    For I := 0 to (Width * Height) Do Begin

      Move(SrcPtr[MaskPos],UseBytes[0],UseLen);

      // Swap blue and red bytes
      TempRed := UseBytes[2];
      TempBlue := Usebytes[0];
      UseBytes[0] := TempRed;
      UseBytes[2] := TempBlue;

      If (UseBytes[0] = 255) And
         (UseBytes[1] = 255) And
         (UseBytes[2] = 255) Then Begin

         For z := 0 to UseLen - 1 Do Begin
          UseBytes[z] := 0;
         End;

      End;

      Move(Usebytes[0],SrcPtr[MaskPos],UseLen);

      MaskPos := MaskPos + UseLen;

    End;

    BitInfo.bmType := 0;
    BitInfo.bmWidth := Width;
    BitInfo.bmHeight := Height;
    BitInfo.bmWidthBytes := (Integer(Width) * USeLen);
    BitInfo.bmPlanes := 1;
    BitInfo.bmBitsPixel := BPP;
    BitInfo.bmBits := @SrcPtr[0];

    BitMap := CreateBitMapIndirect(BitInfo);

    ZeroMemory(@IconStruct,SizeOf(IconStruct));
    IconStruct.fIcon := False;
    IconStruct.xHotspot := HotSpotX;
    IconStruct.yHotspot := HotSpotY;
    IconStruct.hbmMask := BitMap;
    IconStruct.hbmColor := BitMap;

    DeleteObject(BitMap);

    Result.wIcon := CreateIconIndirect(IconStruct);
    Result.wWidth := Width;
    Result.wHeight := Height;
    Result.wHotSpot := POINT(HotSpotX,HotSpotY);




  End;

function GET_X_LPARAM(lParam: NativeInt): Integer;
  begin
    Result := Smallint(LoWord(lParam));
  end;


function GET_Y_LPARAM(lParam: NativeInt): Integer;
  begin
    Result := Smallint(HiWord(lParam));
  end;


Function StringAdd(Source: String; Val: String): String;

Var
CurVal: String;
I: Long;

  Begin

    If Length(Val) = 0 Then Exit;

    For I := 1 to Length(Val) Do Begin

      CurVal := Val[I];

      If CurVal = Char(VK_BACK) Then Begin

        If Length(Source) <> 0 Then Begin
          Source := Copy(Source,1,Length(Source) - 1);
        End;

      End Else If CurVal = Char(VK_RETURN) Then Begin
        Source := Source + sLineBreak;

      End Else If CurVal = Char(VK_ESCAPE) Then Begin
        // Do nothing, ignore the escape

      End Else If CurVal = Char(VK_TAB) Then Begin
        Source := Source + '    ';

      End Else Begin
        Source := Source + CurVal;
      End;

    End;

    Result := Source;

  End;

Procedure SetBit(Var TargetByte: Byte; Value: Byte; Index: Byte);
  Begin
    TargetByte := TargetByte or (WORD(Value) shl Index);
  End;

Function ReadBit(Var TargetByte: Byte; Index: Byte): Byte;
  Begin
    Result := Byte((Word(TargetByte) shr Index) and 1 = 1);
  End;

Function GetBitValue(Index: Byte): Long;
  Begin
    Result := -1;
    If Index > 63 Then Exit;

    Result := trunc(IntPower(2,Index));
  End;

Function ClampToDeadZone(Value,DeadZone: Integer): Single;
  Begin
    If Abs(Value) <= DeadZone Then Begin
      Result := 0;
    End Else Begin
      Result := (Value / High(Int16));
    End;
  End;


Procedure CreateDebugMessage(AMessage: String);
  begin
    Debug(999,999,999,999,Length(AMessage),PAnsiChar(AnsiString(AMessage)),nil);
  end;

Procedure Debug(Source: GLenum; MessageType: GLenum; ID: GLuint; Severity: GLUint; MessageLength: GLsizei; const DebugMessage: PGLChar; const UserParam: Pointer); stdCall;
Var
I: Long;
Chars: Array of AnsiChar;
ErrorString: String;
SourceString: String;
TypeString: String;
SeverityString: String;
FinalString: String;

  Begin

    if Context.IgnoreDebug then Exit;

    If MessageLength = 0 Then Exit;
    If MessageType = GL_DEBUG_TYPE_OTHER_ARB Then Exit;

    // Translate the Error Message to String
    SetLength(Chars,MessageLength);
    ErrorString := '';
    For I := 0 to MessageLength - 1 Do Begin
      Chars[i] := (DebugMessage[i]);
      ErrorString := ErrorString + string(Chars[i]);
    end;
    // Translate the Source Enum to String
    Case Source of
      GL_DEBUG_SOURCE_API_ARB:
        SourceString := 'API: INVALID COMMAND';
      GL_DEBUG_SOURCE_WINDOW_SYSTEM_ARB:
        SourceString := 'WINDOW SYSTEM';
      GL_DEBUG_SOURCE_SHADER_COMPILER_ARB:
        SourceString := 'SHADER COMPILATION';
      GL_DEBUG_SOURCE_THIRD_PARTY_ARB:
        SourceString := 'THIRD PARTY SOURCE';
      GL_DEBUG_SOURCE_APPLICATION_ARB:
        SourceString := 'APPLICATION';
      GL_DEBUG_SOURCE_OTHER_ARB:
        SourceString := 'OTHER SOURCE';
      Else
        SourceString := 'UNSPECIFIED SOURCE';
    End;
    // Translate Message Type Enum to String
    Case MessageType of
      GL_DEBUG_TYPE_ERROR_ARB:
        TypeString := 'ERROR';
      GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR_ARB:
        TypeString := 'WARNING: DEPRECATED BEHAVIOR';
      GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR_ARB:
        TypeString := 'WARNING: UNDEFINED BEHAVIOR';
      GL_DEBUG_TYPE_PORTABILITY_ARB:
        TypeString := 'WARNING: PORTABILITY';
      GL_DEBUG_TYPE_PERFORMANCE_ARB:
        TypeString := 'WARNING: PERFORMANCE';
      GL_DEBUG_TYPE_OTHER_ARB:
        TypeString := 'WARNING: OTHER';
      else
        TypeString := 'UNSPECIFIED MESSAGE TYPE';
    End;
    // Translate Severity Message to String
    Case Severity of
      GL_DEBUG_SEVERITY_HIGH_ARB:
        SeverityString := 'HIGH';
      GL_DEBUG_SEVERITY_MEDIUM_ARB:
        SeverityString := 'MEDIUM';
      GL_DEBUG_SEVERITY_LOW_ARB:
        SeverityString := 'LOW';
    End;
    FinalString := '---------------------------------------------------------' + sLineBreak +
                   'TYPE: ' + TypeString + sLineBreak +
                   'SOURCE: ' + SourceString + sLineBreak +
                   'SEVERITY: ' + SeverityString + sLineBreak +
                   'MESSAGE: ' + ErrorString + sLineBreak +
                   '---------------------------------------------------------';

    If Context.wDebugToMsgBox Then Begin
      MessageBox(0,PWideChar(String(FinalString)),'DEBUG MESSAGE', MB_OK or MB_ICONEXCLAMATION);

    End Else If Context.wDebugToConsole Then Begin
      AllocConsole();
      WriteLn(FinalString);

    End Else If Context.wDebugToLog Then Begin
      Inc(Context.wDebugCount);
      SetLength(Context.wDebugLog,Context.wDebugCount);
      Context.wDebugLog[Context.wDebugCount -1] := FinalString;
    End;


    DebugBreak();



  End;


end.
