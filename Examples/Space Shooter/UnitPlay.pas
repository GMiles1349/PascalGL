unit UnitPlay;

{$HINTS OFF}

interface

Uses
  glDrawMain, glDrawTime, UnitSound, Messages, Neslib.Stb.ImageWrite,
  Classes, System.SysUtils, Math, WinAPI.Windows, dglOpenGL;

  Type GeoTemp = Record
    Point: Array of TPGLVector2;
    Color: Array of TPGLColorF;
    Class Operator Initialize(Out Dest: GeoTemp); Register;
    Procedure AddPoint(X,Y: Single); Register;
    Procedure AdjustCenter(); Register;
    Procedure SortPoints(); Register;
    Procedure SetCenter(Center: TPGLVector2); Register;
    Procedure SetColors(Color: TPGLColorF); Register;
  End;

  Type DrawTemp = Record
    Texture: TPGLTexture;
    Pos: TPGLVector3;
    Bounds: TPGLRectF;
    Colors: TPGLColorI;
    Overlay: TPGLColorI;
    Angle: Single;
    Opacity: Single;
    ShadowGeometry: ^GeoTemp;
  End;

  Type DrawCollection = Record
    Draws: Array [0..1999] of DrawTemp;
    DrawCount: Integer;
    SortTime: Double;
    Procedure AddDraw(Var Texture: TPGLTexture; Pos: TPGLVector3; Bounds: TPGLRectF; Colors,Overlay: TPGLColorI; Angle,Opacity: Single; GeoMetry: Pointer = nil); Register;
    Procedure Draw(); Register;
    Procedure Sort(); Register;
  End;

  Type HitGrid = Record
    Pixel: Array of Array of Byte;
    Width,Height: Integer;
    Procedure SaveToBMP(); Register;
  End;

  Type RadarPointTemp = Record
    Used: Boolean;
    Pos: TPGLVector2;
    Color: TPGLColorI;
    Opacity: Single;
    Procedure Place(X,Y: Single; Color: TPGLColorI); Register;
    Procedure Handle(); Register;
  End;

  Type StarTemp = Record
    Pos: TPGLVector2;
    Size: Single;
    Color: TPGLColorI;
  End;

  Type PlanetTemp = Record
    Texture: TPGLTexture;
    Bounds: TPGLRectF;
    Procedure CheckInBounds(); Register;
  End;

  Type CrossHairTemp = Record
    Pos: TPGLVector2;
    Rotation: Single;
  End;


  Type CrackTemp = Record
    Pos: TPGLVector2;
    Rotation: Single;
    Bounds: TPGLRectF;
    Texture: TPGLTexture;
    Procedure Place(); Register;
  End;



  Type ParticleTemp = Record
    Used: Boolean;
    Pos: TPGLVector3;
    Color: TPGLColorI;
    Size: Single;
    XVal,YVal: Single;
    Angle: Single;
    Duration: Single;
    Procedure Place(Position: TPGLVector3; Angle,Speed,Size: Single; Color: TPGLColorI); Register;
    Procedure Move(); Register;
  End;

  Type FlashTemp = Record
    Used: Boolean;
    Pos: TPGLVector3;
    Size: Single;
    Frames: Integer;
    Color: TPGLColorI;
    Procedure Place(Position: TPGLVector3; Size: Single; Color: TPGLColorI); Register;
    Procedure Handle(); Register;
    Procedure Move(X,Y: Single); Register;
  End;

  Type ExpTemp = Record
    Used: Boolean;
    Pos: TPGLVector3;
    Bounds: TPGLRectF;
    Size: Single;
    Stage: Integer;
    Count: Integer;
    StageDuration: Integer;
    Sound: TPGLSoundSource;
    Procedure Place(Position: TPGLVector3); Register;
    Procedure Handle(); Register;
  End;

  Type ExpSpawnTemp = Record
    Used: Boolean;
    Pos: TPGLVector3;
    ExpCount: Integer;
    InstanceCount: Integer;
    InterVal: Single;
    Duration: Single;
    Procedure Place(Position: TPGLVector3; Interval: Single; Count,InstanceCount: Integer); Register;
    Procedure Handle(); Register;
  End;

  Type DebrisTemp = Record
    Used: Boolean;
    Pos: TPGLVector3;
    Bounds: TPGLRectF;
    XVal,YVal: Single;
    DebrisType: Integer;
    RotationDirection: Integer;
    Speed: Single;
    Angle: Single;
    Opacity: Single;
    Level: Integer;
    Procedure Place(Position: TPGLVector3); Register;
    Procedure Move(); Register;
  End;

  Type RocketTemp = Record
    Used: Boolean;
    Pos: TPGLVector3;
    Bounds: TPGLRectF;
    Angle: Single;
    Speed: Single;
    XVal, YVal: Single;
    Health: Single;
    Grid: ^HitGrid;
    FromPlayer: Boolean; // If From the player
    Target: Integer; // Index of target enemy
    Procedure Place(Position: TPGLVector3; Angle: Single; Speed: Single); Register;
    Procedure Handle(); Register;
    Procedure HandleFromPlayer(); Register;
    Procedure Hurt(Dam: Single); Register;
  End;

  Type RocketSpawnTemp = Record
    Active: Boolean;
    Pos: TPGLVector3;
    Interval: Single;
    Duration: Single;
    Count: Integer;
    Remaining: Integer;
    ReleaseCount: Integer;
    Parent: Pointer;
    Procedure SetAttributes(Interval: Single; Count,ReleaseCount: Integer; Parent: Pointer); Register;
    Procedure SetActive(); Register;
    Procedure Stop(); Register;
    Procedure Handle(); Register;
  End;

  Type EnemyTemp = Record
    Pos: TPGLVector3;
    EnemyType: Integer;
    Bounds: TPGLRectF;
    Speed: Single;
    Angle: Single;
    ToAngle: Single;
    ToSpeed: Single;
    ToZ: Single;
    State: String;
    StateTimer: Single;
    RocketTimer: Single;
    RocketSpawn: RocketSpawnTemp;
    Armor: Single;
    Grid: ^HitGrid;
    ShadowGeometry: ^GeoTemp;
    WasHit: Integer;
    RadarPoint: RadarPointTemp;
    Procedure Move(X,Y: Single); Register;
    Procedure Hurt(Dam: Single); Register;
    Procedure CheckState(); Register;
  End;

  // Callback functiions
  Procedure KeyDown(Key: NativeUInt; Alt,Shift: Boolean); Register;
  Procedure KeyPress(Key: NativeUInt; Alt,Shift: Boolean); Register;
  Procedure KeyUp(Key: NativeUInt; Alt,Shift: Boolean); Register;
  Procedure MouseMove(X,Y: Single; Button: Integer; Shift,Alt: Boolean); Register;
  Procedure MouseDown(X,Y: Single; Button: Integer; Shift,Alt: Boolean); Register;
  Procedure MouseUp(X,Y: Single; Button: Integer; Shift,Alt: Boolean); Register;
  Procedure ControllerButtonDown(Button: Word); Register;
  Procedure ControllerButtonUp(Button: Word); Register;
  Procedure ControllerStateChange(LeftStick,RightStick: TPointFloat; LeftTrigger,RightTrigger: Byte); Register;
  Procedure ControllerStickHeld(LeftStick,RightStick: TPointFloat); Register
  Procedure LostFocus(); Register;
  Procedure GotFocus(); Register;

  Function Biggest(Values: Array of Single): Single; Register;
  Function Rnd(Low,High: Single): Single; Register; Inline;
  Procedure FixRadian(Var Radian: Single); Register; Inline;
  Function VectorAngle(DX,DY: Single): Single; Register; Inline;
  Function CheckInTriangle(Point,P1,P2,P3: TPGLVector2): Boolean; Register;
  Function CheckPointInRect(Point: TPGLVector2; CheckRect: TPGLRectF; RectRotation: Single = 0): Boolean; Register;
  Function CheckHit(): Boolean; Register;
  Function CheckInHitGrid(Var Grid: HitGrid; CheckPoint: TPGLVector2; Angle: Single; ScaleWidth: Single = 0; ScaleHeight: Single = 0): Boolean; Register;
  Function CheckRectCollision(Rect1,Rect2: TPGLRectF): Boolean; Register;
  Function ReturnLineIntersect(CheckPoint: TPGLVector2; CheckRect: TPGLRectF): TPGLVector2; Register;

  Function FindNewParticle(): Long; Register;
  Function FindNewFlash(): Long; Register;
  Function FindNewExplosion(): Long; Register;
  Function FindNewExplosionSpawn(): Long; Register;
  Function FindNewDebris(): Long; Register;
  Function FindNewRocket(): Long; Register;

  Procedure StartPlay(); Register;
  Procedure PlayMain(); Register;

  Procedure CreateCrackTextures(); Register;
  Procedure CreateFlashTexture(); Register;
  Procedure CreateExplosionTextures(); Register;
  Procedure CreateStars(NumStars: Integer); Register;
  Procedure CreatePlanets(); Register;
  Procedure CreateEnemies(); Register;
  Procedure CreateHitGrid(Image: TPGLImage; Var Grid: HitGrid); Register;
  Procedure CreateStaticTextures(); Register;
  Function CreateGeometryFromTexture(Var Texture: TPGLTexture): GeoTemp; Register;
  Procedure CompleteGeometry(Var Points: TArray<TPGLVector2>); Register;
  Function GetGeometryCenter(Var Points: Array of TPGLVector2): TPGLVector2; Register;
  Procedure StretchGeometry(Var Points: Array of TPGLVector2; Center: TPGLVector2; Ratio: Single); Register;
  Procedure SkewGeometry(Var Points: Array of TPGLVector2; Center: TPGLVector2; Source: TPGLVector2; Angle: Single; Ratio: Single); Register;


  Procedure HandleMove(); Register;
  Procedure HandleShoot(); Register;
  Procedure HandleParticles(); Register;
  Procedure HandleFlashes(); Register;
  Procedure HandleEnemies(); Register;
  Procedure HandleExplosions(); Register;
  Procedure HandleExplosionSpawns(); Register;
  Procedure HandleDebris(); Register;
  Procedure HandleRockets(); Register;
  Procedure HandleRadar(); Register;

  Procedure DrawStars(); Register;
  Procedure DrawPlanets(); Register;
  Procedure DrawHUD(); Register;
  Procedure DrawRadar(); Register;
  Procedure DrawCanons(); Register;
  Procedure DrawLasers(); Register;
  Procedure DrawCracks(); Register;
  Procedure DrawEnemies(); Register;
  Procedure DrawParticles(); Register;
  Procedure DrawFlashes(); Register;
  Procedure DrawExplosions(); Register;
  Procedure DrawDebris(); Register;
  Procedure DrawRockets(); Register;
  Procedure DrawStatic(); Register;

  Procedure HeatLasers(); Register;
  Procedure GetTarget(); Register;
  Procedure GetBrightVal(); Register;
  Function BD(Color: TPGLColorI): TPGLColorI; Overload; Register;
  Function BD(Color: TPGLColorF): TPGLColorF; Overload; Register;

  // Timer Functions
  Procedure DriftCrossHair(); Register;
  Procedure ToggleRocketLock(); Register;
  Procedure ToggleHUDFlash(); Register;
  Procedure CoolLasers(); Register;

Var

  LastButton: Word;

  Window: TPGLWindow;
  Buffer: TPGLRenderTexture;
  EditBuffer: TPGLRenderTexture;

  TextureCrossHair: TPGLTexture;
  TextureCrack: Array of TPGLTexture;
  TextureCanon: TPGLTexture;
  TextureCanonWireFrame: TPGLTexture;
  TextureEnemy: TPGLTexture;
  TextureParticle: TPGLTexture;
  TextureAlarmOff,TextureAlarmOn: TPGLTexture;
  TextureOverHeated: TPGLTexture;
  TextureFlame: TPGLTexture;
  TextureExplosion: Array [0..3] of TPGLTexture;
  TextureDebris: Array [0..4] of TPGLTexture;
  TextureRocket: TPGLTexture;
  TextureFlash: TPGLTexture;
  TextureStatic: Array of TPGLTexture;

  Sprite: TPGLSprite;
  LeftCanonSprite,RightCanonSprite: TPGLSprite;
  ExplosionSprite: TPGLSprite;

  ImageEnemy: TPGLImage;
  ImageRocket: TPGLImage;
  EnemyHitGrid: HitGrid;
  RocketHitGrid: HitGrid;

  GeoEnemy: GeoTemp;
  GeoRocket: GeoTemp;
  GeoDebris: Array of GeoTemp;
  GeoExplosion: Array [0..3] of GeoTemp;
  GeoPlanet: Array of GeoTemp;

  Font: TPGLFont;
  TextBox: TPGLText;

  Clock: TPGLClock;
  DriftTimer: TPGLTimer;
  RocketLockTimer: TPGLTimer;
  HUDFlashTimer: TPGLTimer;
  CoolTimer: TPGLTimer;

  PXVal,PYVal: Single;
  AutoSlow: Boolean;
  Lefting,Righting,Uping,Downing,Shooting: Boolean;
  ShootVar,ShootStage: Integer;
  Ammo,MaxAmmo: Integer;
  Fuel,MaxFuel: Single;
  Armor,MaxArmor: Single;
  Instability: Single;

  Star: Array of StarTemp;
  Planet: Array of PlanetTemp;
  CrossHair: CrossHairTemp;
  LaserLeftVisible: Boolean;
  LaserRightVisible: Boolean;
  LaserLeftHeat: Single;
  LaserRightHeat: Single;
  OverHeated: Boolean;
  HeatCount: Integer;
  HeatVisible: Boolean;
  RocketLock: Integer;
  DisplayRocketLock: Boolean;
  HUDFlash: Boolean;
  CurTarget: Integer;

  Cracks: Array of CrackTemp;

  Audio: TPGLSoundInstance;
  LaserBuffer: TPGLSoundBuffer;
  AlarmBuffer: TPGLSoundBuffer;
  EngineHumBuffer: TPGLSoundBuffer;
  ExplosionQuietBuffer: TPGLSoundBuffer;

  LaserSound: TPGLSoundSource;
  EngineHumSound: TPGLSoundSource;
  AlarmSource: TPGLSoundSource;

  GlassPoints: Array [0..5] of TPGLVector2;

  Enemy: Array of EnemyTemp;
  EnemiesLeft: Integer;
  Particle: Array [0..2500] of ParticleTemp;
  Flash: Array [0..100] of FlashTemp;
  Explosion: Array [0..500] of ExpTemp;
  ExplosionSpawn: Array [0..20] of ExpSpawnTemp;
  Debris: Array [0..50] of DebrisTemp;
  Rocket: Array [0..50] of RocketTemp;

  RadarRect: TPGLRectF;
  RadarAngle,RadarLastAngle: Single;

  DrawList: DrawCollection;

  TheSun: TPGLVector2;
  BrightVal: Single;
  Paused: Boolean;
  Controller: TPGLController;
  Mouse: TPGLMouse;
  KeyBoard: TPGLKeyBoard;

  TestImage: TPGLImage;
  TestTexture: TPGLTExture;

Const
  PlayWidth: Long = 3000;
  HalfWidth: Long = 1500;

implementation


Procedure StartPlay();
Var
I: Long;
  Begin

    Randomize();

    pglInit(Window,800,600,'Game',[]);

    PGL.AddDefaultColorReplace(pgl_magenta,pgl_empty);

    Window.SetDisplayRect(RectIWH(0,0,Window.Width,Window.Height),True);

    Buffer := TPGLRenderTexture.Create(800,600,32);
    Buffer.SetRenderRect(RectIWH(0,0,Buffer.Width,Buffer.Height));
    Buffer.SetNearestFilter();

    EditBuffer := TPGLRenderTexture.Create(300,300,32);
    EditBuffer.SetRenderRect(RectIWH(0,0,300,300));
    EditBuffer.SetLinearFilter();

    Clock := TPGLClock.Create();
    Clock.SetintervalInFPS(60);

    DriftTimer := TPGLTimer.Create(DriftCrossHair,1/60,True);
    DriftTimer.Activate();
    Clock.AssignTimer(DriftTimer);

    RocketLockTimer := TPGLTimer.Create(ToggleRocketLock,0.5,true);
    RocketLockTimer.Activate();
    Clock.AssignTimer(RocketLockTimer);

    HUDFlashTimer := TPGLTimer.Create(ToggleHUDFlash,0.05,True);
    HUDFlashTimer.Activate();
    Clock.AssignTimer(HUDFlashTimer);

    CoolTimer := TPGLTimer.Create(CoolLasers,Clock.Interval,True);
    CoolTimer.Activate();
    Clock.AssignTimer(CoolTimer);

    PGL.GetInputDevices(KeyBoard,Mouse,Controller);

    KeyBoard.RegisterKeyDownCallBack(KeyDown);
    KeyBoard.RegisterKeyUpCallBack(KeyUp);
    KeyBoard.RegisterKeyPressCallBack(KeyPress);
    Mouse.RegisterMouseMoveCallBack(MouseMove);
    Mouse.RegisterMouseDownCallBack(MouseDown);
    Mouse.RegisterMouseUpCallBack(MouseUp);
    Mouse.SetVisible(False);
    Controller.RegisterButtonDownCallBack(ControllerButtonDown);
    Controller.RegisterButtonUpCallBack(ControllerButtonUp);
    Controller.RegisterStateChangeCallBack(ControllerStateChange);
    Controller.RegisterStickHeldCallBack(ControllerStickHeld);

    PGL.Context.RegisterGotFocusCallBack(GotFocus);
    PGL.Context.RegisterLostFocusCallBack(LostFocus);

    Font := TPGLFont.Create(pglEXEPath + 'Fonts/consola.ttf',[12,16,20,24,36],False);
    TextBox := TPGLText.Create(Font,'');
    TextBox.SetBorderColor(pgl_empty);
    textBox.SetBorderSize(0);
    TextBox.SetCharSize(12);

    TextureCrossHair := TPGLTexture.CreateFromFile(pglEXEPath + 'Graphics/CrossHair 2.png');
    TextureCrossHair.ReplaceColors([pgl_magenta],pgl_empty);
    TextureCrossHair.SetLinearFilter();

    TextureCanon := TPGLTexture.CreateFromFile(pglEXEPath + 'Graphics/Canon.png');
    TextureCanon.ReplaceColors([pgl_magenta],pgl_empty);
    TextureCanon.SetLinearFilter();

    TextureCanonWireFrame := TPGLTexture.CreateFromFile(pglEXEPath + 'Graphics/Canon WireFrame.png');
    TextureCanonWireFrame.ReplaceColors([pgl_magenta],pgl_empty);
    LeftCanonSprite := TPGLSprite.CreateFromTexture(TextureCanonWireFrame);
    LeftCanonSprite.SetSize(LeftCanonSprite.Width * 2, LeftCanonSprite.Height * 2);
    RightCanonSprite := TPGLSprite.CreateFromTexture(TextureCanonWireFrame);
    RightCanonSprite.SetSize(RightCanonSprite.Width * 2, RightCanonSprite.Height * 2);

    TextureParticle := TPGLTexture.CreateFromFile(pglEXEPath + 'Graphics/Particle.png');
    TextureParticle.ReplaceColors([pgl_magenta],pgl_empty);
    TextureParticle.SetLinearFilter();

    TextureAlarmOff := TPGLTexture.CreateFromFile(pglEXEPath + 'Graphics/Alarm Light Off.png');
    TextureAlarmOff.ReplaceColors([pgl_magenta],pgl_empty);
    TextureAlarmOff.SetLinearFilter();
    TextureAlarmOn := TPGLTexture.CreateFromFile(pglEXEPath + 'Graphics/Alarm Light On.png');
    TextureAlarmOn.ReplaceColors([pgl_magenta],pgl_empty);
    TextureAlarmOn.SetLinearFilter();

    TextureEnemy := TPGLTexture.CreateFromFile(pglEXEPath + 'Graphics/Ship.png');
    GeoEnemy := CreateGeometryFromTexture(TextureEnemy);
    GeoEnemy.SetColors(Color4f(0,0,0,0));
    GeoEnemy.Color[0] := Color4F(0,0,0,1);
    TextureEnemy.SetLinearFilter();

    ImageEnemy := TPGLImage.CreateFromTexture(TextureEnemy);
    TextureEnemy.SaveToFile(pglEXEPath + 'textest.png');



    TextureOverHeated := TPGLTexture.CreateFromFile(pglEXEPath + 'Graphics/Overheated.png');
    TextureFlame := TPGLTexture.CreateFromFile(pglEXEPath + 'Graphics/Flame.png');


    SetLength(GeoDebris,Length(TextureDebris));
    For I := 0 to 4 Do Begin
      TextureDebris[i] := TPGLTexture.CreateFromFile(pglEXEPath + 'Graphics/Debris ' + (I+1).toString + '.png');
      GeoDebris[i] := CreateGeometryFromTexture(TextureDebris[i]);
      GeoDebris[i].SetColors(Color4f(0,0,0,0.0));
      GeoDebris[i].Color[0] := Color4f(0,0,0,0.2);
    End;

    TextureRocket := TPGLTexture.CreateFromFile(pglEXEPath + 'Graphics/Rocket.png');
    GeoRocket := CreateGeometryFromTexture(TextureRocket);
    GeoRocket.SetColors(Color4f(0,0,0,0.1));
    GeoRocket.Color[0] := CC(pgl_black);
    ImageRocket := TPGLImage.CreateFromTexture(TextureRocket);


    Sprite := TPGLSprite.Create();
    Sprite.SetMaskColor(pgl_magenta);

    CreateCrackTextures();
    CreateFlashTexture();
    CreateExplosionTextures();
    CreateStaticTextures();
    CreateStars(500);
    CreatePlanets();
    CreateEnemies();

    CreateHitGrid(ImageEnemy,EnemyHitGrid);
    CreateHitGrid(ImageRocket,RocketHitGrid);

    Ammo := 1500;
    MaxAmmo := 1500;
    Fuel := 100;
    MaxFuel := 100;
    Armor := 100;
    MaxArmor := 100;
    Instability := 0.0;
    LaserLeftHeat := 100;
    LaserRightHeat := 100;
    HeatVisible := True;
    HeatCount := 0;
    RocketLock := 0;
    RadarAngle := 0;
    RadarLastAngle := 0;
    AutoSlow := True;

    Audio := TPGLSoundInstance.Create();
    Audio.SetGlobalVolume(0.8);
    Audio.SetDynamicSound(True);
    Audio.Listener.SetPosition(Buffer.Width / 2, Buffer.Height / 2);

    ExplosionQuietBuffer.LoadDataFromFile(pglEXEPath + '/Sounds/Explosion Quiet.wav','Explosion Quiet');

    AlarmBuffer.LoadDataFromFile(pglEXEPath + 'Sounds/Alarm 2.wav','Alarm');
    AlarmSource.AssignBuffer(AlarmBuffer);
    AlarmSource.SetPosition(Audio.Listener.X, Audio.Listener.Y);
    AlarmSource.SetLooping(False);
    AlarmSource.SetRadius(1000);
    AlarmSource.SetDynamic(True);

    LaserBuffer.LoadDataFromFile(pglEXEPath + 'Sounds/Laser 2.wav','Laser');
    LaserSound.AssignBuffer(LaserBuffer);
    LaserSound.SetDynamic(True);
    LaserSound.SetRadius(2000);

    EngineHumBuffer.LoadDataFromFile(pglEXEPath + 'Sounds/Engine Hum.wav','Engine Hum');
    EngineHumSound.AssignBuffer(EngineHumbuffer);
    EngineHumSound.SetPosition(Buffer.Width / 2, Buffer.Height / 2);
    EngineHumSound.SetDynamic(False);
    EngineHumSound.SetRadius(1000);
    EngineHumSound.SetLooping(True);


    PlayMain();

  End;


Procedure PlayMain();
Var
Angle: Single;
W,H: Long;
OutText: String;
ReadRect: TRect;

  Begin

    Clock.Start();
    EngineHumSound.Play();

    While pglRunning = True Do Begin

      pglWindowUpdate();

      Window.SetTitle(Clock.FPS.ToString);

      GetBrightVal();

      Buffer.Clear();

      DrawStars();
      DrawPlanets();
      DrawEnemies();
      DrawDebris();
      DrawExplosions();
      DrawRockets();
      DrawFlashes();
      DrawParticles();

      DrawList.Draw();

      Window.SetBlendFactors(SOURCE_COLOR, DEST_COLOR);
      Buffer.CopyBlt(Window,Window.DisplayRect,Buffer.RenderRect);

      Buffer.Clear(pgl_empty);

      Window.RestoreBlendDefaults();

      DrawLasers();

      CrossHair.Rotation := CrossHair.Rotation + 0.05;
      Sprite.SetAngle(0);

      Sprite.SetTexture(TextureCrossHair);
      Sprite.SetCenter(CrossHair.Pos);
      Sprite.SetOrigin(Sprite.Center);
      Sprite.SetAngle(CrossHair.Rotation);
      Window.DrawSprite(Sprite);

      DrawHUD();

      Window.DrawText(Clock.FPS.ToString,Font,24,Vec2(20,20),0,pgl_white,pgl_white,false);

      If Paused = False Then Begin

        HandleMove();
        HandleEnemies();
        HandleShoot();
        HandleParticles();
        HandleFlashes();
        HandleExplosionSpawns();
        HandleExplosions();
        HandleDebris();
        HandleRockets();
        HandleRadar();
      End;

      Clock.Wait();
    end;

  End;


Procedure KeyDown(Key: NativeUInt; Alt,Shift: Boolean);
  Begin

  End;


Procedure KeyPress(Key: NativeUInt; Alt,Shift: Boolean);
Var
I: Long;
  Begin

    Case Key of

      VK_ESCAPE:
        Begin
          Window.Close();
        End;

      Ord('A'):
        Begin
          Lefting := True;
        End;

      Ord('W'):
        Begin
          Uping := True;
        End;

      Ord('D'):
        Begin
          Righting := True;
        End;

      Ord('S'):
        Begin
          Downing := True;
        End;

      Ord('P'): Paused := Not Paused;
      Ord('M'):
        Begin
          Window.SetBlendFactors(SOURCE_COLOR,DEST_COLOR);
        End;

    End;

  End;


Procedure KeyUp(Key: NativeUInt; Alt,Shift: Boolean);
  Begin

    Case Key of

      Ord('A'):
        Begin
          Lefting := False;
        End;

      Ord('W'):
        Begin
          Uping := False;
        End;

      Ord('D'):
        Begin
          Righting := False;
        End;

      Ord('S'):
        Begin
          Downing := False;
        End;

    End;

  End;


Procedure MouseMove(X,Y: Single; Button: Integer; Shift,Alt: Boolean);
Var
Center: TPGLVector2;
InRange: Boolean;
Angle,Dist: Single;
I: Long;

  Begin

    Center := Vec2(Buffer.Width / 2, (Buffer.Height / 2) - 75);
    Dist := Sqrt( IntPower(Center.X - X, 2) + IntPower(Center.Y - Y, 2));

    If Dist >= Abs((GlassPoints[0].X - GlassPoints[2].X) / 2) Then Begin
      Angle := ArcTan2(Y - Center.Y, X - Center.X);
      Dist := Abs(GlassPoints[0].X - GlassPoints[2].X) / 2;
      PGL.Context.Mouse.SetPosition( Center.X + ( Dist * Cos(Angle)), Center.Y + (Dist * Sin(Angle)));
    End;

    CrossHair.Pos := Vec2( PGL.Context.Mouse.X, PGL.Context.Mouse.Y);



    For I := 0 to High(enemy) Do Begin
      If Enemy[i].Armor > 0 Then Begin
        If CheckPointInBounds(CrossHair.Pos,Enemy[i].Bounds) Then Begin
          Mouse.SendButtonClick(0);
          Exit;
        End;
      End;
    End;

    Mouse.ReleaseButton(0);


  End;

Procedure MouseDown(X,Y: Single; Button: Integer; Shift,Alt: Boolean);
  Begin
    If OverHeated = False Then Begin
      Shooting := True;
    End;
  End;

Procedure MouseUp(X,Y: Single; Button: Integer; Shift,Alt: Boolean);
  Begin
    Shooting := False;
    ShootVar := 0;
    If (ShootStage = 1) or (ShootStage = 3) Then Begin
      Inc(ShootStage);
    End;
  End;


Procedure ControllerButtonDown(Button: Word);
Var
Success: NativeInt;
  Begin
    Case Button Of

      XInputGamePadRightShoulder:
        Success := SendMessage(Window.Handle, WM_LBUTTONDOWN, wParam(MK_LBUTTON), 0);

      XInputGamePadDPadLeft:
        Success := SendMessage(Window.Handle, WM_KEYDOWN, wParam(Ord('A')), 0);

      XInputGamePadDPadRight:
        Success := SendMessage(Window.Handle, WM_KEYDOWN, wParam(Ord('D')), 0);

      XInputGamePadDPadUp:
        Success := SendMessage(Window.Handle, WM_KEYDOWN, wParam(Ord('W')), 0);

      XInputGamePadDPadDown:
        Success := SendMessage(Window.Handle, WM_KEYDOWN, wParam(Ord('S')), 0);

    End;
  End;

Procedure ControllerButtonUp(Button: Word);
Var
Success: NativeInt;
  Begin
    Case Button Of

      XInputGamePadRightShoulder:
        Success := SendMessage(Window.Handle, WM_LBUTTONUP, wParam(MK_LBUTTON), 0);

      XInputGamePadDPadLeft:
        Success := SendMessage(Window.Handle, WM_KEYUP, wParam(Ord('A')), 0);

      XInputGamePadDPadRight:
        Success := SendMessage(Window.Handle, WM_KEYUP, wParam(Ord('D')), 0);

      XInputGamePadDPadUp:
        Success := SendMessage(Window.Handle, WM_KEYUP, wParam(Ord('W')), 0);

      XInputGamePadDPadDown:
        Success := SendMessage(Window.Handle, WM_KEYUP, wParam(Ord('S')), 0);

    End;
  End;

Procedure ControllerStateChange(LeftStick,RightStick: TPointFloat; LeftTrigger,RightTrigger: Byte);
  Begin

  End;

Procedure ControllerStickHeld(LeftStick,RightStick: TPointFloat);
Var
MX,MY: Single;

  Begin
//    If LeftStick.X <> 0 Then Begin
//      If LeftStick.X < 0 Then Begin
//        Lefting := True;
//      End Else Begin
//        Righting := True;
//      End;
//
//    End Else Begin
//      Lefting := False;
//      Righting := False;
//    End;
//
//    If LeftStick.Y <> 0 Then Begin
//      If LeftStick.Y < 0 Then Begin
//        Downing := True;
//      End Else Begin
//        Uping := True;
//      End;
//
//    End Else Begin
//      Uping := False;
//      Downing := False;
//    End;

    MX := 5 * RightStick.X;
    MY := 5 * RightStick.Y;
    PGL.Context.Mouse.MovePosition(MX,-MY);
  End;


Procedure LostFocus();
  Begin
    Clock.Stop;
    Window.Minimize();
  End;


Procedure GotFocus();
  Begin
    Clock.Start();
    Window.Restore();
  End;


Function Biggest(Values: Array of Single): Single;
Var
I: Long;
SelVal: Single;
  Begin

    // Return the largest value in an array of values

    SelVal := 0;

    For I := 0 to High(Values) Do Begin

      If I = 0 Then Begin
        SelVal := Values[i];
        Continue;
      End;

      If Values[i] > SelVal Then Begin
        SelVal := Values[i];
      End;

    End;

    Result := SelVal;

  End;

Function Rnd(Low,High: Single): Single;
  Begin
    Result := ((High - Low) * Random) + Low;
  End;


Procedure FixRadian(Var Radian: Single);
  Begin
    If Radian > Pi * 2 Then Begin
      While Radian > Pi *2 Do Begin
        Radian := Radian - (Pi * 2);
      End;
    End Else If Radian < 0 Then Begin
      While Radian < 0 Do Begin
        Radian := Radian + (Pi *2);
      End;
    End;
  End;


Function VectorAngle(DX,DY: Single): Single;
  Begin
    Result := ArcTan2(DY,DX);
  End;


Function CheckInTriangle(Point,P1,P2,P3: TPGLVector2): Boolean;
Var
a,b,c: Single;
  Begin

    Result := false;

    a := ((P2.Y - P3.Y)*(Point.X - P3.X) + (P3.X - P2.X)*(Point.Y - P3.Y)) / ((P2.Y - P3.Y)*(P1.X - P3.X) + (P3.X - P2.X)*(P1.Y - P3.Y));
    b := ((P3.Y - P1.Y)*(Point.X - P3.X) + (P1.X - P3.X)*(Point.Y - P3.Y)) / ((P2.Y - P3.Y)*(P1.X - P3.X) + (P3.X - P2.X)*(P1.Y - P3.Y));
    c := 1 - a - b;

    If  ( (0 <= A) And (A <= 1))
    and ( (0 <= B) And (B <= 1))
    and ( (0 <= C) and (C <= 1)) Then Begin
      Result := True;
    end;

  End;


Function CheckPointInRect(Point: TPGLVector2; CheckRect: TPGLRectF; RectRotation: Single = 0): Boolean;
Var
Dist: Single;
OrgPoint: TPGLVector2;
CheckPoint: TPGLVector2;
  Begin
    Result := False;
    FixRadian(RectRotation);
    RotatePoints(Point,Vec2(CheckRect.X, CheckRect.Y),-RectRotation);

    If Point.X >= CheckRect.Left Then Begin
      If Point.X <= CheckRect.Right Then Begin
        If Point.Y >= CheckRect.Top Then Begin
          If Point.Y <= CheckRect.Bottom Then Begin
            Result := True;
          End;
        End;
      End;
    End;

  End;


Function CheckHit(): Boolean;
Var
I,R,T,X,Y: Long;
CheckPoint: TPGLVector2;
  Begin

    Result := False;


    // Enemies
    For I := 0 to High(Enemy) Do Begin

      If Enemy[i].Armor <= 0 Then Continue;

      If CheckPointInRect(CrossHair.Pos, Enemy[i].Bounds, Enemy[i].Angle) Then Begin

        CheckPoint := CrossHair.Pos;
        CheckPoint.Translate(-Enemy[i].Bounds.Left, -Enemy[i].Bounds.Top);
        If CheckInHitGrid(Enemy[i].Grid^,CheckPoint,Enemy[i].Angle,Enemy[i].Bounds.Width,Enemy[i].Bounds.Height) = True Then Begin

          Enemy[i].Hurt(1);

          For R := 0 to 4 Do Begin
            T := FindNewParticle();
            Particle[t].Place(Vec3(CrossHair.Pos.X, CrossHair.Pos.Y, Enemy[i].Pos.Z),
              Rnd(0,Pi*2),Rnd(1,5),Rnd(1,3),pgl_orange);
          End;


          R := FindNewFlash();
          Flash[r].Place(Vec3(CrossHair.Pos.X, CrossHair.Pos.Y, Enemy[i].Pos.Z), 150, pgl_red);

          Result := True;
          Exit;
        End;

      end;

    End;


    // Rockets
    For I := 0 to High(Rocket) Do Begin

      If Rocket[i].Used = False Then Continue;

      If CheckPointInRect(CrossHair.Pos, Rocket[i].Bounds, Rocket[i].Angle) Then Begin

        CheckPoint := CrossHair.Pos;
        CheckPoint.Translate(-Rocket[i].Bounds.Left, -Rocket[i].Bounds.Top);
        If CheckInHitGrid(Rocket[i].Grid^, CheckPoint, Rocket[i].Angle, Rocket[i].Bounds.Width, Rocket[i].Bounds.Height) Then Begin

          Rocket[i].Hurt(1);
          Result := True;
          Exit;

        End;

      End;
    End;

  End;


Function CheckInHitGrid(Var Grid: HitGrid; CheckPoint: TPGLVector2; Angle: Single; ScaleWidth: Single = 0; ScaleHeight: Single = 0): Boolean;
Var
ScaleX,ScaleY: Single;
CheckX, CheckY: Long;
CenterX,CenterY: Single;
OrgPoint: TPGLVector2;
I: long;
  Begin
    Result := False;
    OrgPoint := CheckPoint;

    CenterX := (Grid.Width / 2);
    CenterY := (Grid.Height / 2);

    ScaleX := Grid.Width / ScaleWidth;
    ScaleY := Grid.Height / ScaleHeight;

    CheckPoint.X := (CheckPoint.X * ScaleX);
    CheckPoint.Y := (CheckPoint.Y * ScaleY);
    RotatePoints(CheckPoint,Vec2(CenterX, CenterY),-Angle);

    CheckX := trunc(CheckPoint.X);
    CheckY := trunc(CheckPoint.Y);

    // Exit if point is outside of bounds of grid
    If (CheckX < 0) Or
      (CheckX >= Grid.Width) Or
      (CheckY < 0) Or
      (CheckY >= Grid.Height) Then Begin
      Exit;
    end;

    If Grid.Pixel[CheckX,CheckY] = 1 Then Begin
      Result := True;
    End;
  End;


Function CheckRectCollision(Rect1,Rect2: TPGLRectF): Boolean;
Var
ComWidth,Dist: Single;
  Begin
    Result := False;

    ComWidth := (Rect1.Width / 2) + (Rect2.Width / 2);
    If Abs(Rect1.X - Rect2.X) <= ComWidth Then Begin

      ComWidth := (Rect1.Height / 2) + (Rect2.Height / 2);
      If Abs(Rect1.Y - Rect2.Y) <= ComWidth Then Begin
        Result := True;
      End;
    End;

  End;


Function ReturnLineIntersect(CheckPoint: TPGLVector2; CheckRect: TPGLRectF): TPGLVector2;
Var
Center: TPGLVector2; // Center of rectangle
Corner: TPGLVector2; // Closest Corner
Side: TPGLVector2; // X,Y is either 0, -1 or 1 to show direction to the side intersected
LineAngle: Single;
LineVector: TPGLVector2;
DistTotal: Single;
CornerToAAxisDist: Single;
CenterToAAxisDist: Single;
RemDist: Single;
DistPercent: Single;
PointDist: Single;
  Begin

    Center := Vec2(CheckRect.X, CheckRect.Y);
    DistTotal := Sqrt( IntPower(CheckPoint.X - Center.X, 2) + IntPower(CheckPoint.Y - Center.Y, 2) );
    LineAngle := ArcTan2(Center.Y - CheckPoint.Y, Center.X - CheckPoint.X);

    // Get normalized vector of the intersecting line
    LineVector.X := DistTotal * Cos(LineAngle);
    LineVector.Y := DistTotal * Sin(LineAngle);
    LineVector.X := LineVector.X / DistTotal;
    LineVector.Y := LineVector.Y / DistTotal;

    // Find the Closest Corner
    Corner := Vec2((CheckRect.Width / 2) * sign(LineVector.X), ((CheckRect.Height / 2) * sign(LineVector.Y)));
    Corner.X := Corner.X + CheckRect.X;
    Corner.Y := Corner.Y + CheckRect.Y;

    // Set a vector that tells the side that was intersected
    If abs(LineVector.X) > abs(LineVector.Y) Then Begin
      Side.X := 1 * Sign(LineVector.X);
      Side.Y := 0;
    end Else Begin
      Side.X := 0;
      Side.Y := 1 * Sign(LineVector.Y);
    End;

    // Get the distance along the axis the side intersections from corner to line start
    CornerToAAxisDist := abs((CheckPoint.X - Corner.X) * Side.X) + abs((CheckPoint.Y - Corner.Y) * Side.Y);

    // Get the distance along the axis the side intersects from center to line start
    CenterToAAxisDist := abs((CheckPoint.X - Center.X) * Side.X) + abs((CheckPoint.Y - Center.Y) * Side.Y);

    // Get the amount of the Center to start dist that is 'cut off' in the rectangle;
    RemDist := CenterToAAxisDist - CornerToAAxisDist;

    // the percent of the actual distance from center to checkpoint is RemDist / CenterToAAxisDist
    DistPercent := RemDist / CenterToAAxisDist;

    // the length of our 'cut off' distance
    PointDist := DistTotal * DistPercent;

    // now we can know that the intersect point = Center + (Dist * Angle)
    Result.X := Center.X + (PointDist * Cos(LineAngle));
    Result.Y := Center.y + (PointDist * Sin(LineAngle));

  End;


Function FindNewParticle(): Long;
Var
I: Long;
  Begin
    Result := -1;
    For I := 0 to High(Particle) Do Begin
      If Particle[i].Used = False Then Begin
        Particle[i].Used := True;
        Result := I;
        Exit;
      End;
    End;
  end;


Function FindNewFlash(): Long;
Var
I: Long;
  Begin
    Result := -1;
    For I := 0 to High(Flash) Do Begin
      If Flash[i].Used = False Then Begin
        Flash[i].Used := True;
        Result := I;
        Exit;
      End;
    End;
  End;


Function FindNewExplosion(): Long;
Var
I: Long;
  Begin
    Result := -1;
    For I := 0 to High(Explosion) Do Begin
      If Explosion[i].Used = False Then Begin
        Result := I;
        Explosion[i].Used := True;
        Exit;
      End;
    End;
  End;


Function FindNewExplosionSpawn(): Long;
Var
I: Long;
  Begin
    Result := -1;
    For I := 0 to High(ExplosionSpawn) Do Begin
      If ExplosionSpawn[i].Used = False Then Begin
        ExplosionSpawn[i].Used := True;
        Result := I;
        Exit;
      End;
    end;
  End;

Function FindNewDebris(): Long;
Var
I: Long;
  Begin
    Result := - 1;
    For I := 0 to High(Debris) Do Begin
      If Debris[i].Used = False Then BEgin
        Debris[i].Used := True;
        Result := I;
        Exit;
      End;
    end;
  end;

Function FindNewRocket(): Long;
Var
I: Long;
  Begin
    Result := -1;
    For I := 0 to High(Rocket) Do Begin
      If Rocket[i].Used = False Then Begin
        Rocket[i].Used := True;
        Rocket[i].Grid := @RocketHitGrid;
        Result := I;
        Exit;
      End;
    End;
  End;


Procedure CreateStaticTextures();
Var
I: Long;
TempImage: TPGLImage;
X,Y: Long;
ColorVal: Long;
  Begin

    SetLength(TextureStatic,10);

    For I := 0 to High(TextureStatic) Do Begin

      TempImage := TPGLImage.Create(trunc(Buffer.Width / 4), trunc(Buffer.Height / 4));

      For X := 0 to TempImage.Width - 1 Do Begin
        For Y := 0 to TempImage.Height - 1 Do Begin
          ColorVal := Random(256);
          TempImage.SetPixel(Color3I(ColorVal,ColorVal,ColorVal),X,Y);
        End;
      End;

      TempImage.ReSize(Buffer.Width,Buffer.Height);

      TextureStatic[i] := TPGLTexture.CreateFromImage(TempImage);
      TempImage.Destroy();

    end;

  End;


Function CreateGeometryFromTexture(Var Texture: TPGLTexture): GeoTemp;
Var
I,Z: Long;
TempImage: TPGLImage;
TempTexture: TPGLTexture;
FoundColor: Boolean;
CheckColor: TPGLColorI;
  Begin

    TempImage := TPGLImage.CreateFromTexture(Texture);
    FoundColor := False;

    For Z := 0 to TempImage.Height - 1 Do Begin
      FoundColor := False;

      For I := 0 to TempImage.Width - 1 Do Begin
        CheckColor := TempImage.Pixel(I,Z);

        If (CheckColor.Alpha <> 0) and (FoundColor = False) Then Begin
          FoundColor := True;
          Result.AddPoint(I,Z);
          Continue;
        End Else If (CheckColor.Alpha = 0) and (FoundColor = True) Then Begin
          FoundColor := False;
          Result.AddPoint(I,Z);
          Continue;
        End Else Begin
          If (FoundColor = True) and (I = TempImage.Width - 1) Then Begin
            Result.AddPoint(I,Z);
            Continue;
          End;
        End;

        If (Z = 0) or (Z = TempImage.Height - 1) Then Begin
          If  (CheckColor.Alpha <> 0) Then Begin
            Result.AddPoint(I,Z);
            Continue;
          End;

        End Else Begin
          If (CheckColor.Alpha <> 0) Then Begin
            CheckColor := TempImage.Pixel(I,Z-1);
            If (CheckColor.Alpha = 0) Then Begin
              Result.AddPoint(I,Z);
              Continue;
            End;

            CheckColor := TempImage.Pixel(I,Z+1);
            If (CheckColor.Alpha = 0) Then Begin
              Result.AddPoint(I,Z);
              Continue;
            End;


          End;
        End;



      End;
    End;

    Result.AdjustCenter();
    Result.SortPoints();
    Result.AddPoint(Result.Point[1].X, Result.Point[1].Y);


    TempImage.Destroy();
  End;


Procedure CompleteGeometry(Var Points: TArray<TPGLVector2>);
Var
I: Long;
Len: Long;
  Begin

    Len := Length(Points) + 1;
    SetLength(Points, Len);

    I := High(Points);
    While I >= 1 Do Begin
      Points[i] := Points[i-1];
    end;

    Points[0] := GetGeometryCenter(Points);

  End;


Function GetGeometryCenter(Var Points: Array of TPGLVector2): TPGLVector2;
Var
I: Long;
LowX,HighX,LowY,HighY: Single;
  Begin

    LowX := 0;
    HighX := 0;
    LowY := 0;
    HighY := 0;

    For I := 1 to High(Points) Do Begin
      If I = 1 Then Begin
        LowX := Points[i].X;
        HighX := Points[i].X;
        LowY := Points[i].Y;
        HighY := Points[i].Y;
      End Else Begin

        If Points[i].X < LowX Then LowX := Points[i].X;
        If Points[i].X > HighX Then HighX := Points[i].X;
        If Points[i].Y < LowY Then LowY := Points[i].Y;
        If Points[i].Y > HighY Then HighY := Points[i].Y;

      End;
    End;

    Result.X := LowX + ((LowX + HighX) / 2);
    Result.Y := LowY + ((LowY + HighY) / 2);
  End;


Procedure StretchGeometry(Var Points: Array of TPGLVector2; Center: TPGLVector2; Ratio: Single);
Var
I: Long;
Angle,Dist: Single;
  Begin

    For I := 0 to High(Points) Do Begin

      Angle := ArcTan2(Points[i].Y - Center.Y, Points[i].X - Center.X);
      Dist := Sqrt( IntPower(Points[i].X - Center.X, 2) + IntPower(Points[i].Y - Center.Y, 2) );
      Dist := Dist * Ratio;
      Points[i].X := Center.X + (Dist * Cos(Angle));
      Points[i].Y := Center.Y + (Dist * Sin(Angle));

    End;

  End;


Procedure SkewGeometry(Var Points: Array of TPGLVector2; Center: TPGLVector2; Source: TPGLVector2; Angle: Single; Ratio: Single);
  Begin

  End;


Procedure CreateCrackTextures();
Var
I: Long;
X,Y,G,H: Long;
CheckColor,NewColor: TPGLColorI;
TempImage: TPGLImage;
Done: Boolean;
  Begin

    Done := False;
    I := 0;

    While Done = False Do Begin

      If FileExists(pglEXEPath + 'Graphics/Crack ' + I.ToString + '.png') = False Then Begin
        Done := True;
        Break;
      End;

      TempImage := TPGLImage.CreateFromFile(pglEXEPath + 'Graphics/Crack ' + I.ToString + '.png');

      SetLength(TextureCrack,Length(TextureCrack) + 1);
      TextureCrack[High(TextureCrack)] := TPGLTexture.CreateFromImage(TempImage);

      TempImage.Destroy();

      Inc(I);

    End;


  End;

Procedure CreateFlashTexture();
Var
TempBuffer: TPGLRenderTexture;
  Begin
    TextureFlash := TPGLTexture.Create(500,500);
    TextureFlash.SetLinearFilter();
    TempBuffer := TPGLRenderTexture.Create(500,500,32);
    TempBuffer.ChangeTexture(TextureFlash);
    TempBuffer.DrawCircle(Vec2(250,250),500,0,Color4F(1,1,1,0.75), Color3f(0,0,0),0.0);
    TempBuffer.RestoreTexture();
    TempBuffer.Destroy();
  End;


Procedure CreateExplosionTextures();
Var
I,Z: Long;
TempImage: TPGLImage;
H: Long;
CopyRect: TPGLRectI;
Radius,ArcDist,Angle,AngleInc: Single;
PointCount: Integer;
  Begin

    TempImage := TPGLImage.CreateFromFile(pglEXEPath + 'Graphics/Explosion2.png');
    H := TempImage.Height;
    CopyRect := RectIWH(0,0,H,H);
    TempImage.Brighten(1.5);

    For I := 0 to 3 do Begin
      TextureExplosion[i] := TPGLTexture.Create(H,H);
      TextureExplosion[i].CopyFrom(TempImage,CopyRect.Left,0,H,H);

      Radius := H * ((I+1) * 0.25);
      ArcDist := 2 * (Pi * Radius);
      PointCount := trunc(ArcDist / 10);
      AngleInc := (Pi*2) / PointCount;
      Angle := 0;

      For Z := 0 to PointCount Do Begin
        GeoExplosion[i].AddPoint( 0 + (Radius/2) * Cos(Angle), 0 + (Radius/2) * Sin(Angle));
        Angle := Angle + AngleInc;
      End;

      GeoExplosion[i].SetColors(CC(pgl_empty));
      GeoExplosion[i].Color[0] := Color4F(0,0,0,0.1);

      CopyRect.Translate(H,0);
    end;

    TempImage.Destroy();

  End;


Procedure CreateStars(NumStars: Integer);
Var
I,A: Integer;
  Begin
    SetLength(Star, NumStars);
    For I := 0 to High(Star) Do Begin
      Star[i].Pos.X := Rnd(0,Window.Width);
      Star[i].Pos.Y := Rnd(0,Window.Height);
      Star[i].Size := Rnd(2,4);
      Star[i].Color := pgl_white;

      A := Random(10);

      If A = 0 Then Begin

        A := Random(4);

        Case A Of

          0: Star[i].Color := pgl_Red;
          1: Star[i].Color := pgl_blue;
          2: Star[i].Color := pgl_yellow;
          3: Star[i].Color := pgl_Orange;

        End;

      End;

    End;

    TheSun.X := (buffer.Width / 2) + Rnd(-HalfWidth,HalfWidth);
    TheSun.Y := (buffer.Height / 2) + Rnd(-HalfWidth,HalfWidth);
  End;


Procedure CreatePlanets();
Var
I,R,H: Long;
Failed: Boolean;
  Begin
    Failed := False;
    I := 0;

    While Failed = False Do Begin

      Inc(I);

      Failed := Not FileExists(pglEXEPath + 'Graphics/Planet ' + I.toString + '.png');

      If Failed = False Then Begin
        SetLength(Planet,Length(Planet) + 1);
        R := High(Planet);
        Planet[r].Texture := TPGLTexture.CreateFromFile(pglEXEPath + 'Graphics/Planet ' + I.ToString + '.png');
        Planet[r].Bounds.Width := Planet[r].Texture.Width;
        Planet[r].Bounds.Height := Planet[r].Texture.Height;
        Planet[r].Bounds.SetCenter( Rnd((Buffer.Width / 2) - 2000, (Buffer.Width / 2) + 2000), Rnd((Buffer.Height / 2) - 2000, (Buffer.Height / 2) + 2000));

        SetLength(GeoPlanet,R+1);
        GeoPlanet[r] := CreateGeometryFromTexture(Planet[r].Texture);
        GeoPlanet[r].SetColors(CC(pgl_empty));
        GeoPlanet[r].Color[0] := Color4f(0,0,0,0.5);
        StretchGeometry(GeoPlanet[r].Point, GeoPlanet[r].Point[0], 500);
      End;

    End;

  End;


Procedure CreateEnemies();
Var
I: Long;
  Begin

    SetLength(Enemy,10);
    EnemiesLeft := 15;

    For I := 0 to High(Enemy) Do Begin
      Enemy[i].Pos := Vec3( (Buffer.Width / 2) + Rnd(-HalfWidth,HalfWidth),
                            (Buffer.Height / 2) + Rnd(-HalfWidth,HalfWidth),
                            Rnd(0.2,1.5));

      Enemy[i].Bounds := RectF(Vec2(Enemy[i].Pos), TextureEnemy.Width, TextureEnemy.Height);
      Enemy[i].Bounds.Stretch(Enemy[i].Pos.Z, Enemy[i].Pos.Z);
      Enemy[i].Angle := Rnd(0,Pi * 2);
      Enemy[i].Speed := Rnd(5,15);
      Enemy[i].Armor := 10;
      Enemy[i].RocketTimer := 1;
      Enemy[i].Grid := @EnemyHitGrid;
      Enemy[i].ShadowGeometry := @ GeoEnemy;
      Enemy[i].RadarPoint.Used := true;
      Enemy[i].RadarPoint.Pos := Vec2(Enemy[i].Pos);
      Enemy[i].RadarPoint.Color := pgl_green;
      Enemy[i].RadarPoint.Opacity := 0;
      Enemy[i].EnemyType := 1;
      Enemy[i].RocketSpawn.SetAttributes(0,1,1,@Enemy[i]);
      Enemy[i].RocketSpawn.Pos := Enemy[i].Pos;
    End;

  End;


Procedure CreateHitGrid(Image: TPGLImage; Var Grid: HitGrid);
Var
I,Z: Long;
  Begin
    SetLength(Grid.Pixel, Image.Width, Image.Height);
    Grid.Width := Image.Width;
    Grid.Height := Image.Height;

    For I := 0 to Image.Width - 1 Do Begin
      For Z := 0 to Image.Height - 1 Do Begin

        If Image.Pixel(I,Z).IsColor(pgl_empty) Then Begin
          Grid.Pixel[I,Z] := 0;
        End Else Begin
          Grid.Pixel[I,Z] := 1;
        End;

      End;
    End;

  End;


Procedure DrawStars();
Var
I: Integer;
DRect: TPGLRectF;
DrawColor: TPGLColorF;
Dist: Single;
  Begin
    For I := 0 to High(Star) Do Begin
      DrawColor := CC(Star[i].Color);
      DrawColor.Alpha := DrawColor.Alpha * (1-BrightVal);
      Buffer.DrawCircle(Star[i].Pos,Star[i].Size,0,DrawColor,DrawColor,0.5);
    End;

    Sprite.SetAngle(0);


    // The sun
    DRect := RectF(TheSun,100,100);
    If CheckRectCollision(DRect,Buffer.RenderRect) Then Begin
      Buffer.DrawCircle(TheSun,100,0,Color3f(1,1,0.8),Color3f(0,0,0),0.8);
    end;

    DRect.Stretch(5,5);
    If CheckRectCollision(DRect,Buffer.RenderRect) Then Begin
      Buffer.DrawCircle(TheSun,DRect.Width, 0, Color4F(1,1,1,0.5), cc(pgl_white), 0.0);
    End;


  End;


Procedure DrawPlanets();
Var
I: Long;
DrawRect: TPGLRectF;
  Begin

    For I := 0 to High(Planet) Do Begin
      DrawRect := Planet[i].Bounds;
      DrawList.AddDraw(Planet[i].Texture, Vec3(Planet[i].Bounds.X, Planet[i].Bounds.Y, 0.001),
        DrawRect, pgl_white, pgl_empty, 0, 1, @GeoPlanet[i]);
    End;

  End;


Procedure DrawHUD();
Var
Center: TPGLVector2;
Points: Array of TPGLVector2;
Points2: Array of TPGLVector2;
DrawRect, GaugeRect: TPGLRectF;
Ratio: Single;
Angle: Single;
I: Long;
UseAngle,AngleInc: Single;
DispText: String;
OutlineColor: TPGLColorI;
IPoint: TPGLVector2;
  Begin

    // Glass Panel Lines

    If Instability <> 0 Then Begin
      DrawStatic();
    End;

    Center.X := Buffer.Width / 2;
    Center.Y := (Buffer.Height / 2) - 75;

    SetLength(Points,6);

    UseAngle := 0;
    AngleInc := (Pi * 2) / Length(Points);

    For I := 0 to 5 Do Begin
      Points[i].X := Center.X + (200 * Cos(UseAngle));
      Points[i].Y := Center.Y + (200 * Sin(Useangle));
      GlassPoints[i] := Points[i];
      UseAngle := UseAngle + AngleInc;
    end;


    Window.DrawLine(Points[0], Points[1], 3, 0, Color3f(0.1,0.1,0.1), Color3f(0,0,0));
    Window.DrawLine(Points[1], Points[2], 3, 0, Color3f(0.1,0.1,0.1), Color3f(0,0,0));
    Window.DrawLine(Points[2], Points[3], 3, 0, Color3f(0.1,0.1,0.1), Color3f(0,0,0));
    Window.DrawLine(Points[3], Points[4], 3, 0, Color3f(0.1,0.1,0.1), Color3f(0,0,0));
    Window.DrawLine(Points[4], Points[5], 3, 0, Color3f(0.1,0.1,0.1), Color3f(0,0,0));
    Window.DrawLine(Points[5], Points[0], 3, 0, Color3f(0.1,0.1,0.1), Color3f(0,0,0));

    SetLength(Points2,6);

    UseAngle := 0;
    For I := 0 to 5 Do Begin
      Points2[i].X := Points[i].X + (500 * Cos(UseAngle));
      Points2[i].Y := Points[i].Y + (500 * sin(UseAngle));
      Window.DrawLine(Points[i],Points2[i], 3, 0, Color3f(0.1,0.1,0.1), Color3f(0,0,0));
      UseAngle := UseAngle + AngleInc;
    End;



    // Enemy Boxes
    If HUDFlash = True Then Begin

      For I := 0 to High(Enemy) do Begin
        If enemy[i].Armor > 0 Then Begin
          If CheckRectCollision(Enemy[i].Bounds, Buffer.RenderRect) Then Begin

            If Enemy[i].WasHit = 0 Then Begin
              OutlineColor := Color4I(100,255,100,200);
            End Else Begin
              OutlineColor := Color4I(255,50,50,200);
            End;

            EditBuffer.SetBlendFactors(ONE, ZERO);
            EditBuffer.Clear(pgl_empty);

//            GaugeRect := RectFWH(0,0,Enemy[i].Bounds.Width * 1.33, Enemy[i].Bounds.Height * 1.33);

            GaugeRect.Width := Biggest([Enemy[i].Bounds.Width * 1.33, Enemy[i].Bounds.Height * 1.33]);
            GaugeRect.ReSize(GaugeRect.Width, GaugeRect.Width);
            // Make Sure the rect is of a reasonable, visible size
            If (GaugeRect.Width < 50) Then Begin
              GaugeRect.Resize(50, 50);
            End;

            GaugeRect.SetTopLeft(0,0);

            // Draw Rounded Outline
            EditBuffer.DrawRectangle(GaugeRect, 3, pgl_empty, OutlineColor,5);

            // 'Erase' Middle of sides of Outline
            EditBuffer.DrawRectangle(RectF(Vec2(GaugeRect.X, GaugeRect.Y), GaugeRect.Width * 0.5, GaugeRect.Height),
              0,pgl_empty,pgl_empty);

            EditBuffer.DrawRectangle(RectF(Vec2(GaugeRect.X, GaugeRect.Y), GaugeRect.Width, GaugeRect.Height * 0.5),
              0,pgl_empty,pgl_empty);

            EditBuffer.DrawLastBatch();

            // Draw Outline to Buffer
            DrawRect := GaugeRect;
            DrawRect.SetCenter(Enemy[i].Pos.X, Enemy[i].Pos.Y);
            EditBuffer.CopyBlt(Window, DrawRect, GaugeRect);
          End;
        End;
      End;

    End;


    DrawCracks();

    // Bottom Control Panel

    SetLength(Points,6);
    Points[0] := Vec2(0,Buffer.Height - 150);
    Points[1] := Vec2(75,Buffer.Height - 100);
    Points[2] := Vec2(Buffer.Width - 75, Buffer.Height - 100);
    Points[3] := Vec2(Buffer.Width, Buffer.Height - 150);
    Points[4] := Vec2(Buffer.Width,Buffer.Height);
    Points[5] := Vec2(0,Buffer.Height);

    Window.DrawRectangle(RectFWH(0,Buffer.Height - 100,Buffer.Width,100),0,CC(BD(Color3I(80,120,0))),CC(Color3I(80,120,0)));

    Window.DrawGeometry( [Points[0], Points[1], Points[5] ], CC(BD(Color3I(40,60,0))) );
    Window.DrawGeometry( [Points[2], Points[3], Points[4] ], CC(BD(Color3I(40,60,0))) );

    Window.DrawLine(Points[0],Points[1],2,0,cc(pgl_DarkGrey),cc(pgl_DarkGrey));
    Window.DrawLine(Points[1],Points[2],2,0,cc(pgl_DarkGrey),cc(pgl_DarkGrey));
    Window.DrawLine(Points[2],Points[3],2,0,cc(pgl_DarkGrey),cc(pgl_DarkGrey));
    Window.DrawLine(Points[3],Points[4],2,0,cc(pgl_DarkGrey),cc(pgl_DarkGrey));
    Window.DrawLine(Points[4],Points[5],2,0,cc(pgl_DarkGrey),cc(pgl_DarkGrey));
    Window.DrawLine(Points[5],Points[0],2,0,cc(pgl_DarkGrey),cc(pgl_DarkGrey));
    Window.DrawLine(Points[1], Points[5],2,0,CC(pgl_DarkGrey), CC(pgl_DarkGrey));
    Window.DrawLine(Points[2], Points[4],2,0,CC(pgl_DarkGrey), CC(pgl_DarkGrey));

    // Ammo/Fuel Panel

    DrawRect := RectF( Vec2(Buffer.Width / 2, Buffer.Height - 50), 200,80);
    Window.DrawRectangle(DrawRect,2,cc(pgl_black),cc(pgl_white),5);
    Window.DrawText('Ammo: ', Font, 12, Vec2(DrawRect.Left + 5, DrawRect.Top + 2), 0, pgl_blue,pgl_green,False);
    Window.DrawText('Fuel: ', Font, 12, Vec2(DrawRect.Left + 5, DrawRect.Top + 20), 0, pgl_yellow,pgl_green,False);
    Window.DrawText('Armor: ', Font, 12, Vec2(DrawRect.Left + 5, DrawRect.Top + 38), 0, pgl_green,pgl_green,False);

    // Ammo Gauage
    GaugeRect := RectFWH(DrawRect.Left + 45,DrawRect.Top + 5, DrawRect.Width - 50, 12);
    Buffer.DrawRectangle(GaugeRect,2,cc(pgl_empty),cc(pgl_blue));
    Ratio := Ammo/MaxAmmo;
    GaugeRect.Width := GaugeRect.Width * Ratio;
    GaugeRect.Update(FROMLEFT);
    Window.DrawRectangle(GaugeRect,0,cc(pgl_blue),cc(pgl_blue));

    // Fuel Gauage
    GaugeRect := RectFWH(DrawRect.Left + 45,DrawRect.Top + 23, DrawRect.Width - 50, 12);
    Buffer.DrawRectangle(GaugeRect,2,cc(pgl_empty),cc(pgl_yellow));
    Ratio := Fuel/MaxFuel;
    GaugeRect.Width := GaugeRect.Width * Ratio;
    GaugeRect.Update(FROMLEFT);
    Window.DrawRectangle(GaugeRect,0,cc(pgl_yellow),cc(pgl_yellow));

    // Armor Gauage
    GaugeRect := RectFWH(DrawRect.Left + 45,DrawRect.Top + 41, DrawRect.Width - 50, 12);
    Buffer.DrawRectangle(GaugeRect,2,cc(pgl_empty),cc(pgl_green));
    Ratio := Armor/MaxArmor;
    GaugeRect.Width := GaugeRect.Width * Ratio;
    GaugeRect.Update(FROMLEFT);
    Window.DrawRectangle(GaugeRect,0,cc(pgl_green),cc(pgl_green));

    // Rotation Display
    GaugeRect := RectF(Vec2(Buffer.Width * 0.25, Buffer.Height - 70),150,50);
    Window.DrawRectangle(GaugeRect,2,pgl_black, pgl_darkGrey,5);

    DispText := abs(PXVal).toString(abs(PXVal),TFloatFormat.ffFixed,4,4);
    If abs(PXVal) >= 10 Then Begin
      DispText := ' ' + DispText;
    End Else Begin
      DispText := '  ' + DispText;
    End;
    If PXVal > 0 Then Begin
      DispText[1] := '-';
    End;
    Window.DrawText(DispText, Font, 12, Vec2(GaugeRect.Left + 3, GaugeRect.Top + 5), 0, pgl_white, pgl_white, False);

    DispText := abs(PYVal).toString(abs(PYVal),TFloatFormat.ffFixed,4,4);
    If abs(PYVal) >= 10 Then Begin
      DispText := ' ' + DispText;
    End Else Begin
      DispText := '  ' + DispText;
    End;
    If PYVal > 0 Then Begin
      DispText[1] := '-';
    End;
    Window.DrawText(DispText, Font, 12, Vec2(GaugeRect.Left + 3, GaugeRect.Top + 20), 0, pgl_white, pgl_white, False);

    // Lock On Display
    GaugeRect := RectF(Vec2(Buffer.Width * 0.25, Buffer.Height - 30),150,25);

    If DisplayRocketLock = False Then Begin
      Window.DrawRectangle(GaugeRect,2,pgl_black,pgl_darkgrey,5);
    End Else Begin
      Window.DrawRectangle(GaugeRect,2,pgl_red,pgl_darkgrey,5);
      TextBox.SetText('! LOCK ON DETECTED !');
      TextBox.SetColor(pgl_white);
      TextBox.SetCenter(Vec2(GaugeRect.X,GaugeRect.Y));
      Window.DrawText(TextBox);
    end;

    // Alarm Light
    Sprite.SetAngle(0);
    Sprite.SetTexture(TextureAlarmOff);
    Sprite.Bounds.SetRight(GaugeRect.Left - 25);
    Sprite.Bounds.SetBottom(GaugeRect.Bottom);
    Sprite.SetColors(BD(pgl_white));

    If DisplayRocketLock = True Then Begin
      Sprite.SetTexture(TextureAlarmOn);
    End;

    Window.DrawSprite(Sprite);
    Sprite.SetColors(pgl_white);

    If DisplayRocketLock = True Then Begin
      Window.DrawCircle(Sprite.Center, Sprite.Width * 5, 0, Color4F(1,0.25,0.25,0.75), Color4F(0,0,0,0),0.0);
    End;


    // Radar
    DrawRadar();

    // Laser Canons
    DrawCanons();

    // Red Overlay for Rocket Lock On
    If DisplayRocketLock = True Then Begin
      Window.DrawRectangle(Buffer.RenderRect, 0, Color4F(1,0,0,0.1), Color4F(0,0,0,0));
    End;

  End;


Procedure DrawRadar();
Var
ScaleX, ScaleY: Single;
X,Y: single;
IPoint: TPGLVector2;
I: Long;
  Begin

    // Draw Black Background
    RadarRect.Width := 90;
    RadarRect.Height := 90;
    RadarRect.SetCenter( trunc((Buffer.Width * 0.75)), Buffer.Height - 50);
    Window.DrawRectangle(RadarRect,0,pgl_black,pgl_DarkGrey);

    // draw radar scan line
    X := RadarRect.X + (300 * Cos(RadarAngle));
    Y := RadarRect.Y + (300 * Sin(RadarAngle));
    IPoint := ReturnLineIntersect(Vec2(X,Y), RadarRect);
    Window.DrawLine(Vec2(RadarRect.X, RadarRect.Y), IPoint, 1,0,Color3F(0,0.5,0), Color3F(0,0.5,0));

    Window.DrawPoint(RadarRect.X, RadarRect.Y, 3, pgl_white);

    ScaleX := trunc(RadarRect.Width) / PlayWidth;
    ScaleY := trunc(RadarRect.Height) / PlayWidth;

    // Draw Ships
    For I := 0 to High(Enemy) Do Begin
      If Enemy[i].Armor > 0 Then Begin

        X := (Enemy[i].RadarPoint.Pos.X - trunc(Buffer.Width / 2)) * ScaleX;
        Y := (Enemy[i].RadarPoint.Pos.Y - trunc(Buffer.Height / 2)) * ScaleY;
        X := X + RadarRect.X;
        Y := Y + RadarRect.Y;

        Window.DrawCircle(X,Y,2,0,Enemy[i].RadarPoint.Color,Enemy[i].RadarPoint.Color);

      End;
    End;


    // Draw Rockets
    For I := 0 to High(Rocket) Do Begin
      If Rocket[i].Used = True Then Begin

        X := (Rocket[i].Pos.X - trunc(Buffer.Width / 2)) * ScaleX;
        Y := (Rocket[i].Pos.Y - trunc(Buffer.Height / 2)) * ScaleY;
        X := X + RadarRect.X;
        Y := Y + RadarRect.Y;

        Window.DrawCircle(X,Y,2,0,pgl_red,pgl_red);

      End;
    End;

    // DrawBorder
    RadarRect.Grow(1.5,1.5);
    Window.DrawRectangle(RadarRect,3,pgl_empty,pgl_darkgrey);

  End;


Procedure DrawCanons();
  Begin

    If HeatVisible = False Then Exit;

    // Left Canon
    LeftCanonSprite.SetCenter(Vec2(50 + (LeftCanonSprite.Width / 2), (Buffer.Height - 150) - (LeftCanonSprite.Height / 2)));
    LeftCanonSprite.SetColors( Color3I( Trunc(255 * (1 - (LaserLeftHeat / 100))), Trunc(255 * (LaserLeftHeat / 100)), 0));
    Buffer.DrawSprite(LeftCanonSprite);

    // Right Canon
    RightCanonSprite.SetCenter(Vec2(Buffer.Width - 50 - (RightCanonSprite.Width / 2), (Buffer.Height - 150) - (RightCanonSprite.Height / 2)));
    RightCanonSprite.SetColors( Color3I( Trunc(255 * (1 - (LaserRightHeat / 100))), Trunc(255 * (LaserRightHeat / 100)), 0));
    Buffer.DrawSprite(RightCanonSprite);

    If OverHeated = True Then Begin
      Sprite.SetTexture(TextureOverHeated);
      Sprite.SetAngle(0);
      Sprite.SetCenter(LeftCanonSprite.Center);
      Buffer.DrawSprite(Sprite);

      Sprite.SetCenter(RightCanonSprite.Center);
      Buffer.DrawSprite(Sprite);
    End;

  End;

Procedure DrawLasers();
Var
Points: Array [0..2] of TPGLVector2;
  Begin
    If ShootStage = 1 Then Begin
      Points[0] := Vec2(-20,Buffer.Height);
      Points[1] := CrossHair.Pos;
      Points[2] := Vec2(20,Buffer.Height);
      Window.DrawGeometry(Points,CC(pgl_red));
      Window.DrawCircle(Vec2(0,Buffer.Height), 600, 0, Color4F(1,0,0,0.75), Color4f(0,0,0,0), 0.0);
    End Else If ShootStage = 3 Then Begin
      Points[0] := Vec2(Buffer.Width - 20 ,Buffer.Height);
      Points[1] := CrossHair.Pos;
      Points[2] := Vec2(Buffer.Width + 20,Buffer.Height);
      Window.DrawGeometry(Points,CC(pgl_red));
      Window.DrawCircle(Vec2(Buffer.Width,Buffer.Height), 600, 0, Color4F(1,0,0,0.75), Color4f(0,0,0,0), 0.0);
    End;
  End;


Procedure DrawCracks();
Var
I,R: Long;
  Begin

    If Length(Cracks) = 0 Then Exit;

    For I := 0 to High(Cracks) Do Begin
      Sprite.SetTexture(Cracks[i].Texture);
      Sprite.SetSize(Cracks[i].Bounds.Width, Cracks[i].Bounds.Height);
      Sprite.SetCenter(Cracks[i].Pos);
      Sprite.SetAngle(Cracks[i].Rotation);
      Sprite.SetOpacity(0.5);
      Window.DrawSprite(Sprite);
      Sprite.SetOpacity(1);
    End;

  End;


Procedure DrawEnemies();
Var
I: Long;
Dist,X,Y: Single;
EWidth,FWidth: Single;
GrowVal: Single;
DrawRect: TPGLRectF;
  Begin

    For I := 0 to High(Enemy) Do Begin

      If Enemy[i].Armor <= 0 Then Continue;
      If CheckRectCollision(Enemy[i].Bounds,Buffer.RenderRect) = False Then Continue;

      // Draw The Enemy
      EWidth := Enemy[i].Bounds.Width;
      DrawList.AddDraw(TextureEnemy, Enemy[i].Pos, Enemy[i].Bounds, pgl_white, pgl_empty,
        Enemy[i].Angle,1, Enemy[i].ShadowGeometry);

      // Draw The exhaust flame

      GrowVal := Rnd(0.8,1.2);
      FWidth := TextureFlame.Width * Enemy[i].Pos.Z;
      Dist := ((EWidth / 2) + (FWidth / 2));
      X := Enemy[i].Pos.X + (Dist * Cos(Enemy[i].Angle - Pi));
      Y := Enemy[i].Pos.Y + (Dist * Sin(Enemy[i].Angle - Pi));
      DrawRect.Width := (TextureFlame.Width * GrowVal) * Enemy[i].Pos.Z;
      DrawRect.Height := (TextureFlame.Height * GrowVal) * Enemy[i].Pos.Z;
      DrawRect.SetCenter(X,Y);

      DrawList.AddDraw(TextureFlame, Vec3(X,Y,Enemy[i].Pos.Z),
        DrawRect, pgl_white, pgl_black,
        Enemy[i].Angle,1);
    End;

  End;


Procedure DrawParticles();
Var
I: Long;
DrawColor: TPGLColorI;
  Begin
    Sprite.SetTexture(TextureFlash);

    For I := 0 to High(Particle) Do Begin
      If Particle[i].Used = True Then Begin

        If CheckPointInRect(Vec2(Particle[i].Pos), Buffer.RenderRect,0) = False Then Continue;

        DrawList.AddDraw(TextureFlash, Particle[i].Pos,
          RectF(Vec2(Particle[i].Pos), Particle[i].Size, Particle[i].Size),Particle[i].Color, Particle[i].Color,0,1);
       End;
    End;
  end;


Procedure DrawFlashes();
Var
I: Long;
CheckRect: TPGLRectF;
DrawColor: TPGLColorF;
  Begin
    For I := 0 to High(Flash) Do Begin
      If Flash[i].Used = true Then Begin
        CheckRect := RectF(Vec2(Flash[i].Pos), Flash[i].Size * Flash[i].Pos.Z, flash[i].Size * Flash[i].Pos.Z);
        CheckRect.Stretch(1 / Flash[i].Frames, 1 / Flash[i].Frames);
        If CheckRectCollision(CheckRect,Buffer.RenderRect) = True Then Begin

          DrawList.AddDraw(TextureFlash, Flash[i].Pos, RectF(Vec2(Flash[i].Pos),Flash[i].Size, Flash[i].Size),
            Flash[i].Color, Flash[i].Color, 0, (Flash[i].Color.Alpha / 255));
        End;
      End;
    End;
  End;


Procedure DrawExplosions();
Var
I: Long;
DrawRect: TPGLRectF;
  Begin

    For I := 0 to High(Explosion) Do Begin
      If Explosion[i].Used = True Then Begin
        DrawRect.Width := Explosion[i].Bounds.Width * Explosion[i].Size;
        DrawRect.Height := DrawRect.Width;
        DrawRect.SetCenter(Explosion[i].Pos.X, Explosion[i].Pos.Y);

        DrawList.AddDraw(TextureExplosion[Explosion[i].Stage],Explosion[i].Pos,
          DrawRect,pgl_white,pgl_empty,0,1,@GeoExplosion[Explosion[i].Stage]);
      End;
    End;

  End;

Procedure DrawDebris();
Var
I: Long;
  Begin

    For I := 0 to High(Debris) Do Begin
      If Debris[i].Used = TRue Then Begin

        DrawList.AddDraw(TextureDebris[Debris[i].Debristype],Debris[i].Pos, Debris[i].Bounds, pgl_white, pgl_empty,
          Debris[i].Angle,1,@GeoDebris[Debris[i].DebrisType]);
      End;
    End;
  End;


Procedure DrawRockets();
Var
I: Long;
  Begin
    For I := 0 to High(Rocket) Do Begin
      If Rocket[i].Used = True Then Begin

        DrawList.AddDraw(TextureRocket,Rocket[i].Pos,Rocket[i].Bounds,pgl_white,pgl_empty,Rocket[i].angle,1,@GeoRocket);

      End;
    End;
  End;


Procedure DrawStatic();
Var
I: Long;
  Begin

    I := Random(Length(TextureStatic));
    Sprite.SetTexture(TextureStatic[i]);
    Sprite.SetSize(Buffer.Width, Buffer.Height);
    Sprite.SetCenter(Vec2((Buffer.Width / 2), (Buffer.Height / 2)) );
    Sprite.SetAngle(0);
    Sprite.SetOpacity(1 * (Instability / 10));
    Buffer.DrawSprite(Sprite);
    Sprite.SetOpacity(1);
  End;

Procedure HandleMove();
Var
I: Long;
FuelDrain: Single;
CAngle: Single;
CDist: Single;
  Begin

    FuelDrain := 0;

    InStability := InStability * 0.95;
    If InStability <= 0.01 Then Begin
      InStability := 0;
    End;

    If Lefting = True Then Begin
      PXVal := PXVal + 0.5;
      FuelDrain := FuelDrain + 0.001;
    End;

    If Righting = True Then Begin
      PXVal := PXVal - 0.5;
      FuelDrain := FuelDrain + 0.001;
    End;

    If Uping = True Then Begin
      PYVal := PYVal + 0.5;
      FuelDrain := FuelDrain + 0.001;
    End;

    If Downing = true Then Begin
      PYval := PYval - 0.5;
      FuelDrain := FuelDrain + 0.001;
    end;

    If PXVal < -15 Then Begin
      PXVal := -15;
    End Else If PXVal > 15 Then Begin
      PXVal := 15;
    End;

    If PYVal < -15 Then Begin
      PYVal := -15;
    End Else If PYVal > 15 Then Begin
      PYVal := 15;
    End;


    If AutoSlow = True Then Begin
      If (Lefting = False) and (Righting = False) Then Begin
        PXVal := PXVal * 0.95;
        If Abs(PXVal) < 0.01 Then Begin
          PXVal := 0;
        End;
      End;

      If (Uping = False) and (Downing = False) Then Begin
        PYVal := PYVal * 0.95;
        If Abs(PYVal) < 0.01 Then Begin
          PYVal := 0;
        End;
      end;
    End;

    Fuel := Fuel - (0.001 + FuelDrain);

    EngineHumSound.SetFixedPitch(1 + ((abs(PXVal) + abs(PYVal)) / 50)  );


    For I := 0 to High(Star) Do Begin

      Star[i].Pos.X := Star[i].Pos.X + PXVal;
      If Star[i].Pos.X > Buffer.Width - 1 Then Begin
        Star[i].Pos.X := Star[i].Pos.X - Buffer.Width;
      End Else If Star[i].Pos.X < 0 Then Begin
        Star[i].Pos.X := Star[i].Pos.X + Buffer.Width;
      End;

      Star[i].Pos.Y := Star[i].Pos.Y + PYVal;
      If Star[i].Pos.Y > Buffer.Height - 1 Then Begin
        Star[i].Pos.Y := Star[i].Pos.Y - Buffer.Height;
      End Else If Star[i].Pos.Y < 0 Then Begin
        Star[i].Pos.Y := Star[i].Pos.Y + Buffer.Height;
      End;

    end;

    // The Sun
    TheSun.Translate(PXVal,PYVal);
    If TheSun.X < (Buffer.Width / 2) - HalfWidth Then Begin
      TheSun.X := TheSun.X + PlayWidth;
    End Else If TheSun.X > (Buffer.Width / 2) + HalfWidth Then Begin
      TheSun.X := TheSUn.X - PlayWidth;
    End;

    If TheSun.Y < (Buffer.Height / 2) - HalfWidth Then Begin
      TheSun.Y := TheSun.Y + PlayWidth;
    End Else If TheSun.Y > (Buffer.Height / 2) + HalfWidth Then Begin
      TheSun.Y := TheSUn.Y - PlayWidth;
    End;


    For I := 0 to High(Planet) Do Begin
      Planet[i].Bounds.Translate(PXVal,PYVal);
      Planet[i].CheckInBounds();
    end;

    For I := 0 to High(Enemy) Do Begin
      If Enemy[i].Armor > 0 Then Begin
        Enemy[i].Move(PXVal, PYVal);
      End;
    End;

    For I := 0 to High(Flash) do Begin
      If Flash[i].Used = True Then Begin
        Flash[i].Move(PXVal,PYVal);
      End;
    End;

    For I := 0 to High(Particle)Do Begin
      If Particle[i].Used = True Then Begin
        Particle[i].Pos.Translate(PXVal, PYVal);
      End;
    End;


    For I := 0 to High(Explosion) Do Begin
      If Explosion[i].Used = True Then Begin
        Explosion[i].Pos.Translate(PXVal, PYVal, 0);
        Explosion[i].Bounds.SetCenter(Explosion[i].Pos.X, Explosion[i].Pos.Y);
      End;
    End;

    For I := 0 to High(ExplosionSpawn) Do Begin
      If ExplosionSpawn[i].Used = True Then Begin
        ExplosionSpawn[i].Pos.Translate(PXVal, PYVal, 0);
      End;
    End;

    For I := 0 to High(Rocket) Do Begin
      If Rocket[i].Used = True Then Begin

        Rocket[i].Pos.Translate(PXval, PYval,0);
        If Rocket[i].Pos.X < (Buffer.Width / 2) - HalfWidth Then Begin
          Rocket[i].Pos.X := Rocket[i].Pos.X  + PlayWidth;
        End Else If Rocket[i].Pos.X > (Buffer.Width / 2) + HalfWidth Then Begin
          Rocket[i].Pos.X := Rocket[i].Pos.X - PlayWidth;
        End;

        If Rocket[i].Pos.Y < (Buffer.Height / 2) - HalfWidth Then Begin
          Rocket[i].Pos.Y := Rocket[i].Pos.Y + PlayWidth;
        End Else If Rocket[i].Pos.Y > (Buffer.Height / 2) + HalfWidth Then Begin
          Rocket[i].Pos.Y := Rocket[i].Pos.Y - PlayWidth;
        End;

        Rocket[i].Bounds.SetCenter(Rocket[i].Pos.X, Rocket[i].Pos.y);

      End;
    End;

  End;


Procedure HandleShoot();
  Begin

    If OverHeated = True Then Exit;

    If Shooting = False Then Exit;
    If Ammo = 0 Then Exit;

    LaserLeftVisible := False;
    LaserRightVisible := False;
    ShootVar := ShootVar + 1;

    If ShootVar >= 2 Then Begin
      ShootVar := 0;

      ShootStage := ShootStage + 1;

      If ShootStage >= 4 Then Begin
        ShootStage := 0;
      End;

      If ShootStage = 1 Then Begin
        If Ammo > 0 Then Begin
          Ammo := Ammo - 1;
          LaserLeftVisible := True;
          Audio.PlayFromBuffer(LaserBuffer,0,Buffer.Height, 800,0,1,1,360,1);
          CheckHit();
          HeatLasers();
        End;
      End Else If ShootStage = 3 Then Begin
        If Ammo > 0 Then Begin
          Ammo := Ammo - 1;
          LaserRightVisible := True;
          Audio.PlayFromBuffer(LaserBuffer,Buffer.Width, Buffer.Height, 800,0,1,1,360,1);
          CheckHit();
          HeatLasers();
        End;
      End;

    End;


  End;


Procedure HandleParticles();
Var
I: Long;
  Begin
    For I := 0 to high(Particle) Do Begin
      If Particle[i].Used = True Then Begin
        Particle[i].Move();
      End;
    End;
  End;


Procedure HandleFlashes();
Var
I: Long;
  Begin
    For I := 0 to High(Flash) Do Begin
      If Flash[i].Used = True Then Begin
        Flash[i].Handle();
      End;
    End;
  end;


Procedure HandleEnemies();
Var
I: Long;
  Begin
    For I := 0 to High(Enemy) Do Begin
      If Enemy[i].Armor > 0 Then Begin

        Enemy[i].CheckState();

        If Enemy[i].WasHit > 0 Then Begin
          Dec(Enemy[i].WasHit);
        End;
      End;
    End;
  End;


Procedure HandleExplosions();
Var
I: Long;
  Begin
    For I := 0 to High(Explosion) Do Begin
      If Explosion[i].Used = True Then Begin
        Explosion[i].Handle();
      End;
    End;
  End;


Procedure HandleExplosionSpawns();
Var
I: Long;
  Begin
    For I := 0 to High(ExplosionSpawn) Do Begin
      If ExplosionSpawn[i].Used = True Then Begin
        ExplosionSpawn[i].Handle();
      End;
    end;
  End;

Procedure HandleDebris();
Var
I: Long;
  Begin
    For I := 0 to High(Debris) Do Begin
      If Debris[i].Used = True Then Begin
        Debris[i].Move();
      End;
    End;
  End;

Procedure HandleRockets();
Var
I: Long;
  Begin
    For I := 0 to High(Rocket) Do Begin
      If Rocket[i].Used = True Then Begin
        Rocket[i].Handle();
      End;
    End;
  End;


Procedure HandleRadar();
Var
I,R: Long;
Points: Array [0..2] of TPGLVector2;
  Begin

    // Handle the radar sweep
    RadarAngle := RadarAngle + ( (Pi*2) * (1/180) );
    FixRadian(RadarAngle);
    Points[0] := Vec2(Buffer.Width / 2, Buffer.Height / 2);
    Points[1].X := Points[0].X + (7000 * Cos(RadarAngle));
    Points[1].Y := Points[0].Y + (7000 * Sin(RadarAngle));
    Points[1].X := Points[0].X + (7000 * Cos(RadarLastAngle));
    Points[1].Y := Points[0].Y + (7000 * Sin(RadarLastAngle));

    For I := 0 to High(Enemy) Do Begin
      If Enemy[i].Armor > 0 Then Begin
        If CheckInTriangle(Vec2(Enemy[i].Pos),Points[0], Points[1], Points[2]) Then Begin
          Enemy[i].RadarPoint.Opacity := 1;
        End;
      End;
    End;

    RadarLastAngle := RadarAngle;


  End;

Procedure HitGrid.SaveToBMP();
Var
TempImage: TPGLImage;
I,Z: Long;
  Begin
    TempImage := TPGLImage.Create(Self.Width,Self.Height);
    For I := 0 To Self.Width - 1 Do Begin
      For Z := 0 to Self.Height - 1 Do Begin
        If Self.Pixel[I,Z] = 0 then Begin
          TempImage.SetPixel(pgl_black,I,Z);
        End Else Begin
          TempImage.SetPixel(pgl_white,I,Z);
        End;
      End;
    End;

    TempImage.SaveToFile(pglEXEPath + 'Graphics/GridTest.bmp');
    TempImage.Destroy();
  End;


Procedure RadarPointTemp.Place(X: Single; Y: Single; Color: TPGLColorI);
  Begin
    Self.Pos.X := X;
    Self.Pos.Y := Y;
    Self.Color := Color;
    Self.Opacity := 1;
  End;


Procedure RadarPointTemp.Handle();
  Begin
    Self.Opacity := Self.Opacity - 0.01;
    If Self.Opacity <= 0 Then Begin
      Self.Opacity := 0;
    End;
    Self.Color.Alpha := ClampIColor(trunc(255 * Self.Opacity));
  End;


Procedure PlanetTemp.CheckInBounds();
  Begin
    If Self.Bounds.X < (Buffer.Width / 2) - HalfWidth Then Begin
      Self.Bounds.Translate(PlayWidth,0);
    End Else If Self.Bounds.X > (Buffer.Width / 2) + HalfWidth Then Begin
      Self.Bounds.Translate(-PlayWidth,0);
    End;

    If Self.Bounds.Y < (Buffer.Height / 2) - HalfWidth Then Begin
      Self.Bounds.Translate(0,PlayWidth);
    End Else If Self.Bounds.Y > (Buffer.Height / 2) + HalfWidth Then Begin
      Self.Bounds.Translate(0,-PlayWidth);
    End;
  End;

Procedure CrackTemp.Place();
Var
I: Long;
Center: TPGLVector2;
  Begin

    Self.Pos := vec2(Rnd(0,Buffer.Width), Rnd(0,Buffer.Height));

    I := Random(Length(TextureCrack));
    Self.Texture := TextureCrack[i];
    Self.Bounds := RectF(Self.Pos, Self.Texture.Width, Self.Texture.Height);
    Self.Bounds.Stretch(Rnd(0.7,1.3), Rnd(0.7,1.3));
    Self.Rotation := Rnd(0,Pi * 2);

  End;


Procedure EnemyTemp.Move(X,Y:Single);
Var
MoveX,MoveY: Single;
I,R: Long;
PlacePoint: TPGLVector2;
  Begin

    Self.Pos.Translate(X,Y);

    MoveX := Self.Speed * Cos(Self.Angle);
    MoveY := Self.Speed * Sin(Self.Angle);

    MoveX := MoveX * Self.Pos.Z;
    MoveY := MoveY * Self.Pos.Z;

    Self.Pos.Translate(MoveX,MoveY);

    If Self.Pos.X < (Buffer.Width / 2) - HalfWidth Then Begin
      Self.Pos.Translate(PlayWidth,0);
    End Else If Self.Pos.X > (Buffer.Width / 2) + HalfWidth Then Begin
      Self.Pos.Translate(-PlayWidth,0);
    End;

    If Self.Pos.Y < (Buffer.Height / 2) - HalfWidth Then Begin
      Self.Pos.Translate(0,PlayWidth);
    End Else If Self.Pos.Y > (Buffer.Height / 2) + HalfWidth Then Begin
      Self.Pos.Translate(0,-PlayWidth);
    End;

    Self.Bounds.SetCenter(Self.Pos.X, Self.Pos.Y);
    Self.RadarPoint.Pos := Vec2(Self.Pos);
    Self.RadarPoint.Handle();
    Self.RocketSpawn.Pos := Self.Pos;
    Self.RocketSpawn.Handle();
  End;


Procedure EnemyTemp.Hurt(Dam: Single);
Var
I,R: Long;
X,Y: Single;
Angle: Single;
  Begin
    Self.Armor := Self.Armor - Dam;
    Self.WasHit := 5;

    If Self.Armor <= 0 Then Begin


      I := FindNewExplosionSpawn();
      ExplosionSpawn[i].Place(Self.Pos,Clock.Interval, 30, 3);

      I := FindNewFlash();
      Flash[i].place(Self.Pos, 400, pgl_yellow);

      For R := 0 to Random(10) + 5 Do Begin
        I := FindNewDebris();
        Debris[i].Place(Vec3(Self.Pos.X, Self.Pos.Y, Self.Pos.Z + 0.001));
        Debris[i].Opacity := Rnd(0.5,1);
      End;


      If EnemiesLeft > 0 Then Begin
        Dec(EnemiesLeft);
        Self.Pos := Vec3( (Buffer.Width / 2) + Rnd(-HalfWidth,HalfWidth),
                              (Buffer.Height / 2) + Rnd(-HalfWidth,HalfWidth),
                              0.001);

        Self.Bounds := RectF(Vec2(Self.Pos), TextureEnemy.Width, TextureEnemy.Height);
        Self.Bounds.Stretch(Self.Pos.Z, Self.Pos.Z);
        Self.Angle := Rnd(0,Pi * 2);
        Self.Speed := Rnd(5,15);
        Self.Armor := 10;
        Self.RocketTimer := 1;
        Self.Grid := @EnemyHitGrid;
        Self.RadarPoint.Used := true;
        Self.RadarPoint.Pos := Vec2(Self.Pos);
        Self.RadarPoint.Color := pgl_green;
        Self.RadarPoint.Opacity := 0;
        Self.EnemyType := 1;
        Self.RocketSpawn.SetAttributes(0,1,1,@Self);
        Self.RocketSpawn.Pos := Self.Pos;
        Self.State := 'Change Depth';
        Self.ToZ := Rnd(0.01,1);
      End;

    End;

  End;


Procedure EnemyTemp.CheckState();
Var
CanChoose: Boolean;
I,A: Long;
X,Y: Single;
  Begin

    // Handle rocket timer
    Self.RocketTimer := Self.RocketTimer - Clock.CycleTime;
    If Self.RocketTimer <= 0 Then Begin
      Self.RocketTimer := 5;

      A := Random(15);
      If A = 0 Then Begin
        Self.RocketSpawn.SetActive();
      End;

    End;


    // Handle timer and ability to choose state
    CanChoose := False;

    If Self.State = '' Then Begin
      Self.StateTimer := Self.StateTimer - Clock.CycleTime;
      If Self.StateTimer <= 0 Then Begin
        Self.StateTimer := 0;
        CanChoose := True;
      End;
    End;


    If CanChoose = True Then Begin

      A := Random(3);

      If A = 0 Then Begin
        Self.State := 'Turning';
        Self.ToAngle := Self.Angle + Rnd(-Pi,Pi);
      End Else If A = 1 Then Begin
        Self.State := 'Change Speed';
        Self.ToSpeed := Rnd(5,15);
      End Else If A = 2 Then Begin
        Self.State := 'Change Depth';
        Self.ToZ := Rnd(0.01,1);
      End;
    End;


    // Handle States
    // Turning
    If Self.State = 'Turning' Then Begin

      If Self.ToAngle < Self.Angle Then Begin
        Self.Angle := Self.Angle - 0.01;
          If Self.Angle <= Self.ToAngle Then Begin
            Self.Angle := Self.ToAngle;
            Self.State := '';
            Self.StateTimer := 3;
          End;

      End Else Begin
        Self.Angle := Self.Angle + 0.01;
          If Self.Angle >= Self.ToAngle Then Begin
            Self.Angle := Self.toAngle;
            Self.State := '';
            Self.StateTimer := 3;
          End;

      End;


    // Changing Speed
    End Else If Self.State = 'Change Speed' Then Begin

      If Self.ToSpeed > Self.Speed Then Begin
        Self.Speed := Self.Speed * 1.02;

        If Self.Speed >= Self.ToSpeed Then Begin
          Self.Speed := Self.ToSpeed;
          Self.State := '';
          Self.StateTimer := 3;
        End;

      End Else Begin
        Self.Speed := Self.Speed * 0.98;

        If Self.Speed <= Self.ToSpeed Then Begin
          Self.Speed := Self.ToSpeed;
          Self.State := '';
          Self.StateTimer := 3;
        End;
      End;


    // Changing Depth
    End Else If Self.State = 'Change Depth' Then Begin

      If Self.ToZ > Self.Pos.Z Then Begin
        Self.Pos.Z := Self.Pos.Z + 0.001;
        If Self.Pos.Z >= Self.ToZ Then Begin
          Self.Pos.Z := Self.ToZ;
          Self.State := '';
          Self.StateTimer := 3;
        End;

      End Else Begin
        Self.Pos.Z := Self.Pos.Z - 0.001;
        If Self.Pos.Z <= Self.ToZ Then Begin
          Self.Pos.Z := Self.ToZ;
          Self.State := '';
          Self.StateTimer := 3;
        End;
      End;

      Self.Bounds.Width := TextureEnemy.Width * Self.Pos.Z;
      Self.Bounds.Height := Textureenemy.Height * Self.Pos.Z;
      Self.Bounds.Update(FROMCENTER);

    End;

  End;


Procedure ParticleTemp.Place(Position: TPGLVector3; Angle,Speed,Size: Single; Color: TPGLColorI);
Var
S: Single;
  Begin
    Self.Pos := Position;
    S := Speed * Position.Z;
    Self.Angle := Angle;
    Self.XVal := S * Cos(Self.Angle);
    Self.YVal := S * Sin(Self.Angle);
    Self.Color := Color;
    Self.Duration := Rnd(0.1,0.5);
    Self.Size := Size * Self.Pos.Z;
  End;


Procedure ParticleTemp.Move();
  Begin
    Self.Duration := Self.Duration - Clock.CycleTime;

    If Self.Duration <= 0 Then Begin
      Self.Used := False;
      Exit;
    End;

    Self.Pos.Translate(Self.XVal, Self.YVal);
  End;


Procedure FlashTemp.Place(Position: TPGLVector3; Size: Single; Color: TPGLColorI);
  Begin
    Self.Pos := Position;
    Self.Size := Size * Self.Pos.Z;
    Self.Color := Color;
    Self.Frames := 7;
  End;


Procedure FlashTemp.Handle;
  Begin
    Dec(Self.Frames);
    Self.Size := Self.Size * 1.1;
    Self.Color.Alpha := trunc(Self.Color.Alpha * 1);
    If Self.Frames = 0 Then Begin
      Self.Used := False;
    End;
  End;


Procedure FlashTemp.Move(X: Single; Y: Single);
  Begin

    Self.Pos.Translate(X * Self.Pos.Z, Y * Self.POs.Z, 0);

    If Self.Pos.X < (Buffer.Width / 2) - HalfWidth Then Begin
      Self.Pos.Translate(PlayWidth,0,0);
    end Else If Self.Pos.X > (Buffer.Width / 2) + HalfWidth Then Begin
      Self.Pos.Translate(-PlayWidth,0,0);
    End;

    If Self.Pos.Y < (Buffer.Height / 2) - HalfWidth Then Begin
      Self.Pos.Translate(0,PlayWidth,0);
    End Else If Self.Pos.Y > (buffer.Height / 2) + HalfWidth Then Begin
      Self.Pos.Translate(0,-PlayWidth,0);
    End;

  End;


Procedure ExpTemp.Place(Position: TPGLVector3);
Var
I: Long;
  Begin
    Self.Pos := Position;
    Self.Bounds := RectF(Vec2(Self.Pos), TextureExplosion[0].Width, TextureExplosion[0].Height);
    Self.Bounds.Stretch(Self.Pos.Z, Self.Pos.Z);
    Self.Stage := 0;
    Self.Count := 0;
    Self.StageDuration := Random(4) + 3;
    Self.Size := rnd(0.5,1);
    Self.Sound.AssignBuffer(ExplosionQuietBuffer);
    Self.Sound.SetPosition(Self.Pos.X, Self.Pos.Y);
    Self.Sound.SetRadius(50 * Self.Pos.Z);
    Self.Sound.SetGain(Self.Pos.Z);
    Self.Sound.SetFixedPitch(Rnd(0.9,1.1));
    Self.Sound.SetDynamic(True);
    Self.Sound.Play();
  End;


Procedure ExpTemp.Handle();
  Begin
    Inc(Self.Count);
    If Self.Count >= Self.StageDuration Then Begin
      Self.Count := 0;
      Self.Stage := Self.Stage + 1;
      If Self.Stage = 4 Then Begin
        Self.Used := False;
      End;
    End;
  End;


Procedure ExpSpawnTemp.Place(Position: TPGLVector3; Interval: Single; Count,InstanceCount: Integer);
  Begin
    Self.Pos := Position;
    Self.ExpCount := Count;
    Self.InstanceCount := InstanceCount;
    Self.Interval := Interval;
    Self.Duration := Self.Interval;
  End;


Procedure ExpSpawnTemp.Handle();
Var
I,R: Long;
X,Y: Single;
Angle: Single;
  Begin
    Self.Duration := Self.Duration - Clock.CycleTime;

    If Self.Duration <= 0 Then Begin

      While (Self.Duration < 0) and (Self.Used = True) Do Begin

        Self.Duration := Self.Duration + Self.Interval;
        Self.ExpCount := Self.ExpCount - 1;

        For R := 1 to Self.InstanceCount Do Begin
          I := FindNewExplosion();
          Angle := Rnd(0,Pi*2);
          X := Self.Pos.X + ((Rnd(0,75) * Self.Pos.Z) * Cos(Angle));
          Y := Self.Pos.Y + ((Rnd(0,75) * Self.Pos.Z) * Sin(Angle));
          Explosion[i].Place(Vec3(X,Y,Self.Pos.Z));

          If Self.ExpCount = 0 Then Begin
            Self.Used := False;
            Break;
          End;
        End;

      End;

    End;

  End;


Procedure DebrisTemp.Place(Position: TPGLVector3);
  Begin
    Self.Pos := Position;
    Self.Bounds := RectF(Vec2(Self.Pos), TextureDebris[0].Width, TextureDebris[0].Height);
    Self.Bounds.Stretch(Self.Pos.Z, Self.Pos.Z);
    Self.Angle := Rnd(0,Pi * 2);
    Self.Opacity := 1;
    Self.Speed := Rnd(3,10);
    Self.XVal := Self.Speed * Cos(Self.Angle);
    Self.YVal := Self.Speed * Sin(Self.Angle);
    Self.DebrisType := Random(Length(TextureDebris));
    Self.Level := 2;
    Self.RotationDirection := Random(2);
    If Self.RotationDirection = 0 Then Begin
      Self.RotationDirection := -1;
    End;
  End;

Procedure DebrisTemp.Move();
Var
I,R,A: Long;
NewAngle: Single;

  Begin
    Self.Pos.Translate(PXVal,PYVal,0);
    Self.Pos.Translate(Self.XVal * Self.Pos.Z, Self.YVal * Self.Pos.Z, 0);
    Self.Bounds.SetCenter(Self.Pos.X, Self.Pos.Y);
    Self.Angle := Self.Angle + (0.3 * Self.RotationDirection);

    Self.Opacity := Self.Opacity - 0.01;
    If Self.Opacity <= 0 Then Begin
      Self.Used := false;
    End;

    For R := 0 to 2 Do Begin
      I := FindNewParticle();
      Particle[i].Place(Self.Pos, ArcTan2(Self.YVal, Self.XVal) + Rnd(-(Pi/2), (Pi/2)), Rnd(1,3), Rnd(2,5), CC(Color3F(1,1,0.25)));
    End;

    A := Random(20);
    If A = 0 Then Begin
      I := FindNewExplosion();
      Explosion[i].Place(Self.Pos);
      Explosion[i].Pos.Z := Explosion[i].Pos.Z + Rnd(-0.01,0.01);
    End;

    A := Random(3);
    If A = 0 Then Begin
      I := FindNewFlash();
        Flash[i].Place(Self.Pos, 200, Color4I(255,200,100,150));
    End;
  End;

Procedure RocketTemp.Place(Position: TPGLVector3; Angle: Single; Speed: Single);
  Begin
    Self.Pos := Position;
    Self.Bounds := RectF(Vec2(Self.Pos.X, Self.Pos.Y), TextureRocket.Width * Self.Pos.Z, TextureRocket.Height * Self.Pos.Z);
    Self.Angle := ArcTan2((Buffer.Height / 2) - Self.Pos.Y, (Buffer.Width / 2) - Self.Pos.X);
    Self.Health := 5;
    Self.Angle := Angle;
    Self.Speed := Speed;
    Self.XVal := Self.Speed * Cos(Angle);
    Self.YVal := Self.Speed * Sin(Angle);
    Inc(RocketLock);
  End;


Procedure RocketTemp.Handle();
Var
I,R: Long;
Vector: TPGLVector2;
X,Y: Single;
Angle: Single;
  Begin

    If Self.FromPlayer Then Begin
      Self.HandleFromPlayer();
      Exit;
    End;

    Self.Pos.Z := Self.Pos.Z * 1.005;
    Self.Xval := Self.XVal * 0.98;
    Self.YVal := Self.YVal * 0.98;
    Self.Pos.Translate((Self.XVal * Self.Pos.Z), (Self.XVal * Self.Pos.Z), 0);

    If Self.Pos.X < (Buffer.Width / 2) - HalfWidth Then Begin
      Self.Pos.X := Self.Pos.X + PlayWidth;
    End Else If Self.Pos.X > (Buffer.Width / 2) + HalfWidth Then Begin
      Self.Pos.X := Self.POs.X - PlayWidth;
    End;

    If Self.Pos.Y < (Buffer.Height / 2) - HalfWidth Then Begin
      Self.Pos.Y := Self.Pos.Y + PlayWidth;
    End Else If Self.Pos.Y > (Buffer.Height / 2) + HalfWidth Then BEgin
      Self.Pos.Y := Self.Pos.Y - PlayWidth;
    End;


    Self.Bounds.Stretch(1.005, 1.005);
    Self.Bounds.SetCenter(Self.Pos.X, Self.Pos.Y);


    If Self.Pos.Z > 10 Then Begin
      Self.Used := False;
      Dec(RocketLock);
      Armor := Armor - 5;

      I := FindNewExplosionSpawn();
      ExplosionSpawn[i].Place(Vec3((Buffer.Width / 2)-1, (Buffer.Height / 2)-1, 10), Clock.Interval, 10, 2);

      Instability := Instability + 10;

      For R := 0 to 2 Do Begin
        SetLength(Cracks,Length(Cracks) + 1);
        I := High(Cracks);
        Cracks[i].Place();
      End;

    End;
  End;


Procedure RocketTemp.HandleFromPlayer();
Var
ToAngle: Single;
  Begin
    Self.Pos.Z := Self.Pos.Z * (1.01 * Sign(Enemy[Self.Target].Pos.Z - Self.POs.Z));

    If Self.Pos.Z <= 0.001 Then Begin
      Self.Used := False;
    End;

    ToAngle := ArcTan2(Enemy[Self.Target].Pos.Y - Self.Pos.Y, Enemy[Self.Target].Pos.X - Self.Pos.X);
    Self.Angle := ToAngle;
    Self.XVal := Self.Speed * Cos(ToAngle);
    Self.YVal := Self.Speed * Sin(ToAngle);

    Self.Pos.Translate((Self.XVal * Self.Pos.Z), (Self.XVal * Self.Pos.Z), 0);

    If Self.Pos.X < (Buffer.Width / 2) - HalfWidth Then Begin
      Self.Pos.X := Self.Pos.X + PlayWidth;
    End Else If Self.Pos.X > (Buffer.Width / 2) + HalfWidth Then Begin
      Self.Pos.X := Self.POs.X - PlayWidth;
    End;

    If Self.Pos.Y < (Buffer.Height / 2) - HalfWidth Then Begin
      Self.Pos.Y := Self.Pos.Y + PlayWidth;
    End Else If Self.Pos.Y > (Buffer.Height / 2) + HalfWidth Then BEgin
      Self.Pos.Y := Self.Pos.Y - PlayWidth;
    End;

    Self.Bounds := RectFWH(0,0,TextureRocket.Width * Self.Pos.Z, TextureRocket.Height * Self.Pos.Z);
    Self.Bounds.SetCenter(Self.Pos.X, Self.Pos.Y);

  End;


Procedure RocketTemp.Hurt(Dam: Single);
Var
I: Long;

  Begin
    Self.Health := Self.Health - Dam;
    If Self.Health <= 0 Then Begin
      Self.Used := False;
      Dec(RocketLock);

      I := FindNewFlash();
      Flash[i].Place(Self.Pos, 400, pgl_yellow);
      Flash[i].Pos.Z := Self.Pos.Z + 0.01;

      I := FindNewExplosionSpawn();
      ExplosionSpawn[i].Place(Self.Pos,Clock.Interval,30,3);

    End;
  End;


Procedure RocketSpawnTemp.SetAttributes(Interval: Single; Count: Integer; ReleaseCount: Integer; Parent: Pointer);
  Begin
    Self.Interval := Interval;
    Self.Count := Count;
    Self.ReleaseCount := ReleaseCount;
    Self.Parent := Parent;
  End;

Procedure RocketSpawnTemp.SetActive();
  Begin
    If Self.Active = False Then Begin
      Self.Active := True;
      Self.Duration := Self.Interval;
      Self.Remaining := Self.Count;
    End;
  End;

Procedure RocketSpawnTemp.Stop();
  Begin
    Self.Active := False;
  End;

Procedure RocketSpawnTemp.Handle();
Var
I,R,T: Long;
  Begin

    // Stop spawning if parent is dead or not assigned
    If Self.Parent = nil Then Begin
      Self.Active := False;
      Exit;
    End;

    If EnemyTemp(Self.Parent^).Armor <= 0 Then Begin
      Self.Active := False;
      Exit;
    End;

    If Self.Active = False Then Exit;

    Self.Duration := Self.Duration - Clock.CycleTime;

    If Self.Duration <= 0 Then Begin
      Self.Duration := Self.Duration + Self.Interval;

        For T := 0 to Self.ReleaseCount - 1 Do Begin
          // Exit loop if no rockets remaining
          If (Self.Remaining <= 0) Then Begin
            Self.Stop();
            Break;
          End;

          I := FindNewRocket();
          Rocket[i].Place(Self.Pos, Rnd(0,Pi*2), 10);
          Dec(Self.Remaining);

        If Self.Active = False Then Break;
      End;


    End;


  End;


Class Operator GeoTemp.Initialize(Out Dest: GeoTemp);
  Begin
    SetLength(Dest.Point,1);
    Dest.Point[0] := Vec2(0,0);
    SetLength(Dest.Color,1);
    Dest.Color[0] := Color3F(1,0,1);
  End;


Procedure GeoTemp.AddPoint(X: Single; Y: Single);
  Begin
    SetLength(Self.Point,Length(Self.Point) + 1);
    Self.Point[High(Self.Point)] := Vec2(X,Y);

    SetLength(Self.Color, Length(Self.Point));
    Self.Color[High(Self.Color)] := color3f(1,0,0);
  End;

Procedure GeoTemp.AdjustCenter();
Var
I: Long;
LowX,HighX,LowY,HighY: Single;
  Begin

    LowX := 0;
    HighX := 0;
    LowY := 0;
    HighY := 0;

    For I := 1 to High(Self.Point) Do Begin
      If I = 1 Then Begin
        LowX := Self.Point[i].X;
        HighX := Self.Point[i].X;
        LowY := Self.Point[i].Y;
        HighY := Self.Point[i].Y;
      End Else Begin

        If Self.Point[i].X < LowX Then LowX := Self.Point[i].X;
        If Self.Point[i].X > HighX Then HighX := Self.Point[i].X;
        If Self.Point[i].Y < LowY Then LowY := Self.POint[i].Y;
        If Self.Point[i].Y > HighY Then HighY := Self.Point[i].Y;

      End;
    End;

    Self.Point[0].X := LowX + ((LowX + HighX) / 2);
    Self.Point[0].Y := LowY + ((LowY + HighY) / 2);
  End;


Procedure GeoTemp.SortPoints();
Var
I,Z: Long;
Angle1,Angle2: Single;
TempPoint: TPGLVector2;
TempColor: TPGLColorF;
  Begin

    For I := 1 to High(Self.Point) - 1 Do Begin
      For Z := I + 1 to High(Self.POint) Do Begin
        Angle1 := ArcTan2(Self.Point[I].Y - Self.Point[0].Y, Self.Point[I].X - Self.Point[0].X);
        Angle2 := ArcTan2(Self.Point[Z].Y - Self.Point[0].Y, Self.Point[Z].X - Self.Point[0].X);
        FixRadian(Angle1);
        FixRadian(Angle2);

        If Angle1 >Angle2 Then Begin
          TempPoint := Self.Point[i];
          TempColor := Self.Color[i];

          Self.Point[i] := Self.Point[z];
          Self.Point[z] := TempPoint;

          Self.Color[i] := Self.Color[z];
          Self.Color[z] := TempColor;
        End;

      End;
    End;

  End;

Procedure GeoTemp.SetCenter(Center: TPGLVector2);
Var
XDist,YDist: Single;
I: Long;
  Begin
    XDist := Center.X - Self.Point[0].X;
    YDist := Center.Y - Self.Point[0].Y;
    Self.Point[0] := Center;

    For I := 1 to High(Self.Point) Do Begin
      Self.Point[i].Translate(XDist,YDist);
    End;
  End;

Procedure GeoTemp.SetColors(Color: TPGLColorF);
Var
I: Long;
  Begin
    For I := 0 to High(Self.Color) Do Begin
      Self.Color[i] := color;
    End;
  End;


Procedure DrawCollection.AddDraw(Var Texture: TPGLTexture; Pos: TPGLVector3; Bounds: TPGLRectF; Colors,Overlay: TPGLColorI; Angle,Opacity: Single; GeoMetry: Pointer = nil);
Var
I: Long;
  Begin

    If Self.DrawCount >= 2000 Then Exit;

    Inc(Self.DrawCount);
    I := Self.DrawCount - 1;

    Self.Draws[i].Texture := Texture;
    Self.Draws[i].Pos := Pos;
    Self.Draws[i].Bounds := Bounds;
    Self.Draws[i].Colors := Colors;
    Self.Draws[i].Overlay := Overlay;
    Self.Draws[i].Angle := Angle;
    Self.Draws[i].Opacity := Opacity;
    Self.Draws[i].ShadowGeometry := Geometry;
  End;


Procedure DrawCollection.Draw();
Var
I,R: Long;
DrawColor: TPGLColorF;
SVal: Single;
SAngle: Single;
TempGeo: GeoTemp;

  Begin
    If Self.DrawCount = 0 Then Exit;

    Self.Sort();

    For I := 0 to Self.DrawCount - 1 Do Begin

      Sprite.ResetSkew();

      If BrightVal <> 0 Then Begin

        // Draw Shadow Geometry
        If Self.Draws[i].ShadowGeometry <> nil Then Begin
          SetLength(TempGeo.Point, Length(Self.Draws[i].ShadowGeometry.Point));
          SetLength(TempGeo.Color, Length(TempGeo.Point));
          For R := 0 to High(Self.Draws[i].ShadowGeometry.Point) Do Begin
            TempGeo.Point[r] := Self.Draws[i].ShadowGeometry.Point[r];
            TempGeo.Color[r] := Self.Draws[i].ShadowGeometry.Color[r];
          End;

          TempGeo.SetCenter(Vec2(Self.Draws[i].Pos.X, Self.Draws[i].Pos.Y));
          SVal := Sqrt( IntPower(Self.Draws[i].Pos.X - TheSun.X, 2) + IntPower(Self.Draws[i].Pos.Y - TheSun.Y, 2));
          SVal := 500 / Sval;
          StretchGeometry(TempGeo.Point,TempGeo.Point[0],Self.Draws[i].Pos.Z * (1*(Sval)));
          RotatePoints(TempGeo.Point, TempGeo.Point[0], Self.Draws[i].Angle);
          Buffer.DrawGeometry(TempGeo.Point, TempGeo.Color);
        End;

        Sprite.SetTexture(Self.Draws[i].Texture);
        SVal := 1 + (BrightVal * 0.2);
        Sprite.SetSize(Self.Draws[i].Bounds.Width * SVal, Self.Draws[i].Bounds.Height * SVal);
        Sprite.SetCenter(Vec2(Self.Draws[i].Pos));
        Sprite.SetColors(pgl_black);
        Sprite.SetOverlay(pgl_empty);
        Sprite.SetOpacity(BrightVal * 0.5);
        Sprite.SetAngle(Self.Draws[i].Angle);
        Sprite.SetOrigin(Vec2(Self.Draws[i].Pos));
        Buffer.DrawSprite(Sprite);
      End;


      Sprite.SetTexture(Self.Draws[i].Texture);
      Sprite.SetSize(Self.Draws[i].Bounds.Width, Self.Draws[i].Bounds.Height);
      Sprite.SetCenter(Vec2(Self.Draws[i].Pos.X, Self.Draws[i].Pos.Y));
      DrawColor := CC(Self.Draws[i].Colors);
      DrawColor.Red := DrawColor.Red * (1 - BrightVal);
      DrawColor.Green := DrawColor.Green * (1 - BrightVal);
      DrawColor.Blue := DrawColor.Blue * (1 - BrightVal);
      Sprite.SetColors(CC(DrawColor));
      Sprite.SetOverlay(Self.Draws[i].Overlay);
      Sprite.SetAngle(Self.Draws[i].Angle);
      Sprite.SetOpacity(Self.Draws[i].Opacity);
      Sprite.SetOrigin(Vec2(Self.Draws[i].Pos));
      Buffer.DrawSprite(Sprite);
    End;

    Self.DrawCount := 0;

    Sprite.SetAngle(0);
    Sprite.SetOpacity(1);
    Sprite.SetColors(pgl_white);
    Sprite.SetOverlay(pgl_empty);

  End;


Procedure DrawCollection.Sort();
Var
Temp: DrawTemp;
I,Z: Long;
  Begin

    If Self.DrawCount <= 1 Then Exit;

    For I := 0 to Self.DrawCount - 2 Do Begin
      For Z := I + 1 to Self.DrawCount - 1 Do Begin
        If Self.Draws[z].Pos.Z < Self.Draws[i].Pos.Z Then Begin
          Temp := Self.Draws[i];
          Self.Draws[i] := Self.Draws[z];
          Self.Draws[z] := Temp;
        End;
      End;
    end;

  End;

Procedure HeatLasers();
  Begin
    LaserLeftHeat := LaserLeftHeat - 1;
    LaserRightHeat := LaserRightHeat - 1;
    If (LaserLeftHeat <= 0) or (LaserRightHeat <= 0) Then Begin
      OverHeated := True;
      LaserLeftHeat := 0;
      LaserRightHeat := 0;
      ShootVar := 0;
      Inc(ShootStage);
      Shooting := False;
    End;
  End;


Procedure GetTarget();
Var
I: Long;
CurZ: Single;
TargetList: Array of Integer;
  Begin

    CurTarget := -1;

    // Look for enemies under the mouse
    For I := 0 to High(Enemy) Do Begin
      If Enemy[i].Armor <= 0 Then Continue;

      If CheckPointInRect(CrossHair.Pos, Enemy[i].Bounds) Then Begin
        SetLength(TargetList,Length(TargetList) + 1);
        TargetList[High(TargetList)] := I;
      End;

    End;

    // Exit if there are no targets found
    If Length(TargetList) = 0 Then Exit;

    // Default to first in list to start
    CurTarget := TargetList[0];

    // If the list is longer than 1, get the nearest target
    If Length(TargetList) > 1 Then Begin

      For I := 1 to High(TargetList) Do Begin

        If Enemy[TargetList[i]].Pos.Z  > Enemy[CurTarget].Pos.Z Then Begin
          CurTarget := TargetList[i];
        End;
      End;

    End;


  End;


Procedure GetBrightVal();
Var
Dist: Single;
  Begin
    BrightVal := 0;
    Dist := Sqrt( IntPower((Buffer.Width / 2) - TheSun.X, 2) + IntPower(((Buffer.Height / 2) - 75) - TheSun.Y, 2));
    If Dist <= 500 Then Begin
      BrightVal := 1 - (Dist / 500);
      BrightVal := BrightVal * 0.5;
    End;

    Buffer.SetClearColor(Color3f(BrightVal, BrightVal, BrightVal));

  End;

Function BD(Color: TPGLColorI): TPGLColorI;
  Begin
    Result := Color.ToMultiply(1-BrightVal);
  End;


Function BD(Color: TPGLColorF): TPGLColorF;
  Begin
    Result := Color.ToMultiply(1-BrightVal);
  End;

Procedure CoolLasers();
  Begin
    If LaserLeftHeat < 100 Then Begin

      If (Shooting = False) Then Begin
        LaserLeftHeat := LaserLeftHeat + 0.2;
        LaserRightHeat := LaserRightHeat + 0.2;
      End;

      If OverHeated = True Then Begin

        Inc(HeatCount);
        If HeatCount = 5 Then Begin
          HeatVisible := Not HeatVisible;
          HeatCount := 0;
        End;

        If LaserLeftHeat >= 50 Then Begin
          OverHeated := False;
          HeatVisible := True;
          HeatCount := 0;
        End;
      End;

      If (LaserLeftHeat >= 100) or (LaserRightHeat >= 100) Then Begin
        LaserLeftHeat := 100;
        LaserRightHeat := 100;
      End;

    End;
  End;

Procedure DriftCrossHair();
Var
Angle: Single;
X,Y: Single;
  Begin
    Angle := Rnd(0,Pi*2);
    PXVal := PXVal + (Instability * Cos(Angle));
    PYVal := PYVal + (Instability * Sin(Angle));
  End;


Procedure ToggleRocketLock();
  Begin

    If RocketLock = 0 Then Begin
      DisplayRocketLock := False;
    End Else Begin
      DisplayRocketLock := Not DisplayRocketLock;
      If DisplayRocketLock = True Then Begin
        AlarmSource.Play();
      End;
    End;

  End;


Procedure ToggleHUDFlash();
  Begin
    HUDFlash := Not HUDFlash;
  End;

end.
