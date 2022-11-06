unit glDrawContext;

interface

{$POINTERMATH ON}
{$WARN EXPLICIT_STRING_CAST_LOSS OFF}

Uses
  SysUtils, Classes, Messages, WinAPI.Windows, WinAPI.DwmApi, WinAPI.UxTheme,
  dglOpenGL, Neslib.stb.image, Neslib.stb.imagewrite, UnitXInput, Math;

  (* CallBack Types *)
  Type
    pglHookProc = Function(nCode: Integer; wParameter: NativeUInt; lParameter: NativeInt): LRESULT; stdcall;
    pglKeyCallBack = Procedure(Key: NativeUInt; Shift, Alt: Boolean); Register;
    pglMouseCallBack= Procedure(X,Y: Single; Button: Integer; Shift: Boolean; Alt: Boolean); Register;
    pglControllerButtonCallBack = Procedure(Button: Word); Register;
    pglControllerStateCallBack = Procedure(LeftStick,RightStick: TPointFloat; LeftTrigger,RightTrigger: Byte); Register;
    pglControllerStickCallBack = Procedure(LeftStick,RightStick: TPointFloat); Register;
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

  type RAWINPUTDEVICE = Record
    hDevice: LONGWORD;
    dwType: DWORD;
  End;

  type tagRAWINPUTDEVICELIST = Array of RAWINPUTDEVICE;


  type pglAttribs = Record

    Public
      Count: GLInt;
      Attribs: Array of GLInt;

      Class Operator Initialize(Out Dest: pglAttribs);
      Procedure AddAttribs(Values: Array of GLInt);
  End;

  Type pglWindowFormat = Record
      ColorBits: GLUint;
      DepthBits: GLUInt;
      StencilBits: GLUInt;
      Samples: GLUInt;
      VSync: GLBoolean;
      BufferCopy: GLBoolean;
      FullScreen: GLBoolean;
      TitleBar: Boolean;
      Maximize: Boolean;

      Class Operator Initialize( Out Dest: pglWindowFormat); Register;
  End;

    Type PpglWindowFormat = ^pglWindowFormat;

  Type pglFeatureSettings = Record
    UseKeyBoardInput: Boolean;
    UseCharacterInput: Boolean;
    UseMouseInput: Boolean;
    OpenGLMajorVersion: GLInt;
    OpenGLMinorVersion: GLint;
    OpenGLCompatibilityContext: Boolean;
    OpenGLDebugContext: Boolean;

    Class Operator Initialize (Out Dest: pglFeatureSettings); Register;
  End;

    Type PpglFeatureSettings = ^pglFeatureSettings;


  (* Classes *)

  Type pglIcon = Record
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

  Type pglKeyBoardInstance = Class(TObject)
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
      Procedure RegisterKeyDownCallBack(Proc: pglKeyCallBack); Register;
      Procedure RegisterKeyUpCallBack(Proc: pglKeyCallBack); Register;
      Procedure RegisterKeyPressCallBack(Proc: pglKeyCallBack); Register;
      Procedure RegisterKeyHeldCallBack(Proc: pglKeyCallBack); Register;
      Procedure RegisterKeyCharCallBack(Proc: pglKeyCharCallBack); Register;

  End;


  Type pglMouseInstance = Class(TObject)
    Private
      MouseDownCallBack: pglMouseCallBack;
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
      wInWindow: Boolean;
      wScale: Boolean;

      Cursor: HICON;
      IconSource: ^pglIcon;

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

//      Class Operator Initialize(Out Dest: pglMouseInstance); Register;
      Constructor Create();

      Procedure SetVisible(Enable: Boolean = True); Register;
      Procedure MovePosition(X,Y: Single); Register;
      Procedure SetPosition(X,Y: Single); Register;
      Procedure SendButtonClick(ButtonIndex: Byte); Register;
      Procedure ReleaseButton(ButtonIndex: Byte); Register;
      Procedure SetMouseLock(X,Y: Single; Locked: Boolean = True); Register;
      Procedure SetCursorFromFile(FileName: String; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0); Register;
      Procedure SetCursorFromBits(Source: Pointer; Width,Height,BPP: GLUint; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0); Register;
      Procedure SetCursorFromIcon(Var Source: pglIcon); Register;
      Procedure ScaleToResolution(Enable: Boolean = True); Register;

      Procedure RegisterLeaveCallBack(Proc: pglCallBack); Register;
      Procedure RegisterEnterCallBack(Proc: pglCallBack); Register;
      Procedure RegisterMouseDownCallBack(Proc: pglMouseCallBack); Register;
      Procedure RegisterMouseUpCallBack(Proc: pglMouseCallBack); Register;
      Procedure RegisterMouseMoveCallBack(Proc: pglMouseCallBack); Register;

      Function InWindow(): Boolean; Register;
  End;


  Type pglControllerInstance = Class(TObject)

    Private
      Enabled: Boolean;
      Connected: Array [0..3] of Boolean;
      State: TXInputState;
      BatteryState: TXInputBatteryInformation;
      wBatteryLevel: Single;
      DeviceType: Byte;
      ButtonDownCallBack: pglControllerButtonCallBack;
      ButtonUpCallBack: pglControllerButtonCallBack;
      StateChangeCallBack: pglControllerStateCallBack;
      StickCallBack: pglControllerStickCallBack;
      LSX,LSY,RSX,RSY: ^Int16;
      wLeftStick,wRightStick: TPointFloat;
      LSDeadZone,RSDeadZone: DWORD;
      wA,wB,wX,wY,wLeft,wRight,wUp,wDown,wStart,wBack: Word;

      Procedure HandleStateChange(sender:TObject;userIndex:uint32;newState:TXInputState);
      Procedure HandleConnect(sender:TObject;userIndex:uint32);
      Procedure HandleDisconnect(sender:TObject;userIndex:uint32);
      Procedure HandleButtonDown(sender:TObject;userIndex:uint32;buttons:word);
      Procedure HandleButtonUp(sender:TObject;userIndex:uint32;buttons:word);
      Procedure HandleButtonPress(sender:TObject;userIndex:uint32;buttons:word);
      Procedure HandleStickHeld();
      Procedure QueryState();

    Public

      Property AButton: Word read wA;
      Property BButton: Word read wB;
      Property XButton: Word read wX;
      Property YButton: Word read wY;
      Property LeftButton: Word read wLeft;
      Property RightButton: Word read wRight;
      Property UpButton: Word read wUp;
      Property DownButton: Word read wDown;
      Property StartButton: Word read wStart;
      Property BackButton: Word read wBack;
      Property LeftStick: TPointFloat read wLeftStick;
      Property RightStick: TPointFloat read wRightStick;
      Property BatteryLevel: Single read wBatteryLevel;

      Constructor Create();
      Procedure RegisterButtonDownCallBack(Proc: pglControllerButtonCallBack);
      Procedure RegisterButtonUpCallBack(Proc: pglControllerButtonCallBack);
      Procedure RegisterStateChangeCallBack(Proc: pglControllerStateCallBack);
      Procedure RegisterStickHeldCallBack(Proc: pglControllerStickCallBack);

  End;


  Type pglContext = Class(TObject)

    Private

      // Attributes and flags
      IsReady: Boolean;
      wUpdating: Boolean;
      wHandle: HWND;
      wDC: HDC;
      wMajVersion: GLInt;
      wMinVersion: GLint;
      wMultiSampled: Boolean;
      wFeatures: pglFeatureSettings;
      wDebugToConsole: Boolean;
      wDebugToLog: Boolean;
      wDebugToMsgBox: Boolean;
      wBreakOnDebug: Boolean;
      wDebugLog: Array of String;
      wDebugCount: Integer;
      wIcon: HICON;
      wTitle: String;
      wMessageList: Array of Cardinal;

      // Dimensions
      wWidth: GLUint;
      wHeight: GLUint;
      wMinWidth, wMinHeight: GLUInt;
      wX,wY: GLUint;
      wReturnX, wReturnY: GLUint;
      wCenterX, wCenterY: GLUint;
      wWindowRect: TRECT;
      wClientRect: TRECT;
      wWindowRgn: HRGN;
      wMargins: TMargins;
      wBorderWidth: GLUint;
      wTitleBarHeight: GLUint;
      wShouldClose: Boolean;
      wScreenWidth, wScreenHeight: GLUint;
      wHasStencil: Boolean;
      wHasDepth: Boolean;
      wFormat: pglWindowFormat;

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

      // Functionality Flags
      wKeyBoard: pglKeyBoardInstance;
      wMouse: pglMouseInstance;
      wController: pglControllerInstance;
      wUseKeyInput: Boolean;
      wUseCharacterInput: Boolean;
      wUseMouseInput: Boolean;
      wDeviceList: tagRAWINPUTDEVICELIST;
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

      OrgDevMode: DevMode;
      CurDevMode: DevMode;

      Procedure GetInputDevices(); Register;
      Procedure UpdateRects(); Register;
      Procedure RestoreStyleFlags(); Register;
      Procedure CleanUp(); Register;
      Function ProcessKeyBoardMessages(Var Handle: HWND; Var Messages: Cardinal; Var wParameter: WPARAM; Var lParameter: LPARAM): LRESULT;
      Function ProcessMouseMessages(Var Handle: HWND; Var Messages: Cardinal; Var wParameter: WPARAM; Var lParameter: LPARAM): LRESULT;
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
      Property ShouldClose: Boolean read wShouldClose;
      Property ScreenWidth: GLUint read wScreenWidth;
      Property ScreenHeight: GLUint read wScreenHeight;
      Property Format: pglWindowFormat read wFormat;
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
      Property Keyboard: pglKeyBoardInstance read wKeyBoard;
      Property Mouse: pglMouseInstance read wMouse;
      Property Controller: pglControllerInstance read wController;

      Constructor Create();

      Procedure PollEvents(); Register;
      Procedure Close(); Register;
      Procedure SetTitle(Text: String); Register;
      Procedure SetIconFromFile(FileName: String); Register;
      Procedure SetIconFromBits(Source: Pointer; Width,Height,BPP: GLUint); Register;
      Procedure SetPosition(X,Y: GLUint); Register;
      Procedure SetSize(W,H: GLInt; KeepCentered: Boolean = True); Register;
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

      Procedure RegisterSizeCallBack(Proc: pglWindowSizeCallBack); Register;
      Procedure RegisterMoveCallBack(Proc: pglWindowMoveCallBack); Register;
      Procedure RegisterMaximizeCallBack(Proc: pglCallBack); Register;
      Procedure RegisterMinimizeCallBack(Proc: pglCallBack); Register;
      Procedure RegisterRestoreCallBack(Proc: pglCallBack); Register;
      Procedure RegisterGotFocusCallBack(Proc: pglCallBack); Register;
      Procedure RegisterLostFocusCallBack(Proc: pglCallBack); Register;
      Procedure RegisterDebugCallBack(Proc: TglDebugProc); Register;

      Procedure SetDebugToConsole(); Register;
      Procedure SetDebugToLog(); Register;
      Procedure SetDebugToMsgBox(); Register;
      Procedure SetBreakOnDebug(Enable: Boolean); Register;
      Procedure GetDebugLog(Out Buffer: Array of String);

  end;

  (* PROCEDURES *)

  Procedure pglStart(Width,Height: GLUint; Format: pglWindowFormat; Features: pglFeatureSettings; Title: String); stdcall; cdecl;
  Procedure CreateGLContext(); Register;
  Procedure CheckGLStatus(); Register;
  Function WindowProc(Handle: HWND; Messages: Cardinal; wParameter: WPARAM; lParameter: LPARAM): LRESULT; cdecl; stdcall;
  Procedure Debug(Source: GLenum; MessageType: GLenum; ID: GLuint; Severity: GLUint; MessageLength: GLsizei; const DebugMessage: PGLCHar; const UserParam: PGLVoid); stdcall;
  Procedure ReturnDisplayMode(); Register;

  Function ReturnPFDFlags(): Integer; Register;
  Function ReturnARBPixelFormat(): pglAttribs; Register;
  function ConstructContextAttributes(Maj,Min: Integer): HGLRC; Register;
  Procedure UpdatePixelFormat(DC: HDC; PixelID: Integer); Register;

  Procedure GetKeyDown(Var Value: wParam); Register;
  Procedure GetKeyUp(Var Value: wParam); Register;


  Function pglCreateIcon(SourceIcon: HICON): pglIcon; Register;
  Function pglCreateIconFromFile(FileName: String; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0): pglIcon; Register;
  Function pglCreateIconFromPointer(Source: Pointer; Width,Height,BPP: GLUInt; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0): pglIcon; Register;

  function GET_X_LPARAM(lParam: NativeInt): Integer;
  function GET_Y_LPARAM(lParam: NativeInt): Integer;
  Function StringAdd(Source: String; Val: String): String ; Register;
  Procedure SetBit(Var TargetByte: Byte; Value: Byte; Index: Byte); Register;
  Function ReadBit(Var TargetByte: Byte; Index: Byte): LongBool; Register;
  Function GetBitValue(Index: Byte): Long; Register; Inline;
  Function ClampToDeadZone(Value,DeadZone: Integer): Single;



Var
  Context: pglContext;
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



implementation


Uses
  glDrawMain;

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


(*------------------------------pglAttribs------------------------------------*)

Class Operator pglAttribs.Initialize(Out Dest: pglAttribs);
  Begin
    Dest.Count := 0;
  End;

Procedure pglAttribs.AddAttribs(Values: Array of GLint);
Var
I: LongInt;
  Begin
    for I := 0 to High(Values) Do Begin
      SetLength(Self.Attribs,Length(Self.Attribs) + 1);
      Inc(Self.Count);
      Self.Attribs[Self.Count - 1] := Values[i];
    End;
  End;

(*------------------------------pglWindowformat-------------------------------*)

Class Operator pglWindowformat.Initialize( Out Dest: pglWindowFormat); Register;
  Begin
    Dest.ColorBits := 32;
    Dest.DepthBits := 24;
    Dest.StencilBits := 8;
    Dest.Samples := 24;
    Dest.VSync := False;
    Dest.BufferCopy := False;
    Dest.FullScreen := False;
    Dest.TitleBar := False;
    Dest.Maximize := False;
  End;

(*------------------------------pglFeatureSettings----------------------------*)

Class Operator pglFeatureSettings.Initialize( Out Dest: pglFeatureSettings);
  Begin
    Dest.UseKeyBoardInput := True;
    Dest.UseCharacterInput := True;
    Dest.UseMouseInput := True;
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


Procedure pglIcon.SetTransparent(Color: WORD);
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


Procedure pglIcon.ChangeHotSpot(HotSpotX: Cardinal; HotSpotY: Cardinal);
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


Procedure pglIcon.ChangeSize(Width: Cardinal; Height: Cardinal);
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


Function pglIcon.Destroy(): Boolean;
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
(*                          pglKeyBoardInstance                               *)
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


Constructor pglKeyBoardInstance.Create();
  Begin
    Inherited;
  End;

Function pglKeyBoardInstance.GetKeyState(Index: Integer): Integer;
  Begin
    Result := Context.KeyBoard.Key[Index];
  End;

Procedure pglKeyBoardInstance.SwapChars();
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

Function pglKeyBoardInstance.CheckKeyCombo(Keys: array of NativeInt): Boolean; Register;
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

Function pglKeyBoardInstance.GetChars(): String;
  Begin
    Result := Self.wChars;
  End;

Procedure pglKeyBoardInstance.SendKeyPress(Key: NativeUInt);
  Begin
    If Key < 256 Then Begin
      Self.KeyPress(Key,Self.Shift,Self.Alt);
    End;
  End;

Procedure pglKeyBoardInstance.RegisterKeyDownCallBack(Proc: pglKeyCallBack);
  Begin
    If Context.wFeatures.UseKeyBoardInput = False Then Exit;
    Self.KeyDown := Proc;
  End;

Procedure pglKeyBoardInstance.RegisterKeyPressCallBack(Proc: pglKeyCallBack);
  Begin
    If Context.wFeatures.UseKeyBoardInput = False Then Exit;
    Self.KeyPress := Proc;
  End;

Procedure pglKeyBoardInstance.RegisterKeyHeldCallBack(Proc: pglKeyCallBack);
  Begin
    If Context.wFeatures.UseKeyBoardInput = False Then Exit;
    Self.KeyHeld := Proc;
  End;

Procedure pglKeyBoardInstance.RegisterKeyUpCallBack(Proc: pglKeyCallBack);
  Begin
    If Context.wFeatures.UseKeyBoardInput = False Then Exit;
    Self.KeyUp := Proc;
  End;

Procedure pglKeyBoardInstance.RegisterKeyCharCallBack(Proc: pglKeyCharCallBack);
  Begin
    If Context.wFeatures.UseCharacterInput = False Then Exit;
    Self.CharCallBack := Proc;
  End;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
(*                          pglMouseInstance                                  *)
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


//Class Operator pglMouseInstance.Initialize(Out Dest: pglMouseInstance);
//  Begin
//    Dest.wVisible := True;
//    Dest.wInWindow := True;
//  End;

Constructor pglMouseInstance.Create();
  Begin
    Self.wVisible := True;
    Self.wInWindow := True;
  End;

Procedure pglMouseInstance.SetVisible(Enable: Boolean = True);
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


Procedure pglMouseInstance.MovePosition(X,Y: Single);
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

Procedure pglMouseInstance.SetPosition(X: Single; Y: Single);
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

Procedure pglMouseInstance.SendButtonClick(ButtonIndex: Byte);
//Use to send a button down callback without changing the value of the mouse button
  Begin
    If ButtonIndex < 4 Then Begin
      If Self.wButton[ButtonIndex] <> 1 Then Begin
        Self.MouseDownCallBack(Self.wX, Self.wY, ButtonIndex, Context.wKeyBoard.Shift, Context.wKeyBoard.Alt);
      End;
    End;
  End;

Procedure pglMouseInstance.ReleaseButton(ButtonIndex: Byte);
//Use to send a button up callback without changing the value of the mouse button
  Begin
    If ButtonIndex < 4 Then Begin
      If Self.wButton[ButtonIndex] <> 1 Then Begin
        Self.MouseUpCallBack(Self.wX, Self.wY, ButtonIndex, Context.wKeyBoard.Shift, Context.wKeyBoard.Alt);
      End;
    End;
  End;

Function pglMouseInstance.InWindow(): Boolean;
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

Procedure pglMouseInstance.SetMouseLock(X: Single; Y: Single; Locked: Boolean = True);
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

Procedure pglMouseInstance.ReturnToLock();
Var
MP: TPOINT;
  Begin
    Self.SetPosition(Self.wLockX, Self.wLockY);
  End;

Procedure pglMouseInstance.SetCursorFromFile(FileName: String; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0);
Var
Image: Pointer;
Width,Height,Channels: GLInt;
  Begin
    Image := stbi_load(PansiChar(AnsiString(FileName)),Width,Height,Channels,4);
    Self.SetCursorFromBits(Image,Width,Height,32, HotSpotX, HotSpotY);
    stbi_image_free(Image);
  End;


Procedure pglMouseInstance.SetCursorFromBits(Source: Pointer; Width,Height,BPP: GLUint; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0);
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

Procedure pglMouseInstance.SetCursorFromIcon(Var Source: pglIcon);
  Begin
    Self.Cursor := Source.Icon;
    SetCursor(Self.Cursor);

    If Self.Cursor <> 0 Then Begin
      Self.IconSource := @Source;
    End;
  End;


Procedure pglMouseInstance.ScaleToResolution(Enable: Boolean = True);
  Begin
    Self.wScale := Enable;
  End;

Procedure pglMouseInstance.RegisterMouseDownCallBack(Proc: pglMouseCallBack);
  Begin
    If Context.wFeatures.UseMouseInput = False Then Exit;
    Context.wMouse.MouseDownCallBack := Proc;
  End;

Procedure pglMouseInstance.RegisterMouseUpCallBack(Proc: pglMouseCallBack);
  Begin
    If Context.wFeatures.UseMouseInput = False Then Exit;
    Context.wMouse.MouseUpCallBack := Proc;
  End;

Procedure pglMouseInstance.RegisterMouseMoveCallBack(Proc: pglMouseCallBack);
  Begin
    If Context.wFeatures.UseMouseInput = False Then Exit;
    Context.wMouse.MouseMoveCallBack := Proc;
  End;

Procedure pglMouseInstance.RegisterLeaveCallBack(Proc: pglCallBack);
  Begin
    Self.LeaveCallBack := Proc;
  End;

procedure pglMouseInstance.RegisterEnterCallBack(Proc: pglCallBack);
  Begin
    Self.EnterCallBack := Proc;
  End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
(*                          pglControllerInstan                               *)
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Constructor pglControllerInstance.Create();
  Begin
    Inherited;
    Self.Enabled := XInputAvailable();
    If Self.Enabled Then Begin
      XInput.onControllerConnect := Self.HandleConnect;
      XInput.onControllerDisconnect := Self.HandleDisconnect;
      XInput.onControllerStateChange := Self.HandleStateChange;
      XInput.onControllerButtonDown := Self.HandleButtonDown;
      XInput.onControllerButtonUp := Self.HandleButtonUp;
      XInput.onControllerButtonPress := Self.HandleButtonPress;
      XInput.refresh();

      Self.LSX := @Self.State.stGamepad.gpThumbLX;
      Self.LSY := @Self.State.stGamepad.gpThumbLY;
      Self.RSX := @Self.State.stGamepad.gpThumbRX;
      Self.RSY := @Self.State.stGamepad.gpThumbRY;
      Self.QueryState();

    end;
  End;

Procedure pglControllerInstance.HandleStateChange(sender:TObject;userIndex:uint32;newState:TXInputState);
  Begin
    If Assigned(Self.StateChangeCallBack) Then Begin
      Self.StateChangeCallBack(Self.LeftStick, Self.RightStick,
        newState.stGamepad.gpLeftTrigger, newState.stGamepad.gpLeftTrigger);
    End;

  End;

Procedure pglControllerInstance.HandleConnect(sender:TObject;userIndex:uint32);
  Begin

  End;

Procedure pglControllerInstance.HandleDisconnect(sender:TObject;userIndex:uint32);
  Begin

  End;

Procedure pglControllerInstance.HandleButtonDown(sender:TObject;userIndex:uint32;buttons:word);
Var
I: Long;
Hi,Lo: Byte;
Value: Word;
  Begin
    If Assigned(Self.ButtonDownCallBack) Then Begin

      Lo := LoByte(buttons);
      For I := 0 to 7 Do Begin
        If ReadBit(Lo,I) Then Begin
          Self.ButtonDownCallBack(GetBitValue(I));
        End;
      End;

      Hi := HiByte(buttons);
      For I := 0 to 7 Do Begin
        If ReadBit(Hi,I) Then Begin
          Self.ButtonDownCallBack(GetBitValue(I + 8));
        End;
      End;

    End;
  End;

Procedure pglControllerInstance.HandleButtonUp(sender:TObject;userIndex:uint32;buttons:word);
Var
I: Long;
Hi,Lo: Byte;
Value: Word;
  Begin
    If Assigned(Self.ButtonUpCallBack) Then Begin

      Lo := LoByte(buttons);
      For I := 0 to 7 Do Begin
        If ReadBit(Lo,I) Then Begin
          Self.ButtonUpCallBack(GetBitValue(I));
        End;
      End;

      Hi := HiByte(buttons);
      For I := 0 to 7 Do Begin
        If ReadBit(Hi,I) Then Begin
          Self.ButtonUpCallBack(GetBitValue(I + 8));
        End;
      End;

    End;
  End;

Procedure pglControllerInstance.HandleButtonPress(sender:TObject;userIndex:uint32;buttons:word);
  Begin

  End;

Procedure pglControllerInstance.HandleStickHeld();
  Begin
    If Assigned(Self.StickCallBack) Then Begin
      Self.QueryState();
      Self.StickCallBack(Self.wLeftStick, Self.wRightStick);
    End;
  End;

Procedure pglControllerInstance.RegisterButtonDownCallBack(Proc: pglControllerButtonCallBack);
  Begin
    Self.ButtonDownCallBack := Proc;
  End;

Procedure pglControllerInstance.RegisterButtonUpCallBack(Proc: pglControllerButtonCallBack);
  Begin
    Self.ButtonUpCallBack := Proc;
  End;

Procedure pglControllerInstance.RegisterStateChangeCallBack(Proc: pglControllerStateCallBack);
  Begin
    Self.StateChangeCallBack := Proc;
  End;

Procedure pglControllerInstance.RegisterStickHeldCallBack(Proc: pglControllerStickCallBack);
  Begin
    Self.StickCallBack := Proc;
  End;


Procedure pglControllerInstance.QueryState();
  Begin
    XInput.refresh();
    XInput.llGetState(0,@Self.State);
    Self.wLeftStick.X := ClampToDeadZone(Self.LSX^, 0);
    Self.wLeftStick.Y := ClampToDeadZone(Self.LSY^, 0);
    Self.wRightStick.X := ClampToDeadZone(Self.RSX^, 0);
    Self.wRightStick.Y := ClampToDeadZone(Self.RSY^, 0);

    XInput.llGetBatteryInformation(0,2,@Self.BatteryState);
    Self.wBatteryLevel := Self.BatteryState.biBatteryLevel;
  End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
(*                                pglContext                                  *)
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


Constructor pglContext.Create();
  Begin

  End;

Procedure pglContext.PollEvents();
Var
Messages: MSG;
I: Long;
P: TPOINT;

  Begin

    XInput.refresh();
    If Self.Controller.Enabled = True Then Begin
      Self.Controller.HandleStickHeld();
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


    While PeekMessage(Messages,Context.wHandle,0,0,PM_REMOVE) do Begin
//        // Don't translate if character input wasn't requested
        If Context.wFeatures.UseCharacterInput = True Then Begin
          TranslateMessage(Messages);
        End;

        DispatchMessage(Messages);
    End;

    // Execute Key Held CallBacks
    If Assigned(Self.KeyBoard.KeyHeld) Then Begin
      For I := 0 to 255 Do Begin
        If Self.KeyBoard.KeyState[I] <> 0 Then Begin
          Self.KeyBoard.KeyHeld(I,Self.KeyBoard.Shift,Self.KeyBoard.Alt);
        End;
      End;
    End;

  End;


Function pglContext.ProcessKeyBoardMessages(Var Handle: HWND; Var Messages: Cardinal; Var wParameter: WPARAM; Var lParameter: LPARAM): LRESULT;
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


Function pglContext.ProcessMouseMessages(Var Handle: HWND; Var Messages: Cardinal; Var wParameter: WPARAM; Var lParameter: LPARAM): LRESULT;
Var
P1,P2: TPOINT;
ButtonVal: Integer;
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

          If Assigned(Self.wMouse.MouseDownCallBack) Then Begin
            Self.wMouse.MouseDownCallBack(Self.wMouse.X, Self.wMouse.Y,ButtonVal,Self.wKeyBoard.Shift,Self.wKeyBoard.Alt);
          End;

        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     WM_LBUTTONUP:
      Begin
        ButtonVal := HiWord(wParameter);
        Self.wMouse.wButton[ButtonVal] := 0;

          If Assigned(Self.wMouse.MouseUpCallBack) Then Begin
            Self.wMouse.MouseUpCallBack(Self.wMouse.X, Self.wMouse.Y,ButtonVal,Self.wKeyBoard.Shift,Self.wKeyBoard.Alt);
          End;

        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     WM_RBUTTONDOWN:
      Begin
        Self.wMouse.wButton[1] := 1;

          If Assigned(Self.wMouse.MouseDownCallBack) Then Begin
            Self.wMouse.MouseDownCallBack(Self.wMouse.X, Self.wMouse.Y,1,Self.wKeyBoard.Shift,Self.wKeyBoard.Alt);
          End;

        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     WM_RBUTTONUP:
      Begin
        Self.wMouse.wButton[1] := 0;

          If Assigned(Self.wMouse.MouseUpCallBack) Then Begin
            Self.wMouse.MouseUpCallBack(Self.wMouse.X, Self.wMouse.Y,1,Self.wKeyBoard.Shift,Self.wKeyBoard.Alt);
          End;

        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     WM_XBUTTONDOWN:
      Begin
        ButtonVal := HiWord(wParameter) + 1;
        Self.wMouse.wButton[ButtonVal] := 1;

          If Assigned(Self.wMouse.MouseDownCallBack) Then Begin
            Self.wMouse.MouseDownCallBack(Self.wMouse.X, Self.wMouse.Y,ButtonVal,Self.wKeyBoard.Shift,Self.wKeyBoard.Alt);
          End;

        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     WM_XBUTTONUP:
      Begin
        ButtonVal := HiWord(wParameter) + 1;
        Self.wMouse.wButton[ButtonVal] := 0;

          If Assigned(Self.wMouse.MouseUpCallBack) Then Begin
            Self.wMouse.MouseUpCallBack(Self.wMouse.X, Self.wMouse.Y,ButtonVal,Self.wKeyBoard.Shift,Self.wKeyBoard.Alt);
          End;

        Result := DefWindowProc(Handle,Messages,wParameter,lParameter);
      End;

     Else
      Result := DefWindowProc(Handle,Messages,wParameter,lParameter);

    End;

  End;


Function pglContext.ProcessCharMessages(Var Handle: HWND; Var Messages: Cardinal; Var wParameter: WPARAM; Var lParameter: LPARAM): LRESULT;

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


Procedure pglContext.GetInputDevices();
  Begin

  End;


Procedure pglContext.UpdateRects();
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


Procedure pglContext.RestoreStyleFlags();
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
    wRect := Self.wClientRect;

    If Self.HasCaption = True Then Begin
      AdjustWindowRectEX(wRect,Cardinal(Flags),False,0);
    End;

    SetWindowPos(Self.Handle,HWND_TOP,0,0,wRect.Width,wRect.Height, SWP_NOMOVE or SWP_DRAWFRAME or SWP_FRAMECHANGED or SWP_SHOWWINDOW);
  End;

Procedure pglContext.Close();
  Begin
    ReturnDisplayMode();
    Self.CleanUp();
    Self.wShouldClose := True;
    SendMessage(Self.Handle,WM_QUIT,0,0);
  End;

Procedure pglContext.SetTitle(Text: String);
  Begin
    Self.wTitle := Text;
    SetWindowText(Self.Handle,Self.wTitle);
  End;

Procedure pglContext.SetIconFromFile(FileName: String);
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

Procedure pglContext.SetIconFromBits(Source: Pointer; Width,Height,BPP: GLUint);
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

Procedure pglContext.SetPosition(X: Cardinal; Y: Cardinal);
  Begin
    If Self.FullScreen = True Then Exit;

    Context.wX := X;
    Context.wY := Y;
    SetWindowPos(Context.Handle, 0, Context.X - Context.wBorderWidth, Context.Y, Context.Width, Context.Height,
      SWP_SHOWWINDOW);
  End;

Procedure pglContext.SetSize(W: GLInt; H: GLInt; KeepCentered: Boolean = True);
Var
NewX,NewY: GLInt;
CenterX,CenterY: GLInt;
Flags: GLUint;
wRect: TRECT;

  Begin

    If Self.FullScreen = True Then Exit;

    If W < 0 Then Begin
      W := 0;
    End;

    If H < 0 Then Begin
      H := 0;
    End;

    NewX := 0;
    NewY := 0;
    Flags := SWP_NOMOVE or SWP_SHOWWINDOW or SWP_FRAMECHANGED or SWP_DRAWFRAME;

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

    SetWindowPos(Self.Handle,HWND_TOP,NewX,NewY,wRect.Width,wRect.Height,Flags);
  End;

Procedure pglContext.Maximize();
  Begin
    If Self.FullScreen = True Then Exit;
    SendMessage(Self.Handle,WM_SYSCOMMAND,SC_MAXIMIZE,0);
  End;

Procedure pglContext.Restore();
  Begin
    SendMessage(Self.Handle,WM_SYSCOMMAND,SC_RESTORE,0);
  End;

Procedure pglContext.Minimize();
  Begin
    SendMessage(Self.Handle,WM_SYSCOMMAND,SC_MINIMIZE,0);
  End;

Procedure pglContext.SetHasCaption(Enable: Boolean = True);
  Begin
    Context.wHasCaption := Enable;
    Self.wStyleChanged := True;
  End;

Procedure pglContext.SetHasMenu(Enable: Boolean = True);
  Begin
    Context.wHasMenu := Enable;
    Self.wStyleChanged := True;
  End;

Procedure pglContext.SetHasMaximize(Enable: Boolean = True);
  Begin
    Context.wHasMaximize := Enable;
    Self.wStyleChanged := True;
  End;

Procedure pglContext.SetHasMinimize(Enable: Boolean = True);
  Begin
    Context.wHasMinimize := Enable;
    Self.wStyleChanged := True;
  End;

Procedure pglContext.SetCanSize(Enable: Boolean = True);
  Begin
    Context.wCanSize := Enable;
    Self.wStyleChanged := True;
  End;

Procedure pglContext.SetWin7Frame(Enable: Boolean = True);
Var
Flags: GLInt;
  Begin
    Self.wWin7Frame := Enable;
    Self.wStyleChanged := True;
  End;


Procedure pglContext.SetFullScreen(Enable: Boolean = True);
Var
ReturnVal: Integer;
Error: Cardinal;
  Begin
    // Exit if tyring to enable the current fullscreen status
    If (Context.FullScreen = Enable) Then Exit;

    If Enable = True Then Begin
      //if the window size is not already the display resolution
      If (Context.CurDevMode.dmPelsWidth <> Context.ScreenWidth) and (Context.CurDevMode.dmPelsHeight <> Context.ScreenHeight) Then Begin
        Context.wReturnX := Context.X;
        Context.wReturnY := Context.Y;

        SetWindowLongPtr(Self.Handle,GWL_STYLE,0);
        SetWindowPos(Self.Handle, HWND_TOP,0,0,Self.wWidth, Self.wHeight, SWP_FRAMECHANGED or SWP_DRAWFRAME or SWP_SHOWWINDOW);
        ReturnVal := ChangeDisplaySettings(Self.CurDevMode,CDS_FULLSCREEN or CDS_UPDATEREGISTRY);


        // only flag as full screen in display setting changed successfully
        If ReturnVal = DISP_CHANGE_SUCCESSFUL Then Begin
          Self.wFullScreen := True;
        End Else Begin
          Self.RestoreStyleFlags();
        End;
      End;

    End Else Begin
      ChangeDisplaySettings(Self.OrgDevMode,CDS_UPDATEREGISTRY);
      Self.wFullScreen := False;
      Self.SetHasCaption(Self.HasCaption);
      Self.SetPosition(Self.wReturnX,Self.wReturnY);
    End;
  End;

Procedure pglContext.RegisterSizeCallBack(Proc: pglWindowSizeCallBack);
  Begin
    Self.SizeCallBack := Proc;
  End;

Procedure pglContext.RegisterMoveCallBack(Proc: pglWindowMoveCallBack);
  Begin
    Self.MoveCallBack := Proc;
  End;

Procedure pglContext.RegisterMaximizeCallBack(Proc: pglCallBack);
  Begin
    Self.MaximizeCallBack := Proc;
  End;

Procedure pglContext.RegisterMinimizeCallBack(Proc: pglCallBack);
  Begin
    Self.MinimizeCallBack := Proc;
  End;

Procedure pglContext.RegisterRestoreCallBack(Proc: pglCallBack);
  Begin
    Self.RestoreCallBack := Proc;
  End;

Procedure pglContext.RegisterGotFocusCallBack(Proc: pglCallBack);
  Begin
    Self.GotFocusCallBack := Proc;
  End;

Procedure pglContext.RegisterLostFocusCallBack(Proc: pglCallBack);
  Begin
    Self.LostFocusCallBack := Proc;
  End;

Procedure pglContext.RegisterDebugCallBack(Proc: TglDebugProc);
  Begin
    If Context.wFeatures.OpenGLDebugContext = False Then Exit;
    glDebugMessageCallBack(Proc,nil);
  End;

Procedure pglContext.SetDebugToConsole();
  Begin
    Self.wDebugToConsole := True;
    Self.wDebugToLog := False;
    Self.wDebugToMsgBox := False;
  End;

Procedure pglContext.SetDebugToLog();
  Begin
    Self.wDebugToConsole := False;
    Self.wDebugToLog := True;
    Self.wDebugToMsgBox := False;
  End;

Procedure pglContext.SetDebugToMsgBox();
  Begin
    Self.wDebugToConsole := False;
    Self.wDebugToLog := False;
    Self.wDebugToMsgBox := True;
  End;

Procedure pglContext.SetBreakOnDebug(Enable: Boolean);
  Begin
    Self.wBreakOnDebug := Enable;
  End;

Procedure pglContext.GetDebugLog(out Buffer: array of string);
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

Procedure pglContext.CleanUp();
Var
Success: LongBool;
  Begin
    Success := DeleteObject(Context.wWindowRgn);
  End;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
(*                            Unit Functions                                  *)
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Procedure pglStart(Width,Height: GLUint; Format: pglWindowformat; Features: pglFeatureSettings; Title: String);
Var
DC: HDC;

  Begin

    EXEPath := ExtractfilePath(ParamStr(0));

    Context := pglContext.Create();
    Context.wController := pglControllerInstance.Create();
    Context.wMouse := pglMouseInstance.Create();
    Context.wKeyBoard := pglKeyBoardInstance.Create();

    Context.wFormat := Format;

    Context.wTitle := Title;
    Context.wWidth := Width;
    Context.wHeight := Height;

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

    Context.wX := trunc((Context.ScreenWidth / 2) - Context.Width / 2);
    Context.wY := trunc((Context.ScreenHeight / 2) - Context.Height / 2);

    ReleaseDC(0,DC);

    RegisterClassEX(WC);

    // Handle features, they initialize to all enabled and highest verion, so only need to be assigned if valid pointer
    Context.wFeatures := Features;

    CreateGLContext();

    Context.SetSize(Context.Width, Context.Height,true);
    Context.SetFullScreen(Context.Format.FullScreen);
    SetCursorPos(trunc(Context.wWindowRect.Left + (Context.Width / 2)), trunc(Context.wWindowRect.Top + (Context.Height / 2)));
    Context.IsReady := True;
    Context.SetTitle(Title);


  End;


Function ReturnPFDFlags(): Integer;
Var
Flags: Integer;
  Begin
    Flags := PFD_SUPPORT_OPENGL or PFD_DRAW_TO_WINDOW or PFD_DOUBLEBUFFER;

    If Context.Format.BufferCopy = True Then Begin
      Flags := Flags or  PFD_SWAP_COPY;
    End Else Begin
      Flags := Flags or PFD_SWAP_EXCHANGE;
    End;

    Result := Flags;
  End;

Function ReturnARBPixelFormat(): pglAttribs;
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
    WGL_COLOR_BITS_ARB, 32,
    WGL_RED_BITS_ARB, 8,
    WGL_GREEN_BITS_ARB, 8,
    WGL_BLUE_BITS_ARB, 8,
    WGL_ALPHA_BITS_ARB, 8,
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
A: pglAttribs;

  Begin

    A.AddAttribs([WGL_CONTEXT_MAJOR_VERSION_ARB, Maj]);
    A.AddAttribs([WGL_CONTEXT_MINOR_VERSION_ARB, Min]);
    A.AddAttribs([WGL_CONTEXT_LAYER_PLANE_ARB, 0]);

    If Context.wFeatures.OpenGLDebugContext = True Then Begin
      A.AddAttribs([WGL_CONTEXT_FLAGS_ARB, WGL_CONTEXT_DEBUG_BIT_ARB]);
    End;

    A.AddAttribs([WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_CORE_PROFILE_BIT_ARB]);
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
PixelAttribs: pglAttribs;
ContextAttribs: pglAttribs;
PixelFormatID: GLInt;
numFormats: GLUint;
Status: BOOL;
Options: TRCOptions;
wRect: TRECT;
ContextMajor,ContextMinor: GLInt;
ReturnedFormats: Array [0..99] of Integer;
I: Long;
ErrVar: Cardinal;

  Begin

    Status := InitOpenGL();
    If Status = False Then Begin
      MessageBox(0,'Failed to Initialize OpenGL! Exiting Application!', 'Error', MB_OK or MB_ICONEXCLAMATION);
      Exit;
    End;

    // Create the temporary window to initialize the context with
    TempWindow := CreateWindowEX(0,'OpenGL Window','Temp',0,0,0,800,600,
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
    PixelFormat.cColorBits := 32;
    PixelFormat.cRedBits := 8;
    PixelFormat.cGreenBits := 8;
    PixelFormat.cBlueBits := 8;
    PixelFormat.cAlphaBits := 8;
    PixelFormat.cStencilBits := Context.wFormat.StencilBits;
    PixelFormat.cDepthBits := Context.wFormat.DepthBits;
    PixelFormat.iLayerType := PFD_MAIN_PLANE;

    DescribePixelFormat(TempDC,5,SizeOf(PixelFormat),TPF);

    // Set Pixel Format to Window
      SetLastError(0);
    If SetPixelFormat(TempDC,5,@TPF) = False Then Begin
      ErrVar := GetLastError();
      Messagebox(0,'Failed to Set Pixel Format!', 'Error', MB_OK or MB_ICONEXCLAMATION);
      SendMessage(TempWindow,WM_QUIT,0,0);
      Exit;
    End;

    // Create the initial Context
    Options := [opDoubleBuffered];
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
    Context.wClientRect := wRect;
    Context.wWindowRect := wRect;
    If Context.wFormat.TitleBar = True Then Begin
      AdjustWindowRect(wRect,WS_CAPTION,false);
      Context.wWindowRect := wRect;
    End;

    Context.wHandle := CreateWindowEX(0,'OpenGL Window',
      'OpenGL Window',0,0,0,wRect.Width,wRect.Height,0,0,System.MainInstance,nil);

    If Context.wHandle = 0 Then Begin
      MessageBox(0,'Failed to Create the Final Window!','Error', MB_OK or MB_ICONEXCLAMATION);
      PostQuitMessage(0);
      Exit;
    End;


    ShowWindow(Context.Handle,1);

    Context.SetHasCaption(Context.wFormat.TitleBar);
    Context.SetHasMaximize(Context.wFormat.Maximize);
    Context.SetHasMinimize(Context.wFormat.Maximize);

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
    numFormats := 0;
    PixelFormatID := 0;
    Status := wglChoosePixelFormatARB(Context.DC,@PixelAttribs.Attribs[0],nil,10,@ReturnedFormats,@numFormats);

      If (Status = False) or (numFormats = 0) Then Begin
        MessageBox(0,'Failed to Get ID of new Pixel Format','Error', MB_OK or MB_ICONEXCLAMATION);
        SendMessage(TempWindow,WM_QUIT,0,0);
        SendMessage(Context.Handle,WM_QUIT,0,0);
        Exit;
      End;

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
      glEnable(GL_BLEND);
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    End;

    // Disable Depth Testing if DepthBits = 0
    If Context.wFormat.DepthBits = 0 Then Begin
      glDisable(GL_DEPTH_TEST);
    End;

    // Disable Stencil Testing if StencilBits = 0
    If Context.wFormat.StencilBits = 0 Then Begin
      glDisable(GL_STENCIL_TEST);
    End;

    glEnable(GL_TEXTURE_2D);

    CheckGLStatus();

    If Context.wFormat.ColorBits < 32 Then Begin
    End;

  End;


Procedure CheckGLStatus();
Var
DoubleBuffer: GLInt;
NumExt: GLint;
Samples: GLInt;

  Begin
    glGetIntegerV(GL_MAJOR_VERSION,@Context.wMajVersion);
    glGetIntegerV(GL_MINOR_VERSION,@Context.wMinVersion);
    glGetBooleanV(GL_MULTISAMPLE,@Context.wMultiSampled);
    glGetIntegerV(GL_SAMPLES,@Context.wFormat.Samples);
    glGetIntegerV(GL_NUM_EXTENSIONS, @NumExt);
    glGetIntegerV(GL_STENCIL_BITS, @Context.wFormat.StencilBits);
    glGetIntegerV(GL_DEPTH_BITS, @Context.wFormat.DepthBits);
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

    Case Messages of


     // Handle any close or destroy messages
     WM_DESTROY, WM_QUIT, WM_CLOSE:
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
            ChangeDisplaySettings(Context.CurDevMode, CDS_UPDATEREGISTRY);
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
            Result := 1;
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
    ChangeDisplaySettings(Context.OrgDevMode,CDS_UPDATEREGISTRY);
  End;



Procedure GetKeyDown(Var Value: wParam);
  Begin

    If Assigned(Context.wKeyBoard.KeyDown) Then Begin

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

        Context.wKeyBoard.KeyDown(Value, Context.wKeyBoard.Shift, Context.wKeyBoard.Alt);
      End Else Begin
        Context.wKeyBoard.KeyDown(Value, Context.wKeyBoard.Shift, Context.wKeyBoard.Alt);
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



Function pglCreateIcon(SourceIcon: HICON): pglIcon;
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

Function pglCreateIconFromFile(FileName: String; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0): pglIcon;
Var
Image: Pointer;
Width,Height,Channels,BPP: GLInt;

  Begin

    Image := stbi_load(PAnsiChar(AnsiString(FileName)),Width,Height,Channels,4);

    Result := pglCreateIconFromPointer(Image,Width,Height,32,HotSpotX,HotSpotY);

    stbi_image_free(Image);

  End;


Function pglCreateIconFromPointer(Source: Pointer; Width,Height,BPP: GLUInt; HotSpotX: GLUint = 0; HotSpotY: GLUint = 0): pglIcon;
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

Function ReadBit(Var TargetByte: Byte; Index: Byte): LongBool;
  Begin
    Result := (Word(TargetByte) shr Index) and 1 = 1;
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


Procedure Debug(Source: GLenum; MessageType: GLenum; ID: GLuint; Severity: GLUint; MessageLength: GLsizei; const DebugMessage: PGLChar; const UserParam: PGLVoid); stdCall;
Var
I: Long;
Chars: Array of AnsiChar;
ErrorString: String;
SourceString: String;
TypeString: String;
SeverityString: String;
FinalString: String;

  Begin

    If MessageLength = 0 Then Exit;

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


    {$IFDEF WIN32}
    if Context.wBreakOnDebug Then Begin
      asm int 3 end;
    End;
    {$ENDIF}


  End;


end.
