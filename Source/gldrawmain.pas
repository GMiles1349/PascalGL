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
- prefixes
  pgl* : Data types
  PGL* : Function/Procedure
  PGL_* : Enums, Constants
  p* : Class field for properties
  P* : Pointer to data type


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

  Type pglWindowFlag =
    (pglFullScreen, pglTitleBar, pglSizable, pglDebug, pglScreenCenter);

  Type pglWindowFlags = Set of pglWindowFlag;

  Type pglFrameResizeFunc = Procedure();

  Type pglController = glDrawContext.pglControllerInstance;
  Type pglMouse = glDrawContext.pglMouseInstance;
  Type pglKeyBoard = glDrawContext.pglKeyBoardInstance;

  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////Buffer Objects//////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  {----------------------------------------------------------------------------}
  {

                                                                               }
  {----------------------------------------------------------------------------}

  Type Float2 = Array [0..1] of Float32;
  Type Float4 = Array [0..3] of Float32;

  Type pglArrayIndirectBuffer = Record
    Count,InstanceCount,First,BaseInstance: GLUInt;
  End;

  Type pglElementsIndirectBuffer = Record
    Count,InstanceCount,FirstIndex,BaseVertex,BaseInstance: GLUInt;
  End;

  Type pglVBO = Record

    Private
      InUse: Boolean;
      Buffer: GLUInt;
      SubDataOffSet: GLInt;
      SubDataSize: GLInt;

      Procedure SubData(Binding: glEnum; Offset: GLInt; Size: GLInt; Source: Pointer);
  End;


  Type pglSSBO = Record

    Private
      InUse: Boolean;
      Buffer: GLUInt;
      SubDataOffSet: GLInt;
      SubDataSize: GLInt;

      Procedure SubData(Binding: glEnum; Offset: GLInt; Size: GLInt; Source: Pointer);
  End;

  Type pglBufferCollection = Record

    Public

      VAO: GLUInt;
      EBO: GLUInt;
      VBO: Array [0..39] of pglVBO;
      SSBO: Array [0..39] of pglSSBO;
      CurrentVBO: ^pglVBO;
      CurrentSSBO: ^pglSSBO;
      VBOInc: GLInt;
      SSBOInc: GLInt;

      Const BufferSize:GLUInt = 512000;

      Class Operator Initialize (Out Dest: pglBufferCollection); Register;
      Procedure Bind(); Register;
      Procedure InvalidateBuffers(); Register;
      Procedure BindVBO(N: GLUInt); Register;
      Procedure BindSSBO(N: GLUInt); Register;
      Function GetNextVBO(): GLUInt; Register;
      Function GetNextSSBO(): GLUInt; Register;
  End;

  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////Vectors and Matrices////////////////////////////
  //////////////////////////////////////////////////////////////////////////////


  Type pglMatrix4 = Record
    M: Array [0..15] of GLFloat;
  End;

  Type pglMatrix3 = Record
    M: Array [0..8] of GLFloat;
    Procedure Fill(Values: Array of GLFloat); Register;
    Function Val(X,Y: GLUint): GLFloat; Register;
  End;

  Type pglMatrix2 = Record
    M: Array [0..1] of Array [0..1] of GLFloat;

    Procedure MakeRotation(Angle: GLFloat); Register;
    Procedure MakeTranslation(X,Y: GLFloat); Register;
    Procedure MakeScale(sX,sY: GLFloat); Register;
    Procedure Rotate(Angle: GLFloat); Register;
    Procedure Translate(X,Y: GLFloat); Register;
    Procedure Scale(sX,sY: GLFloat); Register;

  End;


  Type pglIndices = Record

    Index: Array [0..5] of GLUInt;
  End;

	Type pglRectI = Record
    Left,Right,Top,Bottom,X,Y,Width,Height: GLInt;

    Procedure SetLeft(Value: GLInt); Register;
    Procedure SetTop(Value: GLInt); Register;
    Procedure SetRight(Value: GLInt); Register;
    Procedure SetBottom(Value: GLInt); Register;
    Procedure SetTopLeft(L,T: GLInt); Register;
    Procedure SetCenter(X,Y: GLInt); Register;
    Procedure Update(From: Integer); Register;
    Procedure Translate(X,Y: Integer); Register;
    Procedure Resize(Width,Height: Integer); Register;
    Procedure Grow(Width,Height: Integer); Register;
    Procedure Stretch(PercentX,PercentY: Double); Register;
  End;


  Type pglRectF = Record
    Left,Right,Top,Bottom,X,Y,Width,Height: GLFloat;

    Procedure SetLeft(Value: GLFloat); Register;
    Procedure SetTop(Value: GLFloat); Register;
    Procedure SetRight(Value: GLFloat); Register;
    Procedure SetBottom(Value: GLFloat); Register;
    Procedure SetTopLeft(L,T: GLFloat); Register;
    Procedure SetCenter(X,Y: GLFloat); Register;
    Procedure Update(From: Integer); Register;
    Procedure Translate(X,Y: Double); Register;
    Procedure Resize(Width,Height: Double); Register;
    Procedure Grow(Width,Height: Double); Register;
    Procedure Stretch(PercentX,PercentY: Double); Register;
    Procedure Truncate(); Register;
    Procedure ResizeByAngle(Angle: GLFloat); Register;
    Function ToRectFTrunc(): pglRectF; Register;
  End;


  Type pglVector2 = Record
    X,Y: GLFloat;

    Procedure MatrixMultuply(Mat: pglMatrix2); Register;
    Procedure Translate(X,Y: GLFloat); Register;
    Procedure Rotate(Angle: GLFloat); Register;
    Procedure Scale(sX,sY: GLFloat); Register;
    Procedure Normalize(Origin: pglVector2); Register;
  End;

  type pglVector3 = Record
    X,Y,Z: GLFloat;
    Class Operator Subtract(A: pglVector3; B: pglVector3): pglVector3;
    Procedure Normalize(); Register;
    Procedure Cross(Vec: pglVector3); Register;
    Procedure MatrixMultiply(Mat: pglMatrix3); Register;
    Procedure Translate(X: Single = 0; Y: Single = 0; Z: Single = 0); Register;
  End;

  type pglVector4 = Record
    X,Y,Z,W: GLFloat;
  end;

  type pglVectorQuad = Array [0..3] of pglVector2;
  type pglVectorTriangle = Array [0..5] of pglVector2;

  type pglColorI = Record
    Red,Green,Blue,Alpha: glUByte;
    Function Value(): Double;
    Function ToMultiply(Ratio: Single): pglColorI; Register;
    Procedure Adjust(Percent: Integer; AdjustAlpha: Boolean = False); Register;
  End;

  Type pglColorF = Record
    Red,Green,Blue,Alpha: glClampF;
    Function Value(): Double;
    Function ToMultiply(Ratio: Single): pglColorF; Register;
  End;

  Type ColorFArray = Array of pglColorF;
  Type ColorIArray = Array of pglColorI;


  Type pglRenderParams = Record

    ColorValues: pglColorI;
    ColorOverlay: pglColorI;
    MaskColor: pglColorI;
    GreyScale: Boolean;
    MonoChrome: Boolean;
    Opacity: GLFloat;
    PixelSize: GLInt;
  End;

  Type pglCharArray = Array of AnsiChar;


  {///////////// Shapes ///////////////////}
  Type pglShape = Class(TPersistent)

    Private
      Count: GLInt;
      Points: Array of pglVector2;
      Color: ColorFArray;
      Center: pglVector2;

    Public


      Property Position: pglVector2 read Center;
      Property PointColor: ColorFArray read Color;

  End;


  Type pglPoint = Class(TPersistent)

    Private
      pPos: pglVector2;
      pColor: pglColorF;
      pSize: GLFloat;


    Public
      Constructor Create(P: pglVector2; size: GLFloat; color: pglColorF);
      Procedure SetPosition(P: pglVector2); Register;
      Procedure Move(by: pglVector2); Register;
      Procedure SetColor(C: pglColorF); Register;
      Procedure SetSize(S: GLFloat); Register;

      Property Position: pglVector2 read pPos write SetPosition;
      Property Color: pglColorF read pColor write SetColor;
      Property Size: GLFloat read pSize write SetSize;

  End;


  Type pglCircleDescriptor = Record
    Center: pglVector2;
    Width: GLFloat;
    BorderWidth: GLFloat;
    FillColor: pglColorF;
    BorderColor: pglColorF;
    Fade: pglVector4;
  End;

  Type pglCircleBatch = Record

    Count: GLInt;
    Data: PByte;
    Vector: Array [0..4000] of pglVectorQuad;
    Class Operator Initialize(Out Dest: pglCircleBatch);
  End;

  Type pglRectangleBatch = Record

    Count: GLInt;

    Vector: Array [0..40000] of pglVectorQuad;
    Center: Array [0..10000] of pglVector2;
    Dims: Array [0..10000] of pglVector2;
    BorderWidth: Array [0..10000] of GLFloat;
    FillColor: Array [0..10000] of pglColorF;
    BorderColor: Array [0..10000] of pglColorF;
    Curve: Array [0..10000] of GLFloat;
  End;

  Type pglPointBatch = Record
    Count: GLInt;
    Data: PByte;
    Class Operator Initialize(Out Dest: pglPointBatch);
  End;

  Type pglPolygonBatch = Record

    Count: GLInt;
    ShapeCount: GLInt;
    ElementCount: GLInt;
    Vector: Array [0..10000] of pglVector2;
    Color: Array [0..10000] of pglColorF;
    Size: Array [0..10000] of GLFloat;
  End;

  Type pglLightBatch = Record

    Count: GLInt;
    Vertices: Array [0..1000] of pglVectorQuad;
    TexCoords: Array [0..1000] of pglVectorQuad;
    Center: Array [0..1000] of pglVector2;
    Radius: Array [0..1000] of GLFloat;
    Radiance: Array [0..1000] of GLFloat;
    Color: Array [0..1000] of pglColorf;
  End;


  Type pglLightPolygonDescriptor = Record
    Center: pglVector2;
    Color: pglColorF;
    Radius: GLFloat;
    Radiance: GLFloat;
  End;

  type pglLightPolygonBatch = Record
    Count: GLInt;
    Points: Array [0..1000] of pglVector2;
    Index: Array [0..1000] of GLUInt;
    Center: Array [0..50] of pglVector2;
    Color: Array [0..50] of  pglColorF;
    Radius: Array [0..50] of  GLFloat;
    Radiance: Array [0..50] of  GLFloat;
  End;

  Type pglLineBatch = Record
    Count: GLInt;
    Points: Array [0..1000] of pglVector2;
    Color: Array [0..1000] of pglColorF;
  End;

  Type pglShapeDesc = Record
    FillColor: pglColorF;
    BorderColor: pglColorF;
    Width,Height,BorderWidth,ShapeType: GLFloat;
    Pos: pglVector4; // X,Y = center, Z = Angle
  End;

  Type pglShapeBatch = Record
    Count: GLUInt;
    PointCount: GLUInt;
    Points: Array [0..10000] of pglVector2;
    Normal: Array [0..10000] of pglVector2;
    IndexBuffer: Array [0..10000] of GLUInt;
    ShapeBuffer: Array [0..1000] of pglArrayIndirectBuffer;
    Shape: Array [0..1000] of pglShapeDesc;
  End;

  Type pglGeometryBatch = Record
    Count: GLUint;
    Next: GLint;
    Data: PByte;
    DataSize: GLInt;
    Normals: PByte;
    NormalsSize: GLInt;
    Color: PByte;
    ColorSize: GLInt;
    IndirectBuffers: Array [0..1000] of pglArrayIndirectBuffer;
    Class Operator Initialize(Out Dest: pglGeometryBatch);
  End;

  Type pglTextureBatch = Record

    Count: GLInt;
    TextureSlot: Array [0..31] of GLInt;
    SlotsUsed: GLInt;
    Vertices: Array [0..1000] of  pglVectorQuad;
    TexCoords: Array [0..1000] of pglVectorQuad;
    Indices: Array [0..1000] of pglIndices;
    SlotUsing: Array [0..1000] of GLInt;
    MaskColor: Array [0..1000] of pglColorF;
    Opacity: Array [0..1000] of GLFloat;
    ColorVals: Array [0..1000] of pglColorF;
    Overlay: Array [0..1000] of pglColorF;
    GreyScale: Array [0..1000] of GLUint;

    Procedure Clear(); Register;

  End;

  Type pglLightSource = Class

    Public

    Active: Boolean;

    Position: pglVector2;
    Bounds: pglRectF;
    Width: GLFloat;
    Color: pglColorF;
    Radiance: GLFloat;

    Ver: pglVectorQuad;
    Cor: pglvectorQuad;

    Constructor Create(); Register;
    Procedure SetActive(isActive: Boolean = True); Register;
    Procedure SetPosition(Pos: pglVector2); Register;
    Procedure SetColor(Color: pglColorF); Overload; Register;
    Procedure SetColor(Color: pglColorI); Overload; Register;
    Procedure SetRadiance(RadianceVal: GLFloat); Register;
    Procedure SetWidth(Val: GLFloat); Register;
    Procedure Place(Pos: pglVector2; WidthVal: GLFloat); Register;

  End;

  Type pglImageDescriptor = Record

    Public
      Handle: Pointer;
      Width,Height: GLUInt;

  End;

  Type pglImage = Class(TPersistent)

    Private
      isValid: Boolean;
      pHandle: PByte;
      pDataSize: GLInt;
      DataEnd: PByte;
      pChannels: GLInt;
      Data: Array of pglColorI;
      RowPtr: Array of PByte;
      pWidth,pHeight: GLInt;

      Procedure DefineData(); Register;
      Procedure Delete(); Register;

    Public


      Constructor Create(Width: GLUint = 1; Height: GLUint = 1); Register;
      Constructor CreateFromFile(FileName: String); Register;
      Constructor CreateFromMemory(Source: Pointer; Width,Height: NativeUInt; Size: NativeUInt); Register;
      Destructor Destroy(); Override;
      Procedure Clear(); Register;
      Procedure LoadFromFile(FileName: AnsiString); Register;
      Procedure LoadFromMemory(Source: Pointer; Width,Height: GLUInt); Register;
      Procedure CopyFromImage(Var Source: pglImage); Overload; Register;
      Procedure CopyFromImage(Var Source: pglImage; SourceRect, DestRect: pglRectI); Overload; Register;
      Procedure ReplaceColor(TargetColor,NewColor: pglColorI); Register;
      Procedure Darken(Percent: GLFloat); Register;
      Procedure Brighten(Percent: GLFloat); Register;
      Procedure AdjustAlpha(Alpha: GLFloat; IgnoreTransparent: Boolean = True); Register;
      Procedure ToGreyScale(); Register;
      Procedure ToNegative(); Register;
      Procedure Smooth(); Register;
      Procedure SaveToFile(FileName: String); Register;
      Procedure Resize(NewWidth, NewHeight: GLUint); Register;
      Function Pixel(X,Y: Integer): pglColorI; Register;
      Procedure SetPixel(Color: pglColorI; X,Y: Integer) Register;
      Procedure BlendPixel(Color: pglColorI; X,Y: GLInt; SourceFactor: GLFLoat); Register;
      Procedure Pixelate(PixelWidth: GLUint = 2); Register;

      Property Width: GLint read pWidth;
      Property Height: GLint read pHeight;
      Property Handle: PByte read pHandle;
      Property Channels: GLInt read pChannels;
      Property DataSize: GLInt read pDataSize;

  End;


  Type pglTexture = Class

    Public
    Handle: GLUInt;
    Width,Height: GLUInt;
    BitDepth: GLInt;

    Constructor Create(Width: GLUint = 0; Height: GLUint = 0); Register;
    Constructor CreateFromImage(Image: pglImage);
    Constructor CreateFromFile(FileName: string);
    Constructor CreateFromTexture(Texture: pglTexture);
    Procedure Delete(); Register;
    Procedure SaveToFile(FileName: String);
    Procedure Smooth(Area: pglRectF; IgnoreColor: pglColorI); Register;
    Procedure ReplaceColors(TargetColors: Array of pglColorI; NewColor: pglColorI; Tolerance: Double = 0); Register;
    Procedure CopyFromData(Data: Pointer; Width,Height: GLInt); Register;
    Procedure CopyFromTexture(Source: pglTexture; X,Y,Width,Height: GLUInt); Register;
    Procedure SetSize(Width,Height: GLUint; KeepImage: Boolean = False); Register;
    Function Pixel(X,Y: Integer): pglColorI; Register;
    Function SetPixel(Color: pglColorI; X,Y: Integer): pglColorI; Register;
    Procedure Pixelate(PixelWidth: GLUint = 2); Register;
    Procedure CopyToImage(Dest: pglImage; SourceRect, DestRect: pglRectI);
    Procedure CopyToAddress(Dest: Pointer); Register;
    Procedure SetNearestFilter(); Register;
    Procedure SetLinearFilter(); Register;

    Private

    Procedure CheckDefaultReplace(); Register;

  End;



  Type pglSprite = Class

    Private
      pTexture: pglTexture;
      pBounds: pglRectF;
      pTextureRect: pglRectI;
      pTextureSize: pglVector2;
      pMonoChrome: Boolean;
      pGreyScale: Boolean;
      pOpacity: GLFloat;
      pMaskColor: pglColorF;
      pAngle: GLFloat;
      pOrigin: pglVector2;
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
      pColorValues: pglColorF;
      pColorOverlay: pglColorF;
      // Pointers
        pColorValuesPointer: ^pglColorF;
        pColorOverlayPointer: ^pglColorF;

      Ver: pglVectorQuad;
      Cor: pglVectorQuad;
      Translation,Scale,Rotation: pglMatrix4;

      pRectSet: Array [1..100] of pglRectI;


    Private

      Procedure Initialize(); Register;
      Procedure UpdateVertices(); Register;
      Function GetColorValues(): pglColorF; Register;
      Function GetRectSet(S: Integer): pglRectI; Register;
      Function GetCenter(): pglVector2; Register;
      Function GetTopLeft(): pglVector2; Register;

    Public

      Constructor Create(); Overload; Register;
      Constructor CreateFromTexture(Var Texture: pglTexture); Overload; Register;
      Procedure Delete(); Register;
      Procedure SetDefaults(); Register;
      Procedure SetTexture(Sprite: pglSprite); Overload; Register;
      Procedure SetTexture(Var Texture: pglTexture); Overload; Register;
      Procedure SetCenter(Center: pglVector2); Register;
      Procedure SetTopLeft(TopLeft: pglVector2); Register;
      Procedure Move(X,Y: Single); Register;
      Procedure Rotate(Val: GLFloat); Register;
      Procedure SetAngle(Val: GLFloat); Register;
      Procedure SetOrigin(Center: pglVector2); Register;
      Procedure SetFlipped(isFlipped: Boolean); Register;
      Procedure SetMirrored(isMirrored: Boolean); Register;
      Procedure SetSkew(Dimension: GLInt; Amount: GLFloat); Register;
      Procedure ResetSkew(); Register;
      Procedure SetStretch(Dimension: GLInt; Amount: GLFloat); Register;
      Procedure ResetStretch(); Register;
      Procedure SetMaskColor(Color: pglColorF); Overload; Register;
      Procedure SetMaskColor(Color: pglColorI); Overload; Register;
      Procedure SetOpacity(Val: GLFloat); Register;
      Procedure SetColors(Colors: pglColorI); Overload; Register;
      Procedure SetColors(Colors: pointer); Overload; Register;
      Procedure SetOverlay(Colors: pglColorI); Register;
      Procedure SetGreyScale(Val: Boolean = true); Register;
      Procedure ResetColorState(); Register;
      Procedure SetSize(Width,Height: Single); Register;
      Procedure ResetScale(); Register;
      Procedure SetTextureRect(TexRect: pglRectI); Register;
      Procedure SetRectSlot(Slot: GLInt; Rect: pglRectI); Register;
      Procedure UseRectSlot(Slot: GLInt); Register;

      Procedure SaveToFile(FileName: String); Register;

      Property Texture: pglTexture read pTexture;
      Property ColorValues: pglColorF read GetColorValues;
      Property ColorOverlay: pglColorF read pColorOverlay;
      Property TextureSize: pglVector2 Read pTextureSize;
      Property TextureRect: pglRectI Read pTextureRect;
      Property Bounds: pglRectF read pBounds;
      Property X: GLFloat Read pBounds.X;
      Property Y: GLFloat Read pBounds.Y;
      Property Left: GLFloat Read pBounds.Left;
      Property Right: GLFloat read pBounds.Right;
      Property Top: GLFloat read pBounds.Top;
      Property Bottom: GLFloat read pBounds.Bottom;
      Property Width: GLFloat Read pBounds.Width;
      Property Height: GLFloat read pBounds.Height;
      Property Center: pglVector2 read GetCenter;
      Property TopLeft: pglVector2 read GetTopLeft;
      Property Angle: GLFloat read pAngle;
      Property Origin: pglVector2 read pOrigin;
      Property Flipped: GLBoolean read pFlipped;
      Property Mirrored: GLBoolean read pMirrored;
      Property Opacity: GLFloat read pOpacity;
      Property GreyScale: Boolean read pGreyScale;
      Property MonoCrome: Boolean read pMonoChrome;
      Property MaskColor: pglColorF read pMaskColor;
      Property RectSet[Index: Integer]: pglRectI read GetRectSet;

      Function Pixel(X,Y: Integer): pglColorI; Register;

  End;


  Type pglPointCollection = Record

    Private
      pCount: GLUInt;
      pWidth: GLUInt;
      pHeight: GLUInt;
      Data: Array of pglColorI;

    Public
      Procedure BuildFrom(Texture: pglTexture; X: GLUInt = 0; Y: GLUInt = 0; Width: GLUInt = 0; Height: GLUInt = 0); Overload; Register;
      Procedure BuildFrom(Image: pglImage; X: GLUInt = 0; Y: GLUInt = 0; Width: GLUInt = 0; Height: GLUInt = 0); Overload; Register;
      Procedure BuildFrom(Sprite: pglSprite; X: GLUInt = 0; Y: GLUInt = 0; Width: GLUInt = 0; Height: GLUInt = 0); Overload; Register;
      Procedure BuildFrom(Data: Pointer; Width,Height: GLUInt); Overload; Register;
      Procedure ReplaceColor(OldColor,NewColor: pglColorI); Register;

      Function Point(X,Y: GLUInt): pglColorI; Overload; Register;
      Function Point(N: GLUInt): pglColorI; Overload; Register;


      Property Width: GLUInt read pWidth;
      Property Height: GLUInt Read pHeight;
      Property Count: GLUInt Read pCount;

  End;


  Type pglGlyphMetrics = Record

    Private
      Width, Height: GLInt;
      SDFWidth, SDFHeight: GLInt;
      Bearing: GLInt;
      Advance: GLFloat;
      TailHeight: GLInt;
  End;


  Type pglCharacter = Record
    Private
      Position: pglVector2;
      SDFPosition: pglVector2;
      Size: pglVector2;
      Texture: GLUInt;
      OutlineTexture: GLUInt;
      Symbol: String;
      GlyphIndex: GLUInt;
      AsciiCode: GLUInt;
      Metrics: pglGlyphMetrics;

    Private
      OutlinePoints: TArray<TFTVector>;
      Procedure GetOutlinePoints(); Register;

    Public
      Property Width: GLInt Read Metrics.Width;
      Property Height: GLInt Read Metrics.Height;
      Property Bearing: GLInt Read Metrics.Bearing;
      Property Advance: GLFloat Read Metrics.Advance;
      Property TailHeight: GlInt Read Metrics.TailHeight;

  End;


  Type pglAtlas = Record

    Private
      Texture: GLUInt;
      Width, Height: GLUInt;
      OriginY: GLUint;
      TailMax: GLUint;
      TotalHeight: GLInt;
      FontSize: GLInt;
      Character: Array [0..128] of pglCharacter;
  End;

  Type pglFont = Class(TObject)
    Public
      FontName: String;
      FontSize: GLInt;

    Private
      Atlas: Array of pglAtlas;

      Procedure BuildAtlas(A: GLInt); Register;
      Function ChooseAtlas(CharSize: GLUInt): Integer; Register;

    Public
      Constructor Create(FileName: String; Sizes: Array of Integer; Bold: Boolean = False); Register;
  End;


  Type pglText = Class(TObject)
    Private
      UseFont: pglFont;
      UseText: String;
      UseWrapText: String;
      UseLineCount: GLInt;
      UseLineStart: Array of GLInt;
      UseColor: pglColorF;
      UseHasGradient: Boolean;
      UseGradientColorLeft: pglColorF;
      UseGradientColorRight: pglColorF;
      UseGradientOffset: GLFloat;
      UseBorderColor: pglColorf;
      UseBorderSize: GLInt;
      UseCharSize: GLInt;
      UseMultiLine: Boolean;
      UseMultiLineBounds: pglRectF;
      UseShadow: Boolean;
      UseSmooth: Boolean;
      UseTextBounds: pglRectF;
      UseBounds: pglRectF;
      UseAngle: GLFloat;

      CurrentAtlas: GLUint; // Assigned during FindBounds

      DrawPos: pglVector2; // The position that will be passesd to DrawTestString, either the topleft of the bounds or if centered the center - half width and half height

    Private
      Procedure FindBounds(); Register;

      Function FindPosition(): pglVector2; Register;
      Function FindTopLeft(): pglVector2; Register;
      Function FindWidth(): integer; Register;
      Function FindHeight(): integer; Register;

    Public
      Constructor Create(Font: pglFont; Chars: string); Register;
      Procedure SetText(Chars: String); Register;
      Procedure SetColor(Color: pglColorI); Register;
      Procedure SetBorderColor(Color: pglColorI); Register;
      Procedure SetBorderSize(Size: GLInt); Register;
      Procedure SetCharSize(Size: GLInt); Register;
      Procedure SetCenter(Center: pglVector2); Register;
      Procedure SetTopLeft(TopLeft: pglVector2); Register;
      Procedure SetLeft(Left: GLFloat); Register;
      Procedure SetTop(Top: GLFloat); Register;
      Procedure SetRight(Right: GLFloat); Register;
      Procedure SetBottom(Bottom: GLFloat); Register;
      Procedure SetX(X: GLFloat); Register;
      Procedure SetY(Y: GLFloat); Register;
      Procedure SetMultiLine(Value: Boolean = True); Register;
      Procedure SetMultiLineBounds(Bounds: pglRectF); Register;
      Procedure SetWidth(Value: GLUInt); Register;
      Procedure SetShadow(Shadow: Boolean = True); Register;
      Procedure Rotate(Angle: GLFloat); Register;
      Procedure SetRotation(Angle: GLFloat); Register;
      Procedure SetSmooth(Smooth: Boolean = True); Register;
      Procedure SetGradientColors(LeftColor, RightColor: pglColorF); Register;
      Procedure SetUseGradientColors(UseGradient: Boolean = true); Register;
      Procedure SetGradientXOffSet(XOffSet: GLFLoat); Register;

      Procedure WrapText(WrapWidth: GLFloat); Register;

      Property Text: String read UseText write SetText;
      Property Color: pglColorF Read UseColor;
      Property GradientColorSet: Boolean read UseHasGradient;
      Property GradientColorLeft: pglColorF read UseGradientColorLeft;
      Property GradientColorRight: pglColorF read UseGradientColorRight;
      Property GradientXOffSet: GLFloat read UseGradientOffset;
      Property BorderColor: pglColorF Read UseBorderColor;
      Property BorderSize: GLInt read UseBorderSize;
      Property CharSize: GLInt read UseCharSize;
      Property Center: pglVector2 Read FindPosition;
      Property Bounds: pglRectF Read UseBounds;
      Property TopLeft: pglVector2 Read FindTopLeft;
      Property Width: Integer Read FindWidth;
      Property Height: Integer Read FindHeight;
      Property MultiLine: Boolean Read UseMultiline;
      Property MultiLineBounds: pglRectF Read UseMultiLineBounds;
      Property Smooth: Boolean read UseSmooth;
      Property Angle: GLFloat Read UseAngle;

  End;

  Type pglTextTag = Record
    Bold: Boolean;
    Italic: Boolean;
    Color: pglColorF;
    CharStart: GLInt;
    CharEnd: GLInt;
  End;

  Type pglTextTagArray = Array of pglTextTag;


  Type pglTextFormat = Record

    Position: pglVector2; // Top-Left
    Width,Height: GLInt; // Clipping edges. -1 means do not apply clipping
    CharSize: GLInt; // -1 means use the size of the smallest atlas
    Font: pglFont;
    AtlasIndex: GLInt; // Index of Font Atlas to use, -1 if none. Drawing Function chooses if none
    Color: pglColorF;
    BorderColor: pglColorF;
    BorderSize: GLUint; // 0 = no border
    Shadow: Boolean; // Apply a shadow or not
    ShadowOffSet: pglVector2; // X and Y offset of shadow from text
    ShadowColor: pglColorF;
    Smooth: Boolean; // Do a smoothing pass or not
    Rotation: GLFloat; // Angle in Radians
    UseGradient: Boolean;
    GradientLeft: pglColorF;
    GradientRight: pglColorF;
    GradientXOffSet: GLFloat;

    Procedure Reset(); Register;
    Procedure SetFormat(iPosition: pglVector2;
                        iWidth: GLInt;
                        iHeight: GLInt;
                        iFont: pglFont;
                        iAtlasIndex: GLInt;
                        iColor: pglColorF;
                        iBorderColor: pglColorF;
                        iBorderSize: GLUint;
                        iShadow: Boolean;
                        iShadowOffset: pglVector2;
                        iShadowColor: pglColorF;
                        iSmooth: Boolean;
                        iRotation: GLFloat;
                        iUseGradient: Boolean;
                        iGradientLeft: pglColorF;
                        iGradientRight: pglColorF;
                        iGradientXOffSet: GLFloat); Register;
  End;


	Type pglRenderTarget = Class(TPersistent)

    Private
      ResizeFunc: pglFrameResizeFunc;

      pWidth,pHeight: GLUint;
      pDrawOffSet: pglVector2;
      pTextSmoothing: Boolean; // Text Smoothing Enabled
      pTextParams: pglTextFormat;
      pDrawShadows: Boolean;
      pShadowType: GLFloat;

  	Public

      FrameBuffer: GLUInt;
      Texture: GLUInt;
      Texture2D: GLUInt;
      LightMap: GLUInt;
      DepthBuffer: GLUint;

      RenderRect: pglRectF;
      ClipRect: pglRectF;
      ColorVals: pglColorF;
      ColorOverLay: pglColorF;
      GreyScale: Boolean;
      MonoChrome: Boolean;
      Negative: Boolean;
      Swizzle: Boolean;
      SwizzleVals: pglVector3;
      pPixelSize: GLFloat;
      pBrightness: GLFloat;
      pClearColor: pglColorF;
      pClearColorBuffers: Boolean;
      pClearDepthBuffer: Boolean;
      pGlobalLight: glFloat;

      Buffers: pglBufferCollection;
      Ver: pglVectorQuad;
      Cor: pglVectorQuad;
      Indices: Array [0..5] of GLUInt;
      Rotation: pglMatrix4;
      Scale: pglMatrix4;
      Translation: pglMatrix4;


      Points: pglPointBatch;
      Circles: pglCircleBatch;
      Polys: pglPolygonBatch;
      Rectangles: pglRectangleBatch;
      Lights: pglLightBatch;
      LightPolygons: pglLightPolygonBatch;
      TextureBatch: pglTextureBatch;
      LineBatch: pglShapeBatch;
      GeoMetryBatch: pglGeometryBatch;

      DrawState: AnsiString;

      ClearRect: pglRectF;

    Private

      Procedure FillEBO(); Register;
      Procedure DrawTextString(Text: String; Font: pglFont; Size: GLInt; Bounds: pglRectF;
        BorderSize: GLUInt; Color,BorderColor: pglColorI; UseGradient: Boolean; GradientLeft: pglColorF;
        GradientRight: pglColorF; GradientXOffSet: glFloat; Angle: GLFloat = 0; Shadow: Boolean = False); Register;

      Procedure DrawTextCharacters(CharQuads,TexQuads: Array of pglVectorQuad; TextWidth,TextHeight: GLUInt); Register;


    Public

      constructor Create(inWidth,inHeight: GLInt);
      Procedure UpdateVertices(); Register;
      Procedure UpdateCorners(); Register;
      Procedure Display(); Register;
      Procedure Clear(); Overload;
      Procedure Clear(Color: pglColorI); Overload;
      Procedure Clear(Color: pglColorF); Overload;
      Procedure SetClearColorBuffers(Enable: Boolean); Register;
      Procedure SetClearDepthBuffer(Enable: Boolean); Register;
      Procedure SetClearAllBuffers(Enable: Boolean); Register;
      Procedure SetColorValues(inVals: pglColorI); Overload;
      Procedure SetColorValues(inVals: pglColorF); Overload;
      Procedure SetColorOverlay(inVals: pglColorI); Overload;
      Procedure SetColorOverlay(inVals: pglColorF); Overload;
      Procedure SetRenderRect(inRect: pglRectI); Overload; Register;
      Procedure SetRenderRect(inRect: pglRectF); Overload; Register;
      Procedure SetClipRect(inRect: pglRectI); Overload; Register;
      Procedure SetClipRect(inRect: pglRectF); Overload; Register;
      Procedure SetOnResizeEvent(Event: pglFrameResizeFunc); Register;
      Procedure SetClearRect(ClearRect: pglRectF); Register;
      Procedure AttachShadowMap(); Register;

      // Drawing
      Procedure DrawLastBatch(); Register;
      Procedure DrawCircleBatch(); Register;
      Procedure DrawGeometryBatch(); Register;
      Procedure DrawPointBatch(); Register;
      Procedure DrawLineBatch(); Register;
      Procedure DrawLineBatch2(); Register;
      Procedure DrawPolygonBatch(); Register;
      Procedure DrawRectangleBatch(); Register;
      Procedure DrawLightBatch(); Register;
      Procedure DrawSpriteBatch(); Register;

      Procedure DrawCircle(CenterX, CenterY, inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: pglColorI); Overload; Register;
      Procedure DrawCircle(CenterX, CenterY, inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: pglColorF); Overload; Register;
      Procedure DrawCircle(Center: pglVector2; inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: pglColorI); Overload; Register;
      Procedure DrawCircle(Center: pglVector2; inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: pglColorF; FadeToOpacity: GLFloat = 1); Overload; Register;

      Procedure DrawEllipse(Center: pglVector2; XLength,YLength,Angle: GLFloat; Color: pglColorI); Register;

      Procedure DrawGeometry(Points: Array of pglVector2; Color: Array of pglColorF); Register;

      Procedure DrawRegularPolygon(NumVertices: GLInt; Center: pglVector2; Radius,Angle: GLFloat; Color: pglColorI); Register;

      Procedure DrawPoint(CenterX,CenterY,Size: GLFloat; inColor: pglColorI); Overload;
      Procedure DrawPoint(CenterX,CenterY,Size: GLFloat; inColor: pglColorF); Overload;
      Procedure DrawPoint(Center: pglVector2; Size: GLFloat; inColor: pglColorI); Overload;
      Procedure DrawPoint(Center: pglVector2; Size: GLFloat; inColor: pglColorF); Overload;
      Procedure DrawPoint(PointObject: pglPoint); Overload;

      Procedure DrawRectangle(Center: pglVector2; inWidth,inHeight,inBorderWidth: GLFloat; inFillColor,inBorderColor: pglColorI; inCurve: GLFloat = 0); Overload; Register;
      Procedure DrawRectangle(Center: pglVector2; inWidth,inHeight,inBorderWidth: GLFloat; inFillColor,inBorderColor: pglColorF; inCurve: GLFloat = 0); Overload; Register;
      Procedure DrawRectangle(Bounds: pglRectF; inBorderWidth: GLFloat; inFillColor,inBorderColor: pglColorI; inCurve: GLFloat = 0); Overload; Register;
      Procedure DrawRectangle(Bounds: pglRectF; inBorderWidth: GLFloat; inFillColor,inBorderColor: pglColorF; inCurve: GLFloat = 0); Overload; Register;

      Procedure DrawLine(P1,P2: pglVector2; Width,BorderWidth: GLFloat; FillColor, BorderColor: pglColorF); Register;
      Procedure DrawLine2(P1,P2: pglVector2; Width,BorderWidth: GLFloat; FillColor,BorderColor: pglColorF; SmoothEdges: Boolean = False); Register;
      Procedure DrawSprite(Var Sprite: pglSprite); Register;
      Procedure DrawLight(Center: pglVector2; Radius,Radiance: GLFloat; Color: pglColorI); Register;
      Procedure DrawLightCircle(Center: pglVector2; Color: pglColorI; Radiance,Radius: GLFloat); Register;
      Procedure DrawLightFan(Center: pglVector2; Color: pglColorI; Radiance: GLFloat; Radius,Angle,Spread: GLFloat); Register;
      Procedure DrawLightFanBatch(); Register;
      Procedure ApplyLights(); Register;

      Procedure DrawText(Text: pglText); Overload; Register;
      Procedure DrawText(Text: String; Font: pglFont; Size: GLInt; Position: pglVector2; BorderSize: GLUInt; Color,BorderColor: pglColorI; Shadow: Boolean = False); Overload; Register;


      // Effects
      Procedure Swirl(Target: pglRenderTarget; DestRect,SourceRect: pglRectF); Register;
      Procedure Pixelate(PixelRect: pglRectF; PixelSize: GLFloat = 2); Register;
      Procedure Smooth(Area: pglRectF; IgnoreColor: pglColorI); Register;
      Procedure DrawStatic(Area: pglRectF); Register;
      Procedure StereoScope(Area: pglRectF; OffSet: pglVector2); Register;
      Procedure FloodFill(StartCoord: pglVector2; Area: pglRectF); Register;

      Procedure MakeCurrentTarget(); Register;
      Procedure CopyToTexture(SrcX, SrcY, SrcWidth, SrcHeight: GLUint; DestTexture: GLUint); Register;
      Procedure CopyToImage(Dest: pglImage; SourceRect, DestRect: pglRectI); Register;
      Procedure UpdateFromImage(Source: pglImage; SourceRect: pglRectI); Register;

      Property Width: GLUint Read pWidth;
      Property Height: GLUint Read pHeight;
      Property DrawOffset: pglVector2 read pDrawOffset;
      Property PixelSize: GLFloat read pPixelSize;
      Property Brightness: GLFloat read pBrightness;
      Property TextSmoothing: Boolean read pTextSmoothing;
      Property ClearColor: pglColorF read pClearColor;
      Property DrawShadows: Boolean read pDrawShadows;
      Property GlobalLight: GLFloat read pGlobalLight;

      Procedure SetDrawOffSet(OffSet: pglVector2); Register;
      Procedure SetPixelSize(Size: GLFloat); Register;
      Procedure SetBrightness(Level: GLFloat); Register;
      Procedure SetNegative(Enable: Boolean = True); Register;
      Procedure SetSwizzle(Enable: Boolean = True; R: Integer = 0; G: Integer = 1; B: Integer = 2); Register;
      Procedure SetTextSmoothing(Smoothing: Boolean = True); Register;
      Procedure SetClearColor(Color: pglColorI); Overload; Register;
      Procedure SetClearColor(Color: pglColorF); Overload; Register;
      Procedure SetDrawShadows(Draw: Boolean; ShadowType: GLFloat = 0); Register;
      Procedure SetGlobalLight(Value: GLFloat); Register;
  End;




  Type pglRenderTexture = Class(pglRenderTarget)

    Private
      Angle: GLFloat;
      Opacity: GLFloat;
      TextureMS: GLUInt;
      BackTexture: GLUint;
      pisMultiSampled: Boolean;
      pBitDepth: GLInt;
      pPixelFormat: GLInt;


      Procedure SetDrawBuffers(Buffers: Array of GLEnum); Register;
      Procedure SetPixelFormat(); Register;

    Public
      Constructor Create(inWidth,inHeight: GLInt; BitCount: GLInt = 32);
      Procedure Rotate(byAngle: GLFloat); Register;
      Procedure SetRotation(toAngle: GLFloat); Register;
      Procedure SetPixelSize(P: Integer); Register;
      Procedure SetOpacity(Val: GLFloat); Register;
      Procedure SetSize(W,H: GLUInt); Register;
      Procedure SetNearestFilter(); Register;
      Procedure SetLinearFilter(); Register;

      // blting

      Procedure Blt(Dest: pglRenderTarget; destX, destY, destWidth, destHeight, srcX, srcY: GLFloat); Overload; Register;
      Procedure Blt(Dest: pglRenderTarget; DestRect, SourceRect: pglRectI); Overload; Register;

      Procedure StretchBlt(Dest: pglRenderTarget; destX, destY, destWidth, destHeight, srcX,srcY,srcWidth,srcHeight: GLFloat); Overload; Register;
      Procedure StretchBlt(Dest: pglRenderTarget; destRect,srcRect: pglRectI); Overload; Register;
      Procedure StretchBlt(Dest: pglRenderTarget; destRect,srcRect: pglRectF); Overload; Register;

      Procedure BlendBlt(Dest: pglRenderTarget; destX, destY, destWidth, destHeight, srcX,srcY,srcWidth,srcHeight: GLFloat); Overload; Register;
      Procedure BlendBlt(Dest: pglRenderTarget; DestRect,SourceRect: pglRectF); Overload; Register;

      Procedure CopyBlt(Dest: pglRenderTarget; destX, destY, destWidth, destHeight, srcX,srcY,srcWidth,srcHeight: GLFloat); Overload; Register;
      Procedure CopyBlt(Dest: pglRenderTarget; DestRect,SourceRect: pglRectF); Overload; Register;

      Procedure ChangeTexture(Texture: pglTexture); Register;
      Procedure RestoreTexture(); Register;


      // Effects

      Procedure SaveToFile(FileName: String; Channels: Integer = 4); Register;
      Procedure SetMultiSampled(MultiSampled: Boolean); Register;

      Property isMultiSampled: Boolean read pisMultiSampled;
      Property BitDepth: GLInt read pBitDepth;
  End;


  Type pglRenderMap = Class(pglRenderTarget)

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
      pSelectionRect: pglRectI; // Bounds of the rectangle selected from data
      pOffSet: pglVector2; // X and Y of the top left corner of the selected data
      pViewPort: pglRectI; // Bounds of the area of the SelectionRect that is to be drawn to the buffer

    Public

      Constructor Create(Width,Height,SelectionWidth,SelectionHeight,ViewPortWidth,ViewPortHeight: GLUInt); Register;

      Property TotalWidth: GLUInt read pTotalWidth;
      Property TotalHeight: GLUInt read pTotalHeight;
      Property SelectionRect: pglRectI read pSelectionRect;
      Property SelectionOffSet: pglVector2 read pOffSet;
      Property ViewPort: pglRectI read pViewPort;

      Procedure SetSelectionRectSize(Width,Height: GLUInt); Register;
      Procedure MoveSelectionRect(ByX,ByY: GLUInt); Register;
      Procedure SetSelectionRect(Left,Top: GLUInt); Register;
      Procedure UpdateImageSelection(); Register;

      Procedure SetViewPortSize(Width,Height: GLUInt); Register;
      Procedure MoveViewPort(ByX,ByY: GLUInt); Register;
      Procedure SetViewPort(Left,Top: GLUInt); Register;

      Function RetrievePixelsFromMemory(SRect: pglRectI): ColorIArray; Register;

    Private

      Procedure WriteSelectionToImage(); Register;
      Procedure GetSelectionFromImage(X,Y: GLUInt); Register;
  End;



  Type pglWindow = Class(pglRenderTarget)

    // Fields

    Private
      TempBuffer: GLUInt;
      pOrgWidth,pOrgHeight: GLUInt;
      pFullScreen: Boolean;
      pTitleBar: Boolean;
      pTitle: String;
      pDisplayRect: pglRectF;

      pDisplayRectUsing: Boolean;
      pDisplayRectOrigin: pglVector2;
      pDisplayRectScale: Boolean;
      pDisplayRectOrgWidth: GLInt;
      pDisplayRectOrgHeight: GLInt;

    Public
      Handle: HWND;
      osHandle: LongInt;

    // Methods

    Private
      Constructor Create(inWidth,inHeight: GLInt); Register;
      Procedure onResize(); Register;

    Public

//      Property Width: GLUInt read pWidth;
//      Property Height: GLUInt read pHeight;
      Property OrgWidth: GLUInt read pOrgWidth;
      Property OrgHeight: GLUInt read pOrgHeight;
      Property FullScreen: Boolean read pFullScreen;
      Property TitleBar: Boolean read pTitleBar;
      Property Title: String read pTitle;
      Property DisplayRect: pglRectF read pDisplayRect;

      Procedure Close(); Register;
      Procedure DisplayFrame(); Register;

      Procedure SetSize(W,H: GLUInt); Register;
      Procedure SetFullScreen(isFullScreen: Boolean); Register;
      Procedure SetTitleBar(hasTitleBar: Boolean); Register;
      Procedure SetTitle(inTitle: String); Register;
      Procedure SetScreenPosition(X,Y: GLInt); Register;
      Procedure CenterInScreen(); Register;
      Procedure Maximize(); Register;
      Procedure Minimize(); Register;
      Procedure Restore(); Register;
      Procedure SetDisplayRect(Rect: pglRectI; ScaleOnResize: Boolean); Register;
      Procedure SetIcon(Image: pglImage); Overload; Register;
      Procedure SetIcon(FileName: String; TransparentColor: pglColorI); Overload; Register;
  End;


  Type pglUniform = Record
    Name: String;
    Location: GLInt;
  End;

  Type pglProgram = Class

    Public

      ProgramName: String;

      Valid: Boolean;
      ShaderProgram: GLInt;
      VertexShader: GLInt;
      FragmentShader: GLInt;
      GeometryShader: GLInt;

    Private
      UniformCount: GLInt;
      Uniform: Array of pglUniform;

      Function SearchUniform(uName: String): GLInt; Register;
      Procedure AddUniform(uName: string; Location: GLInt); Register;

    Public

      constructor Create(Name: String; VertexShaderPath, FragmentShaderPath: String; GeometryShaderPath: String = '');
      Procedure Use(); Register;

  End;

  Type pglMonitor = Record
    X,Y,Width,Height: GLInt;
  End;



  Type PGLState = Record

    Private
      pMaxTextureSize: GLInt;

      InitWidth, InitHeight: GLInt;
      GlobalLight: GLFloat;
      DefaultMaskColor: pglColorF;

      DefaultReplace: Array of Array [0..1] of pglColorI;

      // States
      MajorVer,MinorVer: GLUInt;
      CurrentRenderTarget: GLUInt;
      CurrentBufferCollection: ^pglBufferCollection;
      ViewPort: pglRectI;
      TextureType: glEnum;
      TextureFormat: GLInt;
      WindowColorFormat: GLInt;
      TexUnit: Array [0..31] of GLUInt;
      EllipsePointInterval: GLInt;

      // Created Objects
      RenderTextures: Array of pglRenderTexture;
      Textures: array of GLUInt;
      TextureObjects: Array of pglTexture;
      Images: Array of pglImage;
      Lights: Array of pglLightSource;
      Sprites: Array of pglSprite;

      ShadowMap: GLUint;
      ShadowTarget: pglRenderTarget;

    Public
      Context: pglContext;
      Window: pglWindow;
      Handle: HWND;
      OSHandle: pointer;
      Screen: pglMonitor;
      VideoMode: DEVMODE;

    Private

      Procedure AddRenderTexture(Source: pglRenderTexture); Register;
      Procedure AddTextureObject(Var TexObject: pglTexture); Register;
      Procedure RemoveTextureObject(Var TexObject: pglTexture); Register;
      Procedure UpdateViewPort(X,Y,W,H: GLInt); Register;
      Procedure GenTexture(Var Texture: GLUInt); Register;
      Procedure DeleteTexture(Var Texture: GLUInt); Register;
      Procedure BindTexture(TextureUnit: GLUInt; Texture: GLUInt); Register;
      Procedure UnBindAll(); Register;
      Procedure UnBindTexture(TexName: GLUint); Register;

      Procedure VBOSubData(Binding: glEnum; OffSet: GLInt; Size: GLInt; Source: Pointer); Register;
      Procedure SSBOSubData(Binding: glEnum; OffSet: GLInt; Size: GLInt; Source: Pointer); Register;
      Function GetNextVBO(): GLInt; Register;
      Function GetNextSSBO(): GLInt; Register;


    Public

      Class Operator Initialize(Out Dest: PGLState); Register;
      Procedure UpdateWindowBounds(); Register;
      Procedure SetDefaultMaskColor(Color: pglColori); Register;
      Procedure AddDefaultColorReplace(Color,NewColor: pglColorI); Register;
      Procedure DestroyImage(Var Image: pglImage); Register;
      Procedure GetInputDevices(var KeyBoard: pglKeyBoard; var Mouse: pglMouse; var Controller: pglController); Register;

      Function GetTextureCount(): NativeUInt; Register;

      Property GetViewPort: pglRectI read ViewPort;
      Property MaxTextureSize: GLInt read pMaxTextureSize;
  End;


  //////////////////////////////////////////////////////////////////////////////
  ////////////////////////// Helper Types //////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  Type
    pglTextureHelper = Class Helper for pglTexture
    Procedure CopyFrom(Image: pglImage; X,Y,Width,Height: GLInt); Overload; Register;
    Procedure CopyFrom(Texture: pglTexture; X,Y,Width,Height: GLInt); Overload; Register;
    Procedure CopyFrom(Sprite: pglSprite; X,Y,Width,Height: GLInt); Overload; Register;
  End;

  Type
    pglImageHelper = Class Helper for pglImage
    Constructor CreateFromTexture(Var Source: pglTexture); Register;
    Procedure CopyFromTexture(Var Source: pglTexture); Register;
  End;

  Type pglColorIHelper = Record Helper for pglColorI
    Function IsColor(CompareColor: pglColorF; Tolerance: Double = 0): Boolean; OverLoad; Register;
    Function IsColor(CompareColor: pglColorI; Tolerance: Double = 0): Boolean; OverLoad; Register;
  End;

  Type pglColorFHelper = Record Helper for pglColorF
    Function IsColor(CompareColor: pglColorI; Tolerance: Double = 0): Boolean; OverLoad; Register;
    Function IsColor(CompareColor: pglColorF; Tolerance: Double = 0): Boolean; OverLoad; Register;
  End;

  pglRectFHelper = Record helper for pglRectF
      Function toRectI(): pglRectI;
      Function toPoints(): pglVectorQuad;
      Function CheckInside(Pos: pglVector2): Boolean; Register;
    End;

    pglRectIHelper = Record helper for pglRectI
      Function toRectF(): pglRectF;
      Function toPoints(): pglVectorQuad;
      Function CheckInside(Pos: pglVector2): Boolean; Register;
    End;


	// Init, config and callback
  Procedure PGLInit(Var Window: pglWindow; Width,Height: GLInt; Title: String; WindowAttributes: pglWindowFlags); Register;
  Procedure PGLSetColorFormats(WindowAttributes: pglWindowFlags); Register;
  Procedure PGLGetWindowColorFormat(); Register;
  Procedure pglExitGL(); Register;
  Procedure PGLAddError(Msg: String); Register;
  Procedure PGLReportErrors(); Register;
  Procedure PGLERRORDEBUG(ErrorStatus: glEnum); Register;


  Procedure pglWindowUpdate(); CDecl;
  Procedure PGLSetShaders(); Register;
  Procedure PGLLoadShadersFromDirectories(); Register;
  Function PGLLoadShader(inShader: GLInt; Path: String): Boolean; Register;
  Procedure pglSetWindowTitle(Title: String); Register;
  Procedure pglSetScales(); Register;
  Procedure PGLSetDefaultColors(); Register;


  // type Functions
 	Function RectI(L,T,R,B: GLFloat): pglRectI; Overload; Register;
  Function RectI(Center: pglVector2; W,H: GLFloat): pglRectI; Overload; Register;
  Function RectIWH(L,T,W,H: GLFloat): pglRectI; Register;
  Function RectF(L,T,R,B: GLFloat): pglRectF; Overload; Register;
  Function RectF(Center: pglVector2; W,H: GLFloat): pglRectF; Overload; Register;
  Function RectFWH(L,T,W,H: GLFloat): pglRectF; Overload; Register;
  Function PointsToRectF(Var Points: Array of pglVector2): pglRectF; Register;
  Function CheckPointInBounds(Point: pglVector2; Bounds: pglRectF): Boolean; Register;

  Function Vec2(inX,InY: GLFloat): pglVector2; Register; Overload;
  Function Vec2(PointF: TPointFloat): pglVector2; Register; Overload;
  Function Vec2(Vector3: pglVector3): pglVector2; Register; Overload;
  Function Vec3(inX,inY,inZ: GLFloat): pglVector3; Register;
  Function Vec4(inX,inY,inZ,inW: GLFloat): pglVector4; Register;
  Function SXVec2(inX,inY: GLFloat): pglVector2; Register;

  Function PGLAngleToRad(Angle: GLFloat): GLFloat; Register;
  Function PGLRadToAngle(Rad: GLFloat): GLFloat; Register;
  Function BoolToInt(Bool: Boolean): GLUint; Register;

  Procedure FlipPoints(Var Points: pglVectorQuad); Register;
  Procedure MirrorPoints(Var Points: pglVectorQuad); Register;
  Procedure RotatePoints(Var Points: Array of pglVector2; Center: pglVector2; Angle: GLFloat); Register;
  Procedure TruncPoints(Var Points: Array of pglVector2); Register;
  Function ReturnRectPoints(P1,P2: pglVector2; Width: GLFloat): pglVectorQuad; Register;

  Function ClampFColor(inVal: GLFloat): GLFloat; Register;
  Function ClampIColor(inVal: GLInt): GLInt; Register;
  Function RoundInt(Value: GLFloat): GLInt; Register;

  Function Color3i(inRed,inGreen,inBlue: GLInt): pglColorI; Register;
  Function Color4i(inRed,inGreen,inBlue,inAlpha: GLInt): pglColorI; Register;
  Function Color3f(inRed,inGreen,inBlue: GLFloat): pglColorF; Register;
  Function Color4f(inRed,inGreen,inBlue,inAlpha: GLFloat): pglColorF; Register;
  Function ColorItoF(inColor: pglColorI): pglColorF; Register;
  Function ColorFtoI(inColor: pglColorF): pglColorI; Register;
  Function GetColorChangeIncrements(StartColor, EndColor: pglColorI; Cycles: Integer): pglColorI; Overload; Register;
  Function GetColorChangeIncrements(StartColor, EndColor: pglColorF; Cycles: Integer): pglColorF; Overload; Register;
  Function CC(Color: pglColorI): pglColorF; OverLoad; Register;
  Function CC(Color: pglColorF): pglColorI; OverLoad; Register;
  Function ColorCombine(Color1,Color2: pglColorI): pglColorI; Overload; Register;
  Function ColorCombine(Color1,Color2: pglColorF): pglColorF; Overload; Register;
  Function ColorMultiply(Color1,Color2: pglColorI): pglColorI; Overload; Register;
  Function ColorMultiply(Color1,Color2: pglColorF): pglColorF; Overload; Register;
  Procedure ColorAdd(Out Color: pglColorI; AddColor: pglColorI; AddAlphas: Boolean = True); Overload; Register;
  Procedure ColorAdd(Out Color: pglColorF; AddColor: pglColorF; AddAlphas: Boolean = True); Overload; Register;
  Function ColorMix(Color1,Color2: pglColorI; Factor: GLFloat): pglColorI; Register;

  Function PGLStringToChar(InString: String): pglCharArray; Register;
  Procedure PGLSaveTexture(Texture: GLUInt; Width,Height: GLUInt; FileName: String; MipLevel: GLUInt = 0); Register;
  Procedure PGLReplaceTextureColors(Textures: Array of pglTexture; Colors: Array of pglColorI; NewColor: pglColorI); Register;
  Procedure PGLReplaceAllTexturesColors(Colors: Array of pglColorI; NewColor: pglColorI); Register;
  Procedure PGLSetEllipseInterval(Interval: GLInt = 10); Register;

  Function ImageDesc(Source: Pointer; Width,Height: GLUInt): pglImageDescriptor; Register;
  Function PGLPixelFromMemory(Source: Pointer; X,Y,Width,Height: GLInt): pglColorI; Register;


  Function FindTextLineBreak(Var Text:String): Integer; Register;
  Function FindTextTags(Var Text:String): pglTextTagArray; Register;


  Procedure ReSizeFuncPlaceHolder(); Register;

  // Math Functions
  Function PGLRound(inVal: GLFloat): GLInt; Register;
  Function PGLMatrixRotation(Out Mat: pglMatrix4;inAngle,X,Y: GLFloat): boolean; Register;
  Function PGLMatrixScale(Out Mat: pglMatrix4; W,H: GLFloat): boolean; Register;
  Function PGLMatrixTranslation(Out Mat: pglMatrix4; X,Y: GLFloat): Boolean; Register;
  Function PGLMat2Rotation(Angle: GLFloat): pglMatrix2; Register;
  Function PGLMat2Translation(X,Y: GLFloat): pglMatrix2; Register;
  Function PGLMat2Scale(sX,sY: GLFloat): pglMatrix2; Register;
  Function PGLMat2Multiply(Mat1,Mat2: pglMatrix2): pglMatrix2; Register;
  Function PGLMat3Multiply(Mat1,Mat2: pglMatrix3): pglMatrix3; Register;
  Function PGLVectorCross(VecA, VecB: pglVector3): pglVector3; Register;
  Function SX(inVal: GLFloat): GLFloat; Register;
  Function SY(inVal: GLFloat): GLFloat; Register;
  Function BX(inVal, BuffWidth: GLFloat): GLFloat; Register;
  Function BY(inVal, BuffHeight: GLFloat): GLFloat; Register;
  Function TX(inVal, TexWidth: GLFloat): GLFloat; Register;
  Function TY(inVal, TexHeight: GLFloat): GLFloat; Register;
  Procedure TransformToScreen(Out Points: pglVectorQuad); Register;
  Procedure TransformToBuffer(Out Points: pglVectorQuad; BuffWidth,BuffHeight: GLFloat); Register;
  Procedure TransformToTexture(Out Points: pglVectorQuad; TexWidth,TexHeight: GLFloat); Register;



  // Shader Functions
  Function PGLGetUniform(Uniform: String): GLInt; Register;
  Procedure PGLUseProgram(ShaderProgramName: String); Register;

Var

  // Context
  PGL: PGLState;
  pglErrorLog: Array of String;

  pglRunning: Boolean;
  pglEXEPath: String;
  pglShaderPath: String;
  pglScaleX,pglScaleY: GLFloat;

  // Window
  pglWindowTitle: String[30];
  pglTempBuffer: pglRenderTexture;
  pglCopyBuffer: pglRenderTexture;
  pglCopyBuffer2: pglRenderTexture;

  // Shaders
  CurrentProgram: pglProgram;
  ProgramList: Array of pglProgram;

  DefaultProgram: pglProgram;
  CircleProgram: pglProgram;
  PointProgram: pglProgram;
  FrameBufferProgram: pglProgram;
  RectangleProgram: pglProgram;
  TextureProgram: pglProgram;
  TextureSimpleProgram: pglProgram;
  TextureSDFProgram: pglProgram;
  TextureLayerProgram: pglProgram;
  LightProgram: pglProgram;
  LightFanProgram: pglProgram;
  PixelateProgram: pglProgram;
  TextProgram: pglProgram;
  TextSDFProgram: pglProgram;
  TextBorderProgram: pglProgram;
  SmoothProgram: pglProgram;
  BlendBltProgram: pglProgram;
  CopyBltProgram: pglProgram;
  SpriteBatchProgram: pglProgram;
  SwirlProgram: pglProgram;
  LineProgram: pglProgram;
  PixelTransferProgram: pglProgram;
  StaticProgram: pglProgram;
  CubeProgram: pglProgram;
  SDFProgram: pglProgram;

  // Colors
  PGL_RED: pglColorI;
  PGL_GREEN: pglColorI;
  PGL_BLUE: pglColorI;
  PGL_YELLOW: pglColorI;
  PGL_MAGENTA: pglColorI;
  PGL_CYAN: pglColorI;
  PGL_WHITE: pglColorI;
  PGL_BLACK: pglColorI;
  PGL_GREY: pglColorI;
  PGL_LIGHTGREY: pglColorI;
  PGL_DARKGREY: pglColorI;
  PGL_ORANGE: pglColorI;
  PGL_BROWN: pglColorI;
  PGL_PINK: pglColorI;
  PGL_PURPLE: pglColorI;
  PGL_EMPTY: pglColorI;

  // Matrices Templates
  pglIdentityMatrix: pglMatrix4;
  pglScaleMatrix: pglMatrix4;

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


Procedure PGLERRORDEBUG(ErrorStatus: glEnum);

  Begin

    If ErrorStatus = GL_INVALID_ENUM Then Begin
      ErrorStatus := 0;
    End Else If ErrorStatus = GL_INVALID_VALUE Then Begin
      ErrorStatus := 0;
    End Else If ErrorStatus = GL_INVALID_OPERATION Then Begin
      ErrorStatus := 0;
    End Else If ErrorStatus = GL_STACK_OVERFLOW Then Begin
      ErrorStatus := 0;
    End Else If ErrorStatus = GL_STACK_UNDERFLOW Then Begin
      ErrorStatus := 0;
    End Else If ErrorStatus = GL_OUT_OF_MEMORY Then Begin
      ErrorStatus := 0;
    End;

  End;


Procedure PGLInit(Var Window: pglWindow; Width,Height: GLInt; Title: String; WindowAttributes: pglWindowFlags);

Var
I: Long;
WRect: TRect;
L,R,T,B: Integer;
CheckVar: GLInt;
ExtPointer: Array of pglUbyte;
ExtString: Array of String;
CharTitle: pglCharArray;
Samples: GLInt;
WinForm: pglWindowFormat;
WinFeats: pglFeatureSettings;

  Begin

    // First, get the monitor and screen data so that flags can be applied correctly

    WinForm.ColorBits := 32;
    WinForm.DepthBits := 0;
    WinForm.StencilBits := 0;
    WinForm.Samples := 0;
    WinForm.VSync := True;
    WinForm.BufferCopy := True;


    If pglFullScreen in WindowAttributes Then BEgin
      WinForm.FullScreen := True;
    End;

    If pglTitleBar in WindowAttributes Then Begin
      WinForm.TitleBar := True;
    End;

    If pglSizable in WindowAttributes Then Begin
      WinForm.Maximize := True;
    End;

    If pglDebug in WindowAttributes Then Begin
      WinFeats.OpenGLDebugContext := True;
    End;

    pglStart(Width,Height,WinForm,WinFeats,Title);
    PGL.Context := glDrawContext.Context;
    PGL.Context.SetDebugToConsole();
    PGL.Context.SetBreakOnDebug(True);

    PGL.Screen.Width := GetDeviceCaps(GetDC(0),HORZRES);
    PGL.Screen.Height :=  GetDeviceCaps(GetDC(0),VERTRES);

    PGLSetColorFormats(WindowAttributes);

    glEnable(GL_PROGRAM_POINT_SIZE);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
    glDisable(GL_STENCIL_TEST);
    glEnable(GL_TEXTURE_2D);

    PGLGetWindowColorFormat();

    Window := pglWindow.Create(Width,Height);
    PGL.Handle := PGL.Context.Handle;
    Window.Handle := PGL.Handle;
    Window.osHandle := PGL.Context.Handle;
    Window.pFullscreen := PGL.Context.FullScreen;

    glViewPort(0,0,Width,Height);
    pglSetScales();

    pglEXEPath := (ExtractFilePath(ParamStr(0)));
    pglShaderPath := (pglEXEPath + 'Shaders\');

    PGLSetShaders();

    PGLSetDefaultColors();

    PGL.CurrentRenderTarget := 0;
    PGL.TextureType := GL_TEXTURE_2D;

    // utility FBOs, not available to user
    pglTempBuffer := pglRenderTexture.Create(800,600);
    pglCopyBuffer := pglRenderTexture.Create(800,600);
    pglCopyBuffer2 := pglRenderTexture.Create(800,600);

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
  End;


Procedure PGLSetColorFormats(WindowAttributes: pglWindowFlags);
  Begin
    PGL.TextureFormat := GL_RGBA;
//    glEnable(GL_DITHER);
    Exit;
  End;

Procedure PGLGetWindowColorFormat();
  Begin
    PGL.WindowColorFormat := GL_RGBA;
  End;


Procedure pglExitGL();

  Begin
    PGL.Context.Close();
    pglRunning := False;
  End;


Procedure PGLAddError(Msg: String);
Var
Len: GLInt;
  Begin
    Len := Length(pglErrorLog) + 1;
    SetLength(pglErrorLog,Len);
    Len := High(pglErrorLog);
    pglErrorLog[Len] := Msg;
  End;


Procedure PGLReportErrors();
Var
ErrString: String;
I: GLInt;
  Begin

    If Length(pglErrorLog) = 0 Then Exit;

    ErrString := '';

    For I := 0 to High(pglErrorLog) Do Begin
      ErrString := ErrString + pglErrorLog[i] + sLineBreak;
    End;

    MessageBox(0,PWideChar(@ErrString),'Error Log',MB_OK or MB_ICONEXCLAMATION);
  end;


Procedure pglWindowUpdate(); CDecl;
Var
Col: pglColorF;
Buffs: GLInt;

	Begin

    PGL.Window.DrawLastBatch();
    If PGL.CurrentRenderTarget <> 0 Then Begin
      glBindFrameBuffer(GL_FRAMEBUFFER,0);
    End;

    SwapBuffers(PGL.Context.DC);

    Col := PGL.Window.ClearColor;

    PGL.Window.Clear();

    PGL.Context.PollEvents();

    if PGL.Context.ShouldClose Then Begin
      pglExitGL;
    end;
  End;


Procedure pglSetWindowTitle(Title: String);
Var
TString: pglCharArray;
  Begin
    PGL.Context.SetTitle(Title);
    PGL.Window.pTitle := Title;
  End;


Procedure pglSetScales();

Var
Center: pglVector2;
OldVer: Array [0..3] of pglVector2;
I: GLInt;
wScaleX,wScaleY: GLFloat;

  Begin
    glViewPort(0,0,PGL.initWidth,PGL.initHeight);

    pglScaleX := 1;
    pglScaleY := 1;


  End;


Procedure PGLSetDefaultColors();
  Begin
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
  End;


Procedure PGLSetShaders();

  Begin
    DefaultProgram := pglProgram.Create('Default','Vertex Default.vert', 'Fragment Default.frag');
    CircleProgram := pglProgram.Create('Circle', 'Vertex Circle.vert', 'Fragment Circle.frag');
    PointProgram := pglProgram.Create('Point', 'Vertex Point.vert', 'Fragment Point.frag');
    FrameBufferProgram := pglProgram.Create('FrameBuffer', 'Vertex FrameBuffer Default.vert', 'Fragment FrameBuffer Default.frag');
    RectangleProgram := pglProgram.Create('Rectangle','Vertex Rectangle.vert', 'Fragment Rectangle.frag');
    TextureProgram := pglProgram.Create('Texture', 'Vertex Texture Default.vert','Fragment Texture Default.frag');
    TextureSimpleProgram := pglProgram.Create('Texture Simple', 'Vertex Texture Simple.vert', 'Fragment Texture Simple.frag');
    LightProgram := pglProgram.Create('Light','Vertex Light Default.vert', 'Fragment Light Source.frag');
    LightFanProgram := pglProgram.Create('Light Fan', 'Vertex Light Default.vert', 'Fragment Light Polygon.frag');
    TextProgram := pglProgram.Create('Text','Vertex Text.vert','Fragment Text.frag');
    TextBorderProgram := pglProgram.Create('Test Border','Vertex Text.vert','Fragment Text Border.frag');
    BlendBltProgram := pglProgram.Create('Blend Blt', 'Vertex BlendBlt.vert', 'Fragment BlendBlt.frag');
    CopyBltProgram := pglProgram.Create('Copy Blt', 'Vertex CopyBlt.vert', 'Fragment CopyBlt.frag');
    SpriteBatchProgram := pglProgram.Create('Sprite Batch', 'Vertex Sprite Batch.vert', 'Fragment Sprite Batch.frag');
    SwirlProgram := pglProgram.Create('Swirl','Vertex Swirl.vert', 'Fragment Swirl.frag');
    SmoothProgram := pglProgram.Create('Smooth', 'Vertex Text.vert', 'Fragment Smooth.frag');
    PixelateProgram := pglProgram.Create('Pixelate', 'Vertex Pixelate.vert', 'Fragment Pixelate.frag');
    LineProgram := pglProgram.Create('Line', 'Vertex Line.vert', 'Fragment Line.frag');
    PixelTransferProgram := pglProgram.Create('Pixel Transfer', 'Vertex Pixel Transfer.vert', 'Fragment Pixel Transfer.frag');
    StaticProgram := pglProgram.Create('Static', 'Vertex Default.vert', 'Fragment Static.frag');
    CubeProgram := pglProgram.Create('Cube', 'Vertex Cube Default.vert', 'Fragment Cube Default.frag');
    SDFProgram := pglProgram.Create('SDF', 'Vertex Text.vert', 'Fragment SDF.frag');

    PGLLoadShadersFromDirectories();
  End;


Class Operator pglPointBatch.Initialize(Out Dest: pglPointBatch);
  Begin
    Dest.Data := GetMemory(182000);
  End;

Class Operator pglCircleBatch.Initialize(Out Dest: pglCircleBatch);
  BEgin
    Dest.Data := GetMemory(SizeOf(pglCircleDescriptor) * High(Dest.Vector));
  End;

Class Operator pglGeometryBatch.Initialize(Out Dest: pglGeometryBatch);
  Begin
    Dest.Data := GetMemory(182000);
    Dest.DataSize := 0;
    Dest.Color := GetMemory(6400);
    Dest.ColorSize := 0;
    Dest.Normals := GetMemory(182000);
    Dest.NormalsSize := 0;
    Dest.Next := 0;
  End;

Procedure PGLUseProgram(ShaderProgramName: String);

Var
I: GLInt;

  Begin

    if Length(ProgramList) = 0 Then Exit;

    For I := 0 to High(ProgramList) Do Begin

      If ProgramList[i].ProgramName = (ShaderProgramName) Then Begin
        ProgramList[i].Use();
        Exit;
      End;

    End;

    // throw error if program not found
    pglAddError('Could find and use program ' + ShaderProgramName + '!');

  End;


Procedure PGLLoadShadersFromDirectories();
Var
Dir: TDirectory;
Folders,Files: TStringDynArray;
I,R,P: GLInt;
DirName: String;
DirPath: String;
FileName: Array [0..1] of String;
TempString: String;

  Begin

    Dir.SetCurrentDirectory(String(pglEXEPath + 'Shaders\'));
    Folders := Dir.GetDirectories(Dir.GetCurrentDirectory);

    if Length(Folders) = 0 Then Exit;

    For I := 0 to High(Folders) Do Begin

      Dir.SetCurrentDirectory(Folders[i]);
      Files := Dir.GetFiles(Dir.GetCurrentDirectory);

      If Length(Files) <> 2 Then Continue;

        DirName := ExtractFileName(Folders[i]);
        DirPath := string(pglEXEPath) + 'Shaders\' + DirName + '\';
        FileName[0] := '';
        FileName[1] := '';

        For R := 0 to high(Files) Do Begin
          TempString := ExtractFileName(Files[r]);

          If POS('.vert',TempString) <> 0 Then Begin
            FileName[0] := TempString;
          End;

          If POS('.frag',TempString) <> 0 Then Begin
            FileName[1] := TempString;
          End;

        End;


        SetLength(ProgramList,Length(ProgramList) + 1);
        P := High(ProgramList);
        ProgramList[P] := pglProgram.Create((DirName),(DirPath + FileName[0]),(DirPath + FileName[1]));

        If ProgramList[p].Valid = False Then Begin
          pglAddError('Failed to load shader ' + DirName + ' from directory!');
          SetLength(ProgramList,Length(ProgramList) - 1);
        End;

    End;

  End;

Function PGLLoadShader(inShader: GLInt; Path: String): boolean;

Var
SourceString: String;
SourceChars: pglCharArray;
Chars: Array of Char;
I: GLInt;
Len: GLInt;
inString: String;
inFile: TextFile;
FileName: String;
CheckString: String;

  Begin

    // check for a path to the file name, if none, try shader default path
    if ExtractFilePath(Path) = '' Then Begin
      Path := string(pglShaderPath) + Path;
    End;

    // If the file doesn't exist, notify, fail and exit
    If FileExists(Path,True) = False Then Begin
      Filename := ExtractFileName(Path);
      PGLAddError('The file ' + FileName + ' could not be found!');
      Result := False;
      Exit;
    End;

    AssignFile(inFile, Path);
    Reset(inFile);

    SourceString := '';

    Repeat
      ReadLn(inFile,inString);
      SourceString := SourceString + (inString) + sLineBreak;
    until EOF(inFile);

    Len := Length(SourceString);
    SourceChars := PGLStringToChar((SourceString));

    glShaderSource(inShader,1,PPGLChar(@SourceChars),@Len);
    glCompileShader(inShader);

    glGetShaderiv(inShader, GL_COMPILE_STATUS, @Len);

    // if the shader doesn't compile, notify, fail and exit
    If Len = 0 Then Begin
      FileName := ExtractFileName(Path);
      PGLAddError('Failed to compile shader from ' + Filename + '!');
      Result := False;
      Exit;
    End;

    Result := True;
  End;


//////////////////////// Type Functions //////////////////////////////

Function RectI(L,T,R,B: GLFloat): pglRectI; OverLoad;
	Begin
  	Result.Left := trunc(L);
    Result.Right := trunc(R);
    Result.Top := trunc(T);
    Result.Bottom := trunc(B);
    Result.X := trunc(L + ((R - L) / 2));
    Result.Y := trunc(T + ((B - T) / 2 ));
    Result.Width := trunc(R-L);
    Result.Height := trunc(B-T);
  End;

Function RectI(Center: pglVector2; W,H: GLFloat): pglRectI; OverLoad;
	Begin
  	Result.X := trunc(Center.X);
    Result.Y := trunc(Center.Y);
    Result.Width := trunc(W);
    Result.Height := trunc(H);
    Result.Update(FROMCENTER);
  End;


Function RectIWH(L,T,W,H: GLFloat): pglRectI;
  Begin
    Result.Width := trunc(W);
    Result.Height := trunc(H);
    Result.Left := trunc(L);
    Result.Top := trunc(T);
    Result.Right := Result.Left + trunc(W);
    Result.Bottom := Result.Top + trunc(H);
    Result.X := RoundInt(Result.Left + (Result.Width / 2));
    Result.Y := RoundInt(Result.Top + (Result.Height / 2));
  End;


Function RectF(L,T,R,B: GLFloat): pglRectF; OverLoad;
	Begin
  	Result.Left := L;
    Result.Right := R;
    Result.Top := T;
    Result.Bottom := B;
    Result.X := L + ((R - L) / 2);
    Result.Y := T + ((B - T) / 2 );
    Result.Width := R-L;
    Result.Height := B-T;
  End;


Function RectFWH(L,T,W,H: GLFloat): pglRectF;
  Begin
    Result.Left := L;
    Result.Top := T;
    Result.Width := W;
    Result.Height := H;
    Result.X := Result.Left + (Result.Width / 2);
    Result.Y := Result.Top + (Result.Height / 2);
    Result.Update(FROMCENTER);
  End;

Function RectF(Center: pglVector2; W,H: GLFloat): pglRectF; OverLoad;
	Begin
  	Result.X := (Center.X);
    Result.Y := (Center.Y);
    Result.Left := (Center.X - (W / 2));
    Result.Right := Result.Left + W;
    Result.Top := (Center.y - (H / 2));
    Result.Bottom := Result.Top + H;
    Result.Width := W;
    Result.Height := H;
  End;


Function PointsToRectF(Var Points: Array of pglVector2): pglRectF;

Var
L,R,T,B: GLFloat;
I: Long;

  Begin

    L := 0;
    R := 0;
    T := 0;
    B := 0;

    For I := 0 to High(Points) Do Begin

      If I = 0 Then Begin
        L := Points[i].X;
        R := Points[i].X;
        T := Points[i].Y;
        B := Points[i].Y;
      End;

      If Points[i].X < L Then L := Points[i].X;
      If Points[i].X > R Then R := Points[i].X;
      If Points[i].Y < T Then T := Points[i].Y;
      If Points[i].Y > B Then B := Points[i].Y;

    End;

    Result := glDrawMain.RectF(L,T,R,B);

  End;


Function CheckPointInBounds(Point: pglVector2; Bounds: pglRectF): Boolean;
  Begin

    Result := false;

    If Point.X >= Bounds.Left Then Begin
      If Point.X <= Bounds.Right Then Begin
        If Point.Y >= Bounds.Top Then Begin
          If POint.Y <= Bounds.Bottom Then Begin
            Result := True;
          End;
        End;
      End;
    End;

  End;

Function Vec2(inX,InY: GLFloat): pglVector2;
	Begin
  	Result.X := inX;
    Result.Y := inY;
  End;

Function Vec2(PointF: TPointFloat): pglVector2;
  Begin
    Result.X := PointF.X;
    Result.Y := PointF.Y;
  End;

Function Vec2(Vector3: pglVector3): pglVector2;
  Begin
    Result.X := Vector3.X;
    Result.Y := Vector3.Y;
  End;

Function Vec3(inX,inY,inZ: GLFloat): pglVector3;
	Begin
  	Result.X := inX;
    Result.Y := inY;
    Result.Z := inZ;
  end;

Function Vec4(inX,inY,inZ,inW: GLFloat): pglVector4;
	Begin
    Result.X := inX;
    Result.Y := inY;
    Result.Z := inZ;
    Result.W := inW;
  end;


Function SXVec2(inX,inY: GLFloat): pglVector2;
  Begin
    Result.X := pglScaleX * (inX);
    Result.Y := pglScaleY * (inY);
  End;


Function PGLAngleToRad(Angle: GLFloat): GLFloat;
  Begin
    Result := Angle * (Pi / 180);
  End;

Function PGLRadToAngle(Rad: GLFloat): GLFloat;
  Begin
    Result := Rad * (180/Pi);
  End;

Function BoolToInt(Bool: Boolean): GLUint;
  Begin

    If Bool = False Then Begin
      Result := 0;
    End Else Begin
      Result := 1;
    End;

  End;

Procedure FlipPoints(Var Points: pglVectorQuad); Register;
// Swap top and bottom points of pglVectorQuad, in effect flipping the points of a rectangle
Var
TP1, TP2: pglVector2;

  Begin
    TP1 := Points[0];
    TP2 := Points[1];
    Points[0] := Points[3];
    Points[1] := Points[2];
    Points[3] := TP1;
    Points[2] := TP2;
  End;


Procedure MirrorPoints(Var Points: pglVectorQuad); Register;
// Mirror Left and Right points of pglVectorQuad, in effect Mirroring the points of a rectangle
Var
TP1, TP2: pglVector2;

  Begin
    TP1 := Points[0];
    TP2 := Points[3];
    Points[0] := Points[1];
    Points[3] := Points[2];
    Points[1] := TP1;
    Points[2] := TP2;
  End;


Procedure RotatePoints(Var Points: Array of pglVector2; Center: pglVector2; Angle: GLFloat);

Var
OldPoints: Array of pglVector2;
Count: Long;
I: Long;
Dist: GLFloat;
PointAngle: GLFloat;

  Begin

    if Angle = 0 Then Exit;

    Count := Length(Points);
    SetLength(OldPoints,Count);
//    Angle := -Angle;

    For I := 0 to Count - 1 Do Begin
      OldPoints[i].X := Points[i].X;
      OldPoints[i].Y := Points[i].Y;
    End;

    For I := 0 to Count - 1 Do Begin
      Dist := Sqrt( IntPower(OldPoints[i].X - Center.X,2) + IntPower(OldPoints[i].Y - Center.Y,2));
      PointAngle := ArcTan2(OldPoints[i].Y - Center.Y,OldPoints[i].X - Center.X);
      Points[i].X := Center.X + (Dist * Cos(Angle + PointAngle));
      Points[i].Y := Center.Y + (Dist * Sin(Angle + PointAngle));
    End;

  End;


Procedure TruncPoints(Var Points: Array of pglVector2);
Var
I,Len: Long;
  Begin
    Len := High(Points);
    For I := 0 to Len Do Begin
      Points[i].X := trunc(Points[i].X);
      Points[i].Y := trunc(Points[i].Y);
    End;

  End;

Function ReturnRectPoints(P1,P2: pglVector2; Width: GLFloat): pglVectorQuad;

Var
Distance, Angle: GLFloat;

  Begin

    Angle := ArcTan2(P2.Y - P1.Y, P2.X - P1.X);

    Result[0].X := P1.X + ((Width / 2) * Cos(Angle + (Pi / 2)));
    Result[0].Y := P1.Y + ((Width / 2) * Sin(Angle + (Pi / 2)));

    Result[1].X := P2.X + ((Width / 2) * Cos(Angle + (Pi / 2)));
    Result[1].Y := P2.Y + ((Width / 2) * Sin(Angle + (Pi / 2)));

    Result[2].X := P2.X + ((Width / 2) * Cos(Angle - (Pi / 2)));
    Result[2].Y := P2.Y + ((Width / 2) * Sin(Angle - (Pi / 2)));

    Result[3].X := P1.X + ((Width / 2) * Cos(Angle - (Pi / 2)));
    Result[3].Y := P1.Y + ((Width / 2) * Sin(Angle - (Pi / 2)));

  End;

Function ClampFColor(inVal: GLFloat): GLFloat;
  Begin
    If inVal > 1 Then inVal := 1;
    if InVal < 0 Then inVal := 0;

    Result := inVal;
  End;

Function ClampIColor(inVal: GLInt): GLInt;
  Begin
    If inVal > 255 Then inVal := 255;
    if InVal < 0 Then inVal := 0;

    Result := inVal;
  End;


Function RoundInt(Value: GLFLoat): GLInt;
Var
VFloat: GLFloat;
  Begin
    VFloat := Value - trunc(Value);
    If VFloat < 5 Then Begin
      Result := Trunc(Value);
    end Else Begin
      Result := Trunc(Value) + 1;
    End;
  End;

Function Color3i(inRed,inGreen,inBlue: GLInt): pglColorI;
	Begin
  	Result.Red := ClampIColor(inRed);
    Result.Green := ClampIColor(inGreen);
    Result.Blue := ClampIColor(inBlue);
    Result.Alpha := 255;
  End;

Function Color4i(inRed,inGreen,inBlue,inAlpha: GLInt): pglColorI;
	Begin
  	Result.Red := ClampIColor(inRed);
    Result.Green := ClampIColor(inGreen);
    Result.Blue := ClampIColor(inBlue);
    Result.Alpha := ClampIColor(inAlpha);
  End;

Function Color3f(inRed,inGreen,inBlue: GLFloat): pglColorF;
	Begin
  	Result.Red := ClampFColor(inRed);
    Result.Green := ClampFColor(inGreen);
    Result.Blue := ClampFColor(inBlue);
    Result.Alpha := 1;
  End;

Function Color4f(inRed,inGreen,inBlue,inAlpha: GLFloat): pglColorF;
  Begin
	  Result.Red := (inRed);
    Result.Green := (inGreen);
    Result.Blue := (inBlue);
    Result.Alpha := (inAlpha);
  End;

Function ColorItoF(inColor: pglColorI): pglColorF;
	Begin
    Result.Red := inColor.Red / 255;
    Result.Green := inColor.Green / 255;
    Result.Blue := inColor.Blue / 255;
    Result.Alpha := incolor.Alpha / 255;
  end;

Function ColorFtoI(inColor: pglColorF): pglColorI;
	Begin
    Result.Red := PGLRound(inColor.Red * 255);
    Result.Green := PGLRound(inColor.Green * 255);
    Result.Blue := PGLRound(inColor.Blue * 255);
    Result.Alpha := PGLRound(incolor.Alpha * 255);
  end;


Function CC(Color: pglColorI): pglColorF;
  Begin
    Result := coloritof(color);
  End;

Function CC(Color: pglColorF): pglColorI;
  Begin
    result := colorftoi(color);
  End;

Function GetColorChangeIncrements(StartColor, EndColor: pglColorI; Cycles: Integer): pglColorI;
  Begin

  End;


Function GetColorChangeIncrements(StartColor, EndColor: pglColorF; Cycles: Integer): pglColorF;

Var
RDif,GDif,BDif,ADif: GLFloat;

  Begin

    RDif := (EndColor.Red - StartColor.Red) / Cycles;
    GDif := (EndColor.Green - StartColor.Green) / Cycles;
    BDif := (EndColor.Blue - StartColor.Blue) / Cycles;
    ADif := (EndColor.Alpha - StartColor.Alpha) / Cycles;

    Result := Color4f(RDif,Gdif,BDif,ADif);
  End;


Function ColorCombine(Color1,Color2: pglColorI): pglColorI;
  Begin
    Result.Red := ClampIColor(Color1.Red + Color2.Red);
    Result.Green := ClampIColor(Color1.Green + Color2.Green);
    Result.Blue := ClampIColor(Color1.Blue + Color2.Blue);
    Result.Alpha := ClampIColor(Color1.Alpha + Color2.Alpha);
  End;

Function ColorCombine(Color1,Color2: pglColorF): pglColorF;
  Begin
    Result.Red := ClampFColor(Color1.Red + Color2.Red);
    Result.Green := ClampFColor(Color1.Green + Color2.Green);
    Result.Blue := ClampFColor(Color1.Blue + Color2.Blue);
    Result.Alpha := ClampFColor(Color1.Alpha + Color2.Alpha);
  End;

Function ColorMultiply(Color1,Color2: pglColorI): pglColorI;
Var
Col1,Col2: pglColorF;
RColor: pglColorF;

  Begin
    Col1 := CC(Color1);
    Col2 := CC(Color2);

    RColor.Red := (Col1.Red * Col2.Red);
    RColor.Green := (Col1.Green * Col2.Green);
    RColor.Blue := (Col1.Blue * Col2.Blue);
    RColor.Alpha := (Col1.Alpha * Col2.Alpha);
    Result := CC(RColor);

  End;


Function ColorMultiply(Color1,Color2: pglColorF): pglColorF;
Var
RColor: pglColorF;

  Begin

    RColor.Red := (Color1.Red * Color2.Red);
    RColor.Green := (Color1.Green * Color2.Green);
    RColor.Blue := (Color1.Blue * Color2.Blue);
    RColor.Alpha := (Color1.Alpha * Color2.Alpha);
    Result := RColor;

  End;

Procedure ColorAdd(Out Color: pglColorI; AddColor: pglColorI; AddAlphas: Boolean = True);
  Begin
    Color.Red := ClampIColor(Color.Red + AddColor.Red);
    Color.Green := ClampIColor(Color.Green + AddColor.Green);
    Color.Blue := ClampIColor(Color.Blue + AddColor.Blue);

    If AddAlphas Then Begin
      Color.Alpha := ClampIColor(Color.Alpha + AddColor.Alpha);
    End;
  End;

Procedure ColorAdd(Out Color: pglColorF; AddColor: pglColorF; AddAlphas: Boolean = True);
  Begin
    Color.Red := ClampFColor(Color.Red + AddColor.Red);
    Color.Green := ClampFColor(Color.Green + AddColor.Green);
    Color.Blue := ClampFColor(Color.Blue + AddColor.Blue);

    If AddAlphas Then Begin
      Color.Alpha := ClampFColor(Color.Alpha + AddColor.Alpha);
    End;
  End;


Function ColorMix(Color1,Color2: pglColorI; Factor: GLFloat): pglColorI;
Var
ColVal: GLInt;
  Begin

    Result.Red := trunc((Color1.Red + Color2.Red) / 2);
    Result.Green := trunc((Color1.Green + Color2.Green) / 2);
    Result.Blue := trunc((Color1.Blue + Color2.Blue) / 2);
    Result.Alpha := trunc((Color1.Alpha + Color2.Alpha) / 2);

  End;


Function PGLStringToChar(InString: String): pglCharArray;

Var
I: Long;
Len: Long;
CHR: pglCharArray;

  Begin

    Len := Length(InString);
    SetLength(CHR,Len);

    For I := 0 To High(CHR) do Begin
      CHR[i] := AnsiChar(InString[I + 1]);
    End;

    Result := CHR;

  End;


Procedure PGLSaveTexture(Texture: GLUInt; Width,Height: GLUInt; FileName: String; MipLevel: GLUInt = 0);

Var
Pixels: Array of pglColorI;
I: Long;
FileChar: pglCharArray;
TexWidth, TexHeight: GLInt;

  Begin

    If MipLevel > 0 Then Begin

      For I := 1 to MipLevel Do Begin
        Width := trunc(Width / 2);
        Height := trunc(Height / 2);
      End;

    End;

    PGL.BindTexture(0,Texture);

    glGetTexLevelParameterIV(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, @TexWidth);
    glGetTexLevelParameterIV(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, @TexHeight);

    SetLength(Pixels,(Width * Height));

    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
    stbi_write_png(PAnsiChar(AnsiString(FileName)),Width,Height,4,Pixels,SizeOf(Pixels[0]) * TexWidth);

  End;


Procedure PGLReplaceTextureColors(Textures: Array of pglTexture; Colors: Array of pglColorI; NewColor: pglColorI); Register;
Var
Count: GLInt;
I,Z,R,T: Long;
Pixels: Array of pglColorI;

  Begin

    // Replace all instances of COLORS in TEXTURES with NEWCOLOR

    Count := Length(Textures);

    For T := 0 to Count - 1 Do Begin

      SetLength(Pixels, Textures[T].Width * Textures[T].Height);
      PGL.BindTexture(0,Textures[T].Handle);

      glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);

      For I := 0 to High(Pixels) Do Begin

          For R := 0 to High(Colors) Do Begin
            If Pixels[i].IsColor(Colors[r]) Then Begin
              Pixels[i] := NewColor;
            End;
          End;
      End;

      glTexImage2d(GL_TEXTURE_2D, 0, GL_RGBA, Textures[T].Width, Textures[T].Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, Pixels);

    End;
  End;


Procedure PGLReplaceAllTexturesColors(Colors: Array of pglColorI; NewColor: pglColorI);
Var
Count: GLInt;
CurTex: pglTexture;
TexWidth, TexHeight: GLInt;
I,T,R: GLInt;
Pixels: Array of pglColorI;

  Begin

    Count := Length(PGL.TextureObjects);

    For T := 0 to Count - 1 Do Begin

      CurTex := PGL.TextureObjects[T];
      PGL.BindTexture(0,CurTex.Handle);
      TexWidth := CurTex.Width;
      TexHeight := CurTex.Height;

      SetLength(Pixels, TexWidth * TexHeight);
      glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE,Pixels);

      For I := 0 to High(Pixels) Do Begin
        For R := 0 to High(Colors) Do Begin
          If Pixels[I].IsColor(Colors[R]) Then Begin
            Pixels[I] := NewColor;
          End;
        End;
      End;

      glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,TexWidth,TexHeight,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);

    End;


  End;


Procedure PGLSetEllipseInterval(Interval: GLInt = 10);
  Begin
    If Interval < 1 Then InterVal := 1;
    PGL.EllipsePointInterval := Interval;
  End;


Function ImageDesc(Source: Pointer; Width,Height: GLUInt): pglImageDescriptor;
  Begin
    Result.Handle := Source;
    Result.Width := Width;
    Result.Height := Height;
  End;

Function PGLPixelFromMemory(Source: Pointer; X,Y,Width,Height: GLInt): pglColorI;
Var
IPtr: PByte;

  Begin

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

  End;

Procedure PGLResizeData(Var Data: Pointer; Width,Height,NewWidth,NewHeight: GLUint);
Var
OrgData: PByte;
DataCopy: PByte;
OrgLoc, CopyLoc: Integer;
UseWidth, UseHeight: GLUint;
I: Long;

  Begin

    // Allocate memory for copy of the data and copy from original
    DataCopy := AllocMem((Width * Height) * 4);
    Move(Data^,DataCopy[0], 4 * (Width * Height));

    // Free the original and reallocate to the new size
    stbi_image_free(Data);
    Data := AllocMem(4 * (NewWidth * NewHeight));

    // Determine the dimensions to work with
    If Width <= NewWidth Then Begin
      UseWidth := Width;
    End Else Begin
      UseWidth := NewWidth;
    End;

    If Height <= NewHeight Then Begin
      UseHeight := Height;
    End Else Begin
      UseHeight := NewHeight;
    End;

    // Set a pointer to the beginning of the original data
    OrgData := Data;
    OrgLoc := 0;
    CopyLoc := 0;

    // Move the relavent areas of the copy into the resized data
    For I := 0 to UseHeight - 1 Do Begin
      Move(DataCopy[CopyLoc], OrgData[OrgLoc], UseWidth * 4);
      OrgLoc := OrgLoc + Integer((NewWidth * 4));
      CopyLoc := CopyLoc + Integer((Width * 4));
    End;

    // Free the copy
    FreeMem(DataCopy,(Width * Height) * 4);

  End;



Function FindTextLineBreak(Var Text: String): Integer;

Var
LBPOS: Integer;

  Begin

    Result := 0;

    // look for sLineBkreak
    LBPOS := POS(sLineBreak,Text);
    If LBPOS <> 0 Then Begin
      Result := LBPOS;
      Exit;
    End;

    // look for \n
    LBPOS := POS('\n',Text);
    If LBPOS <> 0 Then Begin
      Result := LBPOS;
      Exit;
    End;

  End;


Function FindTextTags(Var Text:String): pglTextTagArray;

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
Tags: pglTextTagArray;
TagCount: GLint;
Done: boolean;
TagDone: Boolean;
I: Long;
FoundColor: Boolean;
IsColorI: boolean;
ColorVals: Array [0..3] of GLFloat;
ColorStart: GLint;
CurColor: GLInt;

  Begin

    // Start Tags with <TAG>
    // End Tags with <END>
    // Tags = B - Bold, I - Italic, CI(###,###,###,####) - ColorI, CF(#,#,#,#) - ColorF
    // <TAG>B,I,C(255,255,255,255)<END>

    Len := Length(Text);
    CurChar := 1;
    Done := False;

    While Done = False Do Begin

      // check if tags are present in string
      CurChar := Pos('<TAG>',Text,CurChar);

      // if not, exit
      If CurChar = 0 Then Begin
        Done := True;
        Break;
      End;

      // make sure its actually a tag start that was found
      If AnsiMidStr(Text,CurChar,5) = '<TAG>' Then Begin

        // Increase tag list by 1
        SetLength(Tags,Length(Tags) + 1);
        TagCount := Length(Tags);
        TagStart := CurChar;
        ParseStart := CurChar;
        TagDone := false;

        // Start the tag and the parsing at the found position
        While TagDone = False Do Begin
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

            If ReadChar = '<' Then Begin
              TagDone := True;
              Break;
            End;

            ParseLength := I - ParseStart;
            TagReadString := AnsiMidStr(Text,ParseStart,ParseLength); // Cache the tag read

            If TagReadString = 'B' Then Begin
              Tags[TagCount].Bold := True; // Check For Bold
            End Else If TagReadString = 'I' Then Begin
              Tags[TagCount].Italic := True; // check For Italics
            End Else Begin
              // Else, look for color tags
              If ContainsText(Text,'CI') Then Begin
                IsColorI := True;
                FoundColor := True;
              End Else If ContainsText(Text,'CF') Then Begin
                IsColorI := False;
                FoundColor := True;
              End;

            End;


            // Get the color values if a color was found
            If FoundColor = True Then Begin

              // move start of parse forward to start of colors
              ColorStart := ParseStart + 8;
              ReadPos := ColorStart;
              CurColor := 0;
              I := ColorStart;

              // read forward and parse out colors
              While CurColor < 4 Do Begin

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
                  If ReadChar = ')' Then Break

              End;

              // Convert the color to floats if needed and assign to current tag
              If IsColorI = True Then Begin
                Tags[TagCount].Color := CC(Color4I(trunc(ColorVals[0]),trunc(ColorVals[1]),trunc(ColorVals[2]),trunc(ColorVals[2])));
              End Else Begin
                Tags[TagCount].Color := Color4F(ColorVals[0],ColorVals[1],ColorVals[2],ColorVals[3]);
              End;

            End;

            ParseStart := ReadPos;

        End;


      End;



    End;

    Result := Tags;


  End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////// pglVector2///////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Procedure pglVector2.MatrixMultuply(Mat: pglMatrix2);
Var
X,Y: Single;
  Begin
    X := Self.X;
    Y := Self.Y;
    Self.X := (Mat.M[0,0] * X) + (Mat.M[0,1] * Y);
    Self.Y := (Mat.M[1,0] * X) + (Mat.M[1,1] * Y);
  end;

Procedure pglVector2.Translate(X: Single; Y: Single);
  Begin
      Self.X := Self.X + X;
      Self.Y := Self.Y + Y;
  End;

Procedure pglVector2.Rotate(Angle: Single);
  Begin
    Self.MatrixMultuply(PGLMat2Rotation(Angle));
  End;

Procedure pglVector2.Scale(sX: Single; sY: Single);
  Begin
    Self.X := BX(Self.X,sX);
    Self.Y := BY(Self.Y,sY);
  End;


Procedure pglVector2.Normalize(Origin: pglVector2);

Var
Dist: Single;

  Begin
    Dist := Sqrt( IntPower(Self.Y - Origin.Y,2) + IntPower(Self.X - Origin.X,2));
    Self.X := (Self.X - Origin.X) / Dist;
    Self.y := (Self.Y - Origin.Y) / Dist;
  End;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////// pglVector3 //////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Class Operator pglVector3.Subtract(A: pglVector3; B: pglVector3): pglVector3;
  Begin
    Result := Vec3(A.X - B.X, A.Y - B.Y, A.Z - B.Z);
  End;


Procedure pglVector3.Normalize();
Var
Len: GLFloat;

  Begin
    Len := Sqrt( (Self.X * Self.X) + (Self.Y * Self.Y) + (Self.Z * Self.Z));
    Self.X := Self.X / Len;
    Self.Y := Self.Y / Len;
    Self.Z := Self.Z / Len;
  End;


Procedure pglVector3.Cross(Vec: pglVector3);
Var
RVec: pglVector3;

  Begin
    RVec.X := (Self.Y * Vec.Z) - (Self.Z * Vec.Y);
    RVec.Y := (Self.Z * Vec.X) - (Self.X * Vec.Z);
    RVec.Z := (Self.X * Vec.Y) - (Self.Y * Vec.X);
  End;


Procedure pglVector3.MatrixMultiply(Mat: pglMatrix3);
Var
X,Y,Z: Single;
  Begin
    X := Self.X;
    Y := Self.Y;
    Z := Self.Z;
    Self.X := (Mat.M[0] * X) + (Mat.M[3] * Y) + (Mat.M[6] * Z);
    Self.Y := (Mat.M[1] * X) + (Mat.M[4] * Y) + (Mat.M[7] * Z);
    Self.Z := (Mat.M[2] * X) + (Mat.M[5] * Y) + (Mat.M[8] * Z);
  end;

Procedure pglVector3.Translate(X: Single = 0; Y: Single = 0; Z: Single = 0);
  Begin
    Self.X := Self.X + X;
    Self.Y := Self.Y + Y;
    Self.Z := Self.Z + Z;
  End;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////// pglVectorCube////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////




////////////////////////////////////////////////////////////////////////////////
////////////////////////////// pglMatrix3///////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Procedure pglMatrix3.Fill(Values: Array of GLFloat);
Var
FillCount: GLInt;
I: Long;

  Begin

    If Length(Values) >= 9 Then Begin
      FillCount := 9;
    End Else Begin
      FillCount := Length(Values);
    End;

    For I := 0 to FillCount - 1 Do Begin
      Self.M[I] := Values[I];
    end;

  End;


Function pglMatrix3.Val(X,Y: GLUint): GLFloat;
  Begin
    Result := Self.M[(X * 3) + Y];
  End;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////// pglMatrix2///////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Procedure pglMatrix2.MakeRotation(Angle: Single);
  Begin
    Self := PGLMat2Rotation(Angle);
  End;

Procedure pglMatrix2.MakeTranslation(X: Single; Y: Single);
  Begin
    Self := PGLMat2Translation(X,Y);
  End;

Procedure pglMatrix2.MakeScale(sX,sY: GLFloat);
  Begin
    Self := PGLMat2Scale(sX,sY);
  End;

Procedure pglMatrix2.Rotate(Angle: Single);
  Begin
    Self := PGLMat2Multiply(Self,PGLMat2Rotation(Angle));
  End;

Procedure pglMatrix2.Translate(X: Single; Y: Single);
  Begin
    Self := PGLMat2Multiply(Self,PGLMat2Translation(X,Y));
  End;

Procedure pglMatrix2.Scale(sX: Single; sY: Single);
  Begin
    Self := PGLMat2Multiply(Self,PGLMat2Scale(sX,sY));
  End;

//////////////////////////  Callback Placeholders //////////////////////////////
Procedure ReSizeFuncPlaceHolder();
  Begin
  End;

//////////////////////////  MATH FunctionS //////////////////////////////

Function PGLRound(inVal: GLFloat): GLInt;

Var
Rem: GLFloat;
Val: GLInt;

	Begin
    Val := trunc(inVal);
    Rem := inVal - Val;

    if Rem > 0.5 Then Begin
      Result := Val + 1;
    End Else Begin
    	Result := Val;
    End;

  End;


Function PGLMatrixIdentity(): pglMatrix4;
  Begin
    Result.M[0] := 1; Result.M[4] := 0; Result.M[8] := 0; Result.M[12] := 0;
    Result.M[1] := 0; Result.M[5] := 1; Result.M[9] := 0; Result.M[13] := 0;
    Result.M[2] := 0; Result.M[6] := 0; Result.M[10] := 0; Result.M[14] := 0;
    Result.M[3] := 0; Result.M[7] := 0; Result.M[11] := 0; Result.M[15] := 1;
  End;


Function PGLMatrixRotation(Out Mat: pglMatrix4; inAngle,X,Y: GLFloat): Boolean;
  Begin
    Mat.M[0] := cos(inAngle); Mat.M[4] := sin(inAngle); Mat.M[8] := 0; Mat.M[12] := 0;
    Mat.M[1] := -sin(inAngle); Mat.M[5] := cos(inAngle); Mat.M[9] := 0; Mat.M[13] := 0;
    Mat.M[2] := 0; Mat.M[6] := 0; Mat.M[10] := 0; Mat.M[14] := 0;
    Mat.M[3] := 0; Mat.M[7] := 0; Mat.M[11] := 0; Mat.M[15] := 1;
    Result := True;
  End;

Function PGLMatrixScale(Out Mat: pglMatrix4; W,H: GLFloat): Boolean;
Var
ScaleX,ScaleY: GLFloat;
  Begin

    If w > h Then Begin
      ScaleX := 2 / W;
      ScaleY := ScaleX * (w/h);
    End Else Begin
      ScaleY := 2 / H;
      ScaleX := ScaleY * (h/w);
    End;

    Mat.M[0] := ScaleX; Mat.M[4] := 0; Mat.M[8] := 0; Mat.M[12] := 0;
    Mat.M[1] := 0; Mat.M[5] := ScaleY; Mat.M[9] := 0; Mat.M[13] := 0;
    Mat.M[2] := 0; Mat.M[6] := 0; Mat.M[10] := 0; Mat.M[14] := 0;
    Mat.M[3] := 0; Mat.M[7] := 0; Mat.M[11] := 0; Mat.M[15] := 1;
    Result := true;
  End;

Function PGLMatrixTranslation(Out Mat: pglMatrix4; X,Y: GLFloat): Boolean;
  Begin
    Mat.M[0] := 1; Mat.M[4] := 0; Mat.M[8] := 0; Mat.M[12] := x;
    Mat.M[1] := 0; Mat.M[5] := 1; Mat.M[9] := 0; Mat.M[13] := y;
    Mat.M[2] := 0; Mat.M[6] := 0; Mat.M[10] := 0; Mat.M[14] := 1;
    Mat.M[3] := 0; Mat.M[7] := 0; Mat.M[11] := 0; Mat.M[15] := 1;
    Result := true;
  End;


Function PGLMat2Rotation(Angle: GLFloat): pglMatrix2;
  Begin
    Result.M[0,0] := cos(Angle);  Result.M[0,1] := -sin(Angle);
    Result.M[1,0] := sin(Angle); Result.M[1,1] := cos(Angle);
  End;

Function PGLMat2Translation(X,Y: GLFloat): pglMatrix2;
  Begin
    Result.M[0,0] := X; Result.M[0,1] := 0;
    Result.M[1,0] := 0; Result.M[1,1] := Y;
  End;

Function PGLMat2Scale(sX,sY: GLFloat): pglMatrix2;
  Begin
    Result.M[0,0] := BX(1,sX); Result.M[0,1] := 0;
    Result.M[1,0] := 0;        Result.M[1,1] := BY(1,sY);
  End;

Function PGLMat2Multiply(Mat1,Mat2: pglMatrix2): pglMatrix2;
Var
Rows, Cols, L: Integer;
I, J: Integer;
Sum: Double;
K: Integer;

  Begin
    Rows := 2;
    Cols := 2;
    L := 2;

    For i := 0 to Rows - 1 Do Begin
      For j := 0 to Cols - 1 Do Begin

        Sum := 0.0;
        For k := 0 to l - 1 Do Begin
          Sum := Sum + (Mat1.M[i , k] * Mat2.M[k , j]);
          Result.M[i , j] := Sum;
        End;

      End;
    End;

  End;


Function PGLMat3Multiply(Mat1,Mat2: pglMatrix3): pglMatrix3;
Var
I,Z,C: Long;

  Begin

    For I := 0 to 2 Do Begin
        C := (I * 3) + 0;
        Result.M[C] := (Mat1.M[C] * Mat2.Val(0,I)) + (Mat1.M[C] * Mat2.Val(1,I)) + (Mat1.M[C] * Mat2.VAl(2,I));
        C := (I * 3) + 1;
        Result.M[C] := (Mat1.M[C] * Mat2.Val(0,I)) + (Mat1.M[C] * Mat2.Val(1,I)) + (Mat1.M[C] * Mat2.VAl(2,I));
        C := (I * 3) + 2;
        Result.M[C] := (Mat1.M[C] * Mat2.Val(0,I)) + (Mat1.M[C] * Mat2.Val(1,I)) + (Mat1.M[C] * Mat2.VAl(2,I));
    End;

  End;


Function PGLMatToVec(Mat: pglMatrix2): pglVector2;
  Begin
    Result := Vec2(0,0);
  End;


Function PGLVectorCross(VecA, VecB: pglVector3): pglVector3;
  Begin
    Result.X := (VecA.Y * VecB.Z) - (VecA.Z * VecB.Y);
    Result.Y := (VecA.Z * VecB.X) - (VecA.X * VecB.Z);
    Result.Z := (VecA.X * VecB.Y) - (VecA.Y * VecB.X);
  End;

// Transform Points to Screen Coordinates
Function SX(inVal: GLFloat): GLFloat;
  Begin
    Result := -1 + ((inVal / PGL.Window.Width) * 2);
  End;

Function SY(inVal: GLFloat): GLFloat;
  Begin
    Result := 1 - ((inVal / PGL.Window.Height) * 2);
  End;

// Transform Points to Buffer Coordinates
Function BX(inVal,BuffWidth: GLFloat): GLFloat;
  Begin
    Result := -1 + ((inVal / BuffWidth) * 2);
  End;

Function BY(inVal,BuffHeight: GLFloat): GLFloat;
  Begin
    Result := 1 - ((inVal / BuffHeight) * 2);
  End;

// Transform Points to Texture Coordinates
Function TX(inVal,TexWidth: GLFloat): GLFloat;
  Begin
    Result := InVal / TexWidth;
  End;

Function TY(inVal,TexHeight: GLFloat): GLFloat;
  Begin
    Result := InVal / TexHeight;
  End;

Procedure TransformToScreen(Out Points: pglVectorQuad);
  Begin
    Points[0] := vec2(sx(Points[0].X), sy(Points[0].Y));
    Points[1] := vec2(sx(Points[1].X), sy(Points[1].Y));
    Points[2] := vec2(sx(Points[2].X), sy(Points[2].Y));
    Points[3] := vec2(sx(Points[3].X), sy(Points[3].Y));
  End;


Procedure TransformToBuffer(Out Points: pglVectorQuad; BuffWidth,BuffHeight: GLFloat);
  Begin
    Points[0] := vec2(BX(Points[0].X,BuffWidth), BY(Points[0].Y,BuffHeight));
    Points[1] := vec2(BX(Points[1].X,BuffWidth), BY(Points[1].Y,BuffHeight));
    Points[2] := vec2(BX(Points[2].X,BuffWidth), BY(Points[2].Y,BuffHeight));
    Points[3] := vec2(BX(Points[3].X,BuffWidth), BY(Points[3].Y,BuffHeight));
  End;


Procedure TransformToTexture(Out Points: pglVectorQuad; TexWidth,TexHeight: GLFloat);
  Begin
    Points[0] := vec2(TX(Points[0].X,TexWidth), TY(Points[0].Y,TexHeight));
    Points[1] := vec2(TX(Points[1].X,TexWidth), TY(Points[1].Y,TexHeight));
    Points[2] := vec2(TX(Points[2].X,TexWidth), TY(Points[2].Y,TexHeight));
    Points[3] := vec2(TX(Points[3].X,TexWidth), TY(Points[3].Y,TexHeight));
  End;

////////////////////////////////////////////////////////////////////////////////
////////////////// Shader Functions ////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Function PGLGetUniform(Uniform: String): GLInt;

var
R: GLInt;
Chars: pglCharArray;

  Begin

    If CurrentProgram = nil Then Begin
      PGLAddError('Could not retieve uniform location. No shader program currently used!');
      Result := -1;
      Exit;
    End;

    Result := CurrentProgram.SearchUniform(Uniform);

    If Result = -1 Then Begin
      Chars := PGLStringToChar(Uniform);
      Result := glGetUniformLocation(CurrentProgram.ShaderProgram,PAnsiChar(AnsiString(Uniform)));

      if Result <> -1 Then Begin
        CurrentProgram.AddUniform(Uniform,Result);
      End;

    End Else Begin
      Result := Result;
    End;

  End;


//////////////////////// PGL State Context ///////////////////////////////

Class Operator PGLState.Initialize(Out Dest: PGLState);
  Begin
    Dest.GlobalLight := 1;
    Dest.EllipsePointInterval := 10;
  End;

Procedure PGLState.GetInputDevices(var KeyBoard: pglKeyBoard; var Mouse: pglMouse; var Controller: pglController);
  Begin
    KeyBoard := Self.Context.Keyboard;
    Mouse := Self.Context.Mouse;
    Controller := Self.Context.Controller;
  End;

Procedure PGLState.UpdateWindowBounds();
  Begin
    glViewPort(0,0,PGL.Window.Width,PGL.Window.Height);
  End;


Procedure PGLState.SetDefaultMaskColor(Color: pglColorI);
  Begin
    Self.DefaultMaskColor := ColorItoF(Color);
  End;


Procedure pglState.DestroyImage(Var Image: pglImage);
  Begin
    If Assigned(Image) = False Then Exit;

    If Image.pHandle <> Nil Then Begin
//      Image.Delete();
      FreeMemory(Image.pHandle);
      Image.pHandle := nil;
    End;

    Image.Destroy();
  End;


Procedure PGLState.AddDefaultColorReplace(Color: pglColorI; NewColor: pglColorI);
  Begin
    SetLength(Self.DefaultReplace,Length(Self.DefaultReplace) + 1 );
    Self.DefaultReplace[High(Self.DefaultReplace),0] := Color;
    Self.DefaultReplace[High(Self.DefaultReplace),1] := NewColor;
  End;

Procedure PGLState.AddRenderTexture(Source: pglRenderTexture);
  Begin
    SetLength(Self.RenderTextures,Length(Self.RenderTextures) + 1);
    Self.RenderTextures[High(Self.RenderTextures)] := Source;
  End;

Procedure PGLState.AddTextureObject(var TexObject: pglTexture);
  Begin
    SetLength(Self.TextureObjects,Length(Self.TextureObjects) + 1);
    Self.TextureObjects[High(Self.TextureObjects)] := TexObject;
  End;

Procedure PGLState.RemoveTextureObject(var TexObject: pglTexture);
Var
I: Long;
Sel: Long;

  Begin

    Sel := 0;

    For I := 0 to High(Self.TextureObjects) Do Begin
      If Self.TextureObjects[I] = TexObject Then Begin
        Sel := I;
        Break;
      End;
    End;


    For I := Sel to High(Self.TextureObjects) - 1 Do Begin
      Self.TextureObjects[I] := Self.TextureObjects[I+1];
    End;

    Self.TextureObjects[High(Self.TextureObjects)] := Nil;
    SetLength(Self.TextureObjects,High(Self.TextureObjects));

  End;

Procedure PGLState.UpdateViewPort(X,Y,W,H: GLInt);
  Begin
    Self.ViewPort.Width := W;
    Self.ViewPort.Height := H;
    Self.ViewPort.X := trunc(Self.ViewPort.Width / 2);
    Self.ViewPort.Y := trunc(Self.ViewPort.Height / 2);
    Self.ViewPort.Update(FROMCENTER);
  End;


Procedure PGLState.GenTexture(var Texture: Cardinal);

  Begin
    glGenTextures(1,@Texture);
    SetLength(Self.TExtures,Length(Self.Textures)+1);
    Self.Textures[High(Self.Textures)] := Texture;
  End;


Procedure PGLState.DeleteTexture(var Texture: Cardinal);
Var
I: Long;
Index: Long;

  Begin

    Index := -1;

    For I := 1 to High(Self.Textures) Do Begin
      If Self.Textures[i] = Texture Then Begin
        glDeleteTextures(1,@Texture);
        Index := I;
        Break;
      End;
    End;

    If Index = -1 Then Exit; // because no texture was found to destroy

    For I := Index to High(Self.Textures) - 1 Do Begin
      Self.Textures[i] := Self.Textures[i+1];
    End;

    SetLength(Self.Textures,Length(Self.Textures) - 1);

  End;


Procedure PGLState.BindTexture(TextureUnit: GLUInt; Texture: GLUInt);
  Begin

    If Self.TexUnit[TextureUnit] <> Texture Then Begin
      glActiveTexture(GL_TEXTURE0 + TextureUnit);
      glBindTexture(GL_TEXTURE_2D,texture);
    End;

  End;


Procedure PGLState.UnBindAll();
Var
I: Long;

  Begin

    For I := 0 to 31 Do Begin
      PGL.BindTexture(I,0);
    End;

  End;


Procedure PGLState.UnBindTexture(TexName: Cardinal);

Var
I: Long;

  Begin

    For I := 0 to 31 Do Begin

      If PGL.TexUnit[i] = TexName Then Begin
        PGL.BindTexture(i,0);
      End;

    End;

  end;


Procedure PGLState.VBOSubData(Binding: glEnum; OffSet: GLInt; Size: GLInt; Source: Pointer);
  Begin
    Self.CurrentBufferCollection.CurrentVBO.SubData(binding,offset,size,source);
  End;

Procedure PGLState.SSBOSubData(Binding: glEnum; OffSet: GLInt; Size: GLInt; Source: Pointer);
  Begin
    Self.CurrentBufferCollection.CurrentSSBO.SubData(binding,offset,size,source);
  End;

Function PGLState.GetNextVBO(): GLInt;
  Begin
    Result := Self.CurrentBufferCollection.GetNextVBO;
  End;

Function PGLState.GetNextSSBO(): GLInt;
  Begin
    Result := Self.CurrentBufferCollection.GetNextSSBO;
  End;



Function PGLState.GetTextureCount: NativeUInt;

  Begin
    Result := High(Self.Textures);
  End;


//////////////////////////////////////////////////////////////////////////////
//////////////////////////////pglBufferCollection/////////////////////////////
//////////////////////////////////////////////////////////////////////////////

Class Operator pglBufferCollection.Initialize(Out Dest: pglBufferCollection);

Var
I: Long;

  Begin
    // create the vertex array and buffer objects
    glGenVertexArrays(1,@Dest.VAO);
    glBindVertexArray(Dest.VAO);

    glGenBuffers(1,@Dest.EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,Dest.EBO);


    For I := 0 to High(Dest.VBO) do Begin
      glGenBuffers(1,@Dest.VBO[i].Buffer);
      glBindBuffer(GL_ARRAY_BUFFER,Dest.VBO[i].Buffer);
      glBufferData(GL_ARRAY_BUFFER,Dest.BufferSize,nil,GL_STREAM_DRAW);
      glBindBuffer(GL_ARRAY_BUFFER,0);
      Dest.VBO[i].InUse := false;
    End;

    For I := 0 to High(Dest.SSBO) do Begin
      glGenBuffers(1,@Dest.SSBO[i].Buffer);
      glBindBuffer(GL_ARRAY_BUFFER,Dest.SSBO[i].Buffer);
      glBufferData(GL_ARRAY_BUFFER,Dest.BufferSize,nil,GL_STREAM_DRAW);
      glBindBuffer(GL_ARRAY_BUFFER,0);
      Dest.SSBO[i].InUse := False;
    End;

    Dest.VBOInc := 0;
    Dest.SSBOInc := 0;

  End;

Procedure pglBufferCollection.Bind();
  Begin
      glBindVertexArray(Self.VAO);
      Self.InvalidateBuffers();
      PGL.CurrentBufferCollection := @Self;
  End;

Procedure pglBufferCollection.BindVBO(N: Cardinal);
  Begin
    glBindBuffer(GL_ARRAY_BUFFER,Self.VBO[N].Buffer);
    Self.CurrentVBO := @Self.VBO[N];
  End;

Procedure pglBufferCollection.BindSSBO(N: Cardinal);
  Begin
    glBindBuffer(GL_SHADER_STORAGE_BUFFER,Self.SSBO[N].Buffer);
    Self.CurrentSSBO := @Self.SSBO[N];
  End;

Procedure pglBufferCollection.InvalidateBuffers();
Var
I: Long;

  Begin

    For I := 0 to High(Self.VBO) Do Begin
      If Self.VBO[i].InUse = True Then Begin
//        glInvalidateBufferSubData(Self.VBO[i].Buffer,Self.VBO[i].SubDataOffset,Self.VBO[i].SubDataSize);
        glInvalidateBufferData(Self.VBO[i].Buffer);
        Self.VBO[i].InUse := False;
      End;

      If Self.SSBO[i].InUse = True Then Begin
//        glInvalidateBufferSubData(Self.SSBO[i].Buffer,Self.SSBO[i].SubDataOffset,Self.SSBO[i].SubDataSize);
        glInvalidateBufferData(Self.SSBO[i].Buffer);
        Self.SSBO[i].InUse := False;
      End;

    End;

  End;


Function pglBufferCollection.GetNextVBO(): GLUInt;
Var
I: Long;

  Begin
    inc(Self.VBOInc);
    If Self.VBOInc > High(SElf.VBO) Then Begin
      Self.VBOInc := 0;
    End;

    I := Self.VBOinc;

    Result := I;
    Self.VBO[i].InUse := TRue;
    Self.CurrentVBO := @Self.VBO[i];
    Exit;
  End;

Function pglBufferCollection.GetNextSSBO(): GLUInt;
Var
I: Long;
  Begin
    inc(Self.SSBOInc);
    If Self.SSBOInc > High(SElf.SSBO) Then Begin
      Self.SSBOInc := 0;
    End;

    I := Self.SSBOInc;

    Result := I;
    Self.SSBO[i].InUse := TRue;
    Self.CurrentSSBO := @Self.SSBO[i];
  End;


//////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// pglVBO ///////////////////////////////////
//////////////////////////////////////////////////////////////////////////////


Procedure pglVBO.SubData(Binding: glEnum; Offset: GLInt; Size: GLInt; Source: Pointer);
  Begin
    Self.SubDataOffSet := OffSet;
    Self.SubDataSize := Size;

    glBufferSubData(Binding,Offset,Size,Source);
  End;


//////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// pglSSBO //////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

Procedure pglSSBO.SubData(Binding: glEnum; Offset: GLInt; Size: GLInt; Source: Pointer);
  Begin
    Self.SubDataOffSet := OffSet;
    Self.SubDataSize := Size;

    glBufferSubData(Binding,Offset,Size,Source);
//    glBufferData(Binding,Size,Source,GL_STREAM_DRAW);
  End;


//////////////////////////////////////////////////////////////////////////////
//////////////////////////////pglRenderTarget/////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
constructor pglRenderTarget.Create(inWidth,inHeight: GLInt);

Var
I: GLInt;
CheckVar: glEnum;
Buff: Pointer;

	Begin
    // Set bounds and positions
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


Procedure pglRenderTarget.FillEBO();
Var
I: Long;
  Begin
    For I := 0 to 1000 Do Begin
      Self.TextureBatch.Indices[I].Index[0] := 0 + (4 * (I));
      Self.TextureBatch.Indices[I].Index[1] := 1 + (4 * (I));
      Self.TextureBatch.Indices[I].Index[2] := 2 + (4 * (I));
      Self.TextureBatch.Indices[I].Index[3] := 0 + (4 * (I));
      Self.TextureBatch.Indices[I].Index[4] := 2 + (4 * (I));
      Self.TextureBatch.Indices[I].Index[5] := 3 + (4 * (I));
    End;

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,Self.Buffers.EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER,SizeOf(pglIndices) * 1001,@Self.TextureBatch.Indices,GL_STREAM_DRAW);
  End;


Procedure pglRenderTarget.MakeCurrentTarget();
  Begin

    If PGL.CurrentRenderTarget <> Self.FrameBuffer Then Begin
      glBindFrameBuffer(GL_FRAMEBUFFER,Self.FrameBuffer);
      PGL.CurrentRenderTarget := Self.FrameBuffer;
    End;

    If Self.ClassType = pglWindow Then Begin
      glViewPort(0,0,pglWindow(Self).Width,pglWindow(Self).Height);
      PGL.UpdateViewPort(0,0,pglWindow(Self).Width,pglWindow(Self).Height);
    End Else Begin
      glViewPort(0,0,Self.Width,Self.Height);
      PGL.UpdateViewPort(0,0,Self.Width,Self.Height);
    end;

  End;


Procedure pglRenderTarget.CopyToTexture(SrcX: Cardinal; SrcY: Cardinal; SrcWidth: Cardinal; SrcHeight: Cardinal; DestTexture: Cardinal);

Var
Ver: pglVectorQuad;
Cor: pglVectorQuad;

  Begin

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

    pglRenderTexture(Self).StretchBlt(pglCopyBuffer,0,SrcHeight,SrcWidth,-SrcHeight,SrcX, SrcY, SrcWidth, SrcHeight);


  End;


Procedure CopyToImage2(Source: pglRenderTarget; Dest: pglImage; SourceRect, DestRect: pglRectI);
Var
Ver: pglVectorQuad;
Cor: pglVectorQuad;
PixelBuffer: GLUint;
Buffer: PByte;
BufferSize: GLInt;
NewBuffer: Array of Byte;

  Begin

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

  End;


Procedure pglRenderTarget.CopyToImage(Dest: pglImage; SourceRect, DestRect: pglRectI);
Var
I,Z: GLInt;
OrgPixels: PByte;
PixelCount: GLInt;
ImgPtr: PByte;
ImgLoc: GLInt;
WidthRatio, HeightRatio: GLFloat;

  Begin

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

    If (SourceRect.Width <> DestRect.Width) and (SourceRect.Height <> DestRect.Height) Then Begin
      // If Width and Heights are not the same, go one pixel at a time
      // Get rations between widths and heights
      WidthRatio := SourceRect.Width / DestRect.Width;
      HeightRatio := SourceRect.Height / DestRect.Height;

      For Z := 0 to DestRect.Height - 1 Do Begin
        For I := 0 to DestRect.Width - 1 Do Begin
          Move(OrgPixels[PixelCount], ImgPtr[ImgLoc], 4);
          Inc(PixelCount,4);
          Inc(ImgLoc,4);
        end;
      End;

    End Else Begin
      // If Width and Heights are the same, copy row by row
      For I := 0 to DestRect.Height - 1 Do Begin
        Move(orgPixels[PixelCount], ImgPtr[ImgLoc], 4 * (DestRect.Width));
        Inc(PixelCount, 4 * DestRect.Width);
        Inc(ImgLoc, 4 * (DestRect.Width));
      End;

    End;

    FreeMemory(OrgPixels);

  End;

Procedure pglRenderTarget.UpdateFromImage(Source: pglImage; SourceRect: pglRectI);
Var
I,Z,X,Y: Long;
Buffer: PByte;
SourcePtr: PByte;
SourceLoc, BufferLoc: Integer;

  Begin

    // Allocate Memory to Buffer
    Buffer := GetMemory((SourceRect.Width * SourceRect.Height) * 4);
    BufferLoc := 0;

    // Get pointer to source handle, location starting byte of rect in source data
    SourcePtr := Source.Handle;
    SourceLoc := ( (Source.Width * SourceRect.Top) + SourceRect.Left) * 4;

    // transfer source data to buffer one row at a time
    For I := 0 to SourceRect.Height - 1 Do Begin
      Move(SourcePtr[SourceLoc], Buffer[BufferLoc], 4 * (SourceRect.Width));
      BufferLoc := BufferLoc + (SourceRect.Width * 4);
      SourceLoc := SourceLoc + (Source.Width * 4);
    End;

    // Update framebuffer attachment with buffer data
    Self.MakeCurrentTarget();
    PGL.BindTexture(0,Self.Texture2D);
    glTexSubImage2D(GL_TEXTURE_2D, 0, SourceRect.Left, SourceRect.Top, SourceRect.Width, SourceRect.Height,
      GL_RGBA, GL_UNSIGNED_BYTE, Buffer);

    // Free buffer memory
    FreeMem(Buffer, (SourceRect.Width * SourceRect.Height) * 4);
    Buffer := nil;
    SourcePtr := nil;

  End;


Procedure pglRenderTarget.SetRenderRect(inRect: pglRectI);
Var
TempRect: pglRectF;
  Begin

    Self.RenderRect := RectF(Vec2(inRect.x,inRect.y),inRect.Width,inRect.Height);
    Self.UpdateVertices();
  End;

Procedure pglRenderTarget.SetRenderRect(inRect: pglRectF);
  Begin
    Self.RenderRect := inRect;
    Self.UpdateVertices();
  End;

Procedure pglRenderTarget.SetClipRect(inRect: pglRectI);
  Begin
    Self.ClipRect := RectF(Vec2(inRect.X,inRect.Y), inRect.Width, inRect.Height);
    Self.UpdateCorners;
  End;

Procedure pglRenderTarget.SetClipRect(inRect: pglRectF);
  Begin
    Self.ClipRect := inRect;
    Self.UpdateCorners;
  End;


Procedure pglRenderTarget.UpdateVertices;
  Begin
    // Update Screen Space Corners
    Self.Ver[0] := Vec2(-Self.RenderRect.Width / 2, -Self.RenderRect.Height / 2);
    Self.Ver[1] := Vec2(Self.RenderRect.Width / 2, -Self.RenderRect.Height / 2);
    Self.Ver[2] := Vec2(Self.RenderRect.Width / 2, Self.RenderRect.Height / 2);
    Self.Ver[3] := Vec2(-Self.RenderRect.Width / 2, Self.RenderRect.Height / 2);
  End;

Procedure pglRenderTarget.UpdateCorners();
  Begin
    // Update Clipping Corners
    Self.Cor[0] := Vec2((ClipRect.Left) / Self.Width,  (ClipRect.Top) / Self.Height);
    Self.Cor[1] := Vec2((ClipRect.Right) / Self.Width, (ClipRect.Top) / Self.Height);
    Self.Cor[2] := Vec2((ClipRect.Right) / Self.Width, (ClipRect.Bottom) / Self.Height);
    Self.Cor[3] := Vec2((ClipRect.Left) / Self.Width,  (ClipRect.Bottom) / Self.Height);
  End;


Procedure pglRenderTarget.SetOnResizeEvent(Event: pglFrameResizeFunc);
  Begin
    Self.ResizeFunc := Event;
  End;


Procedure pglRenderTarget.SetClearRect(ClearRect: pglRectF);
  Begin
    Self.ClearRect := ClearRect;
  End;


Procedure pglRenderTarget.AttachShadowMap();

Var
CheckVar: GLEnum;

  Begin

    If PGL.ShadowTarget = Self Then Exit;

    PGL.BindTexture(0,PGL.ShadowMap);

    // remove depth buffer from current owner if owned
    If PGL.ShadowTarget <> nil Then Begin
      glBindFrameBuffer(GL_FRAMEBUFFER,PGL.ShadowTarget.FrameBuffer);
      glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_DEPTH_ATTACHMENT,GL_TEXTURE_2D, 0, 0);
    End;

    // Attach the depth buffer to the new target
    glBindFrameBuffer(GL_FRAMEBUFFER,Self.FrameBuffer);
    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_DEPTH_ATTACHMENT,GL_TEXTURE_2D,PGL.ShadowMap,0);

    // Check for framebuffer completeness
    CheckVar := glCheckFrameBufferStatus(GL_FRAMEBUFFER);
    If CheckVar <> GL_FRAMEBUFFER_COMPLETE Then Begin
      PGLAddError('Unable to attach the shadow map depth buffer to the requested target');
    End;

  End;


Procedure pglRenderTarget.SetDrawOffSet(OffSet: pglVector2);
  Begin
    Self.pDrawOffSet := OffSet;
  End;

Procedure pglRenderTarget.SetPixelSize(Size: Single);
  Begin
    Self.pPixelSize := Size;
  End;

Procedure pglRenderTarget.SetBrightness(Level: Single);
  Begin
    Self.pBrightness := Level;
  End;

Procedure pglRenderTarget.SetNegative(Enable: Boolean = True);
  Begin
    Self.Negative := Enable;
  End;

Procedure pglRenderTarget.SetSwizzle(Enable: Boolean = True; R: Integer = 0; G: Integer = 1; B: Integer = 2);
  Begin
    Self.Swizzle := Enable;
    Self.SwizzleVals.X := R;
    Self.SwizzleVals.Y := G;
    Self.SwizzleVals.Z := B;
  End;

Procedure pglRenderTarget.SetTextSmoothing(Smoothing: Boolean = True);
  Begin
    Self.pTextSmoothing := Smoothing;
  End;

Procedure pglRenderTarget.SetClearColor(Color: pglColorI);
  Begin
    Self.pClearColor := CC(Color);
  End;

Procedure pglRenderTarget.SetClearColor(Color: pglColorF);
  Begin
    Self.pClearColor := Color;
  End;

Procedure pglRenderTarget.SetDrawShadows(Draw: Boolean; ShadowType: GLFloat = 0);
  Begin
    Self.DrawLastBatch();
    Self.pDrawShadows := Draw;
    Self.pShadowType := ShadowType;
  End;

Procedure pglRenderTarget.SetGlobalLight(Value: GLFloat);
  Begin
    self.pGlobalLight := Value;
  End;

Procedure pglRenderTarget.Display();

Var
ErrVar: glEnum;
ScreenVer: pglVectorQuad;
	Begin

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
    glUniform1f(PGLGetUniform('PixelSize'), pglRenderTexture(Self).PixelSize);

    glDrawArrays(GL_QUADS,0,4);

    Self.Texture := Self.Texture2D;

  end;


Procedure pglRenderTarget.Clear();
Var
UseColor: pglColorF;
UseColorI: pglColorI;
Buffers: GLInt;

	Begin

    Self.MakeCurrentTarget;

    glEnable(GL_SCISSOR_TEST);
    glScissor(trunc(Self.ClearRect.Left),
              trunc(Self.Height - Self.ClearRect.Height - Self.ClearRect.Top),
              trunc(Self.ClearRect.Width),
              trunc(Self.ClearRect.HEight));

    glClearColor(Self.ClearColor.Red,Self.ClearColor.Green,Self.ClearColor.Blue,Self.ClearColor.Alpha);
    glClearDepth(1-Self.GlobalLight);

    If Self.ClassType = pglRenderTexture Then Begin
      // For clearing pglRenderTexture
      If Self.pClearColorBuffers = True Then Begin
        glDrawBuffer(GL_COLOR_ATTACHMENT0);
        glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

        glDrawBuffer(GL_COLOR_ATTACHMENT1);
        glClear(GL_COLOR_BUFFER_BIT);
      End;

      If Self.pClearDepthBuffer = True Then Begin
        glDrawBuffer(GL_COLOR_ATTACHMENT2);
        glClearColor(0,0,0,1-Self.GlobalLight);
        glClear(GL_COLOR_BUFFER_BIT);
      End;

      glDrawBuffer(GL_COLOR_ATTACHMENT0);

    End Else Begin
      // For Clearing pglWindow
      Buffers := 0;

      If Self.pClearColorBuffers = True Then Begin
        Buffers := GL_COLOR_BUFFER_BIT;
        glClearColor(Self.ClearColor.Red, Self.ClearColor.Green, Self.ClearColor.Blue, Self.ClearColor.Alpha);
      End;

      If Self.pClearDepthBuffer = True Then Begin
        Buffers := Buffers or GL_DEPTH_BUFFER_BIT;
      End;

      If Buffers <> 0 Then Begin
        glClear(Buffers);
      End;

    End;

    glDisable(GL_SCISSOR_TEST);

  end;


Procedure pglRenderTarget.Clear(Color: pglColorI);

Var
UseColor: pglColorF;
UseColorI: pglColorI;
Buffers: GLEnum;
errvar: glenum;

  Begin

    Self.MakeCurrentTarget();

    glEnable(GL_SCISSOR_TEST);
    glScissor(trunc(Self.ClearRect.Left),
              trunc(Self.Height - Self.ClearRect.Height - Self.ClearRect.Top),
              trunc(Self.ClearRect.Width),
              trunc(Self.ClearRect.HEight));


    UseColor := cc(Color);
    glClearColor(UseColor.Red,UseColor.Green,UseColor.Blue,UseColor.Alpha);
    glClearDepth(0);

    If Self.FrameBuffer = 0 Then Begin
      glClear(GL_COLOR_BUFFER_BIT);
    End Else Begin
      glDrawBuffer(GL_COLOR_ATTACHMENT0);
      glClear(GL_COLOR_BUFFER_BIT  or GL_DEPTH_BUFFER_BIT);

      glDrawBuffer(GL_COLOR_ATTACHMENT1);
      glClear(GL_COLOR_BUFFER_BIT);

      glDrawBuffer(GL_COLOR_ATTACHMENT2);
      glClearColor(0,0,0,1-Self.GlobalLight);
      glClear(GL_COLOR_BUFFER_BIT);

      glDrawBuffer(GL_COLOR_ATTACHMENT0);
    End;

    glDisable(GL_SCISSOR_TEST);


  end;


Procedure pglRenderTarget.Clear(Color: pglColorF);

Var
UseColorI: pglColorI;
	Begin

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

  End;


Procedure pglRenderTarget.SetClearColorBuffers(Enable: Boolean);
  Begin
    Self.pClearColorBuffers := Enable;
  End;


Procedure pglRenderTarget.SetClearDepthBuffer(Enable: Boolean);
  Begin
    Self.pClearDepthBuffer := Enable;
  End;


Procedure pglRenderTarget.SetClearAllBuffers(Enable: Boolean);
  Begin
    Self.pClearColorBuffers := Enable;
    Self.pClearDepthBuffer := Enable;
  End;


Procedure pglRenderTarget.SetColorValues(inVals: pglColorI);
  Begin
    Self.ColorVals := ColorItoF(inVals);
  End;

Procedure pglRenderTarget.SetColorValues(inVals: pglColorF);
  Begin
    Self.ColorVals := inVals;
  End;

Procedure pglRenderTarget.SetColorOverlay(inVals: pglColorI);
  Begin
    Self.ColorOverlay := ColorItoF(inVals);
  End;

Procedure pglRenderTarget.SetColorOverlay(inVals: pglColorF);
  Begin
    Self.ColorOverlay := inVals;
  End;

Procedure pglRenderTarget.DrawLastBatch();
  Begin
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
  End;


Procedure pglRenderTarget.DrawRectangleBatch();

Var
TempVer: pglVectorQuad;

  Begin

    If Self.Rectangles.Count = 0 Then Exit;

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


  End;

Procedure pglRenderTarget.DrawCircleBatch();

Var
IndirectBuffer: pglElementsIndirectBuffer;

  Begin

    If Self.Circles.Count = 0 Then Exit;

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
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0, SizeOf(pglVectorQuad) * Self.Circles.Count,@Self.Circles.Vector);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER, 0, SizeOf(pglCircleDescriptor) * Self.Circles.Count, Self.Circles.Data);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, Self.Buffers.CurrentSSBO.Buffer);

    CircleProgram.Use();

    gluniform1f(PGLGetUniform('planeWidth'),Self.Width);
    glUniform1f(PGLGetUniform('planeHeight'),Self.Height);

//    glDrawElementsIndirect(GL_TRIANGLES,GL_UNSIGNED_INT,@IndirectBuffer);
    glDrawArrays(GL_QUADS, 0, Self.Circles.Count * 4);

    Self.Circles.Count := 0;

    Self.Buffers.InvalidateBuffers();
  End;


Procedure pglRenderTarget.DrawGeometryBatch();
  Begin

    If Self.GeoMetryBatch.Count = 0 Then Exit;

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

  End;


Procedure pglRenderTarget.DrawPointBatch();
Var
IndirectBuffer: pglArrayIndirectBuffer;
  Begin

    If Self.Points.Count = 0 Then Exit;

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

  End;


Procedure pglRenderTarget.DrawLineBatch();
  Begin

  End;


Procedure pglRenderTarget.DrawPolygonBatch();

Var
I: GLInt;
C: ^pglCircleBatch;
IndirectBuffer: pglElementsIndirectBuffer;
  Begin

    If Self.Polys.Count = 0 Then Exit;

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


  End;


{ Circles }

Procedure pglRenderTarget.DrawCircle(Center: pglVector2; inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: pglColorF; FadeToOpacity: GLFloat = 1);
Var
Radius: GLFloat;
I: Long;
Cir: pglCircleDescriptor;
Pos: PByte;
Ver: pglVectorQuad;

  Begin

    If (Self.DrawState <> 'Circle') or (Self.Circles.Count >= High(Self.Circles.Vector)) Then Begin
      Self.DrawLastBatch();
    End;

    Self.DrawState := 'Circle';

    Center.X := Center.X + Self.DrawOffset.X;
    Center.Y := Center.Y + Self.DrawOffSet.Y;
    Cir.Center := Center;
    Cir.Width := inWidth;
    Cir.BorderWidth := inBorderWidth;
    Cir.FillColor := inFillColor;
    Cir.BorderColor := inBorderColor;

    If FadeToOpacity < 1 Then BEgin
      Cir.Fade := Vec4(1,FadeToOpacity,0,0);
    End Else Begin
      Cir.Fade := Vec4(0,1,0,0);
    End;

    Pos := Self.Circles.Data + (Self.Circles.Count * SizeOf(Cir));
    Move(Cir,Pos[0],SizeOf(pglCircleDescriptor));

    Radius := inWidth / 2;
    Ver[0] := Vec2((-Radius + Center.X), (Radius + Center.Y));
    Ver[1] := Vec2((Radius + Center.X),  (Radius + Center.Y));
    Ver[2] := Vec2((Radius + Center.X),  (-Radius + Center.Y));
    Ver[3] := Vec2((-Radius + Center.X),  (-Radius + Center.Y));

    For I := 0 to 3 Do Begin
      Ver[I].Scale(Self.Width, Self.Height);
    End;

    Self.Circles.Vector[Self.Circles.Count] := Ver;

    inc(Self.Circles.Count);

  End;

Procedure pglRenderTarget.DrawCircle(CenterX, CenterY, inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: pglColorI);
  Begin
    Self.DrawCircle(Vec2(CenterX,CenterY),inWidth,InBorderWidth,ColorItoF(inFillColor), ColorItoF(inBorderColor));
  End;

Procedure pglRenderTarget.DrawCircle(CenterX, CenterY, inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: pglColorF);
  Begin
    Self.DrawCircle(Vec2(CenterX,CenterY),inWidth,inBorderWidth,inFillColor,inBorderColor);
  End;

Procedure pglRenderTarget.DrawCircle(Center: pglVector2; inWidth, inBorderWidth: GLFloat; inFillColor, inBorderColor: pglColorI);
  Begin
    Self.DrawCircle(Center,inWidth,inBorderWidth,ColorItoF(inFillColor), ColorItoF(inBorderColor));
  End;


{ Geometry }

Procedure pglRenderTarget.DrawEllipse(Center: pglVector2; XLength,YLength,Angle: GLFloat; Color: pglColorI);
Var
X,Y: GLFloat;
UseAngle,CheckAngle,AngleInc: GLFloat;
Dist: GLFloat;
PointCount: GLInt;
Points: Array of pglVector3;
Circ: GLFloat;
A,B,H: GLFloat;
I: GLint;
Ptr: PByte;
UseColor: pglColorF;

  Begin

    If (Self.DrawState <> 'Geometry') or (Self.GeoMetryBatch.Count >= 500) Then Begin
      Self.DrawLastBatch();
    End;

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

    For I := 1 to PointCount - 1  Do Begin

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

    End;


    // Move Vertex Data into data buffer
    Ptr := Self.GeoMetryBatch.Data;
    Ptr := Ptr + Self.GeoMetryBatch.DataSize;
    Move(Points[0],Ptr[0],SizeOf(pglVector3) * PointCount);
    Inc(Self.GeoMetryBatch.DataSize, SizeOf(pglVector3) * PointCount );

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

  End;


Procedure pglRenderTarget.DrawGeometry(Points: array of pglVector2; Color: Array of pglColorF);
Var
UsePoints: Array of pglVector3;
UseColor: Array of pglColorF;
I,X,Y: Long;
LowX,HighX,LowY,HighY: GLFloat;
Ptr: PByte;

  Begin

    If (Self.DrawState <> 'Geometry') or (Self.GeoMetryBatch.Count >= 500) Then Begin
      Self.DrawLastBatch();
    End;

    Self.DrawState := 'Geometry';

    SetLength(UsePoints,Length(Points));

    For I := 0 to High(UsePoints) Do Begin
      UsePoints[i] := Vec3(Points[i].X, Points[i].Y,Self.GeoMetryBatch.Count);
    End;

    Ptr := Self.GeoMetryBatch.Data;
    Ptr := Ptr + Self.GeoMetryBatch.DataSize;
    Move(UsePoints[0],Ptr[0],SizeOf(pglVector3) * Length(UsePoints));
    Inc(Self.GeoMetryBatch.DataSize, SizeOf(pglVector3) * Length(UsePoints));

    If Length(Color) <> Length(Points) Then Begin
      SetLength(UseColor,Length(Points));
      For I := 0 to High(UseColor) do Begin
        UseColor[i] := Color[0];
      End;

    End Else Begin
      SetLength(UseColor,Length(Color));
      For I := 0 to High(Color) Do Begin
        UseColor[i] := Color[i];
      End;
    End;

    Ptr := Self.GeoMetryBatch.Color;
    Ptr := Ptr + Self.GeoMetryBatch.ColorSize;
    Move(UseColor[0],Ptr[0],SizeOf(pglColorF) * Length(UseColor));
    Inc(Self.GeoMetryBatch.ColorSize, SizeOf(pglColorF) * Length(UseColor));

    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].Count := Length(UsePoints);
    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].InstanceCount := 1;
    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].First := Self.GeoMetryBatch.Next;
    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].BaseInstance := 0;

    Inc(Self.GeoMetryBatch.Count);
    Inc(Self.GeoMetryBatch.Next, Length(UsePoints));

  End;


Procedure pglRenderTarget.DrawRegularPolygon(NumVertices: GLInt; Center: pglVector2; Radius: Single; Angle: Single; Color: pglColorI);
Var
PointCount: GLInt;
Points: Array of pglVector3;
I: Long;
X,Y: GLFloat;
UseAngle,AngleInc: GLFloat;
Ptr: PByte;
UseColor: pglColorF;

  Begin

    If (Self.DrawState <> 'Geometry') or (Self.GeoMetryBatch.Count >= 500) Then Begin
      Self.DrawLastBatch();
    End;

    Self.DrawState := 'Geometry';

    PointCount := NumVertices + 2;
    SetLength(Points,PointCount);

    UseAngle := Angle - (Pi/2);
    AngleInc := (Pi*2) / NumVertices;

    Points[0].X := Center.X;
    Points[0].Y := Center.Y;
    Points[0].Z := Self.GeoMetryBatch.Count;

    For I := 1 to NumVertices Do Begin
      Points[i].X := Center.X + (Radius * Cos(UseAngle));
      Points[i].Y := Center.Y + (Radius * Sin(UseAngle));
      Points[i].Z := Self.GeoMetryBatch.Count;
      UseAngle := UseAngle + AngleInc;
    End;

    Points[High(Points)] := Points[1];

    // Move Points to buffer
    Ptr := Self.GeoMetryBatch.Data;
    Ptr := Ptr + Self.GeoMetryBatch.DataSize;
    Move(Points[0],Ptr[0],SizeOf(pglVector3) * PointCount);
    Inc(Self.GeoMetryBatch.DataSize,SizeOf(pglVector3) * PointCount);

    // Move Color to Buffer
    UseColor := CC(Color);
    Ptr := Self.GeoMetryBatch.Color;
    Ptr := Ptr + Self.GeoMetryBatch.ColorSize;
    Move(UseColor,Ptr[0],SizeOf(pglColorF));
    Inc(Self.GeoMetryBatch.ColorSize,SizeOf(pglColorF));

    // Calculate Normals
    For I := 0 to PointCount - 1 Do Begin
      Points[i].Normalize();
    End;

    // Move normals to buffer
    Ptr := Self.GeoMetryBatch.Normals;
    Ptr := Ptr + Self.GeoMetryBatch.NormalsSize;
    Move(Points[0],Ptr[0],SizeOf(pglVector3) * PointCount);
    Inc(Self.GeoMetryBatch.NormalsSize,SizeOf(pglVector3) * PointCount);

    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].Count := PointCount;
    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].InstanceCount := 1;
    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].First := Self.GeoMetryBatch.Next;
    Self.GeoMetryBatch.IndirectBuffers[Self.GeoMetryBatch.Count].BaseInstance := 0;

    Inc(Self.GeoMetryBatch.Count);
    Inc(Self.GeoMetryBatch.Next,PointCount);

  End;



{ Points }

Procedure pglRenderTarget.DrawPoint(Center: pglVector2; Size: GLFloat; inColor: pglColorF);

Var
Pos: PByte;
Vec: pglVector2;

  Begin

    If (Self.DrawState <> 'Point') or (Self.Points.Count >= 6500) Then Begin
      Self.DrawLastBatch();
    End;

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

  End;

Procedure pglRenderTarget.DrawPoint(CenterX,CenterY,Size: GLFloat; inColor: pglColorI);
  Begin
    Self.DrawPoint(Vec2(CenterX,CenterY),Size,ColorItoF(inColor));
  End;

Procedure pglRenderTarget.DrawPoint(CenterX,CenterY,Size: GLFloat; inColor: pglColorF);
  Begin
    Self.DrawPoint(Vec2(CenterX,CenterY),Size,inColor);
  End;

Procedure pglRenderTarget.DrawPoint(Center: pglVector2; Size: GLFloat; inColor: pglColorI);
  Begin
    Self.DrawPoint(Center,Size,ColorItoF(inColor));
  End;


Procedure pglRenderTarget.DrawPoint(PointObject: pglPoint);
  Begin
    Self.DrawPoint(PointObject.pPos,PointObject.pSize,PointObject.pColor);
  End;

  { Rectangle }

Procedure pglRenderTarget.DrawRectangle(Bounds: pglRectF; inBorderWidth: GLFloat; inFillColor,inBorderColor: pglColorF; inCurve: GLFloat = 0);

Var
P: ^Integer;
R: ^pglRectangleBatch;

  Begin

    If (Self.DrawState <> 'Rectangle') or (Self.Rectangles.Count = High(Self.Rectangles.Center)) Then Begin
      Self.DrawLastBatch();
    End;


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

  End;

Procedure pglRenderTarget.DrawRectangle(Center: pglVector2; inWidth,inHeight,inBorderWidth: GLFloat; inFillColor,inBorderColor: pglColorI; inCurve: GLFloat = 0);
  Begin
    Self.DrawRectangle(RectF(Center,inWidth,inHeight),inBorderWidth,ColorItoF(inFillcolor),ColorItoF(inBorderColor),inCurve);
  End;

Procedure pglRenderTarget.DrawRectangle(Center: pglVector2; inWidth,inHeight,inBorderWidth: GLFloat; inFillColor,inBorderColor: pglColorF; inCurve: GLFloat = 0);
  Begin
    Self.DrawRectangle(RectF(Center,inWidth,inHeight),inBorderWidth,inFillcolor,inBorderColor,inCurve);
  End;

Procedure pglRenderTarget.DrawRectangle(Bounds: pglRectF; inBorderWidth: GLFloat; inFillColor,inBorderColor: pglColorI; inCurve: GLFloat = 0);
  Begin
    Self.DrawRectangle(Bounds,inBorderWidth,ColorItoF(inFillColor),ColorItoF(inBorderColor),inCurve);
  End;


{     LINE       }




Procedure pglRenderTarget.DrawLine2(P1,P2: pglVector2; Width,BorderWidth: GLFloat; FillColor,BorderColor: pglColorF; SmoothEdges: Boolean = False);

Var
C,U: GLUInt;
P: GLUInt;
I: GLUInt;
Angle: Single;
Distance: Double;
TempPoints: pglVectorQuad;
OrgP1,OrgP2: pglVector2;

  Begin

    If (Self.DrawState <> 'Line') or (Self.LineBatch.Count >= 400) Then Begin
      Self.DrawLastBatch();
    End;

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

    For I := 0 to 3 Do Begin
      Self.LineBatch.Normal[P + I] := Self.LineBatch.Points[P + I];
      If (I = 0) or (I = 3) Then Begin
        Self.LineBatch.Normal[P + I].Normalize(OrgP1);
      end Else Begin
        Self.LineBatch.Normal[P + I].Normalize(OrgP2);
      End;

      Self.LineBatch.Points[P + I].Scale(Self.Width,Self.Height);
    End;

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
    If Width > 2 Then Begin

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


      For I := 0 to 3 Do Begin
        Self.LineBatch.Normal[P + I] := Self.LineBatch.Points[P + I];
        Self.LineBatch.Normal[P + I].Normalize(OrgP2);
        Self.LineBatch.Points[P + I].Scale(Self.Width,Self.Height);
      End;

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


      For I := 0 to 3 Do Begin
        Self.LineBatch.Normal[P + I] := Self.LineBatch.Points[P + I];
        Self.LineBatch.Normal[P + I].Normalize(OrgP1);
        Self.LineBatch.Points[P + I].Scale(Self.Width,Self.Height);
      End;

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


    End;

  End;


Procedure pglRenderTarget.DrawLineBatch2();

Var
I,Z: Long;
X,Y: GLFloat;

  Begin

    If Self.LineBatch.Count = 0 Then Exit;

    Self.MakeCurrentTarget();
    Self.Buffers.Bind;

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(pglVector2) * Self.LineBatch.PointCount,@Self.LineBatch.Points);
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
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(pglShapeDesc) * Self.LineBatch.Count,@Self.LineBatch.Shape);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,2,Self.Buffers.CurrentSSBO.Buffer);

    LineProgram.Use();

    glMultiDrawArraysIndirect(GL_QUADS,@Self.LineBatch.ShapeBuffer,Self.LineBatch.Count,0);

    Self.LineBatch.Count := 0;
    Self.LineBatch.PointCount := 0;

    Self.Buffers.InvalidateBuffers();

  End;

Procedure pglRenderTarget.DrawLine(P1,P2: pglVector2; Width,BorderWidth: GLFloat; FillColor, BorderColor: pglColorF);

Var
P: ^Integer;
C: ^pglPolygonBatch;
Ver: Array [0..4] of pglVector2;
Length: GLFloat;
Angle: GLFloat;
Point1,Point2: TPoint;
Radius: GLFloat;
I: GLInt;

  Begin

    If Self.DrawState <> 'Polygon' Then Begin
      Self.DrawLastBatch();
    end;

    Self.DrawState := 'Polygon';

    If Self.Polys.ShapeCount >= 500 Then Begin
      Self.DrawPolygonBatch();
    End;

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

    For I := 0 to 3 Do begin
      C.Vector[P^] := Ver[I + 1];
      C.Color[P^] := FillColor;
      inc(Self.Polys.Count);
    End;

    Inc(Self.Polys.ElementCount,6);

  End;


{    SPRITE      }


Procedure pglRenderTarget.DrawSprite(Var Sprite: pglSprite);

Var
I,R: GLInt;
C: ^Integer;
Slot: Integer;
Mat: pglMatrix2;
Ver: pglVectorQuad;

  Begin

    If (Self.DrawState <> 'Sprite') or (Self.TextureBatch.SlotsUsed = 32) or (Self.TextureBatch.Count = 1000) Then Begin
      Self.DrawSpriteBatch();
    End;

    Self.DrawState := 'Sprite';

    Slot := 0;

    // Look for empty slot or slot that matches texture
    For I := 0 to High(self.TextureBatch.TextureSlot) Do Begin
      If Self.TextureBatch.TextureSlot[i] = 0 Then Begin
        Slot := I;
        Self.TextureBatch.TextureSlot[Slot] := Sprite.pTexture.Handle;
        Inc(Self.TExtureBatch.SlotsUsed);
        Break;
      End Else If Self.TextureBatch.TextureSlot[i] = Integer(Sprite.pTexture.Handle) Then Begin
        Slot := I;
        Break;
      End;
    end;

    C := @Self.TextureBatch.Count;
    Self.TextureBatch.MaskColor[c^] := Sprite.MaskColor;
    Self.TextureBatch.Opacity[c^] := Sprite.Opacity;
    Self.TextureBatch.ColorVals[c^] := Sprite.ColorValues;
    Self.TextureBatch.Overlay[c^] := Sprite.ColorOverlay;
    Self.TextureBatch.GreyScale[c^] := BoolToInt(Sprite.GreyScale);
    Self.TextureBatch.SlotUsing[c^] := Slot;
    Self.TextureBatch.TexCoords[c^] := Sprite.Cor;

    If Sprite.Flipped = True Then Begin
      FlipPoints(Self.TextureBatch.TexCoords[c^]);
    End;
    If Sprite.Mirrored = True Then Begin
      MirrorPoints(Self.TextureBatch.TexCoords[c^]);
    End;

    Sprite.UpdateVertices();
    Ver := Sprite.Ver;

    // Account for skew
    If Sprite.pTopSkew <> 0 Then Begin
      Ver[0].X := Ver[0].X + Sprite.pTopSkew;
      Ver[1].X := Ver[1].X + Sprite.pTopSkew;
    End;
    If Sprite.pBottomSkew <> 0 Then Begin
      Ver[2].X := Ver[2].X + Sprite.pBottomSkew;
      Ver[3].X := Ver[3].X + Sprite.pBottomSkew;
    End;
    If Sprite.pLeftSkew <> 0 Then Begin
      Ver[0].Y := Ver[0].Y + Sprite.pLeftSkew;
      Ver[3].Y := Ver[3].Y + Sprite.pLeftSkew;
    End;
    If Sprite.pRightSkew <> 0 Then Begin
      Ver[1].Y := Ver[1].Y + Sprite.pRightSkew;
      Ver[2].Y := Ver[2].Y + Sprite.pRightSkew;
    End;

    // Account for Stretch
    If Sprite.pLeftStretch <> 0 Then Begin
      Ver[0].Y := Ver[0].Y - Sprite.pLeftStretch / 2;
      Ver[3].Y := Ver[3].Y + Sprite.pLeftStretch / 2;
    End;
    If Sprite.pTopStretch <> 0 Then Begin
      Ver[0].X := Ver[0].X - Sprite.pTopStretch / 2;
      Ver[1].X := Ver[1].X + Sprite.pTopStretch / 2;
    End;
    If Sprite.pRightStretch <> 0 Then Begin
      Ver[1].Y := Ver[1].Y - Sprite.pRightStretch / 2;
      Ver[2].Y := Ver[2].Y + Sprite.pRightStretch / 2;
    End;
    If Sprite.pBottomStretch <> 0 Then Begin
      Ver[3].X := Ver[3].X - Sprite.pBottomStretch / 2;
      Ver[2].X := Ver[2].X + Sprite.pBottomStretch / 2;
    End;


    RotatePoints(Ver,Sprite.Origin,Sprite.Angle);

    For R := 0 to 3 Do Begin
      Ver[r].Translate(Sprite.Bounds.X + Self.DrawOffset.X, Sprite.Bounds.Y + Self.DrawOffSet.Y);
      Ver[r].Scale(Self.Width,Self.Height);
    End;

    Self.TextureBatch.Vertices[c^] := Ver;
    Inc(Self.TextureBatch.Count);
  End;


Procedure pglRenderTarget.DrawSpriteBatch();

Var
I: Long;
List: Array [0..31] of GLInt;
IndirectBuffer: pglElementsIndirectBuffer;
Buffs: Array [0..1] of glEnum;

  Begin

    If Self.TextureBatch.Count = 0 Then Exit;

    IndirectBuffer.Count := Self.TextureBatch.Count * 6;
    IndirectBuffer.InstanceCount := 1;
    Indirectbuffer.FirstIndex := 0;
    IndirectBuffer.BaseVertex := 0;
    IndirectBuffer.BaseInstance := 1;

    Self.MakeCurrentTarget;
    Self.Buffers.Bind;



    If Self.DrawShadows = true Then Begin
      Buffs[0] := GL_COLOR_ATTACHMENT0;
      glEnable(GL_DEPTH_TEST);
      glDepthFunc(GL_ALWAYS);
      glDepthMask(GL_TRUE);
      glDrawBuffers(1,@Buffs);
    End Else Begin
      glDrawBuffer(GL_COLOR_ATTACHMENT0);
    End;

    glEnable(GL_SCISSOR_TEST);
    glScissor(trunc(Self.ClipRect.Left), trunc(Self.Height - Self.ClipRect.Height - Self.ClipRect.Top),
      trunc(Self.ClipRect.Width),trunc(Self.ClipRect.Height));

    For I := 0 to High(Self.TextureBatch.TextureSlot) Do Begin
      If Self.TextureBatch.Textureslot[i] <> 0 Then Begin
        PGL.BindTexture(I,Self.TextureBatch.TextureSlot[i]);
      End;
      List[i] := i;
    End;


    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(pglVectorQuad) * Self.TextureBatch.Count,@Self.TextureBatch.Vertices);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(pglVectorQuad) * Self.TextureBatch.Count,@Self.TextureBatch.TexCoords);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(GLInt) * Self.TextureBatch.Count,@Self.TextureBatch.SlotUsing);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,4,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(pglColorF) * Self.TextureBatch.Count,@Self.TextureBatch.MaskColor);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,5,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(GLFloat) * Self.TextureBatch.Count,@Self.TextureBatch.Opacity);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,6,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(pglColorF) * Self.TextureBatch.Count,@Self.TextureBatch.ColorVals);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,7,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(Self.Buffers.GetNextSSBO);
    Self.Buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(pglColorF) * Self.TextureBatch.Count,@Self.TextureBatch.Overlay);
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

  End;



Procedure pglRenderTarget.DrawLight(Center: pglVector2; Radius,Radiance: GLFloat; Color: pglColorI);
Var
P: Integer;
C: ^pglLightBatch;

  Begin

    If Self.DrawState <> 'Light' Then Begin
      Self.DrawLastBatch();
    End;

    If Self.Lights.Count >= 500 Then Begin
      Self.DrawLightBatch();
//      Exit;
    End;

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
  End;

Procedure pglRenderTarget.DrawLightCircle(Center: pglVector2; Color: pglColorI; Radiance,Radius: GLFloat);

var
Pi8: single;
UseAngle: Single;
I: Long;
  Begin

    UseAngle := 0;
    Pi8 := (Pi * 2) / 8;

    For I := 0 to 7 Do Begin
      Self.DrawLightFan(Center,Color,Radiance,Radius,UseAngle,pi8);
      UseAngle := UseAngle + pi8;
    End;

  End;

Procedure pglRenderTarget.DrawLightFan(Center: pglVector2; Color: pglColorI; Radiance: GLFloat; Radius,Angle,Spread: GLFloat);

Var
C: Integer; // Pointer to count of lights
I: Long;
Point: Array [0..2] of pglVector2;

  Begin

    If (Self.DrawState <> 'Light Polygon') or (Self.LightPolygons.Count = 50) then Begin
      Self.DrawLastBatch();
    End;

    Self.DrawState := 'Light Polygon';

    C := Self.LightPolygons.Count;

    Center.Translate(Self.DrawOffset.X, Self.DrawOffset.Y);

    Point[0] := Center;
    Point[1].X := Center.X + ((Radius * 1.1) * Cos(Angle - (Spread / 2)));
    Point[1].Y := Center.Y + ((Radius * 1.1) * Sin(Angle - (Spread / 2)));
    Point[2].X := Center.X + ((Radius * 1.1) * Cos(Angle + (Spread / 2)));
    Point[2].Y := Center.Y + ((Radius * 1.1) * Sin(Angle + (Spread / 2)));

    For I := 0 to 2 Do Begin
      Self.LightPolygons.Points[(C * 3) + i] := Point[i];
    End;

    Self.LightPolygons.Center[C] := Point[0];
    Self.LightPolygons.Color[C] := cc(Color);
    Self.LightPolygons.Radius[C] := Radius;
    Self.LightPolygons.Radiance[C] := Radiance;

    Inc(Self.LightPolygons.Count);

  end;


Procedure pglRenderTarget.DrawLightFanBatch();

Var
I,Z: Long;
Elements: Array [0..1000] of GLUInt;
CurEl: GLUInt;
IndirectBuffer: pglArrayIndirectBuffer;

  Begin

    If Self.LightPolygons.count = 0 Then Exit;

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
    Self.buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(pglVector2) * ((Self.LightPolygons.Count) * 3),@Self.LightPolygons.Points);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindSSBO(0);
    Self.buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(pglVector2) * Self.LightPolygons.Count,@Self.LightPolygons.Center);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,2,Self.Buffers.CurrentSSBO.Buffer);

    Self.Buffers.BindSSBO(1);
    Self.buffers.CurrentSSBO.SubData(GL_SHADER_STORAGE_BUFFER,0,SizeOf(pglColorF) * Self.LightPolygons.Count,@Self.LightPolygons.Color);
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

  End;


Procedure pglRenderTarget.DrawLightBatch();

Var
CheckVar: GLUInt;
IndirectBuffer: pglElementsIndirectbuffer;
  Begin

    If Self.Lights.Count = 0 Then Exit;

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

  End;


Procedure pglRenderTarget.ApplyLights();

Var
Ver,Cor: pglVectorQuad;

  Begin

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


  End;


Procedure pglRenderTarget.DrawText(Text: pglText);
Var
SendBounds: pglRectF;
SendText: String;
ReturnSmoothing: Boolean;
LineCount: GLint;
I: Long;

  Begin

    If Text.MultiLine = False Then Begin
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

    End;

  End;


Procedure pglRenderTarget.DrawText(Text: String; Font: pglFont; Size: GLInt; Position: pglVector2; BorderSize: GLUInt; Color,BorderColor: pglColorI; Shadow: Boolean = False);
  Begin
    Self.DrawTextString(Text,Font,Size,glDrawMain.RectFWH(Position.X,Position.Y,-1,-1),BorderSize,Color,BorderColor,False,cc(pgl_empty), cc(pgl_empty),0,0,Shadow);
  End;



Procedure pglRenderTarget.DrawTextString(Text: String; Font: pglFont; Size: GLInt; Bounds: pglRectF;
  BorderSize: GLUInt; Color,BorderColor: pglColorI; UseGradient: Boolean; GradientLeft: pglColorF;
  GradientRight: pglColorF; GradientXOffset: glFloat; Angle: GLFloat = 0; Shadow: Boolean = False);


Var
TextWidth,TextHeight: GLFloat;
TextBounds: pglVectorQuad;
CharQuad: Array of pglVectorQuad;
TexQuad: Array of pglVectorQuad;
CurPos: pglVector2;
CurChar: ^pglCharacter;
CurQuad: ^pglVectorQuad;
UseColor: pglColorF;
I,R: GLInt;
BreakLoc: GLInt;
BreakPos: Array of GLInt;
Cur: GLInt;
AdjPer: GLFloat;
AdjSize: pglVector2;
UseAtlas: ^pglAtlas;
RotBounds: pglRectF;
RotPoints: Array [0..3] of pglVector2;
Lines,Chars: GLInt;
TargetVar: GLEnum;
Ibuffer: pglElementsIndirectBuffer;
StartQuad, QuadLength: GLint;
Buffer: Array of GLUByte;

  Begin

    DrawLastBatch();

    UseAtlas := @Font.Atlas[Font.ChooseAtlas(Size)];
    Size := UseAtlas.FontSize;

    // Adjust percentage for varying font sizes
    AdjPer := Size / UseAtlas.FontSize;

    // look for line breaks
    Cur := 1;

    While Cur < Length(Text) Do Begin

      BreakLoc := Pos(sLineBreak,Text,Cur);
      If BreakLoc <> 0 Then Begin
        SetLength(BreakPos,Length(BreakPos) + 1);
        BreakPos[High(BreakPos)] := BreakLoc;
        Cur := BreakLoc + 1;
        Text := text.Replace(sLineBreak,'',[]);
      End Else Begin
        Break;
      End;

    End;



    TextHeight := ((UseAtlas.TotalHeight * AdjPer) * (Length(BreakPos) + 1)) + ((BorderSize * 2) * (Length(BreakPos) + 1));
    RotBounds.Width := 0;
    RotBounds.Height := 0;
    TextWidth := 0;
    Lines := 1;

    If Bounds.Width <> -1 Then Begin
      TextWidth := Bounds.Width;
    End;

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

    for I := 1 to Length(Text) Do Begin

      if Length(BreakPos) <> 0 Then Begin
        For R := 0 to high(BreakPos) Do Begin
          if I = BreakPos[R] Then Begin
            CurPos.y := CurPos.y + (UseAtlas.TotalHeight * AdjPer);
            Lines := Lines + 1;
            CurPos.X := BorderSize;
          End;
        End;
      End;

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

      If Bounds.Width = -1 Then Begin
        If CurPos.X > TextWidth Then Begin
          TextWidth := CurPos.X;
        end;
      End;

      QuadLength := QuadLength + 1;
      If QuadLength = 500 Then Begin
        pglTempBuffer.SetClipRect(RectFWH(0,0,TextWidth,TextHeight));
        Self.pTextParams.Width := trunc(TextWidth);
        Self.DrawTextCharacters(Copy(CharQuad,StartQuad,QuadLength),Copy(TexQuad,StartQuad,QuadLength),trunc(TextWidth),trunc(TextHeight));
        StartQuad := StartQuad + QuadLength;
        QuadLength := 0;
      End;


    End;

    If QuadLength > 0 Then Begin
      pglTempBuffer.SetClipRect(RectFWH(0,0,TextWidth,TextHeight));
      Self.pTextParams.Width := trunc(TextWidth);
      Self.DrawTextCharacters(Copy(CharQuad,StartQuad,QuadLength),Copy(TexQuad,StartQuad,QuadLength),trunc(TextWidth),trunc(TextHeight));
    End;

    // Apply Rotation

    RotBounds := glDrawMain.RectFWH(Bounds.Left,Bounds.Top,TextWidth,TextHeight);

    If Angle <> 0 Then Begin
      pglTempBuffer.Rotate(Angle);
      RotPoints[0] := Vec2(RotBounds.Left,RotBounds.Top);
      RotPoints[1] := Vec2(RotBounds.Right,RotBounds.Top);
      RotPoints[2] := Vec2(RotBounds.Right,RotBounds.Bottom);
      RotPoints[3] := Vec2(RotBounds.Left,RotBounds.Bottom);
      RotatePoints(RotPoints,Vec2(RotBounds.X,RotBounds.Y),pglTempBuffer.Angle);
      RotBounds := PointsToRectF(RotPoints);
    End;

    If RotBounds.Width < TextWidth Then Begin
      RotBounds.Width := TextWidth;
    End;

    If RotBounds.Height < TextHeight Then Begin
      RotBounds.Height := TextHeight;
    End;

    RotBounds.Update(FROMCENTER);

    // If No Border, apply shadow and smoothing if needed, then display to Destination
    if BorderSize >= 0 Then begin

      If Shadow = True Then Begin
        pglTempBuffer.SetColorValues(Color3i(0,0,0));
        pglTempBuffer.SetColorOverlay(Color3i(50,50,50));
        pglTempBuffer.SetOpacity(0.5);
        pglTempBuffer.StretchBlt(Self,RotBounds.Left - 5,Rotbounds.Top + 5,RotBounds.Width,RotBounds.Height,
      (TextWidth / 2) - (RotBounds.Width / 2),(TextHeight / 2) - (RotBounds.Height / 2),RotBounds.Width,RotBounds.Height);

        pglTempBuffer.SetColorValues(Color3i(255,255,255));
        pglTempBuffer.SetColorOverlay(Color3i(0,0,0));
        pglTempBuffer.SetOpacity(1);
      End;

      If Self.TextSmoothing = True Then Begin
        pglTempBuffer.Smooth(glDrawMain.RectF(0,0,pglTempBuffer.Width,pglTempBuffer.Height),pgl_Empty);
      End;


      pglTempBuffer.StretchBlt(Self,RotBounds.Left,RotBounds.Top,RotBounds.Width,RotBounds.Height,
        (TextWidth / 2) - (RotBounds.Width / 2),(TextHeight / 2) - (RotBounds.Height / 2),Rotbounds.Width,RotBounds.Height);

      pglTempBuffer.SetRotation(0);
      Exit;
    End;


  End;


Procedure pglRenderTarget.DrawTextCharacters(CharQuads,TexQuads: Array of pglVectorQuad; TextWidth,TextHeight: GLUInt);

Var
Param: pglTextFormat;
UseColor: pglColorF;
IBuffer: pglElementsIndirectBuffer;

  Begin

    Param := Self.pTextParams;

    pglTempBuffer.MakeCurrentTarget();

    Self.Buffers.Bind();

    PGL.BindTexture(0,Param.Font.Atlas[Param.AtlasIndex].Texture);

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(pglVectorQuad) * Length(CharQuads),@CharQuads);
    glEnableVertexAttribArray(0);
    glVertexAttribPOinter(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(pglVectorQuad) * Length(TexQuads),@TexQuads);
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
  End;


Procedure pglRenderTarget.Swirl(Target: pglRenderTarget; DestRect,SourceRect: pglRectF);

Var
NewVer,NewCor: pglVectorQuad;

  Begin

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
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(pglVectorQuad),@NewVer[0]);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(2);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(pglVectorQuad),@NewCor[0]);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    SwirlProgram.Use();

    glUniform1i(PGLGetUniform('tex'),0);
    glUniform1f(PGLGetUniform('planeWidth'),Self.Width);
    glUniform1f(PGLGetUniform('planeHeight'),Self.Height);
    glUniform2f(PGLGetUniform('inCenter'),SourceRect.X, SourceRect.Y);

    glDrawArrays(GL_QUADS,0,4);


  End;

Procedure pglRenderTarget.Pixelate(PixelRect: pglRectF; PixelSize: GLFloat = 2);

Var
NewVer,NewCor: pglVectorQuad;
checkvar: GLInt;

  Begin

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
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(pglVectorQuad),@NewVer[0]);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(2);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(pglVectorQuad),@NewCor[0]);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));


    PixelateProgram.Use();

    glUniform1i(PGLGetUniform('tex'),0);
    glUniform1f(PGLGetUniform('planeWidth'),Self.Width);
    glUniform1f(PGLGetUniform('planeHeight'),Self.Height);
    glUniform1f(PGLGetUniform('PixelSize'),PixelSize);

    glDrawArrays(GL_QUADS,0,4);



  End;


Procedure pglRenderTarget.Smooth(Area: pglRectF; IgnoreColor: pglColorI);

Var
NewVer,NewCor: pglVectorQuad;
CheckVar: Cardinal;
UseColor: pglColorF;
Buffer: Array of Byte;
TempTex: GLUint;

  Begin

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
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(pglVectorQuad),@NewVer[0]);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    Self.Buffers.BindVBO(Self.Buffers.GetNextVBO);
    Self.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(pglVectorQuad),@NewCor[0]);
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

End;


Procedure pglRenderTarget.DrawStatic(Area: pglRectF);

Var
Ver: Array [0..3] of pglVector2;
I,Z: Long;

  Begin

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

  End;


Procedure pglRenderTarget.StereoScope(Area: pglRectF; OffSet: pglVector2);
Var
Ver: pglVectorQuad;
Cor: pglVectorQuad;

  Begin

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

  End;


Procedure pglRenderTarget.FloodFill(StartCoord: pglVector2; Area: pglRectF);
Var
Ver,Cor: pglVectorQuad;

  Begin

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

  End;


///////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// pglRenderTexture /////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
Constructor pglRenderTexture.Create(inWidth: Integer; inHeight: Integer; BitCount: GLInt = 32);
Var
I: GLInt;
CheckVar: glEnum;

  Begin
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

    if CheckVar <> GL_FRAMEBUFFER_COMPLETE Then Begin
      pglAddError('FRAMEBUFFER INCOMPLETE');
      pglReportErrors;
    end;

    glBindFrameBuffer(GL_FRAMEBUFFER,0);

    // Set 2D non-smooth texture as default;
    Self.Texture := Self.Texture2d;

    Self.FillEBO;

    PGLMatrixScale(Self.Scale,Self.Width,Self.Height);
    Self.Opacity := 1;

    PGL.AddRenderTexture(Self);
  End;


Procedure pglRenderTexture.Rotate(byAngle: Single);
  Begin
    Self.Angle := Self.Angle + byAngle;
    PGLMatrixRotation(Self.Rotation,Self.Angle,0,0);
  End;


Procedure pglRenderTexture.SetRotation(toAngle: Single);
  Begin
    Self.Angle := toAngle;
    PGLMatrixRotation(Self.Rotation,Self.Angle,0,0);
  End;


Procedure pglRenderTexture.SetPixelSize(P: Integer);
  Begin
    Self.pPixelSize := P;
  End;

Procedure pglRenderTexture.SetOpacity(Val: Single);
  Begin
    Self.Opacity := val;
  End;


Procedure pglRenderTexture.SetSize(W,H: GLUInt);

Var
Buffs: Array [0..1] of GLEnum;
CheckVar: GLEnum;
Buff: GLEnum;

  Begin

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
  End;


Procedure pglRenderTexture.SetNearestFilter();
  Begin
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
  End;


Procedure pglRenderTexture.SetLinearFilter();
  Begin
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
  End;



Procedure pglRenderTexture.Blt(Dest: pglRenderTarget; destX, destY, destWidth, destHeight, srcX, srcY: GLFloat);
  Begin
    Self.Blt(Dest, RectIWH(DestX, DestY, DestWidth, DestHEight), RectIWH(srcX, srcY, DestWidth, DestHeight));
  End;

Procedure pglRenderTexture.Blt(Dest: pglRenderTarget; DestRect: pglRectI; SourceRect: pglRectI);
  Begin
    Dest.MakeCurrentTarget();
    glBindFrameBuffer(GL_READ_FRAMEBUFFER, Self.FrameBuffer);
    glBindFrameBuffer(GL_DRAW_FRAMEBUFFER, Dest.FrameBuffer);
    glBlitFrameBuffer(SourceRect.Left, SourceRect.Bottom, SourceRect.Right, SourceRect.Top,
      DestRect.Left, DestRect.Bottom, DestRect.Right, DestRect.Top, GL_COLOR_BUFFER_BIT, GL_NEAREST);

    glBindFrameBuffer(GL_FRAMEBUFFER, Self.FrameBuffer);
  End;

Procedure pglRenderTexture.StretchBlt(Dest: pglRenderTarget; destX, destY, destWidth, destHeight, srcX,srcY,srcWidth,srcHeight: GLFloat);
Var
DestVer: pglVectorQuad; // Screen Coordinates of Destination
DestCor: pglVectorQuad; // Texture Coordinates of Destination
SourceCor: pglVectorQuad; // Texture Coordinates of Source
Rot: pglMatrix4;

SourceBounds,DestBounds: pglRectI;

  Begin

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

  End;

Procedure pglRenderTexture.StretchBlt(Dest: pglRenderTarget; destRect,srcRect: pglRectI);
  Begin
    Self.StretchBlt(Dest,destRect.Left,destRect.Top,destRect.Width,destRect.Height,srcRect.Left,srcRect.Top,srcRect.Width,srcRect.Height);
  End;

Procedure pglRenderTexture.StretchBlt(Dest: pglRenderTarget; destRect,srcRect: pglRectF);
  Begin
    Self.StretchBlt(Dest,destRect.Left,destRect.Top,destRect.Width,destRect.Height,srcRect.Left,srcRect.Top,srcRect.Width,srcRect.Height);
  End;


Procedure pglRenderTexture.BlendBlt(Dest: pglRenderTarget; destX, destY, destWidth, destHeight, srcX,srcY,srcWidth,srcHeight: GLFloat);
Var
NewCor: pglVectorQuad;
NewVer: pglVectorQuad;
SourceCor: pglVectorQuad;
SourceRect,DestRect: pglRectF;
Rot: pglMatrix4;

  Begin

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

  End;


Procedure pglRenderTexture.BlendBlt(Dest: pglRenderTarget; DestRect: pglRectF; SourceRect: pglRectF);
  Begin
    Self.BlendBlt(Dest,DestRect.Left,DestRect.Top,DestRect.Width,DestRect.HEight,SourceREct.Left,SourceRect.Top,SourceRect.Width,SourceRect.Height);
  End;


Procedure pglRenderTexture.CopyBlt(Dest: pglRenderTarget; destX, destY, destWidth, destHeight, srcX,srcY,srcWidth,srcHeight: GLFloat);
Var
NewVer: pglVectorQuad;
SourceCor: pglVectorQuad;
SourceRect,DestRect: pglRectF;
Rot: pglMatrix4;

  Begin

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

    If destWidth < 0 Then Begin
      MirrorPoints(NewVer);
    End;

    If destHeight < 0 Then Begin
      FlipPoints(NewVer);
    End;

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

  End;


Procedure pglRenderTexture.CopyBlt(Dest: pglRenderTarget; DestRect,SourceRect: pglRectF);

  Begin
    Self.CopyBlt(Dest,DestRect.Left,DestRect.Top,DestRect.Width,DestRect.Height,SourceRect.Left,SourceRect.Top,SourceRect.Width,SourceRect.Height);
  End;


Procedure pglRenderTexture.SaveToFile(FileName: string; Channels: Integer = 4);
Var
Succeed: LongBool;
Pixels: Array of Byte;
Format: glEnum;
FileChar: pglCharArray;
  Begin


    glBindFrameBuffer(GL_FRAMEBUFFER,Self.FrameBuffer);
    glBindTexture(GL_TEXTURE_2D,Self.Texture);
    SetLength(Pixels,(Self.Width * Self.Height) * 4);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);

    FileChar := PGLStringtoChar(FileName);
    Succeed := stbi_write_bmp(pAnsiChar(FileChar),Self.Width,Self.Height,4,Pointer(Pixels));

  end;


Procedure pglRenderTexture.SetMultiSampled(MultiSampled: Boolean);
  Begin
    Self.pisMultiSampled := MultiSampled;
  End;


Procedure pglRenderTexture.SetDrawBuffers(Buffers: array of GLEnum);
Var
I: Long;
Buffs: GLEnum;

  Begin

    Buffs := GL_COLOR_ATTACHMENT0 + Buffers[0];

    If Length(Buffers) > 1 Then Begin
      For I := 1 to High(Buffers) Do Begin
        Buffs:= Buffs or (GL_COLOR_ATTACHMENT0 + Buffers[i]);
      End;
    End;

    Self.MakeCurrentTarget();
    glDrawBuffers(Length(Buffers), @Buffs);
  End;

Procedure pglRenderTexture.SetPixelFormat();
  Begin

    Case Self.pBitDepth of

      32:
        Begin
          Self.pPixelFormat := GL_RGBA;
        End;

      24:
        Begin
          Self.pPixelFormat := GL_RGB;
        End;

      16:
        Begin
          Self.pPixelFormat := GL_RGB4;
        End;

      8:
        Begin
          Self.pPixelFormat := GL_RED;
        End;

    End;

  End;


Procedure pglRenderTexture.ChangeTexture(Texture: pglTexture);
Var
Buffs: GLInt;
  Begin

    Self.Texture := Texture.Handle;
    Self.pWidth := Texture.Width;
    Self.pHeight := Texture.Height;

    Buffs := GL_COLOR_ATTACHMENT0;

    Self.MakeCurrentTarget();
    glInvalidateFrameBuffer(GL_FRAMEBUFFER,1,@Buffs);
    glFrameBufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,Texture.Handle,0);
    glDrawBuffer(GL_COLOR_ATTACHMENT0);

  End;


Procedure pglRenderTexture.RestoreTexture();

Var
Pixels: PByte;
Pixels2: PByte;
PLoc1,PLoc2: Pointer;
PSize: GLint;
I,Z: Long;
OutPar: GLInt;
OldTexture: GLUint;
W,H: GLint;

  Begin

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

    For I := 0 to H - 1 Do Begin
      Move(Pixels[0],Pixels2[0],W*4);
      Inc(Pixels,W*4);
      Dec(Pixels2,W*4);
    End;

    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,W,H,0,GL_RGBA,GL_UNSIGNED_BYTE,PLoc2);

    Pixels := PLoc1;
    Pixels2 := PLoc2;

    FreeMemory(Pixels);
    FreeMemory(Pixels2);

  End;





///////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// pglRenderMap /////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

Constructor pglRenderMap.Create(Width,Height,SelectionWidth,SelectionHeight,ViewPortWidth,ViewPortHeight: GLUInt);

Var
ReturnTexture: GLUInt;
I: Long;

  Begin

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

    // Set 2D non-smooth texture as default;
    Self.Texture := Self.Texture2d;

    Self.FillEBO;

    PGLMatrixScale(Self.Scale,SelectionWidth,SelectionHeight);

    // Set dimensions of memory image, selection rect, and view port
    Self.pTotalWidth := Width;
    Self.pTotalHeight := Height;
    Self.pSelectionRect := RectIWH(0,0,SelectionWidth,SelectionHeight);
    Self.pViewPort := RectIWH(0,0,ViewPortWidth,ViewPortHeight);

    // allocate memory and obtain handle for image
    Self.Data := GetMemory((Self.pTotalWidth * Self.pTotalHeight) * 4);

    SetLength(Self.ScanLine,Self.pTotalHeight);

    For I := 0 to High(Self.Scanline) Do Begin
      Self.ScanLine[i] := GetMemory(Self.pTotalWidth * 4);
    End;

  End;


Procedure pglRenderMap.SetSelectionRectSize(Width: Cardinal; Height: Cardinal);
Var
ReturnTexture: GLUInt;

  Begin

    Self.WriteSelectionToImage();

    Self.MakeCurrentTarget();
    ReturnTexture := PGL.TexUnit[0];
    PGL.BindTexture(0,Self.Texture2D);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,Width,Height,0,GL_RGBA,GL_UNSIGNED_BYTE,nil);

    PGL.BindTexture(0,ReturnTexture);

  End;


Procedure pglRenderMap.MoveSelectionRect(ByX: Cardinal; ByY: Cardinal);

  Begin

    Self.DrawLastBatch();
    Self.WriteSelectionToImage();

    // Move it
    Self.SelectionRect.Translate(ByX,ByY);

    // Keep it in bounds
    If Self.SelectionRect.Left < 0 Then Begin
      Self.pSelectionRect.Left := 0;
      Self.pSelectionRect.Update(FROMLEFT);
    End;

    If Self.SelectionRect.Right > integer(Self.TotalWidth) Then Begin
      Self.pSelectionRect.Right := Self.TotalWidth - 1;
      Self.pSelectionRect.Update(FROMRIGHT);
    End;

    If Self.SelectionRect.Top < 0 Then Begin
      Self.pSelectionRect.top := 0;
      Self.pSelectionRect.Update(FROMTOP);
    End;

    If Self.SelectionRect.Bottom > integer(Self.TotalHeight) Then Begin
      Self.pSelectionRect.Bottom := Self.TotalHeight - 1;
      Self.pSelectionRect.Update(FROMBOTTOM);
    End;


    Self.GetSelectionFromImage(Self.SelectionRect.Left,Self.SelectionRect.Top);

  End;


Procedure pglRenderMap.SetSelectionRect(Left: Cardinal; Top: Cardinal);
  Begin

    If Left + Cardinal(Self.SelectionRect.Width) > Self.TotalWidth Then Begin
      Left := (Self.TotalWidth - 1) - Cardinal(Self.SelectionRect.Width);
    End;

    If Top + Cardinal(Self.SelectionRect.Height) > Self.TotalHeight Then Begin
      Top := (Self.TotalHeight - 1) - Cardinal(Self.SelectionRect.Height);
    End;

    Self.pSelectionRect.Left := Left;
    Self.pSelectionRect.Update(FROMLEFT);
    Self.pSelectionRect.Top := Top;
    Self.pSelectionRect.Update(FROMTOP);

  End;


Procedure pglRenderMap.UpdateImageSelection();
  Begin
    Self.DrawLastBatch();
    Self.WriteSelectionToImage();
  End;

Procedure pglRenderMap.SetViewPortSize(Width: Cardinal; Height: Cardinal);
  Begin

  End;


Procedure pglRenderMap.MoveViewPort(ByX: Cardinal; ByY: Cardinal);
  Begin

  End;


Procedure pglRenderMap.SetViewPort(Left: Cardinal; Top: Cardinal);
  Begin

  End;


Procedure pglRenderMap.WriteSelectionToImage;

Var
Pixels: Array of pglColorI; // array of pixels to write to memory
CurPixel: GLUInt; // Current starting location of Pixels to write from
DestPtr: PByte; // Points to current address in Data being written to
CurLine: GLUInt; // Current Scan Line of Image
ReturnTexture: GLUInt; // the original texture bound to texture unit 0
I: GLUInt;

  Begin

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

    For I := 1 to Self.SelectionRect.Height Do Begin
      Move(Pixels[CurPixel],Pointer(DestPtr)^,SizeOf(pglColorI) * Self.SelectionRect.Width);
      CurPixel := CurPixel + Cardinal(Self.SelectionRect.Width);

      If CurLine < Cardinal(Self.SelectionRect.Bottom - 1) then Begin
        Inc(CurLine);
        DestPtr := Self.ScanLine[CurLine];
      End;
    End;


    // Return Original Texture to unit 0
    PGL.BindTexture(0,ReturnTexture);

  End;


Procedure pglRenderMap.GetSelectionFromImage(X: Cardinal; Y: Cardinal);

Var
Pixels: Array of pglColorI; // array of pixels to Set to Texture
CurPixel: GLUInt; // Current starting location of Pixels to write from
SourcePtr: PByte; // Points to current address in Data being read from
CurLine: GLUInt; // Current Scan Line of Image
ReturnTexture: GLUInt; // the original texture bound to texture unit 0
I: GLUInt;

  Begin

    // Adjust X and Y if the selection would fall outside the bounds of the data
    If X + Cardinal(Self.SelectionRect.Width) > Self.TotalWidth Then Begin
      X := Self.TotalWidth - Cardinal(Self.SelectionRect.Width);
    End;

    If Y + Cardinal(Self.SelectionRect.Height) > Self.TotalHeight Then Begin
      Y := Self.TotalHeight - Cardinal(Self.SelectionRect.Height);
    End;

    // Get image data from texture
    SetLength(Pixels,Self.SelectionRect.Width * Self.SelectionRect.Height);

    // Row By Row, extract pixels from data

    CurLine := Self.SelectionRect.Top;
    SourcePtr := Self.ScanLine[CurLine];


    CurPixel := 0;

    For I := 1 to Self.SelectionRect.Height Do Begin
      Move(SourcePtr,Pixels[CurPixel],SizeOf(pglColorI) * Self.SelectionRect.Width);
      CurPixel := CurPixel + Cardinal(Self.SelectionRect.Width);

      If CurLine < Cardinal(Self.SelectionRect.Bottom - 1) Then Begin
        Inc(CurLine);
        SourcePtr := Self.ScanLine[CurLine];
      End;

    End;

    // Update texture with pixels
    ReturnTexture := PGL.TexUnit[0];
    PGL.BindTexture(0,Self.TExture2D);
    glTexSubImage2D(GL_TEXTURE_2D,0,0,0,Self.SelectionRect.Width,Self.SelectionRect.Height,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);

    // return oringal texture
    PGL.BindTexture(0,ReturnTexture);

  End;


Function pglRenderMap.RetrievePixelsFromMemory(SRect: pglRectI): ColorIArray;
Var
Pixels: ColorIArray;
CurPixel: GLUInt; // Current starting location of Pixels to write from
SourcePtr: PByte; // Points to current address in Data being read from
CurLine: GLUInt; // Current Scan Line of Image
ReturnTexture: GLUInt; // the original texture bound to texture unit 0
I: GLUInt;

  Begin

    // Adjust X and Y if the selection would fall outside the bounds of the data
//    If SRect.Right >= Integer(Self.TotalWidth) Then Begin
//      SRect.Left := Self.TotalWidth - SRect.Width;
//      SRect.Update(FROMLEFT);
//    End;
//
//    If SRect.Bottom >= Integer(Self.TotalHeight) Then Begin
//      SRect.Top := Self.TotalHeight - SRect.Height;
//      SRect.Update(FROMTOP);
//    End;


    // Get image data from texture
    SetLength(Pixels, (SRect.Width * SRect.Height));

    // Row By Row, extract pixels from data

//    SourcePtr := Self.Data;
//    SourcePtr := SourcePtr + (((Self.pTotalWidth) * Cardinal(SRect.Top)) * 4) + (SRect.Left * 4);

    CurLine := SRect.Top + (SRect.Height - 1);
    SourcePtr := Self.ScanLine[CurLine];

    CurPixel := 0;

    For I := 1 to SRect.Height Do Begin
      Move(Pointer(SourcePtr)^, Pixels[CurPixel], 16 * SRect.Width);
      CurPixel := CurPixel + Cardinal(SRect.Width);
//      SourcePtr := SourcePtr + (Self.TotalWidth * 4);
      If CurLine > 0 Then Begin
        Dec(CurLine);
        SourcePtr := Self.ScanLine[CurLine];
      End;

    End;


    Result := Pixels;

  End;


///////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// pglWindow /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
constructor pglWindow.Create(inWidth,inHeight: GLInt);

Var
I: Long;

	Begin
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

  End;


Procedure pglWindow.Close();
  Begin
    pglRunning := false;
    PGL.Context.Close();
  End;


Procedure pglWindow.DisplayFrame();
  Begin
    SwapBuffers(PGL.Context.DC);
  End;


Procedure pglWindow.onResize;

Var
Per: GLFloat;
NewWidth,NewHeight: GLInt;

  Begin

  End;


Procedure pglWindow.SetSize(W,H: GLUInt);
  Begin
    PGL.Context.SetSize(W,H,True);
    Self.pWidth := PGL.Context.Width;
    Self.pHeight := PGL.Context.Height;
  End;

Procedure pglWindow.SetFullScreen(isFullScreen: Boolean);
  Begin
    Self.pFullScreen := isFullScreen;
    PGL.Context.SetFullScreen(isFullScreen);
  End;

Procedure pglWindow.SetTitleBar(hasTitleBar: Boolean);
  Begin
    Self.pTitleBar := hasTitleBar;
    PGL.Context.SetHasCaption(hasTitleBar);
  End;

Procedure pglWindow.SetTitle(inTitle: String);
  Begin
    Self.pTitle := inTitle;
    PGL.Context.SetTitle(inTitle);
  End;

Procedure pglWindow.SetScreenPosition(X,Y: GLInt);
  Begin
    PGL.Context.SetPosition(X,Y);
  End;

Procedure pglWindow.CenterInScreen();
  Begin
    PGL.Context.SetPosition(trunc((PGL.Context.ScreenWidth / 2) - (PGL.Context.Width / 2)),
      trunc((PGL.Context.ScreenHeight / 2) - (PGL.Context.Height / 2)));
  End;

Procedure pglWindow.Maximize();
  Begin
    PGL.Context.Maximize();
    PGL.Window.pWidth := PGL.Context.Width;
    PGL.Window.pHeight := PGL.Context.Height;
  End;

Procedure pglWindow.Restore();
  Begin
    PGL.Context.Restore();
    PGL.window.pWidth := PGL.Context.Width;
    PGL.Window.pHeight := PGL.Context.Height;
  End;

Procedure pglWindow.Minimize();
  Begin
    PGL.Context.Minimize();
    PGL.Window.pWidth := PGL.Context.Width;
    PGL.Window.pHeight := PGL.Context.Height;
  End;

Procedure pglWindow.SetDisplayRect(Rect: pglRectI; ScaleOnResize: Boolean);
  Begin
    Self.pDisplayRect.Width := Rect.Width;
    Self.pDisplayRect.Height := Rect.Height;
    Self.pDisplayRect.Left := Rect.Left;
    Self.pDisplayRect.Top := Rect.Top;
    Self.pDisplayRect.SetTopLeft(Rect.Left, Rect.Top);

    Self.pDisplayRectScale := ScaleOnResize;
    Self.pDisplayRectUsing := True;
  End;


Procedure pglWindow.SetIcon(Image: pglImage);
  Begin
    PGL.Context.SetIconFromBits(Image.Handle, Image.Width, Image.Height, 32);
  End;

Procedure pglWindow.SetIcon(FileName: String; TransparentColor: pglColorI);
  Begin
    PGL.Context.SetIconFromFile(FileName);
  End;


///////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// pglTileMap ///////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////




///////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// pglImage /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////


Procedure pglImage.DefineData();
Var
I: Int32;
  Begin
    Self.pDataSize := (Self.Width * Self.Height) * 4;
    Self.DataEnd := Self.Handle;
    Self.DataEnd := Self.DataEnd + Self.DataSize;

    // Get pointers to the start of each row
    SetLength(Self.RowPtr, Self.Height);
    For I := 0 to High(Self.RowPtr) do Begin
      Self.RowPtr[i] := Self.Handle;
      Self.RowPtr[i] := Self.RowPtr[i] + ((Self.Width * I) * 4);
    End;
  End;

Constructor pglImage.Create(Width: GLUint = 1; Height: GLUint = 1);
  Begin
    Self.isValid := True;
    Self.pWidth := Width;
    Self.pHeight := Height;
    Self.pHandle := AllocMem((Width * Height) * 4);
    Self.DefineData;
  End;

Constructor pglImage.CreateFromFile(FileName: String);
Var
SourcePointer: PByte;
  Begin
    SourcePointer := stbi_load(PAnsiChar(AnsiString(FileName)),Self.pWidth,Self.pHeight,Self.pChannels,4);
    Self.pHandle := GetMemory((Self.pWidth * Self.pHeight) * 4);
    Move(SourcePointer[0], Self.pHandle[0], (Self.pWidth * Self.pHeight) * 4);
    stbi_image_free(SourcePointer);
    Self.IsValid := True;
    Self.DefineData;
  End;

Constructor pglImage.CreateFromMemory(Source: Pointer; Width,Height: NativeUInt; Size: NativeUInt);
  Begin

    Self.IsValid := True;
    Self.pWidth := Width;
    Self.pHeight := Height;
    Self.pChannels := 4;
    Self.pHandle := GetMemory(GLInt(Size));
    Move(Source^,Self.Handle^,Size);

    Self.DefineData();
  End;

Destructor pglImage.Destroy();
  Begin
    Self.Delete();
    Inherited;
  End;

Procedure pglImage.Delete();
Var
Ptr: PByte;
RetVal: Integer;
  Begin
    If Self.pHandle <> nil Then Begin
      Try
        RetVal := FreeMemory(Self.pHandle);
        Self.pHandle := Nil;
      Except
        Self.SaveToFile(pglEXEPath + 'Fail Test.bmp');
      End;
    End;
  End;

Procedure pglImage.Clear();
  Begin

    Self.pHandle := nil;
    Self.isValid := FAlse;
    Self.pWidth := 0;
    Self.pHeight := 0;
    Self.pChannels := 0;
    Self.Data := nil;
  End;

Procedure pglImage.LoadFromFile(FileName: AnsiString);
Var
BufferSize: GLInt;
SourcePointer: PByte;
CurPointer: PByte;
I: GLInt;
ByteData: pglColorI;

  Begin

    Self.Clear();

    Self.pHandle := stbi_load(PAnsiChar(FileName),Self.pWidth,Self.pHeight,Self.pChannels,4);
    Self.IsValid := True;

    // Set data array length and move image data 4-bytes at a time
    SetLength(Self.Data,Width * Height);
    BufferSize := (Width * Height) * 4;
    SourcePointer := Self.Handle;

    For I := 0 to BufferSize -1 Do Begin

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

    End;

    SourcePointer := nil;
    CurPointer := nil;

  End;

Procedure pglImage.LoadFromMemory(Source: Pointer; Width,Height: GLUInt);
  Begin

    If Self.Handle <> nil Then Begin
      stbi_image_free(Self.Handle);
      Self.pHandle := Nil;
      Self.IsValid := False;
    End;

    Self.IsValid := True;
    Self.pChannels := 4;
    Self.pWidth := Width;
    Self.pHeight := Height;

    Self.pHandle := GetMemory((Width * Height) * 4);
    Move(Pointer(Source)^,Pointer(Self.handle)^,(Width * Height) * 4);

  End;


Procedure pglImage.CopyFromImage(Var Source: pglImage);
Var
BufferSize: GLInt;
I: GLInt;
SourcePointer: PByte;
CurPointer: PByte;
ByteData: pglColorI;

  Begin

    If Source.isValid = False Then Begin
      pglAddError('Could not copy from image. Source is not valid!');
      Exit;
    End;

    BufferSize := (Source.Width * Source.Height * 4);
    Self.pHandle := GetMemory(BufferSize);
    Move(Pointer(Source.Handle)^,Pointer(Self.Handle)^,BufferSize);
    SetLength(Self.Data,Source.Width * Source.Height);

    For I := 0 to High(Source.Data) Do Begin
      Self.Data[i] := Source.Data[i];
    End;

    Self.pWidth := Source.Width;
    Self.pHeight := Source.Height;
    Self.pChannels := Source.Channels;

    Self.isValid := true;

    Self.DefineData();
  End;


Procedure pglImage.CopyFromImage(Var Source: pglImage; SourceRect, DestRect: pglRectI);

Var
OrgPtr, DestPtr: PByte;
OrgLoc, DestLoc: GLInt;
I,Z: Long;
X,Y: Long;
WidthRatio, HeightRatio: GLFloat;

  Begin
    OrgPtr := Source.Handle;
    DestPtr := Self.Handle;

    If (SourceRect.Width <> DestRect.Width) and (SourceRect.Height <> DestRect.Height) Then Begin
      // If Rect dimensions are not the same, must account for stretch/shrink, copy one pixel at a time

      // Set ratios between widths and heights
      WidthRatio := SourceRect.Width / DestRect.Width;
      HeightRatio := SourceRect.Height / DestRect.Height;

      For Z := 0 to DestRect.Height - 1 Do Begin
        For I := 0 to DestRect.Width - 1 Do Begin

          X := trunc(SourceRect.Left + (I * WidthRatio));
          Y := trunc(SourceRect.Top + (Z * HeightRatio));
          OrgLoc := ((Y * Source.Width) + X) * 4;
          DestLoc := ((Z * Self.Width) + I) * 4;
          Move(OrgPtr[OrgLoc], DestPtr[DestLoc], 4);

        End;
      End;

    End Else Begin
      // If rects are the same size, copy over one entire row at a time
      For Z := 0 to DestRect.Height - 1 Do begin
        OrgLoc := (((SourceRect.Top + Z) * Source.Width) + SourceRect.Left) * 4;
        DestLoc := ((Z * Self.Width) + DestRect.Left) * 4;
        Move(OrgPtr[OrgLoc], DestPtr[DestLoc], 4 * (DestRect.Width));
      End;

    End;

    OrgPtr := Nil;
    DestPtr := Nil;

  End;


Constructor pglImageHelper.CreateFromTexture(Var Source: pglTexture);
Var
Pixels: Array of pglColorI;
Failed: Boolean;

  Begin
    Self.isValid := true;
    Self.pWidth := Source.Width;
    Self.pHeight := Source.Height;
    Self.pHandle := GetMemory((Source.Width * Source.Height) * 4);
    Self.DefineData;

    SetLength(Pixels, Self.Width * Self.Height);

    PGL.BindTexture(0,Source.Handle);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Self.pHandle);
    PGL.UnBindTexture(Source.Handle);
  End;


Procedure pglImageHelper.CopyFromTexture(var Source: pglTexture);

Var
Pixels: Array of Byte;

  Begin

    if Source = nil Then Exit;

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

  End;



Procedure pglImage.ReplaceColor(TargetColor: pglColorI; NewColor: pglColorI);
Var
I,Z: GLInt;
Data: Array of pglColorI;
  Begin
    SetLength(Data,(Self.Width * Self.Height) * 4);
    Move(Self.Handle^, Data[0], 4 * (Self.Width * Self.Height));

    For I := 0 to High(Data) Do Begin
      If Data[I].IsColor(TargetColor, 0.1) Then Begin
        Data[i] := NewColor;
      End;
    End;

    Move(Data[0], Self.Handle^, 4 * (Self.Width * Self.Height));
  End;


Procedure pglImage.Darken(Percent: GLFloat);
Var
Ptr: PByte;
Color: pglColorI;
I: Long;
Len: Long;

  Begin
    Len := (Self.Width * Self.Height);
    Ptr := Self.Handle;

    For I := 0 to Len - 1 Do Begin
      Move(Ptr[0],Color,SizeOf(Color));

      If Color.Alpha = 0 Then Begin
        Ptr := Ptr + 4;
        Continue;
      End;

      Color.Red := Trunc(Color.Red * (1 - Percent));
      Color.Blue := Trunc(Color.Blue * (1 - Percent));
      Color.Green := Trunc(Color.Green * (1 - Percent));
      Move(Color,Ptr[0],SizeOf(Color));
      Ptr := Ptr + 4;
    End;
  End;

Procedure pglImage.Brighten(Percent: GLFloat);
Var
Ptr: PByte;
Color: pglColorI;
I: Long;
Len: Long;

  Begin
    Len := (Self.Width * Self.Height);
    Ptr := Self.Handle;

    For I := 0 to Len - 1 Do Begin
      Move(Ptr[0],Color,SizeOf(Color));

      If Color.Alpha = 0 Then Begin
        Ptr := Ptr + 4;
        Continue;
      end;

      Color.Red := ClampIColor(Trunc(Color.Red * (1 + Percent)));
      Color.Blue := ClampIColor(Trunc(Color.Blue * (1 + Percent)));
      Color.Green := ClampIColor(Trunc(Color.Green * (1 + Percent)));
      Move(Color,Ptr[0],SizeOf(Color));
      Ptr := Ptr + 4;
    End;
  End;


Procedure pglImage.AdjustAlpha(Alpha: Single; IgnoreTransparent: Boolean = True);
Var
Ptr: PByte;
I, Len: Long;
AVal: Byte;

  Begin
    Ptr := Self.Handle;
    Ptr := Ptr + 3;
    Len := (Self.Width * Self.Height);

    For I := 0 to Len - 1 Do Begin
      Move(Ptr[0],AVal,1);

      If IgnoreTransparent = True Then Begin
        If AVal = 0 Then Begin
          Ptr := Ptr + 4;
          Continue;
        End;
      End;

      AVal := trunc(255 * Alpha);
      Move(AVal,Ptr[0],1);
      Ptr := Ptr + 4;
    end;
  End;

Procedure pglImage.ToGreyScale();
Var
I,Len: Long;
Color: pglColorI;
Ptr: PByte;
Max: Byte;

  Begin

    Len := Self.Width * Self.Height;
    Ptr := Self.Handle;

    For I := 0 to Len - 1 Do Begin

      If Ptr[3] = 0 Then Begin
        Inc(Ptr,4);
        Continue;
      End;

      Max := trunc((0.2126 * Ptr[0] + 0.7152 * Ptr[1] + 0.0722 * Ptr[2]));
      Ptr[0] := Byte(Max);
      Ptr[1] := Byte(Max);
      Ptr[2] := Byte(Max);
      Inc(Ptr,4);
    end;

  End;

Procedure pglImage.ToNegative();
Var
I,Len: Long;
Color: pglColorI;
Ptr: PByte;
Max: Byte;

  Begin

    Len := Self.Width * Self.Height;
    Ptr := Self.Handle;

    For I := 0 to Len - 1 Do Begin

      If Ptr[3] = 0 Then Begin
        Inc(Ptr,4);
        Continue;
      End;

      Ptr[0] := 255 - Ptr[0];
      Ptr[1] := 255 - Ptr[1];
      Ptr[2] := 255 - Ptr[2];
      Inc(Ptr,4);
    End;

  End;


Procedure pglImage.Smooth();
Var
I,Z,Len: Long;
X,Y: Long;
Ptr: PByte;
SelfPtr: PByte;
CopyData: PByte;
SamPtr: PByte;
Color: pglColorI;
ComColor: Array [0..3] of Integer;
Sample: Array [0..8] of pglColorI;
CurX, CurY, SamX, SamY: Long;
Count: Long;

  Begin

    If Self.DataSize = 0 Then Exit;

    Len := Self.Width * Self.Height;
    CopyData := GetMemory(Self.DataSize);
    Move(Self.Handle^,CopyData[0],Self.DataSize);
    Ptr := CopyData;
    SelfPtr := Self.Handle;

    For I := 0 to Len - 1 Do Begin
      Move(Ptr[0],Color,4);

      CurY := trunc(I / Self.Width);
      CurX := I - (CurY * Self.Width);

      For X := 0 to 8 Do Begin
        Sample[X] := pgl_empty;
      End;

      Count := 0;

      For X := CurX - 1 to CurX + 1 Do Begin
        For Y := CurY - 1 to CurY + 1 Do Begin

          If (X < 0) And (X >= Self.Width) And (Y < 0) And (Y >= Self.Width) Then Continue;

          SamY := (Y * Self.Width ) * 4;
          SamX := X * 4;
          SamPtr := PByte(Self.Handle) + SamX + SamY;
          Move(SamPtr[0],Sample[Count],4);
          Inc(Count);

        End;
      End;

      Count := 0;

      ComColor[0] := 0;
      ComColor[1] := 0;
      ComColor[2] := 0;
      ComColor[3] := 0;

      for X := 0 to 8 do Begin
        If Sample[X].Alpha <> 0 Then Begin
          Inc(Count);
          ComColor[0] := ComColor[0] + Sample[X].Red;
          ComColor[1] := ComColor[1] + Sample[X].Green;
          ComColor[2] := ComColor[2] + Sample[X].Blue;
        End;
      End;


      If Count <> 0 Then Begin
        Color.Red := trunc(ComColor[0] / Count);
        Color.Green := trunc(ComColor[1] / Count);
        Color.Blue := trunc(ComColor[2] / Count);
        Move(Color,SelfPtr[0],4);
      End;

      Inc(Ptr,4);
      Inc(SelfPtr,4);

    end;

    FreeMem(CopyData);
    Ptr := nil;
    SelfPtr := nil;

  End;


Procedure pglImage.SaveToFile(FileName: string);
  Begin
    stbi_write_bmp(PAnsiChar(AnsiString(FileName)),Self.Width,Self.Height,4,Self.Handle);
  End;


Procedure pglImage.Resize(NewWidth, NewHeight: GLUint);

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
OrgRows: Array of Array of pglColorI;
NewRows: Array of Array of pglColorI;
WidthRatio, HeightRatio: GLFloat;
WidthMax, HeightMax: GLUint;
I,Z: GLInt;

  Begin

    // Record original sizes of image and size of it's data, Get new data size
    OrgWidth := Self.Width;
    OrgHeight := Self.Height;
    OrgDataSize := (OrgWidth * OrgHeight) * 4;
    NewDataSize := (NewWidth * NewHeight) * 4;

    // Get the ratios between the org and new width and height
    WidthRatio := OrgWidth / NewWidth;
    HeightRatio := OrgHeight / NewHeight;

    // Allocate new memory for a copy of the original data and move it from the handle storage
    // Set Pointers to start of datas
    OrgData := AllocMem(OrgDataSize);
    OrgPtr := OrgData;
    Move(Self.Handle^, OrgData[0], OrgDataSize);

    // Size arrays of pixels to apporpriate sizes for org data and new data
    SetLength(OrgRows, OrgWidth, OrgHeight);
    SetLength(NewRows, NewWidth, NewHeight);

    // Move orgdata to org rows
    OrgLoc := 0;
    For Z := 0 to OrgHeight - 1 Do Begin
      For I := 0 to OrgWidth - 1 Do Begin
        Move(OrgPtr[OrgLoc], OrgRows[I,Z], 4);
        OrgLoc := OrgLoc + 4;
      End;
    End;

    // Move OrgRows to NewRows
    For Z := 0 to NewHeight - 1 Do Begin
      For I := 0 to NewWidth - 1 Do Begin
        NewRows[I,Z] := OrgRows[trunc(I * WidthRatio), trunc(Z * HeightRatio)];
      End;
    end;

    //Replace image handle and move in new data, resize image
    If Self.Handle <> nil Then Begin
        FreeMemory(Self.pHandle);
    End;

    Self.pHandle := GetMemory(NewDataSize);

    NewLoc := 0;
    NewPtr := Self.Handle;
    For Z := 0 to NewHeight - 1 Do Begin
      For I := 0 to NewWidth - 1 Do Begin
        Move(NewRows[I,Z], NewPtr[NewLoc], 4);
        NewLoc := NewLoc + 4;
      End;
    End;

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

  End;


Function pglImage.Pixel(X: Integer; Y: Integer): pglColorI;

Var
IPtr: PByte;

  Begin

    If Self.DataSize = 0 Then Begin
      Result := pgl_Empty;
      Exit;
    End;

    // Read pixels directly from Image memory location
    IPtr := Self.Handle;
    IPtr := IPtr + ((Y * trunc(Self.Width) + X) * 4);

    Move(IPtr[0],Result,4);
  End;


Procedure pglImage.SetPixel(Color: pglColorI; X: Integer; Y: Integer);
Var
IPtr: PByte;
  Begin
    // Write Color directly to image data

    If (X >= Self.Width) or (X < 0) or (Y >= Self.Height) or (Y < 0) Then Exit;

    IPtr := Self.RowPtr[Y] + (X * 4);
    Move(Color, IPtr[0], SizeOf(pglColorI));
  End;

Procedure pglImage.BlendPixel(Color: pglColorI; X: Integer; Y: Integer; SourceFactor: GLFloat);
Var
IPtr: PByte;
ILoc: Integer;
DestColor: pglColorI;
SourceColor: pglColorI;
DestFactor: GLFloat;
  Begin
    // Write Color directly to image data

    If (X >= Self.Width) or (Y >= Self.Height) Then Exit;

    // Get Pointer to Pixel
    IPtr := Self.RowPtr[Y] + (X * 4);

    // Move Current source pixel to cache
    Move(IPtr[0],DestColor,SizeOf(pglColorI));

    // Calc dest factor based on source factor
    DestFactor := 1 - SourceFactor;

    // BLEND IT!
    SourceColor.Red := trunc((Color.Red * SourceFactor) + (DestColor.Red * DestFactor));
    SourceColor.Green := trunc((Color.Green * SourceFactor) + (DestColor.Green * DestFactor));
    SourceColor.Blue := trunc((Color.Blue * SourceFactor) + (DestColor.Blue * DestFactor));
    SourceColor.Alpha := trunc((Color.Alpha * SourceFactor) + (DestColor.Alpha * DestFactor));

    // Move the blended color to pixel
    Move(SourceColor, IPtr[0], SizeOf(pglColorI));
  End;


Procedure pglImage.Pixelate(PixelWidth: GLUint = 2);

Type UColor = Record
  Red,Green,Blue,Alpha: Long;
End;

Var
I,Z,X,Y,R: Long;
CX,CY: Long;
Count: Long;
DrawColor: UColor;
SetColor: pglColorI;
SampleColor: Array of pglColorI;
  Begin

    If PixelWidth < 2 Then Exit;

    SetLength(SampleColor, PixelWidth * PixelWidth);

    For I := 0 to trunc(Self.Width / PixelWidth) Do Begin
      For Z := 0 to trunc(Self.Height / PixelWidth) Do Begin
        CX := I * Integer(PixelWidth);
        CY := Z * Integer(PixelWidth);

        Count := 0;
        For X := 0 to PixelWidth - 1 Do Begin
          For Y := 0 to PixelWidth - 1 Do Begin
            SampleColor[Count] := Self.Pixel(CX + X, CY + Y);
            Inc(Count);
          End;
        End;

        DrawColor.Red := 0;
        DrawColor.Blue := 0;
        DrawColor.Green := 0;
        DrawColor.Alpha := 0;
        SetColor := pgl_black;

        For R := 0 to High(SampleColor) Do Begin
          DrawColor.Red := DrawColor.Red + SampleColor[R].Red;
          DrawColor.Green := DrawColor.Green + SampleColor[R].Green;
          DrawColor.Blue := DrawColor.Blue + SampleColor[R].Blue;
          DrawColor.Alpha := DrawColor.Alpha + SampleColor[R].Alpha;
        End;

        SetColor.Red := trunc(DrawColor.Red / Length(SampleColor));
        SetColor.Green := trunc(DrawColor.Green / Length(SampleColor));
        SetColor.Blue := trunc(DrawColor.Blue / Length(SampleColor));
        SetColor.Alpha := trunc(DrawColor.Alpha / Length(SampleColor));

        For X := 0 to PixelWidth - 1 Do Begin
          For Y := 0 to PixelWidth - 1 Do Begin
            Self.SetPixel(SetColor, CX + X, CY + Y);
          End;
        End;

      End;
    End;

  End;


///////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// pglTexture  ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

Constructor pglTexture.Create(Width: GLUint = 0; Height: GLUint = 0);
  Begin
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
  End;

Constructor pglTexture.CreateFromImage(Image: pglImage);
  Begin

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

  End;


Constructor pglTexture.CreateFromFile(FileName: string);
Var
Data: PByte;
IWidth,IHeight,IChannels: GLInt;

  Begin

    If FileExists(FileName,true) = False Then Begin
      FileName := pglEXEPath + 'InvalidImage.png';
    End;

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

  End;


Constructor pglTexture.CreateFromTexture(Texture: pglTexture);

Var
Pixel: Array of pglColorI;
  Begin

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

  End;


Procedure pglTexture.Delete();
  Begin
    glDeleteTextures(1,@Self.Handle);
    PGL.RemoveTextureObject(Self);
    Self.Free();
  End;


Procedure pglTexture.CheckDefaultReplace();
Var
I: Long;
Col,NewCol: pglColorI;

  Begin

    If Length(PGL.DefaultReplace) = 0 Then Exit;

    For I := 0 to High(PGL.DefaultReplace) Do Begin
      Col := PGL.DefaultReplace[I,0];
      NewCol := PGL.DefaultReplace[I,1];
      Self.ReplaceColors(Col,NewCol,0);
    End;

  End;


Procedure pglTexture.SaveToFile(FileName: String);

Var
Pixels: Array of pglColorI;
FileChar: pglCharArray;

  Begin

    SetLength(Pixels,Self.Width * SElf.Height);
    PGL.BindTexture(0,Self.Handle);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
    PGL.UnbindTexture(Self.Handle);

    FileChar := PGLStringToChar(FileName);
    stbi_write_bmp(PansiChar(AnsiString(Filename)),Self.Width,SElf.HEight,4,Pixels);

  End;


Procedure pglTexture.Smooth(Area: pglRectF; IgnoreColor: pglColorI);
Var
ReturnTexture: GLUInt;
ReturnWidth,ReturnHeight: GLUint;
I,Z,R,T,X,Y,CX,CY: Long;
BlendCount: Long;
Count: Long;
Pixels: Array of pglColorI;
OldPixels: Array of Array of pglColorI;
NewPixels: Array of Array of pglColorI;
NewRed,NewGreen,NewBlue,NewAlpha: Long;
  Begin

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


    For I := 0 to Self.Width - 1 Do Begin
      For Z := 0 to Self.Height - 1 Do Begin
        NewPixels[i,z] := OldPIxels[i,z];
      End;
    End;


    For I := 0 to trunc(area.Width) - 1 Do Begin
      For Z := 0 to trunc(area.Height) - 1 Do Begin

        BlendCount := 0;

        X := trunc(Area.Left) + I;
        Y := trunc(Area.Top) + Z;
        NewRed := 0;
        NewBlue := 0;
        NewGreen := 0;
        NewAlpha := 0;

        For R := -1 to 1 Do Begin
          For T := -1 to 1 Do Begin

            CX := X + R;
            CY := Y + T;

              If CX < 0 Then Begin
                Continue;
              End;
              If CX >= (Integer(Self.Width) - 1) Then Begin
                Continue;
              End;
              If CY < 0 Then Begin
                Continue;
              End;
              if CY >= (Integer(Self.Height) - 1) THen Begin
                Continue;
              End;
              If OldPixels[CX,CY].IsColor(IgnoreColor) Then Begin
                Continue;
              End;

            NewRed := NewRed + OldPixels[CX,CY].Red;
            NewGreen := NewGreen + OldPixels[CX,CY].Green;
            NewBlue := NewBlue + OldPixels[CX,CY].Blue;
            NewAlpha := NewAlpha + OldPixels[CX,CY].Alpha;
            Inc(BlendCount);

          End;
        end;


        If BlendCount > 0 Then Begin
          NewPixels[X,Y].Red := ClampIColor(trunc(NewRed / BlendCount));
          NewPixels[X,Y].Green := ClampIColor(trunc(NewGreen / BlendCount));
          NewPixels[X,Y].Blue := ClampIColor(trunc(NewBlue / BlendCount));
          NewPixels[X,Y].Alpha := ClampIColor(trunc(NewAlpha / BlendCount));
        End;


      End;
    End;

    Count := 0;

    SetLength(Pixels,Self.Width * self.Height);

    For I := 0 to Self.Width - 1 Do Begin
      For Z := 0 to Self.Height - 1 Do Begin

        Pixels[Count] := NewPixels[I,Z];
        Inc(Count);
      End;
    end;

    glTexImage2D(GL_TEXTURE_2D,0,PGL.TextureFormat,Self.Width+1,Self.Height+1,0,PGL.WindowColorFormat,GL_UNSIGNED_BYTE,@Pixels[0]);
    PGL.BindTexture(1,0);




  End;


Procedure pglTexture.ReplaceColors(TargetColors: Array of pglColorI; NewColor: pglColorI; Tolerance: Double = 0);

Var
Pixels: Array of pglColorI;
I,Z: Long;

  Begin

    // Get pixels from texture
    SetLength(Pixels,(Self.Width * Self.Height));
    PGL.BindTexture(0,Self.Handle);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);

    // scan and replace
    For I := 0 to (Self.Width * Self.Height) - 1 Do Begin

      For Z := 0 to High(TargetColors) Do Begin
        If Pixels[i].IsColor(TargetColors[z], Tolerance) Then Begin
          Pixels[i] := NewColor;
        End;
      End;
    End;

    // reinsert colors to texture
    glTexSubImage2D(GL_Texture_2D,0,0,0,Self.Width,Self.Height,GL_RGBA,GL_UNSIGNED_BYTE,@Pixels[0]);

    PGL.BindTexture(0,0);

  End;


Procedure pglTexture.CopyFromData(Data: Pointer; Width,Height: GLInt);
  Begin
    Self.Width := Cardinal(Width);
    Self.Height := Cardinal(Height);
    PGL.BindTexture(0,Self.Handle);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,Width,Height,0,GL_RGBA,GL_UNSIGNED_BYTE,Data);
    PGL.UnbindTexture(Self.Handle);
  End;

Procedure pglTexture.CopyFromTexture(Source: pglTexture; X,Y,Width,Height: GLUInt);

Var
Pixels: Array of Byte;
  Begin

    If X > Source.Width Then Exit;
    If Y > Source.Height Then Exit;

    If X + Width > Source.Width Then Begin
      Width := Source.Width - X;
    end;

    If Y + Height > Source.Height Then Begin
      Height := Source.Height - Y;
    End;


    Self.Width := Width;
    Self.Height := Height;

    SetLength(Pixels,(Width * Height) * 4);

    glTexSubImage2D(GL_TEXTURE_2D,0,X,Y,Width,Height,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
    self.CopyFromData(Pixels,Width,Height);

  End;


Procedure pglTexture.SetSize(Width,Height: GLUint; KeepImage: Boolean = False);

Var
Pixels: Array of Byte;
KeepWidth,KeepHeight: GLUint;

  Begin

    // Cache pixels if keep image
    If KeepImage = True Then Begin
      SetLength(Pixels, (Self.Width * Self.Height) * 4);
      PGL.BindTexture(0,Self.Handle);
      glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
    End;

    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,Width,Height,0,GL_RGBA,GL_UNSIGNED_BYTE,nil);

    // Return image if keep image
    If KeepImage = True Then Begin
      glTexSubImage2D(GL_TEXTURE_2D,0,0,0,Width,Height,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
    End;

    PGL.UnbindTexture(Self.Handle);

  End;


Function pglTexture.Pixel(X: Integer; Y: Integer): pglColorI;

Var
IPtr: PByte;

  Begin
    // TO-DO: Finish
    Result := pgl_empty;


  End;


Function pglTexture.SetPixel(Color: pglColorI; X,Y: Integer): pglColorI;
  Begin
    //TO-DO: Finish
    PGL.BindTexture(0,Self.Handle);
    glTexSubImage2D(GL_TEXTURE_2D, 0,X,Y,1,1,GL_RGBA,GL_UNSIGNED_BYTE,@Color);
  End;

Procedure pglTexture.Pixelate(PixelWidth: GLUint = 2);
Var
TempImage: pglImage;
  Begin
    TempImage := pglImage.CreateFromTexture(Self);
    TempImage.Pixelate(PixelWidth);
    Self.CopyFromData(TempImage.Handle,Self.Width,Self.Height);
    TempImage.Destroy();
  End;


Procedure pglTexture.CopyToImage(Dest: pglImage; SourceRect, DestRect: pglRectI);
Var
I,Z: GLInt;
OrgPixels: Array of pglColorI;
NewPixels: Array of pglColorI;
OrgPixelCount: GLInt;
PixelCount: GLInt;
ImgPtr: PByte;
ImgLoc: GLInt;

  Begin
    // Get All Pixels from texture
    PGL.BindTexture(1,Self.Handle);
    SetLength(OrgPixels, Self.Width * Self.Height);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, OrgPixels);

    // Copy OrgPixels into NewPixels
    SetLength(NewPixels, DestRect.Width * DestRect.Height);
    OrgPixelCount := 0;
    PixelCount := 0;
    For Z := 0 to Self.Height - 1 Do Begin
      For I := 0 to Self.Width - 1 Do Begin

        // If I and Z fall with bounds of the SourceRect, copy it over, keep count of pixels in arrays
        If (I >= SourceRect.Left) and (I <= SourceRect.Right) and (Z >= SourceRect.Top) and (Z <= SourceRect.Bottom) Then Begin
          If PixelCount < Length(NewPixels) Then Begin
            NewPixels[PixelCount] := OrgPixels[OrgPixelCount];
            Inc(PixelCount);
          End;
        End;

        Inc(OrgPixelCount);

      End;
    end;

    // Transfer to Image
    PixelCount := 0;
    ImgPtr := Dest.Handle;
    ImgLoc := 0;

    For Z := 0 to DestRect.Height - 1 Do Begin
      For I := 0 to DestRect.Width - 1 Do Begin
        ImgLoc := ((((DestRect.Top + Z) * Self.Width) + (DestRect.Left + I)) * 4);
        Move(NewPixels[PixelCount], ImgPtr[ImgLoc], 4);
        Inc(PixelCount);
      end;
    End;

  End;


Procedure pglTexture.CopyToAddress(Dest: Pointer);
  Begin
    PGL.BindTexture(0,Self.Handle);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, Dest);
  End;


Procedure pglTexture.SetNearestFilter;
Var
ReturnTexture: GLInt;
  Begin
    ReturnTexture := PGL.TexUnit[0];
    PGL.BindTexture(0,Self.Handle);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    PGL.BindTexture(0,ReturnTexture);
  End;


Procedure pglTexture.SetLinearFilter;
Var
ReturnTexture: GLInt;
  Begin
    ReturnTexture := PGL.TexUnit[0];
    PGL.BindTexture(0,Self.Handle);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    PGL.BindTexture(0,ReturnTexture);
  End;


Procedure pglTextureHelper.CopyFrom(Image: pglImage; X,Y,Width,Height: GLInt);
Var
Pixels: Array of pglColorI;
PixelPos: Long;
IPtr: PByte;
I,Z: Long;

  Begin

    SetLength(Pixels,(Width * HEight));
    PixelPos := 0;

    For I := Y to Height - 1 Do Begin

      IPtr := Image.RowPtr[I];
      IPtr := IPtr + (X * 4);
      Move(Iptr[0],Pixels[PixelPos],Width * 4);

      PixelPos := PixelPos + (Width);


    End;


    PGL.BindTexture(0,Self.Handle);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,Width,Height,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
    PGL.UnBindTexture(Self.Handle);
  End;


Procedure pglTextureHelper.CopyFrom(Texture: pglTexture; X,Y,Width,Height: GLInt);
  Begin
    PGL.BindTexture(0,Self.Handle);
    glTexImage2D(GL_TEXTURE_2D,0,PGL.TextureFormat,Width,Height,0,PGL.WindowColorFormat,GL_UNSIGNED_BYTE,nil);

    glCopyImageSubData(Texture.Handle,GL_TEXTURE_2D,0,X,Y,0,
                       Self.Handle,GL_TEXTURE_2D,0,0,0,0,Width,Height,0);

    pGL.UnbindTexture(Self.Handle);
  End;

Procedure pglTextureHelper.CopyFrom(Sprite: pglSprite; X,Y,Width,Height: GLInt);
Var
CheckVar: GLInt;
  Begin


    PGL.BindTexture(0,self.Handle);
    glTexImage2D(GL_TEXTURE_2D,0,PGL.TextureFormat,Width,Height,0,PGL.WindowColorFormat,GL_UNSIGNED_BYTE,nil);
    PGL.UnbindTexture(self.Handle);

    glCopyImageSubData(Sprite.pTexture.Handle,GL_TEXTURE_2D,0,X,Y,0,
                       Self.Handle,GL_TEXTURE_2D,0,0,0,0,Width,Height,1);

  End;


///////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// pglSprite  /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

Procedure pglSprite.Initialize();
  Begin
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
  End;

Constructor pglSprite.Create();
  Begin
    Self.Initialize();
  End;

Constructor pglSprite.CreateFromTexture(Var Texture: pglTexture);
  Begin
    Self.Initialize();
    Self.SetTexture(Texture);
  End;

Procedure pglSprite.Delete();
  Begin
    glDeleteTextures(1,@Self.ptexture);
    Self.Free();
  End;

Procedure pglSprite.SetDefaults();
  Begin
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
  End;


Procedure pglSprite.SetTexture(Var Texture: pglTexture); Register;
  Begin
    Self.pTextureSize := Vec2(Texture.Width, Texture.Height);
    Self.SetTextureRect(RectIWH(0,0,Self.TextureSize.X,Self.TextureSize.Y));

    Self.pTextureSize.X := Texture.Width;
    Self.pTextureSize.Y := Texture.Height;
    Self.pBounds.Width := Texture.Width;
    Self.pBounds.Height := Texture.Height;
    Self.Bounds.Update(FROMCENTER);
    UpdateVertices();

    Self.pTexture := Texture;
  End;


Procedure pglSprite.SetTexture(Sprite: pglSprite);
  Begin
    Self.pTexture := Sprite.pTexture;
    Self.pTextureSize.X := Sprite.TextureSize.X;
    Self.pTextureSize.Y := Sprite.TextureSize.Y;
    Self.pBounds.Width := Sprite.Width;
    Self.PBounds.Height := Sprite.Height;
    Self.Bounds.Update(FROMCENTER);
    Self.UpdateVertices();
    Self.SetTextureRect(RectIWH(0,0,Self.TextureSize.X,Self.TextureSize.Y));
  End;

Procedure pglSprite.SetCenter(Center: pglVector2); Register;
  Begin
    Self.pBounds.X := Center.X;
    Self.pBounds.Y := Center.Y;
    Self.pBounds.Update(FROMCENTER);
    UpdateVertices();
  End;


Procedure pglSprite.SetTopLeft(TopLeft: pglVector2); Register;
  Begin
    Self.pBounds.SetLeft(TopLeft.X);
    Self.pBounds.SetTop(TopLeft.Y);
    UpdateVertices();
  End;

Procedure pglSprite.Move(X,Y: Single); Register;
  Begin
    Self.pBounds.X := Self.Bounds.X + X;
    Self.pBounds.Y := Self.Bounds.Y + Y;
    Self.pBounds.Update(FROMCENTER);
    UpdateVertices();
  End;


Procedure pglSprite.UpdateVertices(); Register;
  Begin
    // Update Screen Space Vertices
    Self.Ver[0] := Vec2(-Self.Bounds.Width / 2, -Self.Bounds.Height / 2);
    Self.Ver[1] := Vec2(Self.Bounds.Width / 2, -Self.Bounds.Height / 2);
    Self.Ver[2] := Vec2(Self.Bounds.Width / 2, Self.Bounds.Height / 2);
    Self.Ver[3] := Vec2(-Self.Bounds.Width / 2, Self.Bounds.Height / 2);
  End;


Procedure pglSprite.Rotate(Val: Single);
  Begin
    Self.pAngle := Self.pAngle + Val;
    PGLMatrixRotation(Self.Rotation,Self.Angle,Self.Bounds.X,Self.BOunds.Y);
  End;


Procedure pglSprite.SetAngle(Val: Single);
  Begin
    Self.pAngle := Val;
    PGLMatrixRotation(Self.Rotation,Self.Angle,Self.Bounds.X,Self.Bounds.Y);
  End;


Procedure pglSprite.SetOrigin(Center: pglVector2);
  Begin
    Self.pOrigin.X := -(Self.Bounds.X - Center.X);
    Self.pOrigin.Y := -(Self.Bounds.Y - Center.Y);
  End;

Procedure pglSprite.SetFlipped(isFlipped: Boolean);
  Begin
    Self.pFlipped := isFlipped;
  End;

Procedure pglSprite.SetMirrored(isMirrored: Boolean);
  Begin
    Self.pMirrored := isMirrored;
  End;

Procedure pglSprite.SetSkew(Dimension: Integer; Amount: Single);
  Begin

    Case Dimension of

      0:
        Begin
          Self.pLeftSkew := Amount;
        End;

      1:
        Begin
          Self.pTopSkew := Amount;
        End;

      2:
        Begin
          Self.pRightSkew := Amount;
        End;

      3:
        Begin
          Self.pBottomSkew := Amount;
        End;

    End;

  End;

Procedure pglSprite.ResetSkew();
  Begin
    Self.pTopSkew := 0;
    Self.pBottomSkew := 0;
    Self.pLeftSkew := 0;
    Self.pRightSkew := 0;
  End;


Procedure pglSprite.SetStretch(Dimension: Integer; Amount: Single);
  Begin

    Case Dimension of

      0:
        Begin
          Self.pLeftStretch := Amount;
        End;

      1:
        Begin
          Self.pTopStretch := Amount;
        End;

      2:
        Begin
          Self.pRightStretch := Amount;
        End;

      3:
        Begin
          Self.pBottomStretch := Amount;
        End;

    End;

  End;

Procedure pglSprite.ResetStretch();
  Begin
    Self.pTopStretch := 0;
    Self.pLeftStretch := 0;
    Self.pRightStretch := 0;
    Self.pBottomStretch := 0;
  End;


Procedure pglSprite.SetMaskColor(Color: pglColorF);
  Begin
    Self.pMaskColor := Color;
  End;

Procedure pglSprite.SetMaskColor(Color: pglColorI);
  Begin
    Self.pMaskColor := ColorItoF(Color);
  End;

Procedure pglSprite.SetOpacity(val: GLFloat);
  Begin
    Self.pOpacity := ClampFColor(Val);
  End;

Procedure pglSprite.SetColors(Colors: pglColorI);
  Begin
    Self.ColorsArePointer := False;
    Self.pColorValues := cc(Colors);
  End;

Procedure pglSprite.SetColors(Colors: Pointer);
  Begin
    Self.ColorsArePointer := true;
    Self.pColorValuesPointer := Colors;
  End;


Function pglSprite.GetColorValues: pglColorF;
  Begin
    If Self.ColorsArePointer = False Then Begin
      Result := Self.pColorValues;
    End Else Begin
      Result := Self.pColorValuesPointer^;
    End;
  End;

Function pglSprite.GetRectSet(S: Integer): pglRectI;
  Begin
    Result := Self.pRectSet[S];
  End;

Function pglSprite.GetCenter(): pglVector2;
  Begin
    Result := Vec2(Self.Bounds.X,Self.Bounds.Y);
  End;

Function pglSprite.GetTopLeft(): pglVector2;
  Begin
    Result := Vec2(Self.Bounds.X - (Self.Bounds.Width / 2), Self.Bounds.Y - (Self.Bounds.Height / 2));
  End;

Procedure pglSprite.SetOverlay(Colors: pglColorI);
  Begin
    Self.pColorOverlay := cc(Colors);
  End;

Procedure pglSprite.SetGreyScale(Val: Boolean = True);
  Begin
    Self.pGreyScale := Val;
  End;

Procedure pglSprite.ResetColorState();
  Begin
    Self.SetColors(cc(Color4f(1,1,1,1)));
    Self.SetOverlay(CC(Color4f(0,0,0,0)));
    Self.pMaskColor := Color4f(0,0,0,0);
    Self.SetGreyScale(False);
  End;

Procedure pglSprite.SetSize(Width: Single; Height: Single);
  Begin
    Self.pBounds.Width := trunc(Width);
    Self.pBounds.Height := trunc(Height);
    Self.SetCenter(Vec2(Self.Bounds.X,Self.Bounds.Y));
  End;

Procedure pglSprite.ResetScale;
  Begin
    Self.SetSize(Self.TextureRect.Width,Self.TextureRect.Height);
  End;


Procedure pglSprite.SetTextureRect(TexRect: pglRectI);

  Begin

    // Update internal texture use rect

    If TexRect.Right > Self.TextureSize.X Then Begin
      TexRect.Right := trunc(Self.TextureSize.X);
    End;

    If TexRect.Left < 0 Then Begin
      TexRect.Left := 0;
    End;

    If TexRect.Top < 0 Then Begin
      TexRect.Top := 0;
    End;

    If TexRect.Bottom > Self.TextureSize.Y Then Begin
      TexRect.Bottom := trunc(Self.TextureSize.Y);
    End;

    Self.pTextureRect := TexRect;
    Self.SetSize(TexRect.Width,TexRect.Height);

    Self.Cor[0] := Vec2(TexRect.Left / Self.TextureSize.X, TexRect.Top / Self.TextureSize.Y);
    Self.Cor[1] := Vec2(TexRect.Right / Self.TextureSize.X, TexRect.Top / Self.TextureSize.Y);
    Self.Cor[2] := Vec2(TexRect.Right / Self.TextureSize.X, TexRect.Bottom / Self.TextureSize.Y);
    Self.Cor[3] := Vec2(TexRect.Left / Self.TextureSize.X, TexRect.Bottom / Self.TextureSize.Y);

  End;


Procedure pglSprite.SetRectSlot(Slot: GLInt; Rect: pglRectI);
  Begin
    Self.pRectSet[Slot] := Rect;
  End;

Procedure pglSprite.UseRectSlot(Slot: GLInt);
  Begin
    Self.SetTextureRect(Self.RectSet[Slot]);
  End;


Procedure pglSprite.SaveToFile(FileName: string);
Var
Succeed: LongBool;
Pixels: Array of pglColorI;
FileChar: pglCharArray;
  Begin
    SetLength(Pixels, trunc(Self.TextureSize.X) * trunc(Self.TextureSize.Y));
    PGL.BindTexture(0,Self.Texture.Handle);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
    PGL.UnbindTexture(Self.Texture.Handle);
    FileChar := PGLStringToChar(FileName);
    Succeed := stbi_write_bmp(LPCSTR(FileChar),trunc(Self.TextureSize.X),trunc(Self.TextureSize.Y),4,Pixels);
  End;

Function pglSprite.Pixel(X: Integer; Y: Integer): pglColorI;
Var
IPtr: PByte;
  Begin
    // Finish Later
    Result := pgl_empty
  End;


///////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// pglProgram /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

Procedure pglPointCollection.BuildFrom(Texture: pglTexture; X: Cardinal = 0; Y: Cardinal = 0; Width: Cardinal = 0; Height: Cardinal = 0);

Var
Pixels: Array of pglColorI;
I,Z,Count: Long;
ReturnTexture: GLUInt;
ReturnBuffeR: GLUInt;
DestVer: pglVectorQuad;
SourceCor: pglVectorQuad;
SourceRect: pglRectF;

  Begin

    If X > Texture.Width Then X := Texture.Width;
    If Y > Texture.Height Then Y := Texture.Height;

    If (Width = 0) Then Begin
      Width := Texture.Width;
    End;

    If X + Width > Texture.Width Then Begin
      Width := Texture.Width - X;
    End;

    If (Height = 0) Then Begin
      Height := Texture.Height;
    End;

    If Y + Height > Texture.Height Then Begin
      Height := Texture.Height - Y;
    End;

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
    pglTempBuffer.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(pglVectorQuad),@DestVer);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    pglTempBuffer.Buffers.BindVBO(1);
    pglTempBuffer.Buffers.CurrentVBO.SubData(GL_ARRAY_BUFFER,0,SizeOf(pglVectorQuad),@SourceCor);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,0,Pointer(0));

    PixelTransferProgram.Use();

    glUniform1i(PGLGetUniform('tex'),0);

    glDrawArrays(GL_QUADS,0,4);

    PGL.BindTexture(0,pglTempBuffer.Texture);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,Self.Data);
    PGL.BindTexture(0,ReturnTexture);

  End;


Procedure pglPointCollection.BuildFrom(Image: pglImage; X: Cardinal = 0; Y: Cardinal = 0;  Width: Cardinal = 0; Height: Cardinal = 0);
  Begin

  End;


Procedure pglPointCollection.BuildFrom(Sprite: pglSprite; X: Cardinal = 0; Y: Cardinal = 0;  Width: Cardinal = 0; Height: Cardinal = 0);

Var
Pixels: Array of pglColorI;
I,Z,Count: Long;
ReturnTexture: GLUInt;
ReturnBuffeR: GLUInt;
DestVer: pglVectorQuad;
SourceCor: pglVectorQuad;
SourceRect: pglRectF;

  Begin

    If X > Sprite.Width Then X := trunc(Sprite.Width);
    If Y > Sprite.Height Then Y := trunc(sprite.Height);

    If (Width = 0) Then Begin
      Width := trunc(Sprite.Width);
    End;

    If X + Width > sprite.Width Then Begin
      Width := trunc(sprite.Width) - X;
    End;

    If (Height = 0) Then Begin
      Height := trunc(sprite.Height);
    End;

    If Y + Height > sprite.Height Then Begin
      Height := trunc(sprite.Height - Y);
    End;

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

    For I := 0 to Width - 1 Do Begin
      For Z := 0 to Height - 1 Do Begin

        If Self.Point(I,Z).IsColor(Sprite.MaskColor) Then Begin
          Self.Data[(Y * Self.Width) + X] := pgl_Empty;
        End;

      End;
    End;

  End;


Procedure pglPointCollection.BuildFrom(Data: Pointer; Width: Cardinal; Height: Cardinal);

Var
Pixels: Array of pglColorI;
I,Z,Count: Long;
ReturnTexture: GLUInt;
ReturnBuffeR: GLUInt;
DestVer: pglVectorQuad;
SourceCor: pglVectorQuad;
SourceRect: pglRectF;

  Begin



    Self.pWidth := Width;
    Self.pHeight := Height;
    Self.pcount := Width * Height;
    SetLength(Self.Data,Self.Width * self.Height);
    Move(Data,Self.Data,(Width * Height) * 4);
  End;


Procedure pglPointCollection.ReplaceColor(OldColor: pglColorI; NewColor: pglColorI);

Var
I,Z,Count: Long;

  Begin

    For I := 0 to Self.Count - 1 Do Begin
      If Self.Data[I].IsColor(OldColor) Then Begin
        Self.Data[i] := NewColor;
      End;
    End;

  End;


Function pglPointCollection.Point(X: Cardinal; Y: Cardinal): pglColorI;
  Begin
    Result := Self.Data[(Y * Self.Width) + X];
  End;


Function pglPointCollection.Point(N: Cardinal): pglColorI;
  Begin
    Result := Self.Data[N];
  End;


///////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// pglProgram /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

constructor pglProgram.Create(Name: String; VertexShaderPath: String; FragmentShaderPath: String; GeometryShaderPath: String = '');

Var
VerPass: Boolean;
FragPass: Boolean;
GeoPass: Boolean;
ExitMesssage: String;
Err: GLInt;
FileName: String;

  Begin

    Self.ProgramName := Name;

    Self.VertexShader := glCreateShader(GL_VERTEX_SHADER);
    Self.FragmentShader := glCreateShader(GL_FRAGMENT_SHADER);

    If GeometryShaderPath <> '' Then Begin
      Self.GeometryShader := glCreateShader(GL_GEOMETRY_SHADER);
      GeoPass := PGLLoadShader(Self.GeometryShader,String(GeometryShaderPath));
    End;

    VerPass := PGLLoadShader(Self.VertexShader,String(VertexShaderPath));
    FragPass := PGLLoadShader(Self.FragmentShader,String(FragmentShaderPath));

    If (VerPass = False) or (FragPass = False) or ((GeoPass = False) and (GeometryShaderPath <> '')) Then Begin
      PGLAddError('Shader Program ' + string(Name) + ' Creation Failed');
    End;

    Self.ShaderProgram := glCreateProgram();
    glAttachShader(Self.ShaderProgram,Self.VertexShader);
    glAttachShader(Self.ShaderProgram,Self.FragmentShader);

    If GeometryShaderPath <> '' Then Begin
      glAttachShader(Self.ShaderProgram,Self.GeometryShader);
    End;

    glLinkProgram(Self.ShaderProgram);

    Self.Valid := True;

  End;


Procedure pglProgram.Use();

  Begin

    If CurrentProgram = Self Then Exit;

    if Self.Valid = True Then Begin
      glUseProgram(Self.ShaderProgram);
      CurrentProgram := Self;
    End Else Begin
      glUseProgram(0);
      CurrentProgram := nil;
      pglAddError(string('Could not use Shader Program ' + Self.ProgramName + '. Invalid Program'));
    end;
  End;


Function pglProgram.SearchUniform(uName: String): GLInt;
Var
I: GLInt;

  Begin

    Result := -1;

    If Self.UniformCount = 0 Then Begin
      Result := -1; // return not found if no uniforms cached
    End Else Begin

      For I := 0 to Self.UniformCount - 1 Do Begin

        If Self.Uniform[i].Name = uName Then Begin
          Result := Self.Uniform[i].Location; // search for uniform by name if uniforms are cached
          Exit;
        End;

        Result := -1; // if not found return not found
      End;

    End;

  End;


Procedure pglProgram.AddUniform(uName: string; Location: GLInt);
Var
I: GLInt;

  Begin
    inc(Self.UniformCount);
    I := Self.UniformCount;
    SetLength(Self.Uniform,I);
    Self.Uniform[i-1].Name := uName;
    Self.Uniform[i-1].Location := Location;

  End;


///////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// pglLightSource /////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

Constructor pglLightSource.Create();
  Begin
    Self.SetActive(False);
    Self.Place(Vec2(0,0),100);
    SElf.SetColor(Color3i(255,255,255));
    Self.SetRadiance(1);

    SetLength(PGL.Lights,Length(PGL.Lights) + 1);
    Pgl.Lights[High(Pgl.Lights)] := Self;
  End;

Procedure pglLightSource.SetActive(isActive: Boolean = True);
  Begin
    Self.Active := isActive;
  End;

Procedure pglLightSource.SetPosition(Pos: pglVector2);
  Begin
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
  End;

Procedure pglLightSource.SetColor(Color: pglColorF);
  Begin
    Self.Color := Color;
  End;

Procedure pglLightSource.SetColor(Color: pglColorI);
  Begin
    Self.Color := ColorItoF(Color);
  End;

Procedure pglLightSource.SetRadiance(RadianceVal: GLFloat);
  Begin
    Self.Radiance := RadianceVal;
  End;

Procedure pglLightSource.SetWidth(Val: GLFloat);
  Begin
    Self.Width := val;
  End;

Procedure pglLightSource.Place(Pos: pglVector2; WidthVal: GLFloat);
  Begin
    Self.SetWidth(WidthVal);
    Self.SetPosition(Pos);
  End;


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////Colors /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
Function pglColorI.Value: Double;
Var
Val: GLInt;
  Begin
    Result := (( Self.Alpha / 0.75) + (Self.Green / 0.50) + (Self.Green / 0.25) + (Self.Red / 0.1) ) * 255;
  End;

Function pglColorI.ToMultiply(Ratio: Single): pglColorI;
  Begin
    Result.Red := ClampIColor(trunc(Self.Red * Ratio));
    Result.Green := ClampIColor(trunc(Self.Green * Ratio));
    Result.Blue := ClampIColor(trunc(Self.Blue * Ratio));
    Result.Alpha := Self.Alpha;
  End;

Procedure pglColorI.Adjust(Percent: Integer; AdjustAlpha: Boolean = False);
  Begin
    Self.Red := ClampIColor(trunc(Self.Red * (Percent / 100)));
    Self.Green := ClampIColor(trunc(Self.Green * (Percent / 100)));
    Self.Blue := ClampIColor(trunc(Self.Blue * (Percent / 100)));

    If AdjustAlpha = True Then Begin
      Self.Alpha := ClampIColor(trunc(Self.Alpha * (Percent / 100)));
    End;
  End;

Function pglColorIHelper.IsColor(CompareColor: pglColorF; Tolerance: Double = 0): Boolean;
Var
RedDiff,GreenDiff,BlueDiff,AlphaDiff: Double;

  Begin

    Result := False;

    RedDiff := abs((Self.Red / 255) - (CompareColor.Red));
    GreenDiff := abs((Self.Green / 255) - CompareColor.Green);
    BlueDiff := abs((Self.Blue / 255) - CompareColor.Blue);
    AlphaDiff := abs((Self.Alpha / 255) - CompareColor.Alpha);


    If (RedDiff) <= Tolerance Then Begin
      If (GreenDiff) <= Tolerance Then Begin
        If (BlueDiff) <= Tolerance Then Begin
          If (AlphaDiff) <= Tolerance Then Begin
            Result := true;
          End;
        End;
      End;
    End;

  End;

Function pglColorIHelper.IsColor(CompareColor: pglColorI; Tolerance: Double = 0): Boolean;
Var
RedDiff,GreenDiff,BlueDiff,AlphaDiff: Double;

  Begin

    Result := False;

    RedDiff := abs((Self.Red / 255) - (CompareColor.Red / 255));
    GreenDiff := abs((Self.Green / 255) - CompareColor.Green / 255);
    BlueDiff := abs((Self.Blue / 255) - CompareColor.Blue / 255);
    AlphaDiff := abs((Self.Alpha / 255) - CompareColor.Alpha / 255);


    If (RedDiff) <= Tolerance Then Begin
      If (GreenDiff) <= Tolerance Then Begin
        If (BlueDiff) <= Tolerance Then Begin
          If (AlphaDiff) <= Tolerance Then Begin
            Result := true;
          End;
        End;
      End;
    End;

  End;

Function pglColorF.Value: Double;
Var
Val: GLInt;
  Begin
    Result := (((Self.Alpha * 255) / 0.75) + ((Self.Green * 255) / 0.5) + ((Self.Green * 255) / 0.25) + ((Self.Red * 255) / 0.1) ) * 255;
  End;

Function pglColorF.ToMultiply(Ratio: Single): pglColorF;
  Begin
    Result.Red := Self.Red * Ratio;
    Result.Green := Self.Green * Ratio;
    Result.Blue := Self.Blue * Ratio;
    Result.Alpha := Self.Alpha;
  End;

Function pglColorFHelper.IsColor(CompareColor: pglColorI; Tolerance: Double = 0): Boolean;

Var
RedDiff,GreenDiff,BlueDiff,AlphaDiff: Double;

  Begin

    Result := False;

    RedDiff := abs(Self.Red - (CompareColor.Red / 255));
    GreenDiff := abs(Self.Green - CompareColor.Green / 255);
    BlueDiff := abs(Self.Blue - CompareColor.Blue / 255);
    AlphaDiff := abs(Self.Alpha - CompareColor.Alpha / 255);


    If (RedDiff) <= Tolerance Then Begin
      If (GreenDiff) <= Tolerance Then Begin
        If (BlueDiff) <= Tolerance Then Begin
          If (AlphaDiff) <= Tolerance Then Begin
            Result := true;
          End;
        End;
      End;
    End;

  end;

Function pglColorFHelper.IsColor(CompareColor: pglColorF; Tolerance: Double = 0): Boolean;

Var
RedDiff,GreenDiff,BlueDiff,AlphaDiff: Double;

  Begin

    Result := False;

    RedDiff := abs(Self.Red - CompareColor.Red);
    GreenDiff := abs(Self.Green - CompareColor.Green);
    BlueDiff := abs(Self.Blue - CompareColor.Blue);
    AlphaDiff := abs(Self.Alpha - CompareColor.Alpha);


    If (RedDiff) <= Tolerance Then Begin
      If (GreenDiff) <= Tolerance Then Begin
        If (BlueDiff) <= Tolerance Then Begin
          If (AlphaDiff) <= Tolerance Then Begin
            Result := true;
          End;
        End;
      End;
    End;

  end;


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////Rects  /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

Procedure pglRectI.SetLeft(Value: GLInt);
  Begin
    Self.Left := Value;
    Self.Update(FROMLEFT);
  End;

Procedure pglRectI.SetTop(Value: GLInt);
  BEgin
    Self.Top := Value;
    Self.Update(FROMTOP);
  End;

Procedure pglRectI.SetRight(Value: GLInt);
  Begin
    Self.Right := Value;
    Self.Update(FROMRIGHT);
  End;

Procedure pglRectI.SetBottom(Value: GLInt);
  BEgin
    Self.Bottom := Value;
    Self.Update(FROMBOTTOM);
  End;

Procedure pglRectI.SetTopLeft(L: GLInt; T: GLInt);
  Begin
    Self.X := L + trunc(Self.Width / 2);
    Self.Y := T + trunc(Self.Height / 2);
    Self.Update(FROMCENTER);
  End;

Procedure pglRectI.SetCenter(X: GLInt; Y: GLInt);
  Begin
    Self.X := X;
    Self.Y := Y;
    Self.Update(FROMCENTER);
  End;


Procedure pglRectI.Update(From: Integer);
  Begin

    Case From of

      0: // From Center
        Begin
          Self.Left := Self.X - RoundInt(Self.Width / 2);
          Self.Right := Self.Left + (Self.Width - 1);
          Self.Top := Self.Y - RoundInt(Self.Height / 2);
          Self.Bottom := Self.Top + (Self.Height - 1);

        End;

      1: // From LEft
        Begin
          Self.X := Self.Left + RoundInt(Self.Width / 2);
          Self.Right := Self.Left + (Self.Width - 1);
          Self.Top := Self.y - RoundInt(Self.Height / 2);
          Self.Bottom := Self.Top + (Self.Height - 1);
        End;

      2: // From Top
        Begin
          Self.Y := Self.Top + RoundInt(Self.Height / 2);
          Self.Bottom := Self.Top + (Self.Height - 1);
          Self.Left := Self.X - RoundInt(Self.Width / 2);
          Self.Right := Self.Left + (Self.Width - 1);
        End;

      3: // From Right
        Begin
          Self.X := Self.Right - RoundInt(Self.Width / 2);
          Self.Left := Self.Right - Self.Width - 1;
          Self.Top := Self.y - RoundInt(Self.Height / 2);
          Self.Bottom := Self.Top + Self.Height - 1;
        End;

      4: // From Bottom
        Begin
          Self.Y := Self.Bottom - RoundInt(Self.Height / 2);
          Self.Top := Self.Bottom - Self.Height - 1;
          Self.Left := SElf.X - RoundInt(SElf.Width / 2);
          Self.Right := SElf.LEft + SElf.Width - 1;
        End;

    End;

  End;

Procedure pglRectI.Translate(X: Integer; Y: Integer);
  Begin
    Self.X := Self.X + X;
    Self.Y := Self.Y + Y;
    Self.Update(FROMCENTER);
  End;

Procedure pglRectI.Resize(Width: Integer; Height: Integer);
  Begin
    Self.Width := Width;
    Self.Height := Height;
    Self.Update(FROMCENTER);
  End;

Procedure pglRectI.Grow(Width: Integer; Height: Integer);
  Begin
    Self.Width := Self.Width + Width;
    Self.Height := Self.Height + Height;
    Self.Update(FROMCENTER);
  End;

Procedure pglRectI.Stretch(PercentX: Double; PercentY: Double);
  Begin
    Self.Width := trunc(Self.Width * PercentX);
    Self.Height := trunc(Self.Height * PercentY);
    Self.Update(FROMCENTER);
  End;


Function pglRectIHelper.ToRectF(): pglRectF;
  Begin
    Result.X := (Self.X);
    Result.Y := (Self.Y);
    Result.Width := (Self.Width);
    Result.Height := (Self.Height);
    Result.Update(FROMCENTER);
  End;

Function pglRectIHelper.toPoints: pglVectorQuad;
  Begin
    Result[0] := vec2(Self.Left, Self.Top);
    Result[1] := vec2(Self.Right, Self.Top);
    Result[2] := Vec2(Self.Right, Self.Bottom);
    Result[3] := Vec2(Self.Left, Self.Bottom);
  end;


Procedure pglRectF.SetLeft(Value: Single);
  Begin
    Self.Left := Value;
    Self.Update(FROMLEFT);
  End;

Procedure pglRectF.SetTop(Value: Single);
  BEgin
    Self.Top := Value;
    Self.Update(FROMTOP);
  End;

Procedure pglRectF.SetRight(Value: Single);
  Begin
    Self.Right := Value;
    Self.Update(FROMRIGHT);
  End;

Procedure pglRectF.SetBottom(Value: Single);
  BEgin
    Self.Bottom := Value;
    Self.Update(FROMBOTTOM);
  End;

Procedure pglRectF.SetTopLeft(L: Single; T: Single);
  Begin
    Self.X := L + (Self.Width / 2);
    Self.Y := T + (Self.Height / 2);
    Self.Update(FROMCENTER);
  End;

Procedure pglRectF.SetCenter(X: Single; Y: Single);
  Begin
    Self.X := X;
    Self.Y := Y;
    Self.Update(FROMCENTER);
  End;


Procedure pglRectF.Update(From: Integer);
  Begin

    Case From of

      0: // From Center
        Begin
          Self.Left := Self.X - (Self.Width / 2);
          Self.Right := Self.Left + Self.Width;
          Self.Top := Self.Y - (Self.Height / 2);
          Self.Bottom := Self.Top + Self.Height;
          Exit;
        End;

      1: // From LEft
        Begin
          Self.X := Self.Left + (Self.Width / 2);
          Self.Right := Self.Left + Self.Width - 1;
          Self.Top := Self.y - (Self.Height / 2);
          Self.Bottom := Self.Top + SElf.Height - 1;
          Exit;
        End;

      2: // From Top
        Begin
          Self.Y := Self.Top + (Self.Height / 2);
          Self.Bottom := Self.Top + Self.Height - 1;
          Self.Left := SElf.X - (SElf.Width / 2);
          Self.Right := SElf.LEft + SElf.Width - 1;
          Exit;
        End;

      3: // From Right
        Begin
          Self.X := Self.Right - (Self.Width / 2);
          Self.Left := Self.Right - Self.Width - 1;
          Self.Top := Self.y - (Self.Height / 2);
          Self.Bottom := Self.Top + SElf.Height - 1;
          Exit;
        End;

      4: // From Bottom
        Begin
          Self.Y := Self.Bottom - (Self.Height / 2);
          Self.Top := Self.Bottom - Self.Height - 1;
          Self.Left := SElf.X - (SElf.Width / 2);
          Self.Right := SElf.LEft + SElf.Width - 1;
          Exit;
        End;

    End;

  End;

Procedure pglRectF.Translate(X: Double; Y: Double);
  Begin
    Self.X := Self.X + X;
    Self.Y := Self.Y + Y;
    Self.Update(FROMCENTER);
  End;

Procedure pglRectF.Resize(Width: Double; Height: Double);
  Begin
    Self.Width := Width;
    Self.Height := Height;
    Self.Update(FROMCENTER);
  End;

Procedure pglRectF.Grow(Width: Double; Height: Double);
  Begin
    Self.Width := Self.Width + Width;
    Self.Height := Self.Height + Height;
    Self.Update(FROMCENTER);
  End;

Procedure pglRectF.Stretch(PercentX: Double; PercentY: Double);
  Begin
    Self.Width := Self.Width * PercentX;
    Self.Height := Self.Height * PercentY;
    Self.Update(FROMCENTER);
  End;

Procedure pglRectF.Truncate();
  Begin
    Self.X := trunc(Self.X);
    Self.Y := trunc(Self.Y);
    Self.Width := trunc(Self.Width);
    Self.Height := trunc(Self.Height);
    Self.Update(FROMCENTER);
    Self.Top := trunc(Self.Top);
    Self.Bottom := trunc(Self.Bottom);
    Self.Left := trunc(Self.Left);
    Self.Right := trunc(Self.Right);
  End;

Procedure pglRectF.ResizeByAngle(Angle: GLFloat);
Var
Hyp: GLFloat;
NewWidth,NewHeight: GLFloat;
Points: pglVectorQuad;
  Begin
    // Rotate corner points and set new bounds
    Points := Self.toPoints;
    RotatePoints(Points, Vec2(Self.X, Self.Y), Angle);
    Self := PointsToRectF(Points);
  End;

Function pglRectF.ToRectFTrunc(): pglRectF;
  Begin
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
  End;


Function pglRectFHelper.ToRectI(): pglRectI;
  Begin
    Result.X := trunc(Self.X);
    Result.Y := trunc(Self.Y);
    Result.Width := trunc(Self.Width);
    Result.Height := trunc(Self.Height);
    Result.Update(FROMCENTER);
  End;

Function pglRectFHelper.toPoints: pglVectorQuad;
  Begin
    Result[0] := vec2(Self.Left, Self.Top);
    Result[1] := vec2(Self.Right, Self.Top);
    Result[2] := Vec2(Self.Right, Self.Bottom);
    Result[3] := Vec2(Self.Left, Self.Bottom);
  End;

Function pglRectFHelper.CheckInside(Pos: pglVector2): Boolean;
  Begin
    Result := False;
      If (Pos.X >= Self.Left) And
         (Pos.X <= Self.Right) And
         (Pos.Y >= Self.Top) And
         (POs.Y <= Self.Bottom) Then Begin

         Result := True;
      End;

  End;

Function pglRectIHelper.CheckInside(Pos: pglVector2): Boolean;
  Begin
    Result := False;
      If (Pos.X >= Self.Left) And
         (Pos.X <= Self.Right) And
         (Pos.Y >= Self.Top) And
         (POs.Y <= Self.Bottom) Then Begin

         Result := True;
      End;

  End;


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////pglTextureBatch ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

Procedure pglTextureBatch.Clear();
Var
I: LongInt;

  Begin

    For I := 0 To High(Self.TextureSlot) Do Begin
      Self.TextureSlot[i] := 0;
    End;

    Self.Count := 0;
    Self.SlotsUsed := 0;

  End;

///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////Shapes /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

Constructor pglPoint.Create(P: pglVector2; size: GLFloat; color: pglColorF);
  Begin
    Self.pPos := P;
    Self.pSize := size;
    Self.pColor := color;
  End;

Procedure pglPoint.SetPosition(P: pglVector2);
  Begin
    Self.pPos.X := P.x;
    Self.pPos.Y := P.Y;
  End;

Procedure pglPoint.Move(by: pglVector2);
  Begin
    Self.pPos.X := Self.pPos.X + by.X;
    Self.pPos.Y := Self.pPos.Y + by.Y;
  End;

Procedure pglPoint.SetColor(C: pglColorF);
  Begin
    Self.pColor := C;
  End;


Procedure pglPoint.SetSize(S: GLFloat);
  Begin
    Self.pSize := S;
  End;



///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////Text   /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////pglCharaccter   ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

Procedure pglCharacter.GetOutlinePoints;
  Begin

  End;


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////pglFont ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////


Constructor pglFont.Create(FileName: String; Sizes: Array of Integer; Bold: Boolean = False);


Var
I,R,T,Z,G,J: GLInt;
LoadFlags: TFTLoadFlags;
Buffer: Array of Byte;
W,H: TFTF26Dot6;
Face: TFTFace;
Quad: pglVectorQuad;
TW,TH: GLInt;
TS: Integer;

  Begin


    Face := TFTFace.Create(PansiChar(AnsiString(FileName)),0);

    Self.FontName := (ExtractFileName(FileName));

    SetLength(Self.Atlas,Length(Sizes));

    For G := 0 to High(Sizes) Do Begin

      H := trunc(Sizes[g] * 64);
      W := trunc(H*1.5);

      Face.SetCharSize(0,H,0,0);
      Self.Atlas[g].FontSize := Sizes[g];


      For I := 31 to 128 Do Begin

        LoadFlags := [ftlfRender];

        if Chr(i) = '' Then Continue;

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


        If Integer(Self.Atlas[g].OriginY) < Self.Atlas[g].Character[i].Bearing Then Begin
           Self.Atlas[g].OriginY := Self.Atlas[g].Character[i].Bearing;
        End;

        If Integer(Self.Atlas[g].TailMax) < Self.Atlas[g].Character[i].TailHeight Then Begin
           Self.Atlas[g].TailMax := Self.Atlas[g].Character[i].TailHeight;
        End;

        If Integer(Self.Atlas[g].TotalHeight) < Self.Atlas[g].Character[i].Height + Self.Atlas[g].Character[i].TailHeight Then Begin
           Self.Atlas[g].TotalHeight := Self.Atlas[g].Character[i].Height + Self.Atlas[g].Character[i].TailHeight;
        End;

      End;

      inc(Self.Atlas[g].TotalHeight,10);
      Face.Glyph.Bitmap.Done();
      Self.BuildAtlas(g);

      glBindTexture(GL_TEXTURE_2D,Self.Atlas[g].Texture);
      glGetTexLevelParameterIV(GL_TEXTURE_2D,0,GL_TEXTURE_WIDTH,@TW);
      glGetTexLevelParameterIV(GL_TEXTURE_2D,0,GL_TEXTURE_HEIGHT,@TH);
      TS := Sizes[g];

      PGLSaveTexture(Self.Atlas[g].Texture,TW,TH,
        pglEXEPath + 'Test Pics/Atlas ' + IntToStr(TS) + '.bmp');

    End;

    FT_Done_Face(Face);


  End;


Function pglFont.ChooseAtlas(CharSize: GLUInt): Integer;

Var
Selected: GLUInt;
CurDiff: GLInt;
I: GLInt;

  Begin

    CurDiff := 1000;

    Selected := 0;

    For I := 0 to High(Self.Atlas) Do Begin

      If abs(Integer(CharSize) - Self.Atlas[i].FontSize) < CurDiff Then Begin
        Selected := I;
        CurDiff := Abs(Integer(CharSize) - Self.Atlas[i].FontSize);
      End;

    End;

    Result := Selected;

  End;


Procedure pglFont.BuildAtlas(A: GLInt);

Var
TotalWidth: GLFloat;
I,R: GLInt;
CurrentX: GLInt;
Ver: pglVectorQuad;
Cor: pglVectorQuad;
Buffer: Array Of Byte;
CheckVar: glEnum;
CheckWidth: GLInt;
CurChar: ^pglCharacter;
Lowest, Highest: Byte;
Swizzle: Array [0..3] of GLInt;
ReturnVal: ByteBool;


  Begin

    TotalWidth := 0;

    For I := 0 to High(Self.Atlas[A].Character) Do Begin
      TotalWidth := TotalWidth + Self.Atlas[A].Character[i].Metrics.SDFWIDTH + 1;
    End;

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

    For I := 31 to High(Self.Atlas[A].Character) Do Begin

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
    End;

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
  End;


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////pglText ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

Constructor pglText.Create(Font: pglFont; Chars: string);
  Begin
    Self.UseFont := Font;
    Self.UseColor := Color4f(1,1,1,1);
    Self.UseBorderColor := Color4f(1,1,1,1);
    Self.UseBorderSize := 0;
    Self.UseCharSize := Font.FontSize;
    Self.SetText(Chars);
  End;



Procedure pglText.FindBounds;
Var
Width,Height: GLFloat;
Highest, Lowest: GLFloat;
Len: GLInt;
I: GLInt;
CurChar: pglCharacter;
CurFont: pglFont;
UseAtlas: ^pglAtlas;
AdjPer: GLFloat;

  Begin

    Self.CurrentAtlas := Self.UseFont.ChooseAtlas(Self.CharSize);
    UseAtlas := @Self.UseFont.Atlas[Self.CurrentAtlas];

    If Self.UseMultiLine = True Then Begin

      Exit;
    End;

    AdjPer := Self.CharSize / UseAtlas.FontSize;

    Len := Length(Self.UseText);

    Lowest := 0;
    Highest := 0;
    Width := 0;
    Height := 0;
    CurFont := Self.UseFont;

    For I := 1 to Len Do Begin
      CurChar := UseAtlas.Character[Ord(Self.UseText[i])];
      Width := Width + ((CurChar.Advance) * AdjPer) + (Self.BorderSize*2);
    End;

    Self.UseTextBounds.Width := trunc(Width);
    Self.UseTextBounds.Height := UseAtlas.TotalHeight * AdjPer;
    Self.UseBounds.Width := Width;
    Self.UseBounds.Update(FROMLEFT);
    Self.UseBounds.HEight := UseAtlas.TotalHeight * AdjPer;
    Self.UseBounds.Update(FROMTOP);

  End;


Procedure pglText.SetText(Chars: String);
  Begin
    Self.UseText := Chars;
    Self.FindBounds();
  End;


Procedure pglText.SetColor(Color: pglColorI);
  Begin
    Self.UseColor := ColorIToF(Color);
  End;


Procedure pglText.SetBorderColor(Color: pglColorI);
  Begin
    Self.UseBorderColor := cc(Color);
  End;

Procedure pglText.SetBorderSize(Size: Integer);
  Begin
    Self.UseBorderSize := Size;
    Self.FindBounds();
  End;

Procedure pglText.SetCharSize(Size: Integer);
  Begin
    Self.UseCharSize := Size;
    Self.FindBounds();
  End;

Procedure pglText.SetShadow(Shadow: Boolean = True);
  Begin
    Self.UseShadow := Shadow;
  End;

Procedure pglText.Rotate(Angle: GLFloat);
  Begin
    Self.UseAngle := Self.UseAngle + Angle;
  end;

Procedure pglText.SetRotation(Angle: GLFloat);
  Begin
    Self.UseAngle := Angle;
  End;

Procedure pglText.SetSmooth(Smooth: Boolean = True);
  Begin
    Self.UseSmooth := Smooth;
  End;

Procedure pglText.SetUseGradientColors(UseGradient: Boolean = True);
  Begin
    Self.UseHasGradient := UseGradient;
  End;

Procedure pglText.SetGradientColors(LeftColor: pglColorF; RightColor: pglColorF);
  Begin
    Self.UseGradientColorLeft := LeftColor;
    Self.UseGradientColorRight := RightColor;
  End;

Procedure pglText.SetGradientXOffSet(XOffSet: Single);
  Begin
    Self.UseGradientOffset := XOffSet;
  End;

Procedure pglText.WrapText(WrapWidth: GLFloat);

Var
I,R: Long;
Len: Integer;
CurChar: ^pglCharacter;
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

  Begin

    If Length(Self.Text) = 0 Then Exit;

    CurPos := 1;
    LastPos := 1;
    CurWidth := 0;
    WordCount := 0;
    Lines := 1;
    Len := Length(Self.Text);
    AdjPer :=  Self.UseFont.Atlas[Self.CurrentAtlas].FontSize / Self.CharSize;
    OutText := '';
    WrapHeight := (Self.UseFont.Atlas[Self.CurrentAtlas].TotalHeight) * AdjPer + (Self.BorderSize * 2);

    While CurPos < Len Do Begin

      ReadChar := AnsiMidStr(Self.Text,CurPos,1);

      If ReadChar = ' '  Then Begin
        SetLength(Words,Length(Words) + 1);
        WordCount := Length(Words)-1;
        Words[WordCount] := AnsiMidStr(Self.Text,LastPos,CurPos - LastPos + 1);
        LastPos := CurPos + 1;
      End;

      CurPos := CurPos + 1;

      If CurPos = Len Then Begin
        SetLength(Words,Length(Words) + 1);
        WordCount := Length(Words)-1;
        Words[WordCount] := AnsiMidStr(Self.Text,LastPos,CurPos - LastPos + 1);
        Break;
      End;

    End;


    For I := 0 to WordCount Do Begin

      Len := Length(Words[i]);

      WordWidth := 0;

      For R := 1 to Len Do Begin
        CurChar := @Self.UseFont.Atlas[Self.CurrentAtlas].Character[ Ord( Self.Text[R] ) ];
        WordWidth := WordWidth + (CurChar.Advance * AdjPer) + (Self.BorderSize * 2);
      End;

      If CurWidth + WordWidth > WrapWidth Then Begin
        CurWidth := WordWidth;
        OutText := OutText + sLineBreak + Words[I];
        Lines := Lines + 1;
      End Else Begin
        CurWidth := CurWidth + WordWidth;
        OutText := OutText + Words[i];
      End;

    End;

    WrapHeight := WrapHeight * Lines;
    Self.SetMultiLine(True);
    Self.SetMultiLineBounds(glDrawMain.RectFWH(Self.Bounds.Left,Self.Bounds.Top,WrapWidth,WrapHeight));
    Self.UseBounds := Self.MultiLineBounds;

    Self.UseWrapText := OutText;
    Self.UseLineCount := Lines;
    SetLength(Self.UseLineStart,Lines);

  End;



Procedure pglText.SetCenter(Center: pglVector2);
  Begin
    Self.UseBounds.X := trunc(Center.X);
    Self.UseBounds.Y := trunc(Center.Y);
    Self.UseBounds.Update(FROMCENTER);
  End;

Procedure pglText.SetTopLeft(TopLeft: pglVector2);
  Begin
    Self.UseBounds.X := trunc(TopLeft.X + (Self.Bounds.Width / 2));
    Self.UseBounds.Y := trunc(TopLeft.Y + (Self.Bounds.Height / 2));
    Self.UseBounds.Update(FROMCENTER);
  End;

Procedure pglText.SetLeft(Left: Single);
  Begin
    Self.UseBounds.Left := Left;
    Self.UseMultiLineBounds.Left := Left;
    Self.UseBounds.Update(FROMLEFT);
    Self.UseMultilinebounds.Update(FROMLEFT);
  End;

Procedure pglText.SetTop(Top: Single);
  Begin
    Self.UseBounds.Top := Top;
    Self.UseMultiLineBounds.Top := Top;
    Self.UseBounds.Update(FROMTOP);
    Self.UseMultilinebounds.Update(FROMTOP);
  End;

Procedure pglText.SetRight(Right: Single);
  Begin
    Self.UseBounds.Right := Right;
    Self.UseMultiLineBounds.Right := Right;
    Self.UseBounds.Update(FROMRIGHT);
    Self.UseMultilinebounds.Update(FROMRIGHT);
  End;


Procedure pglText.SetBottom(Bottom: Single);
  Begin
    Self.UseBounds.Bottom := Bottom;
    Self.UseMultiLineBounds.Bottom := Bottom;
    Self.UseBounds.Update(FROMCENTER);
    Self.UseMultilinebounds.Update(FROMBOTTOM);
  End;

Procedure pglText.SetX(X: Single);
  Begin
    Self.UseBounds.X := X;
    Self.UseMultiLineBounds.X := X;
    Self.UseBounds.Update(FROMCENTER);
    Self.UseMultilinebounds.Update(FROMCENTER);
  End;

Procedure pglText.SetY(Y: Single);
  Begin
    Self.UseBounds.Y := Y;
    Self.UseMultiLineBounds.Y := Y;
    Self.UseBounds.Update(FROMCENTER);
    Self.UseMultilinebounds.Update(FROMCENTER);
  End;


Procedure pglText.SetMultiLine(Value: Boolean = True);
  Begin
    Self.UseMultiLine := Value;
  End;

Procedure pglText.SetMultiLineBounds(Bounds: pglRectF);
  Begin
    Self.UseMultiLineBounds := Bounds;
    Self.UseBounds := Bounds;
  End;

Procedure pglText.SetWidth(Value: Cardinal);
  Begin
    Self.UseBounds.Width := trunc(Value);
    Self.UseBounds.Update(FROMCENTER);

    If Self.UseMultiLine = True Then Begin
      Self.UseMultiLineBounds.Width := Value;
      Self.UseMultiLineBounds.Update(FROMCENTER);
    End;
  End;


Function pglText.FindPosition: pglVector2;
  Begin
    Result := Vec2(Self.Bounds.X,Self.Bounds.Y);
  End;

Function pglText.FindTopLeft: pglVector2;
  Begin
    Result := Vec2(Self.Bounds.Left, Self.Bounds.Top);
  End;

Function pglText.FindWidth: Integer;
  Begin
    Result := trunc(Self.Bounds.Width);
  End;

Function pglText.FindHeight: Integer;
  Begin
    Result := trunc(Self.Bounds.Height);
  End;


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////pglTextFormat //////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////


Procedure pglTextFormat.Reset();
  Begin

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

  End;


Procedure pglTextFormat.SetFormat(iPosition: pglVector2; iWidth: Integer;
          iHeight: Integer; iFont: pglFont; iAtlasIndex: Integer; iColor: pglColorF;
          iBorderColor: pglColorF; iBorderSize: Cardinal; iShadow: Boolean; iShadowOffset: pglVector2;
          iShadowColor: pglColorF; iSmooth: Boolean; iRotation: Single; iUseGradient: Boolean;
          iGradientLeft,iGradientRight: pglColorF; iGradientXOffSet: glFloat);

  Begin
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
    If Self.Width <0 then Begin
      Self.Width := -1;
    End;

    If Self.Height <= 0 Then Begin
      Self.Height := -1;
    End;

    // If the font passed is valid, Ensure atlas index and char size are valid
    If Assigned(iFont) Then Begin

      If (Self.AtlasIndex <= Low(Font.Atlas)) and (Self.AtlasIndex >= High(Font.Atlas)) Then Begin
        Self.AtlasIndex := 0;
      End;

      If Self.CharSize <= 0 Then Begin
        Self.CharSize := iFont.Atlas[Low(iFont.Atlas)].FontSize;
      End;

    End;

  End;

end.

