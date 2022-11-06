unit GLDrawMain;

{-----------------------------------------------------------------------------------------}
{//////////////////////////////////////////////////////////////////////////////////////////
TO-DO:
  - Eliminate automatic generation of center point for DrawGeometry. User should be
    responsible for providing all vertices.

//////////////////////////////////////////////////////////////////////////////////////////}
{-----------------------------------------------------------------------------------------}


{-----------------------------------------------------------------------------------------}
{//////////////////////////////////////////////////////////////////////////////////////////

Naming Conventions
- Classes, Records, Types
  - prefix with 'TPGL'
  - pointers to types prefix with 'PPGL'
  - fields prefix with "F"
  - properties will share the name of the field minus the "F" prefix
  - Helper classes will be suffixed with "Helper"

- Pointers
  -Prefix with 'P'

- functions, procedures
  - prefix with "pgl"
  - if the function returns a PGL type, name it the same as the type minus "TPGL"
    - example: RectI returns TPGLRectI
  - prefix parameters with "A"

- constats, enumerations
  - use screaming snake case
  - prefix with "PGL_"
    example: PGL_FULLSCREEN, PGL_WHITE
//////////////////////////////////////////////////////////////////////////////////////////}
{-----------------------------------------------------------------------------------------}


{$POINTERMATH ON}
{$WARN EXPLICIT_STRING_CAST_LOSS OFF}

interface

uses
  glDrawContext, dglOpenGL, Windows,Classes, SysUtils, System.StrUtils, System.AnsiStrings, Math, Types, IOUtils,
  Neslib.Stb.Image, Neslib.Stb.ImageWrite,
  uFreeType;

  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////Enums and flags/////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  type TPGLWindowFlag =
    (pglFullScreen, pglTitleBar, pglSizable, pglDebug, pglScreenCenter);

  type TPGLWindowFlags = set of TPGLWindowFlag;

  type pglFrameResizeFunc = procedure();

  type TPGLController = glDrawContext.TPGLController;
  type TPGLMouse = glDrawContext.TPGLMouse;
  type TPGLKeyboard = glDrawContext.TPGLKeyboard;

  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////Buffer Objects//////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  {----------------------------------------------------------------------------}
  {

                                                                               }
  {----------------------------------------------------------------------------}

  type TPGLArrayIndirectBuffer = record
    Count,InstanceCount,First,BaseInstance: GLUInt;
  end;


  type TPGLElementsIndirectBuffer = record
    Count,InstanceCount,FirstIndex,BaseVertex,BaseInstance: GLUInt;
  end;


  type TPGLVBO = record
    Private
      InUse: Boolean;
      Buffer: GLUInt;
      SubDataOffSet: GLInt;
      SubDataSize: GLInt;
      procedure SubData(Binding: glEnum; Offset: GLInt; Size: GLInt; Source: Pointer);
  end;


  type TPGLSSBO = record
    Private
      InUse: Boolean;
      Buffer: GLUInt;
      SubDataOffSet: GLInt;
      SubDataSize: GLInt;
      procedure SubData(Binding: glEnum; Offset: GLInt; Size: GLInt; Source: Pointer);
  end;


  type TPGLBufferCollection = record
    Public
      VAO: GLUInt;
      EBO: GLUInt;
      VBO: Array [0..39] of TPGLVBO;
      SSBO: Array [0..39] of TPGLSSBO;
      CurrentVBO: ^TPGLVBO;
      CurrentSSBO: ^TPGLSSBO;
      VBOInc: GLInt;
      SSBOInc: GLInt;

      Const BufferSize:GLUInt = 512000;

      class operator Initialize (Out Dest: TPGLBufferCollection); register;
      procedure Bind(); register;
      procedure InvalidateBuffers(); register;
      procedure BindVBO(N: GLUInt); register;
      procedure BindSSBO(N: GLUInt); register;
      function GetNextVBO(): GLUInt; register;
      function GetNextSSBO(): GLUInt; register;
  end;

  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////Vectors and Matrices////////////////////////////
  //////////////////////////////////////////////////////////////////////////////


  type TPGLMatrix4 = record
    M: Array [0..15] of GLFloat;
  end;


  type TPGLMatrix3 = record
    M: Array [0..8] of GLFloat;
    procedure Fill(Values: Array of GLFloat); register;
    function Val(X,Y: GLUint): GLFloat; register;
  end;


  type TPGLMatrix2 = record
    M: Array [0..1] of Array [0..1] of GLFloat;

    procedure MakeRotation(Angle: GLFloat); register;
    procedure MakeTranslation(X,Y: GLFloat); register;
    procedure MakeScale(sX,sY: GLFloat); register;
    procedure Rotate(Angle: GLFloat); register;
    procedure Translate(X,Y: GLFloat); register;
    procedure Scale(sX,sY: GLFloat); register;
  end;


  type TPGLIndices = record
    Index: Array [0..5] of GLUInt;
  end;


	type TPGLRectI = record
    Left,Right,Top,Bottom,X,Y,Width,Height: GLInt;

    procedure SetLeft(Value: GLInt); register;
    procedure SetTop(Value: GLInt); register;
    procedure SetRight(Value: GLInt); register;
    procedure SetBottom(Value: GLInt); register;
    procedure SetTopLeft(L,T: GLInt); register;
    procedure SetCenter(X,Y: GLInt); register;
    procedure Update(From: Integer); register;
    procedure Translate(X,Y: Integer); register;
    procedure Resize(Width,Height: Integer); register;
    procedure Grow(Width,Height: Integer); register;
    procedure Stretch(PercentX,PercentY: Double); register;
  end;


  type TPGLRectF = record
    Left,Right,Top,Bottom,X,Y,Width,Height: GLFloat;

    procedure SetLeft(Value: GLFloat); register;
    procedure SetTop(Value: GLFloat); register;
    procedure SetRight(Value: GLFloat); register;
    procedure SetBottom(Value: GLFloat); register;
    procedure SetTopLeft(L,T: GLFloat); register;
    procedure SetCenter(X,Y: GLFloat); register;
    procedure Update(From: Integer); register;
    procedure Translate(X,Y: Double); register;
    procedure Resize(Width,Height: Double); register;
    procedure Grow(Width,Height: Double); register;
    procedure Stretch(PercentX,PercentY: Double); register;
    procedure Truncate(); register;
    procedure ResizeByAngle(Angle: GLFloat); register;
    function ToRectFTrunc(): TPGLRectF; register;
  end;


  type TPGLVector2 = record
    X,Y: GLFloat;

    procedure MatrixMultuply(Mat: TPGLMatrix2); register;
    procedure Translate(X,Y: GLFloat); register;
    procedure Rotate(Angle: GLFloat); register;
    procedure Scale(sX,sY: GLFloat); register;
    procedure Normalize(Origin: TPGLVector2); register;
  end;


  type TPGLVector3 = record
    X,Y,Z: GLFloat;
    class operator Subtract(A: TPGLVector3; B: TPGLVector3): TPGLVector3;
    procedure Normalize(); register;
    procedure Cross(Vec: TPGLVector3); register;
    procedure MatrixMultiply(Mat: TPGLMatrix3); register;
    procedure Translate(X: Single = 0; Y: Single = 0; Z: Single = 0); register;
  end;


  type TPGLVector4 = record
    X,Y,Z,W: GLFloat;
  end;


  type TPGLVectorQuad = Array [0..3] of TPGLVector2;
  type TPGLVectorTriangle = Array [0..5] of TPGLVector2;


  type TPGLColorI = record
    Red,Green,Blue,Alpha: glUByte;
    function Value(): Double;
    function ToMultiply(Ratio: Single): TPGLColorI; register;
    procedure Adjust(Percent: Integer; AdjustAlpha: Boolean = False); register;
  end;


  type TPGLColorF = record
    Red,Green,Blue,Alpha: glClampF;
    function Value(): Double;
    function ToMultiply(Ratio: Single): TPGLColorF; register;
  end;


  type TColorFArray = Array of TPGLColorF;
  type TColorArray = Array of TPGLColorI;


  type TPGLRenderParams = record
    ColorValues: TPGLColorI;
    ColorOverlay: TPGLColorI;
    MaskColor: TPGLColorI;
    GreyScale: Boolean;
    MonoChrome: Boolean;
    Opacity: GLFloat;
    PixelSize: GLInt;
  end;


  type TPGLCharArray = Array of AnsiChar;


  {///////////// Shapes ///////////////////}
  type TPGLShape = class(TPersistent)
    Private
      Count: GLInt;
      Points: Array of TPGLVector2;
      Color: TColorFArray;
      Center: TPGLVector2;

    Public
      Property Position: TPGLVector2 read Center;
      Property PointColor: TColorFArray read Color;
  end;


  type TPGLPoint = class(TPersistent)
    Private
      pPos: TPGLVector2;
      pColor: TPGLColorF;
      pSize: GLFloat;

    Public
      constructor Create(P: TPGLVector2; size: GLFloat; color: TPGLColorF);
      procedure SetPosition(P: TPGLVector2); register;
      procedure Move(by: TPGLVector2); register;
      procedure SetColor(C: TPGLColorF); register;
      procedure SetSize(S: GLFloat); register;

      Property Position: TPGLVector2 read pPos write SetPosition;
      Property Color: TPGLColorF read pColor write SetColor;
      Property Size: GLFloat read pSize write SetSize;
  end;


  type TPGLCircleDescriptor = record
    Center: TPGLVector2;
    Width: GLFloat;
    BorderWidth: GLFloat;
    FillColor: TPGLColorF;
    BorderColor: TPGLColorF;
    Fade: TPGLVector4;
  end;


  type TPGLCircleBatch = record
    Count: GLInt;
    Data: PByte;
    Vector: Array [0..4000] of TPGLVectorQuad;
    class operator Initialize(Out Dest: TPGLCircleBatch);
  end;


  type TPGLRectangleBatch = record
    Count: GLInt;
    Vector: Array [0..40000] of TPGLVectorQuad;
    Center: Array [0..10000] of TPGLVector2;
    Dims: Array [0..10000] of TPGLVector2;
    BorderWidth: Array [0..10000] of GLFloat;
    FillColor: Array [0..10000] of TPGLColorF;
    BorderColor: Array [0..10000] of TPGLColorF;
    Curve: Array [0..10000] of GLFloat;
  end;


  type TPGLPointBatch = record
    Count: GLInt;
    Data: PByte;
    class operator Initialize(Out Dest: TPGLPointBatch);
  end;


  type TPGLPolygonBatch = record
    Count: GLInt;
    ShapeCount: GLInt;
    ElementCount: GLInt;
    Vector: Array [0..10000] of TPGLVector2;
    Color: Array [0..10000] of TPGLColorF;
    Size: Array [0..10000] of GLFloat;
  end;


  type TPGLLightBatch = record
    Count: GLInt;
    Vertices: Array [0..1000] of TPGLVectorQuad;
    TexCoords: Array [0..1000] of TPGLVectorQuad;
    Center: Array [0..1000] of TPGLVector2;
    Radius: Array [0..1000] of GLFloat;
    Radiance: Array [0..1000] of GLFloat;
    Color: Array [0..1000] of TPGLColorF;
  end;


  type TPGLLightPolygonDescriptor = record
    Center: TPGLVector2;
    Color: TPGLColorF;
    Radius: GLFloat;
    Radiance: GLFloat;
  end;


  type TPGLLightPolygonBatch = record
    Count: GLInt;
    Points: Array [0..1000] of TPGLVector2;
    Index: Array [0..1000] of GLUInt;
    Center: Array [0..50] of TPGLVector2;
    Color: Array [0..50] of  TPGLColorF;
    Radius: Array [0..50] of  GLFloat;
    Radiance: Array [0..50] of  GLFloat;
  end;


  type TPGLLineBatch = record
    Count: GLInt;
    Points: Array [0..1000] of TPGLVector2;
    Color: Array [0..1000] of TPGLColorF;
  end;


  type TPGLShapeDesc = record
    FillColor: TPGLColorF;
    BorderColor: TPGLColorF;
    Width,Height,BorderWidth,ShapeType: GLFloat;
    Pos: TPGLVector4; // X,Y = center, Z = Angle
  end;


  type TPGLShapeBatch = record
    Count: GLUInt;
    PointCount: GLUInt;
    Points: Array [0..10000] of TPGLVector2;
    Normal: Array [0..10000] of TPGLVector2;
    IndexBuffer: Array [0..10000] of GLUInt;
    ShapeBuffer: Array [0..1000] of TPGLArrayIndirectBuffer;
    Shape: Array [0..1000] of TPGLShapeDesc;
  end;


  type TPGLGeometryBatch = record
    Count: GLUint;
    Next: GLint;
    Data: PByte;
    DataSize: GLInt;
    Normals: PByte;
    NormalsSize: GLInt;
    Color: PByte;
    ColorSize: GLInt;
    IndirectBuffers: Array [0..1000] of TPGLArrayIndirectBuffer;
    class operator Initialize(Out Dest: TPGLGeometryBatch);
  end;


  type TPGLTextureBatch = record
    Count: GLInt;
    TextureSlot: Array [0..31] of GLInt;
    SlotsUsed: GLInt;
    Vertices: Array [0..1000] of  TPGLVectorQuad;
    TexCoords: Array [0..1000] of TPGLVectorQuad;
    Indices: Array [0..1000] of TPGLIndices;
    SlotUsing: Array [0..1000] of GLInt;
    MaskColor: Array [0..1000] of TPGLColorF;
    Opacity: Array [0..1000] of GLFloat;
    ColorVals: Array [0..1000] of TPGLColorF;
    Overlay: Array [0..1000] of TPGLColorF;
    GreyScale: Array [0..1000] of GLUint;

    procedure Clear(); register;
  end;

  type TPGLLightSource = class
    Public

      Active: Boolean;
      Position: TPGLVector2;
      Bounds: TPGLRectF;
      Width: GLFloat;
      Color: TPGLColorF;
      Radiance: GLFloat;
      Ver: TPGLVectorQuad;
      Cor: TPGLVectorQuad;

      constructor Create(); register;
      procedure SetActive(isActive: Boolean = True); register;
      procedure SetPosition(Pos: TPGLVector2); register;
      procedure SetColor(Color: TPGLColorF); Overload; register;
      procedure SetColor(Color: TPGLColorI); Overload; register;
      procedure SetRadiance(RadianceVal: GLFloat); register;
      procedure SetWidth(Val: GLFloat); register;
      procedure Place(Pos: TPGLVector2; WidthVal: GLFloat); register;
  end;


  type TPGLImageDescriptor = record
    Public
      Handle: Pointer;
      Width,Height: GLUInt;
  end;


  type TPGLImage = class(TPersistent)
    Private
      isValid: Boolean;
      pHandle: PByte;
      pDataSize: GLInt;
      DataEnd: PByte;
      pChannels: GLInt;
      Data: Array of TPGLColorI;
      RowPtr: Array of PByte;
      pWidth,pHeight: GLInt;

      procedure DefineData(); register;
      procedure Delete(); register;

    Public
      constructor Create(Width: GLUint = 1; Height: GLUint = 1); register;
      constructor CreateFromFile(FileName: String); register;
      constructor CreateFromMemory(Source: Pointer; Width,Height: NativeUInt; Size: NativeUInt); register;
      Destructor Destroy(); Override;
      procedure Clear(); register;
      procedure LoadFromFile(FileName: AnsiString); register;
      procedure LoadFromMemory(Source: Pointer; Width,Height: GLUInt); register;
      procedure CopyFromImage(Var Source: TPGLImage); Overload; register;
      procedure CopyFromImage(Var Source: TPGLImage; SourceRect, DestRect: TPGLRectI); Overload; register;
      procedure ReplaceColor(TargetColor,NewColor: TPGLColorI); register;
      procedure Darken(Percent: GLFloat); register;
      procedure Brighten(Percent: GLFloat); register;
      procedure AdjustAlpha(Alpha: GLFloat; IgnoreTransparent: Boolean = True); register;
      procedure ToGreyScale(); register;
      procedure ToNegative(); register;
      procedure Smooth(); register;
      procedure SaveToFile(FileName: String); register;
      procedure Resize(NewWidth, NewHeight: GLUint); register;
      function Pixel(X,Y: Integer): TPGLColorI; register;
      procedure SetPixel(Color: TPGLColorI; X,Y: Integer) register;
      procedure BlendPixel(Color: TPGLColorI; X,Y: GLInt; SourceFactor: GLFLoat); register;
      procedure Pixelate(PixelWidth: GLUint = 2); register;

      Property Width: GLint read pWidth;
      Property Height: GLint read pHeight;
      Property Handle: PByte read pHandle;
      Property Channels: GLInt read pChannels;
      Property DataSize: GLInt read pDataSize;
  end;


  type TPGLTexture = class
    Public
      Handle: GLUInt;
      Width,Height: GLUInt;
      BitDepth: GLInt;

      constructor Create(Width: GLUint = 0; Height: GLUint = 0); register;
      constructor CreateFromImage(Image: TPGLImage);
      constructor CreateFromFile(FileName: string);
      constructor CreateFromTexture(Texture: TPGLTexture);
      procedure Delete(); register;
      procedure SaveToFile(FileName: String);
      procedure Smooth(Area: TPGLRectF; IgnoreColor: TPGLColorI); register;
      procedure ReplaceColors(TargetColors: Array of TPGLColorI; NewColor: TPGLColorI; Tolerance: Double = 0); register;
      procedure CopyFromData(Data: Pointer; Width,Height: GLInt); register;
      procedure CopyFromTexture(Source: TPGLTexture; X,Y,Width,Height: GLUInt); register;
      procedure SetSize(Width,Height: GLUint; KeepImage: Boolean = False); register;
      function Pixel(X,Y: Integer): TPGLColorI; register;
      function SetPixel(Color: TPGLColorI; X,Y: Integer): TPGLColorI; register;
      procedure Pixelate(PixelWidth: GLUint = 2); register;
      procedure CopyToImage(Dest: TPGLImage; SourceRect, DestRect: TPGLRectI);
      procedure CopyToAddress(Dest: Pointer); register;
      procedure SetNearestFilter(); register;
      procedure SetLinearFilter(); register;

    Private
      procedure CheckDefaultReplace(); register;
  end;


  type TPGLSprite = class
    Private
      pTexture: TPGLTexture;
      pBounds: TPGLRectF;
      pTextureRect: TPGLRectI;
      pTextureSize: TPGLVector2;
      pMonoChrome: Boolean;
      pGreyScale: Boolean;
      pOpacity: GLFloat;
      pMaskColor: TPGLColorF;
      pAngle: GLFloat;
      pOrigin: TPGLVector2;
      pFlipped: GLBoolean;
      pMirrored: GLBoolean;
      pTopSkew: GLFloat;
      pBottomSkew: GLFloat;
      pLeftSkew: GLFloat;
      pRightSkew: GLFloat;
      pTopStretch: GLFloat;
      pBottomStretch: GLFloat;
      pLeftStretch: GLFloat;
      pRightStretch: GLFloat;
      ColorsArePointer: Boolean;
      pColorValues: TPGLColorF;
      pColorOverlay: TPGLColorF;
      // Pointers
      PColorValuesPointer: ^TPGLColorF;
      PColorOverlayPointer: ^TPGLColorF;

      Ver: TPGLVectorQuad;
      Cor: TPGLVectorQuad;
      Translation,Scale,Rotation: TPGLMatrix4;

      pRectSet: Array [1..100] of TPGLRectI;

    Private
      procedure Initialize(); register;
      procedure UpdateVertices(); register;
      function GetColorValues(): TPGLColorF; register;
      function GetRectSet(S: Integer): TPGLRectI; register;
      function GetCenter(): TPGLVector2; register;
      function GetTopLeft(): TPGLVector2; register;

    Public
      constructor Create(); Overload; register;
      constructor CreateFromTexture(Var Texture: TPGLTexture); Overload; register;
      procedure Delete(); register;
      procedure SetDefaults(); register;
      procedure SetTexture(Sprite: TPGLSprite); Overload; register;
      procedure SetTexture(Var Texture: TPGLTexture); Overload; register;
      procedure SetCenter(Center: TPGLVector2); register;
      procedure SetTopLeft(TopLeft: TPGLVector2); register;
      procedure Move(X,Y: Single); register;
      procedure Rotate(Val: GLFloat); register;
      procedure SetAngle(Val: GLFloat); register;
      procedure SetOrigin(Center: TPGLVector2); register;
      procedure SetFlipped(isFlipped: Boolean); register;
      procedure SetMirrored(isMirrored: Boolean); register;
      procedure SetSkew(Dimension: GLInt; Amount: GLFloat); register;
      procedure ResetSkew(); register;
      procedure SetStretch(Dimension: GLInt; Amount: GLFloat); register;
      procedure ResetStretch(); register;
      procedure SetMaskColor(Color: TPGLColorF); Overload; register;
      procedure SetMaskColor(Color: TPGLColorI); Overload; register;
      procedure SetOpacity(Val: GLFloat); register;
      procedure SetColors(Colors: TPGLColorI); Overload; register;
      procedure SetColors(Colors: pointer); Overload; register;
      procedure SetOverlay(Colors: TPGLColorI); register;
      procedure SetGreyScale(Val: Boolean = true); register;
      procedure ResetColorState(); register;
      procedure SetSize(Width,Height: Single); register;
      procedure ResetScale(); register;
      procedure SetTextureRect(TexRect: TPGLRectI); register;
      procedure SetRectSlot(Slot: GLInt; Rect: TPGLRectI); register;
      procedure UseRectSlot(Slot: GLInt); register;
      procedure SaveToFile(FileName: String); register;

      Property Texture: TPGLTexture read pTexture;
      Property ColorValues: TPGLColorF read GetColorValues;
      Property ColorOverlay: TPGLColorF read pColorOverlay;
      Property TextureSize: TPGLVector2 Read pTextureSize;
      Property TextureRect: TPGLRectI Read pTextureRect;
      Property Bounds: TPGLRectF read pBounds;
      Property X: GLFloat Read pBounds.X;
      Property Y: GLFloat Read pBounds.Y;
      Property Left: GLFloat Read pBounds.Left;
      Property Right: GLFloat read pBounds.Right;
      Property Top: GLFloat read pBounds.Top;
      Property Bottom: GLFloat read pBounds.Bottom;
      Property Width: GLFloat Read pBounds.Width;
      Property Height: GLFloat read pBounds.Height;
      Property Center: TPGLVector2 read GetCenter;
      Property TopLeft: TPGLVector2 read GetTopLeft;
      Property Angle: GLFloat read pAngle;
      Property Origin: TPGLVector2 read pOrigin;
      Property Flipped: GLBoolean read pFlipped;
      Property Mirrored: GLBoolean read pMirrored;
      Property Opacity: GLFloat read pOpacity;
      Property GreyScale: Boolean read pGreyScale;
      Property MonoCrome: Boolean read pMonoChrome;
      Property MaskColor: TPGLColorF read pMaskColor;
      Property RectSet[Index: Integer]: TPGLRectI read GetRectSet;

      function Pixel(X,Y: Integer): TPGLColorI; register;
  end;


  type TPGLPointCollection = record
    Private
      pCount: GLUInt;
      pWidth: GLUInt;
      pHeight: GLUInt;
      Data: Array of TPGLColorI;

    Public
      procedure BuildFrom(Texture: TPGLTexture; X: GLUInt = 0; Y: GLUInt = 0; Width: GLUInt = 0; Height: GLUInt = 0); Overload; register;
      procedure BuildFrom(Image: TPGLImage; X: GLUInt = 0; Y: GLUInt = 0; Width: GLUInt = 0; Height: GLUInt = 0); Overload; register;
      procedure BuildFrom(Sprite: TPGLSprite; X: GLUInt = 0; Y: GLUInt = 0; Width: GLUInt = 0; Height: GLUInt = 0); Overload; register;
      procedure BuildFrom(Data: Pointer; Width,Height: GLUInt); Overload; register;
      procedure ReplaceColor(OldColor,NewColor: TPGLColorI); register;

      function Point(X,Y: GLUInt): TPGLColorI; Overload; register;
      function Point(N: GLUInt): TPGLColorI; Overload; register;

      Property Width: GLUInt read pWidth;
      Property Height: GLUInt Read pHeight;
      Property Count: GLUInt Read pCount;
  end;


  type TPGLGlyphMetrics = record
    Private
      Width, Height: GLInt;
      SDFWidth, SDFHeight: GLInt;
      Bearing: GLInt;
      Advance: GLFloat;
      TailHeight: GLInt;
  end;


  type TPGLCharacter = record
    Private
      Position: TPGLVector2;
      SDFPosition: TPGLVector2;
      Size: TPGLVector2;
      Texture: GLUInt;
      OutlineTexture: GLUInt;
      Symbol: String;
      GlyphIndex: GLUInt;
      AsciiCode: GLUInt;
      Metrics: TPGLGlyphMetrics;
      OutlinePoints: TArray<TFTVector>;

      procedure GetOutlinePoints(); register;

    Public
      Property Width: GLInt Read Metrics.Width;
      Property Height: GLInt Read Metrics.Height;
      Property Bearing: GLInt Read Metrics.Bearing;
      Property Advance: GLFloat Read Metrics.Advance;
      Property TailHeight: GlInt Read Metrics.TailHeight;
  end;


  type TPGLAtlas = record
    Private
      Texture: GLUInt;
      Width, Height: GLUInt;
      OriginY: GLUint;
      TailMax: GLUint;
      TotalHeight: GLInt;
      FontSize: GLInt;
      Character: Array [0..128] of TPGLCharacter;
  end;


  type TPGLFont = class(TObject)
    Private
      Atlas: Array of TPGLAtlas;

      procedure BuildAtlas(A: GLInt); register;
      function ChooseAtlas(CharSize: GLUInt): Integer; register;

    Public
      FontName: String;
      FontSize: GLInt;
      constructor Create(FileName: String; Sizes: Array of Integer; Bold: Boolean = False); register;
  end;


  type TPGLText = class(TObject)
    Private
      UseFont: TPGLFont;
      UseText: String;
      UseWrapText: String;
      UseLineCount: GLInt;
      UseLineStart: Array of GLInt;
      UseColor: TPGLColorF;
      UseHasGradient: Boolean;
      UseGradientColorLeft: TPGLColorF;
      UseGradientColorRight: TPGLColorF;
      UseGradientOffset: GLFloat;
      UseBorderColor: TPGLColorF;
      UseBorderSize: GLInt;
      UseCharSize: GLInt;
      UseMultiLine: Boolean;
      UseMultiLineBounds: TPGLRectF;
      UseShadow: Boolean;
      UseSmooth: Boolean;
      UseTextBounds: TPGLRectF;
      UseBounds: TPGLRectF;
      UseAngle: GLFloat;
      CurrentAtlas: GLUint; // Assigned during FindBounds
      DrawPos: TPGLVector2; // The position that will be passesd to DrawTestString, either the topleft of the bounds or if centered the center - half width and half height

      procedure FindBounds(); register;
      function FindPosition(): TPGLVector2; register;
      function FindTopLeft(): TPGLVector2; register;
      function FindWidth(): integer; register;
      function FindHeight(): integer; register;

    Public
      constructor Create(Font: TPGLFont; Chars: string); register;
      procedure SetText(Chars: String); register;
      procedure SetColor(Color: TPGLColorI); register;
      procedure SetBorderColor(Color: TPGLColorI); register;
      procedure SetBorderSize(Size: GLInt); register;
      procedure SetCharSize(Size: GLInt); register;
      procedure SetCenter(Center: TPGLVector2); register;
      procedure SetTopLeft(TopLeft: TPGLVector2); register;
      procedure SetLeft(Left: GLFloat); register;
      procedure SetTop(Top: GLFloat); register;
      procedure SetRight(Right: GLFloat); register;
      procedure SetBottom(Bottom: GLFloat); register;
      procedure SetX(X: GLFloat); register;
      procedure SetY(Y: GLFloat); register;
      procedure SetMultiLine(Value: Boolean = True); register;
      procedure SetMultiLineBounds(Bounds: TPGLRectF); register;
      procedure SetWidth(Value: GLUInt); register;
      procedure SetShadow(Shadow: Boolean = True); register;
      procedure Rotate(Angle: GLFloat); register;
      procedure SetRotation(Angle: GLFloat); register;
      procedure SetSmooth(Smooth: Boolean = True); register;
      procedure SetGradientColors(LeftColor, RightColor: TPGLColorF); register;
      procedure SetUseGradientColors(UseGradient: Boolean = true); register;
      procedure SetGradientXOffSet(XOffSet: GLFLoat); register;
      procedure WrapText(WrapWidth: GLFloat); register;

      Property Text: String read UseText write SetText;
      Property Color: TPGLColorF Read UseColor;
      Property GradientColorSet: Boolean read UseHasGradient;
      Property GradientColorLeft: TPGLColorF read UseGradientColorLeft;
      Property GradientColorRight: TPGLColorF read UseGradientColorRight;
      Property GradientXOffSet: GLFloat read UseGradientOffset;
      Property BorderColor: TPGLColorF Read UseBorderColor;
      Property BorderSize: GLInt read UseBorderSize;
      Property CharSize: GLInt read UseCharSize;
      Property Center: TPGLVector2 Read FindPosition;
      Property Bounds: TPGLRectF Read UseBounds;
      Property TopLeft: TPGLVector2 Read FindTopLeft;
      Property Width: Integer Read FindWidth;
      Property Height: Integer Read FindHeight;
      Property MultiLine: Boolean Read UseMultiline;
      Property MultiLineBounds: TPGLRectF Read UseMultiLineBounds;
      Property Smooth: Boolean read UseSmooth;
      Property Angle: GLFloat Read UseAngle;
  end;


  type TPGLTextTag = record
    Bold: Boolean;
    Italic: Boolean;
    Color: TPGLColorF;
    CharStart: GLInt;
    CharEnd: GLInt;
  end;

  type TPGLTextTagArray = Array of TPGLTextTag;


  type TPGLTextFormat = record

    Position: TPGLVector2; // Top-Left
    Width,Height: GLInt; // Clipping edges. -1 means do not apply clipping
    CharSize: GLInt; // -1 means use the size of the smallest atlas
    Font: TPGLFont;
    AtlasIndex: GLInt; // Index of Font Atlas to use, -1 if none. Drawing function chooses if none
    Color: TPGLColorF;
    BorderColor: TPGLColorF;
    BorderSize: GLUint; // 0 = no border
    Shadow: Boolean; // Apply a shadow or not
    ShadowOffSet: TPGLVector2; // X and Y offset of shadow from text
    ShadowColor: TPGLColorF;
    Smooth: Boolean; // Do a smoothing pass or not
    Rotation: GLFloat; // Angle in Radians
    UseGradient: Boolean;
    GradientLeft: TPGLColorF;
    GradientRight: TPGLColorF;
    GradientXOffSet: GLFloat;

    procedure Reset(); register;
    procedure SetFormat(iPosition: TPGLVector2;
                        iWidth: GLInt;
                        iHeight: GLInt;
                        iFont: TPGLFont;
                        iAtlasIndex: GLInt;
                        iColor: TPGLColorF;
                        iBorderColor: TPGLColorF;
                        iBorderSize: GLUint;
                        iShadow: Boolean;
                        iShadowOffset: TPGLVector2;
                        iShadowColor: TPGLColorF;
                        iSmooth: Boolean;
                        iRotation: GLFloat;
                        iUseGradient: Boolean;
                        iGradientLeft: TPGLColorF;
                        iGradientRight: TPGLColorF;
                        iGradientXOffSet: GLFloat); register;
  end;


	type TPGLRenderTarget = class(TPersistent)
    Private
      ResizeFunc: pglFrameResizeFunc;
      pWidth,pHeight: GLUint;
      pDrawOffSet: TPGLVector2;
      pTextSmoothing: Boolean; // Text Smoothing Enabled
      pTextParams: TPGLTextFormat;
      pDrawShadows: Boolean;
      pShadowType: GLFloat;

  	Public
      FrameBuffer: GLUInt;
      Texture: GLUInt;
      Texture2D: GLUInt;
      LightMap: GLUInt;
      DepthBuffer: GLUint;
      RenderRect: TPGLRectF;
      ClipRect: TPGLRectF;
      ColorVals: TPGLColorF;
      ColorOverLay: TPGLColorF;
      GreyScale: Boolean;
      MonoChrome: Boolean;
      Negative: Boolean;
      Swizzle: Boolean;
      SwizzleVals: TPGLVector3;
      pPixelSize: GLFloat;
      pBrightness: GLFloat;
      pClearColor: TPGLColorF;
      pClearColorBuffers: Boolean;
      pClearDepthBuffer: Boolean;
      pGlobalLight: glFloat;
      Buffers: TPGLBufferCollection;
      Ver: TPGLVectorQuad;
      Cor: TPGLVectorQuad;
      Indices: Array [0..5] of GLUInt;
      Rotation: TPGLMatrix4;
      Scale: TPGLMatrix4;
      Translation: TPGLMatrix4;
      Points: TPGLPointBatch;
      Circles: TPGLCircleBatch;
      Polys: TPGLPolygonBatch;
      Rectangles: TPGLRectangleBatch;
      Lights: TPGLLightBatch;
      LightPolygons: TPGLLightPolygonBatch;
      TextureBatch: TPGLTextureBatch;
      LineBatch: TPGLShapeBatch;
      GeoMetryBatch: TPGLGeometryBatch;
      DrawState: AnsiString;
      ClearRect: TPGLRectF;

    Private
      procedure FillEBO(); register;
      procedure DrawTextString(Text: String; Font: TPGLFont; Size: GLInt; Bounds: TPGLRectF;
        BorderSize: GLUInt; Color,BorderColor: TPGLColorI; UseGradient: Boolean; GradientLeft: TPGLColorF;
        GradientRight: TPGLColorF; GradientXOffSet: glFloat; Angle: GLFloat = 0; Shadow: Boolean = False); register;

      procedure DrawTextCharacters(CharQuads,TexQuads: Array of TPGLVectorQuad; TextWidth,TextHeight: GLUInt); register;

    Public
      constructor Create(inWidth,inHeight: GLInt);
      procedure UpdateVertices(); register;
      procedure UpdateCorners(); register;
      procedure Display(); register;
      procedure Clear(); Overload;
      procedure Clear(Color: TPGLColorI); Overload;
      procedure Clear(Color: TPGLColorF); Overload;
      procedure SetClearColorBuffers(Enable: Boolean); register;
      procedure SetClearDepthBuffer(Enable: Boolean); register;
      procedure SetClearAllBuffers(Enable: Boolean); register;
      procedure SetColorValues(inVals: TPGLColorI); Overload;
      procedure SetColorValues(inVals: TPGLColorF); Overload;
      procedure SetColorOverlay(inVals: TPGLColorI); Overload;
      procedure SetColorOverlay(inVals: TPGLColorF); Overload;
      procedure SetRenderRect(inRect: TPGLRectI); Overload; register;
      procedure SetRenderRect(inRect: TPGLRectF); Overload; register;
      procedure SetClipRect(inRect: TPGLRectI); Overload; register;
      procedure SetClipRect(inRect: TPGLRectF); Overload; register;
      procedure SetOnResizeEvent(Event: pglFrameResizeFunc); register;
      procedure SetClearRect(ClearRect: TPGLRectF); register;
      procedure AttachShadowMap(); register;

      // Drawing
      procedure DrawLastBatch(); register;
      procedure DrawCircleBatch(); register;
      procedure DrawGeometryBatch(); register;
      procedure DrawPointBatch(); register;
      procedure DrawLineBatch(); register;
      procedure DrawLineBatch2(); register;
      procedure DrawPolygonBatch(); register;
      procedure DrawRectangleBatch(); register;
      procedure DrawLightBatch(); register;
      procedure DrawSpriteBatch(); register;

      procedure DrawCircle(CenterX, CenterY, inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: TPGLColorI); Overload; register;
      procedure DrawCircle(CenterX, CenterY, inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: TPGLColorF); Overload; register;
      procedure DrawCircle(Center: TPGLVector2; inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: TPGLColorI); Overload; register;
      procedure DrawCircle(Center: TPGLVector2; inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: TPGLColorF; FadeToOpacity: GLFloat = 1); Overload; register;
      procedure DrawEllipse(Center: TPGLVector2; XLength,YLength,Angle: GLFloat; Color: TPGLColorI); register;
      procedure DrawGeometry(Points: Array of TPGLVector2; Color: Array of TPGLColorF); register;
      procedure DrawRegularPolygon(NumVertices: GLInt; Center: TPGLVector2; Radius,Angle: GLFloat; Color: TPGLColorI); register;
      procedure DrawPoint(CenterX,CenterY,Size: GLFloat; inColor: TPGLColorI); Overload;
      procedure DrawPoint(CenterX,CenterY,Size: GLFloat; inColor: TPGLColorF); Overload;
      procedure DrawPoint(Center: TPGLVector2; Size: GLFloat; inColor: TPGLColorI); Overload;
      procedure DrawPoint(Center: TPGLVector2; Size: GLFloat; inColor: TPGLColorF); Overload;
      procedure DrawPoint(PointObject: TPGLPoint); Overload;
      procedure DrawRectangle(Center: TPGLVector2; inWidth,inHeight,inBorderWidth: GLFloat; inFillColor,inBorderColor: TPGLColorI; inCurve: GLFloat = 0); Overload; register;
      procedure DrawRectangle(Center: TPGLVector2; inWidth,inHeight,inBorderWidth: GLFloat; inFillColor,inBorderColor: TPGLColorF; inCurve: GLFloat = 0); Overload; register;
      procedure DrawRectangle(Bounds: TPGLRectF; inBorderWidth: GLFloat; inFillColor,inBorderColor: TPGLColorI; inCurve: GLFloat = 0); Overload; register;
      procedure DrawRectangle(Bounds: TPGLRectF; inBorderWidth: GLFloat; inFillColor,inBorderColor: TPGLColorF; inCurve: GLFloat = 0); Overload; register;
      procedure DrawLine(P1,P2: TPGLVector2; Width,BorderWidth: GLFloat; FillColor, BorderColor: TPGLColorF); register;
      procedure DrawLine2(P1,P2: TPGLVector2; Width,BorderWidth: GLFloat; FillColor,BorderColor: TPGLColorF; SmoothEdges: Boolean = False); register;
      procedure DrawSprite(Var Sprite: TPGLSprite); register;
      procedure DrawLight(Center: TPGLVector2; Radius,Radiance: GLFloat; Color: TPGLColorI); register;
      procedure DrawLightCircle(Center: TPGLVector2; Color: TPGLColorI; Radiance,Radius: GLFloat); register;
      procedure DrawLightFan(Center: TPGLVector2; Color: TPGLColorI; Radiance: GLFloat; Radius,Angle,Spread: GLFloat); register;
      procedure DrawLightFanBatch(); register;
      procedure DrawText(Text: TPGLText); Overload; register;
      procedure DrawText(Text: String; Font: TPGLFont; Size: GLInt; Position: TPGLVector2; BorderSize: GLUInt; Color,BorderColor: TPGLColorI; Shadow: Boolean = False); Overload; register;

      // Effects
      procedure ApplyLights(); register;
      procedure Swirl(Target: TPGLRenderTarget; DestRect,SourceRect: TPGLRectF); register;
      procedure Pixelate(PixelRect: TPGLRectF; PixelSize: GLFloat = 2); register;
      procedure Smooth(Area: TPGLRectF; IgnoreColor: TPGLColorI); register;
      procedure DrawStatic(Area: TPGLRectF); register;
      procedure StereoScope(Area: TPGLRectF; OffSet: TPGLVector2); register;
      procedure FloodFill(StartCoord: TPGLVector2; Area: TPGLRectF); register;

      procedure MakeCurrentTarget(); register;
      procedure CopyToTexture(SrcX, SrcY, SrcWidth, SrcHeight: GLUint; DestTexture: GLUint); register;
      procedure CopyToImage(Dest: TPGLImage; SourceRect, DestRect: TPGLRectI); register;
      procedure UpdateFromImage(Source: TPGLImage; SourceRect: TPGLRectI); register;

      Property Width: GLUint Read pWidth;
      Property Height: GLUint Read pHeight;
      Property DrawOffset: TPGLVector2 read pDrawOffset;
      Property PixelSize: GLFloat read pPixelSize;
      Property Brightness: GLFloat read pBrightness;
      Property TextSmoothing: Boolean read pTextSmoothing;
      Property ClearColor: TPGLColorF read pClearColor;
      Property DrawShadows: Boolean read pDrawShadows;
      Property GlobalLight: GLFloat read pGlobalLight;

      procedure SetDrawOffSet(OffSet: TPGLVector2); register;
      procedure SetPixelSize(Size: GLFloat); register;
      procedure SetBrightness(Level: GLFloat); register;
      procedure SetNegative(Enable: Boolean = True); register;
      procedure SetSwizzle(Enable: Boolean = True; R: Integer = 0; G: Integer = 1; B: Integer = 2); register;
      procedure SetTextSmoothing(Smoothing: Boolean = True); register;
      procedure SetClearColor(Color: TPGLColorI); Overload; register;
      procedure SetClearColor(Color: TPGLColorF); Overload; register;
      procedure SetDrawShadows(Draw: Boolean; ShadowType: GLFloat = 0); register;
      procedure SetGlobalLight(Value: GLFloat); register;
  end;


  type TPGLRenderTexture = class(TPGLRenderTarget)
    Private
      Angle: GLFloat;
      Opacity: GLFloat;
      TextureMS: GLUInt;
      BackTexture: GLUint;
      pisMultiSampled: Boolean;
      pBitDepth: GLInt;
      pPixelFormat: GLInt;

      procedure SetDrawBuffers(Buffers: Array of GLEnum); register;
      procedure SetPixelFormat(); register;

    Public
      constructor Create(inWidth,inHeight: GLInt; BitCount: GLInt = 32);
      procedure Rotate(byAngle: GLFloat); register;
      procedure SetRotation(toAngle: GLFloat); register;
      procedure SetPixelSize(P: Integer); register;
      procedure SetOpacity(Val: GLFloat); register;
      procedure SetSize(W,H: GLUInt); register;
      procedure SetNearestFilter(); register;
      procedure SetLinearFilter(); register;

      // blting
      procedure Blt(Dest: TPGLRenderTarget; destX, destY, destWidth, destHeight, srcX, srcY: GLFloat); Overload; register;
      procedure Blt(Dest: TPGLRenderTarget; DestRect, SourceRect: TPGLRectI); Overload; register;
      procedure StretchBlt(Dest: TPGLRenderTarget; destX, destY, destWidth, destHeight, srcX,srcY,srcWidth,srcHeight: GLFloat); Overload; register;
      procedure StretchBlt(Dest: TPGLRenderTarget; destRect,srcRect: TPGLRectI); Overload; register;
      procedure StretchBlt(Dest: TPGLRenderTarget; destRect,srcRect: TPGLRectF); Overload; register;
      procedure BlendBlt(Dest: TPGLRenderTarget; destX, destY, destWidth, destHeight, srcX,srcY,srcWidth,srcHeight: GLFloat); Overload; register;
      procedure BlendBlt(Dest: TPGLRenderTarget; DestRect,SourceRect: TPGLRectF); Overload; register;
      procedure CopyBlt(Dest: TPGLRenderTarget; destX, destY, destWidth, destHeight, srcX,srcY,srcWidth,srcHeight: GLFloat); Overload; register;
      procedure CopyBlt(Dest: TPGLRenderTarget; DestRect,SourceRect: TPGLRectF); Overload; register;
      procedure ChangeTexture(Texture: TPGLTexture); register;
      procedure RestoreTexture(); register;
      procedure SaveToFile(FileName: String; Channels: Integer = 4); register;
      procedure SetMultiSampled(MultiSampled: Boolean); register;

      Property isMultiSampled: Boolean read pisMultiSampled;
      Property BitDepth: GLInt read pBitDepth;
  end;


  type TPGLRenderMap = class(TPGLRenderTarget)
    {
     The intent of the Render Map is to provide a large background or map image
     that can be easily 'chunked' into a grid or array to act as a collection of
     sub-images that can be loaded into VRAM for use as needed.

     Intended usage:
      - Create the map with a desired height and width
      - Specify a 'selection rect' which will hold the image data loaded into VRAM
      - Specify a 'View Port' which is the intended sub-rect of the selection rect
        that will be drawn to the frame buffer.
      - Handle when and how the selection rect is updated from RAM and when the
        view port is moved/updated in response to user input or selection rect
        update
    }

    Private
      ScanLine: Array of Pointer;
      Data: Pointer;
      pTotalWidth,pTotalHeight: GLUInt; // Total width and height of the data held in RAM
      pSelectionRect: TPGLRectI; // Bounds of the rectangle selected from data
      pOffSet: TPGLVector2; // X and Y of the top left corner of the selected data
      pViewPort: TPGLRectI; // Bounds of the area of the SelectionRect that is to be drawn to the buffer

    Public

      constructor Create(Width,Height,SelectionWidth,SelectionHeight,ViewPortWidth,ViewPortHeight: GLUInt); register;

      Property TotalWidth: GLUInt read pTotalWidth;
      Property TotalHeight: GLUInt read pTotalHeight;
      Property SelectionRect: TPGLRectI read pSelectionRect;
      Property SelectionOffSet: TPGLVector2 read pOffSet;
      Property ViewPort: TPGLRectI read pViewPort;

      procedure SetSelectionRectSize(Width,Height: GLUInt); register;
      procedure MoveSelectionRect(ByX,ByY: GLUInt); register;
      procedure SetSelectionRect(Left,Top: GLUInt); register;
      procedure UpdateImageSelection(); register;
      procedure SetViewPortSize(Width,Height: GLUInt); register;
      procedure MoveViewPort(ByX,ByY: GLUInt); register;
      procedure SetViewPort(Left,Top: GLUInt); register;
      function RetrievePixelsFromMemory(SRect: TPGLRectI): TColorArray; register;

    Private
      procedure WriteSelectionToImage(); register;
      procedure GetSelectionFromImage(X,Y: GLUInt); register;
  end;


  type TPGLWindow = class(TPGLRenderTarget)
    Private
      TempBuffer: GLUInt;
      pOrgWidth,pOrgHeight: GLUInt;
      pFullScreen: Boolean;
      pTitleBar: Boolean;
      pTitle: String;
      pDisplayRect: TPGLRectF;
      pDisplayRectUsing: Boolean;
      pDisplayRectOrigin: TPGLVector2;
      pDisplayRectScale: Boolean;
      pDisplayRectOrgWidth: GLInt;
      pDisplayRectOrgHeight: GLInt;

      constructor Create(inWidth,inHeight: GLInt); register;
      procedure onResize(); register;

    Public
      Handle: HWND;
      osHandle: LongInt;

      Property OrgWidth: GLUInt read pOrgWidth;
      Property OrgHeight: GLUInt read pOrgHeight;
      Property FullScreen: Boolean read pFullScreen;
      Property TitleBar: Boolean read pTitleBar;
      Property Title: String read pTitle;
      Property DisplayRect: TPGLRectF read pDisplayRect;

      procedure Close(); register;
      procedure DisplayFrame(); register;
      procedure SetSize(W,H: GLUInt); register;
      procedure SetFullScreen(isFullScreen: Boolean); register;
      procedure SetTitleBar(hasTitleBar: Boolean); register;
      procedure SetTitle(inTitle: String); register;
      procedure SetScreenPosition(X,Y: GLInt); register;
      procedure CenterInScreen(); register;
      procedure Maximize(); register;
      procedure Minimize(); register;
      procedure Restore(); register;
      procedure SetDisplayRect(Rect: TPGLRectI; ScaleOnResize: Boolean); register;
      procedure SetIcon(Image: TPGLImage); Overload; register;
      procedure SetIcon(FileName: String; TransparentColor: TPGLColorI); Overload; register;
  end;


  type TPGLUniform = record
    Name: String;
    Location: GLInt;
  end;


  type TPGLProgram = class
    Private
      UniformCount: GLInt;
      Uniform: Array of TPGLUniform;

      function SearchUniform(uName: String): GLInt; register;
      procedure AddUniform(uName: string; Location: GLInt); register;
    Public
      ProgramName: String;
      Valid: Boolean;
      ShaderProgram: GLInt;
      VertexShader: GLInt;
      FragmentShader: GLInt;
      GeometryShader: GLInt;

      constructor Create(Name: String; VertexShaderPath, FragmentShaderPath: String; GeometryShaderPath: String = '');
      procedure Use(); register;
  end;


  type TPGLMonitor = record
    X,Y,Width,Height: GLInt;
  end;


  type TPGLState = record
    Private
      pMaxTextureSize: GLInt;
      InitWidth, InitHeight: GLInt;
      GlobalLight: GLFloat;
      DefaultMaskColor: TPGLColorF;
      DefaultReplace: Array of Array [0..1] of TPGLColorI;

      // States
      MajorVer,MinorVer: GLUInt;
      CurrentRenderTarget: GLUInt;
      CurrentBufferCollection: ^TPGLBufferCollection;
      ViewPort: TPGLRectI;
      TextureType: glEnum;
      TextureFormat: GLInt;
      WindowColorFormat: GLInt;
      TexUnit: Array [0..31] of GLUInt;
      EllipsePointInterval: GLInt;

      // Created Objects
      RenderTextures: Array of TPGLRenderTexture;
      Textures: array of GLUInt;
      TextureObjects: Array of TPGLTexture;
      Images: Array of TPGLImage;
      Lights: Array of TPGLLightSource;
      Sprites: Array of TPGLSprite;

      ShadowMap: GLUint;
      ShadowTarget: TPGLRenderTarget;

      procedure AddRenderTexture(Source: TPGLRenderTexture); register;
      procedure AddTextureObject(Var TexObject: TPGLTexture); register;
      procedure RemoveTextureObject(Var TexObject: TPGLTexture); register;
      procedure UpdateViewPort(X,Y,W,H: GLInt); register;
      procedure GenTexture(Var Texture: GLUInt); register;
      procedure DeleteTexture(Var Texture: GLUInt); register;
      procedure BindTexture(TextureUnit: GLUInt; Texture: GLUInt); register;
      procedure UnBindAll(); register;
      procedure UnBindTexture(TexName: GLUint); register;
      procedure VBOSubData(Binding: glEnum; OffSet: GLInt; Size: GLInt; Source: Pointer); register;
      procedure SSBOSubData(Binding: glEnum; OffSet: GLInt; Size: GLInt; Source: Pointer); register;
      function GetNextVBO(): GLInt; register;
      function GetNextSSBO(): GLInt; register;

    Public
      Context: TPGLContext;
      Window: TPGLWindow;
      Handle: HWND;
      OSHandle: pointer;
      Screen: TPGLMonitor;
      VideoMode: DEVMODE;

      class operator Initialize(Out Dest: TPGLState); register;
      procedure UpdateWindowBounds(); register;
      procedure SetDefaultMaskColor(Color: TPGLColorI); register;
      procedure AddDefaultColorReplace(Color,NewColor: TPGLColorI); register;
      procedure DestroyImage(Var Image: TPGLImage); register;
      procedure GetInputDevices(var KeyBoard: TPGLKeyboard; var Mouse: TPGLMouse; var Controller: TPGLController); register;
      function GetTextureCount(): NativeUInt; register;

      Property GetViewPort: TPGLRectI read ViewPort;
      Property MaxTextureSize: GLInt read pMaxTextureSize;
  end;


  //////////////////////////////////////////////////////////////////////////////
  ////////////////////////// Helper Types //////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  type
    TPGLTextureHelper = class Helper for TPGLTexture
    procedure CopyFrom(Image: TPGLImage; X,Y,Width,Height: GLInt); Overload; register;
    procedure CopyFrom(Texture: TPGLTexture; X,Y,Width,Height: GLInt); Overload; register;
    procedure CopyFrom(Sprite: TPGLSprite; X,Y,Width,Height: GLInt); Overload; register;
  end;


  type
    TPGLImageHelper = class Helper for TPGLImage
    constructor CreateFromTexture(Var Source: TPGLTexture); register;
    procedure CopyFromTexture(Var Source: TPGLTexture); register;
  end;


  type TPGLColorIHelper = record Helper for TPGLColorI
    function IsColor(CompareColor: TPGLColorF; Tolerance: Double = 0): Boolean; OverLoad; register;
    function IsColor(CompareColor: TPGLColorI; Tolerance: Double = 0): Boolean; OverLoad; register;
  end;


  type TPGLColorFHelper = record Helper for TPGLColorF
    function IsColor(CompareColor: TPGLColorI; Tolerance: Double = 0): Boolean; OverLoad; register;
    function IsColor(CompareColor: TPGLColorF; Tolerance: Double = 0): Boolean; OverLoad; register;
  end;


  Type TPGLRectFHelper = record helper for TPGLRectF
    function toRectI(): TPGLRectI;
    function toPoints(): TPGLVectorQuad;
    function CheckInside(Pos: TPGLVector2): Boolean; register;
  end;

  Type TPGLRectIHelper = record helper for TPGLRectI
    function toRectF(): TPGLRectF;
    function toPoints(): TPGLVectorQuad;
    function CheckInside(Pos: TPGLVector2): Boolean; register;
  end;


  //////////////////////////////////////////////////////////////////////////////
  //////////////////// Global Procedures and Functions /////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  procedure pglInit(Var AWindow: TPGLWindow; AWidth,AHeight: GLInt; ATitle: String; AWindowAttributes: TPGLWindowFlags); register;
  procedure pglSetColorFormats(AWindowAttributes: TPGLWindowFlags); register;
  procedure pglGetWindowColorFormat(); register;
  procedure pglExitGL(); register;
  procedure pglAddError(Msg: String); register;
  procedure pglReportErrors(); register;
  procedure PGLERRORDEBUG(AErrorStatus: glEnum); register;


  procedure pglWindowUpdate(); CDecl;
  procedure pglSetShaders(); register;
  procedure pglLoadShadersFromDirectories(); register;
  function pglLoadShader(AShader: GLInt; APath: String): Boolean; register;
  procedure pglSetWindowTitle(ATitle: String); register;
  procedure pglSetScales(); register;
  procedure pglSetDefaultColors(); register;


  // type functions
 	function RectI(AL,AT,AR,AB: GLFloat): TPGLRectI; Overload; register;
  function RectI(ACenter: TPGLVector2; AWidth,AHeight: GLFloat): TPGLRectI; Overload; register;
  function RectIWH(AL,AT,AWidth,AHeight: GLFloat): TPGLRectI; register;
  function RectF(AL,AT,AR,AB: GLFloat): TPGLRectF; Overload; register;
  function RectF(ACenter: TPGLVector2; AWidth,AHeight: GLFloat): TPGLRectF; Overload; register;
  function RectFWH(AL,AT,AWidth,AHeight: GLFloat): TPGLRectF; Overload; register;
  function PointsToRectF(Var APoints: Array of TPGLVector2): TPGLRectF; register;
  function CheckPointInBounds(APoint: TPGLVector2; ABounds: TPGLRectF): Boolean; register;

  function Vec2(AX,AY: GLFloat): TPGLVector2; register; Overload;
  function Vec2(APointF: TPointFloat): TPGLVector2; register; Overload;
  function Vec2(AVector3: TPGLVector3): TPGLVector2; register; Overload;
  function Vec3(AX,AY,AZ: GLFloat): TPGLVector3; register;
  function Vec4(AX,AY,AZ,AW: GLFloat): TPGLVector4; register;
  function SXVec2(AX,AY: GLFloat): TPGLVector2; register;

  function PGLAngleToRad(AAngle: GLFloat): GLFloat; register;
  function PGLRadToAngle(ARad: GLFloat): GLFloat; register;
  function BoolToInt(ABool: Boolean): GLUint; register;

  procedure FlipPoints(Var APoints: TPGLVectorQuad); register;
  procedure MirrorPoints(Var APoints: TPGLVectorQuad); register;
  procedure RotatePoints(Var APoints: Array of TPGLVector2; ACenter: TPGLVector2; AAngle: GLFloat); register;
  procedure TruncPoints(Var APoints: Array of TPGLVector2); register;
  function ReturnRectPoints(AP1,AP2: TPGLVector2; AWidth: GLFloat): TPGLVectorQuad; register;

  function ClampFColor(AValue: GLFloat): GLFloat; register;
  function ClampIColor(AValue: GLInt): GLInt; register;
  function RoundInt(AValue: GLFloat): GLInt; register;

  function Color3i(ARed,AGreen,ABlue: GLInt): TPGLColorI; register;
  function Color4i(ARed,AGreen,ABlue,AAlpha: GLInt): TPGLColorI; register;
  function Color3f(ARed,AGreen,ABlue: GLFloat): TPGLColorF; register;
  function Color4f(ARed,AGreen,ABlue,AAlpha: GLFloat): TPGLColorF; register;
  function ColorItoF(AColor: TPGLColorI): TPGLColorF; register;
  function ColorFtoI(AColor: TPGLColorF): TPGLColorI; register;
  function GetColorChangeIncrements(AStartColor, AEndColor: TPGLColorI; ACycles: Integer): TPGLColorI; Overload; register;
  function GetColorChangeIncrements(AStartColor, AEndColor: TPGLColorF; ACycles: Integer): TPGLColorF; Overload; register;
  function CC(AColor: TPGLColorI): TPGLColorF; OverLoad; register;
  function CC(AColor: TPGLColorF): TPGLColorI; OverLoad; register;
  function ColorCombine(AColor1,AColor2: TPGLColorI): TPGLColorI; Overload; register;
  function ColorCombine(AColor1,AColor2: TPGLColorF): TPGLColorF; Overload; register;
  function ColorMultiply(AColor1,AColor2: TPGLColorI): TPGLColorI; Overload; register;
  function ColorMultiply(AColor1,AColor2: TPGLColorF): TPGLColorF; Overload; register;
  procedure ColorAdd(Out AColor: TPGLColorI; AAddColor: TPGLColorI; AAddAlphas: Boolean = True); Overload; register;
  procedure ColorAdd(Out AColor: TPGLColorF; AAddColor: TPGLColorF; AAddAlphas: Boolean = True); Overload; register;
  function ColorMix(AColor1,AColor2: TPGLColorI; AFactor: GLFloat): TPGLColorI; register;

  function pglStringToChar(InString: String): TPGLCharArray; register;
  procedure pglSaveTexture(Texture: GLUInt; Width,Height: GLUInt; FileName: String; MipLevel: GLUInt = 0); register;
  procedure pglReplaceTextureColors(Textures: Array of TPGLTexture; Colors: Array of TPGLColorI; NewColor: TPGLColorI); register;
  procedure pglReplaceAllTexturesColors(Colors: Array of TPGLColorI; NewColor: TPGLColorI); register;
  procedure pglSetEllipseInterval(Interval: GLInt = 10); register;

  function ImageDesc(Source: Pointer; Width,Height: GLUInt): TPGLImageDescriptor; register;
  function pglPixelFromMemory(Source: Pointer; X,Y,Width,Height: GLInt): TPGLColorI; register;

  function FindTextLineBreak(Var Text:String): Integer; register;
  function FindTextTags(Var Text:String): TPGLTextTagArray; register;


  procedure ReSizeFuncPlaceHolder(); register;

  // Math functions
  function pglRound(inVal: GLFloat): GLInt; register;
  function pglMatrixRotation(Out Mat: TPGLMatrix4;inAngle,X,Y: GLFloat): boolean; register;
  function pglMatrixScale(Out Mat: TPGLMatrix4; W,H: GLFloat): boolean; register;
  function pglMatrixTranslation(Out Mat: TPGLMatrix4; X,Y: GLFloat): Boolean; register;
  function pglMat2Rotation(Angle: GLFloat): TPGLMatrix2; register;
  function pglMat2Translation(X,Y: GLFloat): TPGLMatrix2; register;
  function pglMat2Scale(sX,sY: GLFloat): TPGLMatrix2; register;
  function pglMat2Multiply(Mat1,Mat2: TPGLMatrix2): TPGLMatrix2; register;
  function pglMat3Multiply(Mat1,Mat2: TPGLMatrix3): TPGLMatrix3; register;
  function pglVectorCross(VecA, VecB: TPGLVector3): TPGLVector3; register;
  function SX(inVal: GLFloat): GLFloat; register;
  function SY(inVal: GLFloat): GLFloat; register;
  function BX(inVal, BuffWidth: GLFloat): GLFloat; register;
  function BY(inVal, BuffHeight: GLFloat): GLFloat; register;
  function TX(inVal, TexWidth: GLFloat): GLFloat; register;
  function TY(inVal, TexHeight: GLFloat): GLFloat; register;
  procedure TransformToScreen(Out Points: TPGLVectorQuad); register;
  procedure TransformToBuffer(Out Points: TPGLVectorQuad; BuffWidth,BuffHeight: GLFloat); register;
  procedure TransformToTexture(Out Points: TPGLVectorQuad; TexWidth,TexHeight: GLFloat); register;

  // Shader functions
  function pglGetUniform(Uniform: String): GLInt; register;
  procedure pglUseProgram(ShaderProgramName: String); register;

Var

  // Context
  PGL: TPGLState;
  pglErrorLog: Array of String;

  pglRunning: Boolean;
  pglEXEPath: String;
  pglShaderPath: String;
  pglScaleX,pglScaleY: GLFloat;

  // Window
  TPGLWindowTitle: String[30];
  pglTempBuffer: TPGLRenderTexture;
  pglCopyBuffer: TPGLRenderTexture;
  pglCopyBuffer2: TPGLRenderTexture;

  // Shaders
  CurrentProgram: TPGLProgram;
  ProgramList: Array of TPGLProgram;

  DefaultProgram: TPGLProgram;
  CircleProgram: TPGLProgram;
  PointProgram: TPGLProgram;
  FrameBufferProgram: TPGLProgram;
  RectangleProgram: TPGLProgram;
  TextureProgram: TPGLProgram;
  TextureSimpleProgram: TPGLProgram;
  TextureSDFProgram: TPGLProgram;
  TextureLayerProgram: TPGLProgram;
  LightProgram: TPGLProgram;
  LightFanProgram: TPGLProgram;
  PixelateProgram: TPGLProgram;
  TextProgram: TPGLProgram;
  TextSDFProgram: TPGLProgram;
  TextBorderProgram: TPGLProgram;
  SmoothProgram: TPGLProgram;
  BlendBltProgram: TPGLProgram;
  CopyBltProgram: TPGLProgram;
  SpriteBatchProgram: TPGLProgram;
  SwirlProgram: TPGLProgram;
  LineProgram: TPGLProgram;
  PixelTransferProgram: TPGLProgram;
  StaticProgram: TPGLProgram;
  CubeProgram: TPGLProgram;
  SDFProgram: TPGLProgram;

  // Colors
  PGL_RED: TPGLColorI;
  PGL_GREEN: TPGLColorI;
  PGL_BLUE: TPGLColorI;
  PGL_YELLOW: TPGLColorI;
  PGL_MAGENTA: TPGLColorI;
  PGL_CYAN: TPGLColorI;
  PGL_WHITE: TPGLColorI;
  PGL_BLACK: TPGLColorI;
  PGL_GREY: TPGLColorI;
  PGL_LIGHTGREY: TPGLColorI;
  PGL_DARKGREY: TPGLColorI;
  PGL_ORANGE: TPGLColorI;
  PGL_BROWN: TPGLColorI;
  PGL_PINK: TPGLColorI;
  PGL_PURPLE: TPGLColorI;
  PGL_EMPTY: TPGLColorI;

  // Matrices Templates
  pglIdentityMatrix: TPGLMatrix4;
  pglScaleMatrix: TPGLMatrix4;

Const

  // Shaders
  PGL_DEFAULT_SHADER = -1;

  // Lighting
  PGL_NORMAL_LIGHT = 1;
  PGL_DIM_LIGHT = 0.75;
  PGL_DARK = 0.25;
  PGL_DARKER = 0.1;
  PGL_DARKEST = 0.05;
  PGL_NO_LIGHT = 0;

  // SHADOWS
  PGL_NO_SHADOW = 0;
  PGL_PARTIAL = 0.5;
  PGL_FULL = 1;

  // Rect Update
  FROMCENTER = 0;
  FROMLEFT = 1;
  FROMTOP = 2;
  FROMRIGHT = 3;
  FROMBOTTOM = 4;

  LEFT = 0;
  TOP = 1;
  RIGHT = 2;
  BOTTOM = 3;

  RED = 0;
  GREEN = 1;
  BLUE = 2;

  VK_PAD_A                        = $5800;
  VK_PAD_B                        = $5801;
  VK_PAD_X                        = $5802;
  VK_PAD_Y                        = $5803;
  VK_PAD_RSHOULDER                = $5804;
  VK_PAD_LSHOULDER                = $5805;
  VK_PAD_LTRIGGER                 = $5806;
  VK_PAD_RTRIGGER                 = $5807;
  VK_PAD_DPAD_UP                  = $5810;
  VK_PAD_DPAD_DOWN                = $5811;
  VK_PAD_DPAD_LEFT                = $5812;
  VK_PAD_DPAD_RIGHT               = $5813;
  VK_PAD_START                    = $5814;
  VK_PAD_BACK                     = $5815;
  VK_PAD_LTHUMB_PRESS             = $5816;
  VK_PAD_RTHUMB_PRESS             = $5817;
  VK_PAD_LTHUMB_UP                = $5820;
  VK_PAD_LTHUMB_DOWN              = $5821;
  VK_PAD_LTHUMB_RIGHT             = $5822;
  VK_PAD_LTHUMB_LEFT              = $5823;
  VK_PAD_LTHUMB_UPLEFT            = $5824;
  VK_PAD_LTHUMB_UPRIGHT           = $5825;
  VK_PAD_LTHUMB_DOWNRIGHT         = $5826;
  VK_PAD_LTHUMB_DOWNLEFT          = $5827;
  VK_PAD_RTHUMB_UP                = $5830;
  VK_PAD_RTHUMB_DOWN              = $5831;
  VK_PAD_RTHUMB_RIGHT             = $5832;
  VK_PAD_RTHUMB_LEFT              = $5833;
  VK_PAD_RTHUMB_UPLEFT            = $5834;
  VK_PAD_RTHUMB_UPRIGHT           = $5835;
  VK_PAD_RTHUMB_DOWNRIGHT         = $5836;
  VK_PAD_RTHUMB_DOWNLEFT          = $5837;
  XInputGamePadDPadUp             = $0001;
  XInputGamePadDPadDown           = $0002;
  XInputGamePadDPadLeft           = $0004;
  XInputGamePadDPadRight          = $0008;
  XInputGamePadStart              = $0010;
  XInputGamePadBack               = $0020;
  XInputGamePadLeftThumb          = $0040;
  XInputGamePadRightThumb         = $0080;
  XInputGamePadLeftShoulder       = $0100;
  XInputGamePadRightShoulder      = $0200;
  XInputGamePadA                  = $1000;
  XInputGamePadB                  = $2000;
  XInputGamePadX                  = $4000;
  XInputGamePadY                  = $8000;


implementation


procedure PGLERRORDEBUG(AErrorStatus: glEnum);

  begin

    if AErrorStatus = GL_INVALID_ENUM then begin
      AErrorStatus := 0;
    End Else if AErrorStatus = GL_INVALID_VALUE then begin
      AErrorStatus := 0;
    End Else if AErrorStatus = GL_INVALID_OPERATION then begin
      AErrorStatus := 0;
    End Else if AErrorStatus = GL_STACK_OVERFLOW then begin
      AErrorStatus := 0;
    End Else if AErrorStatus = GL_STACK_UNDERFLOW then begin
      AErrorStatus := 0;
    End Else if AErrorStatus = GL_OUT_OF_MEMORY then begin
      AErrorStatus := 0;
    end;

  end;


procedure PGLInit(Var AWindow: TPGLWindow; AWidth,AHeight: GLInt; ATitle: String; AWindowAttributes: TPGLWindowFlags);

Var
I: Long;
WRect: TRect;
L,R,T,B: Integer;
CheckVar: GLInt;
ExtPointer: Array of pglUbyte;
ExtString: Array of String;
CharTitle: TPGLCharArray;
Samples: GLInt;
WinForm: TPGLWindowFormat;
WinFeats: TPGLFeatureSettings;

  begin

    // First, get the monitor and screen data so that flags can be applied correctly

    WinForm.ColorBits := 32;
    WinForm.DepthBits := 0;
    WinForm.StencilBits := 0;
    WinForm.Samples := 0;
    WinForm.VSync := True;
    WinForm.BufferCopy := True;


    if pglFullScreen in AWindowAttributes then begin
      WinForm.FullScreen := True;
    end;

    if pglTitleBar in AWindowAttributes then begin
      WinForm.TitleBar := True;
    end;

    if pglSizable in AWindowAttributes then begin
      WinForm.Maximize := True;
    end;

    if pglDebug in AWindowAttributes then begin
      WinFeats.OpenGLDebugContext := True;
    end;

    pglStart(AWidth,AHeight,WinForm,WinFeats,ATitle);
    PGL.Context := glDrawContext.Context;
    PGL.Context.SetDebugToConsole();
    PGL.Context.SetBreakOnDebug(True);

    PGL.Screen.Width := GetDeviceCaps(GetDC(0),HORZRES);
    PGL.Screen.Height :=  GetDeviceCaps(GetDC(0),VERTRES);

    PGLSetColorFormats(AWindowAttributes);

    glEnable(GL_PROGRAM_POINT_SIZE);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
    glDisable(GL_STENCIL_TEST);
    glEnable(GL_TEXTURE_2D);

    PGLGetWindowColorFormat();

    AWindow := TPGLWindow.Create(AWidth,AHeight);
    PGL.Handle := PGL.Context.Handle;
    AWindow.Handle := PGL.Handle;
    AWindow.osHandle := PGL.Context.Handle;
    AWindow.pFullscreen := PGL.Context.FullScreen;

    glViewPort(0,0,AWidth,AHeight);
    pglSetScales();

    pglEXEPath := (ExtractFilePath(ParamStr(0)));
    pglShaderPath := (pglEXEPath + 'Shaders\');

    PGLSetShaders();

    PGLSetDefaultColors();

    PGL.CurrentRenderTarget := 0;
    PGL.TextureType := GL_TEXTURE_2D;

    // utility FBOs, not available to user
    pglTempBuffer := TPGLRenderTexture.Create(800,600);
    pglCopyBuffer := TPGLRenderTexture.Create(800,600);
    pglCopyBuffer2 := TPGLRenderTexture.Create(800,600);

    // Shared shadow map
    glGenTextures(1,@PGL.ShadowMap);
    glBindTexture(GL_TEXTURE_2D,PGL.ShadowMap);
    glTexImage2d(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24,800,600,0,GL_DEPTH_COMPONENT, GL_FLOAT, nil);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindTexture(GL_TEXTURE_2D,0);

    glGetIntegerV(GL_MAJOR_VERSION,@PGL.MajorVer);
    glGetintegerV(GL_MINOR_VERSION,@PGL.MinorVer);

    pglRunning := True;
  end;


procedure PGLSetColorFormats(AWindowAttributes: TPGLWindowFlags);
  begin
    PGL.TextureFormat := GL_RGBA;
//    glEnable(GL_DITHER);
    Exit;
  end;

procedure PGLGetWindowColorFormat();
  begin
    PGL.WindowColorFormat := GL_RGBA;
  end;


procedure pglExitGL();

  begin
    PGL.Context.Close();
    pglRunning := False;
  end;


procedure PGLAddError(Msg: String);
Var
Len: GLInt;
  begin
    Len := Length(pglErrorLog) + 1;
    SetLength(pglErrorLog,Len);
    Len := High(pglErrorLog);
    pglErrorLog[Len] := Msg;
  end;


procedure PGLReportErrors();
Var
ErrString: String;
I: GLInt;
  begin

    if Length(pglErrorLog) = 0 then Exit;

    ErrString := '';

    for I := 0 to High(pglErrorLog) Do begin
      ErrString := ErrString + pglErrorLog[i] + sLineBreak;
    end;

    MessageBox(0,PWideChar(@ErrString),'Error Log',MB_OK or MB_ICONEXCLAMATION);
  end;


procedure pglWindowUpdate(); CDecl;
Var
Col: TPGLColorF;
Buffs: GLInt;

	begin

    PGL.Window.DrawLastBatch();
    if PGL.CurrentRenderTarget <> 0 then begin
      glBindFrameBuffer(GL_FRAMEBUFFER,0);
    end;

    SwapBuffers(PGL.Context.DC);

    Col := PGL.Window.ClearColor;

    PGL.Window.Clear();

    PGL.Context.PollEvents();

    if PGL.Context.ShouldClose then begin
      pglExitGL;
    end;
  end;


procedure pglSetWindowTitle(ATitle: String);
Var
TString: TPGLCharArray;
  begin
    PGL.Context.SetTitle(ATitle);
    PGL.Window.pTitle := ATitle;
  end;


procedure pglSetScales();

Var
Center: TPGLVector2;
OldVer: Array [0..3] of TPGLVector2;
I: GLInt;
wScaleX,wScaleY: GLFloat;

  begin
    glViewPort(0,0,PGL.initWidth,PGL.initHeight);

    pglScaleX := 1;
    pglScaleY := 1;


  end;


procedure PGLSetDefaultColors();
  begin
    PGL_RED := Color4I(255,0,0,255);
    PGL_GREEN := Color4I(0,255,0,255);
    PGL_BLUE := Color4I(0,0,255,255);
    PGL_YELLOW := Color4I(255,255,0,255);
    PGL_MAGENTA := Color4I(255,0,255,255);
    PGL_CYAN := Color4I(0,255,255,255);
    PGL_WHITE := Color4I(255,255,255,255);
    PGL_BLACK := Color4I(0,0,0,255);
    PGL_GREY := Color4I(150,150,150,255);
    PGL_LIGHTGREY := Color4I(200,200,200,255);
    PGL_DARKGREY := Color4I(75,75,75,255);
    PGL_ORANGE := Color4I(255,150,0,255);
    PGL_BROWN := Color4I(125,50,0,255);
    PGL_PINK := Color4I(255,175,255,255);
    PGL_PURPLE := Color4I(150,25,125,255);
    PGL_EMPTY := Color4I(0,0,0,0);
  end;


procedure PGLSetShaders();

  begin
    DefaultProgram := TPGLProgram.Create('Default','Vertex Default.vert', 'Fragment Default.frag');
    CircleProgram := TPGLProgram.Create('Circle', 'Vertex Circle.vert', 'Fragment Circle.frag');
    PointProgram := TPGLProgram.Create('Point', 'Vertex Point.vert', 'Fragment Point.frag');
    FrameBufferProgram := TPGLProgram.Create('FrameBuffer', 'Vertex FrameBuffer Default.vert', 'Fragment FrameBuffer Default.frag');
    RectangleProgram := TPGLProgram.Create('Rectangle','Vertex Rectangle.vert', 'Fragment Rectangle.frag');
    TextureProgram := TPGLProgram.Create('Texture', 'Vertex Texture Default.vert','Fragment Texture Default.frag');
    TextureSimpleProgram := TPGLProgram.Create('Texture Simple', 'Vertex Texture Simple.vert', 'Fragment Texture Simple.frag');
    LightProgram := TPGLProgram.Create('Light','Vertex Light Default.vert', 'Fragment Light Source.frag');
    LightFanProgram := TPGLProgram.Create('Light Fan', 'Vertex Light Default.vert', 'Fragment Light Polygon.frag');
    TextProgram := TPGLProgram.Create('Text','Vertex Text.vert','Fragment Text.frag');
    TextBorderProgram := TPGLProgram.Create('Test Border','Vertex Text.vert','Fragment Text Border.frag');
    BlendBltProgram := TPGLProgram.Create('Blend Blt', 'Vertex BlendBlt.vert', 'Fragment BlendBlt.frag');
    CopyBltProgram := TPGLProgram.Create('Copy Blt', 'Vertex CopyBlt.vert', 'Fragment CopyBlt.frag');
    SpriteBatchProgram := TPGLProgram.Create('Sprite Batch', 'Vertex Sprite Batch.vert', 'Fragment Sprite Batch.frag');
    SwirlProgram := TPGLProgram.Create('Swirl','Vertex Swirl.vert', 'Fragment Swirl.frag');
    SmoothProgram := TPGLProgram.Create('Smooth', 'Vertex Text.vert', 'Fragment Smooth.frag');
    PixelateProgram := TPGLProgram.Create('Pixelate', 'Vertex Pixelate.vert', 'Fragment Pixelate.frag');
    LineProgram := TPGLProgram.Create('Line', 'Vertex Line.vert', 'Fragment Line.frag');
    PixelTransferProgram := TPGLProgram.Create('Pixel Transfer', 'Vertex Pixel Transfer.vert', 'Fragment Pixel Transfer.frag');
    StaticProgram := TPGLProgram.Create('Static', 'Vertex Default.vert', 'Fragment Static.frag');
    CubeProgram := TPGLProgram.Create('Cube', 'Vertex Cube Default.vert', 'Fragment Cube Default.frag');
    SDFProgram := TPGLProgram.Create('SDF', 'Vertex Text.vert', 'Fragment SDF.frag');

    PGLLoadShadersFromDirectories();
  end;


class operator TPGLPointBatch.Initialize(Out Dest: TPGLPointBatch);
  begin
    Dest.Data := GetMemory(182000);
  end;

class operator TPGLCircleBatch.Initialize(Out Dest: TPGLCircleBatch);
  begin
    Dest.Data := GetMemory(SizeOf(TPGLCircleDescriptor) * High(Dest.Vector));
  end;

class operator TPGLGeometryBatch.Initialize(Out Dest: TPGLGeometryBatch);
  begin
    Dest.Data := GetMemory(182000);
    Dest.DataSize := 0;
    Dest.Color := GetMemory(6400);
    Dest.ColorSize := 0;
    Dest.Normals := GetMemory(182000);
    Dest.NormalsSize := 0;
    Dest.Next := 0;
  end;

procedure PGLUseProgram(ShaderProgramName: String);

Var
I: GLInt;

  begin

    if Length(ProgramList) = 0 then Exit;

    for I := 0 to High(ProgramList) Do begin

      if ProgramList[i].ProgramName = (ShaderProgramName) then begin
        ProgramList[i].Use();
        Exit;
      end;

    end;

    // throw error if program not found
    pglAddError('Could find and use program ' + ShaderProgramName + '!');

  end;


procedure PGLLoadShadersFromDirectories();
Var
Dir: TDirectory;
Folders,Files: TStringDynArray;
I,R,P: GLInt;
DirName: String;
DirPath: String;
FileName: Array [0..1] of String;
TempString: String;

  begin

    Dir.SetCurrentDirectory(String(pglEXEPath + 'Shaders\'));
    Folders := Dir.GetDirectories(Dir.GetCurrentDirectory);

    if Length(Folders) = 0 then Exit;

    for I := 0 to High(Folders) Do begin

      Dir.SetCurrentDirectory(Folders[i]);
      Files := Dir.GetFiles(Dir.GetCurrentDirectory);

      if Length(Files) <> 2 then Continue;

        DirName := ExtractFileName(Folders[i]);
        DirPath := string(pglEXEPath) + 'Shaders\' + DirName + '\';
        FileName[0] := '';
        FileName[1] := '';

        for R := 0 to high(Files) Do begin
          TempString := ExtractFileName(Files[r]);

          if POS('.vert',TempString) <> 0 then begin
            FileName[0] := TempString;
          end;

          if POS('.frag',TempString) <> 0 then begin
            FileName[1] := TempString;
          end;

        end;


        SetLength(ProgramList,Length(ProgramList) + 1);
        P := High(ProgramList);
        ProgramList[P] := TPGLProgram.Create((DirName),(DirPath + FileName[0]),(DirPath + FileName[1]));

        if ProgramList[p].Valid = False then begin
          pglAddError('Failed to load shader ' + DirName + ' from directory!');
          SetLength(ProgramList,Length(ProgramList) - 1);
        end;

    end;

  end;

function PGLLoadShader(AShader: GLInt; APath: String): boolean;

Var
SourceString: String;
SourceChars: TPGLCharArray;
Chars: Array of Char;
I: GLInt;
Len: GLInt;
inString: String;
inFile: TextFile;
FileName: String;
CheckString: String;

  begin

    // check for a path to the file name, if none, try shader default path
    if ExtractFilePath(APath) = '' then begin
      APath := string(pglShaderPath) + APath;
    end;

    // if the file doesn't exist, notify, fail and exit
    if FileExists(APath,True) = False then begin
      Filename := ExtractFileName(APath);
      PGLAddError('The file ' + FileName + ' could not be found!');
      Result := False;
      Exit;
    end;

    AssignFile(inFile, APath);
    Reset(inFile);

    SourceString := '';

    Repeat
      ReadLn(inFile,inString);
      SourceString := SourceString + (inString) + sLineBreak;
    until EOF(inFile);

    Len := Length(SourceString);
    SourceChars := PGLStringToChar((SourceString));

    glShaderSource(AShader,1,PPGLChar(@SourceChars),@Len);
    glCompileShader(AShader);

    glGetShaderiv(AShader, GL_COMPILE_STATUS, @Len);

    // if the shader doesn't compile, notify, fail and exit
    if Len = 0 then begin
      FileName := ExtractFileName(APath);
      PGLAddError('Failed to compile shader from ' + Filename + '!');
      Result := False;
      Exit;
    end;

    Result := True;
  end;


//////////////////////// type functions //////////////////////////////

function RectI(AL,AT,AR,AB: GLFloat): TPGLRectI; OverLoad;
	begin
  	Result.Left := trunc(AL);
    Result.Right := trunc(AR);
    Result.Top := trunc(AT);
    Result.Bottom := trunc(AB);
    Result.X := trunc(AL + ((AR - AL) / 2));
    Result.Y := trunc(AT + ((AB - AT) / 2 ));
    Result.Width := trunc(AR-AL);
    Result.Height := trunc(AB-AT);
  end;

function RectI(ACenter: TPGLVector2; AWidth,AHeight: GLFloat): TPGLRectI; OverLoad;
	begin
  	Result.X := trunc(ACenter.X);
    Result.Y := trunc(ACenter.Y);
    Result.Width := trunc(AWidth);
    Result.Height := trunc(AHeight);
    Result.Update(FROMCENTER);
  end;


function RectIWH(AL,AT,AWidth,AHeight: GLFloat): TPGLRectI;
  begin
    Result.Width := trunc(AWidth);
    Result.Height := trunc(AHeight);
    Result.Left := trunc(AL);
    Result.Top := trunc(AT);
    Result.Right := Result.Left + trunc(AWidth);
    Result.Bottom := Result.Top + trunc(AHeight);
    Result.X := RoundInt(Result.Left + (Result.Width / 2));
    Result.Y := RoundInt(Result.Top + (Result.Height / 2));
  end;


function RectF(AL,AT,AR,AB: GLFloat): TPGLRectF; OverLoad;
	begin
  	Result.Left := AL;
    Result.Right := AR;
    Result.Top := AT;
    Result.Bottom := AB;
    Result.X := AL + ((AR - AL) / 2);
    Result.Y := AT + ((AB - AT) / 2 );
    Result.Width := AR-AL;
    Result.Height := AB-AT;
  end;


function RectFWH(AL,AT,AWidth,AHeight: GLFloat): TPGLRectF;
  begin
    Result.Left := AL;
    Result.Top := AT;
    Result.Width := AWidth;
    Result.Height := AHeight;
    Result.X := Result.Left + (Result.Width / 2);
    Result.Y := Result.Top + (Result.Height / 2);
    Result.Update(FROMCENTER);
  end;

function RectF(ACenter: TPGLVector2; AWidth,AHeight: GLFloat): TPGLRectF; OverLoad;
	begin
  	Result.X := (ACenter.X);
    Result.Y := (ACenter.Y);
    Result.Left := (ACenter.X - (AWidth / 2));
    Result.Right := Result.Left + AWidth;
    Result.Top := (ACenter.y - (AHeight / 2));
    Result.Bottom := Result.Top + AHeight;
    Result.Width := AWidth;
    Result.Height := AHeight;
  end;


function PointsToRectF(Var APoints: Array of TPGLVector2): TPGLRectF;

Var
L,R,T,B: GLFloat;
I: Long;

  begin

    L := 0;
    R := 0;
    T := 0;
    B := 0;

    for I := 0 to High(APoints) Do begin

      if I = 0 then begin
        L := APoints[i].X;
        R := APoints[i].X;
        T := APoints[i].Y;
        B := APoints[i].Y;
      end;

      if APoints[i].X < L then L := APoints[i].X;
      if APoints[i].X > R then R := APoints[i].X;
      if APoints[i].Y < T then T := APoints[i].Y;
      if APoints[i].Y > B then B := APoints[i].Y;

    end;

    Result := glDrawMain.RectF(L,T,R,B);

  end;


function CheckPointInBounds(APoint: TPGLVector2; ABounds: TPGLRectF): Boolean;
  begin

    Result := false;

    if APoint.X >= ABounds.Left then begin
      if APoint.X <= ABounds.Right then begin
        if APoint.Y >= ABounds.Top then begin
          if APoint.Y <= ABounds.Bottom then begin
            Result := True;
          end;
        end;
      end;
    end;

  end;

function Vec2(AX,AY: GLFloat): TPGLVector2;
	begin
  	Result.X := AX;
    Result.Y := AY;
  end;

function Vec2(APointF: TPointFloat): TPGLVector2;
  begin
    Result.X := APointF.X;
    Result.Y := APointF.Y;
  end;

function Vec2(AVector3: TPGLVector3): TPGLVector2;
  begin
    Result.X := AVector3.X;
    Result.Y := AVector3.Y;
  end;

function Vec3(AX,AY,AZ: GLFloat): TPGLVector3;
	begin
  	Result.X := AX;
    Result.Y := AY;
    Result.Z := AZ;
  end;

function Vec4(AX,AY,AZ,AW: GLFloat): TPGLVector4;
	begin
    Result.X := AX;
    Result.Y := AY;
    Result.Z := AZ;
    Result.W := AW;
  end;


function SXVec2(AX,AY: GLFloat): TPGLVector2;
  begin
    Result.X := pglScaleX * (AX);
    Result.Y := pglScaleY * (AY);
  end;


function PGLAngleToRad(AAngle: GLFloat): GLFloat;
  begin
    Result := AAngle * (Pi / 180);
  end;

function PGLRadToAngle(ARad: GLFloat): GLFloat;
  begin
    Result := ARad * (180/Pi);
  end;

function BoolToInt(ABool: Boolean): GLUint;
  begin

    if ABool = False then begin
      Result := 0;
    End Else begin
      Result := 1;
    end;

  end;

procedure FlipPoints(Var APoints: TPGLVectorQuad); register;
// Swap top and bottom points of TPGLVectorQuad, in effect flipping the points of a rectangle
Var
TP1, TP2: TPGLVector2;

  begin
    TP1 := APoints[0];
    TP2 := APoints[1];
    APoints[0] := APoints[3];
    APoints[1] := APoints[2];
    APoints[3] := TP1;
    APoints[2] := TP2;
  end;


procedure MirrorPoints(Var APoints: TPGLVectorQuad); register;
// Mirror Left and Right points of TPGLVectorQuad, in effect Mirroring the points of a rectangle
Var
TP1, TP2: TPGLVector2;

  begin
    TP1 := APoints[0];
    TP2 := APoints[3];
    APoints[0] := APoints[1];
    APoints[3] := APoints[2];
    APoints[1] := TP1;
    APoints[2] := TP2;
  end;


procedure RotatePoints(Var APoints: Array of TPGLVector2; ACenter: TPGLVector2; AAngle: GLFloat);

Var
OldPoints: Array of TPGLVector2;
Count: Long;
I: Long;
Dist: GLFloat;
PointAngle: GLFloat;

  begin

    if AAngle = 0 then Exit;

    Count := Length(APoints);
    SetLength(OldPoints,Count);
//    Angle := -Angle;

    for I := 0 to Count - 1 Do begin
      OldPoints[i].X := APoints[i].X;
      OldPoints[i].Y := APoints[i].Y;
    end;

    for I := 0 to Count - 1 Do begin
      Dist := Sqrt( IntPower(OldPoints[i].X - ACenter.X,2) + IntPower(OldPoints[i].Y - ACenter.Y,2));
      PointAngle := ArcTan2(OldPoints[i].Y - ACenter.Y,OldPoints[i].X - ACenter.X);
      APoints[i].X := ACenter.X + (Dist * Cos(AAngle + PointAngle));
      APoints[i].Y := ACenter.Y + (Dist * Sin(AAngle + PointAngle));
    end;

  end;


procedure TruncPoints(Var APoints: Array of TPGLVector2);
Var
I,Len: Long;
  begin
    Len := High(APoints);
    for I := 0 to Len Do begin
      APoints[i].X := trunc(APoints[i].X);
      APoints[i].Y := trunc(APoints[i].Y);
    end;

  end;

function ReturnRectPoints(AP1,AP2: TPGLVector2; AWidth: GLFloat): TPGLVectorQuad;
Var
Distance, Angle: GLFloat;
  begin

    Angle := ArcTan2(AP2.Y - AP1.Y, AP2.X - AP1.X);

    Result[0].X := AP1.X + ((AWidth / 2) * Cos(Angle + (Pi / 2)));
    Result[0].Y := AP1.Y + ((AWidth / 2) * Sin(Angle + (Pi / 2)));

    Result[1].X := AP2.X + ((AWidth / 2) * Cos(Angle + (Pi / 2)));
    Result[1].Y := AP2.Y + ((AWidth / 2) * Sin(Angle + (Pi / 2)));

    Result[2].X := AP2.X + ((AWidth / 2) * Cos(Angle - (Pi / 2)));
    Result[2].Y := AP2.Y + ((AWidth / 2) * Sin(Angle - (Pi / 2)));

    Result[3].X := AP1.X + ((AWidth / 2) * Cos(Angle - (Pi / 2)));
    Result[3].Y := AP1.Y + ((AWidth / 2) * Sin(Angle - (Pi / 2)));

  end;

function ClampFColor(AValue: GLFloat): GLFloat;
  begin
    if AValue > 1 then AValue := 1;
    if AValue < 0 then AValue := 0;

    Result := AValue;
  end;

function ClampIColor(AValue: GLInt): GLInt;
  begin
    if AValue > 255 then AValue := 255;
    if AValue < 0 then AValue := 0;

    Result := AValue;
  end;


function RoundInt(AValue: GLFLoat): GLInt;
Var
VFloat: GLFloat;
  begin
    VFloat := AValue - trunc(AValue);
    if VFloat < 5 then begin
      Result := Trunc(AValue);
    end Else begin
      Result := Trunc(AValue) + 1;
    end;
  end;

function Color3i(ARed,AGreen,ABlue: GLInt): TPGLColorI;
	begin
  	Result.Red := ClampIColor(ARed);
    Result.Green := ClampIColor(AGreen);
    Result.Blue := ClampIColor(ABlue);
    Result.Alpha := 255;
  end;

function Color4i(ARed,AGreen,ABlue,AAlpha: GLInt): TPGLColorI;
	begin
  	Result.Red := ClampIColor(ARed);
    Result.Green := ClampIColor(AGreen);
    Result.Blue := ClampIColor(AGreen);
    Result.Alpha := ClampIColor(AAlpha);
  end;

function Color3f(ARed,AGreen,ABlue: GLFloat): TPGLColorF;
	begin
  	Result.Red := ClampFColor(ARed);
    Result.Green := ClampFColor(AGreen);
    Result.Blue := ClampFColor(ABlue);
    Result.Alpha := 1;
  end;

function Color4f(ARed,AGreen,ABlue,AAlpha: GLFloat): TPGLColorF;
  begin
	  Result.Red := (ARed);
    Result.Green := (AGreen);
    Result.Blue := (ABlue);
    Result.Alpha := (AAlpha);
  end;

function ColorItoF(AColor: TPGLColorI): TPGLColorF;
	begin
    Result.Red := AColor.Red / 255;
    Result.Green := AColor.Green / 255;
    Result.Blue := AColor.Blue / 255;
    Result.Alpha := AColor.Alpha / 255;
  end;

function ColorFtoI(AColor: TPGLColorF): TPGLColorI;
	begin
    Result.Red := PGLRound(AColor.Red * 255);
    Result.Green := PGLRound(AColor.Green * 255);
    Result.Blue := PGLRound(AColor.Blue * 255);
    Result.Alpha := PGLRound(AColor.Alpha * 255);
  end;


function CC(AColor: TPGLColorI): TPGLColorF;
  begin
    Result := ColorIToF(AColor);
  end;

function CC(AColor: TPGLColorF): TPGLColorI;
  begin
    result := ColorFToI(AColor);
  end;

function GetColorChangeIncrements(AStartColor, AEndColor: TPGLColorI; ACycles: Integer): TPGLColorI;
  begin

  end;


function GetColorChangeIncrements(AStartColor, AEndColor: TPGLColorF; ACycles: Integer): TPGLColorF;
Var
RDif,GDif,BDif,ADif: GLFloat;
  begin

    RDif := (AEndColor.Red - AStartColor.Red) / ACycles;
    GDif := (AEndColor.Green - AStartColor.Green) / ACycles;
    BDif := (AEndColor.Blue - AStartColor.Blue) / ACycles;
    ADif := (AEndColor.Alpha - AStartColor.Alpha) / ACycles;

    Result := Color4f(RDif,Gdif,BDif,ADif);
  end;


function ColorCombine(AColor1,AColor2: TPGLColorI): TPGLColorI;
  begin
    Result.Red := ClampIColor(AColor1.Red + AColor2.Red);
    Result.Green := ClampIColor(AColor1.Green + AColor2.Green);
    Result.Blue := ClampIColor(AColor1.Blue + AColor2.Blue);
    Result.Alpha := ClampIColor(AColor1.Alpha + AColor2.Alpha);
  end;

function ColorCombine(AColor1,AColor2: TPGLColorF): TPGLColorF;
  begin
    Result.Red := ClampFColor(AColor1.Red + AColor2.Red);
    Result.Green := ClampFColor(AColor1.Green + AColor2.Green);
    Result.Blue := ClampFColor(AColor1.Blue + AColor2.Blue);
    Result.Alpha := ClampFColor(AColor1.Alpha + AColor2.Alpha);
  end;

function ColorMultiply(AColor1,AColor2: TPGLColorI): TPGLColorI;
Var
Col1,Col2: TPGLColorF;
RColor: TPGLColorF;
  begin
    Col1 := CC(AColor1);
    Col2 := CC(AColor2);

    RColor.Red := (Col1.Red * Col2.Red);
    RColor.Green := (Col1.Green * Col2.Green);
    RColor.Blue := (Col1.Blue * Col2.Blue);
    RColor.Alpha := (Col1.Alpha * Col2.Alpha);
    Result := CC(RColor);
  end;


function ColorMultiply(AColor1,AColor2: TPGLColorF): TPGLColorF;
Var
RColor: TPGLColorF;
  begin
    RColor.Red := (AColor1.Red * AColor2.Red);
    RColor.Green := (AColor1.Green * AColor2.Green);
    RColor.Blue := (AColor1.Blue * AColor2.Blue);
    RColor.Alpha := (AColor1.Alpha * AColor2.Alpha);
    Result := RColor;
  end;

procedure ColorAdd(Out AColor: TPGLColorI; AAddColor: TPGLColorI; AAddAlphas: Boolean = True);
  begin
    AColor.Red := ClampIColor(AColor.Red + AAddColor.Red);
    AColor.Green := ClampIColor(AColor.Green + AAddColor.Green);
    AColor.Blue := ClampIColor(AColor.Blue + AAddColor.Blue);

    if AAddAlphas then begin
      AColor.Alpha := ClampIColor(AColor.Alpha + AAddColor.Alpha);
    end;
  end;

procedure ColorAdd(Out AColor: TPGLColorF; AAddColor: TPGLColorF; AAddAlphas: Boolean = True);
  begin
    AColor.Red := ClampFColor(AColor.Red + AAddColor.Red);
    AColor.Green := ClampFColor(AColor.Green + AAddColor.Green);
    AColor.Blue := ClampFColor(AColor.Blue + AAddColor.Blue);

    if AAddAlphas then begin
      AColor.Alpha := ClampFColor(AColor.Alpha + AAddColor.Alpha);
    end;
  end;


function ColorMix(AColor1,AColor2: TPGLColorI; AFactor: GLFloat): TPGLColorI;
Var
ColVal: GLInt;
  begin
    Result.Red := trunc((AColor1.Red + AColor2.Red) / 2);
    Result.Green := trunc((AColor1.Green + AColor2.Green) / 2);
    Result.Blue := trunc((AColor1.Blue + AColor2.Blue) / 2);
    Result.Alpha := trunc((AColor1.Alpha + AColor2.Alpha) / 2);
  end;


function PGLStringToChar(InString: String): TPGLCharArray;

Var
I: Long;
Len: Long;
CHR: TPGLCharArray;

  begin

    Len := Length(InString);
    SetLength(CHR,Len);

    for I := 0 To High(CHR) do begin
      CHR[i] := AnsiChar(InString[I + 1]);
    end;

    Result := CHR;

  end;


procedure PGLSaveTexture(Texture: GLUInt; Width,Height: GLUInt; FileName: String; MipLevel: GLUInt = 0);

Var
Pixels: Array of TPGLColorI;
I: Long;
FileChar: TPGLCharArray;
TexWidth, TexHeight: GLInt;

  begin

    if MipLevel > 0 then begin

      for I := 1 to MipLevel Do begin
        Width := trunc(Width / 2);
        Height := trunc(Height / 2);
      end;

    end;

    PGL.BindTexture(0,Texture);

    glGetTexLevelParameterIV(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, @TexWidth);
    glGetTexLevelParameterIV(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, @TexHeight);

    SetLength(Pixels,(Width * Height));

    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
    stbi_write_png(PAnsiChar(AnsiString(FileName)),Width,Height,4,Pixels,SizeOf(Pixels[0]) * TexWidth);

  end;


procedure PGLReplaceTextureColors(Textures: Array of TPGLTexture; Colors: Array of TPGLColorI; NewColor: TPGLColorI); register;
Var
Count: GLInt;
I,Z,R,T: Long;
Pixels: Array of TPGLColorI;

  begin

    // Replace all instances of COLORS in TEXTURES with NEWCOLOR

    Count := Length(Textures);

    for T := 0 to Count - 1 Do begin

      SetLength(Pixels, Textures[T].Width * Textures[T].Height);
      PGL.BindTexture(0,Textures[T].Handle);

      glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);

      for I := 0 to High(Pixels) Do begin

          for R := 0 to High(Colors) Do begin
            if Pixels[i].IsColor(Colors[r]) then begin
              Pixels[i] := NewColor;
            end;
          end;
      end;

      glTexImage2d(GL_TEXTURE_2D, 0, GL_RGBA, Textures[T].Width, Textures[T].Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, Pixels);

    end;
  end;


procedure PGLReplaceAllTexturesColors(Colors: Array of TPGLColorI; NewColor: TPGLColorI);
Var
Count: GLInt;
CurTex: TPGLTexture;
TexWidth, TexHeight: GLInt;
I,T,R: GLInt;
Pixels: Array of TPGLColorI;

  begin

    Count := Length(PGL.TextureObjects);

    for T := 0 to Count - 1 Do begin

      CurTex := PGL.TextureObjects[T];
      PGL.BindTexture(0,CurTex.Handle);
      TexWidth := CurTex.Width;
      TexHeight := CurTex.Height;

      SetLength(Pixels, TexWidth * TexHeight);
      glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE,Pixels);

      for I := 0 to High(Pixels) Do begin
        for R := 0 to High(Colors) Do begin
          if Pixels[I].IsColor(Colors[R]) then begin
            Pixels[I] := NewColor;
          end;
        end;
      end;

      glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,TexWidth,TexHeight,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);

    end;


  end;


procedure PGLSetEllipseInterval(Interval: GLInt = 10);
  begin
    if Interval < 1 then InterVal := 1;
    PGL.EllipsePointInterval := Interval;
  end;


function ImageDesc(Source: Pointer; Width,Height: GLUInt): TPGLImageDescriptor;
  begin
    Result.Handle := Source;
    Result.Width := Width;
    Result.Height := Height;
  end;

function PGLPixelFromMemory(Source: Pointer; X,Y,Width,Height: GLInt): TPGLColorI;
Var
IPtr: PByte;

  begin

     // Read pixels directly from Image memory location
    IPtr := Source;
    IPtr := IPtr + ((Y * trunc(Width) + X) * 4);

    Result.Red := Byte(IPtr^);
    inc(IPtr);
    Result.Green := Byte(IPtr^);
    inc(IPtr);
    Result.Blue := Byte(IPtr^);
    inc(IPtr);
    Result.Alpha := Byte(IPtr^);

    // ! Confirmed Slower !
    // Read pixels from Image data Array
    //Result := Self.Image.Data[ (Y * trunc(Self.Width)) + X];

  end;

procedure PGLResizeData(Var Data: Pointer; Width,Height,NewWidth,NewHeight: GLUint);
Var
OrgData: PByte;
DataCopy: PByte;
OrgLoc, CopyLoc: Integer;
UseWidth, UseHeight: GLUint;
I: Long;

  begin

    // Allocate memory for copy of the data and copy from original
    DataCopy := AllocMem((Width * Height) * 4);
    Move(Data^,DataCopy[0], 4 * (Width * Height));

    // Free the original and reallocate to the new size
    stbi_image_free(Data);
    Data := AllocMem(4 * (NewWidth * NewHeight));

    // Determine the dimensions to work with
    if Width <= NewWidth then begin
      UseWidth := Width;
    End Else begin
      UseWidth := NewWidth;
    end;

    if Height <= NewHeight then begin
      UseHeight := Height;
    End Else begin
      UseHeight := NewHeight;
    end;

    // set a pointer to the beginning of the original data
    OrgData := Data;
    OrgLoc := 0;
    CopyLoc := 0;

    // Move the relavent areas of the copy into the resized data
    for I := 0 to UseHeight - 1 Do begin
      Move(DataCopy[CopyLoc], OrgData[OrgLoc], UseWidth * 4);
      OrgLoc := OrgLoc + Integer((NewWidth * 4));
      CopyLoc := CopyLoc + Integer((Width * 4));
    end;

    // Free the copy
    FreeMem(DataCopy,(Width * Height) * 4);

  end;



function FindTextLineBreak(Var Text: String): Integer;

Var
LBPOS: Integer;

  begin

    Result := 0;

    // look for sLineBkreak
    LBPOS := POS(sLineBreak,Text);
    if LBPOS <> 0 then begin
      Result := LBPOS;
      Exit;
    end;

    // look for \n
    LBPOS := POS('\n',Text);
    if LBPOS <> 0 then begin
      Result := LBPOS;
      Exit;
    end;

  end;


function FindTextTags(Var Text:String): TPGLTextTagArray;

Var
Len: GLInt;
CurChar: GLInt;
ReadPos: GLint;
ReadChar: String;
TagReadString: String;
ParseStart, ParseEnd: GLInt;
ParseLength: GLInt;
TagStart,TagEnd: GLInt;
TagLocs: Array of Integer;
Tags: TPGLTextTagArray;
TagCount: GLint;
Done: boolean;
TagDone: Boolean;
I: Long;
FoundColor: Boolean;
IsColorI: boolean;
ColorVals: Array [0..3] of GLFloat;
ColorStart: GLint;
CurColor: GLInt;

  begin

    // Start Tags with <TAG>
    // End Tags with <END>
    // Tags = B - Bold, I - Italic, CI(###,###,###,####) - ColorI, CF(#,#,#,#) - ColorF
    // <TAG>B,I,C(255,255,255,255)<END>

    Len := Length(Text);
    CurChar := 1;
    Done := False;

    while Done = False Do begin

      // check if tags are present in string
      CurChar := Pos('<TAG>',Text,CurChar);

      // if not, exit
      if CurChar = 0 then begin
        Done := True;
        Break;
      end;

      // make sure its actually a tag start that was found
      if AnsiMidStr(Text,CurChar,5) = '<TAG>' then begin

        // Increase tag list by 1
        SetLength(Tags,Length(Tags) + 1);
        TagCount := Length(Tags);
        TagStart := CurChar;
        ParseStart := CurChar;
        TagDone := false;

        // Start the tag and the parsing at the found position
        while TagDone = False Do begin
          I := ParseStart;
          ReadPos := ParseStart;
          FoundColor := False;
          IsColorI := False;

            // read forward until new tag or end tag is found
            Repeat
              ReadChar := AnsiMidStr(Text,I,1);
              I := I + 1;
              ReadPos := ReadPos + 1;
            Until (ReadChar = ',') or (ReadChar = '<');

            if ReadChar = '<' then begin
              TagDone := True;
              Break;
            end;

            ParseLength := I - ParseStart;
            TagReadString := AnsiMidStr(Text,ParseStart,ParseLength); // Cache the tag read

            if TagReadString = 'B' then begin
              Tags[TagCount].Bold := True; // Check for Bold
            End Else if TagReadString = 'I' then begin
              Tags[TagCount].Italic := True; // check for Italics
            End Else begin
              // Else, look for color tags
              if ContainsText(Text,'CI') then begin
                IsColorI := True;
                FoundColor := True;
              End Else if ContainsText(Text,'CF') then begin
                IsColorI := False;
                FoundColor := True;
              end;

            end;


            // Get the color values if a color was found
            if FoundColor = True then begin

              // move start of parse forward to start of colors
              ColorStart := ParseStart + 8;
              ReadPos := ColorStart;
              CurColor := 0;
              I := ColorStart;

              // read forward and parse out colors
              while CurColor < 4 Do begin

                Repeat
                  ReadChar := AnsiMidStr(Text,I,1);
                  I := I + 1;
                  ReadPos := ReadPos + 1;
                Until (ReadChar = ',') or (ReadChar = ')');

                  // assign color found to color val array
                  ColorVals[CurColor] := AnsiMidStr(Text,ColorStart,I - ColorStart - 1).Tointeger;
                  ColorStart := I;
                  CurColor := Curcolor + 1;

                  // this is here to break early in case not enough colors were provided
                  if ReadChar = ')' then Break

              end;

              // Convert the color to floats if needed and assign to current tag
              if IsColorI = True then begin
                Tags[TagCount].Color := CC(Color4I(trunc(ColorVals[0]),trunc(ColorVals[1]),trunc(ColorVals[2]),trunc(ColorVals[2])));
              End Else begin
                Tags[TagCount].Color := Color4F(ColorVals[0],ColorVals[1],ColorVals[2],ColorVals[3]);
              end;

            end;

            ParseStart := ReadPos;

        end;


      end;



    end;

    Result := Tags;


  end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////// TPGLVector2///////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure TPGLVector2.MatrixMultuply(Mat: TPGLMatrix2);
Var
X,Y: Single;
  begin
    X := Self.X;
    Y := Self.Y;
    Self.X := (Mat.M[0,0] * X) + (Mat.M[0,1] * Y);
    Self.Y := (Mat.M[1,0] * X) + (Mat.M[1,1] * Y);
  end;

procedure TPGLVector2.Translate(X: Single; Y: Single);
  begin
      Self.X := Self.X + X;
      Self.Y := Self.Y + Y;
  end;

procedure TPGLVector2.Rotate(Angle: Single);
  begin
    Self.MatrixMultuply(PGLMat2Rotation(Angle));
  end;

procedure TPGLVector2.Scale(sX: Single; sY: Single);
  begin
    Self.X := BX(Self.X,sX);
    Self.Y := BY(Self.Y,sY);
  end;


procedure TPGLVector2.Normalize(Origin: TPGLVector2);

Var
Dist: Single;

  begin
    Dist := Sqrt( IntPower(Self.Y - Origin.Y,2) + IntPower(Self.X - Origin.X,2));
    Self.X := (Self.X - Origin.X) / Dist;
    Self.y := (Self.Y - Origin.Y) / Dist;
  end;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////// TPGLVector3 //////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class operator TPGLVector3.Subtract(A: TPGLVector3; B: TPGLVector3): TPGLVector3;
  begin
    Result := Vec3(A.X - B.X, A.Y - B.Y, A.Z - B.Z);
  end;


procedure TPGLVector3.Normalize();
Var
Len: GLFloat;

  begin
    Len := Sqrt( (Self.X * Self.X) + (Self.Y * Self.Y) + (Self.Z * Self.Z));
    Self.X := Self.X / Len;
    Self.Y := Self.Y / Len;
    Self.Z := Self.Z / Len;
  end;


procedure TPGLVector3.Cross(Vec: TPGLVector3);
Var
RVec: TPGLVector3;

  begin
    RVec.X := (Self.Y * Vec.Z) - (Self.Z * Vec.Y);
    RVec.Y := (Self.Z * Vec.X) - (Self.X * Vec.Z);
    RVec.Z := (Self.X * Vec.Y) - (Self.Y * Vec.X);
  end;


procedure TPGLVector3.MatrixMultiply(Mat: TPGLMatrix3);
Var
X,Y,Z: Single;
  begin
    X := Self.X;
    Y := Self.Y;
    Z := Self.Z;
    Self.X := (Mat.M[0] * X) + (Mat.M[3] * Y) + (Mat.M[6] * Z);
    Self.Y := (Mat.M[1] * X) + (Mat.M[4] * Y) + (Mat.M[7] * Z);
    Self.Z := (Mat.M[2] * X) + (Mat.M[5] * Y) + (Mat.M[8] * Z);
  end;

procedure TPGLVector3.Translate(X: Single = 0; Y: Single = 0; Z: Single = 0);
  begin
    Self.X := Self.X + X;
    Self.Y := Self.Y + Y;
    Self.Z := Self.Z + Z;
  end;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////// pglVectorCube////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////




////////////////////////////////////////////////////////////////////////////////
////////////////////////////// TPGLMatrix3///////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure TPGLMatrix3.Fill(Values: Array of GLFloat);
Var
FillCount: GLInt;
I: Long;

  begin

    if Length(Values) >= 9 then begin
      FillCount := 9;
    End Else begin
      FillCount := Length(Values);
    end;

    for I := 0 to FillCount - 1 Do begin
      Self.M[I] := Values[I];
    end;

  end;


function TPGLMatrix3.Val(X,Y: GLUint): GLFloat;
  begin
    Result := Self.M[(X * 3) + Y];
  end;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////// TPGLMatrix2///////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure TPGLMatrix2.MakeRotation(Angle: Single);
  begin
    Self := PGLMat2Rotation(Angle);
  end;

procedure TPGLMatrix2.MakeTranslation(X: Single; Y: Single);
  begin
    Self := PGLMat2Translation(X,Y);
  end;

procedure TPGLMatrix2.MakeScale(sX,sY: GLFloat);
  begin
    Self := PGLMat2Scale(sX,sY);
  end;

procedure TPGLMatrix2.Rotate(Angle: Single);
  begin
    Self := PGLMat2Multiply(Self,PGLMat2Rotation(Angle));
  end;

procedure TPGLMatrix2.Translate(X: Single; Y: Single);
  begin
    Self := PGLMat2Multiply(Self,PGLMat2Translation(X,Y));
  end;

procedure TPGLMatrix2.Scale(sX: Single; sY: Single);
  begin
    Self := PGLMat2Multiply(Self,PGLMat2Scale(sX,sY));
  end;

//////////////////////////  Callback Placeholders //////////////////////////////
procedure ReSizeFuncPlaceHolder();
  begin
  end;

//////////////////////////  MATH functionS //////////////////////////////

function PGLRound(inVal: GLFloat): GLInt;

Var
Rem: GLFloat;
Val: GLInt;

	begin
    Val := trunc(inVal);
    Rem := inVal - Val;

    if Rem > 0.5 then begin
      Result := Val + 1;
    End Else begin
    	Result := Val;
    end;

  end;


function PGLMatrixIdentity(): TPGLMatrix4;
  begin
    Result.M[0] := 1; Result.M[4] := 0; Result.M[8] := 0; Result.M[12] := 0;
    Result.M[1] := 0; Result.M[5] := 1; Result.M[9] := 0; Result.M[13] := 0;
    Result.M[2] := 0; Result.M[6] := 0; Result.M[10] := 0; Result.M[14] := 0;
    Result.M[3] := 0; Result.M[7] := 0; Result.M[11] := 0; Result.M[15] := 1;
  end;


function PGLMatrixRotation(Out Mat: TPGLMatrix4; inAngle,X,Y: GLFloat): Boolean;
  begin
    Mat.M[0] := cos(inAngle); Mat.M[4] := sin(inAngle); Mat.M[8] := 0; Mat.M[12] := 0;
    Mat.M[1] := -sin(inAngle); Mat.M[5] := cos(inAngle); Mat.M[9] := 0; Mat.M[13] := 0;
    Mat.M[2] := 0; Mat.M[6] := 0; Mat.M[10] := 0; Mat.M[14] := 0;
    Mat.M[3] := 0; Mat.M[7] := 0; Mat.M[11] := 0; Mat.M[15] := 1;
    Result := True;
  end;

function PGLMatrixScale(Out Mat: TPGLMatrix4; W,H: GLFloat): Boolean;
Var
ScaleX,ScaleY: GLFloat;
  begin

    if w > h then begin
      ScaleX := 2 / W;
      ScaleY := ScaleX * (w/h);
    End Else begin
      ScaleY := 2 / H;
      ScaleX := ScaleY * (h/w);
    end;

    Mat.M[0] := ScaleX; Mat.M[4] := 0; Mat.M[8] := 0; Mat.M[12] := 0;
    Mat.M[1] := 0; Mat.M[5] := ScaleY; Mat.M[9] := 0; Mat.M[13] := 0;
    Mat.M[2] := 0; Mat.M[6] := 0; Mat.M[10] := 0; Mat.M[14] := 0;
    Mat.M[3] := 0; Mat.M[7] := 0; Mat.M[11] := 0; Mat.M[15] := 1;
    Result := true;
  end;

function PGLMatrixTranslation(Out Mat: TPGLMatrix4; X,Y: GLFloat): Boolean;
  begin
    Mat.M[0] := 1; Mat.M[4] := 0; Mat.M[8] := 0; Mat.M[12] := x;
    Mat.M[1] := 0; Mat.M[5] := 1; Mat.M[9] := 0; Mat.M[13] := y;
    Mat.M[2] := 0; Mat.M[6] := 0; Mat.M[10] := 0; Mat.M[14] := 1;
    Mat.M[3] := 0; Mat.M[7] := 0; Mat.M[11] := 0; Mat.M[15] := 1;
    Result := true;
  end;


function PGLMat2Rotation(Angle: GLFloat): TPGLMatrix2;
  begin
    Result.M[0,0] := cos(Angle);  Result.M[0,1] := -sin(Angle);
    Result.M[1,0] := sin(Angle); Result.M[1,1] := cos(Angle);
  end;

function PGLMat2Translation(X,Y: GLFloat): TPGLMatrix2;
  begin
    Result.M[0,0] := X; Result.M[0,1] := 0;
    Result.M[1,0] := 0; Result.M[1,1] := Y;
  end;

function PGLMat2Scale(sX,sY: GLFloat): TPGLMatrix2;
  begin
    Result.M[0,0] := BX(1,sX); Result.M[0,1] := 0;
    Result.M[1,0] := 0;        Result.M[1,1] := BY(1,sY);
  end;

function PGLMat2Multiply(Mat1,Mat2: TPGLMatrix2): TPGLMatrix2;
Var
Rows, Cols, L: Integer;
I, J: Integer;
Sum: Double;
K: Integer;

  begin
    Rows := 2;
    Cols := 2;
    L := 2;

    for i := 0 to Rows - 1 Do begin
      for j := 0 to Cols - 1 Do begin

        Sum := 0.0;
        for k := 0 to l - 1 Do begin
          Sum := Sum + (Mat1.M[i , k] * Mat2.M[k , j]);
          Result.M[i , j] := Sum;
        end;

      end;
    end;

  end;


function PGLMat3Multiply(Mat1,Mat2: TPGLMatrix3): TPGLMatrix3;
Var
I,Z,C: Long;

  begin

    for I := 0 to 2 Do begin
        C := (I * 3) + 0;
        Result.M[C] := (Mat1.M[C] * Mat2.Val(0,I)) + (Mat1.M[C] * Mat2.Val(1,I)) + (Mat1.M[C] * Mat2.VAl(2,I));
        C := (I * 3) + 1;
        Result.M[C] := (Mat1.M[C] * Mat2.Val(0,I)) + (Mat1.M[C] * Mat2.Val(1,I)) + (Mat1.M[C] * Mat2.VAl(2,I));
        C := (I * 3) + 2;
        Result.M[C] := (Mat1.M[C] * Mat2.Val(0,I)) + (Mat1.M[C] * Mat2.Val(1,I)) + (Mat1.M[C] * Mat2.VAl(2,I));
    end;

  end;


function PGLMatToVec(Mat: TPGLMatrix2): TPGLVector2;
  begin
    Result := Vec2(0,0);
  end;


function PGLVectorCross(VecA, VecB: TPGLVector3): TPGLVector3;
  begin
    Result.X := (VecA.Y * VecB.Z) - (VecA.Z * VecB.Y);
    Result.Y := (VecA.Z * VecB.X) - (VecA.X * VecB.Z);
    Result.Z := (VecA.X * VecB.Y) - (VecA.Y * VecB.X);
  end;

// Transform Points to Screen Coordinates
function SX(inVal: GLFloat): GLFloat;
  begin
    Result := -1 + ((inVal / PGL.Window.Width) * 2);
  end;

function SY(inVal: GLFloat): GLFloat;
  begin
    Result := 1 - ((inVal / PGL.Window.Height) * 2);
  end;

// Transform Points to Buffer Coordinates
function BX(inVal,BuffWidth: GLFloat): GLFloat;
  begin
    Result := -1 + ((inVal / BuffWidth) * 2);
  end;

function BY(inVal,BuffHeight: GLFloat): GLFloat;
  begin
    Result := 1 - ((inVal / BuffHeight) * 2);
  end;

// Transform Points to Texture Coordinates
function TX(inVal,TexWidth: GLFloat): GLFloat;
  begin
    Result := InVal / TexWidth;
  end;

function TY(inVal,TexHeight: GLFloat): GLFloat;
  begin
    Result := InVal / TexHeight;
  end;

procedure TransformToScreen(Out Points: TPGLVectorQuad);
  begin
    Points[0] := vec2(sx(Points[0].X), sy(Points[0].Y));
    Points[1] := vec2(sx(Points[1].X), sy(Points[1].Y));
    Points[2] := vec2(sx(Points[2].X), sy(Points[2].Y));
    Points[3] := vec2(sx(Points[3].X), sy(Points[3].Y));
  end;


procedure TransformToBuffer(Out Points: TPGLVectorQuad; BuffWidth,BuffHeight: GLFloat);
  begin
    Points[0] := vec2(BX(Points[0].X,BuffWidth), BY(Points[0].Y,BuffHeight));
    Points[1] := vec2(BX(Points[1].X,BuffWidth), BY(Points[1].Y,BuffHeight));
    Points[2] := vec2(BX(Points[2].X,BuffWidth), BY(Points[2].Y,BuffHeight));
    Points[3] := vec2(BX(Points[3].X,BuffWidth), BY(Points[3].Y,BuffHeight));
  end;


procedure TransformToTexture(Out Points: TPGLVectorQuad; TexWidth,TexHeight: GLFloat);
  begin
    Points[0] := vec2(TX(Points[0].X,TexWidth), TY(Points[0].Y,TexHeight));
    Points[1] := vec2(TX(Points[1].X,TexWidth), TY(Points[1].Y,TexHeight));
    Points[2] := vec2(TX(Points[2].X,TexWidth), TY(Points[2].Y,TexHeight));
    Points[3] := vec2(TX(Points[3].X,TexWidth), TY(Points[3].Y,TexHeight));
  end;

////////////////////////////////////////////////////////////////////////////////
////////////////// Shader functions ////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

function PGLGetUniform(Uniform: String): GLInt;

var
R: GLInt;
Chars: TPGLCharArray;

  begin

    if CurrentProgram = nil then begin
      PGLAddError('Could not retieve uniform location. No shader program currently used!');
      Result := -1;
      Exit;
    end;

    Result := CurrentProgram.SearchUniform(Uniform);

    if Result = -1 then begin
      Chars := PGLStringToChar(Uniform);
      Result := glGetUniformLocation(CurrentProgram.ShaderProgram,PAnsiChar(AnsiString(Uniform)));

      if Result <> -1 then begin
        CurrentProgram.AddUniform(Uniform,Result);
      end;

    End Else begin
      Result := Result;
    end;

  end;


//////////////////////// PGL State Context ///////////////////////////////

class operator TPGLState.Initialize(Out Dest: TPGLState);
  begin
    Dest.GlobalLight := 1;
    Dest.EllipsePointInterval := 10;
  end;

procedure TPGLState.GetInputDevices(var KeyBoard: TPGLKeyboard; var Mouse: TPGLMouse; var Controller: TPGLController);
  begin
    KeyBoard := Self.Context.Keyboard;
    Mouse := Self.Context.Mouse;
    Controller := Self.Context.Controller;
  end;

procedure TPGLState.UpdateWindowBounds();
  begin
    glViewPort(0,0,PGL.Window.Width,PGL.Window.Height);
  end;


procedure TPGLState.SetDefaultMaskColor(Color: TPGLColorI);
  begin
    Self.DefaultMaskColor := ColorItoF(Color);
  end;


procedure TPGLState.DestroyImage(Var Image: TPGLImage);
  begin
    if Assigned(Image) = False then Exit;

    if Image.pHandle <> Nil then begin
//      Image.Delete();
      FreeMemory(Image.pHandle);
      Image.pHandle := nil;
    end;

    Image.Destroy();
  end;


procedure TPGLState.AddDefaultColorReplace(Color: TPGLColorI; NewColor: TPGLColorI);
  begin
    SetLength(Self.DefaultReplace,Length(Self.DefaultReplace) + 1 );
    Self.DefaultReplace[High(Self.DefaultReplace),0] := Color;
    Self.DefaultReplace[High(Self.DefaultReplace),1] := NewColor;
  end;

procedure TPGLState.AddRenderTexture(Source: TPGLRenderTexture);
  begin
    SetLength(Self.RenderTextures,Length(Self.RenderTextures) + 1);
    Self.RenderTextures[High(Self.RenderTextures)] := Source;
  end;

procedure TPGLState.AddTextureObject(var TexObject: TPGLTexture);
  begin
    SetLength(Self.TextureObjects,Length(Self.TextureObjects) + 1);
    Self.TextureObjects[High(Self.TextureObjects)] := TexObject;
  end;

procedure TPGLState.RemoveTextureObject(var TexObject: TPGLTexture);
Var
I: Long;
Sel: Long;

  begin

    Sel := 0;

    for I := 0 to High(Self.TextureObjects) Do begin
      if Self.TextureObjects[I] = TexObject then begin
        Sel := I;
        Break;
      end;
    end;


    for I := Sel to High(Self.TextureObjects) - 1 Do begin
      Self.TextureObjects[I] := Self.TextureObjects[I+1];
    end;

    Self.TextureObjects[High(Self.TextureObjects)] := Nil;
    SetLength(Self.TextureObjects,High(Self.TextureObjects));

  end;

procedure TPGLState.UpdateViewPort(X,Y,W,H: GLInt);
  begin
    Self.ViewPort.Width := W;
    Self.ViewPort.Height := H;
    Self.ViewPort.X := trunc(Self.ViewPort.Width / 2);
    Self.ViewPort.Y := trunc(Self.ViewPort.Height / 2);
    Self.ViewPort.Update(FROMCENTER);
  end;


procedure TPGLState.GenTexture(var Texture: Cardinal);

  begin
    glGenTextures(1,@Texture);
    SetLength(Self.TExtures,Length(Self.Textures)+1);
    Self.Textures[High(Self.Textures)] := Texture;
  end;


procedure TPGLState.DeleteTexture(var Texture: Cardinal);
Var
I: Long;
Index: Long;

  begin

    Index := -1;

    for I := 1 to High(Self.Textures) Do begin
      if Self.Textures[i] = Texture then begin
        glDeleteTextures(1,@Texture);
        Index := I;
        Break;
      end;
    end;

    if Index = -1 then Exit; // because no texture was found to destroy

    for I := Index to High(Self.Textures) - 1 Do begin
      Self.Textures[i] := Self.Textures[i+1];
    end;

    SetLength(Self.Textures,Length(Self.Textures) - 1);

  end;


procedure TPGLState.BindTexture(TextureUnit: GLUInt; Texture: GLUInt);
  begin

    if Self.TexUnit[TextureUnit] <> Texture then begin
      glActiveTexture(GL_TEXTURE0 + TextureUnit);
      glBindTexture(GL_TEXTURE_2D,texture);
    end;

  end;


procedure TPGLState.UnBindAll();
Var
I: Long;

  begin

    for I := 0 to 31 Do begin
      PGL.BindTexture(I,0);
    end;

  end;


procedure TPGLState.UnBindTexture(TexName: Cardinal);

Var
I: Long;

  begin

    for I := 0 to 31 Do begin

      if PGL.TexUnit[i] = TexName then begin
        PGL.BindTexture(i,0);
      end;

    end;

  end;


procedure TPGLState.VBOSubData(Binding: glEnum; OffSet: GLInt; Size: GLInt; Source: Pointer);
  begin
    Self.CurrentBufferCollection.CurrentVBO.SubData(binding,offset,size,source);
  end;

procedure TPGLState.SSBOSubData(Binding: glEnum; OffSet: GLInt; Size: GLInt; Source: Pointer);
  begin
    Self.CurrentBufferCollection.CurrentSSBO.SubData(binding,offset,size,source);
  end;

function TPGLState.GetNextVBO(): GLInt;
  begin
    Result := Self.CurrentBufferCollection.GetNextVBO;
  end;

function TPGLState.GetNextSSBO(): GLInt;
  begin
    Result := Self.CurrentBufferCollection.GetNextSSBO;
  end;



function TPGLState.GetTextureCount: NativeUInt;

  begin
    Result := High(Self.Textures);
  end;


//////////////////////////////////////////////////////////////////////////////
//////////////////////////////TPGLBufferCollection/////////////////////////////
//////////////////////////////////////////////////////////////////////////////

class operator TPGLBufferCollection.Initialize(Out Dest: TPGLBufferCollection);

Var
I: Long;

  begin
    // create the vertex array and buffer objects
    glGenVertexArrays(1,@Dest.VAO);
    glBindVertexArray(Dest.VAO);

    glGenBuffers(1,@Dest.EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,Dest.EBO);


    for I := 0 to High(Dest.VBO) do begin
      glGenBuffers(1,@Dest.VBO[i].Buffer);
      glBindBuffer(GL_ARRAY_BUFFER,Dest.VBO[i].Buffer);
      glBufferData(GL_ARRAY_BUFFER,Dest.BufferSize,nil,GL_STREAM_DRAW);
      glBindBuffer(GL_ARRAY_BUFFER,0);
      Dest.VBO[i].InUse := false;
    end;

    for I := 0 to High(Dest.SSBO) do begin
      glGenBuffers(1,@Dest.SSBO[i].Buffer);
      glBindBuffer(GL_ARRAY_BUFFER,Dest.SSBO[i].Buffer);
      glBufferData(GL_ARRAY_BUFFER,Dest.BufferSize,nil,GL_STREAM_DRAW);
      glBindBuffer(GL_ARRAY_BUFFER,0);
      Dest.SSBO[i].InUse := False;
    end;

    Dest.VBOInc := 0;
    Dest.SSBOInc := 0;

  end;

procedure TPGLBufferCollection.Bind();
  begin
      glBindVertexArray(Self.VAO);
      Self.InvalidateBuffers();
      PGL.CurrentBufferCollection := @Self;
  end;

procedure TPGLBufferCollection.BindVBO(N: Cardinal);
  begin
    glBindBuffer(GL_ARRAY_BUFFER,Self.VBO[N].Buffer);
    Self.CurrentVBO := @Self.VBO[N];
  end;

procedure TPGLBufferCollection.BindSSBO(N: Cardinal);
  begin
    glBindBuffer(GL_SHADER_STORAGE_BUFFER,Self.SSBO[N].Buffer);
    Self.CurrentSSBO := @Self.SSBO[N];
  end;

procedure TPGLBufferCollection.InvalidateBuffers();
Var
I: Long;

  begin

    for I := 0 to High(Self.VBO) Do begin
      if Self.VBO[i].InUse = True then begin
//        glInvalidateBufferSubData(Self.VBO[i].Buffer,Self.VBO[i].SubDataOffset,Self.VBO[i].SubDataSize);
        glInvalidateBufferData(Self.VBO[i].Buffer);
        Self.VBO[i].InUse := False;
      end;

      if Self.SSBO[i].InUse = True then begin
//        glInvalidateBufferSubData(Self.SSBO[i].Buffer,Self.SSBO[i].SubDataOffset,Self.SSBO[i].SubDataSize);
        glInvalidateBufferData(Self.SSBO[i].Buffer);
        Self.SSBO[i].InUse := False;
      end;

    end;

  end;


function TPGLBufferCollection.GetNextVBO(): GLUInt;
Var
I: Long;

  begin
    inc(Self.VBOInc);
    if Self.VBOInc > High(SElf.VBO) then begin
      Self.VBOInc := 0;
    end;

    I := Self.VBOinc;

    Result := I;
    Self.VBO[i].InUse := TRue;
    Self.CurrentVBO := @Self.VBO[i];
    Exit;
  end;

function TPGLBufferCollection.GetNextSSBO(): GLUInt;
Var
I: Long;
  begin
    inc(Self.SSBOInc);
    if Self.SSBOInc > High(SElf.SSBO) then begin
      Self.SSBOInc := 0;
    end;

    I := Self.SSBOInc;

    Result := I;
    Self.SSBO[i].InUse := TRue;
    Self.CurrentSSBO := @Self.SSBO[i];
  end;


//////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// TPGLVBO ///////////////////////////////////
//////////////////////////////////////////////////////////////////////////////


procedure TPGLVBO.SubData(Binding: glEnum; Offset: GLInt; Size: GLInt; Source: Pointer);
  begin
    Self.SubDataOffSet := OffSet;
    Self.SubDataSize := Size;

    glBufferSubData(Binding,Offset,Size,Source);
  end;


//////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// TPGLSSBO //////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

procedure TPGLSSBO.SubData(Binding: glEnum; Offset: GLInt; Size: GLInt; Source: Pointer);
  begin
    Self.SubDataOffSet := OffSet;
    Self.SubDataSize := Size;

    glBufferSubData(Binding,Offset,Size,Source);
//    glBufferData(Binding,Size,Source,GL_STREAM_DRAW);
  end;


//////////////////////////////////////////////////////////////////////////////
//////////////////////////////TPGLRenderTarget/////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
constructor TPGLRenderTarget.Create(inWidth,inHeight: GLInt);

Var
I: GLInt;
CheckVar: glEnum;
Buff: Pointer;

	begin
    // set bounds and positions
    Self.pWidth := inWidth;
    Self.pheight := inHeight;

    PGLMatrixRotation(Self.Rotation,0,0,0);
    PGLMatrixScale(Self.Scale,1,1);
    PGLMatrixTranslation(Self.Translation,(Self.Width / 2), (Self.Height / 2));

    Self.SetClearColor(pgl_empty);
    Self.SetClearAllBuffers(True);
    Self.SetColorValues(Color3i(255,255,255));
    Self.SetColorOverlay(Color4i(0,0,0,0));
    Self.GreyScale := False;
    Self.MonoChrome := False;
    Self.SetBrightness(1);

    Self.Points.Count := 0;
    Self.Circles.Count := 0;
    Self.Polys.Count := 0;
    Self.LightPolygons.count := 0;
    Self.DrawState := '';

    Self.Cor[0] := Vec2(0,0);
    Self.Cor[1] := Vec2(1,0);
    Self.Cor[2] := Vec2(1,1);
    Self.Cor[3] := Vec2(0,1);

    Self.SetRenderRect(RectI(0,0,inWidth,inHeight));
    Self.SetClipRect(RectI(0,0,inWidth,inheight));

    Self.Indices[0] := 0;
    Self.Indices[1] := 1;
    Self.Indices[2] := 3;
    Self.Indices[3] := 1;
    Self.Indices[4] := 2;
    Self.Indices[5] := 3;

    Self.SetOnResizeEvent(ReSizeFuncPlaceHolder);

    Self.ClearRect := glDrawMain.RectF(0,0,Self.Width,Self.Height);
    Self.SetDrawOffSet(Vec2(0,0));
    Self.TextureBatch.Clear();
    Self.Polys.shapecount := 0;

  end;


procedure TPGLRenderTarget.FillEBO();
Var
I: Long;
  begin
    for I := 0 to 1000 Do begin
      Self.TextureBatch.Indices[I].Index[0] := 0 + (4 * (I));
      Self.TextureBatch.Indices[I].Index[1] := 1 + (4 * (I));
      Self.TextureBatch.Indices[I].Index[2] := 2 + (4 * (I));
      Self.TextureBatch.Indices[I].Index[3] := 0 + (4 * (I));
      Self.TextureBatch.Indices[I].Index[4] := 2 + (4 * (I));
      Self.TextureBatch.Indices[I].Index[5] := 3 + (4 * (I));
    end;

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,Self.Buffers.EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER,SizeOf(TPGLIndices) * 1001,@Self.TextureBatch.Indices,GL_STREAM_DRAW);
  end;


procedure TPGLRenderTarget.MakeCurrentTarget();
  begin

    if PGL.CurrentRenderTarget <> Self.FrameBuffer then begin
      glBindFrameBuffer(GL_FRAMEBUFFER,Self.FrameBuffer);
      PGL.CurrentRenderTarget := Self.FrameBuffer;
    end;

    if Self.ClassType = TPGLWindow then begin
      glViewPort(0,0,TPGLWindow(Self).Width,TPGLWindow(Self).Height);
      PGL.UpdateViewPort(0,0,TPGLWindow(Self).Width,TPGLWindow(Self).Height);
    End Else begin
      glViewPort(0,0,Self.Width,Self.Height);
      PGL.UpdateViewPort(0,0,Self.Width,Self.Height);
    end;

  end;


procedure TPGLRenderTarget.CopyToTexture(SrcX: Cardinal; SrcY: Cardinal; SrcWidth: Cardinal; SrcHeight: Cardinal; DestTexture: Cardinal);

Var
Ver: TPGLVectorQuad;
Cor: TPGLVectorQuad;

  begin

    Ver[0] := vec2(SrcX, SrcY + SrcHeight);
    Ver[1] := vec2(SrcX + SrcWidth, SrcY + SrcHeight);
    Ver[2] := vec2(SrcX + SrcWidth, SrcY);
    Ver[3] := vec2(SrcX, SrcY);

    Cor[0] := vec2(0,1);
    Cor[1] := vec2(1,1);
    Cor[2] := vec2(1,0);
    Cor[3] := vec2(0,0);

    pglCopyBuffer.SetSize(SrcWidth,SrcHeight);
    glBindFramebuffer(GL_FRAMEBUFFER,pglCopyBuffer.FrameBuffer);
    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,DestTexture,0);

    TPGLRenderTexture(Self).StretchBlt(pglCopyBuffer,0,SrcHeight,SrcWidth,-SrcHeight,SrcX, SrcY, SrcWidth, SrcHeight);


  end;


procedure CopyToImage2(Source: TPGLRenderTarget; Dest: TPGLImage; SourceRect, DestRect: TPGLRectI);
Var
Ver: TPGLVectorQuad;
Cor: TPGLVectorQuad;
PixelBuffer: GLUint;
Buffer: PByte;
BufferSize: GLInt;
NewBuffer: Array of Byte;

  begin

    Ver := SourceRect.ToPoints;
    TransformToBuffer(Ver,Source.Width,Source.Height);
    Cor := DestRect.ToPoints;
    TransformToTexture(Cor,Dest.Width, Dest.Height);
    FlipPoints(Cor);

    BufferSize := (Source.Width * Source.Height) * 4;
    Buffer := GetMemory(BufferSize);

    Source.MakeCurrentTarget();
    Source.Buffers.Bind();

    PGL.BindTexture(0,Source.Texture2D);

    glGenBuffers(1,@PixelBuffer);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER,PixelBuffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER,BufferSize,Buffer,GL_DYNAMIC_DRAW);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,2,PixelBuffer);

    FreeMemory(Buffer);

    Source.Buffers.BindVBO(0);
    Source.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(Ver),@Ver);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Source.Buffers.BindVBO(1);
    Source.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(Cor),@Cor);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    glUniform1i(PGLGetUniform('tex'),0);

    PGLUseProgram('PixelTransfer');

    glDrawArrays(GL_QUADS,0,4);

    glDeleteBuffers(1,@PixelBuffer);

  end;


procedure TPGLRenderTarget.CopyToImage(Dest: TPGLImage; SourceRect, DestRect: TPGLRectI);
Var
I,Z: GLInt;
OrgPixels: PByte;
PixelCount: GLInt;
ImgPtr: PByte;
ImgLoc: GLInt;
WidthRatio, HeightRatio: GLFloat;

  begin

    CopytoImage2(Self,Dest,SourceRect,DestRect);
    Exit;

    Self.DrawLastBatch();

    // Get Pixel Data from Render Target frame buffer
    Self.MakeCurrentTarget();
    OrgPixels := GetMemory((SourceRect.Width * SourceRect.Height) * 4);
    glReadPixels(SourceRect.Left, SourceRect.Top, SourceRect.Width, SourceRect.Height, GL_RGBA,
      GL_UNSIGNED_BYTE, OrgPixels);

    // Transfer to Image
    PixelCount := 0;
    ImgPtr := Dest.Handle;
    ImgLoc := 0;

    if (SourceRect.Width <> DestRect.Width) and (SourceRect.Height <> DestRect.Height) then begin
      // if Width and Heights are not the same, go one pixel at a time
      // Get rations between widths and heights
      WidthRatio := SourceRect.Width / DestRect.Width;
      HeightRatio := SourceRect.Height / DestRect.Height;

      for Z := 0 to DestRect.Height - 1 Do begin
        for I := 0 to DestRect.Width - 1 Do begin
          Move(OrgPixels[PixelCount], ImgPtr[ImgLoc], 4);
          Inc(PixelCount,4);
          Inc(ImgLoc,4);
        end;
      end;

    End Else begin
      // if Width and Heights are the same, copy row by row
      for I := 0 to DestRect.Height - 1 Do begin
        Move(orgPixels[PixelCount], ImgPtr[ImgLoc], 4 * (DestRect.Width));
        Inc(PixelCount, 4 * DestRect.Width);
        Inc(ImgLoc, 4 * (DestRect.Width));
      end;

    end;

    FreeMemory(OrgPixels);

  end;

procedure TPGLRenderTarget.UpdateFromImage(Source: TPGLImage; SourceRect: TPGLRectI);
Var
I,Z,X,Y: Long;
Buffer: PByte;
SourcePtr: PByte;
SourceLoc, BufferLoc: Integer;

  begin

    // Allocate Memory to Buffer
    Buffer := GetMemory((SourceRect.Width * SourceRect.Height) * 4);
    BufferLoc := 0;

    // Get pointer to source handle, location starting byte of rect in source data
    SourcePtr := Source.Handle;
    SourceLoc := ( (Source.Width * SourceRect.Top) + SourceRect.Left) * 4;

    // transfer source data to buffer one row at a time
    for I := 0 to SourceRect.Height - 1 Do begin
      Move(SourcePtr[SourceLoc], Buffer[BufferLoc], 4 * (SourceRect.Width));
      BufferLoc := BufferLoc + (SourceRect.Width * 4);
      SourceLoc := SourceLoc + (Source.Width * 4);
    end;

    // Update framebuffer attachment with buffer data
    Self.MakeCurrentTarget();
    PGL.BindTexture(0,Self.Texture2D);
    glTexSubImage2D(GL_TEXTURE_2D, 0, SourceRect.Left, SourceRect.Top, SourceRect.Width, SourceRect.Height,
      GL_RGBA, GL_UNSIGNED_BYTE, Buffer);

    // Free buffer memory
    FreeMem(Buffer, (SourceRect.Width * SourceRect.Height) * 4);
    Buffer := nil;
    SourcePtr := nil;

  end;


procedure TPGLRenderTarget.SetRenderRect(inRect: TPGLRectI);
Var
TempRect: TPGLRectF;
  begin

    Self.RenderRect := RectF(Vec2(inRect.x,inRect.y),inRect.Width,inRect.Height);
    Self.UpdateVertices();
  end;

procedure TPGLRenderTarget.SetRenderRect(inRect: TPGLRectF);
  begin
    Self.RenderRect := inRect;
    Self.UpdateVertices();
  end;

procedure TPGLRenderTarget.SetClipRect(inRect: TPGLRectI);
  begin
    Self.ClipRect := RectF(Vec2(inRect.X,inRect.Y), inRect.Width, inRect.Height);
    Self.UpdateCorners;
  end;

procedure TPGLRenderTarget.SetClipRect(inRect: TPGLRectF);
  begin
    Self.ClipRect := inRect;
    Self.UpdateCorners;
  end;


procedure TPGLRenderTarget.UpdateVertices;
  begin
    // Update Screen Space Corners
    Self.Ver[0] := Vec2(-Self.RenderRect.Width / 2, -Self.RenderRect.Height / 2);
    Self.Ver[1] := Vec2(Self.RenderRect.Width / 2, -Self.RenderRect.Height / 2);
    Self.Ver[2] := Vec2(Self.RenderRect.Width / 2, Self.RenderRect.Height / 2);
    Self.Ver[3] := Vec2(-Self.RenderRect.Width / 2, Self.RenderRect.Height / 2);
  end;

procedure TPGLRenderTarget.UpdateCorners();
  begin
    // Update Clipping Corners
    Self.Cor[0] := Vec2((ClipRect.Left) / Self.Width,  (ClipRect.Top) / Self.Height);
    Self.Cor[1] := Vec2((ClipRect.Right) / Self.Width, (ClipRect.Top) / Self.Height);
    Self.Cor[2] := Vec2((ClipRect.Right) / Self.Width, (ClipRect.Bottom) / Self.Height);
    Self.Cor[3] := Vec2((ClipRect.Left) / Self.Width,  (ClipRect.Bottom) / Self.Height);
  end;


procedure TPGLRenderTarget.SetOnResizeEvent(Event: pglFrameResizeFunc);
  begin
    Self.ResizeFunc := Event;
  end;


procedure TPGLRenderTarget.SetClearRect(ClearRect: TPGLRectF);
  begin
    Self.ClearRect := ClearRect;
  end;


procedure TPGLRenderTarget.AttachShadowMap();

Var
CheckVar: GLEnum;

  begin

    if PGL.ShadowTarget = Self then Exit;

    PGL.BindTexture(0,PGL.ShadowMap);

    // remove depth buffer from current owner if owned
    if PGL.ShadowTarget <> nil then begin
      glBindFrameBuffer(GL_FRAMEBUFFER,PGL.ShadowTarget.FrameBuffer);
      glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_DEPTH_ATTACHMENT,GL_TEXTURE_2D, 0, 0);
    end;

    // Attach the depth buffer to the new target
    glBindFrameBuffer(GL_FRAMEBUFFER,Self.FrameBuffer);
    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_DEPTH_ATTACHMENT,GL_TEXTURE_2D,PGL.ShadowMap,0);

    // Check for framebuffer completeness
    CheckVar := glCheckFrameBufferStatus(GL_FRAMEBUFFER);
    if CheckVar <> GL_FRAMEBUFFER_COMPLETE then begin
      PGLAddError('Unable to attach the shadow map depth buffer to the requested target');
    end;

  end;


procedure TPGLRenderTarget.SetDrawOffSet(OffSet: TPGLVector2);
  begin
    Self.pDrawOffSet := OffSet;
  end;

procedure TPGLRenderTarget.SetPixelSize(Size: Single);
  begin
    Self.pPixelSize := Size;
  end;

procedure TPGLRenderTarget.SetBrightness(Level: Single);
  begin
    Self.pBrightness := Level;
  end;

procedure TPGLRenderTarget.SetNegative(Enable: Boolean = True);
  begin
    Self.Negative := Enable;
  end;

procedure TPGLRenderTarget.SetSwizzle(Enable: Boolean = True; R: Integer = 0; G: Integer = 1; B: Integer = 2);
  begin
    Self.Swizzle := Enable;
    Self.SwizzleVals.X := R;
    Self.SwizzleVals.Y := G;
    Self.SwizzleVals.Z := B;
  end;

procedure TPGLRenderTarget.SetTextSmoothing(Smoothing: Boolean = True);
  begin
    Self.pTextSmoothing := Smoothing;
  end;

procedure TPGLRenderTarget.SetClearColor(Color: TPGLColorI);
  begin
    Self.pClearColor := CC(Color);
  end;

procedure TPGLRenderTarget.SetClearColor(Color: TPGLColorF);
  begin
    Self.pClearColor := Color;
  end;

procedure TPGLRenderTarget.SetDrawShadows(Draw: Boolean; ShadowType: GLFloat = 0);
  begin
    Self.DrawLastBatch();
    Self.pDrawShadows := Draw;
    Self.pShadowType := ShadowType;
  end;

procedure TPGLRenderTarget.SetGlobalLight(Value: GLFloat);
  begin
    self.pGlobalLight := Value;
  end;

procedure TPGLRenderTarget.Display();

Var
ErrVar: glEnum;
ScreenVer: TPGLVectorQuad;
	begin

    Self.DrawLastBatch();

    PGL.Window.MakeCurrentTarget;
    PGL.Window.Buffers.Bind();

    PGL.BindTexture(0,Self.Texture);

    glBindBuffer(GL_ARRAY_BUFFER,PGL.Window.Buffers.GetNextVBO);
    PGL.Window.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,Sizeof(Self.Ver),@Self.Ver);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    glBindBuffer(GL_ARRAY_BUFFER,PGL.Window.Buffers.GetNextVBO);
    PGL.Window.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,Sizeof(Self.Cor),@Self.Cor);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    FrameBufferProgram.Use();

    PGLMatrixTranslation(Self.Translation,BX(Self.RenderRect.X + Self.DrawOffSet.X,PGL.Window.Width),
                                          BY(Self.RenderRect.Y + Self.DrawOffSet.Y,PGL.Window.Height));
    glUniformMatrix4fv(PGLGetUniform('Translation'),1,GL_FALSE,@Self.Translation);
    glUniformMatrix4fv(PGLGetUniform('Rotation'),1,GL_FALSE,@Self.Rotation);
    glUniformMatrix4fv(PGLGetUniform('Scale'),1,GL_FALSE,@PGL.Window.Scale);
    glUniform3f(PGLGetUniform('ColorVals'),Self.ColorVals.Red,Self.ColorVals.Green,Self.ColorVals.Blue);
    glUniform3f(PGLGetUniform('ColorOverlay'),Self.ColorOverlay.Red,Self.ColorOverlay.Green,Self.ColorOverlay.Blue);
    glUniform1i(PGLGetUniform('GreyScale'),Self.GreyScale.ToInteger);
    glUniform1f(PGLGetUniform('Alpha'),1);
    glUniform1f(PGLGetUniform('planeWidth'), PGL.Window.Width);
    glUniform1f(PGLGetUniform('planeHeight'), PGL.Window.Height);
    glUniform1f(PGLGetUniform('PixelSize'), TPGLRenderTexture(Self).PixelSize);

    glDrawArrays(GL_QUADS,0,4);

    Self.Texture := Self.Texture2D;

  end;


procedure TPGLRenderTarget.Clear();
Var
UseColor: TPGLColorF;
UseColorI: TPGLColorI;
Buffers: GLInt;

	begin

    Self.MakeCurrentTarget;

    glEnable(GL_SCISSOR_TEST);
    glScissor(trunc(Self.ClearRect.Left),
              trunc(Self.Height - Self.ClearRect.Height - Self.ClearRect.Top),
              trunc(Self.ClearRect.Width),
              trunc(Self.ClearRect.HEight));

    glClearColor(Self.ClearColor.Red,Self.ClearColor.Green,Self.ClearColor.Blue,Self.ClearColor.Alpha);
    glClearDepth(1-Self.GlobalLight);

    if Self.ClassType = TPGLRenderTexture then begin
      // for clearing TPGLRenderTexture
      if Self.pClearColorBuffers = True then begin
        glDrawBuffer(GL_COLOR_ATTACHMENT0);
        glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

        glDrawBuffer(GL_COLOR_ATTACHMENT1);
        glClear(GL_COLOR_BUFFER_BIT);
      end;

      if Self.pClearDepthBuffer = True then begin
        glDrawBuffer(GL_COLOR_ATTACHMENT2);
        glClearColor(0,0,0,1-Self.GlobalLight);
        glClear(GL_COLOR_BUFFER_BIT);
      end;

      glDrawBuffer(GL_COLOR_ATTACHMENT0);

    End Else begin
      // for Clearing TPGLWindow
      Buffers := 0;

      if Self.pClearColorBuffers = True then begin
        Buffers := GL_COLOR_BUFFER_BIT;
        glClearColor(Self.ClearColor.Red, Self.ClearColor.Green, Self.ClearColor.Blue, Self.ClearColor.Alpha);
      end;

      if Self.pClearDepthBuffer = True then begin
        Buffers := Buffers or GL_DEPTH_BUFFER_BIT;
      end;

      if Buffers <> 0 then begin
        glClear(Buffers);
      end;

    end;

    glDisable(GL_SCISSOR_TEST);

  end;


procedure TPGLRenderTarget.Clear(Color: TPGLColorI);

Var
UseColor: TPGLColorF;
UseColorI: TPGLColorI;
Buffers: GLEnum;
errvar: glenum;

  begin

    Self.MakeCurrentTarget();

    glEnable(GL_SCISSOR_TEST);
    glScissor(trunc(Self.ClearRect.Left),
              trunc(Self.Height - Self.ClearRect.Height - Self.ClearRect.Top),
              trunc(Self.ClearRect.Width),
              trunc(Self.ClearRect.HEight));


    UseColor := cc(Color);
    glClearColor(UseColor.Red,UseColor.Green,UseColor.Blue,UseColor.Alpha);
    glClearDepth(0);

    if Self.FrameBuffer = 0 then begin
      glClear(GL_COLOR_BUFFER_BIT);
    End Else begin
      glDrawBuffer(GL_COLOR_ATTACHMENT0);
      glClear(GL_COLOR_BUFFER_BIT  or GL_DEPTH_BUFFER_BIT);

      glDrawBuffer(GL_COLOR_ATTACHMENT1);
      glClear(GL_COLOR_BUFFER_BIT);

      glDrawBuffer(GL_COLOR_ATTACHMENT2);
      glClearColor(0,0,0,1-Self.GlobalLight);
      glClear(GL_COLOR_BUFFER_BIT);

      glDrawBuffer(GL_COLOR_ATTACHMENT0);
    end;

    glDisable(GL_SCISSOR_TEST);


  end;


procedure TPGLRenderTarget.Clear(Color: TPGLColorF);

Var
UseColorI: TPGLColorI;
	begin

    Self.MakeCurrentTarget();

    glEnable(GL_SCISSOR_TEST);
    glScissor(trunc(Self.ClearRect.Left),
              trunc(Self.Height - Self.ClearRect.Height - Self.ClearRect.Top),
              trunc(Self.ClearRect.Width),
              trunc(Self.ClearRect.HEight));


    UseColorI := cc(Color);
    glClearColor(Color.Red,Color.Green,Color.Blue,Color.Alpha);
    glClearDepth(0);

    glDrawBuffer(GL_COLOR_ATTACHMENT0);
    glClear(GL_COLOR_BUFFER_BIT  or GL_DEPTH_BUFFER_BIT);

    glDrawBuffer(GL_COLOR_ATTACHMENT1);
    glClear(GL_COLOR_BUFFER_BIT);

    glDrawBuffer(GL_COLOR_ATTACHMENT2);
    glClearColor(0,0,0,1-Self.GlobalLight);
    glClear(GL_COLOR_BUFFER_BIT);

    glDrawBuffer(GL_COLOR_ATTACHMENT0);

    glDisable(GL_SCISSOR_TEST);

  end;


procedure TPGLRenderTarget.SetClearColorBuffers(Enable: Boolean);
  begin
    Self.pClearColorBuffers := Enable;
  end;


procedure TPGLRenderTarget.SetClearDepthBuffer(Enable: Boolean);
  begin
    Self.pClearDepthBuffer := Enable;
  end;


procedure TPGLRenderTarget.SetClearAllBuffers(Enable: Boolean);
  begin
    Self.pClearColorBuffers := Enable;
    Self.pClearDepthBuffer := Enable;
  end;


procedure TPGLRenderTarget.SetColorValues(inVals: TPGLColorI);
  begin
    Self.ColorVals := ColorItoF(inVals);
  end;

procedure TPGLRenderTarget.SetColorValues(inVals: TPGLColorF);
  begin
    Self.ColorVals := inVals;
  end;

procedure TPGLRenderTarget.SetColorOverlay(inVals: TPGLColorI);
  begin
    Self.ColorOverlay := ColorItoF(inVals);
  end;

procedure TPGLRenderTarget.SetColorOverlay(inVals: TPGLColorF);
  begin
    Self.ColorOverlay := inVals;
  end;

procedure TPGLRenderTarget.DrawLastBatch();
  begin
    Self.DrawCircleBatch();
    Self.DrawGeometryBatch();
    Self.DrawPointBatch();
    Self.DrawLineBatch();
    Self.DrawRectangleBatch();
    Self.DrawPolygonBatch();
    Self.DrawSpriteBatch();
    Self.DrawLightFanBatch();
    Self.DrawLightBatch();
    Self.DrawLineBatch2();
  end;


procedure TPGLRenderTarget.DrawRectangleBatch();

Var
TempVer: TPGLVectorQuad;

  begin

    if Self.Rectangles.Count = 0 then Exit;

    Self.MakeCurrentTarget();

    Self.Buffers.Bind();

    // Send vertices in VBO
    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(Self.Rectangles.Vector[0]) * Self.Rectangles.Count,@Self.Rectangles.Vector);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));


    // Send other data in buffer storage objects
    // Center
    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(Self.Rectangles.Center[0]) * Self.Rectangles.Count,@Self.Rectangles.Center);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,1,Self.Buffers.CurrentSSBO.Buffer);

    // Fillcolor
    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(Self.Rectangles.FillColor[0]) * Self.Rectangles.Count,@Self.Rectangles.FillColor);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,2,Self.Buffers.CurrentSSBO.Buffer);

    // BorderColor
    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(Self.Rectangles.BorderColor[0]) * Self.Rectangles.Count,@Self.Rectangles.BorderColor);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,3,Self.Buffers.CurrentSSBO.Buffer);

    // Dims
    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(Self.Rectangles.Dims[0]) * Self.Rectangles.Count,@Self.Rectangles.Dims);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,4,Self.Buffers.CurrentSSBO.Buffer);

    // BorderWidth
    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(Self.Rectangles.BorderWidth[0]) * Self.Rectangles.Count,@Self.Rectangles.BorderWidth);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,5,Self.Buffers.CurrentSSBO.Buffer);

    // Curve
    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(Self.Rectangles.Curve[0]) * Self.Rectangles.Count,@Self.Rectangles.Curve);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,6,Self.Buffers.CurrentSSBO.Buffer);

    RectangleProgram.Use();

    glUniform1f(PGLGetUniform('planeWidth'),PGL.GetViewPort.Width);
    glUniform1f(PGLGetUniform('planeHeight'),PGL.GetViewPort.Height);

    glDrawArrays(GL_QUADS,0,Self.Rectangles.Count * 4);

    Self.Rectangles.Count := 0;

    Self.Buffers.InvalidateBuffers();


  end;

procedure TPGLRenderTarget.DrawCircleBatch();

Var
IndirectBuffer: TPGLElementsIndirectBuffer;

  begin

    if Self.Circles.Count = 0 then Exit;

    IndirectBuffer.Count := Self.Circles.Count * 6;
    IndirectBuffer.InstanceCount := 1;
    IndirectBuffer.FirstIndex := 0;
    IndirectBuffer.BaseVertex := 0;
    IndirectBuffer.BaseInstance := 1;

    Self.MakeCurrentTarget();
    Self.Buffers.Bind();

    glDisable(GL_SCISSOR_TEST);

    // Send vertices in VBO
    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0, SizeOf(TPGLVectorQuad) * Self.Circles.Count,@Self.Circles.Vector);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER, 0, SizeOf(TPGLCircleDescriptor) * Self.Circles.Count, Self.Circles.Data);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, Self.Buffers.CurrentSSBO.Buffer);

    CircleProgram.Use();

    gluniform1f(PGLGetUniform('planeWidth'),Self.Width);
    glUniform1f(PGLGetUniform('planeHeight'),Self.Height);

//    glDrawElementsIndirect(GL_TRIANGLES,GL_UNSIGNED_INT,@IndirectBuffer);
    glDrawArrays(GL_QUADS, 0, Self.Circles.Count * 4);

    Self.Circles.Count := 0;

    Self.Buffers.InvalidateBuffers();
  end;


procedure TPGLRenderTarget.DrawGeometryBatch();
  begin

    if Self.GeoMetryBatch.Count = 0 then Exit;

    Self.MakeCurrentTarget();
    Self.Buffers.Bind();

    glEnable(GL_SCISSOR_TEST);
    glScissor(Trunc(Self.ClipRect.Left), Trunc(Self.Height - Self.ClipRect.Bottom),
      Trunc(Self.ClipRect.Width), Trunc(Self.ClipRect.Height));

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,Self.GeoMetryBatch.DataSize,Self.GeoMetryBatch.Data);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,3,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,Self.GeoMetryBatch.NormalsSize,Self.GeoMetryBatch.Normals);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2,3,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,Self.GeoMetryBatch.ColorSize,Self.GeoMetryBatch.Color);
    glEnableVertexAttribArray(4);
    glVertexAttribPointer(4,4,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,Self.GeoMetryBatch.ColorSize,Self.GeoMetryBatch.Color);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,1,Self.Buffers.CurrentSSBO.Buffer);

    glBindBuffer(GL_DRAW_INDIRECT_BUFFER,0);

    PGLUseProgram('Geometry');

    glUniform1f(pglGetUniform('planeWidth'),Self.Width);
    glUniform1f(pglGetUniform('planeHeight'),Self.Height);

    glMultiDrawArraysIndirect(GL_TRIANGLE_FAN,@Self.GeoMetryBatch.IndirectBuffers[0],Self.GeoMetryBatch.Count,0);

    glDisable(GL_SCISSOR_TEST);

    Self.GeoMetryBatch.Count := 0;
    Self.GeoMetryBatch.Next := 0;
    Self.GeoMetryBatch.DataSize := 0;
    Self.GeoMetryBatch.ColorSize := 0;
    Self.GeoMetryBatch.NormalsSize := 0;

    Self.Buffers.InvalidateBuffers();

  end;


procedure TPGLRenderTarget.DrawPointBatch();
Var
IndirectBuffer: TPGLArrayIndirectBuffer;
  begin

    if Self.Points.Count = 0 then Exit;

    IndirectBuffer.Count := Self.Points.Count;
    IndirectBuffer.InstanceCount := 1;
    Indirectbuffer.First := 0;
    Indirectbuffer.BaseInstance := 1;

    Self.MakeCurrentTarget();
    Self.Buffers.Bind();

    glEnable(GL_SCISSOR_TEST);
    glScissor(Trunc(Self.ClipRect.Left), Trunc(Self.Height - Self.ClipRect.Bottom),
      Trunc(Self.ClipRect.Width), Trunc(Self.ClipRect.Height));

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,28 * Points.Count, Points.Data);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,28,Pointer(0));

    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,4,GL_FLOAT,GL_FALSE,28,Pointer(8));

    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2,1,GL_FLOAT,GL_FALSE,28,Pointer(24));

    PointProgram.Use();

    glUniform1f(PGLGetUniform('planeWidth'),Self.Width);
    glUniform1f(PGLGetUniform('planeHeight'),Self.Height);

    glDrawArraysIndirect(GL_POINTS,@IndirectBuffer);

    Points.Count := 0;

    Self.Buffers.InvalidateBuffers();

    glVertexAttribDivisor(0,0);
    glVertexAttribDivisor(1,0);
    glVertexAttribDivisor(2,0);

    glDisable(GL_SCISSOR_TEST);

  end;


procedure TPGLRenderTarget.DrawLineBatch();
  begin

  end;


procedure TPGLRenderTarget.DrawPolygonBatch();

Var
I: GLInt;
C: ^TPGLCircleBatch;
IndirectBuffer: TPGLElementsIndirectBuffer;
  begin

    if Self.Polys.Count = 0 then Exit;

    IndirectBuffer.Count := Self.Polys.ElementCount;
    IndirectBuffer.InstanceCount := 1;
    IndirectBuffer.FirstIndex := 0;
    IndirectBuffer.BaseVertex := 0;
    IndirectBuffer.BaseInstance := 1;

    Self.MakeCurrentTarget();

    Self.Buffers.Bind();

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(Self.Polys.Vector[0]) * Self.Polys.Count,@Self.Polys.Vector);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(Self.Polys.Color[0]) * Self.Polys.Count,@Self.Polys.Color);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,4,GL_FLOAT,GL_FALSE,0,Pointer(0));

    DefaultProgram.Use();

    glUniform1f(PGLGetUniform('planeWidth'),PGL.GetViewport.Width);
    glUniform1f(PGLGetUniform('planeHeight'),PGL.GetViewport.Height);

    glDrawElementsIndirect(GL_TRIANGLES,GL_UNSIGNED_INT,@IndirectBuffer);

    Self.Polys.Count := 0;
    Self.Polys.Shapecount := 0;
    Self.Polys.ElementCount := 0;

    Self.Buffers.InvalidateBuffers();


  end;


{ Circles }

procedure TPGLRenderTarget.DrawCircle(Center: TPGLVector2; inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: TPGLColorF; FadeToOpacity: GLFloat = 1);
Var
Radius: GLFloat;
I: Long;
Cir: TPGLCircleDescriptor;
Pos: PByte;
Ver: TPGLVectorQuad;

  begin

    if (Self.DrawState <> 'Circle') or (Self.Circles.Count >= High(Self.Circles.Vector)) then begin
      Self.DrawLastBatch();
    end;

    Self.DrawState := 'Circle';

    Center.X := Center.X + Self.DrawOffset.X;
    Center.Y := Center.Y + Self.DrawOffSet.Y;
    Cir.Center := Center;
    Cir.Width := inWidth;
    Cir.BorderWidth := inBorderWidth;
    Cir.FillColor := inFillColor;
    Cir.BorderColor := inBorderColor;

    if FadeToOpacity < 1 then begin
      Cir.Fade := Vec4(1,FadeToOpacity,0,0);
    End Else begin
      Cir.Fade := Vec4(0,1,0,0);
    end;

    Pos := Self.Circles.Data + (Self.Circles.Count * SizeOf(Cir));
    Move(Cir,Pos[0],SizeOf(TPGLCircleDescriptor));

    Radius := inWidth / 2;
    Ver[0] := Vec2((-Radius + Center.X), (Radius + Center.Y));
    Ver[1] := Vec2((Radius + Center.X),  (Radius + Center.Y));
    Ver[2] := Vec2((Radius + Center.X),  (-Radius + Center.Y));
    Ver[3] := Vec2((-Radius + Center.X),  (-Radius + Center.Y));

    for I := 0 to 3 Do begin
      Ver[I].Scale(Self.Width, Self.Height);
    end;

    Self.Circles.Vector[Self.Circles.Count] := Ver;

    inc(Self.Circles.Count);

  end;

procedure TPGLRenderTarget.DrawCircle(CenterX, CenterY, inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: TPGLColorI);
  begin
    Self.DrawCircle(Vec2(CenterX,CenterY),inWidth,InBorderWidth,ColorItoF(inFillColor), ColorItoF(inBorderColor));
  end;

procedure TPGLRenderTarget.DrawCircle(CenterX, CenterY, inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: TPGLColorF);
  begin
    Self.DrawCircle(Vec2(CenterX,CenterY),inWidth,inBorderWidth,inFillColor,inBorderColor);
  end;

procedure TPGLRenderTarget.DrawCircle(Center: TPGLVector2; inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: TPGLColorI);
  begin
    Self.DrawCircle(Center,inWidth,inBorderWidth,ColorItoF(inFillColor), ColorItoF(inBorderColor));
  end;


{ Geometry }

procedure TPGLRenderTarget.DrawEllipse(Center: TPGLVector2; XLength,YLength,Angle: GLFloat; Color: TPGLColorI);
Var
X,Y: GLFloat;
UseAngle,CheckAngle,AngleInc: GLFloat;
Dist: GLFloat;
PointCount: GLInt;
Points: Array of TPGLVector3;
Circ: GLFloat;
A,B,H: GLFloat;
I: GLint;
Ptr: PByte;
UseColor: TPGLColorF;

  begin

    if (Self.DrawState <> 'Geometry') or (Self.GeoMetryBatch.Count >= 500) then begin
      Self.DrawLastBatch();
    end;

    Self.DrawState := 'Geometry';

    // Half of axis lengths
    A := XLength / 2;
    B := YLength / 2;

    // Calculate circumference
    H :=  (IntPower( A-B,2) ) / (IntPower(A+B,2));
    Circ := (Pi * (A+B)) * (1 + ( (H*3) / (10 + Sqrt(4-(3*H)))));

    // Calculate needed count of points and amount to increase angle per point
    PointCount := trunc(Circ / PGL.EllipsePointInterval) + 1;
    SetLength(Points,PointCount);
    UseAngle := Angle;
    AngleInc := (Pi*2) / (PointCount - 2);

    // First point is always the center
    Points[0] := Vec3(Center.X, Center.Y,Self.GeoMetryBatch.Count);

    for I := 1 to PointCount - 1  Do begin

      // Get initial position, will always ignore angle
      X := Center.X + (A * Cos(UseAngle));
      Y := Center.Y + (B * Sin(UseAngle));

      // translate position to the correct angle
      Dist := Sqrt( IntPower(X - Center.X,2) + IntPower(Y - Center.Y,2) );
      CheckAngle := ArcTan2(Y - Center.Y, X - Center.X);
      X := Center.X + (Dist * Cos(CheckAngle + Angle));
      Y := Center.Y + (Dist * Sin(CheckAngle + Angle));

      // update the point array
      Points[i] := Vec3(X,Y,Self.GeoMetryBatch.Count);

      // increase the angle
      UseAngle := UseAngle + AngleInc;

    end;


    // Move Vertex Data into data buffer
    Ptr := Self.GeoMetryBatch.Data;
    Ptr := Ptr + Self.GeoMetryBatch.DataSize;
    Move(Points[0],Ptr[0],SizeOf(TPGLVector3) * PointCount);
    Inc(Self.GeoMetryBatch.DataSize, SizeOf(TPGLVector3) * PointCount );

    // Move Color into data Buffer
    UseColor := CC(Color);
    Ptr := Self.GeoMetryBatch.Color;
    Ptr := Ptr + Self.GeoMetryBatch.ColorSize;
    Move(UseColor,Ptr[0],SizeOf(UseColor));
    Inc(Self.GeoMetryBatch.ColorSize,SizeOf(UseColor));

    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].Count := Length(Points);
    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].InstanceCount := 1;
    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].First := Self.GeoMetryBatch.Next;
    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].BaseInstance := 0;

    Inc(Self.GeoMetryBatch.Count);
    Inc(Self.GeoMetryBatch.Next, PointCount);

  end;


procedure TPGLRenderTarget.DrawGeometry(Points: array of TPGLVector2; Color: Array of TPGLColorF);
Var
UsePoints: Array of TPGLVector3;
UseColor: Array of TPGLColorF;
I,X,Y: Long;
LowX,HighX,LowY,HighY: GLFloat;
Ptr: PByte;

  begin

    if (Self.DrawState <> 'Geometry') or (Self.GeoMetryBatch.Count >= 500) then begin
      Self.DrawLastBatch();
    end;

    Self.DrawState := 'Geometry';

    SetLength(UsePoints,Length(Points));

    for I := 0 to High(UsePoints) Do begin
      UsePoints[i] := Vec3(Points[i].X, Points[i].Y,Self.GeoMetryBatch.Count);
    end;

    Ptr := Self.GeoMetryBatch.Data;
    Ptr := Ptr + Self.GeoMetryBatch.DataSize;
    Move(UsePoints[0],Ptr[0],SizeOf(TPGLVector3) * Length(UsePoints));
    Inc(Self.GeoMetryBatch.DataSize, SizeOf(TPGLVector3) * Length(UsePoints));

    if Length(Color) <> Length(Points) then begin
      SetLength(UseColor,Length(Points));
      for I := 0 to High(UseColor) do begin
        UseColor[i] := Color[0];
      end;

    End Else begin
      SetLength(UseColor,Length(Color));
      for I := 0 to High(Color) Do begin
        UseColor[i] := Color[i];
      end;
    end;

    Ptr := Self.GeoMetryBatch.Color;
    Ptr := Ptr + Self.GeoMetryBatch.ColorSize;
    Move(UseColor[0],Ptr[0],SizeOf(TPGLColorF) * Length(UseColor));
    Inc(Self.GeoMetryBatch.ColorSize, SizeOf(TPGLColorF) * Length(UseColor));

    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].Count := Length(UsePoints);
    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].InstanceCount := 1;
    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].First := Self.GeoMetryBatch.Next;
    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].BaseInstance := 0;

    Inc(Self.GeoMetryBatch.Count);
    Inc(Self.GeoMetryBatch.Next, Length(UsePoints));

  end;


procedure TPGLRenderTarget.DrawRegularPolygon(NumVertices: GLInt; Center: TPGLVector2; Radius: Single; Angle: Single; Color: TPGLColorI);
Var
PointCount: GLInt;
Points: Array of TPGLVector3;
I: Long;
X,Y: GLFloat;
UseAngle,AngleInc: GLFloat;
Ptr: PByte;
UseColor: TPGLColorF;

  begin

    if (Self.DrawState <> 'Geometry') or (Self.GeoMetryBatch.Count >= 500) then begin
      Self.DrawLastBatch();
    end;

    Self.DrawState := 'Geometry';

    PointCount := NumVertices + 2;
    SetLength(Points,PointCount);

    UseAngle := Angle - (Pi/2);
    AngleInc := (Pi*2) / NumVertices;

    Points[0].X := Center.X;
    Points[0].Y := Center.Y;
    Points[0].Z := Self.GeoMetryBatch.Count;

    for I := 1 to NumVertices Do begin
      Points[i].X := Center.X + (Radius * Cos(UseAngle));
      Points[i].Y := Center.Y + (Radius * Sin(UseAngle));
      Points[i].Z := Self.GeoMetryBatch.Count;
      UseAngle := UseAngle + AngleInc;
    end;

    Points[High(Points)] := Points[1];

    // Move Points to buffer
    Ptr := Self.GeoMetryBatch.Data;
    Ptr := Ptr + Self.GeoMetryBatch.DataSize;
    Move(Points[0],Ptr[0],SizeOf(TPGLVector3) * PointCount);
    Inc(Self.GeoMetryBatch.DataSize,SizeOf(TPGLVector3) * PointCount);

    // Move Color to Buffer
    UseColor := CC(Color);
    Ptr := Self.GeoMetryBatch.Color;
    Ptr := Ptr + Self.GeoMetryBatch.ColorSize;
    Move(UseColor,Ptr[0],SizeOf(TPGLColorF));
    Inc(Self.GeoMetryBatch.ColorSize,SizeOf(TPGLColorF));

    // Calculate Normals
    for I := 0 to PointCount - 1 Do begin
      Points[i].Normalize();
    end;

    // Move normals to buffer
    Ptr := Self.GeoMetryBatch.Normals;
    Ptr := Ptr + Self.GeoMetryBatch.NormalsSize;
    Move(Points[0],Ptr[0],SizeOf(TPGLVector3) * PointCount);
    Inc(Self.GeoMetryBatch.NormalsSize,SizeOf(TPGLVector3) * PointCount);

    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].Count := PointCount;
    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].InstanceCount := 1;
    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].First := Self.GeoMetryBatch.Next;
    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].BaseInstance := 0;

    Inc(Self.GeoMetryBatch.Count);
    Inc(Self.GeoMetryBatch.Next,PointCount);

  end;



{ Points }

procedure TPGLRenderTarget.DrawPoint(Center: TPGLVector2; Size: GLFloat; inColor: TPGLColorF);

Var
Pos: PByte;
Vec: TPGLVector2;

  begin

    if (Self.DrawState <> 'Point') or (Self.Points.Count >= 6500) then begin
      Self.DrawLastBatch();
    end;

    Self.DrawState := 'Point';

    Pos := Self.Points.Data + (28 * Self.Points.Count);
    Vec.X := (Center.X + Self.DrawOffset.X);
    Vec.Y := (Center.Y + Self.DrawOffset.Y);

    Move(Vec,Pos[0],8);

    Inc(Pos,8);
    Move(InColor, Pos[0],16);

    Inc(Pos,16);
    Move(Size, Pos[0],4);

    inc(Self.Points.Count);

  end;

procedure TPGLRenderTarget.DrawPoint(CenterX,CenterY,Size: GLFloat; inColor: TPGLColorI);
  begin
    Self.DrawPoint(Vec2(CenterX,CenterY),Size,ColorItoF(inColor));
  end;

procedure TPGLRenderTarget.DrawPoint(CenterX,CenterY,Size: GLFloat; inColor: TPGLColorF);
  begin
    Self.DrawPoint(Vec2(CenterX,CenterY),Size,inColor);
  end;

procedure TPGLRenderTarget.DrawPoint(Center: TPGLVector2; Size: GLFloat; inColor: TPGLColorI);
  begin
    Self.DrawPoint(Center,Size,ColorItoF(inColor));
  end;


procedure TPGLRenderTarget.DrawPoint(PointObject: TPGLPoint);
  begin
    Self.DrawPoint(PointObject.pPos,PointObject.pSize,PointObject.pColor);
  end;

  { Rectangle }

procedure TPGLRenderTarget.DrawRectangle(Bounds: TPGLRectF; inBorderWidth: GLFloat; inFillColor,inBorderColor: TPGLColorF; inCurve: GLFloat = 0);

Var
P: ^Integer;
R: ^TPGLRectangleBatch;

  begin

    if (Self.DrawState <> 'Rectangle') or (Self.Rectangles.Count = High(Self.Rectangles.Center)) then begin
      Self.DrawLastBatch();
    end;


    Self.DrawState := 'Rectangle';

    R := @Self.Rectangles;
    P := @R.Count;

    R.Vector[P^,0] := Vec2((Bounds.Left + Self.DrawOffSet.X) ,(Bounds.Bottom + Self.DrawOffSet.Y));
    R.Vector[P^,1] := Vec2((Bounds.Right + Self.DrawOffSet.X),(Bounds.Bottom + Self.DrawOffSet.Y));
    R.Vector[P^,2] := Vec2((Bounds.Right + Self.DrawOffSet.X),(Bounds.Top + Self.DrawOffSet.Y));
    R.Vector[P^,3] := Vec2((Bounds.Left + Self.DrawOffSet.X) ,(Bounds.Top + Self.DrawOffSet.Y));

    R.Center[P^] := Vec2(Bounds.X + Self.DrawOffSet.X, Bounds.Y + Self.DrawOffSet.Y);
    R.Dims[P^] := Vec2(Bounds.Right - Bounds.Left, Bounds.Bottom - Bounds.Top);
    R.BorderWidth[P^] := inBorderWidth;
    R.FillColor[P^] := inFillColor;
    R.BorderColor[P^] := inBorderColor;
    R.Curve[P^] := inCurve;

    inc(R.Count);

  end;

procedure TPGLRenderTarget.DrawRectangle(Center: TPGLVector2; inWidth,inHeight,inBorderWidth: GLFloat; inFillColor,inBorderColor: TPGLColorI; inCurve: GLFloat = 0);
  begin
    Self.DrawRectangle(RectF(Center,inWidth,inHeight),inBorderWidth,ColorItoF(inFillcolor),ColorItoF(inBorderColor),inCurve);
  end;

procedure TPGLRenderTarget.DrawRectangle(Center: TPGLVector2; inWidth,inHeight,inBorderWidth: GLFloat; inFillColor,inBorderColor: TPGLColorF; inCurve: GLFloat = 0);
  begin
    Self.DrawRectangle(RectF(Center,inWidth,inHeight),inBorderWidth,inFillcolor,inBorderColor,inCurve);
  end;

procedure TPGLRenderTarget.DrawRectangle(Bounds: TPGLRectF; inBorderWidth: GLFloat; inFillColor,inBorderColor: TPGLColorI; inCurve: GLFloat = 0);
  begin
    Self.DrawRectangle(Bounds,inBorderWidth,ColorItoF(inFillColor),ColorItoF(inBorderColor),inCurve);
  end;


{     LINE       }




procedure TPGLRenderTarget.DrawLine2(P1,P2: TPGLVector2; Width,BorderWidth: GLFloat; FillColor,BorderColor: TPGLColorF; SmoothEdges: Boolean = False);

Var
C,U: GLUInt;
P: GLUInt;
I: GLUInt;
Angle: Single;
Distance: Double;
TempPoints: TPGLVectorQuad;
OrgP1,OrgP2: TPGLVector2;

  begin

    if (Self.DrawState <> 'Line') or (Self.LineBatch.Count >= 400) then begin
      Self.DrawLastBatch();
    end;

    Self.DrawState := 'Line';

    OrgP1 := P1;
    OrgP2 := P2;

    C := Self.LineBatch.Count;
    U := C * 4;
    P := Self.LineBatch.PointCount;

    Angle := ArcTan2(OrgP2.Y - OrgP1.Y, OrgP2.X - OrgP1.X);

    Self.LineBatch.ShapeBuffer[C].Count := 4;
    Self.LineBatch.ShapeBuffer[C].InstanceCount := 1;
    Self.LineBatch.ShapeBuffer[C].First := Self.LineBatch.PointCount;
    Self.LineBatch.ShapeBuffer[C].BaseInstance := 0;

    TempPoints := ReturnRectPoints(P1,P2,Width);
    Self.LineBatch.Points[P + 0] := TempPoints[0];
    Self.LineBatch.Points[P + 1] := TempPoints[1];
    Self.LineBatch.Points[P + 2] := TempPoints[2];
    Self.LineBatch.Points[P + 3] := TempPoints[3];

    for I := 0 to 3 Do begin
      Self.LineBatch.Normal[P + I] := Self.LineBatch.Points[P + I];
      if (I = 0) or (I = 3) then begin
        Self.LineBatch.Normal[P + I].Normalize(OrgP1);
      end Else begin
        Self.LineBatch.Normal[P + I].Normalize(OrgP2);
      end;

      Self.LineBatch.Points[P + I].Scale(Self.Width,Self.Height);
    end;

    Self.LineBatch.IndexBuffer[P + 0] := C;
    Self.LineBatch.IndexBuffer[P + 1] := C;
    Self.LineBatch.IndexBuffer[P + 2] := C;
    Self.LineBatch.IndexBuffer[P + 3] := C;

    inc(Self.LineBatch.PointCount, 4);

    Self.LineBatch.Shape[C].ShapeType := 1;
    Self.LineBatch.Shape[C].FillColor := FillColor;
    Self.LineBatch.Shape[C].BorderColor := BorderColor;
    Self.LineBatch.Shape[C].Width := (Width);
    Self.LineBatch.Shape[C].Height := Width;
    Self.LineBatch.Shape[C].BorderWidth := BorderWidth;
    Self.LineBatch.Shape[C].Pos := Vec4((orgp1.x + orgp2.x) / 2, (orgp1.y + orgp2.y) / 2,angle,0);


    Inc(Self.LineBatch.Count);

    // rounded caps
    if Width > 2 then begin

      // end cap

      C := Self.LineBatch.Count;
      U := C * 4;
      P := Self.LineBatch.PointCount;

      Self.LineBatch.ShapeBuffer[C].Count := 4;
      Self.LineBatch.ShapeBuffer[C].InstanceCount := 1;
      Self.LineBatch.ShapeBuffer[C].First := Self.LineBatch.PointCount;
      Self.LineBatch.ShapeBuffer[C].BaseInstance := 0;

      P1.X := OrgP2.X + (Width * Cos(Angle));
      P1.Y := OrgP2.Y + (Width * Sin(Angle));
      TempPoints := ReturnRectPoints(P1,OrgP2,Width);
      Self.LineBatch.Points[P + 0] := TempPoints[0];
      Self.LineBatch.Points[P + 1] := TempPoints[1];
      Self.LineBatch.Points[P + 2] := TempPoints[2];
      Self.LineBatch.Points[P + 3] := TempPoints[3];


      for I := 0 to 3 Do begin
        Self.LineBatch.Normal[P + I] := Self.LineBatch.Points[P + I];
        Self.LineBatch.Normal[P + I].Normalize(OrgP2);
        Self.LineBatch.Points[P + I].Scale(Self.Width,Self.Height);
      end;

      Self.LineBatch.IndexBuffer[P + 0] := C;
      Self.LineBatch.IndexBuffer[P + 1] := C;
      Self.LineBatch.IndexBuffer[P + 2] := C;
      Self.LineBatch.IndexBuffer[P + 3] := C;

      inc(Self.LineBatch.PointCount, 4);

      Self.LineBatch.Shape[C].ShapeType := 0;
      Self.LineBatch.Shape[C].FillColor := FillColor;
      Self.LineBatch.Shape[C].BorderColor := BorderColor;
      Self.LineBatch.Shape[C].Width := Width;
      Self.LineBatch.Shape[C].Height := 0;
      Self.LineBatch.Shape[C].BorderWidth := BorderWidth / 2;
      Self.LineBatch.Shape[C].Pos := Vec4(OrgP2.X,OrgP2.Y,0,0);

      Inc(Self.LineBatch.Count);


      // Start Cap

      C := Self.LineBatch.Count;
      U := C * 4;
      P := Self.LineBatch.PointCount;

      Self.LineBatch.ShapeBuffer[C].Count := 4;
      Self.LineBatch.ShapeBuffer[C].InstanceCount := 1;
      Self.LineBatch.ShapeBuffer[C].First := Self.LineBatch.PointCount;
      Self.LineBatch.ShapeBuffer[C].BaseInstance := 0;

      P2.X := OrgP1.X + (Width * Cos(Angle - Pi));
      P2.Y := OrgP1.Y + (Width * Sin(Angle - Pi));
      TempPoints := ReturnRectPoints(OrgP1,P2,Width);
      Self.LineBatch.Points[P + 0] := TempPoints[0];
      Self.LineBatch.Points[P + 1] := TempPoints[1];
      Self.LineBatch.Points[P + 2] := TempPoints[2];
      Self.LineBatch.Points[P + 3] := TempPoints[3];


      for I := 0 to 3 Do begin
        Self.LineBatch.Normal[P + I] := Self.LineBatch.Points[P + I];
        Self.LineBatch.Normal[P + I].Normalize(OrgP1);
        Self.LineBatch.Points[P + I].Scale(Self.Width,Self.Height);
      end;

      Self.LineBatch.IndexBuffer[P + 0] := C;
      Self.LineBatch.IndexBuffer[P + 1] := C;
      Self.LineBatch.IndexBuffer[P + 2] := C;
      Self.LineBatch.IndexBuffer[P + 3] := C;

      inc(Self.LineBatch.PointCount, 4);

      Self.LineBatch.Shape[C].ShapeType := 0;
      Self.LineBatch.Shape[C].FillColor := FillColor;
      Self.LineBatch.Shape[C].BorderColor := BorderColor;
      Self.LineBatch.Shape[C].Width := Width;
      Self.LineBatch.Shape[C].Height := 0;
      Self.LineBatch.Shape[C].BorderWidth := BorderWidth / 2;
      Self.LineBatch.Shape[C].Pos := Vec4(OrgP1.X,OrgP1.Y,0,0);

      Inc(Self.LineBatch.Count);


    end;

  end;


procedure TPGLRenderTarget.DrawLineBatch2();

Var
I,Z: Long;
X,Y: GLFloat;

  begin

    if Self.LineBatch.Count = 0 then Exit;

    Self.MakeCurrentTarget();
    Self.Buffers.Bind;

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(TPGLVector2) * Self.LineBatch.PointCount,@Self.LineBatch.Points);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));


    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(GLUInt) * Self.LineBatch.PointCount,@Self.LineBatch.IndexBuffer);
    glEnableVertexAttribArray(1);
    glVertexAttribIPointer(1,1,GL_UNSIGNED_INT,0,Pointer(0));

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,8 * Self.LineBatch.PointCount,@Self.LineBatch.Normal);
    glEnableVertexAttribArray(3);
    glVertexAttribPointer(3,2,GL_FLOAT,GL_FALSE,0,Pointer(0));


    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(TPGLShapeDesc) * Self.LineBatch.Count,@Self.LineBatch.Shape);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,2,Self.Buffers.CurrentSSBO.Buffer);

    LineProgram.Use();

    glMultiDrawArraysIndirect(GL_QUADS,@Self.LineBatch.ShapeBuffer,Self.LineBatch.Count,0);

    Self.LineBatch.Count := 0;
    Self.LineBatch.PointCount := 0;

    Self.Buffers.InvalidateBuffers();

  end;

procedure TPGLRenderTarget.DrawLine(P1,P2: TPGLVector2; Width,BorderWidth: GLFloat; FillColor, BorderColor: TPGLColorF);

Var
P: ^Integer;
C: ^TPGLPolygonBatch;
Ver: Array [0..4] of TPGLVector2;
Length: GLFloat;
Angle: GLFloat;
Point1,Point2: TPoint;
Radius: GLFloat;
I: GLInt;

  begin

    if Self.DrawState <> 'Polygon' then begin
      Self.DrawLastBatch();
    end;

    Self.DrawState := 'Polygon';

    if Self.Polys.ShapeCount >= 500 then begin
      Self.DrawPolygonBatch();
    end;

    inc(Self.Polys.ShapeCount);

    Point1.X := trunc(p1.X + Self.DrawOffSet.X);
    Point1.Y := trunc(p1.Y + Self.DrawOffSet.Y);
    Point2.X := trunc(p2.X + Self.DrawOffSet.X);
    Point2.Y := trunc(p2.Y + Self.DrawOffSet.Y);

    Length := Point1.Distance(Point2);
    Angle := Point1.Angle(Point2);
    Radius := ceil(Width / 2);

    // Center Point
    Ver[0].X := (P1.X + ((P2.X - P1.X) / 2));
    Ver[0].Y := (P1.Y + ((P2.Y - P1.Y) / 2));

    //Corner Points Clockwise Order
    Ver[1].X := (P1.X + (Radius * Cos(Angle + (Pi / 4))));
    Ver[1].Y := (P1.Y + (Radius * Sin(Angle + (Pi / 4))));

    Ver[2].X := (P2.X + (Radius * Cos(Angle + (Pi / 4))));
    Ver[2].Y := (P2.Y + (Radius * Sin(Angle + (Pi / 4))));

    Ver[3].X := (P2.X + (Radius * Cos(Angle - (Pi / 4))));
    Ver[3].Y := (P2.Y + (Radius * Sin(Angle - (Pi / 4))));

    Ver[4].X := (P1.X + (Radius * Cos(Angle - (Pi / 4))));
    Ver[4].Y := (P1.Y + (Radius * Sin(Angle - (Pi / 4))));

    P := @Self.Polys.Count;
    C := @Self.Polys;

    for I := 0 to 3 Do begin
      C.Vector[P^] := Ver[I + 1];
      C.Color[P^] := FillColor;
      inc(Self.Polys.Count);
    end;

    Inc(Self.Polys.ElementCount,6);

  end;


{    SPRITE      }


procedure TPGLRenderTarget.DrawSprite(Var Sprite: TPGLSprite);

Var
I,R: GLInt;
C: ^Integer;
Slot: Integer;
Mat: TPGLMatrix2;
Ver: TPGLVectorQuad;

  begin

    if (Self.DrawState <> 'Sprite') or (Self.TextureBatch.SlotsUsed = 32) or (Self.TextureBatch.Count = 1000) then begin
      Self.DrawSpriteBatch();
    end;

    Self.DrawState := 'Sprite';

    Slot := 0;

    // Look for empty slot or slot that matches texture
    for I := 0 to High(self.TextureBatch.TextureSlot) Do begin
      if Self.TextureBatch.TextureSlot[i] = 0 then begin
        Slot := I;
        Self.TextureBatch.TextureSlot[Slot] := Sprite.pTexture.Handle;
        Inc(Self.TExtureBatch.SlotsUsed);
        Break;
      End Else if Self.TextureBatch.TextureSlot[i] = Integer(Sprite.pTexture.Handle) then begin
        Slot := I;
        Break;
      end;
    end;

    C := @Self.TextureBatch.Count;
    Self.TextureBatch.MaskColor[c^] := Sprite.MaskColor;
    Self.TextureBatch.Opacity[c^] := Sprite.Opacity;
    Self.TextureBatch.ColorVals[c^] := Sprite.ColorValues;
    Self.TextureBatch.Overlay[c^] := Sprite.ColorOverlay;
    Self.TextureBatch.GreyScale[c^] := BoolToInt(Sprite.GreyScale);
    Self.TextureBatch.SlotUsing[c^] := Slot;
    Self.TextureBatch.TexCoords[c^] := Sprite.Cor;

    if Sprite.Flipped = True then begin
      FlipPoints(Self.TextureBatch.TexCoords[c^]);
    end;
    if Sprite.Mirrored = True then begin
      MirrorPoints(Self.TextureBatch.TexCoords[c^]);
    end;

    Sprite.UpdateVertices();
    Ver := Sprite.Ver;

    // Account for skew
    if Sprite.pTopSkew <> 0 then begin
      Ver[0].X := Ver[0].X + Sprite.pTopSkew;
      Ver[1].X := Ver[1].X + Sprite.pTopSkew;
    end;
    if Sprite.pBottomSkew <> 0 then begin
      Ver[2].X := Ver[2].X + Sprite.pBottomSkew;
      Ver[3].X := Ver[3].X + Sprite.pBottomSkew;
    end;
    if Sprite.pLeftSkew <> 0 then begin
      Ver[0].Y := Ver[0].Y + Sprite.pLeftSkew;
      Ver[3].Y := Ver[3].Y + Sprite.pLeftSkew;
    end;
    if Sprite.pRightSkew <> 0 then begin
      Ver[1].Y := Ver[1].Y + Sprite.pRightSkew;
      Ver[2].Y := Ver[2].Y + Sprite.pRightSkew;
    end;

    // Account for Stretch
    if Sprite.pLeftStretch <> 0 then begin
      Ver[0].Y := Ver[0].Y - Sprite.pLeftStretch / 2;
      Ver[3].Y := Ver[3].Y + Sprite.pLeftStretch / 2;
    end;
    if Sprite.pTopStretch <> 0 then begin
      Ver[0].X := Ver[0].X - Sprite.pTopStretch / 2;
      Ver[1].X := Ver[1].X + Sprite.pTopStretch / 2;
    end;
    if Sprite.pRightStretch <> 0 then begin
      Ver[1].Y := Ver[1].Y - Sprite.pRightStretch / 2;
      Ver[2].Y := Ver[2].Y + Sprite.pRightStretch / 2;
    end;
    if Sprite.pBottomStretch <> 0 then begin
      Ver[3].X := Ver[3].X - Sprite.pBottomStretch / 2;
      Ver[2].X := Ver[2].X + Sprite.pBottomStretch / 2;
    end;


    RotatePoints(Ver,Sprite.Origin,Sprite.Angle);

    for R := 0 to 3 Do begin
      Ver[r].Translate(Sprite.Bounds.X + Self.DrawOffset.X, Sprite.Bounds.Y + Self.DrawOffSet.Y);
      Ver[r].Scale(Self.Width,Self.Height);
    end;

    Self.TextureBatch.Vertices[c^] := Ver;
    Inc(Self.TextureBatch.Count);
  end;


procedure TPGLRenderTarget.DrawSpriteBatch();

Var
I: Long;
List: Array [0..31] of GLInt;
IndirectBuffer: TPGLElementsIndirectBuffer;
Buffs: Array [0..1] of glEnum;

  begin

    if Self.TextureBatch.Count = 0 then Exit;

    IndirectBuffer.Count := Self.TextureBatch.Count * 6;
    IndirectBuffer.InstanceCount := 1;
    Indirectbuffer.FirstIndex := 0;
    IndirectBuffer.BaseVertex := 0;
    IndirectBuffer.BaseInstance := 1;

    Self.MakeCurrentTarget;
    Self.Buffers.Bind;



    if Self.DrawShadows = true then begin
      Buffs[0] := GL_COLOR_ATTACHMENT0;
      glEnable(GL_DEPTH_TEST);
      glDepthFunc(GL_ALWAYS);
      glDepthMask(GL_TRUE);
      glDrawBuffers(1,@Buffs);
    End Else begin
      glDrawBuffer(GL_COLOR_ATTACHMENT0);
    end;

    glEnable(GL_SCISSOR_TEST);
    glScissor(trunc(Self.ClipRect.Left), trunc(Self.Height - Self.ClipRect.Height - Self.ClipRect.Top),
      trunc(Self.ClipRect.Width),trunc(Self.ClipRect.Height));

    for I := 0 to High(Self.TextureBatch.TextureSlot) Do begin
      if Self.TextureBatch.Textureslot[i] <> 0 then begin
        PGL.BindTexture(I,Self.TextureBatch.TextureSlot[i]);
      end;
      List[i] := i;
    end;


    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(TPGLVectorQuad) * Self.TextureBatch.Count,@Self.TextureBatch.Vertices);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(TPGLVectorQuad) * Self.TextureBatch.Count,@Self.TextureBatch.TexCoords);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(GLInt) * Self.TextureBatch.Count,@Self.TextureBatch.SlotUsing);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,4,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(TPGLColorF) * Self.TextureBatch.Count,@Self.TextureBatch.MaskColor);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,5,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(GLFloat) * Self.TextureBatch.Count,@Self.TextureBatch.Opacity);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,6,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(TPGLColorF) * Self.TextureBatch.Count,@Self.TextureBatch.ColorVals);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,7,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(TPGLColorF) * Self.TextureBatch.Count,@Self.TextureBatch.Overlay);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,8,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(GLFloat) * Self.TextureBatch.Count,@Self.TextureBatch.GreyScale);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,9,Self.Buffers.CurrentSSBO.Buffer);

    SpriteBatchProgram.Use();

    glUniform1iv(PGLGetUniform('tex'),32,@List);
    glUniform1f(PGLGetUniform('ShadowVal'),Self.pShadowType);

    glDrawElementsIndirect(GL_TRIANGLES,GL_UNSIGNED_INT,@IndirectBuffer);

    Self.TextureBatch.Clear();
    Self.TextureBatch.TextureSlot[31] := Self.Texture2D;
    Self.TextureBatch.SlotsUsed := 1;

    glDisable(GL_DEPTH_TEST);
    glDisable(GL_SCISSOR_TEST);

  end;



procedure TPGLRenderTarget.DrawLight(Center: TPGLVector2; Radius,Radiance: GLFloat; Color: TPGLColorI);
Var
P: Integer;
C: ^TPGLLightBatch;

  begin

    if Self.DrawState <> 'Light' then begin
      Self.DrawLastBatch();
    end;

    if Self.Lights.Count >= 500 then begin
      Self.DrawLightBatch();
//      Exit;
    end;

    Self.DrawState := 'Light';

    P := Self.Lights.Count;
    C := @Self.Lights;

    C.Vertices[P,0] := vec2(Center.X - Radius + Self.DrawOffset.X, Center.Y + Radius + Self.DrawOffset.Y);
    C.Vertices[P,1] := vec2(Center.X + Radius + Self.DrawOffset.X, Center.Y + Radius + Self.DrawOffset.Y);
    C.Vertices[P,2] := vec2(Center.X + Radius + Self.DrawOffset.X, Center.Y - Radius + Self.DrawOffset.Y);
    C.Vertices[P,3] := vec2(Center.X - Radius + Self.DrawOffset.X, Center.Y - Radius + Self.DrawOffset.Y);

    C.Center[P] := Vec2(Center.x + Self.DrawOffSet.X, Center.Y + Self.DrawOffset.Y);
    C.Radius[P] := Radius;
    C.Radiance[P] := Radiance;
    C.Color[P] := ColorItoF(Color);

    Inc(Self.Lights.Count);
  end;

procedure TPGLRenderTarget.DrawLightCircle(Center: TPGLVector2; Color: TPGLColorI; Radiance,Radius: GLFloat);

var
Pi8: single;
UseAngle: Single;
I: Long;
  begin

    UseAngle := 0;
    Pi8 := (Pi * 2) / 8;

    for I := 0 to 7 Do begin
      Self.DrawLightFan(Center,Color,Radiance,Radius,UseAngle,pi8);
      UseAngle := UseAngle + pi8;
    end;

  end;

procedure TPGLRenderTarget.DrawLightFan(Center: TPGLVector2; Color: TPGLColorI; Radiance: GLFloat; Radius,Angle,Spread: GLFloat);

Var
C: Integer; // Pointer to count of lights
I: Long;
Point: Array [0..2] of TPGLVector2;

  begin

    if (Self.DrawState <> 'Light Polygon') or (Self.LightPolygons.Count = 50) then begin
      Self.DrawLastBatch();
    end;

    Self.DrawState := 'Light Polygon';

    C := Self.LightPolygons.Count;

    Center.Translate(Self.DrawOffset.X, Self.DrawOffset.Y);

    Point[0] := Center;
    Point[1].X := Center.X + ((Radius * 1.1) * Cos(Angle - (Spread / 2)));
    Point[1].Y := Center.Y + ((Radius * 1.1) * Sin(Angle - (Spread / 2)));
    Point[2].X := Center.X + ((Radius * 1.1) * Cos(Angle + (Spread / 2)));
    Point[2].Y := Center.Y + ((Radius * 1.1) * Sin(Angle + (Spread / 2)));

    for I := 0 to 2 Do begin
      Self.LightPolygons.Points[(C * 3) + i] := Point[i];
    end;

    Self.LightPolygons.Center[C] := Point[0];
    Self.LightPolygons.Color[C] := cc(Color);
    Self.LightPolygons.Radius[C] := Radius;
    Self.LightPolygons.Radiance[C] := Radiance;

    Inc(Self.LightPolygons.Count);

  end;


procedure TPGLRenderTarget.DrawLightFanBatch();

Var
I,Z: Long;
Elements: Array [0..1000] of GLUInt;
CurEl: GLUInt;
IndirectBuffer: TPGLArrayIndirectBuffer;

  begin

    if Self.LightPolygons.count = 0 then Exit;

    IndirectBuffer.Count := Self.LightPolygons.Count * 3;
    IndirectBuffer.InstanceCount := 1;
    IndirectBuffer.First := 0;
    IndirectBuffer.BaseInstance := 1;

    Self.MakeCurrentTarget();
    Self.Buffers.Bind();

    glDrawBuffer(GL_COLOR_ATTACHMENT2);

    PGL.BindTexture(1, Self.Texture2D);
    PGL.BindTexture(2, Self.DepthBuffer);


    Self.Buffers.BindVBO(0);
    Self.buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(TPGLVector2) * ((Self.LightPolygons.Count) * 3),@Self.LightPolygons.Points);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindSSBO(0);
    Self.buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(TPGLVector2) * Self.LightPolygons.Count,@Self.LightPolygons.Center);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,2,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(1);
    Self.buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(TPGLColorF) * Self.LightPolygons.Count,@Self.LightPolygons.Color);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,3,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(2);
    Self.buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(GLFloat) * Self.LightPolygons.Count,@Self.LightPolygons.Radius);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,4,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(3);
    Self.buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(GLFloat) * Self.LightPolygons.Count,@Self.LightPolygons.Radiance);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,5,Self.Buffers.CurrentSSBO.Buffer);

    LightFanProgram.Use();

    glUniform1f(PGLGetUniform('planeWidth'),Self.Width);
    glUniform1f(PGLGetUniform('planeHeight'),Self.Height);
    glUniform1f(PGLGetUniform('GlobalLight'),Self.GlobalLight);
    glUniform1i(PGLGetUniform('undermap'),1);
    glUniform1i(PGLGetUniform('lightmap'),2);


    glDrawArraysIndirect(GL_TRIANGLES,@IndirectBuffer);

    Self.LightPolygons.Count := 0;

    glDrawBuffer(GL_COLOR_ATTACHMENT0);
    glReadBuffer(GL_COLOR_ATTACHMENT0);

  end;


procedure TPGLRenderTarget.DrawLightBatch();

Var
CheckVar: GLUInt;
IndirectBuffer: TPGLElementsIndirectBuffer;
  begin

    if Self.Lights.Count = 0 then Exit;

    IndirectBuffer.Count := Self.Lights.Count * 6;
    IndirectBuffer.InstanceCount := 1;
    IndirectBuffer.FirstIndex := 0;
    IndirectBuffer.BaseVertex := 0;
    IndirectBuffer.BaseInstance := 1;

    Self.MakeCurrentTarget();
    glDrawBuffer(GL_NONE);
    glDrawBuffer(GL_COLOR_ATTACHMENT2);
    glReadBuffer(GL_COLOR_ATTACHMENT2);

    PGL.BindTexture(0,Self.Texture);
    PGL.BindTexture(2,Self.LightMap);

    Self.Buffers.Bind();

    Self.Buffers.BindVBO(1);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(Self.Lights.Vertices[0]) * Self.Lights.Count,@Self.Lights.Vertices);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(2);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(Self.Lights.Vertices[0]) * Self.Lights.Count,@Self.Lights.Vertices);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));


    Self.Buffers.BindSSBO(1);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(Self.Lights.Center[0]) * Self.Lights.Count,@Self.Lights.Center);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,2,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(2);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(Self.Lights.Radius[0]) * Self.Lights.Count,@Self.Lights.Radius);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,3,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(3);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(Self.Lights.Radiance[0]) * Self.Lights.Count,@Self.Lights.Radiance);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,4,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(4);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(Self.Lights.Color[0]) * Self.Lights.Count,@Self.Lights.Color);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,5,Self.Buffers.CurrentSSBO.Buffer);

    LightProgram.Use();

    glUniform1i(PGLGetUniform('LightCount'),Self.Lights.Count);
    glUniform1f(PGLGetUniform('GlobalLight'),Self.GlobalLight);
    glUniform1f(PGLGetUniform('planeWidth'), PGL.GetViewport.Width);
    glUniform1f(PGLGetUniform('planeHeight'), PGL.GetViewport.Height);
    glUniform1i(PGLGetUniform('tex'),0);
    glUniform1i(PGLGetUniform('lightmap'),2);

    glDrawElementsIndirect(GL_TRIANGLES,GL_UNSIGNED_INT,@IndirectBuffer);

    Self.Lights.Count := 0;

    glDrawBuffer(GL_COLOR_ATTACHMENT0);
    glReadBuffer(GL_COLOR_ATTACHMENT0);

  end;


procedure TPGLRenderTarget.ApplyLights();

Var
Ver,Cor: TPGLVectorQuad;

  begin

    Self.DrawLastBatch();

    Ver[0] := Vec2(-1,1);
    Ver[1] := Vec2(1,1);
    Ver[2] := Vec2(1,-1);
    Ver[3] := Vec2(-1,-1);

    Cor[0] := Vec2(0,1);
    Cor[1] := Vec2(1,1);
    Cor[2] := Vec2(1,0);
    Cor[3] := Vec2(0,0);

    Self.MakeCurrentTarget();
    Self.Buffers.Bind;

    PGL.BindTexture(1,Self.Texture);
    PGL.BindTexture(2,Self.LightMap);

    Self.Buffers.BindVBO(0);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER, 0, SizeOf(Ver), @Ver);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT, GL_FALSE, 0, Pointer(0));

    Self.Buffers.BindVBO(1);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER, 0, SizeOf(Cor), @Cor);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT, GL_FALSE, 0, Pointer(0));

    PGLUseProgram('Apply Lights');

    glUniform1i(pglGetUniform('tex'),1);
    glUniform1i(pglGetUniform('lighttex'),2);
    glUniform1f(pglGetUniform('GlobalLight'), Self.GlobalLight);
    glUniform1f(pglGetUniform('planeWidth'), Self.Width);
    glUniform1f(pglGetUniform('planeHeight'), Self.Height);

    glDrawArrays(GL_QUADS,0,4);


  end;


procedure TPGLRenderTarget.DrawText(Text: TPGLText);
Var
SendBounds: TPGLRectF;
SendText: String;
ReturnSmoothing: Boolean;
LineCount: GLint;
I: Long;

  begin

    if Text.MultiLine = False then begin
      SendBounds := glDrawMain.RectFWH(Text.Bounds.Left,Text.Bounds.Top,-1,-1);
      SendText := Text.Text;

      Self.DrawTextString(SendText,Text.UseFont,Text.CharSize,SendBounds,Text.BorderSize,ColorFtoI(Text.Color),ColorFtoI(Text.BorderColor),
        Text.UseHasGradient,Text.GradientColorLeft,Text.GradientColorRight,Text.GradientXOffSet,Text.Angle,Text.UseShadow);

    End Else begin
      SendBounds := Text.Bounds;
      SendText := Text.UseWrapText;

      ReturnSmoothing := Self.TextSmoothing;
      Self.pTextSmoothing := Text.Smooth;

      Self.DrawTextString(SendText,Text.UseFont,Text.CharSize,SendBounds,Text.BorderSize,ColorFtoI(Text.Color),ColorFtoI(Text.BorderColor),
        Text.UseHasGradient,Text.GradientColorLeft,Text.GradientColorRight,Text.GradientXOffSet,Text.Angle,Text.UseShadow);

      Self.pTextSmoothing := ReturnSmoothing;

    end;

  end;


procedure TPGLRenderTarget.DrawText(Text: String; Font: TPGLFont; Size: GLInt; Position: TPGLVector2; BorderSize: GLUInt; Color,BorderColor: TPGLColorI; Shadow: Boolean = False);
  begin
    Self.DrawTextString(Text,Font,Size,glDrawMain.RectFWH(Position.X,Position.Y,-1,-1),BorderSize,Color,BorderColor,False,cc(pgl_empty), cc(pgl_empty),0,0,Shadow);
  end;



procedure TPGLRenderTarget.DrawTextString(Text: String; Font: TPGLFont; Size: GLInt; Bounds: TPGLRectF;
  BorderSize: GLUInt; Color,BorderColor: TPGLColorI; UseGradient: Boolean; GradientLeft: TPGLColorF;
  GradientRight: TPGLColorF; GradientXOffset: glFloat; Angle: GLFloat = 0; Shadow: Boolean = False);


Var
TextWidth,TextHeight: GLFloat;
TextBounds: TPGLVectorQuad;
CharQuad: Array of TPGLVectorQuad;
TexQuad: Array of TPGLVectorQuad;
CurPos: TPGLVector2;
CurChar: ^TPGLCharacter;
CurQuad: ^TPGLVectorQuad;
UseColor: TPGLColorF;
I,R: GLInt;
BreakLoc: GLInt;
BreakPos: Array of GLInt;
Cur: GLInt;
AdjPer: GLFloat;
AdjSize: TPGLVector2;
UseAtlas: ^TPGLAtlas;
RotBounds: TPGLRectF;
RotPoints: Array [0..3] of TPGLVector2;
Lines,Chars: GLInt;
TargetVar: GLEnum;
Ibuffer: TPGLElementsIndirectBuffer;
StartQuad, QuadLength: GLint;
Buffer: Array of GLUByte;

  begin

    DrawLastBatch();

    UseAtlas := @Font.Atlas[Font.ChooseAtlas(Size)];
    Size := UseAtlas.FontSize;

    // Adjust percentage for varying font sizes
    AdjPer := Size / UseAtlas.FontSize;

    // look for line breaks
    Cur := 1;

    while Cur < Length(Text) Do begin

      BreakLoc := Pos(sLineBreak,Text,Cur);
      if BreakLoc <> 0 then begin
        SetLength(BreakPos,Length(BreakPos) + 1);
        BreakPos[High(BreakPos)] := BreakLoc;
        Cur := BreakLoc + 1;
        Text := text.Replace(sLineBreak,'',[]);
      End Else begin
        Break;
      end;

    end;



    TextHeight := ((UseAtlas.TotalHeight * AdjPer) * (Length(BreakPos) + 1)) + ((BorderSize * 2) * (Length(BreakPos) + 1));
    RotBounds.Width := 0;
    RotBounds.Height := 0;
    TextWidth := 0;
    Lines := 1;

    if Bounds.Width <> -1 then begin
      TextWidth := Bounds.Width;
    end;

    SetLength(CharQuad, Length(Text));
    SetLength(TexQuad,Length(CharQuad));
    CurPos.X := BorderSize;
    CurPOs.Y := BorderSize;

    Self.pTextParams.Reset();
    Self.pTextParams.SetFormat(Vec2(Bounds.Left,Bounds.Top),0,trunc(TextHeight),Font,Font.ChooseAtlas(Size),
      cc(Color),cc(BorderColor),BorderSize,Shadow,Vec2(0,0),cc(pgl_empty),Self.TextSmoothing,0,UseGradient,GradientLeft,
      GradientRight,GradientXOffSet);


    StartQuad := 0;
    QuadLength := 0;

    pglTempBuffer.Clear(pgl_empty);

    for I := 1 to Length(Text) Do begin

      if Length(BreakPos) <> 0 then begin
        for R := 0 to high(BreakPos) Do begin
          if I = BreakPos[R] then begin
            CurPos.y := CurPos.y + (UseAtlas.TotalHeight * AdjPer);
            Lines := Lines + 1;
            CurPos.X := BorderSize;
          end;
        end;
      end;

      CurChar := @UseAtlas.Character[Ord(Text[i])];

      AdjSize.X := (CurChar.Metrics.Width * AdjPer);
      AdjSize.y := (CurChar.Metrics.Height * AdjPer);

      CharQuad[i-1,0] := Vec2(CurPos.X,             CurPos.Y);
      CharQuad[i-1,1] := Vec2((CurPos.X) + AdjSize.X, CurPos.Y);
      CharQuad[i-1,2] := Vec2(CurPos.X + AdjSize.X, (CurPos.Y + (UseAtlas.TotalHeight * AdjPer)) );
      CharQuad[i-1,3] := Vec2(CurPos.X,             (CurPos.Y + (UseAtlas.TotalHeight * AdjPer)) );

      TexQuad[i-1,0] := Vec2(CurChar.Position.X - BorderSize,                   UseAtlas.TotalHeight);
      TexQuad[i-1,1] := Vec2(CurChar.Position.X + CurChar.Metrics.Width + (BorderSize), UseAtlas.TotalHeight);
      TexQuad[i-1,2] := Vec2(CurChar.Position.X + CurChar.Metrics.Width + (BorderSize), 0);
      TexQuad[i-1,3] := Vec2(CurChar.Position.X - BorderSize,                   0);

      CurPos.X := CurPos.X + ((CurChar.Advance + (BorderSize * 2)));

      if Bounds.Width = -1 then begin
        if CurPos.X > TextWidth then begin
          TextWidth := CurPos.X;
        end;
      end;

      QuadLength := QuadLength + 1;
      if QuadLength = 500 then begin
        pglTempBuffer.SetClipRect(RectFWH(0,0,TextWidth,TextHeight));
        Self.pTextParams.Width := trunc(TextWidth);
        Self.DrawTextCharacters(Copy(CharQuad,StartQuad,QuadLength),Copy(TexQuad,StartQuad,QuadLength),trunc(TextWidth),trunc(TextHeight));
        StartQuad := StartQuad + QuadLength;
        QuadLength := 0;
      end;


    end;

    if QuadLength > 0 then begin
      pglTempBuffer.SetClipRect(RectFWH(0,0,TextWidth,TextHeight));
      Self.pTextParams.Width := trunc(TextWidth);
      Self.DrawTextCharacters(Copy(CharQuad,StartQuad,QuadLength),Copy(TexQuad,StartQuad,QuadLength),trunc(TextWidth),trunc(TextHeight));
    end;

    // Apply Rotation

    RotBounds := glDrawMain.RectFWH(Bounds.Left,Bounds.Top,TextWidth,TextHeight);

    if Angle <> 0 then begin
      pglTempBuffer.Rotate(Angle);
      RotPoints[0] := Vec2(RotBounds.Left,RotBounds.Top);
      RotPoints[1] := Vec2(RotBounds.Right,RotBounds.Top);
      RotPoints[2] := Vec2(RotBounds.Right,RotBounds.Bottom);
      RotPoints[3] := Vec2(RotBounds.Left,RotBounds.Bottom);
      RotatePoints(RotPoints,Vec2(RotBounds.X,RotBounds.Y),pglTempBuffer.Angle);
      RotBounds := PointsToRectF(RotPoints);
    end;

    if RotBounds.Width < TextWidth then begin
      RotBounds.Width := TextWidth;
    end;

    if RotBounds.Height < TextHeight then begin
      RotBounds.Height := TextHeight;
    end;

    RotBounds.Update(FROMCENTER);

    // if No Border, apply shadow and smoothing if needed, then display to Destination
    if BorderSize >= 0 then begin

      if Shadow = True then begin
        pglTempBuffer.SetColorValues(Color3i(0,0,0));
        pglTempBuffer.SetColorOverlay(Color3i(50,50,50));
        pglTempBuffer.SetOpacity(0.5);
        pglTempBuffer.StretchBlt(Self,RotBounds.Left - 5,Rotbounds.Top + 5,RotBounds.Width,RotBounds.Height,
      (TextWidth / 2) - (RotBounds.Width / 2),(TextHeight / 2) - (RotBounds.Height / 2),RotBounds.Width,RotBounds.Height);

        pglTempBuffer.SetColorValues(Color3i(255,255,255));
        pglTempBuffer.SetColorOverlay(Color3i(0,0,0));
        pglTempBuffer.SetOpacity(1);
      end;

      if Self.TextSmoothing = True then begin
        pglTempBuffer.Smooth(glDrawMain.RectF(0,0,pglTempBuffer.Width,pglTempBuffer.Height),pgl_Empty);
      end;


      pglTempBuffer.StretchBlt(Self,RotBounds.Left,RotBounds.Top,RotBounds.Width,RotBounds.Height,
        (TextWidth / 2) - (RotBounds.Width / 2),(TextHeight / 2) - (RotBounds.Height / 2),Rotbounds.Width,RotBounds.Height);

      pglTempBuffer.SetRotation(0);
      Exit;
    end;


  end;


procedure TPGLRenderTarget.DrawTextCharacters(CharQuads,TexQuads: Array of TPGLVectorQuad; TextWidth,TextHeight: GLUInt);

Var
Param: TPGLTextFormat;
UseColor: TPGLColorF;
IBuffer: TPGLElementsIndirectBuffer;

  begin

    Param := Self.pTextParams;

    pglTempBuffer.MakeCurrentTarget();

    Self.Buffers.Bind();

    PGL.BindTexture(0,Param.Font.Atlas[Param.AtlasIndex].Texture);

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(TPGLVectorQuad) * Length(CharQuads),@CharQuads);
    glEnableVertexAttribArray(0);
    glVertexAttribPOinter(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(TPGLVectorQuad) * Length(TexQuads),@TexQuads);
    glEnableVertexAttribArray(1);
    glVertexAttribPOinter(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    TextProgram.Use();

    glUniform1i(PGLGetUniform('tex'),0);
    glUniform1f(PGLGetUniform('planeWidth'),pglTempBuffer.Width);
    glUniform1f(PGLGetUniform('planeHeight'),pglTempBuffer.Height);
    glUniform1f(PGLGetUniform('TextWidth'), Param.Width);

    glUniform4fv(PGLGetUniform('TextColor'),1, @Param.Color);
    glUniform4fv(PGLGetUniform('GradientLeft'),1,@Param.GradientLeft);
    glUniform4fv(PGLGetUniform('GradientRight'),1,@Param.GradientRight);
    glUniform1i(PGLGetUniform('HasGradient'),BoolToInt(Param.UseGradient));
    glUniform1f(PGLGetUniform('GradientOffset'),Param.GradientXOffSet);
    glUniform1i(PGLGetUniform('BorderSize'),Param.BorderSize);
    glUniform4fv(PGLGetUniform('BorderColor'),1,@Param.BorderColor);

    IBuffer.Count := Length(CharQuads) * 6;
    IBuffer.InstanceCount := 1;
    IBuffer.FirstIndex := 0;
    IBuffer.BaseVertex := 0;
    IBuffer.BaseInstance := 1;

    glDrawElementsIndirect(GL_TRIANGLES,GL_UNSIGNED_INT,@iBuffer);
//    glDrawArrays(GL_QUADS,0,Length(CharQuads) * 4);

    Self.Buffers.InvalidateBuffers();
  end;


procedure TPGLRenderTarget.Swirl(Target: TPGLRenderTarget; DestRect,SourceRect: TPGLRectF);

Var
NewVer,NewCor: TPGLVectorQuad;

  begin

    Self.DrawLastBatch();

    NewVer[0] := Vec2(DestRect.Left, DestRect.Top);
    NewVer[1] := Vec2(DestRect.Right, DestRect.Top);
    NewVer[2] := Vec2(DestRect.Right, DestRect.Bottom);
    NewVer[3] := Vec2(DestRect.Left, DestRect.Bottom);

    NewCor[0] := Vec2(SourceRect.Left, SourceRect.Top);
    NewCor[1] := Vec2(SourceRect.Right, SourceRect.Top);
    NewCor[2] := Vec2(SourceRect.Right, SourceRect.Bottom);
    NewCor[3] := Vec2(SourceRect.Left, SourceRect.Bottom);

    Target.MakeCurrentTarget();
    Target.Buffers.Bind();

    PGL.BindTexture(0,Target.Texture2D);

    Self.Buffers.BindVBO(1);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(TPGLVectorQuad),@NewVer[0]);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(2);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(TPGLVectorQuad),@NewCor[0]);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    SwirlProgram.Use();

    glUniform1i(PGLGetUniform('tex'),0);
    glUniform1f(PGLGetUniform('planeWidth'),Self.Width);
    glUniform1f(PGLGetUniform('planeHeight'),Self.Height);
    glUniform2f(PGLGetUniform('inCenter'),SourceRect.X, SourceRect.Y);

    glDrawArrays(GL_QUADS,0,4);


  end;

procedure TPGLRenderTarget.Pixelate(PixelRect: TPGLRectF; PixelSize: GLFloat = 2);

Var
NewVer,NewCor: TPGLVectorQuad;
checkvar: GLInt;

  begin

    Self.DrawLastBatch();

    NewVer[0] := Vec2(PixelRect.Left, PixelRect.Top);
    NewVer[1] := Vec2(PixelRect.Right, PixelRect.Top);
    NewVer[2] := Vec2(PixelRect.Right, PixelRect.Bottom);
    NewVer[3] := Vec2(PixelRect.Left, PixelRect.Bottom);

    TransformToBuffer(NewVer,Self.Width,Self.Height);

    NewCor[0] := Vec2(PixelRect.Left / Self.Width, PixelRect.Bottom / Self.Height);
    NewCor[1] := Vec2(PixelRect.Right / Self.Width, PixelRect.Bottom / Self.Height);
    NewCor[2] := Vec2(PixelRect.Right / Self.Width, PixelRect.Top / Self.Height);
    NewCor[3] := Vec2(PixelRect.Left / Self.Width, PixelRect.Top / Self.Height);

    Self.MakeCurrentTarget();
    Self.Buffers.Bind();

    PGL.BindTexture(0,Self.Texture);

    glEnable(GL_SCISSOR_TEST);
    glScissor(trunc(PixelRect.Left),Trunc(Self.Height - PixelRect.Height - PixelRect.Top),trunc(PixelRect.Width), trunc(Pixelrect.HEight));

    Self.Buffers.BindVBO(1);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(TPGLVectorQuad),@NewVer[0]);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(2);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(TPGLVectorQuad),@NewCor[0]);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));


    PixelateProgram.Use();

    glUniform1i(PGLGetUniform('tex'),0);
    glUniform1f(PGLGetUniform('planeWidth'),Self.Width);
    glUniform1f(PGLGetUniform('planeHeight'),Self.Height);
    glUniform1f(PGLGetUniform('PixelSize'),PixelSize);

    glDrawArrays(GL_QUADS,0,4);



  end;


procedure TPGLRenderTarget.Smooth(Area: TPGLRectF; IgnoreColor: TPGLColorI);

Var
NewVer,NewCor: TPGLVectorQuad;
CheckVar: Cardinal;
UseColor: TPGLColorF;
Buffer: Array of Byte;
TempTex: GLUint;

  begin

    Self.DrawLastBatch();

    PGL.GenTexture(TempTex);
    glBindTexture(GL_TEXTURE_2D,TempTex);
    glTexParameterI(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D,GL_TEXTURE_Min_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);

    NewVer[0] := Vec2(Area.Left, Area.Top);
    NewVer[1] := Vec2(Area.Right, Area.Top);
    NewVer[2] := Vec2(Area.Right, Area.Bottom);
    NewVer[3] := Vec2(Area.Left, Area.Bottom);

//    TransformToBuffer(NewVer,Self.Width,Self.Height);

    NewCor[0] := Vec2(Area.Left / Self.Width, Area.Bottom / Self.Height);
    NewCor[1] := Vec2(Area.Right / Self.Width, Area.Bottom / Self.Height);
    NewCor[2] := Vec2(Area.Right / Self.Width, Area.Top / Self.Height);
    NewCor[3] := Vec2(Area.Left / Self.Width, Area.Top / Self.Height);

    Self.MakeCurrentTarget();
    Self.Buffers.Bind();

    PGL.BindTexture(0,TempTex);
    glCopyTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,trunc(Area.Left), Trunc(Area.TOp),
      trunc(Area.Width), trunc(Area.Height), 0);

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(TPGLVectorQuad),@NewVer[0]);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(TPGLVectorQuad),@NewCor[0]);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    SmoothProgram.Use();

    glUniform1i(PGLGetUniform('tex'),0);
    glUniform1f(PGLGetUniform('planeWidth'),Self.Width);
    glUniform1f(PGLGetUniform('planeHeight'),Self.Height);
    UseColor := cc(IgnoreColor);
    glUniform4fv(PGLGetUniform('IgnoreColor'),1,@UseColor);

    glDrawArrays(GL_QUADS,0,4);

    PGL.DeleteTexture(TempTex);

end;


procedure TPGLRenderTarget.DrawStatic(Area: TPGLRectF);

Var
Ver: Array [0..3] of TPGLVector2;
I,Z: Long;

  begin

    Self.MakeCurrentTarget();
    Self.Buffers.Bind();
    Self.SetClipRect(Area);

    Ver[0] := Vec2(Area.Left, Area.Top);
    Ver[1] := Vec2(Area.Right, Area.Top);
    Ver[2] := Vec2(Area.Right, Area.Bottom);
    Ver[3] := Vec2(Area.Left, Area.Bottom);

    Self.Buffers.GetNextVBO();
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(Ver),@Ver);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    StaticProgram.Use;

    glUniform1f(PGLGetUniform('planeWidth'),Self.Width);
    glUniform1f(PGLGetUniform('planeHeight'),Self.Height);
    glUniform1f(PGLGetUniform('Seed'),Random());

    glDrawElements(GL_TRIANGLES,6,GL_UNSIGNED_INT,nil);

  end;


procedure TPGLRenderTarget.StereoScope(Area: TPGLRectF; OffSet: TPGLVector2);
Var
Ver: TPGLVectorQuad;
Cor: TPGLVectorQuad;

  begin

    Self.DrawLastBatch();

    Ver[0] := Vec2(Area.Left, Area.Top);
    Ver[1] := Vec2(Area.Right, Area.Top);
    Ver[2] := Vec2(Area.Right, Area.Bottom);
    Ver[3] := Vec2(Area.Left, Area.Bottom);

    Cor := Ver;

    Self.MakeCurrentTarget();
    Self.Buffers.Bind();

    PGL.BindTexture(0,Self.Texture2D);

    Self.Buffers.BindVBO(0);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(Ver),@Ver);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT, GL_FALSE, 0, Pointer(0));

    Self.Buffers.BindVBO(1);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(Cor),@Cor);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT, GL_FALSE, 0, Pointer(0));

    PGLUseProgram('Stereoscope');

    glUniform1i(pglGetUniform('tex'),0);
    glUniform1f(pglGetUniform('planeWidth'),Self.Width);
    glUniform1f(pglGetUniform('planeHeight'),Self.Height);
    glUniform2fv(pglGetUniform('OffSet'),1,@OffSet);

    glDrawElements(GL_TRIANGLES,6,GL_UNSIGNED_INT,nil);

  end;


procedure TPGLRenderTarget.FloodFill(StartCoord: TPGLVector2; Area: TPGLRectF);
Var
Ver,Cor: TPGLVectorQuad;

  begin

    Ver[0] := Vec2(Area.Left, Area.Top);
    Ver[1] := Vec2(Area.Right, Area.Top);
    Ver[2] := Vec2(Area.Right, Area.Bottom);
    Ver[3] := Vec2(Area.Left, Area.Bottom);

    Cor[0] := Vec2(Area.Left / Self.Width, Area.Top / Self.Height);
    Cor[1] := Vec2(Area.Right / Self.Width, Area.Top / Self.Height);
    Cor[2] := Vec2(Area.Right / Self.Width, Area.Bottom / Self.Height);
    Cor[3] := Vec2(Area.Left / Self.Width, Area.Bottom / Self.Height);

    Self.MakeCurrentTarget();
    Self.Buffers.Bind();

    PGL.BindTexture(0,Self.Texture);

    Self.Buffers.BindVBO(0);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER, 0, SizeOf(Ver),@Ver);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(1);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER, 0, SizeOf(Cor),@Cor);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    PGLUseProgram('Flood Fill');

    glUniform1i(pglGetUniform('tex'),0);
    glUniform1f(pglGetUniform('planeWidth'), Self.Width);
    glUniform1f(pglGetUniform('planeHeight'), Self.Height);
    glUniform2f(pglGetUniform('Center'),(StartCoord.X / Self.Width), 1 - (StartCoord.Y / Self.Height));

    glDrawArrays(GL_QUADS,0,4);

  end;


///////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// TPGLRenderTexture /////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
constructor TPGLRenderTexture.Create(inWidth: Integer; inHeight: Integer; BitCount: GLInt = 32);
Var
I: GLInt;
CheckVar: glEnum;

  begin
    inherited Create(inWidth,inHeight);

    Self.pBitDepth := BitCount;
    Self.SetPixelFormat();

    glGenFrameBuffers(1,@Self.FrameBuffer);
    glBindFrameBuffer(GL_FRAMEBUFFER,Self.FrameBuffer);

    // Non-Smooth regular texture
    Pgl.GenTexture(Self.Texture2D);
    PGL.BindTexture(0,Self.Texture2D);
    glTexImage2D(GL_TEXTURE_2D,0,Self.pPixelFormat,inWidth,inHeight,0,GL_RGBA,GL_UNSIGNED_BYTE,nil);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    Pgl.BindTexture(0,0);

    // Back texture, not typically used
    Pgl.GenTexture(Self.BackTexture);
    PGL.BindTexture(0,Self.BackTexture);
    glTexImage2D(GL_TEXTURE_2D,0,Self.pPixelFormat,inWidth,inHeight,0,GL_RGBA,GL_UNSIGNED_BYTE,nil);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    Pgl.BindTexture(0,0);

    // Light map
    Pgl.GenTexture(Self.LightMap);
    PGL.BindTexture(0,Self.LightMap);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,inWidth,inHeight,0,GL_RGBA, GL_UNSIGNED_BYTE,nil);
    glTexParameterI(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameterI(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    Pgl.BindTexture(0,0);

    // Depth Buffer
    Pgl.GenTexture(Self.DepthBuffer);
    PGL.BindTexture(0,Self.DepthBuffer);
    glTexImage2D(GL_TEXTURE_2D,0,GL_DEPTH_COMPONENT16,inWidth,inHeight,0,GL_DEPTH_COMPONENT,GL_UNSIGNED_BYTE,nil);
    glTexParameterI(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameterI(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    Pgl.BindTexture(0,0);

//
    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,Self.Texture2D,0);
    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT1,GL_TEXTURE_2D,Self.BackTexture,0);
    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT2,GL_TEXTURE_2D,Self.LightMap,0);
    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_DEPTH_ATTACHMENT,GL_TEXTURE_2D,Self.DepthBuffer,0);


    glDrawBuffer(GL_COLOR_ATTACHMENT0);

    CheckVar := glCheckFrameBufferStatus(GL_FRAMEBUFFER);

    if CheckVar <> GL_FRAMEBUFFER_COMPLETE then begin
      pglAddError('FRAMEBUFFER INCOMPLETE');
      pglReportErrors;
    end;

    glBindFrameBuffer(GL_FRAMEBUFFER,0);

    // set 2D non-smooth texture as default;
    Self.Texture := Self.Texture2d;

    Self.FillEBO;

    PGLMatrixScale(Self.Scale,Self.Width,Self.Height);
    Self.Opacity := 1;

    PGL.AddRenderTexture(Self);
  end;


procedure TPGLRenderTexture.Rotate(byAngle: Single);
  begin
    Self.Angle := Self.Angle + byAngle;
    PGLMatrixRotation(Self.Rotation,Self.Angle,0,0);
  end;


procedure TPGLRenderTexture.SetRotation(toAngle: Single);
  begin
    Self.Angle := toAngle;
    PGLMatrixRotation(Self.Rotation,Self.Angle,0,0);
  end;


procedure TPGLRenderTexture.SetPixelSize(P: Integer);
  begin
    Self.pPixelSize := P;
  end;

procedure TPGLRenderTexture.SetOpacity(Val: Single);
  begin
    Self.Opacity := val;
  end;


procedure TPGLRenderTexture.SetSize(W,H: GLUInt);

Var
Buffs: Array [0..1] of GLEnum;
CheckVar: GLEnum;
Buff: GLEnum;

  begin

    Self.MakeCurrentTarget();

    Buff := GL_COLOR_ATTACHMENT0;
    glInvalidateFrameBuffer(GL_FRAMEBUFFER,1,@Buff);

    Self.pWidth := W;
    Self.pHeight := H;

    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,0,0);
    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT1,GL_TEXTURE_2D,0,0);

    PGL.BindTexture(0,Self.Texture2D);
    glTexImage2d(GL_TEXTURE_2D,0,GL_RGBA,W,H,0,GL_RGBA,GL_UNSIGNED_BYTE,nil);
    PGL.BindTexture(0,0);

    PGL.BindTexture(0,Self.BackTexture);
    glTexImage2d(GL_TEXTURE_2D,0,GL_RGBA,W,H,0,GL_RGBA,GL_UNSIGNED_BYTE,nil);
    PGL.BindTexture(0,0);

    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,Self.Texture2D,0);
    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT1,GL_TEXTURE_2D,Self.BackTexture,0);

    Self.SetRenderRect(RectIWH(0,0,Self.Width,Self.Height));
    Self.SetClipRect(Self.RenderRect);
    glViewPort(0,0,Self.Width,Self.Height);
    PGL.UpdateViewPort(0,0,Self.Width,Self.Height);
  end;


procedure TPGLRenderTexture.SetNearestFilter();
  begin
    PGL.BindTexture(0,Self.Texture2D);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

    PGL.BindTexture(0,Self.BackTexture);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

    PGL.BindTexture(0,Self.LightMap);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

    PGL.BindTexture(0,Self.DepthBuffer);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

    PGL.UnBindTexture(Self.DepthBuffer);
  end;


procedure TPGLRenderTexture.SetLinearFilter();
  begin
    PGL.BindTexture(0,Self.Texture2D);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    PGL.BindTexture(0,Self.BackTexture);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    PGL.BindTexture(0,Self.LightMap);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    PGL.BindTexture(0,Self.DepthBuffer);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    PGL.UnBindTexture(Self.DepthBuffer);
  end;



procedure TPGLRenderTexture.Blt(Dest: TPGLRenderTarget; destX, destY, destWidth, destHeight, srcX, srcY: GLFloat);
  begin
    Self.Blt(Dest, RectIWH(DestX, DestY, DestWidth, DestHEight), RectIWH(srcX, srcY, DestWidth, DestHeight));
  end;

procedure TPGLRenderTexture.Blt(Dest: TPGLRenderTarget; DestRect: TPGLRectI; SourceRect: TPGLRectI);
  begin
    Dest.MakeCurrentTarget();
    glBindFrameBuffer(GL_READ_FRAMEBUFFER, Self.FrameBuffer);
    glBindFrameBuffer(GL_DRAW_FRAMEBUFFER, Dest.FrameBuffer);
    glBlitFrameBuffer(SourceRect.Left, SourceRect.Bottom, SourceRect.Right, SourceRect.Top,
      DestRect.Left, DestRect.Bottom, DestRect.Right, DestRect.Top, GL_COLOR_BUFFER_BIT, GL_NEAREST);

    glBindFrameBuffer(GL_FRAMEBUFFER, Self.FrameBuffer);
  end;

procedure TPGLRenderTexture.StretchBlt(Dest: TPGLRenderTarget; destX, destY, destWidth, destHeight, srcX,srcY,srcWidth,srcHeight: GLFloat);
Var
DestVer: TPGLVectorQuad; // Screen Coordinates of Destination
DestCor: TPGLVectorQuad; // Texture Coordinates of Destination
SourceCor: TPGLVectorQuad; // Texture Coordinates of Source
Rot: TPGLMatrix4;

SourceBounds,DestBounds: TPGLRectI;

  begin

    Self.DrawLastBatch();

    // calcuate new texture coordinates for the source and the destination draw coordinates

    DestBounds := RectIWH(DestX, DestY, DestWidth, DestHeight);
    SourceBounds := RectIWH(SrcX, SrcY, SrcWidth, SrcHeight);

    DestVer[0] := Vec2(DestBounds.Left, DestBounds.Bottom);
    DestVer[1] := Vec2(DestBounds.Right, DestBounds.Bottom);
    DestVer[2] := Vec2(DestBounds.Right, DestBounds.Top);
    DestVer[3] := Vec2(DestBounds.Left, DestBounds.Top);

    SourceCor[0] := Vec2(SourceBounds.Left, SourceBounds.Bottom);
    SourceCor[1] := Vec2(SourceBounds.Right, SourceBounds.Bottom);
    SourceCor[2] := Vec2(SourceBounds.Right, SourceBounds.Top);
    SourceCor[3] := Vec2(SourceBounds.Left, SourceBounds.Top);

    RotatePoints(SourceCor,Vec2(SourceBounds.X, SourceBounds.Y),Self.Angle);



    Dest.MakeCurrentTarget();
    Self.Buffers.Bind();

    glEnable(GL_SCISSOR_TEST);
    glScissor(trunc(DestX),trunc(Dest.Height - DestY - DestHeight),trunc(DestWidth), trunc(DestHeight));

    PGL.BindTexture(0,Self.Texture);

    Self.Buffers.BindVBO(1);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(DestVer),@DestVer);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(2);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(SourceCor),@SourceCor);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(3);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(DestCor),@DestCor);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindSSBO(0);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 15, Self.Buffers.CurrentSSBO.Buffer);

    TextureProgram.Use();

    glUniform1i(PGLGetUniform('tex'),0);
    glUniform3f(PGLGetUniform('ColorVals'),SElf.ColorVals.Red,
                                           SElf.ColorVals.Green,
                                           SElf.ColorVals.Blue);

    glUniform3f(PGLGetUniform('ColorOverlay'),SElf.ColorOverlay.Red,
                                              SElf.ColorOverlay.Green,
                                              SElf.ColorOverlay.Blue);
    glUniform1i(PGLGetUniform('GreyScale'),SElf.GreyScale.ToInteger);
    glUniform1i(PGLGetUniform('MonoChrome'),SElf.MonoChrome.ToInteger);
    glUniform1f(PGLGetUniform('Brightness'),SElf.Brightness);
    glUniform1i(PGLGetUniform('Negative'),Self.Negative.Tointeger);
    glUniform1f(PGLGetUniform('Opacity'),Self.Opacity);
    glUniform1f(pglGetUniform('PixelSize'),Dest.PixelSize);
    glUniform1f(pglGetUniform('planeWidth'),Dest.Width);
    glUniform1f(pglGetUniform('planeHeight'),Dest.Height);
    glUniform1f(pglGetUniform('sourceWidth'),Self.Width);
    glUniform1f(pglGetUniform('sourceHeight'),Self.Height);

    glUniform4f(PGLGetUniform('Swizzle'),Self.SwizzleVals.x, Self.SwizzleVals.Y, Self.SwizzleVals.Z, Self.Swizzle.ToInteger);

    glDrawArrays(GL_QUADS,0,4);

    glDisable(GL_SCISSOR_TEST);

  end;

procedure TPGLRenderTexture.StretchBlt(Dest: TPGLRenderTarget; destRect,srcRect: TPGLRectI);
  begin
    Self.StretchBlt(Dest,destRect.Left,destRect.Top,destRect.Width,destRect.Height,srcRect.Left,srcRect.Top,srcRect.Width,srcRect.Height);
  end;

procedure TPGLRenderTexture.StretchBlt(Dest: TPGLRenderTarget; destRect,srcRect: TPGLRectF);
  begin
    Self.StretchBlt(Dest,destRect.Left,destRect.Top,destRect.Width,destRect.Height,srcRect.Left,srcRect.Top,srcRect.Width,srcRect.Height);
  end;


procedure TPGLRenderTexture.BlendBlt(Dest: TPGLRenderTarget; destX, destY, destWidth, destHeight, srcX,srcY,srcWidth,srcHeight: GLFloat);
Var
NewCor: TPGLVectorQuad;
NewVer: TPGLVectorQuad;
SourceCor: TPGLVectorQuad;
SourceRect,DestRect: TPGLRectF;
Rot: TPGLMatrix4;

  begin

    Self.DrawLastBatch();
    Dest.DrawLastBatch();

    // calcuate new texture coordinates for the source and the destination draw coordinates

    SourceRect := RectFWH(SrcX,SrcY,SrcWidth,SrcHeight);
    DestRect := RectFWH(DestX,DestY,DestWidth,DestHeight);

    SourceCor[0] := Vec2(SourceRect.Left / Self.Width, SourceRect.Bottom / Self.Height);
    SourceCor[1] := Vec2(SourceRect.Right / Self.Width, SourceRect.Bottom / Self.Height);
    SourceCor[2] := Vec2(SourceRect.Right / Self.Width, SourceRect.Top / Self.Height);
    SourceCor[3] := Vec2(SourceRect.Left / Self.Width, SourceRect.Top / Self.Height);

//    RotatePoints(SourceCor,Vec2(SourceRect.X / Self.Width, SourceRect.Y / Self.Height), Self.Angle);

    NewCor[0] := Vec2(DestRect.Left / Dest.Width, DestRect.Bottom / Dest.Height);
    NewCor[1] := Vec2(DestRect.Right / Dest.Width, DestRect.Bottom / Dest.Height);
    NewCor[2] := Vec2(DestRect.Right / Dest.Width, DestRect.Top / Dest.Height);
    NewCor[3] := Vec2(DestRect.Left / Dest.Width, DestRect.Top / Dest.Height);

    NewVer[0] := Vec2(DestRect.Left, DestRect.Bottom);
    NewVer[1] := Vec2(DestRect.Right, DestRect.Bottom);
    NewVer[2] := Vec2(DestRect.Right, DestRect.Top);
    NewVer[3] := Vec2(DestRect.Left, DestRect.Top);


    Dest.MakeCurrentTarget();
    Self.Buffers.Bind();

    PGL.BindTexture(0,Self.Texture2d);
    PGL.BindTexture(1,Dest.Texture2d);

    glEnable(GL_SCISSOR_TEST);
    glScissor(trunc(DestRect.Left), trunc(Dest.Height - DestRect.Height - DestRect.Top), trunc(DestRect.Width), Trunc(DestRect.Height));

    Self.Buffers.BindVBO(1);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(NewVer),@NewVer);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(2);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(NewCor),@NewCor);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(3);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(SourceCor),@SourceCor);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    BlendBltProgram.Use();

    glUniform1f(PGLGetUniform('planeWidth'),Dest.Width);
    glUniform1f(PGLGetUniform('planeHeight'),Dest.Height);

    glUniform1i(PGLGetUniform('SourceTex'),0);
    glUniform1i(PGLGetUniform('DestTex'),1);

    glDrawArrays(GL_QUADS,0,4);

    glActiveTexture(GL_TEXTURE0);

    glDisable(GL_SCISSOR_TEST);

  end;


procedure TPGLRenderTexture.BlendBlt(Dest: TPGLRenderTarget; DestRect: TPGLRectF; SourceRect: TPGLRectF);
  begin
    Self.BlendBlt(Dest,DestRect.Left,DestRect.Top,DestRect.Width,DestRect.HEight,SourceREct.Left,SourceRect.Top,SourceRect.Width,SourceRect.Height);
  end;


procedure TPGLRenderTexture.CopyBlt(Dest: TPGLRenderTarget; destX, destY, destWidth, destHeight, srcX,srcY,srcWidth,srcHeight: GLFloat);
Var
NewVer: TPGLVectorQuad;
SourceCor: TPGLVectorQuad;
SourceRect,DestRect: TPGLRectF;
Rot: TPGLMatrix4;

  begin

    Self.DrawLastBatch();

    // calcuate new texture coordinates for the source and the destination draw coordinates

    SourceRect := RectFWH(SrcX,SrcY,abs(SrcWidth),abs(SrcHeight));
    DestRect := RectFWH(DestX,DestY,abs(DestWidth),abs(DestHeight));

    SourceCor[0] := Vec2(SourceRect.Left, SourceRect.Top);
    SourceCor[1] := Vec2(SourceRect.Right, SourceRect.Top);
    SourceCor[2] := Vec2(SourceRect.Right, SourceRect.Bottom);
    SourceCor[3] := Vec2(SourceRect.Left, SourceRect.Bottom);

    RotatePoints(SourceCor,Vec2(SourceRect.X, SourceRect.Y),Self.Angle);

    NewVer[0] := Vec2(DestRect.Left, DestRect.Top);
    NewVer[1] := Vec2(DestRect.Right, DestRect.Top);
    NewVer[2] := Vec2(DestRect.Right, DestRect.Bottom);
    NewVer[3] := Vec2(DestRect.Left, DestRect.Bottom);

    if destWidth < 0 then begin
      MirrorPoints(NewVer);
    end;

    if destHeight < 0 then begin
      FlipPoints(NewVer);
    end;

    Dest.MakeCurrentTarget();
    Dest.Buffers.Bind();

    glEnable(GL_SCISSOR_TEST);
    glScissor(trunc(DestRect.Left), trunc(Dest.Height - DestRect.Height - DestRect.Top), trunc(DestRect.Width), Trunc(DestRect.Height));

    PGL.BindTexture(0,Self.TExture);


    Dest.Buffers.BindVBO(1);
    Dest.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(NewVer),@NewVer);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Dest.Buffers.BindVBO(2);
    Dest.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(SourceCor),@SourceCor);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    CopyBltProgram.Use();

    glUniform1f(PGLGetUniform('planeWidth'),Dest.Width);
    glUniform1f(PGLGetUniform('planeHeight'),Dest.Height);
    glUniform1f(PGLGetUniform('PixelSize'),Dest.PixelSize);

    glUniform1i(PGLGetUniform('SourceTex'),0);

    glDrawArrays(GL_QUADS,0,4);

    glDisable(GL_SCISSOR_TEST);

  end;


procedure TPGLRenderTexture.CopyBlt(Dest: TPGLRenderTarget; DestRect,SourceRect: TPGLRectF);

  begin
    Self.CopyBlt(Dest,DestRect.Left,DestRect.Top,DestRect.Width,DestRect.Height,SourceRect.Left,SourceRect.Top,SourceRect.Width,SourceRect.Height);
  end;


procedure TPGLRenderTexture.SaveToFile(FileName: string; Channels: Integer = 4);
Var
Succeed: LongBool;
Pixels: Array of Byte;
Format: glEnum;
FileChar: TPGLCharArray;
  begin


    glBindFrameBuffer(GL_FRAMEBUFFER,Self.FrameBuffer);
    glBindTexture(GL_TEXTURE_2D,Self.Texture);
    SetLength(Pixels,(Self.Width * Self.Height) * 4);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);

    FileChar := PGLStringtoChar(FileName);
    Succeed := stbi_write_bmp(pAnsiChar(FileChar),Self.Width,Self.Height,4,Pointer(Pixels));

  end;


procedure TPGLRenderTexture.SetMultiSampled(MultiSampled: Boolean);
  begin
    Self.pisMultiSampled := MultiSampled;
  end;


procedure TPGLRenderTexture.SetDrawBuffers(Buffers: array of GLEnum);
Var
I: Long;
Buffs: GLEnum;

  begin

    Buffs := GL_COLOR_ATTACHMENT0 + Buffers[0];

    if Length(Buffers) > 1 then begin
      for I := 1 to High(Buffers) Do begin
        Buffs:= Buffs or (GL_COLOR_ATTACHMENT0 + Buffers[i]);
      end;
    end;

    Self.MakeCurrentTarget();
    glDrawBuffers(Length(Buffers), @Buffs);
  end;

procedure TPGLRenderTexture.SetPixelFormat();
  begin

    Case Self.pBitDepth of

      32:
        begin
          Self.pPixelFormat := GL_RGBA;
        end;

      24:
        begin
          Self.pPixelFormat := GL_RGB;
        end;

      16:
        begin
          Self.pPixelFormat := GL_RGB4;
        end;

      8:
        begin
          Self.pPixelFormat := GL_RED;
        end;

    end;

  end;


procedure TPGLRenderTexture.ChangeTexture(Texture: TPGLTexture);
Var
Buffs: GLInt;
  begin

    Self.Texture := Texture.Handle;
    Self.pWidth := Texture.Width;
    Self.pHeight := Texture.Height;

    Buffs := GL_COLOR_ATTACHMENT0;

    Self.MakeCurrentTarget();
    glInvalidateFrameBuffer(GL_FRAMEBUFFER,1,@Buffs);
    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,Texture.Handle,0);
    glDrawBuffer(GL_COLOR_ATTACHMENT0);

  end;


procedure TPGLRenderTexture.RestoreTexture();

Var
Pixels: PByte;
Pixels2: PByte;
PLoc1,PLoc2: Pointer;
PSize: GLint;
I,Z: Long;
OutPar: GLInt;
OldTexture: GLUint;
W,H: GLint;

  begin

    Self.DrawLastBatch();

    Self.MakeCurrentTarget();

    // Swap the old texture back into the frame buffer
    OldTexture := Self.Texture;
    Self.Texture := Self.Texture2D;

    // Restore original dimensions
    PGL.BindTexture(0,Self.Texture2D);
    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,Self.Texture2D,0);

    glGetTexLevelParameteriv(GL_TEXTURE_2D,0,GL_TEXTURE_WIDTH,@OutPar);
    Self.pWidth := OutPar;

    glGetTexLevelParameteriv(GL_TEXTURE_2D,0,GL_TEXTURE_HEIGHT,@OutPar);
    Self.pHeight := OutPar;

    glDrawBuffer(GL_COLOR_ATTACHMENT0);

    // Flip the Replaced Texture
    PGL.BindTexture(0,OldTexture);
    glGetTexLevelParameterIV(GL_TEXTURE_2D,0,GL_TEXTURE_WIDTH,@W);
    glGetTexLevelParameterIV(GL_TEXTURE_2D,0,GL_TEXTURE_HEIGHT,@H);
    PSize := (W * H) * 4;
    Pixels := GetMemory(PSize);
    Pixels2 := GetMemory(PSize);
    PLoc1 := Pixels;
    PLoc2 := Pixels2;
    Pixels2 := Pixels2 + (PSize - 1) - (W*4);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);

    for I := 0 to H - 1 Do begin
      Move(Pixels[0],Pixels2[0],W*4);
      Inc(Pixels,W*4);
      Dec(Pixels2,W*4);
    end;

    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,W,H,0,GL_RGBA,GL_UNSIGNED_BYTE,PLoc2);

    Pixels := PLoc1;
    Pixels2 := PLoc2;

    FreeMemory(Pixels);
    FreeMemory(Pixels2);

  end;





///////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// TPGLRenderMap /////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

constructor TPGLRenderMap.Create(Width,Height,SelectionWidth,SelectionHeight,ViewPortWidth,ViewPortHeight: GLUInt);

Var
ReturnTexture: GLUInt;
I: Long;

  begin

    Inherited Create(Width,Height);

    glGenFrameBuffers(1,@Self.FrameBuffer);
    glBindFrameBuffer(GL_FRAMEBUFFER,Self.FrameBuffer);

    // Non-Smooth regular texture
    Pgl.GenTexture(Self.Texture2D);
    glBindTexture(GL_TEXTURE_2D,Self.TExture2D);
    glTexImage2D(GL_TEXTURE_2D,0,PGL.TextureFormat,SelectionWidth,SelectionHeight,0,PGL.WindowColorFormat,GL_UNSIGNED_BYTE,nil);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindTexture(GL_TEXTURE_2D,0);

    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,Self.Texture2D,0);

    glDrawBuffer(GL_COLOR_ATTACHMENT0);
    glReadBuffer(GL_COLOR_ATTACHMENT0);

    glBindFrameBuffer(GL_FRAMEBUFFER,0);

    // set 2D non-smooth texture as default;
    Self.Texture := Self.Texture2d;

    Self.FillEBO;

    PGLMatrixScale(Self.Scale,SelectionWidth,SelectionHeight);

    // set dimensions of memory image, selection rect, and view port
    Self.pTotalWidth := Width;
    Self.pTotalHeight := Height;
    Self.pSelectionRect := RectIWH(0,0,SelectionWidth,SelectionHeight);
    Self.pViewPort := RectIWH(0,0,ViewPortWidth,ViewPortHeight);

    // allocate memory and obtain handle for image
    Self.Data := GetMemory((Self.pTotalWidth * Self.pTotalHeight) * 4);

    SetLength(Self.ScanLine,Self.pTotalHeight);

    for I := 0 to High(Self.Scanline) Do begin
      Self.ScanLine[i] := GetMemory(Self.pTotalWidth * 4);
    end;

  end;


procedure TPGLRenderMap.SetSelectionRectSize(Width: Cardinal; Height: Cardinal);
Var
ReturnTexture: GLUInt;

  begin

    Self.WriteSelectionToImage();

    Self.MakeCurrentTarget();
    ReturnTexture := PGL.TexUnit[0];
    PGL.BindTexture(0,Self.Texture2D);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,Width,Height,0,GL_RGBA,GL_UNSIGNED_BYTE,nil);

    PGL.BindTexture(0,ReturnTexture);

  end;


procedure TPGLRenderMap.MoveSelectionRect(ByX: Cardinal; ByY: Cardinal);

  begin

    Self.DrawLastBatch();
    Self.WriteSelectionToImage();

    // Move it
    Self.SelectionRect.Translate(ByX,ByY);

    // Keep it in bounds
    if Self.SelectionRect.Left < 0 then begin
      Self.pSelectionRect.Left := 0;
      Self.pSelectionRect.Update(FROMLEFT);
    end;

    if Self.SelectionRect.Right > integer(Self.TotalWidth) then begin
      Self.pSelectionRect.Right := Self.TotalWidth - 1;
      Self.pSelectionRect.Update(FROMRIGHT);
    end;

    if Self.SelectionRect.Top < 0 then begin
      Self.pSelectionRect.top := 0;
      Self.pSelectionRect.Update(FROMTOP);
    end;

    if Self.SelectionRect.Bottom > integer(Self.TotalHeight) then begin
      Self.pSelectionRect.Bottom := Self.TotalHeight - 1;
      Self.pSelectionRect.Update(FROMBOTTOM);
    end;


    Self.GetSelectionFromImage(Self.SelectionRect.Left,Self.SelectionRect.Top);

  end;


procedure TPGLRenderMap.SetSelectionRect(Left: Cardinal; Top: Cardinal);
  begin

    if Left + Cardinal(Self.SelectionRect.Width) > Self.TotalWidth then begin
      Left := (Self.TotalWidth - 1) - Cardinal(Self.SelectionRect.Width);
    end;

    if Top + Cardinal(Self.SelectionRect.Height) > Self.TotalHeight then begin
      Top := (Self.TotalHeight - 1) - Cardinal(Self.SelectionRect.Height);
    end;

    Self.pSelectionRect.Left := Left;
    Self.pSelectionRect.Update(FROMLEFT);
    Self.pSelectionRect.Top := Top;
    Self.pSelectionRect.Update(FROMTOP);

  end;


procedure TPGLRenderMap.UpdateImageSelection();
  begin
    Self.DrawLastBatch();
    Self.WriteSelectionToImage();
  end;

procedure TPGLRenderMap.SetViewPortSize(Width: Cardinal; Height: Cardinal);
  begin

  end;


procedure TPGLRenderMap.MoveViewPort(ByX: Cardinal; ByY: Cardinal);
  begin

  end;


procedure TPGLRenderMap.SetViewPort(Left: Cardinal; Top: Cardinal);
  begin

  end;


procedure TPGLRenderMap.WriteSelectionToImage;

Var
Pixels: Array of TPGLColorI; // array of pixels to write to memory
CurPixel: GLUInt; // Current starting location of Pixels to write from
DestPtr: PByte; // Points to current address in Data being written to
CurLine: GLUInt; // Current Scan Line of Image
ReturnTexture: GLUInt; // the original texture bound to texture unit 0
I: GLUInt;

  begin

    // Get image data from texture
    SetLength(Pixels,Self.SelectionRect.Width * Self.SelectionRect.Height);

    ReturnTexture := PGL.TexUnit[0];
    PGL.BindTexture(0,Self.Texture2D);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);


    // row by row, obtain pointer to appropriate place in image memory and write
    // pixels to memory

    CurLine := Self.SelectionRect.Top;
    DestPtr := Self.ScanLine[CurLine];

    CurPixel := 0;

    for I := 1 to Self.SelectionRect.Height Do begin
      Move(Pixels[CurPixel],Pointer(DestPtr)^,SizeOf(TPGLColorI) * Self.SelectionRect.Width);
      CurPixel := CurPixel + Cardinal(Self.SelectionRect.Width);

      if CurLine < Cardinal(Self.SelectionRect.Bottom - 1) then begin
        Inc(CurLine);
        DestPtr := Self.ScanLine[CurLine];
      end;
    end;


    // Return Original Texture to unit 0
    PGL.BindTexture(0,ReturnTexture);

  end;


procedure TPGLRenderMap.GetSelectionFromImage(X: Cardinal; Y: Cardinal);

Var
Pixels: Array of TPGLColorI; // array of pixels to set to Texture
CurPixel: GLUInt; // Current starting location of Pixels to write from
SourcePtr: PByte; // Points to current address in Data being read from
CurLine: GLUInt; // Current Scan Line of Image
ReturnTexture: GLUInt; // the original texture bound to texture unit 0
I: GLUInt;

  begin

    // Adjust X and Y if the selection would fall outside the bounds of the data
    if X + Cardinal(Self.SelectionRect.Width) > Self.TotalWidth then begin
      X := Self.TotalWidth - Cardinal(Self.SelectionRect.Width);
    end;

    if Y + Cardinal(Self.SelectionRect.Height) > Self.TotalHeight then begin
      Y := Self.TotalHeight - Cardinal(Self.SelectionRect.Height);
    end;

    // Get image data from texture
    SetLength(Pixels,Self.SelectionRect.Width * Self.SelectionRect.Height);

    // Row By Row, extract pixels from data

    CurLine := Self.SelectionRect.Top;
    SourcePtr := Self.ScanLine[CurLine];


    CurPixel := 0;

    for I := 1 to Self.SelectionRect.Height Do begin
      Move(SourcePtr,Pixels[CurPixel],SizeOf(TPGLColorI) * Self.SelectionRect.Width);
      CurPixel := CurPixel + Cardinal(Self.SelectionRect.Width);

      if CurLine < Cardinal(Self.SelectionRect.Bottom - 1) then begin
        Inc(CurLine);
        SourcePtr := Self.ScanLine[CurLine];
      end;

    end;

    // Update texture with pixels
    ReturnTexture := PGL.TexUnit[0];
    PGL.BindTexture(0,Self.TExture2D);
    glTexSubImage2D(GL_TEXTURE_2D,0,0,0,Self.SelectionRect.Width,Self.SelectionRect.Height,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);

    // return oringal texture
    PGL.BindTexture(0,ReturnTexture);

  end;


function TPGLRenderMap.RetrievePixelsFromMemory(SRect: TPGLRectI): TColorArray;
Var
Pixels: TColorArray;
CurPixel: GLUInt; // Current starting location of Pixels to write from
SourcePtr: PByte; // Points to current address in Data being read from
CurLine: GLUInt; // Current Scan Line of Image
ReturnTexture: GLUInt; // the original texture bound to texture unit 0
I: GLUInt;

  begin

    // Adjust X and Y if the selection would fall outside the bounds of the data
//    if SRect.Right >= Integer(Self.TotalWidth) then begin
//      SRect.Left := Self.TotalWidth - SRect.Width;
//      SRect.Update(FROMLEFT);
//    end;
//
//    if SRect.Bottom >= Integer(Self.TotalHeight) then begin
//      SRect.Top := Self.TotalHeight - SRect.Height;
//      SRect.Update(FROMTOP);
//    end;


    // Get image data from texture
    SetLength(Pixels, (SRect.Width * SRect.Height));

    // Row By Row, extract pixels from data

//    SourcePtr := Self.Data;
//    SourcePtr := SourcePtr + (((Self.pTotalWidth) * Cardinal(SRect.Top)) * 4) + (SRect.Left * 4);

    CurLine := SRect.Top + (SRect.Height - 1);
    SourcePtr := Self.ScanLine[CurLine];

    CurPixel := 0;

    for I := 1 to SRect.Height Do begin
      Move(Pointer(SourcePtr)^, Pixels[CurPixel], 16 * SRect.Width);
      CurPixel := CurPixel + Cardinal(SRect.Width);
//      SourcePtr := SourcePtr + (Self.TotalWidth * 4);
      if CurLine > 0 then begin
        Dec(CurLine);
        SourcePtr := Self.ScanLine[CurLine];
      end;

    end;


    Result := Pixels;

  end;


///////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// TPGLWindow /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
constructor TPGLWindow.Create(inWidth,inHeight: GLInt);

Var
I: Long;

	begin
    inHerited;

    PGL.Window := Self;

    Self.SetSize(inWidth,inHeight);
    Self.pOrgWidth := inWidth;
    Self.pOrgHeight := inheight;

    Self.FrameBuffer := 0;
    Self.Texture2D := 0;
    Self.Texture := Self.Texture2D;

    // Create the framebuffer for temporary use
    glGenFrameBuffers(1,@Self.TempBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER,Self.TempBuffer);
    PGL.BindTexture(0,Self.Texture2D);
    glFrameBufferTexture2d(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,Self.Texture2D,0);
    PGL.UnBindTexture(Self.Texture2D);
    glBindFrameBuffer(GL_FRAMEBUFFER,0);

    // Prepare Buffer Objects
    Self.FillEBO;

    PGLMatrixScale(self.Scale,Self.Width,Self.Height);

    Self.pDisplayRectOrgWidth := inWidth;
    Self.pDisplayRectOrgHeight := inHeight;

  end;


procedure TPGLWindow.Close();
  begin
    pglRunning := false;
    PGL.Context.Close();
  end;


procedure TPGLWindow.DisplayFrame();
  begin
    SwapBuffers(PGL.Context.DC);
  end;


procedure TPGLWindow.onResize;

Var
Per: GLFloat;
NewWidth,NewHeight: GLInt;

  begin

  end;


procedure TPGLWindow.SetSize(W,H: GLUInt);
  begin
    PGL.Context.SetSize(W,H,True);
    Self.pWidth := PGL.Context.Width;
    Self.pHeight := PGL.Context.Height;
  end;

procedure TPGLWindow.SetFullScreen(isFullScreen: Boolean);
  begin
    Self.pFullScreen := isFullScreen;
    PGL.Context.SetFullScreen(isFullScreen);
  end;

procedure TPGLWindow.SetTitleBar(hasTitleBar: Boolean);
  begin
    Self.pTitleBar := hasTitleBar;
    PGL.Context.SetHasCaption(hasTitleBar);
  end;

procedure TPGLWindow.SetTitle(inTitle: String);
  begin
    Self.pTitle := inTitle;
    PGL.Context.SetTitle(inTitle);
  end;

procedure TPGLWindow.SetScreenPosition(X,Y: GLInt);
  begin
    PGL.Context.SetPosition(X,Y);
  end;

procedure TPGLWindow.CenterInScreen();
  begin
    PGL.Context.SetPosition(trunc((PGL.Context.ScreenWidth / 2) - (PGL.Context.Width / 2)),
      trunc((PGL.Context.ScreenHeight / 2) - (PGL.Context.Height / 2)));
  end;

procedure TPGLWindow.Maximize();
  begin
    PGL.Context.Maximize();
    PGL.Window.pWidth := PGL.Context.Width;
    PGL.Window.pHeight := PGL.Context.Height;
  end;

procedure TPGLWindow.Restore();
  begin
    PGL.Context.Restore();
    PGL.window.pWidth := PGL.Context.Width;
    PGL.Window.pHeight := PGL.Context.Height;
  end;

procedure TPGLWindow.Minimize();
  begin
    PGL.Context.Minimize();
    PGL.Window.pWidth := PGL.Context.Width;
    PGL.Window.pHeight := PGL.Context.Height;
  end;

procedure TPGLWindow.SetDisplayRect(Rect: TPGLRectI; ScaleOnResize: Boolean);
  begin
    Self.pDisplayRect.Width := Rect.Width;
    Self.pDisplayRect.Height := Rect.Height;
    Self.pDisplayRect.Left := Rect.Left;
    Self.pDisplayRect.Top := Rect.Top;
    Self.pDisplayRect.SetTopLeft(Rect.Left, Rect.Top);

    Self.pDisplayRectScale := ScaleOnResize;
    Self.pDisplayRectUsing := True;
  end;


procedure TPGLWindow.SetIcon(Image: TPGLImage);
  begin
    PGL.Context.SetIconFromBits(Image.Handle, Image.Width, Image.Height, 32);
  end;

procedure TPGLWindow.SetIcon(FileName: String; TransparentColor: TPGLColorI);
  begin
    PGL.Context.SetIconFromFile(FileName);
  end;


///////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// pglTileMap ///////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////




///////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// TPGLImage /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////


procedure TPGLImage.DefineData();
Var
I: Int32;
  begin
    Self.pDataSize := (Self.Width * Self.Height) * 4;
    Self.DataEnd := Self.Handle;
    Self.DataEnd := Self.DataEnd + Self.DataSize;

    // Get pointers to the start of each row
    SetLength(Self.RowPtr, Self.Height);
    for I := 0 to High(Self.RowPtr) do begin
      Self.RowPtr[i] := Self.Handle;
      Self.RowPtr[i] := Self.RowPtr[i] + ((Self.Width * I) * 4);
    end;
  end;

constructor TPGLImage.Create(Width: GLUint = 1; Height: GLUint = 1);
  begin
    Self.isValid := True;
    Self.pWidth := Width;
    Self.pHeight := Height;
    Self.pHandle := AllocMem((Width * Height) * 4);
    Self.DefineData;
  end;

constructor TPGLImage.CreateFromFile(FileName: String);
Var
SourcePointer: PByte;
  begin
    SourcePointer := stbi_load(PAnsiChar(AnsiString(FileName)),Self.pWidth,Self.pHeight,Self.pChannels,4);
    Self.pHandle := GetMemory((Self.pWidth * Self.pHeight) * 4);
    Move(SourcePointer[0], Self.pHandle[0], (Self.pWidth * Self.pHeight) * 4);
    stbi_image_free(SourcePointer);
    Self.IsValid := True;
    Self.DefineData;
  end;

constructor TPGLImage.CreateFromMemory(Source: Pointer; Width,Height: NativeUInt; Size: NativeUInt);
  begin

    Self.IsValid := True;
    Self.pWidth := Width;
    Self.pHeight := Height;
    Self.pChannels := 4;
    Self.pHandle := GetMemory(GLInt(Size));
    Move(Source^,Self.Handle^,Size);

    Self.DefineData();
  end;

Destructor TPGLImage.Destroy();
  begin
    Self.Delete();
    Inherited;
  end;

procedure TPGLImage.Delete();
Var
Ptr: PByte;
RetVal: Integer;
  begin
    if Self.pHandle <> nil then begin
      Try
        RetVal := FreeMemory(Self.pHandle);
        Self.pHandle := Nil;
      Except
        Self.SaveToFile(pglEXEPath + 'Fail Test.bmp');
      end;
    end;
  end;

procedure TPGLImage.Clear();
  begin

    Self.pHandle := nil;
    Self.isValid := FAlse;
    Self.pWidth := 0;
    Self.pHeight := 0;
    Self.pChannels := 0;
    Self.Data := nil;
  end;

procedure TPGLImage.LoadFromFile(FileName: AnsiString);
Var
BufferSize: GLInt;
SourcePointer: PByte;
CurPointer: PByte;
I: GLInt;
ByteData: TPGLColorI;

  begin

    Self.Clear();

    Self.pHandle := stbi_load(PAnsiChar(FileName),Self.pWidth,Self.pHeight,Self.pChannels,4);
    Self.IsValid := True;

    // set data array length and move image data 4-bytes at a time
    SetLength(Self.Data,Width * Height);
    BufferSize := (Width * Height) * 4;
    SourcePointer := Self.Handle;

    for I := 0 to BufferSize -1 Do begin

      CurPointer := SourcePointer;
      ByteData.REd := CurPointer^;

      CurPointer := SourcePointer + 1;
      ByteData.Green := CurPointer^;

      CurPointer := SourcePointer + 2;
      ByteData.Blue := CurPointer^;

      CurPointer := SourcePointer + 3;
      ByteData.Alpha := CurPointer^;

      Self.Data[i] := ByteData;

      SourcePointer := CurPointer + 1;

    end;

    SourcePointer := nil;
    CurPointer := nil;

  end;

procedure TPGLImage.LoadFromMemory(Source: Pointer; Width,Height: GLUInt);
  begin

    if Self.Handle <> nil then begin
      stbi_image_free(Self.Handle);
      Self.pHandle := Nil;
      Self.IsValid := False;
    end;

    Self.IsValid := True;
    Self.pChannels := 4;
    Self.pWidth := Width;
    Self.pHeight := Height;

    Self.pHandle := GetMemory((Width * Height) * 4);
    Move(Pointer(Source)^,Pointer(Self.handle)^,(Width * Height) * 4);

  end;


procedure TPGLImage.CopyFromImage(Var Source: TPGLImage);
Var
BufferSize: GLInt;
I: GLInt;
SourcePointer: PByte;
CurPointer: PByte;
ByteData: TPGLColorI;

  begin

    if Source.isValid = False then begin
      pglAddError('Could not copy from image. Source is not valid!');
      Exit;
    end;

    BufferSize := (Source.Width * Source.Height * 4);
    Self.pHandle := GetMemory(BufferSize);
    Move(Pointer(Source.Handle)^,Pointer(Self.Handle)^,BufferSize);
    SetLength(Self.Data,Source.Width * Source.Height);

    for I := 0 to High(Source.Data) Do begin
      Self.Data[i] := Source.Data[i];
    end;

    Self.pWidth := Source.Width;
    Self.pHeight := Source.Height;
    Self.pChannels := Source.Channels;

    Self.isValid := true;

    Self.DefineData();
  end;


procedure TPGLImage.CopyFromImage(Var Source: TPGLImage; SourceRect, DestRect: TPGLRectI);

Var
OrgPtr, DestPtr: PByte;
OrgLoc, DestLoc: GLInt;
I,Z: Long;
X,Y: Long;
WidthRatio, HeightRatio: GLFloat;

  begin
    OrgPtr := Source.Handle;
    DestPtr := Self.Handle;

    if (SourceRect.Width <> DestRect.Width) and (SourceRect.Height <> DestRect.Height) then begin
      // if Rect dimensions are not the same, must account for stretch/shrink, copy one pixel at a time

      // set ratios between widths and heights
      WidthRatio := SourceRect.Width / DestRect.Width;
      HeightRatio := SourceRect.Height / DestRect.Height;

      for Z := 0 to DestRect.Height - 1 Do begin
        for I := 0 to DestRect.Width - 1 Do begin

          X := trunc(SourceRect.Left + (I * WidthRatio));
          Y := trunc(SourceRect.Top + (Z * HeightRatio));
          OrgLoc := ((Y * Source.Width) + X) * 4;
          DestLoc := ((Z * Self.Width) + I) * 4;
          Move(OrgPtr[OrgLoc], DestPtr[DestLoc], 4);

        end;
      end;

    End Else begin
      // if rects are the same size, copy over one entire row at a time
      for Z := 0 to DestRect.Height - 1 Do begin
        OrgLoc := (((SourceRect.Top + Z) * Source.Width) + SourceRect.Left) * 4;
        DestLoc := ((Z * Self.Width) + DestRect.Left) * 4;
        Move(OrgPtr[OrgLoc], DestPtr[DestLoc], 4 * (DestRect.Width));
      end;

    end;

    OrgPtr := Nil;
    DestPtr := Nil;

  end;


constructor TPGLImageHelper.CreateFromTexture(Var Source: TPGLTexture);
Var
Pixels: Array of TPGLColorI;
Failed: Boolean;

  begin
    Self.isValid := true;
    Self.pWidth := Source.Width;
    Self.pHeight := Source.Height;
    Self.pHandle := GetMemory((Source.Width * Source.Height) * 4);
    Self.DefineData;

    SetLength(Pixels, Self.Width * Self.Height);

    PGL.BindTexture(0,Source.Handle);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Self.pHandle);
    PGL.UnBindTexture(Source.Handle);
  end;


procedure TPGLImageHelper.CopyFromTexture(var Source: TPGLTexture);

Var
Pixels: Array of Byte;

  begin

    if Source = nil then Exit;

    Self.pHandle := Nil;
    setLength(Self.Data,0);

    SetLength(Pixels,(Source.Width * Source.Height) * 4);
    PGL.BindTexture(0,Source.Handle);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
    PGL.BindTexture(0,0);

    Self.pWidth := Source.Width;
    Self.pHeight := Source.Height;

    Self.pHandle := GetMemory(SizeOf(Pixels));
    Move(Pixels,Self.pHandle,SizeOf(Pixels));
    SetLength(Self.Data,Self.Width * Self.Height);
    Move(Pixels,Self.Data,SizeOf(Pixels));

  end;



procedure TPGLImage.ReplaceColor(TargetColor: TPGLColorI; NewColor: TPGLColorI);
Var
I,Z: GLInt;
Data: Array of TPGLColorI;
  begin
    SetLength(Data,(Self.Width * Self.Height) * 4);
    Move(Self.Handle^, Data[0], 4 * (Self.Width * Self.Height));

    for I := 0 to High(Data) Do begin
      if Data[I].IsColor(TargetColor, 0.1) then begin
        Data[i] := NewColor;
      end;
    end;

    Move(Data[0], Self.Handle^, 4 * (Self.Width * Self.Height));
  end;


procedure TPGLImage.Darken(Percent: GLFloat);
Var
Ptr: PByte;
Color: TPGLColorI;
I: Long;
Len: Long;

  begin
    Len := (Self.Width * Self.Height);
    Ptr := Self.Handle;

    for I := 0 to Len - 1 Do begin
      Move(Ptr[0],Color,SizeOf(Color));

      if Color.Alpha = 0 then begin
        Ptr := Ptr + 4;
        Continue;
      end;

      Color.Red := Trunc(Color.Red * (1 - Percent));
      Color.Blue := Trunc(Color.Blue * (1 - Percent));
      Color.Green := Trunc(Color.Green * (1 - Percent));
      Move(Color,Ptr[0],SizeOf(Color));
      Ptr := Ptr + 4;
    end;
  end;

procedure TPGLImage.Brighten(Percent: GLFloat);
Var
Ptr: PByte;
Color: TPGLColorI;
I: Long;
Len: Long;

  begin
    Len := (Self.Width * Self.Height);
    Ptr := Self.Handle;

    for I := 0 to Len - 1 Do begin
      Move(Ptr[0],Color,SizeOf(Color));

      if Color.Alpha = 0 then begin
        Ptr := Ptr + 4;
        Continue;
      end;

      Color.Red := ClampIColor(Trunc(Color.Red * (1 + Percent)));
      Color.Blue := ClampIColor(Trunc(Color.Blue * (1 + Percent)));
      Color.Green := ClampIColor(Trunc(Color.Green * (1 + Percent)));
      Move(Color,Ptr[0],SizeOf(Color));
      Ptr := Ptr + 4;
    end;
  end;


procedure TPGLImage.AdjustAlpha(Alpha: Single; IgnoreTransparent: Boolean = True);
Var
Ptr: PByte;
I, Len: Long;
AVal: Byte;

  begin
    Ptr := Self.Handle;
    Ptr := Ptr + 3;
    Len := (Self.Width * Self.Height);

    for I := 0 to Len - 1 Do begin
      Move(Ptr[0],AVal,1);

      if IgnoreTransparent = True then begin
        if AVal = 0 then begin
          Ptr := Ptr + 4;
          Continue;
        end;
      end;

      AVal := trunc(255 * Alpha);
      Move(AVal,Ptr[0],1);
      Ptr := Ptr + 4;
    end;
  end;

procedure TPGLImage.ToGreyScale();
Var
I,Len: Long;
Color: TPGLColorI;
Ptr: PByte;
Max: Byte;

  begin

    Len := Self.Width * Self.Height;
    Ptr := Self.Handle;

    for I := 0 to Len - 1 Do begin

      if Ptr[3] = 0 then begin
        Inc(Ptr,4);
        Continue;
      end;

      Max := trunc((0.2126 * Ptr[0] + 0.7152 * Ptr[1] + 0.0722 * Ptr[2]));
      Ptr[0] := Byte(Max);
      Ptr[1] := Byte(Max);
      Ptr[2] := Byte(Max);
      Inc(Ptr,4);
    end;

  end;

procedure TPGLImage.ToNegative();
Var
I,Len: Long;
Color: TPGLColorI;
Ptr: PByte;
Max: Byte;

  begin

    Len := Self.Width * Self.Height;
    Ptr := Self.Handle;

    for I := 0 to Len - 1 Do begin

      if Ptr[3] = 0 then begin
        Inc(Ptr,4);
        Continue;
      end;

      Ptr[0] := 255 - Ptr[0];
      Ptr[1] := 255 - Ptr[1];
      Ptr[2] := 255 - Ptr[2];
      Inc(Ptr,4);
    end;

  end;


procedure TPGLImage.Smooth();
Var
I,Z,Len: Long;
X,Y: Long;
Ptr: PByte;
SelfPtr: PByte;
CopyData: PByte;
SamPtr: PByte;
Color: TPGLColorI;
ComColor: Array [0..3] of Integer;
Sample: Array [0..8] of TPGLColorI;
CurX, CurY, SamX, SamY: Long;
Count: Long;

  begin

    if Self.DataSize = 0 then Exit;

    Len := Self.Width * Self.Height;
    CopyData := GetMemory(Self.DataSize);
    Move(Self.Handle^,CopyData[0],Self.DataSize);
    Ptr := CopyData;
    SelfPtr := Self.Handle;

    for I := 0 to Len - 1 Do begin
      Move(Ptr[0],Color,4);

      CurY := trunc(I / Self.Width);
      CurX := I - (CurY * Self.Width);

      for X := 0 to 8 Do begin
        Sample[X] := pgl_empty;
      end;

      Count := 0;

      for X := CurX - 1 to CurX + 1 Do begin
        for Y := CurY - 1 to CurY + 1 Do begin

          if (X < 0) And (X >= Self.Width) And (Y < 0) And (Y >= Self.Width) then Continue;

          SamY := (Y * Self.Width ) * 4;
          SamX := X * 4;
          SamPtr := PByte(Self.Handle) + SamX + SamY;
          Move(SamPtr[0],Sample[Count],4);
          Inc(Count);

        end;
      end;

      Count := 0;

      ComColor[0] := 0;
      ComColor[1] := 0;
      ComColor[2] := 0;
      ComColor[3] := 0;

      for X := 0 to 8 do begin
        if Sample[X].Alpha <> 0 then begin
          Inc(Count);
          ComColor[0] := ComColor[0] + Sample[X].Red;
          ComColor[1] := ComColor[1] + Sample[X].Green;
          ComColor[2] := ComColor[2] + Sample[X].Blue;
        end;
      end;


      if Count <> 0 then begin
        Color.Red := trunc(ComColor[0] / Count);
        Color.Green := trunc(ComColor[1] / Count);
        Color.Blue := trunc(ComColor[2] / Count);
        Move(Color,SelfPtr[0],4);
      end;

      Inc(Ptr,4);
      Inc(SelfPtr,4);

    end;

    FreeMem(CopyData);
    Ptr := nil;
    SelfPtr := nil;

  end;


procedure TPGLImage.SaveToFile(FileName: string);
  begin
    stbi_write_bmp(PAnsiChar(AnsiString(FileName)),Self.Width,Self.Height,4,Self.Handle);
  end;


procedure TPGLImage.Resize(NewWidth, NewHeight: GLUint);

Var
OrgWidth, OrgHeight: GLUint;
OrgData: PByte;
NewData: PByte;
OrgDataSize: GLInt;
NewDataSize: GLInt;
OrgPtr: PByte;
NewPtr: PByte;
OrgLoc: GLInt;
NewLoc: GLint;
OrgRows: Array of Array of TPGLColorI;
NewRows: Array of Array of TPGLColorI;
WidthRatio, HeightRatio: GLFloat;
WidthMax, HeightMax: GLUint;
I,Z: GLInt;

  begin

    // record original sizes of image and size of it's data, Get new data size
    OrgWidth := Self.Width;
    OrgHeight := Self.Height;
    OrgDataSize := (OrgWidth * OrgHeight) * 4;
    NewDataSize := (NewWidth * NewHeight) * 4;

    // Get the ratios between the org and new width and height
    WidthRatio := OrgWidth / NewWidth;
    HeightRatio := OrgHeight / NewHeight;

    // Allocate new memory for a copy of the original data and move it from the handle storage
    // set Pointers to start of datas
    OrgData := AllocMem(OrgDataSize);
    OrgPtr := OrgData;
    Move(Self.Handle^, OrgData[0], OrgDataSize);

    // Size arrays of pixels to apporpriate sizes for org data and new data
    SetLength(OrgRows, OrgWidth, OrgHeight);
    SetLength(NewRows, NewWidth, NewHeight);

    // Move orgdata to org rows
    OrgLoc := 0;
    for Z := 0 to OrgHeight - 1 Do begin
      for I := 0 to OrgWidth - 1 Do begin
        Move(OrgPtr[OrgLoc], OrgRows[I,Z], 4);
        OrgLoc := OrgLoc + 4;
      end;
    end;

    // Move OrgRows to NewRows
    for Z := 0 to NewHeight - 1 Do begin
      for I := 0 to NewWidth - 1 Do begin
        NewRows[I,Z] := OrgRows[trunc(I * WidthRatio), trunc(Z * HeightRatio)];
      end;
    end;

    //Replace image handle and move in new data, resize image
    if Self.Handle <> nil then begin
        FreeMemory(Self.pHandle);
    end;

    Self.pHandle := GetMemory(NewDataSize);

    NewLoc := 0;
    NewPtr := Self.Handle;
    for Z := 0 to NewHeight - 1 Do begin
      for I := 0 to NewWidth - 1 Do begin
        Move(NewRows[I,Z], NewPtr[NewLoc], 4);
        NewLoc := NewLoc + 4;
      end;
    end;

    Self.pWidth := NewWidth;
    Self.pHeight := NewHeight;

    // Clean Up
    Finalize(OrgData, OrgDataSize);
    FreeMem(OrgData, OrgDataSize);
    Finalize(OrgRows[0,0], OrgWidth * OrgHeight);
    Finalize(NewRows[0,0], NewWidth * NewHeight);
    OrgData := nil;
    NewData := nil;
    OrgPtr := nil;
    NewPtr := nil;

  end;


function TPGLImage.Pixel(X: Integer; Y: Integer): TPGLColorI;

Var
IPtr: PByte;

  begin

    if Self.DataSize = 0 then begin
      Result := pgl_Empty;
      Exit;
    end;

    // Read pixels directly from Image memory location
    IPtr := Self.Handle;
    IPtr := IPtr + ((Y * trunc(Self.Width) + X) * 4);

    Move(IPtr[0],Result,4);
  end;


procedure TPGLImage.SetPixel(Color: TPGLColorI; X: Integer; Y: Integer);
Var
IPtr: PByte;
  begin
    // Write Color directly to image data

    if (X >= Self.Width) or (X < 0) or (Y >= Self.Height) or (Y < 0) then Exit;

    IPtr := Self.RowPtr[Y] + (X * 4);
    Move(Color, IPtr[0], SizeOf(TPGLColorI));
  end;

procedure TPGLImage.BlendPixel(Color: TPGLColorI; X: Integer; Y: Integer; SourceFactor: GLFloat);
Var
IPtr: PByte;
ILoc: Integer;
DestColor: TPGLColorI;
SourceColor: TPGLColorI;
DestFactor: GLFloat;
  begin
    // Write Color directly to image data

    if (X >= Self.Width) or (Y >= Self.Height) then Exit;

    // Get Pointer to Pixel
    IPtr := Self.RowPtr[Y] + (X * 4);

    // Move Current source pixel to cache
    Move(IPtr[0],DestColor,SizeOf(TPGLColorI));

    // Calc dest factor based on source factor
    DestFactor := 1 - SourceFactor;

    // BLEND IT!
    SourceColor.Red := trunc((Color.Red * SourceFactor) + (DestColor.Red * DestFactor));
    SourceColor.Green := trunc((Color.Green * SourceFactor) + (DestColor.Green * DestFactor));
    SourceColor.Blue := trunc((Color.Blue * SourceFactor) + (DestColor.Blue * DestFactor));
    SourceColor.Alpha := trunc((Color.Alpha * SourceFactor) + (DestColor.Alpha * DestFactor));

    // Move the blended color to pixel
    Move(SourceColor, IPtr[0], SizeOf(TPGLColorI));
  end;


procedure TPGLImage.Pixelate(PixelWidth: GLUint = 2);

type UColor = record
  Red,Green,Blue,Alpha: Long;
end;

Var
I,Z,X,Y,R: Long;
CX,CY: Long;
Count: Long;
DrawColor: UColor;
SetColor: TPGLColorI;
SampleColor: Array of TPGLColorI;
  begin

    if PixelWidth < 2 then Exit;

    SetLength(SampleColor, PixelWidth * PixelWidth);

    for I := 0 to trunc(Self.Width / PixelWidth) Do begin
      for Z := 0 to trunc(Self.Height / PixelWidth) Do begin
        CX := I * Integer(PixelWidth);
        CY := Z * Integer(PixelWidth);

        Count := 0;
        for X := 0 to PixelWidth - 1 Do begin
          for Y := 0 to PixelWidth - 1 Do begin
            SampleColor[Count] := Self.Pixel(CX + X, CY + Y);
            Inc(Count);
          end;
        end;

        DrawColor.Red := 0;
        DrawColor.Blue := 0;
        DrawColor.Green := 0;
        DrawColor.Alpha := 0;
        SetColor := pgl_black;

        for R := 0 to High(SampleColor) Do begin
          DrawColor.Red := DrawColor.Red + SampleColor[R].Red;
          DrawColor.Green := DrawColor.Green + SampleColor[R].Green;
          DrawColor.Blue := DrawColor.Blue + SampleColor[R].Blue;
          DrawColor.Alpha := DrawColor.Alpha + SampleColor[R].Alpha;
        end;

        SetColor.Red := trunc(DrawColor.Red / Length(SampleColor));
        SetColor.Green := trunc(DrawColor.Green / Length(SampleColor));
        SetColor.Blue := trunc(DrawColor.Blue / Length(SampleColor));
        SetColor.Alpha := trunc(DrawColor.Alpha / Length(SampleColor));

        for X := 0 to PixelWidth - 1 Do begin
          for Y := 0 to PixelWidth - 1 Do begin
            Self.SetPixel(SetColor, CX + X, CY + Y);
          end;
        end;

      end;
    end;

  end;


///////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// TPGLTexture  ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

constructor TPGLTexture.Create(Width: GLUint = 0; Height: GLUint = 0);
  begin
    Pgl.GenTexture(Self.Handle);
    PGL.BindTexture(0,Self.Handle);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,Width,Height,0,GL_RGBA,GL_UNSIGNED_BYTE,nil);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    PGL.UnBindTexture(Self.Handle);

    Self.Width := Width;
    Self.Height := Height;

    PGL.AddTextureObject(Self);
  end;

constructor TPGLTexture.CreateFromImage(Image: TPGLImage);
  begin

    Self.Width := Image.Width;
    Self.Height := Image.Height;

    Pgl.GenTexture(Self.Handle);
    PGL.BindTexture(0,self.Handle);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,trunc(Image.Width),trunc(Image.Height),0,GL_RGBA,GL_UNSIGNED_BYTE,Image.Handle);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    PGL.UnbindTexture(Self.Handle);

    PGL.AddTextureObject(Self);

    Self.CheckDefaultReplace();

  end;


constructor TPGLTexture.CreateFromFile(FileName: string);
Var
Data: PByte;
IWidth,IHeight,IChannels: GLInt;

  begin

    if FileExists(FileName,true) = False then begin
      FileName := pglEXEPath + 'InvalidImage.png';
    end;

    Data := stbi_load(PAnsiChar(AnsiString(FileName)),IWidth,IHeight,IChannels,4);

    Self.Width := IWidth;
    Self.Height := IHeight;

    Pgl.GenTexture(Self.Handle);
    PGL.BindTexture(0,Self.Handle);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,IWidth,IHeight,0,GL_RGBA,GL_UNSIGNED_BYTE,Data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    PGL.UnbindTexture(Self.Handle);

    stbi_image_free(Data);

    PGL.AddTextureObject(Self);

    Self.CheckDefaultReplace();

  end;


constructor TPGLTexture.CreateFromTexture(Texture: TPGLTexture);

Var
Pixel: Array of TPGLColorI;
  begin

    Self.Width := Texture.Width;
    Self.Height := Texture.Height;

    SetLength(Pixel,Texture.Width * Texture.height);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixel);

    Pgl.GenTexture(Self.Handle);
    PGL.BindTexture(0,Self.Handle);
    glTexImage2D(GL_TEXTURE_2D,0,PGL.TextureFormat,trunc(Texture.Width),trunc(Texture.Height),0,PGL.WindowColorFormat,GL_UNSIGNED_BYTE,Pixel);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    PGL.UnbindTexture(Self.Handle);

    PGL.AddTextureObject(Self);

    Self.CheckDefaultReplace();

  end;


procedure TPGLTexture.Delete();
  begin
    glDeleteTextures(1,@Self.Handle);
    PGL.RemoveTextureObject(Self);
    Self.Free();
  end;


procedure TPGLTexture.CheckDefaultReplace();
Var
I: Long;
Col,NewCol: TPGLColorI;

  begin

    if Length(PGL.DefaultReplace) = 0 then Exit;

    for I := 0 to High(PGL.DefaultReplace) Do begin
      Col := PGL.DefaultReplace[I,0];
      NewCol := PGL.DefaultReplace[I,1];
      Self.ReplaceColors(Col,NewCol,0);
    end;

  end;


procedure TPGLTexture.SaveToFile(FileName: String);

Var
Pixels: Array of TPGLColorI;
FileChar: TPGLCharArray;

  begin

    SetLength(Pixels,Self.Width * SElf.Height);
    PGL.BindTexture(0,Self.Handle);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
    PGL.UnbindTexture(Self.Handle);

    FileChar := PGLStringToChar(FileName);
    stbi_write_bmp(PansiChar(AnsiString(Filename)),Self.Width,SElf.HEight,4,Pixels);

  end;


procedure TPGLTexture.Smooth(Area: TPGLRectF; IgnoreColor: TPGLColorI);
Var
ReturnTexture: GLUInt;
ReturnWidth,ReturnHeight: GLUint;
I,Z,R,T,X,Y,CX,CY: Long;
BlendCount: Long;
Count: Long;
Pixels: Array of TPGLColorI;
OldPixels: Array of Array of TPGLColorI;
NewPixels: Array of Array of TPGLColorI;
NewRed,NewGreen,NewBlue,NewAlpha: Long;
  begin

    // GPU Implimentation

    ReturnTexture := pglTempBuffer.Texture;
    ReturnWidth := pglTempBuffer.Width;
    ReturnHeight := pglTempBuffer.Height;

    pglTempBuffer.SetSize(trunc(Area.Width),trunc(Area.Height));
    pglTempBuffer.Texture := Self.Handle;
    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,pglTempBuffer.Texture,0);
    pglTempBuffer.Smooth(Area,IgnoreColor);
    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,ReturnTexture,0);
    pglTempBuffer.Texture := ReturnTexture;
    pglTempBuffer.SetSize(ReturnWidth,ReturnHeight);

    Exit;

    // CPU Implimentation
    SetLength(NewPixels,(Self.Width), (Self.Height));
    SetLength(OldPIxels,(Self.Width), (Self.Height));

    pglTempbuffer.MakeCurrentTarget();
    PGL.BindTexture(1,Self.Handle);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,OldPIxels);


    for I := 0 to Self.Width - 1 Do begin
      for Z := 0 to Self.Height - 1 Do begin
        NewPixels[i,z] := OldPIxels[i,z];
      end;
    end;


    for I := 0 to trunc(area.Width) - 1 Do begin
      for Z := 0 to trunc(area.Height) - 1 Do begin

        BlendCount := 0;

        X := trunc(Area.Left) + I;
        Y := trunc(Area.Top) + Z;
        NewRed := 0;
        NewBlue := 0;
        NewGreen := 0;
        NewAlpha := 0;

        for R := -1 to 1 Do begin
          for T := -1 to 1 Do begin

            CX := X + R;
            CY := Y + T;

              if CX < 0 then begin
                Continue;
              end;
              if CX >= (Integer(Self.Width) - 1) then begin
                Continue;
              end;
              if CY < 0 then begin
                Continue;
              end;
              if CY >= (Integer(Self.Height) - 1) then begin
                Continue;
              end;
              if OldPixels[CX,CY].IsColor(IgnoreColor) then begin
                Continue;
              end;

            NewRed := NewRed + OldPixels[CX,CY].Red;
            NewGreen := NewGreen + OldPixels[CX,CY].Green;
            NewBlue := NewBlue + OldPixels[CX,CY].Blue;
            NewAlpha := NewAlpha + OldPixels[CX,CY].Alpha;
            Inc(BlendCount);

          end;
        end;


        if BlendCount > 0 then begin
          NewPixels[X,Y].Red := ClampIColor(trunc(NewRed / BlendCount));
          NewPixels[X,Y].Green := ClampIColor(trunc(NewGreen / BlendCount));
          NewPixels[X,Y].Blue := ClampIColor(trunc(NewBlue / BlendCount));
          NewPixels[X,Y].Alpha := ClampIColor(trunc(NewAlpha / BlendCount));
        end;


      end;
    end;

    Count := 0;

    SetLength(Pixels,Self.Width * self.Height);

    for I := 0 to Self.Width - 1 Do begin
      for Z := 0 to Self.Height - 1 Do begin

        Pixels[Count] := NewPixels[I,Z];
        Inc(Count);
      end;
    end;

    glTexImage2D(GL_TEXTURE_2D,0,PGL.TextureFormat,Self.Width+1,Self.Height+1,0,PGL.WindowColorFormat,GL_UNSIGNED_BYTE,@Pixels[0]);
    PGL.BindTexture(1,0);




  end;


procedure TPGLTexture.ReplaceColors(TargetColors: Array of TPGLColorI; NewColor: TPGLColorI; Tolerance: Double = 0);

Var
Pixels: Array of TPGLColorI;
I,Z: Long;

  begin

    // Get pixels from texture
    SetLength(Pixels,(Self.Width * Self.Height));
    PGL.BindTexture(0,Self.Handle);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);

    // scan and replace
    for I := 0 to (Self.Width * Self.Height) - 1 Do begin

      for Z := 0 to High(TargetColors) Do begin
        if Pixels[i].IsColor(TargetColors[z], Tolerance) then begin
          Pixels[i] := NewColor;
        end;
      end;
    end;

    // reinsert colors to texture
    glTexSubImage2D(GL_Texture_2D,0,0,0,Self.Width,Self.Height,GL_RGBA,GL_UNSIGNED_BYTE,@Pixels[0]);

    PGL.BindTexture(0,0);

  end;


procedure TPGLTexture.CopyFromData(Data: Pointer; Width,Height: GLInt);
  begin
    Self.Width := Cardinal(Width);
    Self.Height := Cardinal(Height);
    PGL.BindTexture(0,Self.Handle);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,Width,Height,0,GL_RGBA,GL_UNSIGNED_BYTE,Data);
    PGL.UnbindTexture(Self.Handle);
  end;

procedure TPGLTexture.CopyFromTexture(Source: TPGLTexture; X,Y,Width,Height: GLUInt);

Var
Pixels: Array of Byte;
  begin

    if X > Source.Width then Exit;
    if Y > Source.Height then Exit;

    if X + Width > Source.Width then begin
      Width := Source.Width - X;
    end;

    if Y + Height > Source.Height then begin
      Height := Source.Height - Y;
    end;


    Self.Width := Width;
    Self.Height := Height;

    SetLength(Pixels,(Width * Height) * 4);

    glTexSubImage2D(GL_TEXTURE_2D,0,X,Y,Width,Height,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
    self.CopyFromData(Pixels,Width,Height);

  end;


procedure TPGLTexture.SetSize(Width,Height: GLUint; KeepImage: Boolean = False);

Var
Pixels: Array of Byte;
KeepWidth,KeepHeight: GLUint;

  begin

    // Cache pixels if keep image
    if KeepImage = True then begin
      SetLength(Pixels, (Self.Width * Self.Height) * 4);
      PGL.BindTexture(0,Self.Handle);
      glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
    end;

    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,Width,Height,0,GL_RGBA,GL_UNSIGNED_BYTE,nil);

    // Return image if keep image
    if KeepImage = True then begin
      glTexSubImage2D(GL_TEXTURE_2D,0,0,0,Width,Height,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
    end;

    PGL.UnbindTexture(Self.Handle);

  end;


function TPGLTexture.Pixel(X: Integer; Y: Integer): TPGLColorI;

Var
IPtr: PByte;

  begin
    // TO-DO: Finish
    Result := pgl_empty;


  end;


function TPGLTexture.SetPixel(Color: TPGLColorI; X,Y: Integer): TPGLColorI;
  begin
    //TO-DO: Finish
    PGL.BindTexture(0,Self.Handle);
    glTexSubImage2D(GL_TEXTURE_2D, 0,X,Y,1,1,GL_RGBA,GL_UNSIGNED_BYTE,@Color);
  end;

procedure TPGLTexture.Pixelate(PixelWidth: GLUint = 2);
Var
TempImage: TPGLImage;
  begin
    TempImage := TPGLImage.CreateFromTexture(Self);
    TempImage.Pixelate(PixelWidth);
    Self.CopyFromData(TempImage.Handle,Self.Width,Self.Height);
    TempImage.Destroy();
  end;


procedure TPGLTexture.CopyToImage(Dest: TPGLImage; SourceRect, DestRect: TPGLRectI);
Var
I,Z: GLInt;
OrgPixels: Array of TPGLColorI;
NewPixels: Array of TPGLColorI;
OrgPixelCount: GLInt;
PixelCount: GLInt;
ImgPtr: PByte;
ImgLoc: GLInt;

  begin
    // Get All Pixels from texture
    PGL.BindTexture(1,Self.Handle);
    SetLength(OrgPixels, Self.Width * Self.Height);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, OrgPixels);

    // Copy OrgPixels into NewPixels
    SetLength(NewPixels, DestRect.Width * DestRect.Height);
    OrgPixelCount := 0;
    PixelCount := 0;
    for Z := 0 to Self.Height - 1 Do begin
      for I := 0 to Self.Width - 1 Do begin

        // if I and Z fall with bounds of the SourceRect, copy it over, keep count of pixels in arrays
        if (I >= SourceRect.Left) and (I <= SourceRect.Right) and (Z >= SourceRect.Top) and (Z <= SourceRect.Bottom) then begin
          if PixelCount < Length(NewPixels) then begin
            NewPixels[PixelCount] := OrgPixels[OrgPixelCount];
            Inc(PixelCount);
          end;
        end;

        Inc(OrgPixelCount);

      end;
    end;

    // Transfer to Image
    PixelCount := 0;
    ImgPtr := Dest.Handle;
    ImgLoc := 0;

    for Z := 0 to DestRect.Height - 1 Do begin
      for I := 0 to DestRect.Width - 1 Do begin
        ImgLoc := ((((DestRect.Top + Z) * Self.Width) + (DestRect.Left + I)) * 4);
        Move(NewPixels[PixelCount], ImgPtr[ImgLoc], 4);
        Inc(PixelCount);
      end;
    end;

  end;


procedure TPGLTexture.CopyToAddress(Dest: Pointer);
  begin
    PGL.BindTexture(0,Self.Handle);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, Dest);
  end;


procedure TPGLTexture.SetNearestFilter;
Var
ReturnTexture: GLInt;
  begin
    ReturnTexture := PGL.TexUnit[0];
    PGL.BindTexture(0,Self.Handle);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    PGL.BindTexture(0,ReturnTexture);
  end;


procedure TPGLTexture.SetLinearFilter;
Var
ReturnTexture: GLInt;
  begin
    ReturnTexture := PGL.TexUnit[0];
    PGL.BindTexture(0,Self.Handle);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    PGL.BindTexture(0,ReturnTexture);
  end;


procedure TPGLTextureHelper.CopyFrom(Image: TPGLImage; X,Y,Width,Height: GLInt);
Var
Pixels: Array of TPGLColorI;
PixelPos: Long;
IPtr: PByte;
I,Z: Long;

  begin

    SetLength(Pixels,(Width * HEight));
    PixelPos := 0;

    for I := Y to Height - 1 Do begin

      IPtr := Image.RowPtr[I];
      IPtr := IPtr + (X * 4);
      Move(Iptr[0],Pixels[PixelPos],Width * 4);

      PixelPos := PixelPos + (Width);


    end;


    PGL.BindTexture(0,Self.Handle);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,Width,Height,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
    PGL.UnBindTexture(Self.Handle);
  end;


procedure TPGLTextureHelper.CopyFrom(Texture: TPGLTexture; X,Y,Width,Height: GLInt);
  begin
    PGL.BindTexture(0,Self.Handle);
    glTexImage2D(GL_TEXTURE_2D,0,PGL.TextureFormat,Width,Height,0,PGL.WindowColorFormat,GL_UNSIGNED_BYTE,nil);

    glCopyImageSubData(Texture.Handle,GL_TEXTURE_2D,0,X,Y,0,
                       Self.Handle,GL_TEXTURE_2D,0,0,0,0,Width,Height,0);

    pGL.UnbindTexture(Self.Handle);
  end;

procedure TPGLTextureHelper.CopyFrom(Sprite: TPGLSprite; X,Y,Width,Height: GLInt);
Var
CheckVar: GLInt;
  begin


    PGL.BindTexture(0,self.Handle);
    glTexImage2D(GL_TEXTURE_2D,0,PGL.TextureFormat,Width,Height,0,PGL.WindowColorFormat,GL_UNSIGNED_BYTE,nil);
    PGL.UnbindTexture(self.Handle);

    glCopyImageSubData(Sprite.pTexture.Handle,GL_TEXTURE_2D,0,X,Y,0,
                       Self.Handle,GL_TEXTURE_2D,0,0,0,0,Width,Height,1);

  end;


///////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// TPGLSprite  /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

procedure TPGLSprite.Initialize();
  begin
    Self.pColorValues :=  Color4f(1,1,1,1);
    Self.pColorOverlay := Color4f(0,0,0,0);
    Self.pMaskColor := PGL.DefaultMaskColor;
    Self.pOpacity := 1;
    PGLMatrixRotation(Self.Rotation,0,0,0);
    PGLMatrixTranslation(Self.Translation,0,0);
    PGLMatrixScale(Self.Scale,1,1);
    Self.Cor[0] := Vec2(0,1);
    Self.Cor[1] := Vec2(1,1);
    Self.Cor[2] := Vec2(1,0);
    Self.Cor[3] := Vec2(0,0);
    Self.pBounds := gldrawMain.RectF(0,0,0,0);
    Self.pTextureSize := Vec2(0,0);
    Self.pTextureRect := gldrawMain.RectI(0,0,0,0);

    SetLength(PGL.Sprites,Length(PGL.Sprites) + 1);
    PGL.Sprites[High(PGL.Sprites)] := Self;
  end;

constructor TPGLSprite.Create();
  begin
    Self.Initialize();
  end;

constructor TPGLSprite.CreateFromTexture(Var Texture: TPGLTexture);
  begin
    Self.Initialize();
    Self.SetTexture(Texture);
  end;

procedure TPGLSprite.Delete();
  begin
    glDeleteTextures(1,@Self.ptexture);
    Self.Free();
  end;

procedure TPGLSprite.SetDefaults();
  begin
    Self.pTexture := nil;
    Self.pMirrored := False;
    Self.pFlipped := False;
    Self.SetTextureRect(RectI(0,0,0,0));
    Self.SetSize(0,0);
    Self.SetOpacity(1);
    Self.SetAngle(0);
    Self.SetOrigin(Vec2(0,0));
    Self.ResetSkew();
    Self.ResetStretch();
    Self.ResetScale();
    Self.ResetColorState();
  end;


procedure TPGLSprite.SetTexture(Var Texture: TPGLTexture); register;
  begin
    Self.pTextureSize := Vec2(Texture.Width, Texture.Height);
    Self.SetTextureRect(RectIWH(0,0,Self.TextureSize.X,Self.TextureSize.Y));

    Self.pTextureSize.X := Texture.Width;
    Self.pTextureSize.Y := Texture.Height;
    Self.pBounds.Width := Texture.Width;
    Self.pBounds.Height := Texture.Height;
    Self.Bounds.Update(FROMCENTER);
    UpdateVertices();

    Self.pTexture := Texture;
  end;


procedure TPGLSprite.SetTexture(Sprite: TPGLSprite);
  begin
    Self.pTexture := Sprite.pTexture;
    Self.pTextureSize.X := Sprite.TextureSize.X;
    Self.pTextureSize.Y := Sprite.TextureSize.Y;
    Self.pBounds.Width := Sprite.Width;
    Self.PBounds.Height := Sprite.Height;
    Self.Bounds.Update(FROMCENTER);
    Self.UpdateVertices();
    Self.SetTextureRect(RectIWH(0,0,Self.TextureSize.X,Self.TextureSize.Y));
  end;

procedure TPGLSprite.SetCenter(Center: TPGLVector2); register;
  begin
    Self.pBounds.X := Center.X;
    Self.pBounds.Y := Center.Y;
    Self.pBounds.Update(FROMCENTER);
    UpdateVertices();
  end;


procedure TPGLSprite.SetTopLeft(TopLeft: TPGLVector2); register;
  begin
    Self.pBounds.SetLeft(TopLeft.X);
    Self.pBounds.SetTop(TopLeft.Y);
    UpdateVertices();
  end;

procedure TPGLSprite.Move(X,Y: Single); register;
  begin
    Self.pBounds.X := Self.Bounds.X + X;
    Self.pBounds.Y := Self.Bounds.Y + Y;
    Self.pBounds.Update(FROMCENTER);
    UpdateVertices();
  end;


procedure TPGLSprite.UpdateVertices(); register;
  begin
    // Update Screen Space Vertices
    Self.Ver[0] := Vec2(-Self.Bounds.Width / 2, -Self.Bounds.Height / 2);
    Self.Ver[1] := Vec2(Self.Bounds.Width / 2, -Self.Bounds.Height / 2);
    Self.Ver[2] := Vec2(Self.Bounds.Width / 2, Self.Bounds.Height / 2);
    Self.Ver[3] := Vec2(-Self.Bounds.Width / 2, Self.Bounds.Height / 2);
  end;


procedure TPGLSprite.Rotate(Val: Single);
  begin
    Self.pAngle := Self.pAngle + Val;
    PGLMatrixRotation(Self.Rotation,Self.Angle,Self.Bounds.X,Self.BOunds.Y);
  end;


procedure TPGLSprite.SetAngle(Val: Single);
  begin
    Self.pAngle := Val;
    PGLMatrixRotation(Self.Rotation,Self.Angle,Self.Bounds.X,Self.Bounds.Y);
  end;


procedure TPGLSprite.SetOrigin(Center: TPGLVector2);
  begin
    Self.pOrigin.X := -(Self.Bounds.X - Center.X);
    Self.pOrigin.Y := -(Self.Bounds.Y - Center.Y);
  end;

procedure TPGLSprite.SetFlipped(isFlipped: Boolean);
  begin
    Self.pFlipped := isFlipped;
  end;

procedure TPGLSprite.SetMirrored(isMirrored: Boolean);
  begin
    Self.pMirrored := isMirrored;
  end;

procedure TPGLSprite.SetSkew(Dimension: Integer; Amount: Single);
  begin

    Case Dimension of

      0:
        begin
          Self.pLeftSkew := Amount;
        end;

      1:
        begin
          Self.pTopSkew := Amount;
        end;

      2:
        begin
          Self.pRightSkew := Amount;
        end;

      3:
        begin
          Self.pBottomSkew := Amount;
        end;

    end;

  end;

procedure TPGLSprite.ResetSkew();
  begin
    Self.pTopSkew := 0;
    Self.pBottomSkew := 0;
    Self.pLeftSkew := 0;
    Self.pRightSkew := 0;
  end;


procedure TPGLSprite.SetStretch(Dimension: Integer; Amount: Single);
  begin

    Case Dimension of

      0:
        begin
          Self.pLeftStretch := Amount;
        end;

      1:
        begin
          Self.pTopStretch := Amount;
        end;

      2:
        begin
          Self.pRightStretch := Amount;
        end;

      3:
        begin
          Self.pBottomStretch := Amount;
        end;

    end;

  end;

procedure TPGLSprite.ResetStretch();
  begin
    Self.pTopStretch := 0;
    Self.pLeftStretch := 0;
    Self.pRightStretch := 0;
    Self.pBottomStretch := 0;
  end;


procedure TPGLSprite.SetMaskColor(Color: TPGLColorF);
  begin
    Self.pMaskColor := Color;
  end;

procedure TPGLSprite.SetMaskColor(Color: TPGLColorI);
  begin
    Self.pMaskColor := ColorItoF(Color);
  end;

procedure TPGLSprite.SetOpacity(val: GLFloat);
  begin
    Self.pOpacity := ClampFColor(Val);
  end;

procedure TPGLSprite.SetColors(Colors: TPGLColorI);
  begin
    Self.ColorsArePointer := False;
    Self.pColorValues := cc(Colors);
  end;

procedure TPGLSprite.SetColors(Colors: Pointer);
  begin
    Self.ColorsArePointer := true;
    Self.pColorValuesPointer := Colors;
  end;


function TPGLSprite.GetColorValues: TPGLColorF;
  begin
    if Self.ColorsArePointer = False then begin
      Result := Self.pColorValues;
    End Else begin
      Result := Self.pColorValuesPointer^;
    end;
  end;

function TPGLSprite.GetRectSet(S: Integer): TPGLRectI;
  begin
    Result := Self.pRectSet[S];
  end;

function TPGLSprite.GetCenter(): TPGLVector2;
  begin
    Result := Vec2(Self.Bounds.X,Self.Bounds.Y);
  end;

function TPGLSprite.GetTopLeft(): TPGLVector2;
  begin
    Result := Vec2(Self.Bounds.X - (Self.Bounds.Width / 2), Self.Bounds.Y - (Self.Bounds.Height / 2));
  end;

procedure TPGLSprite.SetOverlay(Colors: TPGLColorI);
  begin
    Self.pColorOverlay := cc(Colors);
  end;

procedure TPGLSprite.SetGreyScale(Val: Boolean = True);
  begin
    Self.pGreyScale := Val;
  end;

procedure TPGLSprite.ResetColorState();
  begin
    Self.SetColors(cc(Color4f(1,1,1,1)));
    Self.SetOverlay(CC(Color4f(0,0,0,0)));
    Self.pMaskColor := Color4f(0,0,0,0);
    Self.SetGreyScale(False);
  end;

procedure TPGLSprite.SetSize(Width: Single; Height: Single);
  begin
    Self.pBounds.Width := trunc(Width);
    Self.pBounds.Height := trunc(Height);
    Self.SetCenter(Vec2(Self.Bounds.X,Self.Bounds.Y));
  end;

procedure TPGLSprite.ResetScale;
  begin
    Self.SetSize(Self.TextureRect.Width,Self.TextureRect.Height);
  end;


procedure TPGLSprite.SetTextureRect(TexRect: TPGLRectI);

  begin

    // Update internal texture use rect

    if TexRect.Right > Self.TextureSize.X then begin
      TexRect.Right := trunc(Self.TextureSize.X);
    end;

    if TexRect.Left < 0 then begin
      TexRect.Left := 0;
    end;

    if TexRect.Top < 0 then begin
      TexRect.Top := 0;
    end;

    if TexRect.Bottom > Self.TextureSize.Y then begin
      TexRect.Bottom := trunc(Self.TextureSize.Y);
    end;

    Self.pTextureRect := TexRect;
    Self.SetSize(TexRect.Width,TexRect.Height);

    Self.Cor[0] := Vec2(TexRect.Left / Self.TextureSize.X, TexRect.Top / Self.TextureSize.Y);
    Self.Cor[1] := Vec2(TexRect.Right / Self.TextureSize.X, TexRect.Top / Self.TextureSize.Y);
    Self.Cor[2] := Vec2(TexRect.Right / Self.TextureSize.X, TexRect.Bottom / Self.TextureSize.Y);
    Self.Cor[3] := Vec2(TexRect.Left / Self.TextureSize.X, TexRect.Bottom / Self.TextureSize.Y);

  end;


procedure TPGLSprite.SetRectSlot(Slot: GLInt; Rect: TPGLRectI);
  begin
    Self.pRectSet[Slot] := Rect;
  end;

procedure TPGLSprite.UseRectSlot(Slot: GLInt);
  begin
    Self.SetTextureRect(Self.RectSet[Slot]);
  end;


procedure TPGLSprite.SaveToFile(FileName: string);
Var
Succeed: LongBool;
Pixels: Array of TPGLColorI;
FileChar: TPGLCharArray;
  begin
    SetLength(Pixels, trunc(Self.TextureSize.X) * trunc(Self.TextureSize.Y));
    PGL.BindTexture(0,Self.Texture.Handle);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
    PGL.UnbindTexture(Self.Texture.Handle);
    FileChar := PGLStringToChar(FileName);
    Succeed := stbi_write_bmp(LPCSTR(FileChar),trunc(Self.TextureSize.X),trunc(Self.TextureSize.Y),4,Pixels);
  end;

function TPGLSprite.Pixel(X: Integer; Y: Integer): TPGLColorI;
Var
IPtr: PByte;
  begin
    // Finish Later
    Result := pgl_empty
  end;


///////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// TPGLProgram /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

procedure TPGLPointCollection.BuildFrom(Texture: TPGLTexture; X: Cardinal = 0; Y: Cardinal = 0; Width: Cardinal = 0; Height: Cardinal = 0);

Var
Pixels: Array of TPGLColorI;
I,Z,Count: Long;
ReturnTexture: GLUInt;
ReturnBuffeR: GLUInt;
DestVer: TPGLVectorQuad;
SourceCor: TPGLVectorQuad;
SourceRect: TPGLRectF;

  begin

    if X > Texture.Width then X := Texture.Width;
    if Y > Texture.Height then Y := Texture.Height;

    if (Width = 0) then begin
      Width := Texture.Width;
    end;

    if X + Width > Texture.Width then begin
      Width := Texture.Width - X;
    end;

    if (Height = 0) then begin
      Height := Texture.Height;
    end;

    if Y + Height > Texture.Height then begin
      Height := Texture.Height - Y;
    end;

    Self.pWidth := Width;
    Self.pHeight := Height;
    Self.pcount := Width * Height;
    SetLength(Self.Data,Self.Width * self.Height);

    DestVer[0] := Vec2(-1,1);
    DestVer[1] := Vec2(1,1);
    DestVer[2] := Vec2(1,-1);
    DestVer[3] := Vec2(-1,-1);

    SourceRect := RectFWH(X,Y,Width,Height);

    SourceCor[0] := Vec2(SourceRect.Left / Texture.Width, SourceRect.Bottom / Texture.Height);
    SourceCor[1] := Vec2(SourceRect.Right / Texture.Width, SourceRect.Bottom / Texture.Height);
    SourceCor[2] := Vec2(SourceRect.Right / Texture.Width, SourceRect.Top / Texture.Height);
    SourceCor[3] := Vec2(SourceRect.Left / Texture.Width, SourceRect.Top / Texture.Height);


    glGetIntegerV(GL_TEXTURE0,@ReturnTexture);
    ReturnBuffer := PGL.CurrentRenderTarget;

    pglTempBuffer.SetSize(Width,Height);
    pglTempBuffer.MakeCurrentTarget();
    pglTempBuffer.Buffers.Bind();

    PGL.BindTexture(0,Texture.Handle);

    pglTempBuffer.Buffers.BindVBO(0);
    pglTempBuffer.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(TPGLVectorQuad),@DestVer);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    pglTempBuffer.Buffers.BindVBO(1);
    pglTempBuffer.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(TPGLVectorQuad),@SourceCor);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    PixelTransferProgram.Use();

    glUniform1i(PGLGetUniform('tex'),0);

    glDrawArrays(GL_QUADS,0,4);

    PGL.BindTexture(0,pglTempBuffer.Texture);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Self.Data);
    PGL.BindTexture(0,ReturnTexture);

  end;


procedure TPGLPointCollection.BuildFrom(Image: TPGLImage; X: Cardinal = 0; Y: Cardinal = 0;  Width: Cardinal = 0; Height: Cardinal = 0);
  begin

  end;


procedure TPGLPointCollection.BuildFrom(Sprite: TPGLSprite; X: Cardinal = 0; Y: Cardinal = 0;  Width: Cardinal = 0; Height: Cardinal = 0);

Var
Pixels: Array of TPGLColorI;
I,Z,Count: Long;
ReturnTexture: GLUInt;
ReturnBuffeR: GLUInt;
DestVer: TPGLVectorQuad;
SourceCor: TPGLVectorQuad;
SourceRect: TPGLRectF;

  begin

    if X > Sprite.Width then X := trunc(Sprite.Width);
    if Y > Sprite.Height then Y := trunc(sprite.Height);

    if (Width = 0) then begin
      Width := trunc(Sprite.Width);
    end;

    if X + Width > sprite.Width then begin
      Width := trunc(sprite.Width) - X;
    end;

    if (Height = 0) then begin
      Height := trunc(sprite.Height);
    end;

    if Y + Height > sprite.Height then begin
      Height := trunc(sprite.Height - Y);
    end;

    Self.pWidth := Width;
    Self.pHeight := Height;
    Self.pcount := Width * Height;
    SetLength(Self.Data,Self.Width * self.Height);

    ReturnTexture := PGL.TexUnit[0];

    pglTempBuffer.SetSize(Width,Height);
    pglTempBuffer.DrawSprite(Sprite);

    PGL.BindTexture(0,pglTempBuffer.Texture);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Self.Data);
    PGL.BindTexture(0,ReturnTexture);

    Count := 0;

    for I := 0 to Width - 1 Do begin
      for Z := 0 to Height - 1 Do begin

        if Self.Point(I,Z).IsColor(Sprite.MaskColor) then begin
          Self.Data[(Y * Self.Width) + X] := pgl_Empty;
        end;

      end;
    end;

  end;


procedure TPGLPointCollection.BuildFrom(Data: Pointer; Width: Cardinal; Height: Cardinal);

Var
Pixels: Array of TPGLColorI;
I,Z,Count: Long;
ReturnTexture: GLUInt;
ReturnBuffeR: GLUInt;
DestVer: TPGLVectorQuad;
SourceCor: TPGLVectorQuad;
SourceRect: TPGLRectF;

  begin



    Self.pWidth := Width;
    Self.pHeight := Height;
    Self.pcount := Width * Height;
    SetLength(Self.Data,Self.Width * self.Height);
    Move(Data,Self.Data,(Width * Height) * 4);
  end;


procedure TPGLPointCollection.ReplaceColor(OldColor: TPGLColorI; NewColor: TPGLColorI);

Var
I,Z,Count: Long;

  begin

    for I := 0 to Self.Count - 1 Do begin
      if Self.Data[I].IsColor(OldColor) then begin
        Self.Data[i] := NewColor;
      end;
    end;

  end;


function TPGLPointCollection.Point(X: Cardinal; Y: Cardinal): TPGLColorI;
  begin
    Result := Self.Data[(Y * Self.Width) + X];
  end;


function TPGLPointCollection.Point(N: Cardinal): TPGLColorI;
  begin
    Result := Self.Data[N];
  end;


///////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// TPGLProgram /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

constructor TPGLProgram.Create(Name: String; VertexShaderPath: String; FragmentShaderPath: String; GeometryShaderPath: String = '');

Var
VerPass: Boolean;
FragPass: Boolean;
GeoPass: Boolean;
ExitMesssage: String;
Err: GLInt;
FileName: String;

  begin

    Self.ProgramName := Name;

    Self.VertexShader := glCreateShader(GL_VERTEX_SHADER);
    Self.FragmentShader := glCreateShader(GL_FRAGMENT_SHADER);

    if GeometryShaderPath <> '' then begin
      Self.GeometryShader := glCreateShader(GL_GEOMETRY_SHADER);
      GeoPass := PGLLoadShader(Self.GeometryShader,String(GeometryShaderPath));
    end;

    VerPass := PGLLoadShader(Self.VertexShader,String(VertexShaderPath));
    FragPass := PGLLoadShader(Self.FragmentShader,String(FragmentShaderPath));

    if (VerPass = False) or (FragPass = False) or ((GeoPass = False) and (GeometryShaderPath <> '')) then begin
      PGLAddError('Shader Program ' + string(Name) + ' Creation Failed');
    end;

    Self.ShaderProgram := glCreateProgram();
    glAttachShader(Self.ShaderProgram,Self.VertexShader);
    glAttachShader(Self.ShaderProgram,Self.FragmentShader);

    if GeometryShaderPath <> '' then begin
      glAttachShader(Self.ShaderProgram,Self.GeometryShader);
    end;

    glLinkProgram(Self.ShaderProgram);

    Self.Valid := True;

  end;


procedure TPGLProgram.Use();

  begin

    if CurrentProgram = Self then Exit;

    if Self.Valid = True then begin
      glUseProgram(Self.ShaderProgram);
      CurrentProgram := Self;
    End Else begin
      glUseProgram(0);
      CurrentProgram := nil;
      pglAddError(string('Could not use Shader Program ' + Self.ProgramName + '. Invalid Program'));
    end;
  end;


function TPGLProgram.SearchUniform(uName: String): GLInt;
Var
I: GLInt;

  begin

    Result := -1;

    if Self.UniformCount = 0 then begin
      Result := -1; // return not found if no uniforms cached
    End Else begin

      for I := 0 to Self.UniformCount - 1 Do begin

        if Self.Uniform[i].Name = uName then begin
          Result := Self.Uniform[i].Location; // search for uniform by name if uniforms are cached
          Exit;
        end;

        Result := -1; // if not found return not found
      end;

    end;

  end;


procedure TPGLProgram.AddUniform(uName: string; Location: GLInt);
Var
I: GLInt;

  begin
    inc(Self.UniformCount);
    I := Self.UniformCount;
    SetLength(Self.Uniform,I);
    Self.Uniform[i-1].Name := uName;
    Self.Uniform[i-1].Location := Location;

  end;


///////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// TPGLLightSource /////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

constructor TPGLLightSource.Create();
  begin
    Self.SetActive(False);
    Self.Place(Vec2(0,0),100);
    SElf.SetColor(Color3i(255,255,255));
    Self.SetRadiance(1);

    SetLength(PGL.Lights,Length(PGL.Lights) + 1);
    Pgl.Lights[High(Pgl.Lights)] := Self;
  end;

procedure TPGLLightSource.SetActive(isActive: Boolean = True);
  begin
    Self.Active := isActive;
  end;

procedure TPGLLightSource.SetPosition(Pos: TPGLVector2);
  begin
    Self.Position := Pos;

    Self.Bounds.X := Pos.X;
    Self.Bounds.Y := Pos.Y;
    Self.Bounds.Left := Pos.X - (Self.Width / 2);
    Self.Bounds.Right := Self.Bounds.Left + Self.Width;
    Self.Bounds.Top := Pos.Y - (Self.Width / 2);
    Self.Bounds.Bottom := Self.Bounds.Top + Self.Width;

    Self.Ver[0] := Vec2((Bounds.Left), (Bounds.Top));
    Self.Ver[1] := Vec2((Bounds.Right),(Bounds.Top));
    Self.Ver[2] := Vec2((Bounds.Right),(Bounds.Bottom));
    Self.Ver[3] := Vec2((Bounds.Left), (Bounds.Bottom));
  end;

procedure TPGLLightSource.SetColor(Color: TPGLColorF);
  begin
    Self.Color := Color;
  end;

procedure TPGLLightSource.SetColor(Color: TPGLColorI);
  begin
    Self.Color := ColorItoF(Color);
  end;

procedure TPGLLightSource.SetRadiance(RadianceVal: GLFloat);
  begin
    Self.Radiance := RadianceVal;
  end;

procedure TPGLLightSource.SetWidth(Val: GLFloat);
  begin
    Self.Width := val;
  end;

procedure TPGLLightSource.Place(Pos: TPGLVector2; WidthVal: GLFloat);
  begin
    Self.SetWidth(WidthVal);
    Self.SetPosition(Pos);
  end;


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////Colors /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
function TPGLColorI.Value: Double;
Var
Val: GLInt;
  begin
    Result := (( Self.Alpha / 0.75) + (Self.Green / 0.50) + (Self.Green / 0.25) + (Self.Red / 0.1) ) * 255;
  end;

function TPGLColorI.ToMultiply(Ratio: Single): TPGLColorI;
  begin
    Result.Red := ClampIColor(trunc(Self.Red * Ratio));
    Result.Green := ClampIColor(trunc(Self.Green * Ratio));
    Result.Blue := ClampIColor(trunc(Self.Blue * Ratio));
    Result.Alpha := Self.Alpha;
  end;

procedure TPGLColorI.Adjust(Percent: Integer; AdjustAlpha: Boolean = False);
  begin
    Self.Red := ClampIColor(trunc(Self.Red * (Percent / 100)));
    Self.Green := ClampIColor(trunc(Self.Green * (Percent / 100)));
    Self.Blue := ClampIColor(trunc(Self.Blue * (Percent / 100)));

    if AdjustAlpha = True then begin
      Self.Alpha := ClampIColor(trunc(Self.Alpha * (Percent / 100)));
    end;
  end;

function TPGLColorIHelper.IsColor(CompareColor: TPGLColorF; Tolerance: Double = 0): Boolean;
Var
RedDiff,GreenDiff,BlueDiff,AlphaDiff: Double;

  begin

    Result := False;

    RedDiff := abs((Self.Red / 255) - (CompareColor.Red));
    GreenDiff := abs((Self.Green / 255) - CompareColor.Green);
    BlueDiff := abs((Self.Blue / 255) - CompareColor.Blue);
    AlphaDiff := abs((Self.Alpha / 255) - CompareColor.Alpha);


    if (RedDiff) <= Tolerance then begin
      if (GreenDiff) <= Tolerance then begin
        if (BlueDiff) <= Tolerance then begin
          if (AlphaDiff) <= Tolerance then begin
            Result := true;
          end;
        end;
      end;
    end;

  end;

function TPGLColorIHelper.IsColor(CompareColor: TPGLColorI; Tolerance: Double = 0): Boolean;
Var
RedDiff,GreenDiff,BlueDiff,AlphaDiff: Double;

  begin

    Result := False;

    RedDiff := abs((Self.Red / 255) - (CompareColor.Red / 255));
    GreenDiff := abs((Self.Green / 255) - CompareColor.Green / 255);
    BlueDiff := abs((Self.Blue / 255) - CompareColor.Blue / 255);
    AlphaDiff := abs((Self.Alpha / 255) - CompareColor.Alpha / 255);


    if (RedDiff) <= Tolerance then begin
      if (GreenDiff) <= Tolerance then begin
        if (BlueDiff) <= Tolerance then begin
          if (AlphaDiff) <= Tolerance then begin
            Result := true;
          end;
        end;
      end;
    end;

  end;

function TPGLColorF.Value: Double;
Var
Val: GLInt;
  begin
    Result := (((Self.Alpha * 255) / 0.75) + ((Self.Green * 255) / 0.5) + ((Self.Green * 255) / 0.25) + ((Self.Red * 255) / 0.1) ) * 255;
  end;

function TPGLColorF.ToMultiply(Ratio: Single): TPGLColorF;
  begin
    Result.Red := Self.Red * Ratio;
    Result.Green := Self.Green * Ratio;
    Result.Blue := Self.Blue * Ratio;
    Result.Alpha := Self.Alpha;
  end;

function TPGLColorFHelper.IsColor(CompareColor: TPGLColorI; Tolerance: Double = 0): Boolean;

Var
RedDiff,GreenDiff,BlueDiff,AlphaDiff: Double;

  begin

    Result := False;

    RedDiff := abs(Self.Red - (CompareColor.Red / 255));
    GreenDiff := abs(Self.Green - CompareColor.Green / 255);
    BlueDiff := abs(Self.Blue - CompareColor.Blue / 255);
    AlphaDiff := abs(Self.Alpha - CompareColor.Alpha / 255);


    if (RedDiff) <= Tolerance then begin
      if (GreenDiff) <= Tolerance then begin
        if (BlueDiff) <= Tolerance then begin
          if (AlphaDiff) <= Tolerance then begin
            Result := true;
          end;
        end;
      end;
    end;

  end;

function TPGLColorFHelper.IsColor(CompareColor: TPGLColorF; Tolerance: Double = 0): Boolean;

Var
RedDiff,GreenDiff,BlueDiff,AlphaDiff: Double;

  begin

    Result := False;

    RedDiff := abs(Self.Red - CompareColor.Red);
    GreenDiff := abs(Self.Green - CompareColor.Green);
    BlueDiff := abs(Self.Blue - CompareColor.Blue);
    AlphaDiff := abs(Self.Alpha - CompareColor.Alpha);


    if (RedDiff) <= Tolerance then begin
      if (GreenDiff) <= Tolerance then begin
        if (BlueDiff) <= Tolerance then begin
          if (AlphaDiff) <= Tolerance then begin
            Result := true;
          end;
        end;
      end;
    end;

  end;


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////Rects  /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

procedure TPGLRectI.SetLeft(Value: GLInt);
  begin
    Self.Left := Value;
    Self.Update(FROMLEFT);
  end;

procedure TPGLRectI.SetTop(Value: GLInt);
  begin
    Self.Top := Value;
    Self.Update(FROMTOP);
  end;

procedure TPGLRectI.SetRight(Value: GLInt);
  begin
    Self.Right := Value;
    Self.Update(FROMRIGHT);
  end;

procedure TPGLRectI.SetBottom(Value: GLInt);
  begin
    Self.Bottom := Value;
    Self.Update(FROMBOTTOM);
  end;

procedure TPGLRectI.SetTopLeft(L: GLInt; T: GLInt);
  begin
    Self.X := L + trunc(Self.Width / 2);
    Self.Y := T + trunc(Self.Height / 2);
    Self.Update(FROMCENTER);
  end;

procedure TPGLRectI.SetCenter(X: GLInt; Y: GLInt);
  begin
    Self.X := X;
    Self.Y := Y;
    Self.Update(FROMCENTER);
  end;


procedure TPGLRectI.Update(From: Integer);
  begin

    Case From of

      0: // From Center
        begin
          Self.Left := Self.X - RoundInt(Self.Width / 2);
          Self.Right := Self.Left + (Self.Width - 1);
          Self.Top := Self.Y - RoundInt(Self.Height / 2);
          Self.Bottom := Self.Top + (Self.Height - 1);

        end;

      1: // From LEft
        begin
          Self.X := Self.Left + RoundInt(Self.Width / 2);
          Self.Right := Self.Left + (Self.Width - 1);
          Self.Top := Self.y - RoundInt(Self.Height / 2);
          Self.Bottom := Self.Top + (Self.Height - 1);
        end;

      2: // From Top
        begin
          Self.Y := Self.Top + RoundInt(Self.Height / 2);
          Self.Bottom := Self.Top + (Self.Height - 1);
          Self.Left := Self.X - RoundInt(Self.Width / 2);
          Self.Right := Self.Left + (Self.Width - 1);
        end;

      3: // From Right
        begin
          Self.X := Self.Right - RoundInt(Self.Width / 2);
          Self.Left := Self.Right - Self.Width - 1;
          Self.Top := Self.y - RoundInt(Self.Height / 2);
          Self.Bottom := Self.Top + Self.Height - 1;
        end;

      4: // From Bottom
        begin
          Self.Y := Self.Bottom - RoundInt(Self.Height / 2);
          Self.Top := Self.Bottom - Self.Height - 1;
          Self.Left := SElf.X - RoundInt(SElf.Width / 2);
          Self.Right := SElf.LEft + SElf.Width - 1;
        end;

    end;

  end;

procedure TPGLRectI.Translate(X: Integer; Y: Integer);
  begin
    Self.X := Self.X + X;
    Self.Y := Self.Y + Y;
    Self.Update(FROMCENTER);
  end;

procedure TPGLRectI.Resize(Width: Integer; Height: Integer);
  begin
    Self.Width := Width;
    Self.Height := Height;
    Self.Update(FROMCENTER);
  end;

procedure TPGLRectI.Grow(Width: Integer; Height: Integer);
  begin
    Self.Width := Self.Width + Width;
    Self.Height := Self.Height + Height;
    Self.Update(FROMCENTER);
  end;

procedure TPGLRectI.Stretch(PercentX: Double; PercentY: Double);
  begin
    Self.Width := trunc(Self.Width * PercentX);
    Self.Height := trunc(Self.Height * PercentY);
    Self.Update(FROMCENTER);
  end;


function TPGLRectIHelper.ToRectF(): TPGLRectF;
  begin
    Result.X := (Self.X);
    Result.Y := (Self.Y);
    Result.Width := (Self.Width);
    Result.Height := (Self.Height);
    Result.Update(FROMCENTER);
  end;

function TPGLRectIHelper.toPoints: TPGLVectorQuad;
  begin
    Result[0] := vec2(Self.Left, Self.Top);
    Result[1] := vec2(Self.Right, Self.Top);
    Result[2] := Vec2(Self.Right, Self.Bottom);
    Result[3] := Vec2(Self.Left, Self.Bottom);
  end;


procedure TPGLRectF.SetLeft(Value: Single);
  begin
    Self.Left := Value;
    Self.Update(FROMLEFT);
  end;

procedure TPGLRectF.SetTop(Value: Single);
  begin
    Self.Top := Value;
    Self.Update(FROMTOP);
  end;

procedure TPGLRectF.SetRight(Value: Single);
  begin
    Self.Right := Value;
    Self.Update(FROMRIGHT);
  end;

procedure TPGLRectF.SetBottom(Value: Single);
  begin
    Self.Bottom := Value;
    Self.Update(FROMBOTTOM);
  end;

procedure TPGLRectF.SetTopLeft(L: Single; T: Single);
  begin
    Self.X := L + (Self.Width / 2);
    Self.Y := T + (Self.Height / 2);
    Self.Update(FROMCENTER);
  end;

procedure TPGLRectF.SetCenter(X: Single; Y: Single);
  begin
    Self.X := X;
    Self.Y := Y;
    Self.Update(FROMCENTER);
  end;


procedure TPGLRectF.Update(From: Integer);
  begin

    Case From of

      0: // From Center
        begin
          Self.Left := Self.X - (Self.Width / 2);
          Self.Right := Self.Left + Self.Width;
          Self.Top := Self.Y - (Self.Height / 2);
          Self.Bottom := Self.Top + Self.Height;
          Exit;
        end;

      1: // From LEft
        begin
          Self.X := Self.Left + (Self.Width / 2);
          Self.Right := Self.Left + Self.Width - 1;
          Self.Top := Self.y - (Self.Height / 2);
          Self.Bottom := Self.Top + SElf.Height - 1;
          Exit;
        end;

      2: // From Top
        begin
          Self.Y := Self.Top + (Self.Height / 2);
          Self.Bottom := Self.Top + Self.Height - 1;
          Self.Left := SElf.X - (SElf.Width / 2);
          Self.Right := SElf.LEft + SElf.Width - 1;
          Exit;
        end;

      3: // From Right
        begin
          Self.X := Self.Right - (Self.Width / 2);
          Self.Left := Self.Right - Self.Width - 1;
          Self.Top := Self.y - (Self.Height / 2);
          Self.Bottom := Self.Top + SElf.Height - 1;
          Exit;
        end;

      4: // From Bottom
        begin
          Self.Y := Self.Bottom - (Self.Height / 2);
          Self.Top := Self.Bottom - Self.Height - 1;
          Self.Left := SElf.X - (SElf.Width / 2);
          Self.Right := SElf.LEft + SElf.Width - 1;
          Exit;
        end;

    end;

  end;

procedure TPGLRectF.Translate(X: Double; Y: Double);
  begin
    Self.X := Self.X + X;
    Self.Y := Self.Y + Y;
    Self.Update(FROMCENTER);
  end;

procedure TPGLRectF.Resize(Width: Double; Height: Double);
  begin
    Self.Width := Width;
    Self.Height := Height;
    Self.Update(FROMCENTER);
  end;

procedure TPGLRectF.Grow(Width: Double; Height: Double);
  begin
    Self.Width := Self.Width + Width;
    Self.Height := Self.Height + Height;
    Self.Update(FROMCENTER);
  end;

procedure TPGLRectF.Stretch(PercentX: Double; PercentY: Double);
  begin
    Self.Width := Self.Width * PercentX;
    Self.Height := Self.Height * PercentY;
    Self.Update(FROMCENTER);
  end;

procedure TPGLRectF.Truncate();
  begin
    Self.X := trunc(Self.X);
    Self.Y := trunc(Self.Y);
    Self.Width := trunc(Self.Width);
    Self.Height := trunc(Self.Height);
    Self.Update(FROMCENTER);
    Self.Top := trunc(Self.Top);
    Self.Bottom := trunc(Self.Bottom);
    Self.Left := trunc(Self.Left);
    Self.Right := trunc(Self.Right);
  end;

procedure TPGLRectF.ResizeByAngle(Angle: GLFloat);
Var
Hyp: GLFloat;
NewWidth,NewHeight: GLFloat;
Points: TPGLVectorQuad;
  begin
    // Rotate corner points and set new bounds
    Points := Self.toPoints;
    RotatePoints(Points, Vec2(Self.X, Self.Y), Angle);
    Self := PointsToRectF(Points);
  end;

function TPGLRectF.ToRectFTrunc(): TPGLRectF;
  begin
    Result := self;
    Result.X := trunc(Result.X);
    Result.Y := trunc(Result.Y);
    Result.Width := trunc(Result.Width);
    Result.Height := trunc(Result.Height);
    Result.Update(FROMCENTER);
    Result.Top := trunc(Result.Top);
    Result.Bottom := trunc(Result.Bottom);
    Result.Left := trunc(Result.Left);
    Result.Right := trunc(Result.Right);
  end;


function TPGLRectFHelper.ToRectI(): TPGLRectI;
  begin
    Result.X := trunc(Self.X);
    Result.Y := trunc(Self.Y);
    Result.Width := trunc(Self.Width);
    Result.Height := trunc(Self.Height);
    Result.Update(FROMCENTER);
  end;

function TPGLRectFHelper.toPoints: TPGLVectorQuad;
  begin
    Result[0] := vec2(Self.Left, Self.Top);
    Result[1] := vec2(Self.Right, Self.Top);
    Result[2] := Vec2(Self.Right, Self.Bottom);
    Result[3] := Vec2(Self.Left, Self.Bottom);
  end;

function TPGLRectFHelper.CheckInside(Pos: TPGLVector2): Boolean;
  begin
    Result := False;
      if (Pos.X >= Self.Left) And
         (Pos.X <= Self.Right) And
         (Pos.Y >= Self.Top) And
         (POs.Y <= Self.Bottom) then begin

         Result := True;
      end;

  end;

function TPGLRectIHelper.CheckInside(Pos: TPGLVector2): Boolean;
  begin
    Result := False;
      if (Pos.X >= Self.Left) And
         (Pos.X <= Self.Right) And
         (Pos.Y >= Self.Top) And
         (POs.Y <= Self.Bottom) then begin

         Result := True;
      end;

  end;


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////TPGLTextureBatch ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

procedure TPGLTextureBatch.Clear();
Var
I: LongInt;

  begin

    for I := 0 To High(Self.TextureSlot) Do begin
      Self.TextureSlot[i] := 0;
    end;

    Self.Count := 0;
    Self.SlotsUsed := 0;

  end;

///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////Shapes /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

constructor TPGLPoint.Create(P: TPGLVector2; size: GLFloat; color: TPGLColorF);
  begin
    Self.pPos := P;
    Self.pSize := size;
    Self.pColor := color;
  end;

procedure TPGLPoint.SetPosition(P: TPGLVector2);
  begin
    Self.pPos.X := P.x;
    Self.pPos.Y := P.Y;
  end;

procedure TPGLPoint.Move(by: TPGLVector2);
  begin
    Self.pPos.X := Self.pPos.X + by.X;
    Self.pPos.Y := Self.pPos.Y + by.Y;
  end;

procedure TPGLPoint.SetColor(C: TPGLColorF);
  begin
    Self.pColor := C;
  end;


procedure TPGLPoint.SetSize(S: GLFloat);
  begin
    Self.pSize := S;
  end;



///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////Text   /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////pglCharaccter   ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

procedure TPGLCharacter.GetOutlinePoints;
  begin

  end;


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////TPGLFont ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////


constructor TPGLFont.Create(FileName: String; Sizes: Array of Integer; Bold: Boolean = False);


Var
I,R,T,Z,G,J: GLInt;
LoadFlags: TFTLoadFlags;
Buffer: Array of Byte;
W,H: TFTF26Dot6;
Face: TFTFace;
Quad: TPGLVectorQuad;
TW,TH: GLInt;
TS: Integer;

  begin


    Face := TFTFace.Create(PansiChar(AnsiString(FileName)),0);

    Self.FontName := (ExtractFileName(FileName));

    SetLength(Self.Atlas,Length(Sizes));

    for G := 0 to High(Sizes) Do begin

      H := trunc(Sizes[g] * 64);
      W := trunc(H*1.5);

      Face.SetCharSize(0,H,0,0);
      Self.Atlas[g].FontSize := Sizes[g];


      for I := 31 to 128 Do begin

        LoadFlags := [ftlfRender];

        if Chr(i) = '' then Continue;

        Face.LoadChar(I,LoadFlags);
        Face.Glyph.RenderGlyph(TFTRenderMode.ftrmLight);

        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

        Pgl.GenTexture(Self.Atlas[g].Character[i].Texture);
        PGL.BindTexture(0,Self.Atlas[g].Character[i].Texture);

        glTexImage2d(GL_TEXTURE_2D,0,GL_RED, trunc(Face.Glyph.Bitmap.Width),
                                              trunc(Face.Glyph.Bitmap.Rows),
                                              0,
                                              GL_RED,
                                              GL_UNSIGNED_BYTE,
                                              Face.Glyph.Bitmap.Buffer);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        glPixelStorei(GL_UNPACK_ALIGNMENT, 4);


        Self.Atlas[g].Character[i].Position := vec2(0,0);
        Self.Atlas[g].Character[i].Size := Vec2(Face.Glyph.Bitmap.Width, Face.Glyph.BitmapTop);
        Self.Atlas[g].Character[i].Symbol := Chr(i);
        Self.Atlas[g].Character[i].AsciiCode := Ord(Chr(i));

        {No SDF}
        Self.Atlas[g].Character[i].Metrics.Width := trunc(Face.Glyph.Metrics.Width / 64);
        Self.Atlas[g].Character[i].Metrics.Height := trunc(Face.Glyph.Metrics.Height / 64);
        Self.Atlas[g].Character[i].Metrics.SDFWidth := Self.Atlas[g].Character[i].Metrics.Width + 10;
        Self.Atlas[g].Character[i].Metrics.SDFHeight := Self.Atlas[g].Character[i].Metrics.Height + 10;
        Self.Atlas[g].Character[i].Metrics.Bearing := trunc(Face.Glyph.Metrics.HorzBearingY / 64);
        Self.Atlas[g].Character[i].Metrics.Advance := (Face.Glyph.Metrics.HorzAdvance / 64);
        Self.Atlas[g].Character[i].Metrics.TailHeight := Self.Atlas[g].Character[i].Height -
                                                         Self.Atlas[g].Character[i].Bearing;


        if Integer(Self.Atlas[g].OriginY) < Self.Atlas[g].Character[i].Bearing then begin
           Self.Atlas[g].OriginY := Self.Atlas[g].Character[i].Bearing;
        end;

        if Integer(Self.Atlas[g].TailMax) < Self.Atlas[g].Character[i].TailHeight then begin
           Self.Atlas[g].TailMax := Self.Atlas[g].Character[i].TailHeight;
        end;

        if Integer(Self.Atlas[g].TotalHeight) < Self.Atlas[g].Character[i].Height + Self.Atlas[g].Character[i].TailHeight then begin
           Self.Atlas[g].TotalHeight := Self.Atlas[g].Character[i].Height + Self.Atlas[g].Character[i].TailHeight;
        end;

      end;

      inc(Self.Atlas[g].TotalHeight,10);
      Face.Glyph.Bitmap.Done();
      Self.BuildAtlas(g);

      glBindTexture(GL_TEXTURE_2D,Self.Atlas[g].Texture);
      glGetTexLevelParameterIV(GL_TEXTURE_2D,0,GL_TEXTURE_WIDTH,@TW);
      glGetTexLevelParameterIV(GL_TEXTURE_2D,0,GL_TEXTURE_HEIGHT,@TH);
      TS := Sizes[g];

      PGLSaveTexture(Self.Atlas[g].Texture,TW,TH,
        pglEXEPath + 'Test Pics/Atlas ' + IntToStr(TS) + '.bmp');

    end;

    FT_Done_Face(Face);


  end;


function TPGLFont.ChooseAtlas(CharSize: GLUInt): Integer;

Var
Selected: GLUInt;
CurDiff: GLInt;
I: GLInt;

  begin

    CurDiff := 1000;

    Selected := 0;

    for I := 0 to High(Self.Atlas) Do begin

      if abs(Integer(CharSize) - Self.Atlas[i].FontSize) < CurDiff then begin
        Selected := I;
        CurDiff := Abs(Integer(CharSize) - Self.Atlas[i].FontSize);
      end;

    end;

    Result := Selected;

  end;


procedure TPGLFont.BuildAtlas(A: GLInt);

Var
TotalWidth: GLFloat;
I,R: GLInt;
CurrentX: GLInt;
Ver: TPGLVectorQuad;
Cor: TPGLVectorQuad;
Buffer: Array Of Byte;
CheckVar: glEnum;
CheckWidth: GLInt;
CurChar: ^TPGLCharacter;
Lowest, Highest: Byte;
Swizzle: Array [0..3] of GLInt;
ReturnVal: ByteBool;


  begin

    TotalWidth := 0;

    for I := 0 to High(Self.Atlas[A].Character) Do begin
      TotalWidth := TotalWidth + Self.Atlas[A].Character[i].Metrics.SDFWIDTH + 1;
    end;

    Pgl.GenTexture(Self.Atlas[A].Texture);
    PGL.BindTexture(0,Self.Atlas[A].Texture);

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    glTexImage2d(GL_TEXTURE_2D,0,GL_RED,trunc(TotalWidth),Self.Atlas[A].TotalHeight,0,GL_RED,GL_UNSIGNED_BYTE,nil);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    PGL.UnbindTexture(Self.Atlas[A].Texture);

    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);

    Cor[0] := vec2(0,1);
    Cor[1] := vec2(1,1);
    Cor[2] := vec2(1,0);
    Cor[3] := vec2(0,0);

    CurrentX := 5;

    pglTempBuffer.SetSize(trunc(TotalWidth),Self.Atlas[A].TotalHeight);
    pglTempBuffer.MakeCurrentTarget;
    pglTempBuffer.Clear(pgl_empty);
    glDrawBuffer(GL_COLOR_ATTACHMENT0);

    for I := 31 to High(Self.Atlas[A].Character) Do begin

      PGL.BindTexture(0,Self.Atlas[A].Character[i].Texture);

      CurChar := @Self.Atlas[A].Character[i];

      Self.Atlas[A].Character[i].Position.X := CurrentX;
      Self.Atlas[A].Character[i].Position.Y := Self.Atlas[A].Character[i].Bearing;

      Self.Atlas[A].Character[i].SDFPosition.X := Self.Atlas[A].Character[i].Position.X - 5;
      Self.Atlas[A].Character[i].SDFPosition.Y := Self.Atlas[A].Character[i].Position.Y - 5;

      Ver[0] := vec2(CurrentX,
                     Integer(Self.Atlas[A].OriginY) + Self.Atlas[a].Character[i].TailHeight + 5);

      Ver[1] := vec2(CurrentX + Self.Atlas[A].Character[i].Metrics.Width,
                     Integer(Self.Atlas[A].OriginY) + Self.Atlas[a].Character[i].TailHeight + 5);

      Ver[2] := vec2(CurrentX + Self.Atlas[A].Character[i].Metrics.Width,
                     Integer(Self.Atlas[A].OriginY) - Self.Atlas[a].Character[i].Bearing);

      Ver[3] := vec2(CurrentX,
                     Integer(Self.Atlas[A].OriginY) - Self.Atlas[a].Character[i].Bearing);

      pglTempBuffer.Buffers.Bind();

      pglTempBuffer.Buffers.BindVBO(0);
      pglTempBuffer.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(Ver),@Ver);
      glEnableVertexAttribArray(0);
      glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,POinter(0));


      pglTempBuffer.Buffers.BindVBO(1);
      pglTempBuffer.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(Cor),@Cor);
      glEnableVertexAttribArray(1);
      glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,POinter(0));

      TextureSimpleProgram.Use();

      glUniform1i(pglGetUniform('tex'),0);
      glUniform1f(pglGetUniform('planeWidth'),TotalWidth);
      glUniform1f(pglGetUniform('planeHeight'),Self.Atlas[A].TotalHeight);

      glDrawArrays(GL_QUADS,0,4);

      PGL.UnbindTexture(Self.Atlas[A].Character[i].Texture);

      CurrentX := CurrentX + trunc(Self.Atlas[A].Character[i].Metrics.Width + 10);

      PGL.DeleteTexture(Self.Atlas[a].Character[i].Texture);
    end;

//    pglTempBuffer.Smooth(RectFWH(0,0,pglTempBuffer.Width,pglTempBuffer.Height),pgl_empty);

    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,Self.Atlas[A].Texture,0);

    Ver[0] := Vec2(0, 0);
    Ver[1] := Vec2(TotalWidth, 0);
    Ver[2] := Vec2(TotalWidth, Self.Atlas[a].TotalHeight);
    Ver[3] := Vec2(0, Self.Atlas[a].TotalHeight);

    Cor[0] := vec2(0,0);
    Cor[1] := vec2(1,0);
    Cor[2] := vec2(1,1);
    Cor[3] := vec2(0,1);

    PGL.BindTexture(0,pglTempbuffer.Texture2D);

    pglTempBuffer.Buffers.BindVBO(0);
    PglTempBuffer.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(Ver),@Ver);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    pglTempBuffer.Buffers.BindVBO(1);
    PglTempBuffer.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(Cor),@Cor);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    SDFProgram.Use();

    glUniform1i(PGLGetUniform('tex'),0);
    glUniform1f(PGLGetUniform('planeWidth'),pglTempBuffer.Width);
    glUniform1f(PGLGetUniform('planeHeight'),pglTempBuffer.Height);

    glDrawArrays(GL_QUADS,0,4);

    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,pglTempBuffer.Texture2D,0);
    pglTempBuffer.Clear();
  end;


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////TPGLText ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

constructor TPGLText.Create(Font: TPGLFont; Chars: string);
  begin
    Self.UseFont := Font;
    Self.UseColor := Color4f(1,1,1,1);
    Self.UseBorderColor := Color4f(1,1,1,1);
    Self.UseBorderSize := 0;
    Self.UseCharSize := Font.FontSize;
    Self.SetText(Chars);
  end;



procedure TPGLText.FindBounds;
Var
Width,Height: GLFloat;
Highest, Lowest: GLFloat;
Len: GLInt;
I: GLInt;
CurChar: TPGLCharacter;
CurFont: TPGLFont;
UseAtlas: ^TPGLAtlas;
AdjPer: GLFloat;

  begin

    Self.CurrentAtlas := Self.UseFont.ChooseAtlas(Self.CharSize);
    UseAtlas := @Self.UseFont.Atlas[Self.CurrentAtlas];

    if Self.UseMultiLine = True then begin

      Exit;
    end;

    AdjPer := Self.CharSize / UseAtlas.FontSize;

    Len := Length(Self.UseText);

    Lowest := 0;
    Highest := 0;
    Width := 0;
    Height := 0;
    CurFont := Self.UseFont;

    for I := 1 to Len Do begin
      CurChar := UseAtlas.Character[Ord(Self.UseText[i])];
      Width := Width + ((CurChar.Advance) * AdjPer) + (Self.BorderSize*2);
    end;

    Self.UseTextBounds.Width := trunc(Width);
    Self.UseTextBounds.Height := UseAtlas.TotalHeight * AdjPer;
    Self.UseBounds.Width := Width;
    Self.UseBounds.Update(FROMLEFT);
    Self.UseBounds.HEight := UseAtlas.TotalHeight * AdjPer;
    Self.UseBounds.Update(FROMTOP);

  end;


procedure TPGLText.SetText(Chars: String);
  begin
    Self.UseText := Chars;
    Self.FindBounds();
  end;


procedure TPGLText.SetColor(Color: TPGLColorI);
  begin
    Self.UseColor := ColorIToF(Color);
  end;


procedure TPGLText.SetBorderColor(Color: TPGLColorI);
  begin
    Self.UseBorderColor := cc(Color);
  end;

procedure TPGLText.SetBorderSize(Size: Integer);
  begin
    Self.UseBorderSize := Size;
    Self.FindBounds();
  end;

procedure TPGLText.SetCharSize(Size: Integer);
  begin
    Self.UseCharSize := Size;
    Self.FindBounds();
  end;

procedure TPGLText.SetShadow(Shadow: Boolean = True);
  begin
    Self.UseShadow := Shadow;
  end;

procedure TPGLText.Rotate(Angle: GLFloat);
  begin
    Self.UseAngle := Self.UseAngle + Angle;
  end;

procedure TPGLText.SetRotation(Angle: GLFloat);
  begin
    Self.UseAngle := Angle;
  end;

procedure TPGLText.SetSmooth(Smooth: Boolean = True);
  begin
    Self.UseSmooth := Smooth;
  end;

procedure TPGLText.SetUseGradientColors(UseGradient: Boolean = True);
  begin
    Self.UseHasGradient := UseGradient;
  end;

procedure TPGLText.SetGradientColors(LeftColor: TPGLColorF; RightColor: TPGLColorF);
  begin
    Self.UseGradientColorLeft := LeftColor;
    Self.UseGradientColorRight := RightColor;
  end;

procedure TPGLText.SetGradientXOffSet(XOffSet: Single);
  begin
    Self.UseGradientOffset := XOffSet;
  end;

procedure TPGLText.WrapText(WrapWidth: GLFloat);

Var
I,R: Long;
Len: Integer;
CurChar: ^TPGLCharacter;
CurPos: Integer;
LastPos: Integer;
CurWidth: GLFloat;
ReadChar: String;
Words: Array of String;
WordCount: Integer;
WordWidth: GLFloat;
AdjPer: GLFloat;
OutText: String;
WrapHeight: GLFloat;
Lines: GLInt;

  begin

    if Length(Self.Text) = 0 then Exit;

    CurPos := 1;
    LastPos := 1;
    CurWidth := 0;
    WordCount := 0;
    Lines := 1;
    Len := Length(Self.Text);
    AdjPer :=  Self.UseFont.Atlas[Self.CurrentAtlas].FontSize / Self.CharSize;
    OutText := '';
    WrapHeight := (Self.UseFont.Atlas[Self.CurrentAtlas].TotalHeight) * AdjPer + (Self.BorderSize * 2);

    while CurPos < Len Do begin

      ReadChar := AnsiMidStr(Self.Text,CurPos,1);

      if ReadChar = ' '  then begin
        SetLength(Words,Length(Words) + 1);
        WordCount := Length(Words)-1;
        Words[WordCount] := AnsiMidStr(Self.Text,LastPos,CurPos - LastPos + 1);
        LastPos := CurPos + 1;
      end;

      CurPos := CurPos + 1;

      if CurPos = Len then begin
        SetLength(Words,Length(Words) + 1);
        WordCount := Length(Words)-1;
        Words[WordCount] := AnsiMidStr(Self.Text,LastPos,CurPos - LastPos + 1);
        Break;
      end;

    end;


    for I := 0 to WordCount Do begin

      Len := Length(Words[i]);

      WordWidth := 0;

      for R := 1 to Len Do begin
        CurChar := @Self.UseFont.Atlas[Self.CurrentAtlas].Character[ Ord( Self.Text[R] ) ];
        WordWidth := WordWidth + (CurChar.Advance * AdjPer) + (Self.BorderSize * 2);
      end;

      if CurWidth + WordWidth > WrapWidth then begin
        CurWidth := WordWidth;
        OutText := OutText + sLineBreak + Words[I];
        Lines := Lines + 1;
      End Else begin
        CurWidth := CurWidth + WordWidth;
        OutText := OutText + Words[i];
      end;

    end;

    WrapHeight := WrapHeight * Lines;
    Self.SetMultiLine(True);
    Self.SetMultiLineBounds(glDrawMain.RectFWH(Self.Bounds.Left,Self.Bounds.Top,WrapWidth,WrapHeight));
    Self.UseBounds := Self.MultiLineBounds;

    Self.UseWrapText := OutText;
    Self.UseLineCount := Lines;
    SetLength(Self.UseLineStart,Lines);

  end;



procedure TPGLText.SetCenter(Center: TPGLVector2);
  begin
    Self.UseBounds.X := trunc(Center.X);
    Self.UseBounds.Y := trunc(Center.Y);
    Self.UseBounds.Update(FROMCENTER);
  end;

procedure TPGLText.SetTopLeft(TopLeft: TPGLVector2);
  begin
    Self.UseBounds.X := trunc(TopLeft.X + (Self.Bounds.Width / 2));
    Self.UseBounds.Y := trunc(TopLeft.Y + (Self.Bounds.Height / 2));
    Self.UseBounds.Update(FROMCENTER);
  end;

procedure TPGLText.SetLeft(Left: Single);
  begin
    Self.UseBounds.Left := Left;
    Self.UseMultiLineBounds.Left := Left;
    Self.UseBounds.Update(FROMLEFT);
    Self.UseMultilinebounds.Update(FROMLEFT);
  end;

procedure TPGLText.SetTop(Top: Single);
  begin
    Self.UseBounds.Top := Top;
    Self.UseMultiLineBounds.Top := Top;
    Self.UseBounds.Update(FROMTOP);
    Self.UseMultilinebounds.Update(FROMTOP);
  end;

procedure TPGLText.SetRight(Right: Single);
  begin
    Self.UseBounds.Right := Right;
    Self.UseMultiLineBounds.Right := Right;
    Self.UseBounds.Update(FROMRIGHT);
    Self.UseMultilinebounds.Update(FROMRIGHT);
  end;


procedure TPGLText.SetBottom(Bottom: Single);
  begin
    Self.UseBounds.Bottom := Bottom;
    Self.UseMultiLineBounds.Bottom := Bottom;
    Self.UseBounds.Update(FROMCENTER);
    Self.UseMultilinebounds.Update(FROMBOTTOM);
  end;

procedure TPGLText.SetX(X: Single);
  begin
    Self.UseBounds.X := X;
    Self.UseMultiLineBounds.X := X;
    Self.UseBounds.Update(FROMCENTER);
    Self.UseMultilinebounds.Update(FROMCENTER);
  end;

procedure TPGLText.SetY(Y: Single);
  begin
    Self.UseBounds.Y := Y;
    Self.UseMultiLineBounds.Y := Y;
    Self.UseBounds.Update(FROMCENTER);
    Self.UseMultilinebounds.Update(FROMCENTER);
  end;


procedure TPGLText.SetMultiLine(Value: Boolean = True);
  begin
    Self.UseMultiLine := Value;
  end;

procedure TPGLText.SetMultiLineBounds(Bounds: TPGLRectF);
  begin
    Self.UseMultiLineBounds := Bounds;
    Self.UseBounds := Bounds;
  end;

procedure TPGLText.SetWidth(Value: Cardinal);
  begin
    Self.UseBounds.Width := trunc(Value);
    Self.UseBounds.Update(FROMCENTER);

    if Self.UseMultiLine = True then begin
      Self.UseMultiLineBounds.Width := Value;
      Self.UseMultiLineBounds.Update(FROMCENTER);
    end;
  end;


function TPGLText.FindPosition: TPGLVector2;
  begin
    Result := Vec2(Self.Bounds.X,Self.Bounds.Y);
  end;

function TPGLText.FindTopLeft: TPGLVector2;
  begin
    Result := Vec2(Self.Bounds.Left, Self.Bounds.Top);
  end;

function TPGLText.FindWidth: Integer;
  begin
    Result := trunc(Self.Bounds.Width);
  end;

function TPGLText.FindHeight: Integer;
  begin
    Result := trunc(Self.Bounds.Height);
  end;


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////TPGLTextFormat //////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////


procedure TPGLTextFormat.Reset();
  begin

    Self.Position := Vec2(0,0);
    Self.Width := 0;
    Self.Height := 0;
    Self.CharSize := 0;
    Self.Font := nil;
    Self.AtlasIndex := 0;
    Self.Color := Color4f(0,0,0,0);
    Self.BorderColor := Color4f(0,0,0,0);
    Self.BorderSize := 0;
    Self.Shadow := False;
    Self.ShadowOffSet := Vec2(0,0);
    Self.ShadowColor := Color4f(0,0,0,0);
    Self.Smooth := false;
    Self.Rotation := 0;
    Self.UseGradient := false;
    Self.GradientLeft := color4f(0,0,0,0);
    Self.GradientRight := Color4f(0,0,0,0);
    Self.GradientXOffSet := 0;

  end;


procedure TPGLTextFormat.SetFormat(iPosition: TPGLVector2; iWidth: Integer;
          iHeight: Integer; iFont: TPGLFont; iAtlasIndex: Integer; iColor: TPGLColorF;
          iBorderColor: TPGLColorF; iBorderSize: Cardinal; iShadow: Boolean; iShadowOffset: TPGLVector2;
          iShadowColor: TPGLColorF; iSmooth: Boolean; iRotation: Single; iUseGradient: Boolean;
          iGradientLeft,iGradientRight: TPGLColorF; iGradientXOffSet: glFloat);

  begin
    Self.Position := iPosition;
    Self.Width := iWidth;
    Self.Height := iHeight;
    Self.Font := iFont;
    Self.AtlasIndex := iAtlasIndex;
    Self.Color := iColor;
    Self.BorderColor := iBorderColor;
    Self.BorderSize := iBorderSize;
    Self.Shadow := iShadow;
    Self.ShadowOffSet := iShadowOffset;
    Self.ShadowColor := iShadowColor;
    Self.Smooth := iSmooth;
    Self.Rotation := iRotation;
    Self.UseGradient := iUseGradient;
    Self.GradientLeft := iGradientLeft;
    Self.GradientRight := iGradientRight;
    Self.GradientXOffSet := iGradientXOffset;

    // Ensure Width and Height are Valide
    if Self.Width <0 then begin
      Self.Width := -1;
    end;

    if Self.Height <= 0 then begin
      Self.Height := -1;
    end;

    // if the font passed is valid, Ensure atlas index and char size are valid
    if Assigned(iFont) then begin

      if (Self.AtlasIndex <= Low(Font.Atlas)) and (Self.AtlasIndex >= High(Font.Atlas)) then begin
        Self.AtlasIndex := 0;
      end;

      if Self.CharSize <= 0 then begin
        Self.CharSize := iFont.Atlas[Low(iFont.Atlas)].FontSize;
      end;

    end;

  end;

end.

