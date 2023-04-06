unit PGLMain;

interface

uses
  uFreeType, System.SysUtils, Classes, Types, System.StrUtils, System.AnsiStrings, System.IOUtils, WinAPI.Windows, dglOpenGL, PGLContext,
  PGLClock, PGLTypes, PGLMath, Math, Neslib.Stb.Image, Neslib.Stb.ImageWrite;

{$POINTERMATH ON}


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                     Enums
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

{$REGION 'ENUMS'}

  type TPGLDrawFilter = (pgl_nearest = 0, pgl_linear = 1);
  type TPGLBlitBlend = (pgl_overwrite = 0, pgl_blend = 1, pgl_additive = 2, pgl_draw_depth = 3);
  type TPGLBlitDepth = (pgl_no_copy_depth = 0, pgl_copy_depth = 1);
  type TPGLImageFormat = (pgl_bmp = 0, pgl_png = 1);

{$ENDREGION}


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                Imported Types
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


{$REGION 'IMPORTS'}

  // PGLContxt
  type TPGLWindowFormat = PGLContext.TPGLWindowFormat;
  type PPGLWindowFormat = ^TPGLWindowFormat;

  type TPGLFeatureSettings = PGLContext.TPGLFeatureSettings;
  type PPGLFeatureSettings = ^TPGLFeatureSettings;

  type TPGLKeyBoard = PGLContext.TPGLKeyBoard;
  type TPGLKeyCallBack = PGLContext.pglKeyCallBack;
  type TPGLMouse = PGLContext.TPGLMouse;
  type TPGLMouseCallBack = PGLContext.pglMouseCallBack;
  type TPGLController = PGLContext.TPGLController;
  type TPGLControllerButtonCallback = PGLContext.pglControllerButtonCallBack;
  type TPGLControllerStateCallback = PGLContext.pglControllerStateCallBack;
  type TPGLControllerStickCallback = PGLContext.pglControllerStickCallBack;
  type TPGLControllerStickReleaseCallBack = PGLContext.pglControllerStickReleaseCallBack;
  type TPGLControllerTriggerCallback = PGLContext.pglControllerTriggerCallBack;



  // PGLClock
  type TPGLClock = PGLClock.TPGLClock;


// Local Types
{$ENDREGION}

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                Local Types
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

{$REGION 'LOCAL TYPES'}

  type TPGLProc = procedure();

  type TPGLWindowProc = procedure();

  type
    PPGLBlitMode = ^TPGLBlitMode;
    TPGLBlitMode = record
      public
        BlendMode: TPGLBlitBlend;
        DepthMode: TPGLBlitDepth;

        class operator Initialize( out Dest: TPGLBlitMode); register;
        constructor Create(ABlendMode: TPGLBlitBlend; ADepthMode: TPGLBlitDepth); register;
  end;

  type TPGLUniform = record
    // used to hold uniform name and location information for TPGLPrograms
    private
      Name: String;
      Location: GLInt;
      DataType: GLEnum;
  end;


  type TPGLProgram = class(TObject)
    public
      Valid: GLInt;
      ID: GLUint;
      VertexShader, FragmentShader: GLUint;
      Name: String;
      UniformCount: GLInt;
      Uniform: Array of TPGLUniform;
      BlockCount: GLInt;

      constructor Create(APath: String); register;
      procedure ReadUniforms(); register;
      function GetUniform(AName: String): GLInt; register;
      function AddUniform(AName: String): GLInt; register;
  end;


  type TPGLVBO = record
    Buffer: GLUInt;
    Size: GLUInt;
    InUse: Boolean;
    InUseSize: GLInt;
    procedure SubData(ASize: GLUInt; AData: Pointer); register;
    procedure SetAttribPointer(AIndex: GLInt; AComponents: GLInt; AType: GLEnum; ANormalize: ByteBool; AStride: GLInt; AOffSet: GLInt); register;
  end;

  type TPGLSSBO = record
    Buffer: GLUInt;
    Size: GLUInt;
    InUse: Boolean;
    InUseSize: GLInt;
    Mapped: Boolean;
    Ptr: PByte;

    procedure SubData(ASize: GLUInt; AData: Pointer); register;
    procedure BindToBase(AIndex: GLInt); register;
    procedure Map(); register;
    procedure UnMap(); register;
  end;


  type TPGLBuffers = record
    VAO: GLInt;
    VBO: Array of TPGLVBO;
    SSBO: Array  of TPGLSSBO;
    StaticSSBO: TPGLSSBO;
    CurrentVBO: ^TPGLVBO;
    CurrentSSBO: ^TPGLSSBO;
    EBO: GLUint;
    ShapeEBO: GLUint;
    AttribArray: Array of ByteBool;

    procedure FillBuffers(); register;
    procedure SelectNextVBO(); register;
    procedure SelectNextSSBO(); register;
    procedure SelectStaticSSBO(); register;
    procedure EnableAttrib(AIndex: GLInt); register;
    procedure Reset(); register;
  end;


  type TPGLElementIndirectBuffer = record
    Count: GLUint;
    InstanceCount: GLUint;
    First: GLUint;
    BaseVertex: GLInt;
    BaseInstance: GLUint;
  end;


  type TPGLArrayIndirectBuffer = record
    Count: GLUint;
    InstanceCount: GLUint;
    First: GLUint;
    BaseInstance: GLUint;
  end;


  {$A16}
  type TPGLSpriteParams = record
    Overlay: TPGLColorF;
    GreyScale: GLInt;
    MonoChrome: GLInt;
    Brightness: GLFLoat;
    Opacity: GLFloat;
  end;
  {$A8}

  type TPGLLightParams = record
    Radius: GLFloat;
    GlobalLight: GLFloat;
    Luminance: GLFloat;
    Padding: GLFloat;
  end;

  type TPGLTextParams = record
    private
      ScalePointSizes: Boolean;
      LastTextBounds: TPGLRectF;
      ClipBounds: TPGLRectF;
  end;


  type TPGLDrawParams = record
    DrawCount: GLInt;
    VertexCount: GLInt;
    ElementCount: GLInt;

    // global draw data
    TexSlot: Array [0..31] of GLUint;  // GL texture name storage
    SpriteInfo: Array [0..999] of TPGLSpriteParams;
    LightInfo: Array [0..999] of TPGLLightParams;

    // per draw data
    ElementIndirect: Array [0..999] of TPGLElementIndirectBuffer;
    ArrayIndirect: Array [0..999] of TPGLArrayIndirectBuffer;
    Translation: Array [0..999] of TPGLMat4;
    OriginTranslation: Array [0..999] of TPGLMat4;
    Rotation: Array [0..999] of TPGLMat4;
    TexUsing: Array [0..999] of GLInt; // Index of TexSlot that the draw uses for tex coords
    Size: Array [0..999] of GLFloat;
    Width: Array [0..999] of GLFloat;
    Height: Array [0..999] of GLFloat;
    BorderWidth: Array [0..999] of GLFloat;
    BorderColor: Array [0..999] of TPGLColorF;
    Center: Array [0..999] of TPGLVec4;

    // per vertex data
    Vertices: Array [0..64000] of TPGLVertex;
    Index: Array [0..64000] of GLInt;
    Elements: Array [0..24000] of GLInt;

    class operator Initialize(out Dest: TPGLDrawParams); register;
  end;


  type TPGLImage = class(TObject)
    private
      fWidth, fHeight: GLInt;
      fIsValid: Boolean;
      fData: PByte;
      fDataSize: GLUInt;
      fRowPos: Array of PByte;

      destructor Destroy(); override;
      procedure Free(); register;

      procedure Define(); register;
      function GetPixelPos(AX,AY: GLUInt): PByte; register;
      function GetRect(): TPGLRectI; register;

    public
      property Width: GLInt read fWidth;
      property Height: GLInt read fHeight;
      property IsValid: Boolean read fIsValid;
      property DataSize: GLUint read fDataSize;
      property Bounds: TPGLRectI read GetRect;

      constructor Create(AWidth: GLUint = 1; AHeight: GLUint = 1); overload; register;
      constructor Create(AFileName: String); overload; register;
      constructor Create(var ASourceImage: TPGLImage); overload; register;
      constructor Create(AData: Pointer; AWidth, AHeight: GLUInt); overload; register;

      procedure CopyFrom(var ASourceImage: TPGLImage); overload; register;
      procedure CopyFrom(var ASourceImage: TPGLImage; ASrcRect: TPGLRectI); overload; register;
      procedure CopyFrom(var ASourceImage: TPGLImage; ASrcRect: TPGLRectI; ADestRect: TPGLRectI); overload; register;

      function GetPixelF(AX,AY: GLUInt): TPGLColorF; register;
      function GetPixelI(AX,AY: GLUInt): TPGLCOlorI; register;
      function GetPixels(ARect: TPGLRectI): TArray<Byte>; overload; register;
      procedure GetPixels(ARect: TPGLRectI; out ADestination: Pointer); overload; register;
      procedure SetPixel(AX,AY: GLUint; AColor: TPGLColorF); overload; register;
      procedure SetPixel(AX,AY: GLUint; AColor: TPGLColorI); overload; register;

      procedure ReplaceColor(AOldColor: TPGLColorF; ANewColor: TPGLColorF); register;
      procedure ReplaceColors(AOldColors: Array of TPGLColorF; ANewColors: Array of TPGLColorF); register;

      function ReturnHitMap(): TArray<Byte>; register;

      procedure SetAlpha(AValue: GLFloat); register;
      procedure Fill(AColor: TPGLColorF); register;
      procedure MixColor(AColor: TPGLColorF; AIgnoreTransparent: Boolean = True); register;
      procedure Stretch(AXPercent: GLFloat = 1; AYPercent: GLFloat = 1); register;
      procedure ChangeSize(ANewWidth: GLUInt = 1; ANewHeight: GLUInt = 1); register;
      procedure Pixelate(APixelSize: GLUInt); register;
      procedure Lighten(AValue: GLFloat); register;

      procedure SaveToFile(AFileName: String); register;

  end;


  type TPGLTexture = class(TObject)
    private
      fHandle: GLUint;
      fWidth,fHeight: GLUint;
      fDataSize: GLUint;

      // editing
      fEditMode: Boolean;
      MapPointer: Pointer;
      EditImage: TPGLImage;

      // state
      fAttachedToTarget: Boolean;
      fTarget: TObject;

      destructor Destroy(); override;

      function GetRect(): TPGLRectI; register;

    public
      property Handle: GLUint read fHandle;
      property Width: GLUint read fWidth;
      property Height: GLUint read fHeight;
      property DataSize: GLUint read fDataSize;
      property Bounds: TPGLRectI read GetRect;
      property EditMode: Boolean read fEditMode;
      property Edit: TPGLImage read EditImage;
      property AttachedToTarget: Boolean read fAttachedToTarget;
      property Target: TObject read fTarget;

      constructor Create(AWidth: GLUint = 1; AHeight: GLUint = 1); overload; register;
      constructor Create(ASourceImage: TPGLImage); overload; register;
      constructor Create(AFileName: String); overload; register;
      constructor Create(var ASourceTexture: TPGLTexture); overload; register;

      // utitility
      procedure Clear(AColor: TPGLColorF); overload; register;
      procedure Clear(); overload; register;
      procedure CopyFrom(var ATexture: TPGLTexture); overload; register;
      procedure CopyFrom(var ATexture: TPGLTexture; ASourceRect,ADestRect: TPGLRectI); overload; register;
      procedure CopyFrom(var AImage: TPGLImage); overload; register;
      procedure CopyFrom(var AImage: TPGLImage; ASourceRect,ADestRect: TPGLRectI); overload; register;
      procedure CopyFrom(AData: Pointer; AWidth, AHeight: GLUInt); overload; register;
      procedure ReSize(ANewWidth: GLUint = 1; ANewHeight: GLUint = 1; AKeepData: Boolean = True); register;
      procedure SaveToFile(AFileName: String; AFormat: TPGLImageFormat = pgl_bmp); register;


      // editing
      procedure OpenForEditing(); register;
      procedure CloseForEditing(); register;
  end;


  type TPGLSprite = class(TObject)
    private
      fTexture: TPGLTexture;
      fBounds: TPGLRectF;
      fTextureRect: TPGLRectI;
      fSubRect: Array [0..99] of TPGLRectI;
      fColorValues: TPGLColorF;
      fColorOverlay: TPGLColorF;
      fGreyScale: Boolean;
      fMonoChrome: Boolean;
      fBrightness: GLFloat;
      fOpacity: GLFloat;
      fAngleX,fAngleY,fAngleZ: GLFloat;
      fOrigin: TPGLVec3;
      TransMat: TPGLMat4;
      RotMat: TPGLMat4;

      destructor Destroy(); override; register;
      procedure Free(); register;

      procedure SetInit(); register;
      function GetAngles(): TPGLVec3; register;
      function GetSubRect(I: Integer): TPGLRectI;  register;

    public
      property Texture: TPGLTexture read fTexture;
      property Bounds: TPGLRectF read fBounds;
      property TextureRect: TPGLRectI read fTextureRect;
      property SubRect[Index: GLInt]: TPGLRectI read GetSubRect;
      property ColorValues: TPGLColorF read fColorValues;
      property ColorOverlay: TPGLColorF read fColorOverlay;
      property GreyScale: Boolean read fGreyScale;
      property MonoChrome: Boolean read fMonoChrome;
      property Brightness: GLFloat read fBrightness;
      property Opacity: GLFloat read fOpacity;
      property AngleX: GLFloat read fAngleX;
      property AngleY: GLFloat read fAngleY;
      property AngleZ: GLFloat read fAngleZ;
      property Angles: TPGLVec3 read GetAngles;
      property Origin: TPGLVec3 read fOrigin;

      constructor Create(); overload; register;
      constructor Create(var ATexture: TPGLTexture); overload; register;

      procedure SetTexture(ATexture: TPGLTexture); register;
      procedure SetLeft(ALeft: GLFloat); register;
      procedure SetTop(ATop: GLFloat); register;
      procedure SetRight(ARight: GLFloat); register;
      procedure SetBottom(ABottom: GLFloat); register;
      procedure SetWidth(AWidth: GLFloat); register;
      procedure SetHeight(AHeight: GLFloat); register;
      procedure SetSize(AWidth,AHeight: GLFloat); register;
      procedure SetCenter(ACenter: TPGLVec3); register;
      procedure SetX(AX: GLFloat); register;
      procedure SetY(AY: GLFloat); register;
      procedure SetZ(AZ: GLFloat); register;
      procedure Translate(AX,AY,AZ: GLFloat); register;
      procedure SetAngleX(Angle: GLFloat); register;
      procedure SetAngleY(Angle: GLFloat); register;
      procedure SetAngleZ(Angle: GLFloat); register;
      procedure SetAngles(AX: GLFLoat = 0; AY: GLFLoat = 0; AZ: GLFLoat = 0); overload; register;
      procedure SetAngles(AAngles: TPGLVec3); overload; register;
      procedure SetOrigin(AOrigin: TPGLVec3); register;
      procedure RotateX(AValue: GLFloat); register;
      procedure RotateY(AValue: GLFloat); register;
      procedure RotateZ(AValue: GLFloat); register;
      procedure Rotate(AX: GLFloat = 0; AY: GLFloat = 0; AZ: GLFloat = 0); overload; register;
      procedure Rotate(AValues: TPGLVec3); overload; register;
      procedure SetTextureRect(ARect: TPGLRectI; AUpdateBounds: Boolean = True); register;
      procedure SetColorValues(AValues: TPGLColorF); register;
      procedure SetColorOverlay(AColor: TPGLColorF); register;
      procedure SetGreyScale(AEnable: Boolean = True); register;
      procedure SetMonoChrome(AEnable: Boolean = True); register;
      procedure SetBrightness(AValue: GLFloat); register;
      procedure SetOpacity(AValue: GLFloat); register;
      procedure SetSubRect(AIndex: GLUInt; ARect: TPGLRectI); register;
      procedure UseSubRect(AIndex: GLUInt; AUpdateBounds: Boolean = True); register;
      function GetTexCoords(): TArray<TPGLVec3>; register;

      // resets
      procedure ResetBounds(); register;
      procedure ResetColors(); register;
      procedure ResetRotations(); register;
      procedure Reset(); register;

  end;


  type TPGLShape = class(TObject)
    private
      fPointCount: GLUint;
      fCenter: TPGLVec3;
      fWidth,fHeight: GLFloat;
//      fVertices: Array of TPGLVertex;
      fShapeType: GLInt;
      fTexture: TPGLTexture;

    const
      CIRCLE_SHAPE = 0;
      RECTANGLE_SHAPE = 1;

      function GetVertex(I: GLUint): TPGLVertex; register;
      function GetElements(): TArray<GLInt>; register;

    public
      Vertex: Array of TPGLVertex;

      property PointCount: GLUint read fPointCount;
      property Center: TPGLVec3 read fCenter;
      property Width: GLFloat read fWidth;
      property Height: GLFloat read fHeight;
      property Texture: TPGLTexture read fTexture;
//      property Vertex[Index: GLUint]: TPGLVertex read GetVertex;

      constructor Create(APointCount: GLUInt); overload; register;
      constructor CreateCircle(ARadius: GLFloat = 1; APointCount: GLInt = -1); overload; register;
      constructor CreateRectangle(AWidth: GLFLoat = 1; AHeight: GLFloat = 1); overload; register;

      procedure SetColor(AColor: TPGLColorF); register;
      procedure SetCenter(ACenter: TPGLVec3); register;
      procedure PlaceVertex(AIndex: GLUint; APosition: TPGLVec3); register;
      procedure SetTexture(ATexture: TPGLTexture); overload; register;
      procedure Translate(AValues: TPGLVec3); register;


  end;

  type TPGLCharacter = record
    public
      Symbol: Char;
      Width,Height: GLInt;
      GlyphWidth,GlyphHeight: GLInt;
      Advance: GLFloat;
      TailHeight: GLFloat;
      BearingX, BearingY: GLFloat;
      xMin,xMax,yMin,yMax: GLFloat;
      Origin: GLFloat;
      SDFDiff: GLFloat;
      Position: TPGLVec2;
      Bounds: TPGLRectI;
  end;


  type
    TPGLAtlas = class;
    TPGLFont = class;

    TPGLAtlas = Class(TPersistent)
      private
        fParent: TPGLFont;
        fTexture: TPGLTexture;
        fCharacter: Array [32..128] of TPGLCharacter;
        Width,Height: GLInt;
        Origin: GLFloat;
        PointSize: GLInt;
        GlyphType: GLInt;

        const glyph_type_normal: GLInt = 0;
        const glyph_type_sdf: GLInt = 1;

        constructor Create(AParent: TPGLFont); register;
        destructor Destroy(); override; register;

        procedure MakeSDF(AFontName: String; APointSize: GLInt); register;
        procedure MakeNormal(AFontName: String; APointSize: GLUInt); register;
        procedure SaveCharReport(APath: String); register;
        function GetTextWidth(AText: String): GLFloat; register;

      public
        property Texture: TPGLTexture read fTexture;
    end;

    TPGLFont = Class(TObject)
      private
        fName: String;
        fFontPath: String;
        fResolution: TPoint;
        fAtlas: Array of TPGLAtlas;

        destructor Destroy(); override; register;
        procedure Free(); register;

        function GetAtlas(Index: Integer): TPGLAtlas; register;
        function SelectAtlas(APointSize: GLInt): TPGLAtlas; register;

        procedure MakeNormals(AFontName: String); register;
        procedure MakeSDFs(AFontName: String); register;

      public
        property Atlas[Index: Integer]: TPGLAtlas read GetAtlas;

        constructor Create(AFontName: String; ACreateSDFFont: Boolean = False); overload;
        constructor Create(AFontName: String; AResolution: TPoint; ACreateSDFFont: Boolean = False); overload;
        procedure Refresh(); register;
        function GetCharacter(ACharacter: Char; APointSize: GLInt): TPGLCharacter; register;
    end;

  type TPGLText = Class(TObject)
    private
      fBounds: TPGLRectF;
      fTextWidth,fTextHeight: GLFloat;
      fText: String;
      fPointSize: GLUInt;
      fTextLines: Array of String;
      fLineWidths: Array of GLFloat;
      fFont: TPGLFont;
      fAtlasUsing: TPGLAtlas;
      fTextColor: TPGLColorF;
      fBackColor: TPGLColorF;
      fCentered: Boolean;
      fBoundsLocked: Boolean;
      fLockWidth: GLFloat;
      fLockHeight: GLFloat;
      fLockYOffSet: GLFloat;
      fLockYMaxOffSet: GLFloat;

      destructor Destroy(); override; register;
      procedure Free(); register;

      procedure SetTextProp(const AText: String); register;
      procedure SetTextNoLock(AText: String); register;
      procedure SetTextLocked(AText: String); register;
      function GetTextLineWidth(AIndex: GLInt): GLFloat; register;
      procedure UpdateBounds(); register;
      function GetBounds(): TPGLRectF; register;
      function GetNumLines(): GLInt; register;
      function GetLineBounds(I: GLInt): TPGLRectF; register;
      procedure Reset(); register;

    public
      property Bounds: TPGLRectF read GetBounds;
      property Text: String read fText write SetTextProp;
      property Font: TPGLFont read fFont;
      property TextColor: TPGLColorF read fTextColor;
      property BackColor: TPGLCOlorF read fBackColor;
      property Centered: Boolean read fCentered;
      property PointSize: GLUint read fPointSize;
      property BoundsLocked: Boolean read fBoundsLocked;
      property LockWidth: GLFloat read fLockWidth;
      property LockHeight: GLFloat read fLockHeight;
      property LockedBoundsYOffset: GLFloat read fLockYOffSet;
      property LockedBoundsYMaxOffset: GLFloat read fLockYMaxOffset;
      property MaxTextWidth: GLFloat read fTextWidth;
      property MaxTextHeight: GLFloat read fTextHeight;
      property NumLines: GLInt read GetNumLines;
      property LineBounds[Index: GLInt]: TPGLRectF read GetLineBounds;

      constructor Create(); overload; register;
      constructor Create(AFont: TPGLFont; AText: String = ''; APointSize: GLUInt = 12); overload; register;

      procedure SetText(const AText: String); register;
      procedure SetPointSize(ASize: GLUint); register;
      procedure SetTextColor(AColor: TPGLColorF); register;
      procedure SetBackColor(AColor: TPGLColorF); register;
      procedure KeepCentered(ACentered: Boolean = True); register;
      procedure LockBounds(ALock: Boolean = True); register;
      procedure SetLockedSize(ALockedWidth, ALockedHeight: GLUint); register;
      procedure SetLockedWidth(ALockedWidth: GLUint); register;
      procedure SetLockedHeight(ALockedHeight: GLUint); register;
      procedure SetLockedBoundsYOffSet(AOffSet: GLFloat); register;
      procedure IncLockedBoundsYOffSet(AValue: GLFloat); register;

      procedure SetLeft(ALeft: GLFloat); register;
      procedure SetTop(ATop: GLFloat); register;
      procedure SetCenter(ACenter: TPGLVec3); register;

      procedure WriteToTexture(ATexture: TPGLTexture); register;

  end;


  type TPGLRenderTarget = Class(TObject)


    {$A16}
    type TPGLGlobalDrawValues =  record
      ColorValues: TPGLColorF;
      ColorOverlay: TPGLColorF;
      Brightness: GLFloat;
      TargetWidth: GLFloat;
      TargetHeight: GLFloat;
      ViewNear, ViewFar: GLFLoat;
      GreyScale: GLInt;
      MonoChrome: GLInt;
      BlitOpacity: GLFloat;
    end;
    {$A8}

    private

      // gl objects
      fFrameBuffer: GLUint;
      fAttachment: TPGLTexture;
      fOwnedTexture: GLUint;
      fTexture2D: GLUint;
      fBackTexture2D: GLUint;
      fDepthBuffer: GLUint;
      fNormalMap: GLUInt;
      fPositionMap: GLUint;
      TextParams: TPGLTextParams;
      fAngleX, fAngleY, fAngleZ: GLFLoat;

      // attributes
      fWidth,fHeight: GLInt;
      fClearColor: TPGLColorF;
      fClearDepth: GLFloat;
      fColorValues: TPGLVec3;
      fRenderRect: TPGLRectI;

      // states
      GlobalDrawValues: TPGLGlobalDrawValues;
      fDepthAttach: Boolean;
      fDrawOffset: TPGLVec3;

      constructor Create(AWidth,AHeight: GLUInt); register;
      destructor Destroy(); override; register;
      procedure Free(); register;

      procedure CreateFBO(AWidth,AHeight: GLUint); register;
      function GetAngles(): TPGLVec3; register;
      procedure ChangeSize(); register;


      procedure DrawPointBatch(); register;
      procedure DrawCircleBatch(); register;
      procedure DrawRectangleBatch(); register;
      procedure DrawSpriteBatch(); register;
      procedure DrawTextureBatch(); register;
      procedure DrawShapeBatch(); register;
      procedure DrawLineBatch(); register;
      procedure DrawChars(AAtlas: TPGLAtlas; ABackColor: TPGLColorF); register;
      procedure DrawLightBatch(); register;

    public
      property Width: GLInt read fWidth;
      property Height: GLInt read fHeight;
      property ClearColor: TPGLColorF read fClearColor;
      property ClearDepth: GLFLoat read fClearDepth;
      property ColorValues: TPGLColorF read GlobalDrawValues.ColorValues;
      property ColorOverlay: TPGLColorF read GlobalDrawValues.ColorOverlay;
      property Brightness: GLFloat read GlobalDrawValues.Brightness;
      property GreyScale: GLInt read GlobalDrawValues.GreyScale;
      property MonoChrome: GLInt read GlobalDrawValues.MonoChrome;
      property BlitOpacity: GLFloat read GlobalDrawValues.BlitOpacity write GlobalDrawValues.BlitOpacity;
      property RenderRect: TPGLRectI read fRenderRect;
      property DrawOffset: TPGLVec3 read fDrawOffset;
      property AngleX: GLFloat read fAngleX;
      property AngleY: GLFloat read fAngleY;
      property AngleZ: GLFloat read fAngleZ;
      property Angles: TPGLVec3 read GetAngles;
      property DepthBufferAttached: Boolean read fDepthAttach;
      property LastTextBounds: TPGLRectF read TextParams.LastTextBounds;
      property ScaleFontPointSizes: Boolean read TextParams.ScalePointSizes;

      procedure MakeCurrentTarget(); register;

      // set attributes and fields
      procedure SetClearColor(AColor: TPGLColorF); register;
      procedure SetClearDepth(ADepth: GLFloat); register;
      procedure SetColorValues(AValues: TPGLColorF); register;
      procedure SetColorOverlay(AValues: TPGLColorF); register;
      procedure SetBrightness(AValue: GLFloat); register;
      procedure SetGreyScale(AGreyScale: Boolean = True); register;
      procedure SetMonoChrome(AMonoChrome: Boolean = True); register;
      procedure SetAngleX(AX: GLFloat); register;
      procedure SetAngleY(AY: GLFloat); register;
      procedure SetAngleZ(AZ: GLFloat); register;
      procedure SetAngles(AAngles: TPGLVec3); register;
      procedure RotateX(AX: GLFloat); register;
      procedure RotateY(AY: GLFloat); register;
      procedure RotateZ(AZ: GLFloat); register;
      procedure Rotate(AAngles: TPGLVec3); register;
      procedure SetDrawOffSet(AOffSet: TPGLVec3); register;
      procedure SetDrawOffSetX(AOffSetX: GLFloat); register;
      procedure SetDrawOffSetY(AOffSetY: GLFloat); register;

      // drawing
      procedure Clear(); overload; register;
      procedure Clear(AColor: TPGLColorF); overload; register;
      procedure DistanceLight(); register;
      procedure ReplaceColor(ARect: TPGLRectI; AOldColor,ANewColor: TPGLColorF); register;
      procedure AdjustColors(AColors: TPGLColorF); register;
      procedure AdjustColorScale(AColors: TPGLColorF); register;
      procedure Darken(ARect: TPGLRectI; ALightValue: GLFloat); register;

      // draw functions
      Procedure DrawLastBatch(); register;

      procedure DrawPoint(APoint: TPGLVec3; AColor: TPGLColorF; ASize: Single); register;
      procedure DrawSprite(var ASprite: TPGLSprite); register;
      function DrawCircle(ACenter: TPGLVec3; ARadius: GLFLoat; ABorderWidth: GLFloat; AColor: TPGLColorF; ABorderColor: TPGLColorF): TArray<TPGLVec3>; register;
      procedure DrawRectangle(ARect: TPGLRectF; AColor: Cardinal = 0; ABorderColor: Cardinal = $00000000; ABorderWidth: GLFloat = 00000000); register;
      procedure DrawRoundRectangle(ARect: TPGLRectF; AColor, ABorderColor: GLUint; ABorderWidth: GLFloat = 0; ACornerSize: GLFloat = 0); register;
      procedure DrawTexture(ATexture: TPGLTexture; ASrcRect, ADestRect: TPGLRectF); register;
      procedure DrawShape(var AShape: TPGLShape); register;
      procedure DrawLine(AStart,AEnd: TPGLVec3; AWidth: GLFloat; AColor: TPGLColorF); register;
      procedure DrawText(AText: String; AFont: TPGLFont; ASize: GLFloat; Position: TPGLVec3; AColor, ABackColor: TPGLColorF); overload; register;
      procedure DrawText(AText: TPGLText); overload; register;
      procedure DrawPointLight(ACenter: TPGLVec3; ARadius: GLFloat; AThreshold: GLFloat = 0; AColor: Cardinal = $FFFFFFFF; AGlobalLight: GLFloat = 1); register;

      // copy functions
      procedure CopyFromTexture(var ASource: TPGLTexture; ASourceRect: TPGLRectI; ADestX, ADestY: GLInt); register;
      procedure CopyFromData(AData: Pointer; ADataWidth, ADataHeight: GLInt; ADestRect, ASourceRect: TPGLRectI); register;
      procedure CopyToTarget(ATarget: TPGLRenderTarget; ASourceRect: TPGLRectI; ADestRect: TPGLRectI); register;
      procedure Blit(ATarget: TPGLRenderTarget; ASourceRect, ADestRect: TPGLRectI; ABlitMode: PPGLBlitMode = nil); register;

      // effects
      procedure Pixelate(APixelSize: GLUInt = 2); register;

      // utility
      procedure SaveToFile(AFileName: String); register;
      procedure SaveDepthToFile(AFileName: String); register;
      procedure SaveNormalToFile(AFileName: String); register;
      procedure GetDepthData(var [ref] ADestPtr: Pointer); register;
      procedure AttachDepthBuffer(AAttach: Boolean = True); register;
      procedure AttachTexture(var ATexture: TPGLTexture); register;
      procedure RestoreTexture(); register;

  end;


  type TPGLRenderTexture = Class(TPGLRenderTarget)
    private

      Destructor Destroy(); override; register;
      procedure Free(); register;

    public
      constructor Create(AWidth,AHeight: GLInt); register;

      procedure SetSize(AWidth,AHeight: GLUInt); register;

  end;

  type TPGLWindow = Class(TPGLRenderTarget)

    private
      fCloseFlag: GLInt;
      fLeft,fRight,fTop,fBottom: GLInt;
      fOSHandle: HWND;
      fDC: HDC;
      fScreenWidth,fScreenHeight: GLInt;

      // window attributes
      fTitle: String;
      fHasTitleBar: Boolean;
      fSizable: Boolean;
      fFullScreen: Boolean;
      fMaximized: Boolean;
      fMinimized: Boolean;
      fHasFocus: Boolean;
      fKeepCentered: Boolean;
      fDisplayRect: TPGLRectI;

      // procs
      fMaximizeProc: TPGLWindowProc;
      fMinimizeProc: TPGLWindowProc;
      fGotFocusProc: TPGLWindowProc;
      fLostFocusProc: TPGLWindowProc;

    public
      property CloseFlag: GLInt read fCloseFlag;
      property Left: GLInt read fLeft;
      property Right: GLInt read fRight;
      property Top: GLInt read fTop;
      property Bottom: GLInt read fBottom;
      property Title: String read fTitle;
      property OSHandle: HWND read fOSHandle;
      property DC: HDC read fDC;
      property ScreenWidth: GLInt read fScreenWidth;
      property ScreenHeight: GLInt read fScreenHeight;
      property HasTitleBar: Boolean read fHasTitleBar;
      property Sizable: Boolean read fSizable;
      property FullScreen: Boolean read fFullScreen;
      property Maximized: Boolean read fMaximized;
      property Minimzed: Boolean read fMinimized;
      property HasFocus: Boolean read fHasFocus;
      property KeepCentered: Boolean read fKeepCentered;

      property GotFocusProc: TPGLWindowProc read fGotFocusProc;
      property LostFocusProc: TPGLWindowProc read fLostFocusProc;

      constructor Create(AWidth: GLInt = 800; AHeight: GLInt = 600; ATitle: String = 'Window'; AFormat: PPGLWindowFormat = nil; ASettings: PPGLFeatureSettings = nil); register;
      procedure Update(); register;
      procedure Close(); register;
      procedure Finish(); register;

      // called from PGL callbacks
      procedure UpdatePosition(); register;

      // set attributes and state
      procedure SetTitle(ATitle: String = ''); register;
      procedure SetScreenCenter(); register;
      procedure SetKeepCentered(ACentered: Boolean = True); register;
      procedure SetHasTitleBar(ATitleBar: Boolean = True); register;
      procedure SetSizable(ASizable: Boolean = True); register;
      function SetWidth(AWidth: GLUint): Boolean; register;
      function SetHeight(AHeight: GLUint): Boolean; register;
      function SetSize(AWidth, AHeight: GLUint): Boolean; register;
      procedure SetFullScreen(AFullScreen: Boolean = True); register;
      procedure SetPosition(APosition: TPGLVec2); register;

      // set procs
      procedure SetMaximizeProc(AProc: TPGLWindowProc); register;
      procedure SetMinimizeProc(AProc: TPGLWindowProc); register;
      procedure SetGotFocusProc(AProc: TPGLWindowProc); register;
      procedure SetLostFocusProc(AProc: TPGLWindowProc); register;
      procedure SetWindowCloseProc(AProc: TPGLWindowProc); register;

  end;


  type TPGLDrawState = record
    private
      State: String;
      Buffers: TPGLBuffers;
      CurrentTarget: TPGLRenderTarget;
      CurrentProgram: TPGLProgram;
      ColorCompareThreshold: GLFloat;
      TransparentColor: TPGLColorF;
      Camera: TPGLCamera;
      OwnedCamera: TPGLCamera;
      ViewNear, ViewFar: GLFLoat;
      Params: TPGLDrawParams;
  end;


  type TPGLInstance = class(TObject)

    protected
      // PGL states and global variables
      fContext: TPGLContext;
      fRunning: Boolean;
      fDebug: Boolean;
      fEXEPath: String;
      fSourcePath: String;
      fWindow: TPGLWindow;
      fKeyBoard: TPGLKeyBoard;
      fMouse: TPGLMouse;
      fController: TPGLController;

      TempBuffer: TPGLRenderTexture;
      TempSprite: TPGLSprite;
      DrawState: TPGLDrawState;
      BlitMode: TPGLBlitMode;
      fLightReferenceBuffer: TPGLRenderTarget;

      // gl State values
      fMinVer,fMajVer: GLInt;
      fMaxUBOSize: GLInt;
      fMaxTexUnits: GLInt;
      fMaxSamplerUnits: GLInt;
      fMaxAnisoTrophy: GLInt;
      fTexUnit: Array of GLUint;
      fDepthWrite: Boolean;
      fAlphaChannel: Boolean;
      fDrawFilter: TPGLDrawFilter;
      fAnisotropy: GLInt;
      fL3CacheSize: GLInt;
      fL2CacheSize: GLInt;
      fL1CacheSize: GLInt;


      // object caches
      fProgramList: Array of TPGLProgram;
      fSampler: GLUint;
      fImages: Array of TPGLImage;
      fTextures: Array of TPGLTexture;
      fSprites: Array of TPGLSprite;
      fRenderTextures: Array of TPGLRenderTexture;
      fFonts: Array of TPGLFont;
      fTexts: Array of TPGLText;

      fErrorLog: Array of String;

      // callback skips
      fSkipPosCallback: Boolean;

      // main loop proc
      fMainLoop: TPGLProc;

      // Setup
      constructor Create(); register;
      destructor Destroy(); override; register;
      procedure Free(); register;

      procedure CreateShaders(); register;
      procedure CreateSamplers(); register;
      function GetTextureUnit(Index: GLUInt): GLUint;

      procedure UpdateDrawState(ANewTarget: TPGLRenderTarget); register;

      // Private Factories

      procedure AddImage(var AImage: TPGLImage); register;
      procedure RemoveImage(var AImage: TPGLImage); register;

      procedure GenTexture(var ATexture: TPGLTexture); register;
      procedure AddTexture(var ATexture: TPGLTexture); register;
      procedure RemoveTexture(var ATexture: TPGLTexture); register;

      procedure AddSPrite(var ASprite: TPGLSprite); register;
      procedure RemoveSprite(var ASprite: TPGLSprite); register;

      procedure AddFont(var AFont: TPGLFont); register;
      procedure RemoveFont(var AFont: TPGLFont); register;

      procedure AddText(var AText: TPGLText); register;
      procedure RemoveText(var AText: TPGLText); register;

      procedure AddRenderTexture(var ARenderTexture: TPGLRenderTexture); register;
      procedure RemoveRenderTexture(var ARenderTexture: TPGLRenderTexture); register;

      // object state updates
      procedure UpdateFontRefresh(var AFont: TPGLFont); register;
      procedure UpdateFontDestroy(var AFont: TPGLFont); register;
      procedure UpdateTextureDestroy(var ATexture: TPGLTexture); register;

      // object queries

      function GetImageCount(): GLInt; register;
      function GetTextureCount(): GLInt; register;
      function GetSpriteCount(): GLInt; register;
      function GetFontCount(): GLInt; register;
      function GetTextCount(): GLInt; register;
      function GetRenderTextureCount(): GLInt; register;

    public
      property Context: TPGLContext read fContext;
      property Running: Boolean read fRunning;
      property MinorVersion: GLInt read fMinVer;
      property MajorVerion: GLInt read fMajVer;
      property EXEPath: String read fEXEPath;
      property SourcePath: String read fSourcePath write fSourcePath;
      property KeyBoard: TPGLKeyBoard read fKeyBoard;
      property Mouse: TPGLMouse read fMouse;
      property Controller: TPGLController read fController;
      property ColorCompareThreshold: GLFloat read DrawState.ColorCompareThreshold;
      property TransparentColor: TPGLColorF read DrawState.TransparentColor;
      property TextureUnit[Index: GLUInt]: GLUint read GetTextureUnit;
      property DepthWrite: Boolean read fDepthWrite;
      property AlphaChannel: Boolean read fAlphaChannel;
      property DrawFilter: TPGLDrawFilter read fDrawFilter;
      property LightReferenceBuffer: TPGLRenderTarget read fLightReferenceBuffer;

      property ImageCount: GLInt read GetImageCount;
      property TextureCount: GLInt read GetTextureCount;
      property SpriteCount: GLInt read GetSpriteCount;
      property FontCount: GLInt read GetFontCount;
      property TextCount: GLInt read GetTextCount;
      property RenderTextureCount: GLInt read GetRenderTextureCount;
      property Camera: TPGLCamera read DrawState.Camera;

      // program control
      procedure Init(var AWindow: TPGLWindow; AWidth,AHeight: GLInt; ATitle: String; AFormat: PPGLWindowFormat = nil; ASettings: PPGLFeatureSettings = nil); register;
      procedure Run(AMainLoop: TPGLProc); register;
      procedure Quit(); register;

      // Change State
      procedure SetColorCompareThreshold(AValue: GLFloat); register;
      procedure SetTransparentColor(AColor: TPGLColorF); register;
      procedure SelectCamera(ACamera: TPGLCamera); register;
      procedure SetViewRange(ANear,AFar: GLFloat); register;
      procedure EnableDepthWrite(); register;
      procedure DisableDepthWrite(); register;
      procedure EnableAlphaChannel(); register;
      procedure DisableAlphaChannel(); register;
      procedure SetDrawFilter(AFilter: TPGLDrawFilter); register;
      procedure SetAnisotropy(AValue: GLInt); register;

      // public factories
      procedure DeleteImage(var AImage: TPGLImage); register;
      procedure DeleteTexture(var ATexture: TPGLTexture); register;
      procedure DeleteSprite(var ASprite: TPGLSPrite); register;
      procedure DeleteFont(var AFont: TPGLFont); register;
      procedure DeleteText(var AText: TPGLText); register;
      procedure DeleteRenderTexture(var ARenderTexture: TPGLRenderTexture); register;

      // Queries
      procedure OutputTextureBindings(); register;

      // select targets and programs
      function SetCurrentTarget(var ATarget: TPGLRenderTarget): Boolean; register;
      procedure UseProgram(AName: String); register;
      function GetUniform(AName: String): GLInt; register;
      procedure BindTexture(ATextureUnit: GLUint = 0; ATextureHandle: GLUint = 0); overload; register;
      procedure BindTexture(ATextureUnit: GLUint; var ATexture: TPGLTexture); overload; register;
      procedure UnbindTexture(var ATexture: TPGLTexture); overload; register;
      procedure UnbindTexture(ATextureHandle: GLUint = 0); overload; register;
      procedure UnbindAllTextures(); register;
      procedure SetLigthReferenceBuffer(ATarget: TPGLRenderTarget); register;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                Helpers
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


  type TPGLTextureHelper = Class helper for TPGLTexture
    public
      procedure CopyFrom(ARenderTarget: TPGLRenderTarget); overload; register;
      procedure CopyFrom(ARenderTarget: TPGLRenderTarget; ASrcRect,ADestRect: TPGLRectI); overload; register;
  end;



{$ENDREGION}


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                Procedures
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

{$REGION 'PROCEDURES'}
  // callbacks

  // debug
  procedure pglDebug(source: GLEnum; ErrorType: GLEnum; ID: GLUInt; Severity: GLUInt; MessageLength: GLsizei; const ErrorMessage: PGLCHar; userParam: Pointer); stdcall;

    // Window
  procedure UpdateWindowSize(AWindow: TPGLWindow; AWidth, AHeight: GLInt); register;
  procedure WindowMaximize(AWindow: TPGLWindow); register;
  procedure WindowMinimize(AWindow: TPGLWindow); register;

  // Programs
  function LoadShader(var AVShader: GLUint; var AFShader: GLUint; APath: String): String; register;

  // images/image data
  procedure pglResizeRGBAData(var AData: PByte; ADataWidth,ADataHeight,ADataNewWidth,ADataNewHeight: GLUint); register;

  // textures
  procedure pglSaveGLTexture(ATexture: GLUint; AFileName: String); register;
  procedure pglSaveWindowBuffer(AFileName: String); register;
  procedure pglDataToRGBA(var AData: TArray<Byte>; ARedSize, AGreenSize, ABlueSize, AlphaSize: GLInt); register;

  // blits/draw state
  function pglBlitMode(ABlendMode: TPGLBlitBlend; ADepthMode: TPGLBlitDepth): PPGLBlitMode; register;

  // colors
  Function pglMixColorS(AColors: TArray<TPGLColorF>): TPGLColorF; register;

  // strings/text
  function pglFindSubString(AText: String; ASubString: String): TArray<GLint>;
  function pglTextToWordArray(AText: String; ADelimiters: String = ''; ARemoveDelimiters: Boolean = True): TArray<String>; register;
  procedure pglRemoveChars(var AText: String; AChars: TArray<Char>); register;
  function pglParseBetween(AText: String; AStartChar: Char; AEndChar: Char): TArray<String>; register;
  procedure pglWriteFile(AFileName: String; AText: String); register;
  function pglReadFile(AFileName: String): String; register;

{$ENDREGION}

var
  PGL: TPGLInstance;

  // Shader global draw values source insert
  GlobalHeader, GlobalBody: AnsiString;

  // OpenGL procedures
  glBlitNamedFramebuffer: procedure(readBuffer: GLUint; drawBuffer: GLUint; srcX0: GLint; srcY0: GLint; srcX1: GLint; srcY1: GLint; dstX0: GLint; dstY0: GLint; dstX1: GLint; dstY1: GLint; mask: GLbitfield; filter: GLenum); stdcall;
  glBindTextureUnit: procedure(ATexUnit: GLUint; ATexHandle: GLUint); stdcall;

const
  screen_width = 1001;
  screen_height = 1002;

implementation

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                Procedures
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


procedure pglDebug(source: GLEnum; ErrorType: GLEnum; ID: GLUInt; Severity: GLUInt; MessageLength: GLsizei; const ErrorMessage: PGLCHar; userParam: Pointer); stdcall;
var
ErrorString: String;
I: Integer;
  begin

    if ErrorType = GL_DEBUG_TYPE_OTHER then exit;

    ErrorString := String(ErrorMessage);

    SetLength(PGL.fErrorLog, Length(PGL.fErrorLog) + 1);
    I := High(PGL.fErrorLog);
    PGL.fErrorLog[i] := ErrorString;

    AllocConsole();
    WriteLn(PGL.fErrorLog[i] + sLineBreak + sLineBreak);

    DebugBreak();

  end;


procedure UpdateWindowSize(AWindow: TPGLWindow; AWidth, AHeight: GLInt);
  begin
    AWindow.fWidth := AWidth;
    AWindow.fHeight := AHeight;

    if AWindow.fKeepCentered then begin
      AWindow.SetScreenCenter();
    end;
  end;

procedure WindowMaximize(AWindow: TPGLWindow);
  begin
    AWindow.fMaximized := True;
    AWindow.fMinimized := False;

    if Assigned(AWindow.fMaximizeProc) then begin
      AWindow.fMaximizeProc();
    end;
  end;

procedure WindowMinimize(AWindow: TPGLWindow);
  begin
    AWindow.fMaximized := False;
    AWindow.fMinimized := True;

    if Assigned(AWindow.fMinimizeProc) then begin
      AWindow.fMinimizeProc();
    end;
  end;


function LoadShader(var AVShader: GLUint; var AFShader: GLUint; APath: String): String;
var
InFile: HFILE;
FileStruct: OFSTRUCT;
DirName: String;
Source: Array [0..9999] of AnsiChar;
SourceString: AnsiString;
SourceLength: GLUint;
I: GLInt;
Pos: GLInt;
Success: LongBool;
Status: GLInt;
InfoLog: Array [0..511] of AnsiChar;
  begin

      if DirectoryExists(APath) = False then exit; // exit if directory doesn't exit
      if APath[Length(APath)] <> '\' then exit;    // exit if string not in right format

      // Get the directory name
      I := Length(APath);
      Pos := I;

      while Pos > 0 do begin
        Pos := Pos - 1;
        if APath[Pos] = '\' then begin
          break;
        end;
      end;

      DirName := Copy(APath,Pos + 1,Length(APath) - Pos - 1);

      // load the vertex shader source
      if FileExists(APath + DirName + '.vert') = False then exit; // exit if vertex shader doesn't exist

      // open the file, read out entire contents, close it
      InFile := CreateFile(PWideChar(APath + DirName + '.vert'),GENERIC_READ,FILE_SHARE_READ,nil,OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL, 0);

      Success := ReadFile(InFile, Source[0], 9999, SourceLength, nil);
      CloseHandle(InFile);

      SourceString := Copy(Source,0,SourceLength);
      SourceString := StringReplace(SourceString, AnsiString('/* INSERT GLOBAL VALUES HEADER */'), GlobalHeader, [rfReplaceAll]);

      SourceLength := Length(SourceString);

      // create the vertex shader
      AVShader := glCreateShader(GL_VERTEX_SHADER);
      glShaderSource(AVShader,1,@SourceString,@SourceLength);
      glCompileShader(AVShader);

      // check compile status
      glGetShaderiv(AVShader, GL_COMPILE_STATUS, @Status);

      if Status = 0 then begin
        glGetShaderInfoLog(AVShader, 512, nil, @InfoLog[0]);
        pglDebug(AVShader, 0, 0, 3, 512, @InfoLog[0], nil);
      end;

      // load the fragment shader source
      if FileExists(APath + DirName + '.frag') = False then exit; // exit if fragment shader doesn't exist

      // open the file, read out entire contents, close it
      InFile := CreateFile(PWideChar(APath + DirName + '.frag'),GENERIC_READ,FILE_SHARE_READ,nil,OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL, 0);

      Success := ReadFile(InFile, Source[0], 9999, SourceLength, nil);
      CloseHandle(InFile);

      SourceString := Copy(Source,0,SourceLength);

      SourceString := StringReplace(SourceString, AnsiString('/* INSERT GLOBAL VALUES HEADER */'), GlobalHeader, [rfReplaceAll]);
      SourceString := StringReplace(SourceString, AnsiString('/* INSERT GLOBAL VALUES BODY */'), GlobalBody, [rfReplaceAll]);

      SourceLength := Length(SourceString);

      // create the fragment shader
      AFSHader := glCreateShader(GL_FRAGMENT_SHADER);
      glShaderSource(AFSHader,1,@SourceString,@SourceLength);
      glCompileShader(AFSHader);

      glGetShaderiv(AFShader, GL_COMPILE_STATUS, @Status);

      if Status = 0 then begin
        glGetShaderInfoLog(AFShader, 512, nil, @InfoLog[0]);
        pglDebug(AFShader, 0, 0, 3, 512, @InfoLog[0], nil);
      end;

      Result := DirName;

  end;


procedure pglResizeRGBAData(var AData: PByte; ADataWidth,ADataHeight,ADataNewWidth,ADataNewHeight: GLUint);
var
XScale,YScale: GLFloat;
I,Z,G,H: GLInt;
SrcPos,DestPos: PByte;
NewData: PByte;
NewDataSize: GLInt;
UseWidth,UseHeight: GLUint;
DestI,DestZ: GLInt;
SrcI,SrcZ: GLInt;
  begin

    // allocate space for new data to be written to
    NewDataSize := (ADataNewWidth * ADataNewHeight) * 4;
    NewData := GetMemory(NewDataSize);

    // decide the upper bounds of the loops, get scales relative to old and new dimensions
    if ADataWidth > ADataNewWidth then begin
      UseWidth := ADataWidth;
      XScale := ADataNewWidth / ADataWidth;
    end else begin
      UseWidth := ADataNewWidth;
      XScale := ADataWidth / ADataNewWidth;
    end;

    if ADataHeight > ADataNewHeight then begin
      UseHeight := ADataHeight;
      YScale := ADataNewHeight / ADataHeight;
    end else begin
      UseHeight := ADataNewHeight;
      YScale := ADataHeight / ADataNewHeight;
    end;

    // loop through pixels and transfer
    for Z := 0 to UseHeight - 1 do begin
      for I := 0 to UseWidth - 1 do begin

        // get correct 'I' and 'Z' values for source and dest
        if ADataWidth = UseWidth then begin
          SrcI := I;
          DestI := trunc(I * XScale);
        end else begin
          SrcI := trunc(I * XScale);
          DestI := I;
        end;

        if ADataHeight = UseHeight then begin
          SrcZ := Z;
          DestZ := trunc(Z * YScale);
        end else begin
          SrcZ := trunc(Z * YScale);
          DestZ := Z;
        end;

        // get the position of relevant pixels in each set of data
        SrcPos := AData;
        SrcPos := SrcPos + (((Srcz * Integer(ADataWidth)) + SrcI) * 4);
        DestPos := NewData;
        DestPos := DestPos + trunc(( (DestZ * Integer(ADataNewHeight)) + DestI) * 4);

        // copy from src to dest
        Move(SrcPos[0], DestPos[0], 4);
      end;
    end;

    // Free image data, reallocate, copy NewData into image data, free NewData
    FreeMemory(AData);
    AData := GetMemory(NewDataSize);
    Move(NewData[0],AData[0],NewDataSize);
    FreeMemory(NewData);
  end;


procedure pglSaveGLTexture(ATexture: GLUint; AFileName: String);
var
W,H: GLInt;
DataSize: GLInt;
Data: TArray<Byte>;
RedComp,GreenComp,BlueComp,AlphaComp: GLInt;
PixelSize: GLInt;
  begin
    PGL.bindTexture(0,ATexture);

    glGetTexLevelParameterIV(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, @W);
    glGetTexLevelParameterIV(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, @H);

    DataSize := (W * H) * 4;
    SetLength(Data, DataSize);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, @Data[0]);
    PGL.BindTexture(0,0);

    stbi_write_bmp(PAnsiChar(AnsiString(AFileName)), W, H, 4, @Data[0]);

  end;

procedure pglSaveWindowBuffer(AFileName: String);
var
DataSize: GLInt;
Data: PByte;
  begin

    DataSize := (PGL.fWindow.Width * PGL.fWindow.Height) * 4;
    Data := GetMemory(DataSize);

    glBindFrameBuffer(GL_FRAMEBUFFER, 0);
    glReadPixels(0,0,PGL.fWindow.Width, PGL.fWindow.Height, GL_RGBA, GL_UNSIGNED_BYTE, Data);

    stbi_write_bmp(PAnsiChar(AnsiString(AFileName)), PGL.fWindow.Width, PGL.fWindow.Height, 4, Data);

    FreeMemory(Data);

    glBindFrameBuffer(GL_FRAMEBUFFER, PGL.DrawState.CurrentTarget.fFrameBuffer);
  end;


procedure pglDataToRGBA(var AData: TArray<Byte>; ARedSize, AGreenSize, ABlueSize, AlphaSize: GLInt);
var
PixelSize: GLInt;
NewSize: GLInt;
NewData: TArray<Byte>;
DataPos,NewDataPos: GLInt;
MultAdj: GLInt;
I: GLint;
  begin

    PixelSize := trunc((ARedSize + AGreenSize + ABlueSize + AlphaSize) / 8);
    MultAdj := 4 - PixelSize;

    NewSize := Length(AData) * (MultAdj + 1);
    SetLength(NewData,NewSize);

    DataPos := 0;
    NewDataPos := 0;

    for I := 0 to trunc(Length(NewData) / 4) - 1 do begin

      // fill red component
      if ARedSize <> 0 then begin
        NewData[NewDataPos] := AData[DataPos];
        Inc(DataPos);
      end else begin
        NewData[NewDataPos] := 0;
      end;

      Inc(NewDataPos);

      // fill green component
      if AGreenSize <> 0 then begin
        NewData[NewDataPos] := AData[DataPos];
        Inc(DataPos);
      end else begin
        NewData[NewDataPos] := 0;
      end;

      Inc(NewDataPos);

      // fill blue component
      if ABlueSize <> 0 then begin
        NewData[NewDataPos] := AData[DataPos];
        Inc(DataPos);
      end else begin
        NewData[NewDataPos] := 0;
      end;

      Inc(NewDataPos);

      // fill alpha component
      if AlphaSize <> 0 then begin
        NewData[NewDataPos] := AData[DataPos];
        Inc(DataPos);
      end else begin
        NewData[NewDataPos] := 255;
      end;

      Inc(NewDataPos);

    end;

    AData := NewData;

  end;


function pglBlitMode(ABlendMode: TPGLBlitBlend; ADepthMode: TPGLBlitDepth): PPGLBlitMode;
  begin
    PGL.BlitMode.BlendMode := ABlendMode;
    PGL.BlitMode.DepthMode := ADepthMode;
    Result := @PGL.BlitMode;
  end;


Function pglMixColorS(AColors: TArray<TPGLColorF>): TPGLColorF;
var
R,G,B,A: GLFloat;
I: GLInt;
  begin

    R := 0;
    G := 0;
    B := 0;
    A := 0;

    for I := 0 to High(AColors) do begin
      IncF(R, AColors[i].Red);
      IncF(G, AColors[i].Green);
      IncF(B, AColors[i].Blue);
      IncF(A, AColors[i].Alpha);
    end;

    Result.Red := R / Length(AColors);
    Result.Green := G / Length(AColors);
    Result.Blue := B / Length(AColors);
    Result.Alpha := A / Length(AColors);

  end;

function pglFindSubString(AText: String; ASubString: String): TArray<GLint>;
// Search the provided text for instances of AChar, return an array of the position of the instances
var
I,R: GLInt;
Len: GLInt;
CurPos: GLInt;
SubPos: GLInt;
  begin

    Len := 0;
    I := 1;

    // iterate through the whole text
    while I <= Length(AText) do begin

      // if char in text position = first char of substring
      if AText[I] = ASubString[1] then begin

        SubPos := 1;
        for R := 2 to Length(ASubString) do begin

          // break if we've gone passed the end of AText
          if I > Length(AText) then Break;

          // if char in text pos = substring position, continue to search
          if AText[I] = ASubString[SubPos] then begin
            Inc(I);
            Inc(SubPos);
          // else, break the loop
          end else begin
            break;
          end;

        end;

        // add to the array if subpos = length of substring
        if SubPos = Length(ASubString) then begin
          Inc(Len);
          SetLength(Result,Len);
          Result[Len - 1] := I;
          Inc(I);
        end;

      // else inc I
      end else begin
        Inc(I);
      end;

    end;

  end;


function pglTextToWordArray(AText: String; ADelimiters: String = ''; ARemoveDelimiters: Boolean = True): TArray<String>; register;
// take a string as input, output an array of the string's individual words/delimited values
// ADelimiters is a space delimited list of delimiters used to split the string.
// Space is used as a delimeter by default.
var
I: GLInt;
WordCount: GLInt;
Words: TArray<String>;
CurPos: GLInt;
Delimiters: TArray<String>;
Spaces: TArray<GLInt>;
  begin
    // Get count and position of spaces in text, set word count to spaces + 1
    Spaces := pglFindSubString(AText, ADelimiters);
    WordCount := Length(Spaces) + 1;
    SetLength(Words, WordCount);

    // get words as MidStr based on space positions
    CurPos := 1;
    for I := 0 to High(Spaces) do begin
      Words[i] := MidStr(AText,CurPos, Spaces[i] - CurPos);
      if ARemoveDelimiters = True then begin
        SetLength(Words[i],Length(Words[i]) - 1);
      end;
      CurPos := Spaces[i] + 1;
    end;

    Words[High(Words)] := MidStr(AText, CurPos, Length(AText) - CurPos + 1);

    Result := Words;

  end;

procedure pglRemoveChars(var AText: String; AChars: TArray<Char>);
// remove chars in the array from the string
Var
I,R: GLInt;
DoInc: Boolean;
  begin
    if length(AText) = 0 then exit;

    I := 1;
    while I <= Length(AText) do begin

      DoInc := True;

      for R := 0 to High(AChars) do begin
        if AText[i] = AChars[r] then begin
          Delete(AText,I,1);
          DoInc := False;
          break;
        end;
      end;

      if DoInc then Inc(I);

    end;

  end;

function pglParseBetween(AText: String; AStartChar: Char; AEndChar: Char): TArray<String>;
// return array of strings that are between instances of AStartChar and AEndChar
// ex. AStartChar = [, AEndChar = ], [Example] returns Example
var
CurPos,StartPos,EndPos: GLInt;
  begin

    CurPos := 1;
    StartPos := 0;
    EndPos := 0;

    while CurPos <= Length(AText) do begin
      if AText[CurPos] = AStartChar then begin
        StartPos := CurPos;
      end;

      if (AText[CurPos] = AEndChar) and (StartPos <> 0) then begin
        EndPos := CurPos;

        SetLength(Result,Length(Result) + 1);
        Result[High(Result)] := MidStr(AText,StartPos + 1, EndPos - StartPos - 1);

        StartPos := 0;
        EndPos := 0;
      end;

      Inc(CurPos);

    end;

  end;


procedure pglWriteFile(AFileName: String; AText: String);
var
OutFile: HFile;
BytesWritten: Cardinal;
  begin
    OutFile := CreateFile(PWideChar(AFileName), GENERIC_WRITE, FILE_SHARE_WRITE or FILE_SHARE_READ, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    WriteFile(OutFile, AText[1], Length(AText) * 2, BytesWritten, nil);
  end;


function pglReadFile(AFileName: String): String;
var
InFile: HFILE;
BuffSize: Int64;
ReadBuff: AnsiString;
BytesRead: Cardinal;
  begin

    InFile := CreateFile(PWideChar(AFileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL, 0);

    GetFileSizeEX(InFile,BuffSize);

    SetLength(ReadBuff,BuffSize);

    ReadFile(InFile, ReadBuff[1], BuffSize, BytesRead, nil);

    CloseHandle(InFile);

    Result := String(ReadBuff);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLProgram
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

class operator TPGLBlitMode.Initialize( out Dest: TPGLBlitMode);
  begin
    Dest.BlendMode := pgl_blend;
    Dest.DepthMode := pgl_no_copy_depth;
  end;

constructor TPGLBlitMode.Create(ABlendMode: TPGLBlitBlend; ADepthMode: TPGLBlitDepth);
  begin
    Self.BlendMode := ABlendMode;
    Self.DepthMode := ADepthMode;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLProgram
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLProgram.Create(APath: String);
var
Status: GLInt;
  begin
    Self.Name := LoadShader(Self.VertexShader, Self.FragmentShader, APath);
    Self.ID := glCreateProgram();

    glAttachShader(Self.ID, Self.VertexShader);
    glAttachShader(Self.ID, Self.FragmentShader);

    glLinkProgram(Self.ID);
    glGetProgramIV(Self.ID, GL_LINK_STATUS, @Self.Valid);

    // delete the shaders
    glDeleteShader(Self.VertexShader);
    glDeleteShader(Self.FragmentShader);

    // validate the program
    glValidateProgram(Self.ID);
    glGetProgramIV(Self.ID, GL_VALIDATE_STATUS, @Status);

    self.ReadUniforms();

  end;

procedure TPGLProgram.ReadUniforms();
var
I: GLInt;
Len: GLInt;
USize: GLInt;
UType: GLEnum;
UName: Array [0..98] of AnsiChar;
  begin

    // get the active uniforms from the program
    // get the count of active uniforms
    glGetProgramIV(Self.ID, GL_ACTIVE_UNIFORMS, @Self.UniformCount);

    // set size of uniform struct array
    SetLength(Self.Uniform, Self.UniformCount);

    // populate the structs with uniform information
    for I := 0 to Self.UniformCount - 1 do begin
      glGetActiveUniform(Self.ID, I, 99, Len, USize, UType, @UName[0]);
      Self.Uniform[i].Name := String(UName);
      Self.Uniform[i].Location := I;
      Self.Uniform[i].DataType := UType;
    end;

  end;


function TPGLProgram.GetUniform(AName: string): GLInt;
var
I: Integer;
ErrMsg: String;
  begin
    Result := -1;

    if Length(Self.Uniform) = 0 then begin
      Result := Self.AddUniform(AName);

    end else begin

      // loop through cached uniform locations and match by name
      for I := 0 to High(Self.Uniform) do begin
        if Self.Uniform[i].Name = AName then begin
          Result := Self.Uniform[i].Location;
          exit;
        end;
      end;

      // if loop finishes, then the uniform hasn't been cached, add a new one
      Result := Self.AddUniform(AName);

    end;

    // send debug message if uniform is not found
    if Result = -1 then begin
      ErrMsg := 'Could not find uniform ' + AName + ' in current program!';
      Debug(0, 0, 0, 3, Length(ErrMsg), PAnsiChar(AnsiString(ErrMsg)), nil);
    end;
  end;

function TPGLProgram.AddUniform(AName: String): GLInt; register;
var
I: Integer;
  begin
    SetLength(Self.Uniform, Length(Self.Uniform) + 1);
    I := High(Self.Uniform);
    Self.Uniform[i].Location := glGetUniformLocation(Self.ID, PAnsiChar(AnsiString(AName)));
    Self.Uniform[i].Name := AName;
    Result := Self.Uniform[i].Location;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                    TPGLVBO
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

procedure TPGLVBO.SubData(ASize: GLUint; AData: Pointer);
  begin
    Self.InUse := True;
    Self.InUseSize := ASize;

    glBindBuffer(GL_ARRAY_BUFFER,Self.Buffer);

    if ASize <= Self.Size then begin
      // use sub data for better performance if data can fit in buffer
      glBufferSubData(GL_ARRAY_BUFFER,0,ASize,AData);
    end else begin
      // if data is too big for buffer, user slower glBufferData call to resize the buffer to the data size
      glBufferData(GL_ARRAY_BUFFER, ASize, AData, GL_STREAM_DRAW);
      Self.Size := Asize;
    end;

  end;

procedure TPGLVBO.SetAttribPointer(AIndex: GLInt; AComponents: GLInt; AType: GLEnum; ANormalize: ByteBool; AStride: GLInt; AOffSet: Integer);
  begin
    PGL.DrawState.Buffers.EnableAttrib(AIndex);

    if (AType <> GL_INT) and (AType <> GL_UNSIGNED_INT) then begin
      glVertexAttribPointer(AIndex, AComponents, AType, ANormalize, AStride, Pointer(AOffSet));
    end else begin
      glVertexAttribIPointer(AIndex, AComponents, AType, AStride, Pointer(AOffSet));
    end;
  end;



{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                    TPGLSSBO
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


procedure TPGLSSBO.SubData(ASize: GLUInt; AData: Pointer);
  begin
    Self.InUse := True;
    Self.InUseSize := ASize;
    glBindBuffer(GL_SHADER_STORAGE_BUFFER,Self.Buffer);

    if ASize <= Self.Size then begin
      // use sub data for better performance if data can fit in buffer
      glBufferSubData(GL_SHADER_STORAGE_BUFFER,0,ASize,AData);
    end else begin
      // if data is too big for buffer, user slower glBufferData call to resize the buffer to the data size
      glBufferData(GL_SHADER_STORAGE_BUFFER, ASize, AData, GL_DYNAMIC_DRAW);
      Self.Size := ASize;
    end;
  end;


procedure TPGLSSBO.BindToBase(AIndex: Integer);
var
ErrString: String;
  begin
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, AIndex, Self.Buffer);

    // produce verbose debug message if buffer is not current in use
    {$IFDEF PGL_VERBOSE_DEBUG_OUTPUT}

    if PGL.Context.Settings.OpenGLDebugContext then begin
      if Self.InUse = false then begin
        ErrString := 'Attempting to bind a TPGLSSBO that has not been flagged as in use. The SSBO likely holds no data. No data will be bound to shader program buffer target';
        Debug(0, 0, 0, 3, length(ErrString), PansiChar(AnsiString(ErrString)), nil);
      end;
    end;

    {$ENDIF}
  end;


procedure TPGLSSBO.Map();
  begin
    if Self.Mapped = false then begin
      if Self.InUse = false then begin
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, Self.Buffer);
        Self.Ptr := glMapBuffer(GL_SHADER_STORAGE_BUFFER, GL_READ_WRITE);
      end;
    end;
  end;


procedure TPGLSSBO.UnMap();
  begin
    If Self.Mapped = true then begin
      glBindBuffer(GL_SHADER_STORAGE_BUFFER, Self.Buffer);
      glUnMapBuffer(GL_SHADER_STORAGE_BUFFER);
    end;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                    TPGLBuffers
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

procedure TPGLBuffers.FillBuffers();
var
I, Z: Integer;
A: Array [0..5] of GLUInt;
Indices: Array [0..95999] of GLUint;
Data: PByte;
  begin

    glGenVertexArrays(1,@Self.VAO);
    glBindVertexArray(Self.VAO);

    // create and fill VBOs
    SetLength(Self.VBO, 5);

    Data := GetMemory(128000);

    for I := 0 to High(Self.VBO) do begin
      glGenBuffers(1,@Self.VBO[i].Buffer);
      glBindBuffer(GL_ARRAY_BUFFER, Self.VBO[i].Buffer);
      glBufferData(GL_ARRAY_BUFFER,128000,Data,GL_STREAM_DRAW);
      Self.VBO[i].Size := 128000;
    end;

    glBindBuffer(GL_ARRAY_BUFFER,0);

    FreeMemory(Data);

    // create and fill SSBOs
    SetLength(Self.SSBO, 5);

    Data := GetMemory(128000);

    for I := 0 to High(Self.SSBO) do begin
      glGenBuffers(1,@Self.SSBO[i].Buffer);
      glBindBuffer(GL_SHADER_STORAGE_BUFFER, Self.SSBO[i].Buffer);
      glBufferData(GL_SHADER_STORAGE_BUFFER,128000,Data,GL_STREAM_DRAW);
      Self.SSBO[i].Size := 128000;

    end;

    glBindBuffer(GL_SHADER_STORAGE_BUFFER, 0);


    glGenBuffers(1,@Self.StaticSSBO);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER,Self.StaticSSBO.Buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, 128000, Data, GL_STREAM_DRAW);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,9,Self.StaticSSBO.Buffer);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, 0);

    FreeMemory(Data);

    // set up variable indice shape EBO
    glGenBuffers(1, @Self.ShapeEBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, Self.ShapeEBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, 96000, nil, GL_STREAM_DRAW);

    // Set Up General use EBO
    glGenBuffers(1,@Self.EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, Self.EBO);

    I := 0;
    Z := 0;

    while I < 96000 do begin
      A[0] := 0 + Z;
      A[1] := 1 + Z;
      A[2] := 3 + Z;
      A[3] := 1 + Z;
      A[4] := 2 + Z;
      A[5] := 3 + Z;

      Move(A[0], Indices[I], SizeOf(Integer) * 6);
      Inc(I,6);
      Inc(Z,4);
    end;

    glBufferData(GL_ELEMENT_ARRAY_BUFFER, 96000, @Indices[0], GL_STREAM_DRAW);

  end;


procedure TPGLBuffers.SelectNextVBO();
var
I: Integer;
  begin
    // find next VBO not in use
    for I := 0 to High(Self.VBO) do begin
      if Self.VBO[i].InUse = False then begin
        Self.CurrentVBO := @Self.VBO[i];
        exit;
      end;
    end;

    // if we leave the loop, no free VBO was found, create a new one
    SetLength(Self.VBO, Length(Self.VBO) + 1);
    I := High(Self.VBO);
    glGenBuffers(1,@Self.VBO[i]);
    Self.CurrentVBO := @Self.VBO[i];
    Self.CurrentVBO.Size := 0;

  end;


procedure TPGLBuffers.SelectNextSSBO;
var
I: Integer;
  begin
    // find next SSBO not in use
    for I := 0 to High(Self.SSBO) do begin
      if Self.SSBO[i].InUse = False then begin
        Self.CurrentSSBO := @Self.SSBO[i];
        exit;
      end;
    end;

    // if we leave the loop, no free SSBO was found, create a new one
    SetLength(Self.SSBO, Length(Self.SSBO) + 1);
    I := High(Self.SSBO);
    glGenBuffers(1,@Self.SSBO[i]);
    Self.CurrentSSBO := @Self.SSBO[i];
    Self.CurrentSSBO.Size := 0;
  end;


procedure TPGLBuffers.SelectStaticSSBO();
  begin
    Self.CurrentSSBO := @Self.StaticSSBO;
  end;


procedure TPGLBuffers.EnableAttrib(AIndex: Integer);
  begin
    if AIndex > High(Self.AttribArray) then begin
      SetLength(Self.AttribArray, AIndex + 1);
    end;

    if Self.AttribArray[AIndex] = False then begin
      Self.AttribArray[AIndex] := True;
      glEnableVertexAttribArray(AIndex);
    end;

  end;


procedure TPGLBuffers.Reset();
var
I: Integer;
  begin
    // invalidate and set not in use VBOs that were used
    for I := 0 to High(Self.VBO) do begin
      if Self.VBO[i].InUse then begin
        Self.VBO[i].InUse := False;
        glInvalidateBufferSubData(Self.VBO[i].Buffer, 0, Self.VBO[i].InUseSize);
      end;
    end;

    // invalidate and set not in use SSBOs that were used
    for I := 0 to High(Self.SSBO) do begin
      if Self.SSBO[i].InUse then begin
        Self.SSBO[i].InUse := False;
        glInvalidateBufferSubData(Self.SSBO[i].Buffer, 0, Self.SSBO[i].InUseSize);
      end;
    end;

    // disable attrib arrays that were enabled
//    for I := 0 to High(Self.AttribArray) do begin
//      if Self.AttribArray[I] = True then begin
//        Self.AttribArray[I] := False;
//        glVertexAttribDivisor(I,0);
//        glDisableVertexAttribArray(I);
//      end;
//    end;

  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                  TPGLDrawParams
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


class operator TPGLDrawParams.Initialize(out Dest: TPGLDrawParams);
  begin
    Dest.DrawCount := 0;
    Dest.VertexCount := 0;
    Dest.ElementCount := 0;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                  TPGLImage
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLImage.Create(AWidth: Cardinal = 1; AHeight: Cardinal = 1);
  begin
    Self.fWidth := AWidth;
    Self.fHeight := AHeight;

    Self.fDataSize := (Self.Width * Self.Height) * 4;
    Self.fData := GetMemory(Self.fDataSize);
    Self.Define();

    Self.fIsValid := True;

    PGL.AddImage(Self);
  end;


constructor TPGLImage.Create(AFileName: string);
var
inWidth,inHeight,inChannels: GLInt;
ImageData: Pointer;
  begin

    if FileExists(AFileName) = False then begin
      AFileName := PGL.EXEPath + 'InvalidImage.png';
    end;

    ImageData := stbi_load(PAnsiChar(AnsiString(AFileName)), inWidth, inHeight, inChannels, 4);
    Self.fWidth := inWidth;
    Self.fHeight := inHeight;

    Self.fDataSize := (Self.Width * Self.Height) * 4;
    Self.fData := GetMemory(Self.fDataSize);
    Self.Define();

    Move(ImageData^, Self.fData[0], Self.fDataSize);

    stbi_image_free(ImageData);

    Self.fIsValid := True;

    PGL.AddImage(Self);
  end;

constructor TPGLImage.Create(var ASourceImage: TPGLImage);
  begin

    if (Assigned(ASourceImage) = False) or (ASourceImage.IsValid = False) then begin
      Self.fIsValid := False;
      exit;
    end;

    Self.fWidth := ASourceImage.Width;
    Self.fHeight := ASourceImage.Height;
    Self.fDataSize := ASourceImage.DataSize;
    Self.fData := GetMemory(Self.fDataSize);
    Move(ASourceImage.fData[0], Self.fData[0], ASourceImage.fDataSize);
    Self.Define();
    Self.fIsValid := True;

    PGL.AddImage(Self);
  end;

constructor TPGLImage.Create(AData: Pointer; AWidth, AHeight: GLUInt);
  begin
    Self.fWidth := AWidth;
    Self.fHeight := AHeight;
    Self.fDataSize := (Self.Width * Self.Height) * 4;
    Self.fData := GetMemory(Self.fDataSize);
    Move(AData^, Self.fData[0], Self.fDataSize);
    Self.Define();
    Self.fIsValid := True;

    PGL.AddImage(Self);
  end;

destructor TPGLImage.Destroy();
var
I: GLInt;
  begin

    for I := 0 to High(Self.fRowPos) do begin
      Self.fRowPos := nil;
    end;

    FreeMemory(Self.fData);

    Inherited;

  end;

procedure TPGLImage.Free();
  begin
    inherited Free();
  end;

procedure TPGLImage.Define();
var
I,P: GLInt;
  begin
    // set pointers to beginning of rows
    SetLength(Self.fRowPos, Self.Height);

    P := Self.Height - 1;
    for I := 0 to Self.Height - 1 Do Begin
      Self.fRowPos[P] := Self.fData;
      Self.fRowPos[P] := Self.fRowPos[P] + ((Self.Width * 4) * I);
      Dec(P);
    end;

  end;

function TPGLImage.GetPixelPos(AX: Cardinal; AY: Cardinal): PByte;
  begin
    // return beginning of data if AX or AY are outside of bounds
    if (AX > Cardinal(Self.Width) - 1) or (AY > Cardinal(Self.Height) - 1) then begin
      result := Self.fData;
    end;

    Result := Self.fRowPos[AY] + (Integer(AX) * 4);
  end;

function TPGLImage.GetRect(): TPGLRectI;
  begin
    Result := RectIWH(0,0,Self.Width,Self.Height);
  end;

procedure TPGLImage.CopyFrom(var ASourceImage: TPGLImage);
  begin
    // do nothing if source not created or is not valid
    if (Assigned(ASourceImage) = False) or (ASourceImage.fIsValid = false) then begin
      exit;
    end;

    Self.fWidth := ASourceImage.Width;
    Self.fHeight := ASourceimage.Height;
    Self.fDataSize := ASourceImage.DataSize;
    FreeMemory(Self.fData);
    Self.fData := GetMemory(Self.fDataSize);
    Self.Define();

    Move(ASourceImage.fData[0], Self.fData[0], Self.fDataSize);
    Self.fIsValid := True;
  end;

procedure TPGLImage.CopyFrom(var ASourceImage: TPGLImage; ASrcRect: TPGLRectI);
var
I,Z: GLInt;
G,H: GLInt;
  begin

    // do nothing if source not created or is not valid
    if (Assigned(ASourceImage) = False) or (ASourceImage.fIsValid = false) then begin
      exit;
    end;

    // if Source Rect falls outside of source bounds, do noting
    if (ASrcRect.Left < 0) or (ASrcRect.Right > ASourceImage.Width - 1) or (ASrcRect.Top < 0) or (ASrcRect.Bottom > ASourceImage.Height - 1) then begin
      exit;
    end;

    Self.fWidth := ASrcRect.Width;
    Self.fHeight := ASrcRect.Height;
    Self.fDataSize := (Self.Width * Self.Height) * 4;
    FreeMemory(Self.fData);
    Self.fData := GetMemory(Self.DataSize);
    Self.Define();

    for Z := ASrcRect.Top to ASrcRect.Bottom do begin
      for I := ASrcRect.Left to ASrcRect.Right do begin
        G := Z - ASrcRect.Top; // Current Dest Row
        Move(ASourceImage.GetPixelPos(I,Z)[0], Self.fRowPos[G], ASrcRect.Width * 4);
      end;
    end;

    Self.fIsValid := True;

  end;

procedure TPGLImage.CopyFrom(var ASourceImage: TPGLImage; ASrcRect: TPGLRectI; ADestRect: TPGLRectI);
var
WidthRatio: GLFloat;
HeightRatio: GLFloat;
I,Z,X,Y: GLInt;
SrcPos, DestPos: PByte;
  begin

    // resize Source rect to be within bounds
    if ASrcRect.Left < 0 then begin
      ASrcRect.SetWidth(ASrcRect.Width - abs(ASrcRect.Left));
      ASrcRect.SetLeft(0);
    end;

    if ASrcRect.Top < 0 then begin
      ASrcRect.SetHeight(ASrcRect.Height - Abs(ASrcRect.Top));
      ASrcRect.SetTop(0);
    end;

    if ASrcRect.Right > ASourceImage.Width - 1 then begin
      ASrcRect.SetWidth(ASrcRect.Width - (ASourceImage.Width - ASrcRect.Right));
      ASrcRect.SetRight(ASourceImage.Width - 1);
    end;

    if ASrcRect.Bottom > ASourceImage.Height - 1 then begin
      ASrcRect.SetHeight(ASrcRect.Height - (ASourceImage.Height - ASrcRect.Bottom));
      ASrcRect.SetBottom(ASourceImage.Height - 1);
    end;

    // resize Dest rect to be within bounds
    if ADestRect.Left < 0 then begin
      ADestRect.SetWidth(ADestRect.Width - abs(ADestRect.Left));
      ADestRect.SetLeft(0);
    end;

    if ADestRect.Top < 0 then begin
      ADestRect.SetHeight(ADestRect.Height - Abs(ADestRect.Top));
      ADestRect.SetTop(0);
    end;

    if ADestRect.Right > Self.Width - 1 then begin
      ADestRect.SetWidth(ADestRect.Width - (Self.Width - ADestRect.Right));
      ADestRect.SetRight(Self.Width - 1);
    end;

    if ADestRect.Bottom > Self.Height - 1 then begin
      ADestRect.SetHeight(ADestRect.Height - (Self.Height - ADestRect.Bottom));
      ADestRect.SetBottom(Self.Height - 1);
    end;

    // get ration between dest and src widths and heights
    WidthRatio := ADestRect.Width / ASrcRect.Width;
    HeightRatio := ADestRect.Height / ASrcRect.Height;

    // copy from dest to src, adjusting for ratios


    for Z := ASrcRect.Top to ASrcRect.Bottom do begin
      for I := ASrcRect.Left to ASrcRect.Right do begin

        // Get X and Y coord of DestRect based on current SrcRect coord
        X := trunc((ADestRect.Left + (I - ASrcRect.Left)) * WidthRatio);
        Y := trunc((ADestRect.Top + (Z - ASrcRect.Top)) * HeightRatio);

        DestPos := Self.GetPixelPos(X,Y);
        SrcPos := ASourceImage.GetPixelPos(I,Z);

        if ColorF(SrcPos) = pgl_empty then begin
          continue;
        end;

        Move(SrcPos[0], DestPos[0], 4);
      end;
    end;

  end;


function TPGLImage.GetPixelF(AX: GLUint; AY: GLUint): TPGLColorF;
var
ReturnColor: TPGLColorI;
DataPos: PByte;
  begin

    if (AX > Cardinal(Self.Width) - 1) or (AY > Cardinal(Self.Height) - 1) then begin
      result := pgl_empty.toColorF;
      exit;
    end;

    DataPos := Self.fRowPos[AY] + (Integer(AX) * 4);
    Move(DataPos[0], ReturnColor, SizeOf(TPGLColorI));
    Result := ReturnColor.toColorF;
  end;

function TPGLImage.GetPixelI(AX: GLUint; AY: GLUint): TPGLColorI;
var
DataPos: PByte;
  begin

    if (AX > Cardinal(Self.Width) - 1) or (AY > Cardinal(Self.Height) - 1) then begin
      result := pgl_empty;
      exit;
    end;

    DataPos := Self.fRowPos[AY] + (Integer(AX) * 4);
    Move(DataPos[0], Result, SizeOf(TPGLColorI));
  end;

function TPGLImage.GetPixels(ARect: TPGLRectI): TArray<Byte>;
// return an array of bytes from a provided rect respresenting a block of image data
var
NewLeft,NewRight,NewTop,NewBottom,I,Z,Pos: GLInt;
Ptr,DestPtr: PByte;
NewRect: TPGLRectI;
  begin
    NewLeft := ARect.Left;
    NewRight := ARect.Right;
    NewTop := ARect.Top;
    NewBottom := ARect.Bottom;

    // make sure bounds of rect are withing image bounds
    if ARect.Left < 0 then begin
      NewLeft := 0;
    end;

    if ARect.Right > Self.Width - 1 then begin
      NewRight := Self.Width - 1;
    end;

    if ARect.Top < 0 then begin
      NewTop := 0;
    end;

    if ARect.Bottom > Self.Height - 1 then begin
      NewBottom := Self.Height - 1;
    end;

    NewRect := RectI(NewLeft,NewTop,NewRight,NewBottom);
    SetLength(Result, (NewRect.Width * NewRect.Height) * 4);

    // loop through top to bototm, left to right, transfer image data into byte array

    Pos := 0;

    for Z := NewRect.Top to NewRect.Bottom do begin
      for I := NewRect.Left to NewRect.Right do begin
        Ptr := Self.GetPixelPos(I,Z);
        Move(Ptr[0], Result[Pos], 4);
        Inc(Pos,4);
      end;
    end;

  end;

procedure TPGLImage.GetPixels(ARect: TPGLRectI; out ADestination: Pointer);
// return a pointer to memory containing data copied from image
// the user provided pointer is assigned nil and then used to allocate the appropriate size of memory
// therefore, it is possible for the user cause memory leaks by providing a pointer to a block of memory
// that has not been freed
var
NewLeft,NewRight,NewTop,NewBottom,I,Z,Pos: GLInt;
Ptr,DestPtr: PByte;
NewRect: TPGLRectI;
  begin
    NewLeft := ARect.Left;
    NewRight := ARect.Right;
    NewTop := ARect.Top;
    NewBottom := ARect.Bottom;

    // make sure bounds of rect are withing image bounds
    if ARect.Left < 0 then begin
      NewLeft := 0;
    end;

    if ARect.Right > Self.Width - 1 then begin
      NewRight := Self.Width - 1;
    end;

    if ARect.Top < 0 then begin
      NewTop := 0;
    end;

    if ARect.Bottom > Self.Height - 1 then begin
      NewBottom := Self.Height - 1;
    end;

    NewRect := RectI(NewLeft,NewTop,NewRight,NewBottom);

    ADestination := nil;
    ADestination := GetMemory((NewRect.Width * NewRect.Height) * 4);
    DestPtr := ADestination;

    // loop through top to bototm, left to right, transfer image data into byte array

    Pos := 0;

    for Z := NewRect.Top to NewRect.Bottom do begin
      for I := NewRect.Left to NewRect.Right do begin
        Ptr := Self.GetPixelPos(I,Z);
        Move(Ptr[0], DestPtr[Pos], 4);
        Inc(Pos,4);
      end;
    end;

  end;

procedure TPGLImage.SetPixel(AX,AY: GLUint; AColor: TPGLColorF);
var
SetColor: TPGLColorI;
WritePos: PByte;
  begin

    if (AX > Cardinal(Self.Width) - 1) or (AY > Cardinal(Self.Height) - 1) then begin
      exit;
    end;

    SetColor := AColor.toColorI;
    WritePos := Self.GetPixelPos(AX,AY);
    Move(SetColor, WritePos[0], SizeOf(TPGLColorI));
  end;

procedure TPGLImage.SetPixel(AX,AY: GLUint; AColor: TPGLColorI);
var
WritePos: PByte;
  begin

    if (AX > Cardinal(Self.Width) - 1) or (AY > Cardinal(Self.Height) - 1) then begin
      exit;
    end;

    WritePos := Self.GetPixelPos(AX,AY);
    Move(AColor, WritePos[0], SizeOf(TPGLColorI));
  end;

procedure TPGLImage.ReplaceColor(AOldColor: TPGLColorF; ANewColor: TPGLColorF);
var
I: GLInt;
Ptr: PByte;
CheckColor: TPGLColorI;
ConvertColor: TPGLColorI;
  begin

    // convert ANewColor to TPGLColorI for memory compatibility
    ConvertColor := ANewColor.toColorI;

    // traverse data memory 16 bytes at a time, size of color structs
    for I := 0 to trunc(Self.DataSize / ColorISize) - 1 do begin

      // set Ptr to address of next 'color' in memory
      Ptr := Self.fData + (I * ColorISize);
      // Move Data into variable
      CheckColor := Ptr;

      if CheckColor = AOldColor then begin
        Move(ConvertColor.Red, Ptr[0], ColorISize);
      end;

    end;

  end;

procedure TPGLImage.ReplaceColors(AOldColors: Array of TPGLColorF; ANewColors: Array of TPGLColorF);
var
I,Z,R: GLInt;
CheckColor: TPGLColorI;
ConvertColor: Array of TPGLColorI;
Ptr: PByte;
  begin

    // create an array of ColorI, convert ANewColors to ColorI for memory compatibility
    SetLength(ConvertColor,Length(ANewColors));
    for I := 0 to High(ConvertColor) do begin
      ConvertColor[i] := ANewColors[i];
    end;

    // traverse image data at ColorISize Intervals
    for I := 0 to trunc(Self.fDataSize / ColorISize) - 1 do begin

      // get pointer to color in memory, copy memory into variable to use as TPGLColorI
      Ptr := Self.fData + (I * ColorISize);
      CheckColor := Ptr;

      // loop through colors that are to be replaced
      for R := 0 to High(AOldColors) do begin
        // if replacing
        if CheckColor = AOldColors[r] then begin

          // check for if there is a counterpart to old colors in new colors
          // if so, replace with that counterpart
          if R <= Length(ConvertColor) then begin
            Move(ConvertColor[r], Ptr[0], ColorISize);

          end else begin
          // if not, replace with the last index of ConvertColor
            Move(ConvertColor[High(ConvertColor)], Ptr[0], ColorISize);
          end;

        end;
      end;

    end;

  end;


function TPGLImage.ReturnHitMap(): TArray<Byte>;
var
I,Z: GLInt;
  begin

    SetLength(Result, (Self.Width * Self.Height));

    for I := 0 to Self.Width - 1 do begin
      for Z := 0 to Self.Height - 1 do begin
        if Self.GetPixelF(I,Z) = pgl_empty then begin
          Result[ (Z * Self.Width) + I] := 0;
        end else begin
          Result[ (Z * Self.Width) + I] := 1;
        end;
      end;
    end;

  end;


procedure TPGLImage.SetAlpha(AValue: GLFloat);
var
I,Z: GLInt;
Ptr: PByte;
  begin

    ClampF(AValue);
    for I := 0 to Self.Width - 1 do begin
      for Z := 0 to Self.Height - 1 do begin
        Ptr := Self.GetPixelPos(I,Z);
        Ptr[3] := trunc(AValue * 255);
      end;
    end;

  end;


procedure TPGLImage.Fill(AColor: TPGLColorF);
var
I,Z: GLInt;
Ptr: PByte;
  begin
    for I := 0 to Self.Width - 1 do begin
      for Z := 0 to Self.Height - 1 do begin
        Self.SetPixel(I,Z,AColor);
      end;
    end;
  end;


procedure TPGLImage.MixColor(AColor: TPGLColorF; AIgnoreTransparent: Boolean = True);
var
I,Z: GLInt;
Ptr: PByte;
CheckColor: TPGLColorF;
  begin

    for I := 0 to Self.Width - 1 do begin
      for Z := 0 to Self.Height - 1 do begin
        CheckColor := Self.GetPixelF(I,Z);
        if CheckColor.Alpha <> 0 then begin
          Self.SetPixel(I,Z, pglMixColors( [AColor, CheckColor] ) );
        end;
      end;
    end;

  end;


procedure TPGLImage.Stretch(AXPercent: GLFloat = 1; AYPercent: GLFloat = 1);
  begin
    Self.ChangeSize(RoundF(Self.Width * AXPercent), RoundF(Self.Height * AYPercent));
  end;


procedure TPGLImage.ChangeSize(ANewWidth: GLUInt = 1; ANewHeight: GLUInt = 1);
var
XScale,YScale: GLFloat;
I,Z,G,H: GLInt;
SrcPos,DestPos: PByte;
NewData: PByte;
NewDataSize: GLInt;
UseWidth,UseHeight: GLUint;

DestI,DestZ: GLInt;
SrcI,SrcZ: GLInt;
  begin

    // allocate space for new data to be written to
    NewDataSize := (ANewWidth * ANewHeight) * 4;
    NewData := GetMemory(NewDataSize);

    // decide the upper bounds of the loops, get scales relative to old and new dimensions
    if cardinal(Self.Width) > ANewWidth then begin
      UseWidth := Self.Width;
      XScale := ANewWidth / Self.Width;
    end else begin
      UseWidth := ANewWidth;
      XScale := Self.Width / ANewWidth;
    end;

    if cardinal(Self.Height) > ANewHeight then begin
      UseHeight := Self.Height;
      YScale := ANewHeight / Self.Height;
    end else begin
      UseHeight := ANewHeight;
      YScale := Self.Height / ANewHeight;
    end;

    // loop through pixels and transfer
    for Z := 0 to UseHeight - 1 do begin
      for I := 0 to UseWidth - 1 do begin

        // get correct 'I' and 'Z' values for source and dest
        if cardinal(Self.Width) = UseWidth then begin
          SrcI := I;
          DestI := trunc(I * XScale);
        end else begin
          SrcI := trunc(I * XScale);
          DestI := I;
        end;

        if cardinal(Self.Height) = UseHeight then begin
          SrcZ := Z;
          DestZ := trunc(Z * YScale);
        end else begin
          SrcZ := trunc(Z * YScale);
          DestZ := Z;
        end;

        // get the position of relevant pixels in each set of data
        SrcPos := Self.GetPixelPos(SrcI,SrcZ);
        DestPos := NewData;
        DestPos := DestPos + trunc(( (DestZ * Integer(ANewHeight)) + DestI) * 4);

        // copy from src to dest
        Move(SrcPos[0], DestPos[0], 4);
      end;
    end;

    // Free image data, reallocate, copy NewData into image data, free NewData
    FreeMemory(Self.fData);
    Self.fData := GetMemory(NewDataSize);
    Move(NewData[0],Self.fData[0],NewDataSize);
    FreeMemory(NewData);

    Self.fDataSize := NewDataSize;
    Self.fWidth := ANewWidth;
    Self.fHeight := ANewHeight;
    Self.Define();

  end;


procedure TPGLImage.Pixelate(APixelSize: Cardinal);
var
I,Z,G,H: GLUint;
ComColors: TArray<TPGLColorF>;
UseColor: TPGLColorI;
  begin

    SetLength(ComColors, APixelSize * APixelSize);

    for I := 0 to trunc(Self.Width / APixelSize) - 1 do begin
      for Z := 0 to trunc(Self.Height / APixelSize) - 1 do begin

        // sample pixels in pixel size block and get 'average color'
        for G := 0 to APixelSize - 1 do begin
          for H := 0 to APixelSize - 1 do begin
            ComColors[ (G * APixelSize) + H] := Self.GetPixelI( (I * APixelSize) + G, (Z * APixelSize) + H);
          end;
        end;

        UseColor := pglMixColors(ComColors);

        // set all pixels in block to averaged color

        for G := 0 to APixelSize - 1 do begin
          for H := 0 to APixelSize - 1 do begin
            Self.SetPixel( (I * APixelSize) + G, (Z * APixelSize) + H, UseCOlor);
          end;
        end;

      end;
    end;

  end;


procedure TPGLImage.Lighten(AValue: GLFloat);
var
CheckColor: TPGLColorF;
Brightness: GLFloat;
I,Z: GLInt;
  begin

    for I := 0 to Self.Width - 1 do begin
      for Z := 0 to Self.Height - 1 do begin
        CheckColor := Self.GetPixelF(I,Z);
        CheckColor.Lighten(AValue);
        Self.SetPIxel(I,Z,CheckColor);
      end;
    end;

  end;

procedure TPGLImage.SaveToFile(AFileName: String);
  begin
    stbi_write_bmp(PAnsiChar(AnsiString(AFileName)), Self.Width, Self.Height, 4, Self.fData);
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                  TPGLTexture
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLTexture.Create(AWidth: Cardinal = 1; AHeight: Cardinal = 1);
var
Data: PByte;
  begin

    inherited Create();

    Self.fWidth := AWidth;
    Self.fHeight := AHeight;
    Self.fDataSize := (Self.Width * Self.Height) * 4;

    PGL.GenTexture(Self);
  end;

constructor TPGLTexture.Create(ASourceImage: TPGLImage);
  begin
    Self.fWidth := ASourceImage.Width;
    Self.fHeight := ASourceImage.Height;
    Self.fDataSize := (Self.Width * Self.Height) * 4;

    PGL.GenTexture(Self);

    PGL.BindTexture(0,Self);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Self.Width, Self.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, ASourceImage.fData);
    PGL.BindTexture(0,0);

  end;

constructor TPGLTexture.Create(AFileName: string);
var
Data: Pointer;
Width,Height,Channels: GLInt;
  begin

    if FileExists(AFileName) = False then begin
      AFileName := PGL.SourcePath + 'InvalidImage.png';
    end;

    Data := stbi_load(PAnsiChar(AnsiString(AFileName)), Width, Height, Channels, 4);

    Self.fWidth := Width;
    SElf.fHeight := Height;
    Self.fDataSize := (Self.Width * Self.Height) * 4;

    PGL.GenTexture(Self);
    PGL.BindTexture(0,Self);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Self.Width, Self.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, Data);

    stbi_image_free(Data);

    Self.OpenForEditing();
    Self.Edit.ReplaceColor(PGL.TransparentColor, pgl_empty);
    Self.CloseForEditing();

  end;

constructor TPGLTexture.Create(var ASourceTexture: TPGLTexture);
  begin
    Self.fWidth := ASourceTexture.Width;
    Self.fHeight := ASourceTexture.Height;
    Self.fDataSize := (Self.Width * Self.Height) * 4;

    PGL.GenTexture(Self);

    glCopyImageSubData(ASourceTexture.fHandle, GL_TEXTURE_2D, 0, 0, 0, 0, Self.fHandle, GL_TEXTURE_2D, 0,
      0, 0, 0, Self.Width, Self.Height, 1);
  end;

destructor TPGLTexture.Destroy();
  begin
    Self.CloseForEditing();
    PGL.UnbindTexture(Self);
    inherited;
  end;

function TPGLTexture.GetRect: TPGLRectI;
  begin
    Result := RectIWH(0,0,Self.Width,SElf.Height);
  end;


procedure TPGLTexture.Clear(AColor: TPGLColorF);
var
Data: TArray<Byte>;
I: GLInt;
DataPos: GLInt;
UseColor: TPGLColorI;
  begin
    UseColor := AColor;

    SetLength(Data, (Self.Width * Self.Height) * 4);

    for I := 0 to trunc(Length(Data) / 4) - 1 do begin
      DataPos := I * 4;
      Data[DataPos + 0] := UseColor.Red;
      Data[DataPos + 1] := UseColor.Red;
      Data[DataPos + 2] := UseColor.Red;
      Data[DataPos + 3] := UseColor.Red;
    end;

    PGL.BindTexture(0,Self);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, Self.Width, Self.Height, GL_RGBA, GL_UNSIGNED_BYTE, @Data[0]);

  end;

procedure TPGLTexture.Clear();
var
//Data: TArray<Byte>;
Data: PByte;
  begin
//    SetLength(Data,(Self.fWidth * Self.fHeight) * 4);
    Data := GetMemory((Self.fWidth * Self.fHeight) * 4);
    ZeroMemory(Data,(Self.fWidth * Self.fheight) * 4);
    PGL.BindTexture(0,Self);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, Self.Width, Self.Height, GL_RGBA, GL_UNSIGNED_BYTE, Data);
    FreeMemory(Data);
  end;

procedure TPGLTexture.CopyFrom(var ATexture: TPGLTexture);
// perform a 1:1 copy of texture data, resizing destination if needed
  begin

    if ATexture.fEditMode = True then begin
        exit;
    end;

    // resize if not same dimensions as ATexture
    if (Self.Width <> ATexture.Width) or (Self.Height <> ATexture.Height) then begin
        Self.ReSize(ATexture.Width, ATexture.Height, False);
    end;

    // perform GPU copy
    glCopyImageSubData(Self.fHandle, GL_TEXTURE_2D, 0, 0, 0, 0, ATexture.fHandle, GL_TEXTURE_2D, 0, 0, 0, 0,
      ATexture.Width, ATexture.Height, 1);
  end;

procedure TPGLTexture.CopyFrom(var ATexture: TPGLTexture; ASourceRect,ADestRect: TPGLRectI);
var
TempImage: TPGLImage;
ScaleX, ScaleY: GLFloat;
NewSourceRect: TPGLRectI;
Data: TArray<Byte>;
  begin

    TempImage := TPGLImage.Create(ATexture.Width, ATexture.Height);

    PGL.BindTexture(0, ATexture);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, TempImage.fData);

    ScaleX := ADestRect.Width / ASourceRect.Width;
    ScaleY := ADestRect.Height / ASourceRect.Height;

    TempImage.Stretch(ScaleX, ScaleY);
    NewSourceRect := ASourceRect;
    NewSourceRect.SetWidth(NewSourceRect.Width * ScaleX);
    NewSourceRect.SetHeight(NewSourceRect.Height * ScaleY);
    NewSourceRect.SetLeft(ASourceRect.Left * ScaleX);
    NewSourceRect.SetTop(ASourceRect.Top * ScaleY);

    Data := TempImage.GetPixels(NewSourceRect);

    PGL.BindTexture(0, Self);
    glTexSubImage2D(GL_TEXTURE_2D, 0, ADestRect.Left, ADestRect.Top, ADestRect.Width, ADestRect.Height, GL_RGBA, GL_UNSIGNED_BYTE, @Data[0]);

    PGL.Deleteimage(TempImage);

  end;

procedure TPGLTexture.CopyFrom(var AImage: TPGLImage);
// perform a 1:1 copy of image data into texture, resizing destination if needed
  begin
    PGL.BindTexture(0,Self);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, AImage.Width, AImage.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, AImage.fData);
    Self.fWidth := AImage.Width;
    Self.fHeight := AImage.Height;
  end;

procedure TPGLTexture.CopyFrom(var AImage: TPGLImage; ASourceRect,ADestRect: TPGLRectI);
var
Data: TArray<Byte>;
  begin
    Data := AImage.GetPixels(ASourceRect);

    PGL.BindTexture(0,Self);

    glTexSubImage2D(GL_TEXTURE_2D, 0, ADestRect.Left, ADestRect.top, ADestRect.Width, ADestRect.Height, GL_RGBA,
      GL_UNSIGNED_BYTE, @Data[0]);
  end;

procedure TPGLTexture.CopyFrom(AData: Pointer; AWidth, AHeight: GLUInt);
  begin
    PGL.BindTexture(0,Self);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, AWidth, AHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, AData);
  end;

procedure TPGLTexture.ReSize(ANewWidth: GLUint = 1; ANewHeight: GLUint = 1; AKeepData: Boolean = True);
var
TempImage: TPGLImage;
  begin

    if Self.EditMode then exit;
    if Self.AttachedToTarget then exit;

    PGL.BindTexture(0,Self);

    if AKeepData = True then begin
      TempImage := TPGLImage.Create(Self.Width, Self.Height);
      glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, TempImage.fData);
      TempImage.ChangeSize(ANewWidth,ANewHeight);
      TempImage.SaveToFile(PGL.EXEPath + 'Test.bmp');
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, ANewWidth, ANewHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, TempImage.fData);
      PGL.DeleteImage(TempImage);

    end else begin
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, ANewWidth, ANewHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);

    end;

    Self.fWidth := ANewwidth;
    Self.fHeight := ANewHeight;
    Self.fDataSize := (Self.Width * Self.Height) * 4;

  end;


procedure TPGLTexture.SaveToFile(AFileName: String; AFormat: TPGLImageFormat = pgl_bmp);
var
Data: Array of Byte;
  begin

    SetLength(Data, (Self.Width * Self.Height) * 4);

    glBindTexture(GL_TEXTURE_2D, Self.fHandle);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, @Data[0]);

    if AFormat = pgl_bmp then begin
      stbi_write_bmp(PAnsiChar(AnsiString(AFileName)), Self.Width, Self.Height, 4, @Data[0]);
    end else begin
       stbi_write_png(PAnsiChar(AnsiString(AFileName)), Self.Width, Self.Height, 4, @Data[0], 4 * Self.Width);
    end;

  end;

procedure TPGLTexture.OpenForEditing();
  begin
    if Self.EditMode = False then begin
      Self.fEditMode := True;

      // create an image to hold texture data, transfer from GPU to image data
      Self.EditImage := TPGLImage.Create(Self.Width, Self.Height);

      PGL.BindTexture(0,Self.fHandle);
      glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, Self.EditImage.fData);
      PGL.BindTexture(0,0);

    end;
  end;

procedure TPGLTexture.CloseForEditing();
  begin
    if Self.EditMode = True then begin
      Self.fEditMode := False;

      Self.fWidth := Self.EditImage.Width;
      Self.fHeight := Self.EditImage.Height;
      Self.fDataSize := (Self.Width * Self.Height) * 4;

      // transfer image data back from CPU to GPU, clean up the image object
      PGL.BindTexture(0,Self.fHandle);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Self.EditImage.Width, Self.EditImage.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, Self.EditImage.fData);
      PGL.BindTexture(0,0);
      PGL.DeleteImage(Self.EditImage);

    end;
  end;



{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                  TPGLTexture
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLSprite.Create;
  begin
    Self.Bounds.SetSize(0,0);
    Self.Bounds.SetCenter(Vec3(0,0,0));
    Self.SetInit();

    PGL.AddSprite(Self);
  end;

constructor TPGLSPrite.Create(var ATexture: TPGLTexture);
  begin
    Self.SetInit();
    Self.Bounds.SetSize(ATexture.Width, ATexture.Height);
    Self.fTexture := ATexture;
    Self.fTextureRect := RectIWH(0,0,ATexture.Width,ATexture.Height);
    Self.fOrigin := Vec2(0,0);

    PGL.AddSprite(Self);
  end;

destructor TPGLSPrite.Destroy();
  begin
    inherited Destroy();
  end;

procedure TPGLSPrite.Free();
  begin
    inherited Free();
  end;

procedure TPGLSprite.SetInit();
  begin
    Self.fColorValues := pgl_white.toColorF;
    Self.fColorOverlay := pgl_empty.toColorF;
    Self.fGreyScale := False;
    Self.fMonoChrome := False;
    Self.fBrightness := 1;
    Self.fOpacity := 1;
  end;

function TPGLSprite.GetAngles: TPGLVec3;
  begin
    Result.X := Self.AngleX;
    Result.Y := Self.AngleY;
    Result.Z := Self.AngleZ;
  end;

function TPGLSprite.GetSubRect(I: GLint): TPGLRectI;
  begin
    Result := Self.fSubRect[I];
  end;

procedure TPGLSprite.SetTexture(ATexture: TPGLTexture);
  begin
    if Assigned(ATexture) = false then exit;

    Self.Bounds.SetSize(ATexture.Width, ATexture.Height);
    Self.fTexture := ATexture;
    Self.fTextureRect := RectIWH(0,0,ATexture.Width + 1,ATexture.Height + 1);
    Self.fOrigin := Vec3(0,0)
  end;

procedure TPGLSprite.SetLeft(ALeft: GLFloat);
  begin
    Self.Bounds.SetLeft(ALeft);
  end;

procedure TPGLSprite.SetTop(ATop: GLFloat);
  begin
    Self.Bounds.SetTop(ATop);
  end;

procedure TPGLSprite.SetRight(ARight: GLFloat);
  begin
    Self.Bounds.SetRight(ARight);
  end;

procedure TPGLSprite.SetBottom(ABottom: GLFloat);
  begin
    Self.Bounds.SetBottom(ABottom);
  end;

procedure TPGLSprite.SetWidth(AWidth: GLFloat);
  begin
    Self.Bounds.SetWidth(AWidth);
  end;

procedure TPGLSprite.SetHeight(AHeight: GLFloat);
  begin
    Self.Bounds.SetHeight(AHeight);
  end;

procedure TPGLSprite.SetSize(AWidth,AHeight: GLFloat);
  begin
    Self.Bounds.SetSize(AWidth,AHeight);
  end;

procedure TPGLSprite.SetCenter(ACenter: TPGLVec3);
  begin
    Self.Bounds.SetCenter(ACenter);
  end;

procedure TPGLSprite.SetX(AX: GLFloat);
  begin
    Self.Bounds.SetX(AX);
  end;

procedure TPGLSprite.SetY(AY: GLFloat);
  begin
    Self.Bounds.SetY(AY);
  end;

procedure TPGLSprite.SetZ(AZ: GLFloat);
  begin
    Self.Bounds.SetZ(AZ);
  end;

procedure TPGLSprite.Translate(AX,AY,AZ: GLFloat);
  begin
    Self.fBounds.Translate(AX,AY);
  end;

procedure TPGLSprite.SetAngleX(Angle: GLFloat);
  begin
    Self.fAngleX := Angle;
    Self.RotMat.Rotate(Self.fAngleX, Self.fAngleY, Self.fAngleZ);
  end;

procedure TPGLSprite.SetAngleY(Angle: GLFloat);
  begin
    Self.fAngleY := Angle;
    Self.RotMat.Rotate(Self.fAngleX, Self.fAngleY, Self.fAngleZ);
  end;

procedure TPGLSprite.SetAngleZ(Angle: GLFloat);
  begin
    Self.fAngleZ := Angle;
    Self.RotMat.Rotate(Self.fAngleX, Self.fAngleY, Self.fAngleZ);
  end;

procedure TPGLSprite.SetAngles(AX: GLFLoat = 0; AY: GLFLoat = 0; AZ: GLFLoat = 0);
  begin
    Self.fAngleX := AX;
    self.fAngleY := AY;
    Self.fAngleZ := AZ;
  end;

procedure TPGLSprite.SetAngles(AAngles: TPGLVec3);
  begin
    Self.fAngleX := AAngles.X;
    self.fAngleY := AAngles.Y;
    Self.fAngleZ := AAngles.Z;
  end;

procedure TPGLSprite.SetOrigin(AOrigin: TPGLVec3);
  begin
    Self.fOrigin := AOrigin;
  end;

procedure TPGLSprite.RotateX(AValue: GLFloat);
  begin
    IncF(Self.fAngleX, AValue);
  end;

procedure TPGLSprite.RotateY(AValue: GLFloat);
  begin
    IncF(Self.fAngleY, AValue);
  end;

procedure TPGLSprite.RotateZ(AValue: GLFloat);
  begin
    IncF(Self.fAngleZ, AValue);
  end;

procedure TPGLSprite.Rotate(AX: GLFloat = 0; AY: GLFloat = 0; AZ: GLFloat = 0);
  begin
    IncF(Self.fAngleX, AX);
    IncF(Self.fAngleY, AY);
    IncF(Self.fAngleZ, AZ);
  end;

procedure TPGLSprite.Rotate(AValues: TPGLVec3);
  begin
    IncF(Self.fAngleX, AValues.X);
    IncF(Self.fAngleY, AValues.Y);
    IncF(Self.fAngleZ, AValues.Z);
  end;

procedure TPGLSprite.SetTextureRect(ARect: TPGLRectI; AUpdateBounds: Boolean = True);
var
NewLeft,NewTop,NewRight,NewBottom: GLInt;
  begin

    NewLeft := ARect.Left;
    NewTop := ARect.Top;
    NewRight := ARect.Right;
    NewBottom := ARect.Bottom;

    if ARect.Left < 0 then begin
      NewLeft := 0;
    end;

    if ARect.Top < 0 then begin
      NewTop := 0;
    end;

    if ARect.Right > Integer(Self.Texture.Width) - 1 then begin
      NewRight := Self.Texture.Width - 1;
    end;

    if ARect.Bottom > Integer(Self.Texture.Height) - 1 then begin
      NewBottom := Self.Texture.Height - 1;
    end;

    Self.fTextureRect := RectI(NewLeft,NewTop,NewRight,NewBottom);

    if AUpdateBounds = True then begin
      Self.Bounds.SetSize(Self.fTextureRect.Width, Self.fTextureRect.Height, from_center);
    end;
  end;


procedure TPGLSprite.SetColorValues(AValues: TPGLColorF);
  begin
    Self.fColorValues := AValues;
  end;

procedure TPGLSprite.SetColorOverlay(AColor: TPGLColorF);
  begin
    Self.fColorOverlay := AColor;
  end;

procedure TPGLSprite.SetGreyScale(AEnable: Boolean = True);
  begin
    Self.fGreyScale := AEnable;
  end;

procedure TPGLSprite.SetMonoChrome(AEnable: Boolean = True);
  begin
    Self.fMonoChrome := AEnable;
  end;

procedure TPGLSprite.SetBrightness(AValue: Single);
  begin
    Self.fBrightness := ClampF(AValue);
  end;

procedure TPGLSprite.SetOpacity(AValue: Single);
  begin
    Self.fOpacity := ClampF(AValue);
  end;

procedure TPGLSprite.SetSubRect(AIndex: GLUInt; ARect: TPGLRectI);
  begin
    // exit if AIndex out of range
    if AIndex > High(Self.fSubRect) then exit;

    Self.fSubRect[AIndex] := ARect;
  end;

procedure TPGLSprite.UseSubRect(AIndex: GLUInt; AUpdateBounds: Boolean = True);
  begin
    Self.SetTextureRect(Self.fSubRect[AIndex], AUpdateBounds);
  end;

function TPGLSprite.GetTexCoords(): TArray<TPGLVec3>;
  begin
    SetLength(Result,4);
    Result[0] := Vec2(Self.fTextureRect.Left / Self.Texture.Width, Self.fTextureRect.Top / Self.fTexture.Height);
    Result[1] := Vec2(Self.fTextureRect.Right / Self.Texture.Width, Self.fTextureRect.Top / Self.fTexture.Height);
    Result[2] := Vec2(Self.fTextureRect.Right / Self.Texture.Width, Self.fTextureRect.Bottom / Self.fTexture.Height);
    Result[3] := Vec2(Self.fTextureRect.Left / Self.Texture.Width, Self.fTextureRect.Bottom / Self.fTexture.Height);
  end;

procedure TPGLSprite.ResetBounds();
  begin
    if Assigned(Self.Texture) = false then exit;
    Self.Bounds.SetSize(Self.fTexture.Width, Self.fTexture.Height, from_center);
    Self.Bounds.SetZ(0);
    Self.SetTextureRect(RectIWH(0,0,Self.Bounds.Width,Self.Bounds.Height));
  end;

procedure TPGLSprite.ResetColors();
  begin
    Self.SetColorValues(ColorF(1,1,1));
    Self.SetColorOverlay(ColorF(0,0,0));
    Self.SetOpacity(1);
  end;

procedure TPGLSprite.ResetRotations();
  begin
    Self.SetAngles(Vec3(0,0,0));
    Self.fOrigin := Vec2(0,0);
  end;

procedure TPGLSprite.Reset();
  begin
    Self.ResetBounds();
    Self.ResetColors();
    Self.ResetRotations();
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                TPGLTextureHelper
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

procedure TPGLTextureHelper.CopyFrom(ARenderTarget: TPGLRenderTarget);
  begin

    ARenderTarget.DrawLastBatch();

    if (Self.Width <> cardinal(ARenderTarget.Width)) or (Self.Height <> cardinal(ARenderTarget.Height)) then begin
      Self.ReSize(ARenderTarget.Width, ARenderTarget.Height);
    end;

    glCopyImageSubData(ARenderTarget.fTexture2D, GL_TEXTURE_2D, 0, 0, 0, 0, Self.fHandle, GL_TEXTURE_2D,
      0, 0, 0, 0, Self.Width, Self.Height, 1);

  end;

procedure TPGLTextureHelper.CopyFrom(ARenderTarget: TPGLRenderTarget; ASrcRect,ADestRect: TPGLRectI);
var
NewSrcRect,NewDestRect: TPGLRectI;
TargetData: PByte;
DataSize: GLInt;
  begin

    ARenderTarget.DrawLastBatch();

    NewSrcRect := AsrcRect;
    NewSrcRect.FitInRect(ARenderTarget.RenderRect);
    NewDestRect := ADestRect;
    NewDestRect.FitInRect(Self.Bounds);

    PGL.TempBuffer.AttachTexture(Self);
    ARenderTarget.Blit(PGL.TempBuffer, NewSrcRect, NewDestRect);
    PGL.TempBuffer.RestoreTexture();

  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                    TPGLSHAPE
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLShape.Create(APointCount: GLUInt);
  begin
    Self.fPointCount := APointCount;
    SetLength(Self.Vertex,APointCount);
    Self.fCenter := Vec3();
    Self.fWidth := 0;
    Self.fHeight := 0;
  end;

constructor TPGLShape.CreateCircle(ARadius: GLFloat = 1; APointCount: GLInt = -1);
var
PointCount: GLInt;
AngleArc: GLFloat;
UseAngle,AngleInc: GLFloat;
I: GLInt;
  begin

    if APointCount < 5 then begin
      PointCount := -1;
    end else begin
      PointCount := APointCount;
    end;


    if PointCount = -1 then begin
      AngleArc := 2 * (Pi * ARadius);
      PointCount := trunc(AngleArc / 5) + 2;
    end;

    Self.fPointCount := PointCount;

    SetLength(Self.Vertex, PointCount);
    UseAngle := 0;
    AngleInc := (Pi * 2) / (PointCount - 1);

    Self.Vertex[0].Vector := Vec3(0,0,0);
    Self.Vertex[0].Color := pgl_white_f;
    Self.Vertex[0].TexCoord := Vec3(0,0,0);
    Self.Vertex[0].Normal := Vec3(0,0,0);

    for I := 1 to PointCount - 1 do begin
      Self.Vertex[i].Vector.X := ARadius * Cos(UseAngle);
      Self.Vertex[i].Vector.Y := ARadius * Sin(UseAngle);
      Self.Vertex[i].Color := pgl_white_f;
      Self.Vertex[i].TexCoord := Vec3(0,0,0);
      Self.Vertex[i].Normal := Vec3(0,0,0);
      IncF(UseAngle,AngleInc);
    end;

    Self.fCenter := Vec3(0,0,0);
    Self.fWidth := ARadius * 2;
    Self.fHeight := ARadius * 2;
    Self.fShapeType := CIRCLE_SHAPE;

  end;

constructor TPGLShape.CreateRectangle(AWidth: GLFLoat = 1; AHeight: GLFLoat = 1);
var
VRect: TPGLRectF;
  begin
    VRect := RectFWH(0,0,AWidth, AHeight);
    Self.fPointCount := 5;
    Self.fCenter := VRect.Center;
    SetLength(Self.Vertex, 5);
    Self.Vertex[0].Vector := VRect.Center;
    Self.Vertex[1].Vector := VRect.TopLeft;
    Self.Vertex[2].Vector := VRect.TopRight;
    Self.Vertex[3].Vector := VRect.BottomRight;
    Self.Vertex[4].Vector := VRect.BottomLeft;
  end;

procedure TPGLShape.SetColor(AColor: TPGLColorF);
var
I: GLInt;
  begin
    for I := 0 to High(Self.Vertex) do begin
      Self.Vertex[i].Color := AColor;
    end;
  end;

procedure TPGLShape.SetCenter(ACenter: TPGLVec3);
var
I: GLInt;
Diff: TPGLVec3;
  begin
    Diff := ACenter - Self.fCenter;
    Self.fCenter := ACenter;
    For I := 0 to High(Self.Vertex) do begin
      Self.Vertex[i].Vector.Translate(Diff);
    end;
  end;

procedure TPGLShape.PlaceVertex(AIndex: GLUint; APosition: TPGLVec3);
  begin
    if AIndex = 0 then Exit;
    if AIndex > Self.fPointCount - 1 then Exit;
    Self.Vertex[AIndex].Vector := APosition;
  end;

procedure TPGLShape.SetTexture(ATexture: TPGLTexture);
  begin
    Self.fTexture := ATexture;
  end;

procedure TPGLShape.Translate(AValues: TPGLVec3);
var
I: GLInt;
  begin
    For I := 0 to High(Self.Vertex) do begin
      Self.Vertex[i].Vector.Translate(AValues);
    end;
  end;


function TPGLShape.GetVertex(I: GLUint): TPGLVertex;
  begin

    if Self.fPointCount = 0 then exit;
    if I > Self.fPointCount then exit;

    Result := Self.Vertex[I];
  end;


function TPGLShape.GetElements: System.TArray<GLInt>;
var
I: GLInt;
Count: GLInt;
Elements: TArray<GLInt>;
  begin

    Count := 0;

    case Self.fShapeType of

      0: // Circle;
        begin

          for I := 2 to High(Self.Vertex) do begin
            SetLength(Elements, Length(Elements) + 3);
            Elements[Count] := I;
            Elements[Count + 1] := 0;
            Elements[Count + 2] := I - 1;
            Inc(Count,3);
          end;

          SetLength(Elements, Length(Elements) + 3);
          Elements[Count] := 1;
          Elements[Count + 1] := 0;
          Elements[Count + 2] := High(Self.Vertex);
          Inc(Count,3);

          Result := Elements;

        end;

      1: // rectangle
        begin

        end;

    end;

  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                    TPGLAtlas
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLAtlas.Create(AParent: TPGLFont);
  begin
    inherited Create();
    Self.fParent := AParent;
  end;

destructor TPGLAtlas.Destroy();
  begin
    PGL.DeleteTexture(Self.fTexture);
    Inherited;
  end;

procedure TPGLAtlas.MakeSDF(AFontName: string; APointSize: GLInt);
var
Face: TFTFace;
LoadFlags: TFTLoadFlags;
I,Z: GLInt;
CharTexture: Array [31..128] of GLUint;
BBox: TPGLRectF;
CurChar: ^TPGLCharacter;
UseWidth,UseHeight: GLInt;
Data: TArray<Byte>;
DataPos: GLInt;
LowY,HighY: GLInt;
TempTexture: TPGLTexture;
  begin
    Self.GlyphType := Self.glyph_type_sdf;
    Self.Width := 0;
    Self.Height := 0;
    Self.Origin := 0;

    Self.PointSize := APointSize;

    Face := TFTFace.Create(AnsiString(AFontName),0);
    Face.SetCharSize(0, APointSize * 64, 0, 0);

    BBox := PGLTypes.RectF(Face.BBox.XMin / 32, Face.BBox.YMin / 32, Face.bbox.XMax / 32, Face.BBox.YMax / 32);
    Self.Origin := BBox.Bottom;
    Self.Height := trunc(BBox.Height);

    for I := 32 to 128 do begin

      if Char(i) = '' then Continue;

      LoadFlags := [ftlfRender,ftlfForceAutohint];
      Face.LoadGlyph(Face.GetCharIndex(I), LoadFlags);

      if Char(i) = ' ' then begin
        UseWidth := trunc(Face.Glyph.Metrics.HorzAdvance / 64);
        UseHeight := trunc(Self.Origin);
      end else begin
        Face.Glyph.RenderGlyph(TFTRenderMode.ftrmSDF);
        UseWidth := Face.Glyph.Bitmap.Width;
        UseHeight := Face.Glyph.Bitmap.Rows;
      end;

      glGenTextures(1,@CharTexture[i]);
      PGL.BindTexture(0,CharTexture[i]);

      glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

      glTexImage2d(GL_TEXTURE_2D,0,GL_RGBA, UseWidth,
                                            UseHeight,
                                            0,
                                            GL_RED,
                                            GL_UNSIGNED_BYTE,
                                            Face.Glyph.Bitmap.Buffer);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

      glPixelStorei(GL_UNPACK_ALIGNMENT, 4);

      CurChar := @Self.fCharacter[i];

      Self.fCharacter[i].Symbol := Char(i);
      Self.fCharacter[i].Width := trunc(Face.Glyph.Metrics.Width / 64);
      Self.fCharacter[i].Height := trunc(Face.Glyph.Metrics.Height / 64);
      Self.fCharacter[i].GlyphWidth := Face.Glyph.Bitmap.Width;
      Self.fCharacter[i].GlyphHeight := Face.Glyph.Bitmap.Rows;
      Self.fCharacter[i].SDFDiff := (Self.fCharacter[i].GlyphHeight - Self.fCharacter[i].Height) / 2;
      Self.fCharacter[i].Advance := CurChar.Width + 1;
      Self.fCharacter[i].BearingX := (Face.Glyph.Metrics.HorzBearingX / 64);
      Self.fCharacter[i].BearingY := (Face.Glyph.Metrics.HorzBearingY / 64);
      Self.fCharacter[i].TailHeight := Self.fCharacter[i].Height - Self.fCharacter[i].BearingY;

      if Char(i) = ' ' then begin
        CurChar.Width := CurChar.GlyphWidth;
        CurChar.height := CurChar.GlyphHeight;
      end;

      Self.fCharacter[i].Position := vec2(Self.Width, Self.Origin - (CurChar.BearingY + 12));

      Inc(Self.Width, Self.fCharacter[i].GlyphWidth + 1);

      Face.Glyph.Bitmap.Done;

    end;

    for I := 32 to 128 do begin
      CurChar := @Self.fCharacter[i];
      CurChar.Bounds := RectIWH(CurChar.Position.X, 0, CurChar.GlyphWidth, Self.Height);
    end;

    TempTexture := TPGLTexture.Create(Self.Width,Self.Height);
    PGL.BindTexture(0,TempTexture);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Self.Width, Self.Height, 0, GL_RED, GL_UNSIGNED_BYTE, nil);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    for I := 32 to 128 do begin
      if Char(i) = '' then continue;
      glCopyImageSubData(CharTexture[i], GL_TEXTURE_2D, 0, 0, 0, 0, TempTexture.fHandle, GL_TEXTURE_2D, 0,
        trunc(Self.fCharacter[i].Position.X), trunc(Self.fCharacter[i].Position.Y), 0, Self.fCharacter[i].GlyphWidth, Self.fCharacter[i].GlyphHeight, 1);
    end;

    // trim excess black from top and bototm of atlas texture
    LowY := trunc(self.Height / 2);
    HighY := LowY;
    DataPos := 0;

    SetLength(Data, (Self.Width * Self.Height) * 4);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RED, GL_UNSIGNED_BYTE, @Data[0]);

    for I := 0 to Self.Width - 1 do begin
      for Z := 0 to Self.Height -1 do begin

        DataPos := ((Z * Self.Width) + I);

        if Data[DataPos] <> 0 then begin
          if Z < LowY then LowY := Z;
          if Z > HighY then HighY := Z;
        end;

      end;
    end;

    Self.Height := (HighY - LowY) + 1;

    Self.fTexture := TPGLTexture.Create(Self.Width,Self.Height);
    PGL.BindTexture(0,Self.fTexture);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Self.Width, Self.Height, 0, GL_RED, GL_UNSIGNED_BYTE, nil);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    glCopyImageSubData(TempTexture.Handle, GL_TEXTURE_2D, 0, 0, LowY, 0, Self.fTexture.Handle, GL_TEXTURE_2D,
      0, 0, 0, 0, Self.Width, Self.Height, 1);

    PGL.DeleteTexture(TempTexture);

    for I := 32 to 128 do begin
      glDeleteTextures(1,@CharTexture[i]);
      Self.fCharacter[i].Bounds.SetHeight(Self.Height, from_top);
    end;

    Face.Destroy();
  end;


procedure TPGLAtlas.MakeNormal(AFontName: String; APointSize: GLUInt);
var
Face: TFTFace;
LoadFlags: TFTLoadFlags;
I,Z: GLInt;
CharTexture: Array [31..128] of GLUint;
BBox: TPGLRectF;
CurChar: ^TPGLCharacter;
UseWidth,UseHeight: GLInt;
Data: TArray<Byte>;
DataPos: GLInt;
LowY,HighY: GLInt;
TempTexture: TPGLTexture;
SizeRequest: TFTSizeRequest;
  begin
    // set atlas glyph type and zero some initial fields
    Self.GlyphType := Self.glyph_type_normal;
    Self.Width := 0;
    Self.Height := 0;
    Self.Origin := 0;

    // create the FreeType face and request the point size
    Self.PointSize := APointSize;
    Face := TFTFace.Create(AnsiString(AFontName),0);
    Face.SetPixelSize(0, RoundF( (APointSize * (Self.fParent.fResolution.Y / Self.fParent.fResolution.X)) * (Context.DPIY / 72)  ));

    // get the initial height and origin of the atlas
    BBox := PGLTypes.RectF(Face.BBox.XMin / 32, Face.BBox.YMin / 32, Face.bbox.XMax / 32, Face.BBox.YMax / 32);
    Self.Origin := BBox.Bottom;
    Self.Height := trunc(BBox.Height);

    // load each character glyph
    for I := 32 to 128 do begin

      if Char(i) = '' then Continue;

      LoadFlags := [ftlfRender,ftlfForceAutohint];
      Face.LoadGlyph(Face.GetCharIndex(I), LoadFlags);

      // account for if the character is space which has no glyph
      if Char(i) = ' ' then begin
        UseWidth := trunc(APointSize / 4);
        UseHeight := trunc(Self.Origin);
      end else begin
        Face.Glyph.RenderGlyph(TFTRenderMode.ftrmLight);
        UseWidth := Face.Glyph.Bitmap.Width;
        UseHeight := Face.Glyph.Bitmap.Rows;
      end;

      // create a gl texture and store the glyph in it

      if Char(i) <> ' ' then begin
        glGenTextures(1,@CharTexture[i]);
        PGL.BindTexture(0,CharTexture[i]);

        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

        glTexImage2d(GL_TEXTURE_2D,0,GL_RED, UseWidth,
                                              UseHeight,
                                              0,
                                              GL_RED,
                                              GL_UNSIGNED_BYTE,
                                              Face.Glyph.Bitmap.Buffer);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
      end;

      CurChar := @Self.fCharacter[i];

      // get character metrics
      Self.fCharacter[i].Symbol := Char(i);
      Self.fCharacter[i].Width := UseWidth;
      Self.fCharacter[i].Height := trunc(Face.Glyph.Metrics.Height / 64);
      Self.fCharacter[i].GlyphWidth := Face.Glyph.Bitmap.Width;
      Self.fCharacter[i].GlyphHeight := Face.Glyph.Bitmap.Rows;
      Self.fCharacter[i].SDFDiff := (Self.fCharacter[i].GlyphHeight - Self.fCharacter[i].Height) / 2;
      Self.fCharacter[i].Advance := CurChar.Width + 1;
      Self.fCharacter[i].BearingX := (Face.Glyph.Metrics.HorzBearingX / 64);
      Self.fCharacter[i].BearingY := (Face.Glyph.Metrics.HorzBearingY / 64);
      Self.fCharacter[i].TailHeight := Self.fCharacter[i].Height - Self.fCharacter[i].BearingY;

      if Char(i) = ' ' then begin
        CurChar.Width := CurChar.GlyphWidth;
        CurChar.height := CurChar.GlyphHeight;
      end;

      Self.fCharacter[i].Position := vec2(Self.Width, Self.Origin - (CurChar.BearingY));

      Inc(Self.Width, Self.fCharacter[i].GlyphWidth + 1);

      Face.Glyph.Bitmap.Done();

    end;

    // set bounding box in atlas for each character
    for I := 32 to 128 do begin
      CurChar := @Self.fCharacter[i];
      CurChar.Bounds := RectIWH(CurChar.Position.X, 0, CurChar.GlyphWidth, Self.Height);
    end;

    // create a temporary atlas texture to transfer glyph images into
    TempTexture := TPGLTexture.Create(Self.Width,Self.Height);
    PGL.BindTexture(0,TempTexture);

    // change temp atlas to red channel only
    glPixelStoreI(GL_UNPACK_ALIGNMENT,1);

    SetLength(Data,Self.Width * Self.Height);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, Self.Width, Self.Height, 0, GL_RED, GL_UNSIGNED_BYTE, @Data[0]);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    Finalize(Data);

    glPixelStoreI(GL_UNPACK_ALIGNMENT,4);

    // transfer each glyph into temp atlas
    for I := 32 to 128 do begin
      if (Char(i) = '') or (Char(i) = ' ') then continue;
      glCopyImageSubData(CharTexture[i], GL_TEXTURE_2D, 0, 0, 0, 0, TempTexture.fHandle, GL_TEXTURE_2D, 0,
        trunc(Self.fCharacter[i].Position.X), trunc(Self.fCharacter[i].Position.Y), 0, Self.fCharacter[i].GlyphWidth, Self.fCharacter[i].GlyphHeight, 1);
    end;


    // trim excess black from top and bototm of atlas texture
    LowY := Self.Height;
    HighY := 0;
    DataPos := 0;

    // first, transfer temp atlas image data into byte array
    glPixelStoreI(GL_PACK_ALIGNMENT,1);

    SetLength(Data, (Self.Width * Self.Height));
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RED, GL_UNSIGNED_BYTE, @Data[0]);

    glPixelStoreI(GL_PACK_ALIGNMENT,1);

    // traverse byte array looking for the lowest and highest Y that has a non-0 pixel
    for I := 0 to Self.Width - 1 do begin
      for Z := 0 to Self.Height -1 do begin

        DataPos := ((Z * Self.Width) + I);

        if Data[DataPos] <> 0 then begin
          if Z < LowY then LowY := Z;
          if Z > HighY then HighY := Z;
        end;

      end;
    end;

    glPixelStoreI(GL_PACK_ALIGNMENT,4);

    // atlas height equals difference between heighest and lowest pixels that are not 0
    Self.Height := (HighY - LowY) + 1;

    // delete all temporary character gl textures
    for I := 32 to 128 do begin
      glDeleteTextures(1,@CharTexture[i]);
    end;

    // create the final atlas texture
    Self.fTexture := TPGLTexture.Create(Self.Width,Self.Height);
    PGL.BindTexture(0,Self.fTexture);

    // make single red channel
    glPixelStoreI(GL_UNPACK_ALIGNMENT,1);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, Self.Width, Self.Height, 0, GL_RED, GL_UNSIGNED_BYTE, nil);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    glPixelStoreI(GL_UNPACK_ALIGNMENT,4);

    // copy trimmed bounds of temp texture into final texture
    glCopyImageSubData(TempTexture.Handle, GL_TEXTURE_2D, 0, 0, LowY, 0, Self.fTexture.Handle, GL_TEXTURE_2D,
      0, 0, 0, 0, Self.Width, Self.Height, 1);

    PGL.DeleteTexture(TempTexture);

    // adjust bounds of characters
    for I := 32 to 128 do begin
      Self.fCharacter[i].Bounds.SetHeight(Self.Height, from_top);
    end;

    Face.Destroy();

  end;

procedure TPGLAtlas.SaveCharReport(APath: String);
var
I: GLInt;
WriteString: String;
OutFile: TextFile;
CurChar: ^TPGLCharacter;
  begin

    WriteString := '';

    for I := 32 to 128 do begin
      CurChar := @Self.fCharacter[I];
      WriteString := WriteString + 'Character: ' + CurChar.Symbol + sLineBreak;
      WriteString := WriteString +  ' - Ansi Code: ' + I.Tostring + sLineBreak;
      WriteString := WriteString +  ' - Width: ' + CurChar.Width.ToString + sLineBreak;
      WriteString := WriteString +  ' - Height: ' + CurChar.Height.ToString + sLineBreak;
      WriteString := WriteString +  ' - Glyph Width: ' + CurChar.GlyphWidth.ToString + sLineBreak;
      WriteString := WriteString +  ' - Glygh Height: ' + CurChar.GlyphHeight.ToString + sLineBreak;
      WriteString := WriteString +  ' - Advance: ' + CurChar.Advance.ToString + sLineBreak;
      WriteString := WriteString + '-------------------------------------------------------' + sLineBreak;
    end;

    AssignFile(OutFile,APath + 'CharReport.txt');
    ReWrite(OutFile);
    WriteLn(OutFile, WriteString);
    CloseFile(OutFile);

  end;


function TPGLAtlas.GetTextWidth(AText: String): GLFloat;
var
I: GLInt;
CharNum: GLInt;
  begin
    Result := 0;

    for I := 1 to Length(Atext) do begin
      CharNum := Ord(AText[i]);
      if (CharNum >= 32) and (CharNum <= 128) then begin
        Result := Result + Self.fCharacter[CharNum].Advance;
      end;
    end;

  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                    TPGLFont
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLFont.Create(AFontName: string; ACreateSDFFont: Boolean = False);
var
I: GLInt;
  begin
    PGL.context.SetIgnoreDebug(True);
    Self.fResolution := Point(Context.NativeScreenWidth, Context.NativeScreenHeight);
    Self.fFontPath := AFontName;

    if ACreateSDFFont = true then begin
      Self.MakeSDFs(Self.fFontPath);
    end else begin
      Self.MakeNormals(Self.fFontPath);
    end;

    PGL.AddFont(Self);

    PGL.Context.SetIgnoreDebug(False);

  end;

constructor TPGLFont.Create(AFontName: String; AResolution: TPoint; ACreateSDFFont: Boolean = False);
  begin
    PGL.context.SetIgnoreDebug(True);
    Self.fResolution := AResolution;
    Self.fFontPath := AFontName;

    if ACreateSDFFont = true then begin
      Self.MakeSDFs(Self.fFontPath);
    end else begin
      Self.MakeNormals(Self.fFontPath);
    end;

    PGL.AddFont(Self);

    PGL.Context.SetIgnoreDebug(False);
  end;

destructor TPGLFont.Destroy();
var
I: GLInt;
  begin

    for I := 0 to High(Self.fAtlas) do begin
      Self.fAtlas[i].Free();
      Self.fAtlas[i] := Nil;
    end;

    inherited Destroy();
  end;

procedure TPGLFont.Free();
  begin
    inherited Free();
  end;

procedure TPGLFont.Refresh();
var
I: GLInt;
  begin

      for I := 0 to High(Self.fAtlas) do begin
        Self.fAtlas[i].Free();
        Self.fAtlas[i] := Nil;
      end;

      Self.MakeNormals(Self.fFontPath);

      PGL.UpdateFontRefresh(Self);
  end;

procedure TPGLFont.MakeNormals(AFontName: String);
  begin
    SetLength(Self.fAtlas,10);

    Self.fAtlas[0] := TPGLAtlas.Create(Self);
    Self.fAtlas[0].MakeNormal(AFontName,8);

    Self.fAtlas[1] := TPGLAtlas.Create(Self);
    Self.fAtlas[1].MakeNormal(AFontName,12);

    Self.fAtlas[2] := TPGLAtlas.Create(Self);
    Self.fAtlas[2].MakeNormal(AFontName,16);

    Self.fAtlas[3] := TPGLAtlas.Create(Self);
    Self.fAtlas[3].MakeNormal(AFontName,20);

    Self.fAtlas[4] := TPGLAtlas.Create(Self);
    Self.fAtlas[4].MakeNormal(AFontName,24);

    Self.fAtlas[5] := TPGLAtlas.Create(Self);
    Self.fAtlas[5].MakeNormal(AFontName,30);

    Self.fAtlas[6] := TPGLAtlas.Create(Self);
    Self.fAtlas[6].MakeNormal(AFontName,36);

    Self.fAtlas[7] := TPGLAtlas.Create(Self);
    Self.fAtlas[7].MakeNormal(AFontName,48);

    Self.fAtlas[8] := TPGLAtlas.Create(Self);
    Self.fAtlas[8].MakeNormal(AFontName,60);

    Self.fAtlas[9] := TPGLAtlas.Create(Self);
    Self.fAtlas[9].MakeNormal(AFontName,72);
  end;

procedure TPGLFont.MakeSDFs(AFontName: String);
  begin
    SetLength(Self.fAtlas,6);

    Self.fAtlas[0] := TPGLAtlas.Create(Self);
    Self.fAtlas[0].MakeSDF(AFontName,12);

    Self.fAtlas[1] := TPGLAtlas.Create(Self);
    Self.fAtlas[1].MakeSDF(AFontName,16);

    Self.fAtlas[2] := TPGLAtlas.Create(Self);
    Self.fAtlas[2].MakeSDF(AFontName,24);

    Self.fAtlas[3] := TPGLAtlas.Create(Self);
    Self.fAtlas[3].MakeSDF(AFontName,32);

    Self.fAtlas[4] := TPGLAtlas.Create(Self);
    Self.fAtlas[4].MakeSDF(AFontName,48);

    Self.fAtlas[5] := TPGLAtlas.Create(Self);
    Self.fAtlas[5].MakeSDF(AFontName,60);

  end;

function TPGLFont.GetAtlas(Index: Integer): TPGLAtlas;
  begin
    if (Index <= High(Self.fAtlas)) and (Index >= 0) then begin
      Result := Self.fAtlas[Index];
    end else begin
      Result := Self.fAtlas[0];
    end;
  end;

function TPGLFont.SelectAtlas(APointSize: GLInt): TPGLAtlas;
var
Diff: GLInt;
CurDiff: GLInt;
Selected: GLInt;
I: GLInt;
  begin
    Result := Self.fAtlas[0];
    CurDiff := abs(APointSize - Self.fAtlas[0].PointSize);
    Selected := 0;

    for I := 0 to High(Self.fAtlas) do begin
      Diff := APointSize - Self.fAtlas[i].PointSize;

      if abs(Diff) < CurDiff then begin
        CurDiff := abs(Diff);
        Selected := I;
      end;
    end;

    Result := Self.fAtlas[Selected];

  end;

function TPGLFont.GetCharacter(ACharacter: Char; APointSize: GLInt): TPGLCharacter;
var
CurAtlas: TPGLAtlas;
Adj: GLFloat;
  begin
    CurAtlas := Self.SelectAtlas(APointSize);
    Adj := APointSize / CurAtlas.PointSize;

    Result := CurAtlas.fCharacter[Ord(ACharacter)];
    Result.Width := RoundF(Result.Width * Adj);
    Result.Height := RoundF(Result.Height * Adj);
    Result.GlyphWidth := RoundF(Result.GlyphWidth * Adj);
    Result.GlyphHeight := RoundF(Result.GlyphHeight * Adj);
    Result.Advance := Result.Advance * Adj;
    Result.TailHeight := Result.TailHeight * Adj;
    Result.BearingX := Result.BearingX * Adj;
    Result.BearingY := Result.BearingY * Adj;
    Result.Bounds.Stretch(Adj,Adj);

  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                    TPGLText
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLText.Create();
  begin
    Self.fTextHeight := 0;
    PGL.AddText(Self);
  end;


constructor TPGLText.Create(AFont: TPGLFont; AText: String = ''; APointSize: GLUInt = 12);
  begin
    Self.fTextHeight := 0;
    Self.fFont := AFont;
    Self.fPointSize := APointSize;
    Self.SetText(AText);
    PGL.AddText(Self);
  end;

destructor TPGLText.Destroy();
  begin
    PGL.RemoveText(Self);
    inherited;
  end;

procedure TPGLText.Free();
  begin
    inherited Free();
  end;

function TPGLText.GetTextLineWidth(AIndex: GLInt): GLFloat;
var
I: GLInt;
TextWidth: GLFloat;
CharNum: GLInt;
Adj: GLFloat;
CurAtlas: TPGLAtlas;
  begin

    CurAtlas := Self.fAtlasUsing;

    TextWidth := 0;
    Adj := Self.PointSize / CurAtlas.PointSize;

    for I := 1 to Length(Self.fTextLines[AIndex]) do begin
      CharNum := Ord(Self.fTextLines[AIndex][I]);
      TextWidth := TextWidth + (CurAtlas.fCharacter[CharNum].Advance * Adj);
    end;

    Self.fLineWidths[AIndex] := (TextWidth);
    Result := (TextWidth);
  end;

procedure TPGLText.UpdateBounds();
var
TopLeft: TPGLVec3;
  begin
    if Self.Centered then begin

      if Self.fBoundsLocked = false then begin
        Self.fBounds.SetSize(Self.fTextWidth, Self.fTextHeight, from_center);
      end else begin
        Self.fBounds.SetSize(Self.fLockWidth, Self.fLockHeight, from_center);
      end;

    end else begin

      TopLeft := Vec2(Self.fBounds.Left, Self.fBounds.Top);

      if Self.fBoundsLocked = false then begin
        Self.fBounds.SetSize(Self.fTextWidth, Self.fTextHeight, from_center);
      end else begin
        Self.fBounds.SetSize(Self.fLockWidth, Self.fLockHeight, from_center);
      end;

      Self.fBounds.SetTopLeft(TopLeft.X, TopLeft.Y);

    end;
  end;

function TPGLText.GetBounds(): TPGLRectF;
  begin
    Result := Self.fBounds;
  end;

function TPGLText.GetNumLines(): GLInt; register;
  begin
    Result := High(Self.fTextLines);
  end;

function TPGLText.GetLineBounds(I: GLInt): TPGLRectF; register;
var
Adj: GLFloat;
  begin
    if Length(Self.fTextLines) = 0 then begin
      Result := RectFWH(0,0,0,0);
      exit;
    end;

    Adj := Self.PointSize / Self.fAtlasUsing.PointSize;
    Result := RectFWH(Self.Bounds.Left, Self.Bounds.Top + ((Self.fAtlasUsing.Height * I) * Adj), Self.Bounds.Width, Self.fAtlasUsing.Height * Adj);
  end;

procedure TPGLText.Reset();
  begin
    Self.fFont := nil;
    Self.fBounds := RectFWH(0,0,0,0);
    Self.fTextWidth := 0;
    SetLength(Self.fTextLines, 0);
    SetLength(Self.fLineWidths, 0);
    Self.fTextHeight := 0;
    self.fText := '';
    Self.fPointSize := 12;
    Self.fAtlasUsing := nil;
    Self.fBoundsLocked := False;
    Self.fLockWidth := 0;
    Self.fLockHeight := 0;
    Self.fLockYOffSet := 0;
    Self.fLockYMaxOffSet := 0;
  end;

procedure TPGLText.SetTextProp(const AText: String);
  begin
    Self.SetText(AText);
  end;

procedure TPGLText.SetText(const AText: String);
  begin
    if Self.fBoundsLocked then begin
      Self.SetTextLocked(AText);
    end else begin
      Self.SetTextNoLock(AText);
    end;
  end;


procedure TPGLText.SetTextNoLock(AText: String);
var
I,R: GLInt;
CurPos: GLInt;
CharNum: GLInt;
CurAtlas: TPGLAtlas;
TextWidth: GLFloat;
HighWidth: GLFloat;
Adj: GLFloat;
  begin

    if Assigned(Self.fFont) = false then Exit;

    Self.fLockYOffSet := 0;
    Self.fLockYMaxOffSet := 0;

    Self.fAtlasUsing := Self.Font.SelectAtlas(Self.PointSize);
    CurAtlas := Self.fAtlasUsing;

    Self.fText := AText;
    Adj := Self.PointSize / CurAtlas.PointSize;

    // separate text into array of indivual lines based on line breaks
    SetLength(Self.fTextLines,0);
    CurPos := 1;
    I := 1;
    while I <= Length(Self.fText) do begin
      CharNum := Ord(Char(Self.fText[I])); // convert text character to ascii code

      // if ascii code is carriage return, copy from CurPos to I - 1 into TextLine
      if (CharNum = 13) then begin
        SetLength(Self.fTextLines, Length(Self.fTextLines) + 1);
        R := High(Self.fTextLines);
        Self.fTextLines[R] := MidStr(Self.fText, CurPos, I - CurPos);
        Inc(I);
        CurPos := I + 1;
      end;

      // if end of string, copy remainder into TextLine
      if I >= Length(Self.fText) then begin
        I := Length(Self.fText);
        SetLength(Self.fTextLines, Length(Self.fTextLines) + 1);
        R := High(Self.fTextLines);
        Self.fTextLines[R] := MidStr(Self.fText, CurPos, I - CurPos + 1);
        Break;
      end;

      Inc(I);

    end;

    SetLength(Self.fLineWidths, Length(Self.fTextLines));

    // set bounds width to widest TextLine
    HighWidth := 0;
    for I := 0 to High(Self.fTextLines) do begin
      TextWidth := Self.GetTextLineWidth(I);
      if TextWidth > HighWidth then begin
        HighWidth := TextWidth;
      end;
    end;

    Self.fTextWidth := (HighWidth);

    // Bounds Height is number of text lines * Font Atlas Real Height
    Self.fTextHeight := Length(Self.fTextLines) * (CurAtlas.Height * Adj);

    Self.UpdateBounds();
  end;

procedure TPGLText.SetTextLocked(AText: String);
var
TextWidth: GLFloat;
I,R: GLInt;
Adj: GLFloat;
CurPos: GLInt;
Words: TArray<String>;
CharCount: GLInt;
Breaks: TArray<GLInt>;
CurAtlas: TPGLAtlas;
CurLine: String;
WordWidth: GLFloat;
SpaceWidth: GLFloat;
Skip: Boolean;
  begin

    if Assigned(Self.fFont) = False then Exit;

    Self.fText := AText;
    Self.fAtlasUsing := Self.Font.SelectAtlas(Self.PointSize);
    CurAtlas := Self.fAtlasUsing;

    Adj := Self.PointSize / CurAtlas.PointSize;

    CharCount := 0;
    Words := pglTextToWordArray(AText, ' ');

    // get line breaks
    I := 0;
    While I <= High(Words) do begin

      CurPos := Pos(sLineBreak,Words[i],1);

      if CurPos <> 0 then begin
        SetLength(Breaks, Length(Breaks) + 1);
        Breaks[High(Breaks)] := I + 1;
        CurLine := Words[i];

        SetLength(Words,Length(Words) + 1);
        R := High(Words);
        while R > I do begin
          Words[R] := Words[R -1];
          Dec(R);
        end;

        Words[i] := MidStr(CurLine, 1, CurPos - 1);
        Words[i + 1] := MidStr(CurLine, CurPos + 1, Length(CurLine) - (CurPos));

      end;

      Inc(I);

    end;

    TextWidth := 0;
    SpaceWidth := CurAtlas.fCharacter[32].Advance * Adj;
    CurLine := '';

    SetLength(Self.fLineWidths, 0);
    SetLength(Self.fTextLines, 0);

    for I := 0 to High(Words) do begin

      for R := 0 to high(Breaks) do begin
        if Breaks[r] = I then begin
          SetLength(Self.fLineWidths, Length(Self.fLineWidths) + 1);
          SetLength(Self.fTextLines, Length(Self.fTextLines) + 1);
          Self.fLineWidths[High(Self.fLineWidths)] := TextWidth;
          Self.fTextLines[High(Self.fTextLines)] := CurLine;
          TextWidth := 0;
          CurLine := '';
        end;
      end;

      Skip := False;

      WordWidth := CurAtlas.GetTextWidth(Words[i]) * Adj;

      // if single word is bigger than or equal to locked bounds width
      if (WordWidth >= Self.fLockWidth) or (WordWidth + SpaceWidth >= Self.fLockWidth) then begin

        if CurLine <> '' then begin

          SetLength(Self.fLineWidths, Length(Self.fLineWidths) + 1);
          SetLength(Self.fTextLines, Length(Self.fTextLines) + 1);
          Self.fLineWidths[High(Self.fLineWidths)] := TextWidth;
          Self.fTextLines[High(Self.fTextLines)] := CurLine;
          TextWidth := 0;
          CurLine := '';
          Skip := True;

        end else begin

          SetLength(Self.fLineWidths, Length(Self.fLineWidths) + 1);
          SetLength(Self.fTextLines, Length(Self.fTextLines) + 1);
          Self.fLineWidths[High(Self.fLineWidths)] := WordWidth;
          Self.fTextLines[High(Self.fTextLines)] := Words[i];
          TextWidth := 0;
          CurLine := '';
          continue; // go to next iteration

        end;

      end;

      // if not single word is width of locked bounds width, move on combining words

      // if new word would make line too long
      if Skip = False then begin
        if TextWidth + WordWidth + SpaceWidth >= Self.fLockWidth then begin
          SetLength(Self.fLineWidths, Length(Self.fLineWidths) + 1);
          SetLength(Self.fTextLines, Length(Self.fTextLines) + 1);
          Self.fLineWidths[High(Self.fLineWidths)] := TextWidth;
          Self.fTextLines[High(Self.fTextLines)] := CurLine;
          TextWidth := 0;
          CurLine := '';
        end;
      end;

      TextWidth := TextWidth + WordWidth + SpaceWidth;
      CurLine := CurLine + Words[i] + ' ';

    end;

    // if there is still text left in curline
    if Curline <> '' then begin
      SetLength(Self.fLineWidths, Length(Self.fLineWidths) + 1);
      SetLength(Self.fTextLines, Length(Self.fTextLines) + 1);
      Self.fLineWidths[High(Self.fLineWidths)] := TextWidth;
      Self.fTextLines[High(Self.fTextLines)] := CurLine;
    end;

    // get the overall longest line width
    TextWidth := 0;
    for I := 0 to High(Self.fLineWidths) do begin
      if Self.fLineWidths[i] > TextWidth then begin
        TextWidth := Self.fLineWidths[i];
      end;
    end;

    Self.fTextWidth := TextWidth;

    Self.fTextHeight := (CurAtlas.Height * Length(Self.fTextLines)) * Adj;

    Self.fLockYMaxOffSet := Biggest([0,Self.fTextHeight - Self.fBounds.Height]);
    if Self.fLockYOffSet > Self.fLockYMaxOffSet then Self.fLockYOffSet := Self.fLockYMaxOffSet;

  end;

procedure TPGLText.SetPointSize(ASize: GLUint);
  begin
    Self.fPointSize := ASize;
    Self.SetText(Self.Text);
  end;

procedure TPGLText.SetTextColor(AColor: TPGLColorF);
  begin
    Self.fTextColor := AColor;
  end;

procedure TPGLText.SetBackColor(AColor: TPGLColorF);
  begin
    Self.fBackColor := AColor;
  end;

procedure TPGLText.KeepCentered(ACentered: Boolean = True);
  begin
    Self.fCentered := ACentered;
  end;

procedure TPGLText.LockBounds(ALock: Boolean = True);
  begin
    Self.fBoundsLocked := ALock;
  end;

procedure TPGLText.SetLockedSize(ALockedWidth, ALockedHeight: GLUint);
  begin
    Self.fLockWidth := ALockedWidth;
    Self.fLockHeight := ALockedHeight;
    Self.UpdateBounds;
  end;

procedure TPGLText.SetLockedWidth(ALockedWidth: GLUint);
  begin
    Self.fLockWidth := ALockedWidth;
    Self.UpdateBounds;
  end;

procedure TPGLText.SetLockedHeight(ALockedHeight: GLUint);
  begin
    Self.fLockHeight := ALockedHeight;
    Self.UpdateBounds;
  end;

procedure TPGLText.SetLockedBoundsYOffSet(AOffSet: GLFloat);
  begin

    if Self.fBoundsLocked = False then Exit;

    if AOffSet < 0 then AOffSet := 0;
    if AOffSet > Biggest([0,Self.fTextHeight - Self.Bounds.Height]) then AOffSet := Biggest([0,Self.fTextHeight - Self.Bounds.Height]);

    Self.fLockYOffSet := AOffSet;
  end;

procedure TPGLText.IncLockedBoundsYOffSet(AValue: GLFloat);
   begin
    Self.SetLockedBoundsYOffSet(Self.fLockYOffSet + AValue);
   end;

procedure TPGLText.SetLeft(ALeft: GLFloat);
  begin
    Self.fBounds.SetLeft(ALeft);
    Self.UpdateBounds();
  end;

procedure TPGLText.SetTop(ATop: GLFloat);
  begin
    Self.fBounds.SetTop(ATop);
    Self.UpdateBounds();
  end;

procedure TPGLText.SetCenter(ACenter: TPGLVec3);
  begin
    Self.fBounds.SetCenter(ACenter);
    Self.UpdateBounds();
  end;


procedure TPGLText.WriteToTexture(ATexture: TPGLTexture);
var
ReturnPos: TPGLVec2;
  begin

    if Assigned(Self.fFont) = False then Exit;

    // don't allow if the texture is attached to a target
    if ATexture.AttachedToTarget then exit;

    ATexture.ReSize(RoundUp(Self.fBounds.Width), RoundUp(Self.fBounds.Height), False);
    ATexture.Clear();

    ReturnPos := Vec2(Self.Bounds.Left, Self.Bounds.Top);

    Self.SetLeft(0);
    Self.SetTop(0);

    PGL.TempBuffer.AttachTexture(ATexture);
    PGL.TempBuffer.DrawText(Self.Text, Self.Font, Self.PointSize, Vec2(0,0), Self.TextColor, pgl_empty);

    PGL.TempBuffer.RestoreTexture();

    ATexture.fDataSize := (ATexture.Width * ATexture.Height) * 4;

    Self.SetLeft(ReturnPos.X);
    Self.SetTop(ReturnPos.Y);
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                TPGLRenderTarget
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLRenderTarget.Create(AWidth,AHeight: GLUint);
  begin
    Self.fWidth := AWidth;
    Self.fHeight := AHeight;
    Self.fClearColor := pgl_empty;
    Self.fClearDepth := PGL.DrawState.ViewFar;
    Self.fRenderRect := RectIWH(0,0,AWidth,AHeight);
    Self.fDepthAttach := True;
    Self.fColorValues := Vec3(1,1,1);
    Self.GlobalDrawValues.Brightness := 1;
    Self.GlobalDrawValues.ColorValues := ColorF(1,1,1);
    Self.GlobalDrawValues.ColorOverlay := ColorF(0,0,0);
    Self.GlobalDrawValues.GreyScale := 0;
    Self.GlobalDrawValues.MonoChrome := 0;
    Self.GlobalDrawValues.TargetWidth := Self.Width;
    Self.GlobalDrawValues.TargetHeight := Self.Height;
    Self.GlobalDrawValues.BlitOpacity := 1;
    Self.TextParams.ScalePointSizes := true;
    Self.TextParams.ClipBounds := Self.fRenderRect;
  end;

destructor TPGLRenderTarget.Destroy();
  begin
    inherited Destroy();
  end;

procedure TPGLRenderTarget.Free();
  begin
    inherited Free();
  end;

procedure TPGLRenderTarget.CreateFBO(AWidth,AHeight: GLUint);
var
ErrorString: AnsiString;
  begin

    Self.fWidth := AWidth;
    Self.fHeight := AHeight;

    // Create texture and depth buffer for FBO
    glGenTextures(1,@Self.fOwnedTexture);
    Self.fTexture2D := Self.fOwnedTexture;
    glBindTexture(GL_TEXTURE_2D, Self.fTexture2D);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, AWidth, AHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);

    // back texture used in post processing
    glGenTextures(1,@Self.fBackTexture2D);
    glBindTexture(GL_TEXTURE_2D, Self.fBackTexture2D);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, AWidth, AHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);

    // normal map
    glGenTextures(1,@Self.fNormalMap);
    glBindTexture(GL_TEXTURE_2D, Self.fNormalMap);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8_SNORM , AWidth, AHeight, 0, GL_RGBA, GL_FLOAT, nil);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);

    // position map, integer
    glGenTextures(1,@Self.fPositionMap);
    glBindTexture(GL_TEXTURE_2D, Self.fPositionMap);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32I, AWidth, AHeight, 0, GL_RGBA_INTEGER, GL_INT, nil);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);

    // depth/stencil buffer
    glGenTextures(1,@Self.fDepthBuffer);
    glBindTexture(GL_TEXTURE_2D, Self.fDepthBuffer);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32F, AWidth, AHeight, 0, GL_DEPTH_COMPONENT, GL_FLOAT, nil);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_REF_TO_TEXTURE);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC, GL_LEQUAL);
    glBindTexture(GL_TEXTURE_2D, 0);

    // create FBO and assign textures
    glGenFramebuffers(1,@Self.fFrameBuffer);
    glBindFrameBuffer(GL_FRAMEBUFFER,Self.fFrameBuffer);
    glFrameBufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, Self.fOwnedTexture, 0);
    glFrameBufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, Self.fBackTexture2D, 0);
    glFrameBufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, Self.fDepthBuffer, 0);
    glFrameBufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT2, GL_TEXTURE_2D, Self.fNormalMap, 0);
    glFrameBufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT3, GL_TEXTURE_2D, Self.fPositionMap, 0);


    if glCheckFrameBufferStatus(GL_FRAMEBUFFER) <> GL_FRAMEBUFFER_COMPLETE then begin
      ErrorString := 'Framebuffer status check failed. Framebuffer is incomplete!';
      pglDebug(999, 999, 999, 999, Length(ErrorString), @ErrorString[1], nil);
    end;

    Self.Clear();

  end;


function TPGLRenderTarget.GetAngles(): TPGLVec3;
  begin
    Result := Vec3(Self.fAngleX, Self.fAngleY, Self.fAngleZ);
  end;


procedure TPGLRenderTarget.ChangeSize();
  begin

  end;

procedure TPGLRenderTarget.MakeCurrentTarget();
var
V: Array [0..3] of GLInt;
I: GLInt;
  begin

    if PGL.SetCurrentTarget(Self) = false then begin
      PGL.DrawState.Camera.SetViewport(Self.RenderRect, PGL.Camera.ViewNear, PGL.Camera.ViewDistance);
      exit;
    end;

    glBindFramebuffer(GL_FRAMEBUFFER, Self.fFrameBuffer);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, self.fFrameBuffer);
    glDrawBuffer(GL_COLOR_ATTACHMENT0);
  end;


procedure TPGLRenderTarget.SetClearColor(AColor: TPGLColorF);
  begin
    Self.fClearColor := AColor;
  end;


procedure TPGLRenderTarget.SetClearDepth(ADepth: GLFLoat);
  begin
    Self.fClearDepth := ADepth;
  end;

procedure TPGLRenderTarget.SetColorValues(AValues: TPGLColorF);
  begin
    Self.GlobalDrawValues.ColorValues := AValues;
  end;

procedure TPGLRenderTarget.SetColorOverlay(AValues: TPGLColorF);
  begin
    Self.GlobalDrawValues.ColorOverlay := AValues;
  end;

procedure TPGLRenderTarget.SetBrightness(AValue: Single);
  begin
    Self.GlobalDrawValues.Brightness := AValue;
  end;

procedure TPGLRenderTarget.SetGreyScale(AGreyScale: Boolean = True);
  begin
    Self.GlobalDrawValues.GreyScale := AGreyScale.ToInteger;
  end;

procedure TPGLRenderTarget.SetMonoChrome(AMonoChrome: Boolean = True);
  begin
    Self.GlobalDrawValues.MonoChrome := AMonoChrome.ToInteger;
  end;

procedure TPGLRenderTarget.SetAngleX(AX: GLFloat);
  begin
    Self.fAngleX := AX;
  end;

procedure TPGLRenderTarget.SetAngleY(AY: GLFloat);
  begin
    Self.fAngleY := AY;
  end;

procedure TPGLRenderTarget.SetAngleZ(AZ: GLFloat);
  begin
    Self.fangleZ := AZ;
  end;

procedure TPGLRenderTarget.SetAngles(AAngles: TPGLVec3);
  begin
    Self.fAngleX := AAngles.X;
    Self.fAngleY := AAngles.Y;
    Self.fAngleZ := AAngles.Z;
  end;

procedure TPGLRenderTarget.RotateX(AX: GLFloat);
  begin
   IncF(Self.fAngleX, AX);
  end;

procedure TPGLRenderTarget.RotateY(AY: GLFloat);
  begin
    IncF(Self.fAngleY, AY);
  end;

procedure TPGLRenderTarget.RotateZ(AZ: GLFloat);
  begin
    IncF(Self.fAngleZ, AZ);
  end;

procedure TPGLRenderTarget.Rotate(AAngles: TPGLVec3);
  begin
    IncF(Self.fAngleX, AAngles.X);
    IncF(Self.fAngleY, AAngles.Y);
    IncF(Self.fAngleZ, AAngles.Z);
  end;

procedure TPGLRenderTarget.SetDrawOffSet(AOffSet: TPGLVec3);
  begin
    Self.DrawLastBatch();
    Self.fDrawOffset := AOffSet;
  end;

procedure TPGLRenderTarget.SetDrawOffSetX(AOffSetX: GLFloat);
  begin
    Self.DrawLastBatch();
    Self.fDrawOffSet.X := AOffSetX;
  end;

procedure TPGLRenderTarget.SetDrawOffSetY(AOffSetY: GLFloat);
  begin
    Self.DrawLastBatch();
    Self.fDrawOffSet.Y := AOffSetY;
  end;

procedure TPGLRenderTarget.Clear();
var
Buffs: Array [0..1] of GLEnum;
  begin
    Self.MakeCurrentTarget();
    Self.DrawLastBatch();

    Buffs[0] := GL_COLOR_ATTACHMENT0;
    Buffs[1] := GL_COLOR_ATTACHMENT1;

    glDrawBuffers(2,@Buffs);

    glDisable(GL_SCISSOR_TEST);
    glEnable(GL_DEPTH_TEST);
    glClearDepth(Self.ClearDepth);
    glDepthMask(GL_TRUE);

    glClearColor(Self.ClearColor.Red, Self.ClearColor.Green, Self.ClearColor.Blue, Self.ClearColor.Alpha);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);


    glDrawBuffer(GL_COLOR_ATTACHMENT0);

  end;


procedure TPGLRenderTarget.Clear(AColor: TPGLColorF);
var
Buffs: Array [0..1] of GLEnum;
  begin

    Self.MakeCurrentTarget();

    Buffs[0] := GL_COLOR_ATTACHMENT0;
    Buffs[1] := GL_COLOR_ATTACHMENT1;

    glDrawBuffers(2,@Buffs);

    glDisable(GL_SCISSOR_TEST);
    glClearDepth(Self.fClearDepth);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_ALWAYS);
    glDepthMask(GL_TRUE);

    glClearColor(AColor.Red, AColor.Green, AColor.Blue, AColor.Alpha);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

    glDrawBuffer(GL_COLOR_ATTACHMENT2);
    glClearColor(0,0,0,1);
    glClear(GL_COLOR_BUFFER_BIT);

    glDrawBuffer(GL_COLOR_ATTACHMENT0);
  end;


procedure TPGLRenderTarget.DistanceLight();
var
Ver,Cor: TArray<TPGLVec3>;
TempName: GLUInt;
  begin

    Self.DrawLastBatch();

    Ver := RectFWH(0,0,Self.Width,Self.height).toVectors;
    ScaleNDC(Ver,Self.Width,Self.Height,1);
    Cor := PGLTypes.RectF(0,0,1,1).toVectors;
    Cor[0].Z := 0;
    Cor[1].Z := 0;
    Cor[2].Z := 0;
    Cor[3].Z := 0;


    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_ALWAYS);
    glDepthMask(GL_FALSE);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, PGL.DrawState.Buffers.EBO);

    PGL.BindTexture(0,Self.fTexture2D);
    PGL.BindTexture(1,Self.fDepthBuffer);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVec3) * 4, @Ver[0]);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, Pointer(0));

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVec3) * 4, @Cor[0]);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, Pointer(0));

    PGL.UseProgram('Depth Light');

    glUniform1i(PGL.GetUniform('tex'),0);
    glUniform1i(PGL.GetUniform('depth'),1);

    glDrawArrays(GL_QUADS,0,4);

    PGL.DrawState.Buffers.Reset();
  end;

procedure TPGLRenderTarget.ReplaceColor(ARect: TPGLRectI; AOldColor,ANewColor: TPGLColorF);
var
Ver,Coord: TArray<TPGLVec3>;
TransMat: TPGLMat4;
  begin

    TransMat.MakeTranslation(ARect.X, ARect.Y);
    ARect.Translate(-ARect.X, -ARect.Y, 0);
    Ver := ARect.toVectors();
    Coord := ARect.toVectors();
    ScaleCoord(Coord,Self.width,Self.Height,1);

    Self.DrawLastBatch();
    Self.MakeCurrentTarget();

    glEnable(GL_SCISSOR_TEST);
    glScissor(0,0,Self.Width,Self.Height);

    if PGL.DepthWrite then begin
      glEnable(GL_DEPTH_TEST);
      glDepthMask(GL_TRUE);
      glDepthFunc(GL_LEQUAL);
    end;

    PGL.BindTexture(0,Self.fTexture2D);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.Subdata(SizeOf(TPGLVec3) * 4, @Ver[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.Subdata(SizeOf(TPGLVec3) * 4, @Coord[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, 0);

    PGL.UseProgram('Target Replace Color');

    glUniform1i(PGL.GetUniform('tex'),0);
    glUniform1f(PGL.GetUniform('Threshold'),PGL.DrawState.ColorCompareThreshold);
    glUniform4fv(PGL.GetUniform('SearchColor'),1,@AOldColor);
    glUniform4fv(PGL.GetUniform('ReplaceColor'),1,@ANewColor);
    glUniformMatrix4fv(PGL.GetUniform('TransMat'),1,GL_FALSE,@TransMat);

    glDrawArrays(GL_QUADS,0,4);

    PGL.DrawState.Buffers.Reset();

  end;


procedure TPGLRenderTarget.AdjustColors(AColors: TPGLColorF);
var
Ver,Coord: TArray<TPGLVec3>;
  begin

    Self.DrawLastBatch();
    Self.MakeCurrentTarget();

    glCopyImageSubData(Self.fTexture2D, GL_TEXTURE_2D, 0, 0, 0, 0, Self.fBackTexture2D, GL_TEXTURE_2D,
      0, 0, 0, 0, Self.Width, Self.Height, 1);

    SetLength(Ver,4);
    Ver[0] := Vec2(-1,-1);
    Ver[1] := Vec2(1,-1);
    Ver[2] := Vec2(1,1);
    Ver[3] := Vec2(-1,1);

    SetLength(Coord,4);
    Coord[0] := Vec2(0,0);
    Coord[1] := Vec2(1,0);
    Coord[2] := Vec2(1,1);
    Coord[3] := Vec2(0,1);


    glEnable(GL_SCISSOR_TEST);
    glScissor(0,0,Self.Width,Self.Height);

    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);

    PGL.BindTexture(0,Self.fBackTexture2D);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.Subdata(SizeOf(TPGLVec3) * 4, @Ver[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.Subdata(SizeOf(TPGLVec3) * 4, @Coord[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, 0);

    PGL.UseProgram('Target Adjust Color');

    glUniform1i(PGL.GetUniform('tex'),0);
    glUniform4fv(PGL.GetUniform('vColor'),1,@AColors);

    glDrawArrays(GL_QUADS,0,4);

    PGL.DrawState.Buffers.Reset();

  end;


procedure TPGLRenderTarget.AdjustColorScale(AColors: TPGLColorF);
var
Ver,Coord: TArray<TPGLVec3>;
  begin

    Self.DrawLastBatch();
    Self.MakeCurrentTarget();

    glCopyImageSubData(Self.fTexture2D, GL_TEXTURE_2D, 0, 0, 0, 0, Self.fBackTexture2D, GL_TEXTURE_2D,
      0, 0, 0, 0, Self.Width, Self.Height, 1);

    SetLength(Ver,4);
    Ver[0] := Vec2(-1,-1);
    Ver[1] := Vec2(1,-1);
    Ver[2] := Vec2(1,1);
    Ver[3] := Vec2(-1,1);

    SetLength(Coord,4);
    Coord[0] := Vec2(0,0);
    Coord[1] := Vec2(1,0);
    Coord[2] := Vec2(1,1);
    Coord[3] := Vec2(0,1);


    glEnable(GL_SCISSOR_TEST);
    glScissor(0,0,Self.Width,Self.Height);

    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);

    PGL.BindTexture(0,Self.fBackTexture2D);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.Subdata(SizeOf(TPGLVec3) * 4, @Ver[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.Subdata(SizeOf(TPGLVec3) * 4, @Coord[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, 0);

    PGL.UseProgram('Target Color Scale');

    glUniform1i(PGL.GetUniform('tex'),0);
    glUniform4fv(PGL.GetUniform('vColor'),1,@AColors);

    glDrawArrays(GL_QUADS,0,4);

    PGL.DrawState.Buffers.Reset();

  end;

procedure TPGLRenderTarget.Darken(ARect: TPGLRectI; ALightValue: GLFloat);
var
Ver,Coord: TArray<TPGLVec3>;
TransMat: TPGLMat4;
Buffs: Array [0..1] of GLEnum;
  begin

    Ver := RectI(-1, -1, 1, 1).toVectors();
    Coord := RectI(0, 0, 1, 1).toVectors();

    Self.DrawLastBatch();
    Self.MakeCurrentTarget();

    Buffs[0] := GL_COLOR_ATTACHMENT0;
    Buffs[1] := GL_COLOR_ATTACHMENT2;
    glDrawBuffers(2,@Buffs);


    glEnable(GL_SCISSOR_TEST);
    glScissor(0,0,Self.Width,Self.Height);

    glDisable(GL_DEPTH_TEST);

    PGL.BindTexture(0,Self.fTexture2D);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.Subdata(SizeOf(TPGLVec3) * 4, @Ver[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.Subdata(SizeOf(TPGLVec3) * 4, @Coord[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, 0);

    PGL.UseProgram('Darken Target');

    glUniform1i(PGL.GetUniform('tex'),0);
    glUniform1f(PGL.GetUniform('Value'),ALightValue);

    glDrawArrays(GL_QUADS,0,4);

    PGL.DrawState.Buffers.Reset();

    glDrawBuffer(GL_COLOR_ATTACHMENT0);

  end;

procedure TPGLRenderTarget.DrawLastBatch();
var
P: PByte;
  begin

    if PGL.DrawState.Params.DrawCount = 0 then exit;

    Self.MakeCurrentTarget();

    Self.DrawPointBatch();
    Self.DrawCircleBatch();
    Self.DrawRectangleBatch();
    Self.DrawSpriteBatch();
    Self.DrawTextureBatch();
    Self.DrawShapeBatch();
    Self.DrawLineBatch();
    Self.DrawLightBatch();

    PGL.DrawState.Buffers.Reset();
    PGL.DrawState.Params.DrawCount := 0;
    PGL.DrawState.Params.VertexCount := 0;
    PGL.DrawState.Params.ElementCount := 0;
  end;

procedure TPGLRenderTarget.DrawPointBatch();
  begin

    if (PGL.DrawState.State <> 'Point') then exit;
    if (PGL.DrawState.Params.DrawCount = 0) then exit;

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, PGL.DrawState.Buffers.EBO);

    glEnable(GL_SCISSOR_TEST);
    glScissor(0,0,Self.Width,Self.Height);

    if PGL.DepthWrite then begin
      glEnable(GL_DEPTH_TEST);
      glDepthMask(GL_TRUE);
      glDepthFunc(GL_LEQUAL);
    end;

    glBindVertexArray(PGL.DrawState.Buffers.VAO);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVertex) * PGL.DrawState.Params.VertexCount, @PGL.DrawState.Params.Vertices[0]);

    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(0, 3, GL_FLOAT, GL_FALSE, SizeOf(TPGLVertex), 0);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(1, 4, GL_FLOAT, GL_FALSE, SizeOf(TPGLVertex), 12);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(GLFloat) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Size[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(2, 1, GL_FLOAT, GL_FALSE, 0, 0);

    PGL.UseProgram('Point');

    glUniformMatrix4fv(PGL.GetUniform('ProjMat'),1,GL_FALSE,@PGL.DrawState.Camera.ProjectionMatrix);
    glUniformMatrix4fv(PGL.GetUniform('ViewMat'),1,GL_FALSE,@PGL.DrawState.Camera.ViewMatrix);
    glUniform4fv(PGL.GetUniform('TransparentColor'),1,@PGL.DrawState.TransparentColor);

    glDrawArrays(GL_POINTS,0,PGL.DrawState.Params.VertexCount);

    PGL.DrawState.Buffers.Reset();

    PGL.DrawState.Params.DrawCount := 0;
    PGL.DrawState.Params.VertexCount := 0;
  end;

procedure TPGLRenderTarget.DrawPoint(APoint: TPGLVec3; AColor: TPGLColorF; ASize: Single);
var
CurDraw, CurVer: GLInt;
  begin

    Self.MakeCurrentTarget();

    if (PGL.DrawState.State <> 'Point') or (PGL.DrawState.Params.DrawCount = 1000) then begin
      Self.DrawLastBatch();
    end;

    PGL.DrawState.State := 'Point';

    CurDraw := PGL.DrawState.Params.DrawCount;
    CurVer := PGL.DrawState.Params.VertexCount;

    PGL.DrawState.Params.Vertices[CurVer].Vector := APoint + Self.fDrawOffSet;
    PGL.DrawState.Params.Vertices[CurVer].Color := AColor;
    PGL.DrawState.Params.Size[CurDraw] := Asize;

    Inc(PGL.DrawState.Params.DrawCount);
    Inc(PGL.DrawState.Params.VertexCount);
  end;


procedure TPGLRenderTarget.DrawSpriteBatch();
var
I: GLUInt;
TexCount: GLInt;
Values: Array of GLInt;
Buffs: Array [0..2] of GLEnum;
  begin

    if PGL.DrawState.Params.DrawCount = 0 then exit;
    if PGL.DrawState.State <> 'Sprite' then exit;

    Buffs[0] := GL_COLOR_ATTACHMENT0;
    Buffs[1] := GL_COLOR_ATTACHMENT2;
    Buffs[2] := GL_COLOR_ATTACHMENT3;
    glDrawBuffers(3, @Buffs);

    glEnable(GL_SCISSOR_TEST);
    glScissor(0,0,Self.Width,Self.Height);

    if PGL.DepthWrite then begin
      glEnable(GL_DEPTH_TEST);
      glDepthFunc(GL_LEQUAL);
      glDepthMask(GL_TRUE);
    end;

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, PGL.DrawState.Buffers.EBO);

    // bind textures in Params TexSlots
    TexCount := 0;
    for I := 0 to 31 do begin
      if PGL.DrawState.Params.TexSlot[i] <> 0 then begin
        glActiveTexture(GL_TEXTURE0 + I);
        glBindTexture(GL_TEXTURE_2D, PGL.DrawState.Params.TexSlot[i]);
        Inc(TexCount);
      end;
    end;

    setLength(Values,TexCount);
    for I := 0 to High(Values) do begin
      Values[i] := I;
    end;


    // Send attribute values
    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVertex) * PGL.DrawState.Params.VertexCount, @PGL.DrawState.Params.Vertices[0]);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, SizeOf(TPGLVertex), Pointer(0));

    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, SizeOf(TPGLVertex), Pointer(12));

    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, SizeOf(TPGLVertex), Pointer(28));

    glEnableVertexAttribArray(3);
    glVertexAttribPointer(3, 3, GL_FLOAT, GL_FALSE, SizeOf(TPGLVertex), Pointer(40));

    // send buffer binding values for sprites
    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLSpriteParams) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.SpriteInfo);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(0);

    // translation matrices
    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLMat4) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Translation[0]);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,4,PGL.DrawState.Buffers.CurrentSSBO.Buffer);

    // rotation matrices
    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLMat4) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Rotation[0]);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,5,PGL.DrawState.Buffers.CurrentSSBO.Buffer);

    // origin translation matrices
    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLMat4) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.OriginTranslation[0]);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,8,PGL.DrawState.Buffers.CurrentSSBO.Buffer);

    // TexUsing
    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(GLInt) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.TexUsing[0]);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER,6,PGL.DrawState.Buffers.CurrentSSBO.Buffer);

    PGL.UseProgram('Sprite');

    glUniformMatrix4fv(PGL.GetUniform('ProjMat'),1,GL_FALSE,@PGL.DrawState.Camera.ProjectionMatrix);
    glUniformMatrix4fv(PGL.GetUniform('ViewMat'),1,GL_FALSE,@PGL.DrawState.Camera.ViewMatrix);
    glUniform4fv(PGL.GetUniform('TransparentColor'),1,@PGL.DrawState.TransparentColor);
    glUniform1iv(PGL.GetUniform('tex'),texcount,@Values[0]);

    glMultiDrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_INT, @PGL.DrawState.Params.ElementIndirect[0], PGL.DrawState.Params.DrawCount, 0);

    for I := 0 to 31 do begin
      PGL.DrawState.Params.TexSlot[i] := 0;
    end;

    glDrawBuffer(GL_COLOR_ATTACHMENT0);
  end;


procedure TPGLRenderTarget.DrawSprite(var ASprite: TPGLSprite);
var
CurDraw, CurVer: GLInt;
Vecs: TArray<TPGLVec3>;
Coords: TArray<TPGLVec3>;
N: TPGLVec3;
UseTex: GLInt;
I: GLInt;
  begin

    Self.MakeCurrentTarget();

    // draw last batch if current state is not sprite or all tex slots are already used
    if (PGL.DrawState.State <> 'Sprite') or (PGL.DrawState.Params.TexSlot[31] <> 0) or (PGL.DrawState.Params.DrawCount >= 999) then begin
      Self.DrawLastBatch();
    end;

    PGL.DrawState.State := 'Sprite';

    if ASprite.fTexture = nil then Exit;
    if ASprite.fTexture.fEditMode then Exit;

    // Assign a texture slot in the draw params
    UseTex := -1;

    // loop through the tex slots to search for a match
    for I := 0 to High(PGL.DrawState.Params.TexSlot) do begin
      if PGL.DrawState.Params.TexSlot[i] = ASprite.fTexture.fHandle then begin
        UseTex := I;
        break;
      end;
    end;

    // if no match is found, search for the next empty slot
    if UseTex = -1 then begin
      for I := 0 to high(PGL.DrawState.Params.TexSlot) do begin
        if PGL.DrawState.Params.TexSlot[i] = 0 then begin
          UseTex := I;
          PGL.DrawState.Params.TexSlot[i] := ASprite.fTexture.fHandle;
          break;
        end;
      end;
    end;

    CurDraw := PGL.DrawState.Params.DrawCount;
    CurVer := PGL.DrawState.Params.VertexCount;

    PGL.DrawState.Params.TexUsing[CurDraw] := UseTex;

    // set up the indirect buffers
    PGL.DrawState.Params.ElementIndirect[CurDraw].Count := 6;
    PGL.DrawState.Params.ElementIndirect[CurDraw].InstanceCount := 1;
    PGL.DrawState.Params.ElementIndirect[CurDraw].First := 0;
    PGL.DrawState.Params.ElementIndirect[CurDraw].BaseVertex := CurVer;
    PGL.DrawState.Params.ElementIndirect[CurDraw].BaseInstance := 1;

    // set up the params for SSBO buffers
    PGL.DrawState.Params.SpriteInfo[CurDraw].Overlay := ASprite.ColorOverlay;
    PGL.DrawState.Params.SpriteInfo[CurDraw].GreyScale := ASprite.GreyScale.ToInteger;
    PGL.DrawState.Params.SpriteInfo[CurDraw].MonoChrome := ASprite.MonoChrome.ToInteger;
    PGL.DrawState.Params.SpriteInfo[CurDraw].Brightness := ASprite.Brightness;
    PGL.DrawState.Params.SpriteInfo[CurDraw].Opacity := ASprite.Opacity;

    // set up vertices for vertex attributes
    Vecs := ASprite.Bounds.ToVectors();
    Coords := ASprite.GetTexCoords();

    if PGL.Camera.CameraType = camera_type_3D then begin
      FlipVerticle(Coords);
    end;

    PGL.DrawState.Params.Translation[CurDraw].MakeTranslation(ASprite.Bounds.Center + Self.fDrawOffset + ASprite.Origin);
    PGL.DrawState.Params.OriginTranslation[CurDraw].MakeTranslation(-ASprite.Origin);
    PGL.DrawState.Params.Rotation[CurDraw].Rotate(ASprite.Angles);

    for I := 0 to 3 do begin
      PGL.DrawState.Params.Vertices[CurVer + I].Vector := Vecs[i] - ASprite.Bounds.Center;
      PGL.DrawState.Params.Vertices[CurVer + I].Color := ASprite.ColorValues;
      PGL.DrawState.Params.Vertices[CurVer + I].TexCoord := Coords[i];
      PGL.DrawState.Params.Vertices[CurVer + I].Normal := Vec3(0,0,1);
    end;

    // set up transformation matrices


    Inc(PGL.DrawState.Params.DrawCount);
    Inc(PGL.DrawState.Params.VertexCount,4);
  end;


procedure TPGLRenderTarget.DrawCircleBatch();
  begin

    if PGL.DrawState.Params.DrawCount = 0 then exit;
    if PGL.DrawState.State <> 'Circle' then exit;

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, PGL.DrawState.Buffers.EBO);

    glEnable(GL_SCISSOR_TEST);
    glScissor(0,0,Self.Width,Self.Height);

    if PGL.DepthWrite = True then begin
      glEnable(GL_DEPTH_TEST);
      glDepthFunc(GL_LEQUAL);
      glDepthMask(GL_TRUE);
    end;

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVertex) * PGL.DrawState.Params.VertexCount, @PGL.DrawState.Params.Vertices[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(0, 3, GL_FLOAT, GL_FALSE, SizeOf(TPGLVertex), 0);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(1, 4, GL_FLOAT, GL_FALSE, SizeOf(TPGLVertex), 12);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(GLInt) * PGL.DrawState.Params.VertexCount, @PGL.DrawState.Params.Index[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(2, 1, GL_INT, GL_FALSE, 0, 0);

    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(GLFloat) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Size[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(1);

    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLColorF) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.BorderColor[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(2);

    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(GLFloat) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.BorderWidth[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(3);

    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLVec4) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Center[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(4);

    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLMat4) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Translation[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(0);

    PGL.UseProgram('Circle');

    glUniformMatrix4fv(PGL.GetUniform('ProjMat'),1,GL_FALSE,@PGL.DrawState.Camera.ProjectionMatrix);
    glUniformMatrix4fv(PGL.GetUniform('ViewMat'),1,GL_FALSE,@PGL.DrawState.Camera.ViewMatrix);
    glMultiDrawArraysIndirect(GL_TRIANGLE_FAN, @PGL.DrawState.Params.ArrayIndirect[0], PGL.DrawState.Params.DrawCount, SizeOf(TPGLArrayIndirectBuffer));

    glDisable(GL_SCISSOR_TEST);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);

  end;


function TPGLRenderTarget.DrawCircle(ACenter: TPGLVec3; ARadius: GLFLoat; ABorderWidth: GLFloat; AColor: TPGLColorF; ABorderColor: TPGLColorF): TArray<TPGLVec3>;
var
CurDraw: GLInt;
CurVer: GLInt;
Ver: TArray<TPGLVec3>;
I: GLInt;
PointCount: GLInt;
UseAngle,AngleInc,AngleArc: Double;
  begin

    Self.MakeCurrentTarget();

    if (PGL.DrawState.State <> 'Circle') or (PGL.DrawState.Params.DrawCount >= 999) then begin
      Self.DrawLastBatch();
    end;

    PGL.DrawState.State := 'Circle';

    AngleArc := 2 * (Pi * ARadius);
    PointCount := trunc(AngleArc / 5) + 2;

    if PointCount < 10 then begin
      PointCount := 10;
    end;

    SetLength(Ver,PointCount);


    // if new points will overflow vertex array, draw last batch
    if PGL.DrawState.Params.VertexCount + PointCount > High(PGL.DrawState.Params.Vertices) then begin
      Self.DrawLastBatch();
    end;

    CurDraw := PGL.DrawState.Params.DrawCount;
    CurVer := PGL.DrawState.Params.VertexCount;

    Ver[0] := Vec3(0,0,0);

    UseAngle := 0;
    AngleInc := (Pi * 2) / (PointCount - 2);

    for I := 1 to PointCount - 1 do begin
      Ver[i].X := (ARadius * Cos(UseAngle));
      Ver[i].Y := (ARadius * Sin(UseAngle));
      Ver[i].Z := ACenter.Z;
      UseAngle := UseAngle + AngleInc;
    end;


    for I := 0 to PointCount - 1 do begin
      PGL.DrawState.Params.Vertices[CurVer + i].Vector := Ver[i];
      PGL.DrawState.Params.Vertices[CurVer + i].Color := AColor;
      PGL.DrawState.Params.Index[CurVer + i] := CurDraw;
    end;

    PGL.DrawState.Params.ArrayIndirect[CurDraw].Count := PointCount;
    PGL.DrawState.Params.ArrayIndirect[CurDraw].InstanceCount := 1;
    PGL.DrawState.Params.ArrayIndirect[CurDraw].First := CurVer;
    PGL.DrawState.Params.ArrayIndirect[CurDraw].BaseInstance := 0;

    PGL.DrawState.Params.Size[CurDraw] := ARadius;
    PGL.DrawState.Params.BorderWidth[CurDraw] := ABorderWidth;
    PGL.DrawState.Params.BorderColor[CurDraw] := ABorderColor;
    PGL.DrawState.Params.Center[CurDraw] := ACenter + Self.fDrawOffSet;

    PGL.DrawState.Params.Translation[CurDraw].MakeTranslation(ACenter + Self.fDrawOffSet);

    inc(PGL.DrawState.Params.DrawCount);
    inc(PGL.DrawState.Params.VertexCount, PointCount);

    for I := 0 to High(Ver) do begin
      Ver[i] := Ver[i] + ACenter;
    end;

    Result := Ver;

  end;


procedure TPGLRenderTarget.DrawRectangleBatch();
  begin

    if PGL.DrawState.Params.DrawCount = 0 then exit;
    if PGL.DrawState.State <> 'Rectangle' then exit;

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, PGL.DrawState.Buffers.ebo);

    glEnable(GL_SCISSOR_TEST);
    glScissor(0, 0, Self.Width, Self.Height);

    if PGL.DepthWrite then begin
      glEnable(GL_DEPTH_TEST);
      glDepthFunc(GL_LEQUAL);
      glDepthMask(GL_TRUE);
    end;

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVertex) * PGL.DrawState.Params.VertexCount, @PGL.DrawState.Params.Vertices[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(0, 3, GL_FLOAT, GL_FALSE, SizeOf(TPGLVertex), 0);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(1, 4, GL_FLOAT, GL_FALSE, SizeOf(TPGLVertex), 12);

    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLColorF) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.BorderColor[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(2);

    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(GLFloat) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.BorderWidth[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(3);

    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(GLFloat) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Width[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(4);

    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(GLFloat) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Height[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(5);

    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLVec4) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Center[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(6);

    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(GLFloat) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Size[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(7);


    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLMat4) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Translation[0]);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, PGL.DrawState.Buffers.CurrentSSBO.Buffer);

    PGL.UseProgram('Round Rectangle');

    glUniformMatrix4fv(PGL.GetUniform('ProjMat'),1,GL_FALSE,@PGL.DrawState.Camera.ProjectionMatrix);
    glUniformMatrix4fv(PGL.GetUniform('ViewMat'),1,GL_FALSE,@PGL.DrawState.Camera.ViewMatrix);
    glUniform4fv(PGL.GetUniform('TransparentColor'),1,@PGL.DrawState.TransparentColor);

    glMultiDrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_INT, @PGL.DrawState.Params.ElementIndirect[0], PGL.DrawState.Params.DrawCount, 0);

    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
  end;


procedure TPGLRenderTarget.DrawRectangle(ARect: TPGLRectF; AColor: Cardinal = 0; ABorderColor: Cardinal = 0; ABorderWidth: GLFloat = 0);
var
CurDraw: GLInt;
CurVer: GLInt;
Ver: TArray<TPGLVec3>;
I: GLInt;
  begin

    Self.MakeCurrentTarget();

    if (PGL.DrawState.State <> 'Rectangle') or (PGL.DrawState.Params.DrawCount >= 999) then begin
      Self.DrawLastBatch();
    end;

    PGL.DrawState.State := 'Rectangle';

    CurDraw := PGL.DrawState.Params.DrawCount;
    CurVer := PGL.DrawState.Params.VertexCount;

    PGL.DrawState.Params.ElementIndirect[CurDraw].Count := 6;
    PGL.DrawState.Params.ElementIndirect[CurDraw].InstanceCount := 1;
    PGL.DrawState.Params.ElementIndirect[CurDraw].First := 0;
    PGL.DrawState.Params.ElementIndirect[CurDraw].BaseVertex := CurVer;
    PGL.DrawState.Params.ElementIndirect[CurDraw].BaseInstance := 1;

    Ver := ARect.toVectors();

    for I := 0 to 3 do begin
      PGL.DrawState.Params.Vertices[CurVer + I].Vector := Ver[i] - ARect.Center;
      PGL.DrawState.Params.Vertices[CurVer + I].Color := AColor;
    end;

    PGL.DrawState.Params.BorderColor[CurDraw] := ABorderColor;
    PGL.DrawState.Params.BorderWidth[CurDraw] := ABorderWidth;
    PGL.DrawState.Params.Width[CurDraw] := ARect.Width;
    PGL.DrawState.Params.Height[CurDraw] := ARect.Height;
    PGL.DrawState.Params.Center[CurDraw] := ARect.Center + Self.DrawOffset;
    PGL.DrawState.Params.Size[CurDraw] := 0;

    PGL.DrawState.Params.Translation[CurDraw].MakeTranslation(ARect.Center + Self.fDrawOffset);

    Inc(PGL.DrawState.Params.DrawCount);
    Inc(PGL.DrawState.Params.VertexCount,4);
  end;

procedure TPGLRenderTarget.DrawRoundRectangle(ARect: TPGLRectF; AColor, ABorderColor: GLUint; ABorderWidth: GLFloat = 0; ACornerSize: GLFloat = 0);
  var
CurDraw: GLInt;
CurVer: GLInt;
Ver: TArray<TPGLVec3>;
I: GLInt;
  begin

    Self.MakeCurrentTarget();

    if (PGL.DrawState.State <> 'Rectangle') or (PGL.DrawState.Params.DrawCount >= 999) then begin
      Self.DrawLastBatch();
    end;

    PGL.DrawState.State := 'Rectangle';

    CurDraw := PGL.DrawState.Params.DrawCount;
    CurVer := PGL.DrawState.Params.VertexCount;

    PGL.DrawState.Params.ElementIndirect[CurDraw].Count := 6;
    PGL.DrawState.Params.ElementIndirect[CurDraw].InstanceCount := 1;
    PGL.DrawState.Params.ElementIndirect[CurDraw].First := 0;
    PGL.DrawState.Params.ElementIndirect[CurDraw].BaseVertex := CurVer;
    PGL.DrawState.Params.ElementIndirect[CurDraw].BaseInstance := 1;

    Ver := ARect.toVectors();

    for I := 0 to 3 do begin
      PGL.DrawState.Params.Vertices[CurVer + I].Vector := Ver[i] - Vec3(ARect.X, ARect.Y);
      PGL.DrawState.Params.Vertices[CurVer + I].Color := AColor;
    end;

    PGL.DrawState.Params.BorderColor[CurDraw] := ABorderColor;
    PGL.DrawState.Params.BorderWidth[CurDraw] := ABorderWidth;
    PGL.DrawState.Params.Width[CurDraw] := ARect.Width;
    PGL.DrawState.Params.Height[CurDraw] := ARect.Height;
    PGL.DrawState.Params.Center[CurDraw] := ARect.Center + Self.DrawOffset;
    PGL.DrawState.Params.Size[CurDraw] := ACornerSize;;

    PGL.DrawState.Params.Translation[CurDraw].MakeTranslation(ARect.Center + Self.fDrawOffset);

    Inc(PGL.DrawState.Params.DrawCount);
    Inc(PGL.DrawState.Params.VertexCount,4);
  end;

procedure TPGLRenderTarget.DrawTextureBatch();
var
TexCount: GLInt;
I: GLInt;
Values: Array [0..31] of GLInt;
  begin

    if PGL.DrawState.Params.DrawCount = 0 then exit;
    if PGL.DrawState.State <> 'Texture' then exit;

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, PGL.DrawState.Buffers.EBO);

    glEnable(GL_SCISSOR_TEST);
    glScissor(0, 0, Self.Width, Self.Height);

    if PGL.DepthWrite = True then begin
      glEnable(GL_DEPTH_TEST);
      glDepthMask(GL_TRUE);
      glDepthFunc(GL_LEQUAL);
    end;

    // bind the relevant textures
    TexCount := 0;
    for I := 0 to 31 do begin
      if PGL.DrawState.Params.TexSlot[i] <> 0 then begin
        PGL.BindTexture(I, PGL.DrawState.Params.TexSlot[i]);
        Values[i] := I;
        Inc(TexCount);
      end;
    end;

    // Vertex data, just Vector and TexCoord
    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVertex) * PGL.DrawState.Params.VertexCount, @PGL.DrawState.Params.Vertices[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(0, 3, GL_FLOAT, GL_FALSE, SizeOf(TPGLVertex), 0);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(1, 3, GL_FLOAT, GL_FALSE, SizeOf(TPGLVertex), 28);

    // Draw index of Vertices
    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(GLInt) * PGL.DrawState.Params.VertexCount, @PGL.DrawState.Params.Index[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(2, 1, GL_INT, GL_FALSE, 0, 0);

    // Draw translation matrices
    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLMat4) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Translation[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(0);

    // Draw texture using Index
    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(GLInt) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.TexUsing[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(1);

    PGL.UseProgram('Draw Texture');

    glUniform4fv(PGL.GetUniform('TransparentColor'),1,@PGL.DrawState.TransparentColor);
    glUniform1iv(PGL.GetUniform('tex'),TexCount,@Values[0]);
    glUniformMatrix4fv(PGL.GetUniform('ProjMat'),1,GL_FALSE,@PGL.DrawState.Camera.ProjectionMatrix);

    glMultiDrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_INT, @PGL.DrawState.Params.ElementIndirect[0], PGL.DrawState.Params.DrawCount, SizeOf(TPGLElementIndirectBuffer));

    for I := 0 to 31 do begin
      PGL.DrawState.Params.TexSlot[i] := 0;
    end;

    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
  end;


procedure TPGLRenderTarget.DrawTexture(ATexture: TPGLTexture; ASrcRect, ADestRect: TPGLRectF);
var
Ver: TArray<TPGLVec3>;
Coord: TArray<TPGLVec3>;
UseTex: GLInt;
I: GLUInt;
CurDraw, CurVer: GLUint;
  begin

    Self.MakeCurrentTarget();

    if (PGL.DrawState.State <> 'Texture') or (PGL.DrawState.Params.DrawCount >= 1000) then begin
      Self.DrawLastBatch();
    end;

    PGL.DrawState.State := 'Texture';

    // find and assign texture slot and texture using
    UseTex := -1;

    for I := 0 to 31 do begin
      if PGL.DrawState.Params.TexSlot[i] = 0 then begin
        PGL.DrawState.Params.TexSlot[i] := ATexture.fHandle;
        UseTex := I;
        break;
      end else if PGL.DrawState.Params.TexSlot[i] = ATexture.fHandle then begin
        UseTex := I;
        break;
      end;
    end;

    // if not slot is found, slots are full, draw the batch
    if UseTex = -1 then begin
      Self.DrawLastBatch();
      UseTex := 0;
      PGL.DrawState.Params.TexSlot[0] := ATexture.fHandle;
    end;

    // fill indirect buffer, vertices and tex coords
    CurDraw := PGL.DrawState.Params.DrawCount;
    CurVer := PGL.DrawState.Params.VertexCount;

    PGL.DrawState.Params.ElementIndirect[CurDraw].Count := 6;
    PGL.DrawState.Params.ElementIndirect[CurDraw].InstanceCount := 1;
    PGL.DrawState.Params.ElementIndirect[CurDraw].First := 0;
    PGL.DrawState.Params.ElementIndirect[CurDraw].BaseVertex := CurVer;
    PGL.DrawState.Params.ElementIndirect[CurDraw].BaseInstance := 1;

    PGL.DrawState.Params.TexUsing[CurDraw] := UseTex;

    Ver := ADestRect.toVectors;
    Coord := ASrcRect.toVectors;
    ScaleCoord(Coord,ATexture.Width, ATexture.Height, 1);
    FlipVerticle(Coord);

    for I := 0 to 3 do begin
      PGL.DrawState.Params.Vertices[CurVer + i].Vector := Ver[i] - Vec3(ADestRect.X, ADestRect.Y);
      PGL.DrawState.Params.Vertices[CurVer + i].TexCoord := Coord[i];
      PGL.DrawState.Params.Index[CurVer + i] := CurDraw;
    end;

    PGL.DrawState.Params.Translation[CurDraw].MakeTranslation(ADestRect.Center + Self.fDrawOffset);

    Inc(PGL.DrawState.Params.DrawCount);
    Inc(PGL.DrawState.Params.VertexCount,4);
  end;


procedure TPGLRenderTarget.DrawShapeBatch();
var
TexCount: GLint;
Values: Array of GLInt;
I: GLInt;
  begin

    if (PGL.DrawState.Params.DrawCount = 0) or (PGL.DrawState.State <> 'Shape') then Exit;

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, PGL.DrawState.Buffers.ShapeEBO);
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, SizeOf(GLInt) * PGL.DrawState.Params.ElementCount, @PGL.DrawState.Params.Elements[0]);

    glEnable(GL_SCISSOR_TEST);
    glScissor(0,0,Self.Width,Self.Height);

    if PGL.DepthWrite = True then begin
      glEnable(GL_DEPTH_TEST);
      glDepthMask(GL_TRUE);
      glDepthFunc(GL_LEQUAL);
    end;

    // bind textures in Params TexSlots
    TexCount := 0;
    for I := 0 to 31 do begin
      if PGL.DrawState.Params.TexSlot[i] <> 0 then begin
        glActiveTexture(GL_TEXTURE0 + I);
        glBindTexture(GL_TEXTURE_2D, PGL.DrawState.Params.TexSlot[i]);
        Inc(TexCount);
      end;
    end;

    setLength(Values,TexCount);
    for I := 0 to High(Values) do begin
      Values[i] := I;
    end;

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVertex) * PGL.DrawState.Params.VertexCount, @PGL.DrawState.Params.Vertices[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(0, 3, GL_FLOAT, GL_FALSE, SizeOf(TPGLVertex), 0);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(1, 4, GL_FLOAT, GL_FALSE, SizeOf(TPGLVertex), 12);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(2, 3, GL_FLOAT, GL_FALSE, SizeOf(TPGLVertex), 28);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(GLInt) * PGL.DrawState.Params.VertexCount, @PGL.DrawState.Params.Index[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(3, 1, GL_UNSIGNED_INT, GL_FALSE, 0, 0);

    // Draw translation matrices
    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLMat4) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Translation[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(0);

    // texture indices
    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(GLUint) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.TexUsing[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(1);

    PGL.UseProgram('Shape');
    glUniformMatrix4fv(PGL.GetUniform('ProjMat'),1,GL_FALSE,@PGL.DrawState.Camera.ProjectionMatrix);
    glUniformMatrix4fv(PGL.GetUniform('ViewMat'),1,GL_FALSE,@PGL.DrawState.Camera.ViewMatrix);
    glUniform1iv(PGL.GetUniform('tex'),texcount,@Values[0]);

    glMultiDrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_INT, @PGL.DrawState.Params.ElementIndirect[0], PGL.DrawState.Params.DrawCount, SizeOf(TPGLElementIndirectBuffer) );

  end;

procedure TPGLRenderTarget.DrawShape(var AShape: TPGLShape);
var
I: GLInt;
UseTex: GLInt;
CurDraw,CurVer, CurElement: GLInt;
ECount: GLInt;
E: TArray<GLInt>;
  begin

    Self.MakeCurrentTarget();

    if (PGL.DrawState.State <> 'Shape') or (PGL.DrawState.Params.DrawCount >= 1000) then begin
      Self.DrawLastBatch();
    end;

    PGL.DrawState.State := 'Shape';

    CurDraw := PGL.DrawState.Params.DrawCount;
    CurVer := PGL.DrawState.Params.VertexCount;
    CurElement := PGL.DrawState.Params.ElementCount;

    // handle texture
    // Assign a texture slot in the draw params
    UseTex := -1;

    // ignore if shape has no texture
    if AShape.fTexture <> nil then begin
      // loop through the tex slots to search for a match
      for I := 0 to High(PGL.DrawState.Params.TexSlot) do begin
        if PGL.DrawState.Params.TexSlot[i] = AShape.fTexture.fHandle then begin
          UseTex := I;
          break;
        end;
      end;

      // if no match is found, search for the next empty slot
      if UseTex = -1 then begin
        for I := 0 to high(PGL.DrawState.Params.TexSlot) do begin
          if PGL.DrawState.Params.TexSlot[i] = 0 then begin
            UseTex := I;
            PGL.DrawState.Params.TexSlot[i] := AShape.fTexture.fHandle;
            break;
          end;
        end;
      end;

    end;

    CurDraw := PGL.DrawState.Params.DrawCount;
    CurVer := PGL.DrawState.Params.VertexCount;

    PGL.DrawState.Params.TexUsing[CurDraw] := UseTex;

    // handle verticies and elements
    E := AShape.GetElements();

    if PGL.DrawState.Params.ElementCount + Length(E) > High(PGL.DrawState.Params.Elements) then begin
      Self.DrawShapeBatch();
      CurDraw := 0;
      CurVer := 0;
      CurElement := 0;
    end;

    for I := 0 to High(E) do begin
      PGL.DrawState.Params.Elements[CurElement + I] := E[I];
    end;

    PGL.DrawState.Params.ElementIndirect[CurDraw].Count := Length(E);
    PGL.DrawState.Params.ElementIndirect[CurDraw].InstanceCount := 1;
    PGL.DrawState.Params.ElementIndirect[CurDraw].First := 0;
    PGL.DrawState.Params.ElementIndirect[CurDraw].BaseVertex := CurVer;
    PGL.DrawState.Params.ElementIndirect[CurDraw].BaseInstance := 1;

    for I := 0 to High(AShape.Vertex) do begin
      PGL.DrawState.Params.Vertices[CurVer + I] := AShape.Vertex[i];
      PGL.DrawState.Params.Vertices[CurVer + I].Vector.Translate(-AShape.fCenter);
      PGL.DrawState.Params.Vertices[CurVer + I].Color := AShape.Vertex[i].Color;
      PGL.DrawState.Params.Index[CurVer + I] := CurDraw;
    end;

    PGL.DrawState.Params.Translation[CurDraw].MakeTranslation(AShape.fCenter + Self.fDrawOffSet);

    Inc(PGL.DrawState.Params.DrawCount);
    Inc(PGL.DrawState.Params.VertexCount, AShape.fPointCount);
    Inc(PGL.DrawState.Params.ElementCount, Length(E));

  end;


procedure TPGLRenderTarget.DrawLineBatch();
  begin

    if PGL.DrawState.Params.DrawCount = 0 then exit;
    if PGL.DrawState.State <> 'Line' then exit;

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, PGL.DrawState.Buffers.EBO);

    glEnable(GL_SCISSOR_TEST);
    glScissor(0,0,Self.Width,Self.Height);

    if PGL.DepthWrite = True then begin
      glEnable(GL_DEPTH_TEST);
      glDepthMask(GL_TRUE);
      glDepthFunc(GL_LEQUAL);
    end else begin
      glDisable(GL_DEPTH_TEST);
      glDepthMask(GL_FALSE);
    end;

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVertex) * PGL.DrawState.Params.VertexCount, @PGL.DrawState.Params.Vertices[0]);

    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(0,3,GL_FLOAT,GL_FALSE,SizeOf(TPGLVertex),0);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(1,4,GL_FLOAT,GL_FALSE,SizeOf(TPGLVertex),12);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(GLInt) * PGL.DrawState.Params.VertexCount, @PGL.DrawState.Params.Index[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(2, 1, GL_UNSIGNED_INT, GL_FALSE, 0, 0);

    // Draw translation matrices
    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLMat4) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Translation[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(0);

    PGL.UseProgram('Shape');

    glUniformMatrix4fv(PGL.GetUniform('ProjMat'),1,GL_FALSE,@PGL.DrawState.Camera.ProjectionMatrix);
    glMultiDrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_INT, @PGL.DrawState.Params.ElementIndirect[0], PGL.DrawState.Params.DrawCount, SizeOf(TPGLElementIndirectBuffer) );
  end;


procedure TPGLRenderTarget.DrawLine(AStart,AEnd: TPGLVec3; AWidth: GLFloat; AColor: TPGLColorF);
var
CurDraw,CurVer: GLInt;
UseAngle: GLFloat;
LineLength: GLFloat;
Center: TPGLVec3;
Ver: TArray<TPGLVec3>;
I: GLInt;
  begin

    Self.MakeCurrentTarget();

    if (PGL.DrawState.State <> 'Line') or (PGL.DrawState.Params.DrawCount >= 1000) then begin
      Self.DrawLastBatch();
    end;

    PGL.DrawState.State := 'Line';

    CurDraw := PGL.DrawState.Params.DrawCount;
    CurVer := PGL.DrawState.Params.VertexCount;

    UseAngle := ArcTan2(AEnd.Y - AStart.Y, AEnd.X - AStart.X);
    LineLength := Distance(AStart.X, AStart.Y, AEnd.X, AEnd.Y);
    Center.X := AStart.X + ((LineLength / 2) * Cos(UseAngle));
    Center.Y := AStart.Y + ((LineLength / 2) * Sin(UseAngle));
    SetLength(Ver,4);

    PGL.DrawState.Params.ElementIndirect[CurDraw].Count := 6;
    PGL.DrawState.Params.ElementIndirect[CurDraw].InstanceCount := 1;
    PGL.DrawState.Params.ElementIndirect[CurDraw].First := 0;
    PGL.DrawState.Params.ElementIndirect[CurDraw].BaseVertex := CurVer;
    PGL.DrawState.Params.ElementIndirect[CurDraw].BaseInstance := 0;

    Ver[0].X := AStart.X - ((AWidth / 2) * Cos(UseAngle + (Pi / 2)));
    Ver[0].Y := AStart.Y - ((AWidth / 2) * Sin(UseAngle + (Pi / 2)));

    Ver[1].X := AStart.X + ((AWidth / 2) * Cos(UseAngle + (Pi / 2)));
    Ver[1].Y := AStart.Y + ((AWidth / 2) * Sin(UseAngle + (Pi / 2)));

    Ver[2].X := AEnd.X + ((AWidth / 2) * Cos(UseAngle + (Pi / 2)));
    Ver[2].Y := AEnd.Y + ((AWidth / 2) * Sin(UseAngle + (Pi / 2)));

    Ver[3].X := AEnd.X - ((AWidth / 2) * Cos(UseAngle + (Pi / 2)));
    Ver[3].Y := AEnd.Y - ((AWidth / 2) * Sin(UseAngle + (Pi / 2)));

    for I := 0 to 3 do begin
      PGL.DrawState.Params.Vertices[CurVer + I].Vector := Ver[I] - Center;
      PGL.DrawState.Params.Vertices[CurVer + I].Color := AColor;
      PGL.DrawState.Params.Index[CurVer + I] := CurDraw;
    end;

    PGL.DrawState.Params.Translation[CurDraw].MakeTranslation(Center + Self.fDrawOffset);
    PGL.DrawState.Params.Rotation[CurDraw].SetIdentity;

    Inc(PGL.DrawState.Params.DrawCount);
    Inc(PGL.DrawState.Params.VertexCount,4);

  end;


procedure TPGLRenderTarget.DrawText(AText: String; AFont: TPGLFont; ASize: GLFLoat; Position: TPGLVec3; AColor, ABackColor: TPGLColorF);
var
I,R: GLInt;
CharNum: GLInt;
CurChar: ^TPGLCharacter;
CurAtlas: TPGLAtlas;
TextWidth,TextHeight: GLInt;
CurPos: TPGLVec2;
SourceRect, DestRect: TPGLRectF;
Breaks: Tarray<GLInt>;
CurVer,CurDraw: GLInt;
Ver,Coord: TArray<TPGLVec3>;
Adj: GLFloat;
CopyBounds: TPGLRectF;
CopyLeft,CopyRight,CopyTop,CopyBottom: GLFloat;
  begin

    if Assigned(AFont) = False then begin

      {$IFDEF PGL_VERBOSE_DEBUG_OUTPUT}
        CreateDebugMessage('Attempted to call TPGLRenderTarget.DrawText() with an uninitialized TPGLFont object!');
      {$ENDIF}

      Exit;

    end;

    Self.MakeCurrentTarget();
    Self.DrawLastBatch();

    CopyBounds.SetSize(0,0);
    CopyBounds.SetCenter(Self.RenderRect.Center);
    CopyLeft := 0;
    CopyRight := 0;
    CopyTop := 0;
    CopyBottom := 0;

    CurAtlas := AFont.SelectAtlas(trunc(ASize));

    CurPos := Position;
    Adj := ASize / CurAtlas.PointSize;
    Breaks := pglFindSubString(AText, sLineBreak);

    // prepare draw parameters per character

    for I := 1 to Length(AText) do begin

      CharNum := Ord(AText[i]);

      for R := 0 to High(Breaks) do begin
        if I = Breaks[R] then begin
          CurPos.X := Position.X;
          CurPos.Y := CurPos.Y + (CurAtlas.Height * Adj);
        end;
      end;

      if (CharNum < 32) or (CharNum > 128) then continue;

      CurVer := PGL.DrawState.Params.VertexCount;
      CurDraw := PGL.DrawState.Params.DrawCount;

      CharNum := Ord(AText[i]);
      CurChar := @CurAtlas.fCharacter[CharNum];

      DestRect := RectFWH(CurPos.X, CurPos.Y, CurChar.Bounds.Width * Adj, Curchar.Bounds.Height * Adj);
      SourceRect := CurChar.Bounds;

      if RectCollision(DestRect + Self.DrawOffSet, Self.TextParams.ClipBounds) then begin

        Ver := DestRect.toVectors();
        Coord := SourceRect.toVectors();
        ScaleCoord(Coord,CurAtlas.Width,CurAtlas.Height,1);

        PGL.DrawState.Params.ElementIndirect[CurDraw].Count := 6;
        PGL.DrawState.Params.ElementIndirect[CurDraw].InstanceCount := 1;
        PGL.DrawState.Params.ElementIndirect[CurDraw].First := 0;
        PGL.DrawState.Params.ElementIndirect[CurDraw].BaseVertex := CurVer;
        PGL.DrawState.Params.ElementIndirect[CurDraw].BaseInstance := 1;

        for R := 0 to 3 do begin
          PGL.DrawState.Params.Vertices[CurVer + R].Vector := Ver[R] - DestRect.Center;
          PGL.DrawState.Params.Vertices[CurVer + R].Color := Acolor;
          PGL.DrawState.Params.Vertices[CurVer + R].TexCoord := Coord[R];
        end;

        PGL.DrawState.Params.Translation[CurDraw].MakeTranslation(DestRect.Center + Self.DrawOffSet);
        PGL.DrawState.Params.Rotation[CurDraw].SetIdentity();

        Inc(PGL.DrawState.Params.DrawCount);
        Inc(PGL.DrawState.Params.VertexCount, 4);

        if I = 1 then begin
          CopyLeft := DestRect.Left;
          CopyRight := DestRect.Right;
          CopyTop := DestRect.Top;
          CopyBottom := DestRect.Bottom;
        end else begin
          CopyLeft := Smallest([CopyLeft,DestRect.Left]);
          CopyRight := Biggest([CopyRight,DestRect.Right]);
          CopyTop := Smallest([CopyTop,DestRect.Top]);
          CopyBottom := Biggest([CopyBottom,DestRect.Bottom]);
        end;

      end;

      CurPos.X := CurPos.X + (CurChar.Advance * Adj);

      if (PGL.DrawState.Params.DrawCount = 1000) or (I = Length(AText)) then begin
        Self.DrawChars(CurAtlas, ABackColor);
        CopyBounds := PGLTypes.RectF(CopyLeft,CopyTop,CopyRight,CopyBottom);
        Self.TextParams.LastTextBounds := CopyBounds;
      end;

    end;
  end;

procedure TPGLRenderTarget.DrawText(AText: TPGLText);
var
I: GLInt;
DrawLeft, DrawTop: GLFloat;
Adj: GLFloat;
  begin

    if Assigned(AText) = False then Exit;

    if Length(AText.fTextLines) = 0 then Exit;

    if AText.fBoundsLocked then begin
      Self.TextParams.ClipBounds := AText.Bounds;
    end;

    DrawTop := AText.Bounds.Top - AText.fLockYOffSet;

    for I := 0 to High(AText.fTextLines) do begin

      if AText.Centered = false then begin
        DrawLeft := AText.Bounds.Left;
        Self.DrawText(AText.fTextLines[I], AText.Font, AText.PointSize, Vec2(DrawLeft, DrawTop), AText.TextColor, AText.BackColor);
      end else begin
        DrawLeft := AText.Bounds.X - (AText.fLineWidths[I] / 2);
        Self.DrawText(AText.fTextLines[I], AText.Font, AText.PointSize, Vec2(DrawLeft, DrawTop), AText.TextColor, AText.BackColor);
      end;

      Adj := AText.fPointSize / AText.fAtlasUsing.PointSize;
      IncF(DrawTop, AText.fAtlasUsing.Height * Adj);
    end;

    Self.TextParams.ClipBounds := Self.fRenderRect;
  end;


procedure TPGLRenderTarget.DrawChars(AAtlas: TPGLAtlas; ABackColor: TPGLColorF);
  begin
    // draw it
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, PGL.DrawState.Buffers.EBO);

    glEnable(GL_SCISSOR_TEST);
    glScissor(trunc(Self.TextParams.ClipBounds.Left),
              Self.Height - trunc(Self.TextParams.ClipBounds.Height) - trunc(Self.TextParams.ClipBounds.Top),
              trunc(Self.TextParams.ClipBounds.Width),
              trunc(Self.TextParams.ClipBounds.Height));

    if PGL.DepthWrite = True then begin
      glEnable(GL_DEPTH_TEST);
      glDepthMask(GL_TRUE);
      glDepthFunc(GL_LEQUAL);
    end;

    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);

    PGL.BindTexture(0,AAtlas.Texture.fHandle);
    glBindSampler(0,0);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVertex) * PGL.DrawState.Params.VertexCount, @PGL.DrawState.Params.Vertices[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(0,3,GL_FLOAT,GL_FALSE,SizeOf(TPGLVertex),0);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(1,4,GL_FLOAT,GL_FALSE,SizeOf(TPGLVertex),12);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(2,3,GL_FLOAT,GL_FALSE,SizeOf(TPGLVertex),28);

    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLMat4) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Translation[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(4);

    PGL.UseProgram('Text');

    glUniform1i(PGL.GetUniform('tex'),0);
    glUniform1ui(PGL.GetUniform('GlyphType'),AAtlas.GlyphType);
    glUniformMatrix4fv(PGL.GetUniform('ProjMat'), 1, GL_FALSE, @PGL.DrawState.Camera.ProjectionMatrix);
    glMultiDrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_INT, @PGL.DrawState.Params.ElementIndirect[0], PGL.DrawState.Params.DrawCount, SizeOf(TPGLElementIndirectBuffer) );

    glDisable(GL_SCISSOR_TEST);

    PGL.DrawState.Buffers.Reset();
    PGL.DrawState.Params.DrawCount := 0;
    PGL.DrawState.Params.VertexCount := 0;
    PGL.DrawState.Params.ElementCount := 0;

    glBindSampler(0,PGL.fSampler);
  end;


procedure TPGLRenderTarget.DrawLightBatch();
var
ARect: TPGLRectI;
Buffs: Array [0..1] of GLEnum;
DW,DH: GLInt;
  begin

    if PGL.DrawState.Params.DrawCount = 0 then exit;
    if PGL.DrawState.State <> 'Point Light' then exit;

//    glDisable(GL_BLEND);

    glDisable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glDepthMask(GL_FALSE);

    glEnable(GL_SCISSOR_TEST);
    glScissor(0,0,Self.Width,Self.Height);

//    Buffs[0] := GL_COLOR_ATTACHMENT0;
//    Buffs[1] := GL_DEPTH_ATTACHMENT;
//    glDrawBuffers(2,@Buffs);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, PGL.DrawState.Buffers.EBO);

    PGL.BindTexture(0, Self.fTexture2d);

    if PGL.fLightReferenceBuffer <> nil then begin
      PGL.BindTexture(1, PGL.fLightReferenceBuffer.fDepthBuffer);
    end;

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVertex) * PGL.DrawState.Params.VertexCount, @PGL.DrawState.Params.Vertices[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(0,3,GL_FLOAT,GL_FALSE,SizeOf(TPGLVertex),0);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(1,4,GL_FLOAT,GL_FALSE,SizeOf(TPGLVertex),12);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(2,3,GL_FLOAT,GL_FALSE,SizeOf(TPGLVertex),28);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(GLInt) * PGL.DrawState.Params.VertexCount, @PGL.DrawState.Params.Index[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(3, 1, GL_INT, GL_FALSE, 0, 0);

    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLVec4) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Center[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(1);

    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLLightParams) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.LightInfo[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(2);

    PGL.DrawState.Buffers.SelectNextSSBO();
    PGL.DrawState.Buffers.CurrentSSBO.SubData(SizeOf(TPGLMat4) * PGL.DrawState.Params.DrawCount, @PGL.DrawState.Params.Translation[0]);
    PGL.DrawState.Buffers.CurrentSSBO.BindToBase(0);

    PGL.UseProgram('Point Light');

    glUniform1i(PGL.GetUniform('tex'), 0);
    glUniform1i(PGL.GetUniform('depthtex'), 1);
    glUniformMatrix4fv(PGL.GetUniform('ProjMat'),1,GL_FALSE,@PGL.DrawState.Camera.ProjectionMatrix);

    glMultiDrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_INT, @PGL.DrawState.Params.ElementIndirect[0], PGL.DrawState.Params.DrawCount, SizeOf(TPGLElementIndirectBuffer) );

    glDisable(GL_SCISSOR_TEST);

    if PGL.AlphaChannel = True then begin
      glEnable(GL_BLEND);
    end;

  end;


procedure TPGLRenderTarget.DrawPointLight(ACenter: TPGLVec3; ARadius: GLFloat; AThreshold: GLFloat = 0; AColor: Cardinal = $FFFFFFFF; AGlobalLight: GLFloat = 1);
var
CurDraw,CurVer: GLInt;
Ver,Coord: TArray<TPGLVec3>;
DrawRect: TPGLRectF;
I: GLInt;
  begin

    Self.MakeCurrentTarget();

    if (PGL.DrawState.State <> 'Point Light') or (PGL.DrawState.Params.DrawCount = 1000) then begin
      Self.DrawLastBatch();
    end;

    PGL.DrawState.State := 'Point Light';

    CurDraw := PGL.DrawState.Params.DrawCount;
    CurVer := PGL.DrawState.Params.VertexCount;

    PGL.DrawState.Params.ElementIndirect[CurDraw].Count := 6;
    PGL.DrawState.Params.ElementIndirect[CurDraw].InstanceCount := 1;
    PGL.DrawState.Params.ElementIndirect[CurDraw].First := 0;
    PGL.DrawState.Params.ElementIndirect[CurDraw].BaseVertex := CurVer;
    PGL.DrawState.Params.ElementIndirect[CurDraw].BaseInstance := 0;

    PGL.DrawState.Params.Center[CurDraw] := ACenter + Self.DrawOffset;
    PGL.DrawState.Params.LightInfo[CurDraw].Radius := ARadius;
    PGL.DrawState.Params.LightInfo[CurDraw].GlobalLight := AThreshold;

    DrawRect := RectF(Vec3(0,0,0),ARadius * 2, ARadius * 2);
    Ver := DrawRect.toVectors();
    DrawRect := RectF(ACenter + Self.DrawOffset,ARadius * 2, ARadius * 2);
    SetLength(Coord, 4);
    Coord[0] := Vec2(DrawRect.Left / Self.Width, DrawRect.Top / Self.Height);
    Coord[1] := Vec2(DrawRect.Right / Self.Width, DrawRect.Top / Self.Height);
    Coord[2] := Vec2(DrawRect.Right / Self.Width, DrawRect.Bottom / Self.Height);
    Coord[3] := Vec2(DrawREct.Left / Self.Width, DrawRect.Bottom / Self.Height);

    for I := 0 to 3 do begin
      PGL.DrawState.Params.Vertices[CurVer + I].Vector := Ver[i];
      PGL.DrawState.Params.Vertices[CurVer + I].Color := AColor;
      PGL.DrawState.Params.Vertices[CurVer + I].TexCoord := Coord[i];
      PGL.DrawState.Params.Index[CurVer + I] := CurDraw;
    end;

    PGL.DrawState.Params.Translation[curDraw].MakeTranslation(ACenter + Self.DrawOffset);

    Inc(PGL.DrawState.Params.DrawCount);
    Inc(PGL.DrawState.Params.VertexCount, 4);

  end;


procedure TPGLRenderTarget.SaveToFile(AFileName: string);
var
Data: TArray<Byte>;
W,H: GLInt;
  begin

    Self.DrawLastBatch();

    PGL.BindTexture(0,Self.fTexture2D);

    glGetTexLevelParameterIV(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, @W);
    glGetTexLevelParameterIV(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, @H);

    SetLength(Data, (W * H) * 4);

    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, @Data[0]);

    stbi_write_bmp(PAnsiChar(AnsiString(AFileName)),W ,H, 4, @Data[0]);
  end;

procedure TPGLRenderTarget.SaveDepthToFile(AFileName: String);
var
Data: TArray<Byte>;
Avg: Byte;
W,H: GLInt;
I: GLInt;
  begin

    Self.DrawLastBatch();

    SetLength(Data, (Self.Width * Self.Height) * 4);

    PGL.BindTexture(0, Self.fDepthBuffer);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, GL_FLOAT, @Data[0]);

    stbi_write_bmp(PAnsiChar(AnsiString(AFileName)),Self.Width, Self.Height, 4, @Data[0]);
  end;


procedure TPGLRenderTarget.SaveNormalToFile(AFileName: String);
var
Data: TArray<Byte>;
W,H: GLInt;
  begin

    PGL.BindTexture(0,Self.fNormalMap);

    glGetTexLevelParameterIV(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, @W);
    glGetTexLevelParameterIV(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, @H);

    SetLength(Data, (W * H) * 4);

    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, @Data[0]);

    stbi_write_bmp(PAnsiChar(AnsiString(AFileName)),W ,H, 4, @Data[0]);
  end;


procedure TPGLRenderTarget.GetDepthData(var [ref] ADestPtr: Pointer);
  begin
    ADestPtr := GetMemory((Self.Width * Self.Height) * 4);

    PGL.BindTexture(0,Self.fDepthBuffer);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, GL_FLOAT, ADestPtr);
    PGL.BindTexture(0,0);
  end;


procedure TPGLRenderTarget.AttachDepthBuffer(AAttach: Boolean = True);
  begin
    if AAttach = Self.fDepthAttach then exit;

    Self.MakeCurrentTarget();

    if AAttach = true then begin
      glFrameBufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, Self.fDepthBuffer, 0);
    end else begin
      glFrameBufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, 0, 0);
    end;
  end;


procedure TPGLRenderTarget.AttachTexture(var ATexture: TPGLTexture);
  begin

    if Assigned(Self.fAttachment) then begin
      Self.fAttachment.fAttachedToTarget := False;
      Self.fAttachment.fTarget := Nil;
    end;

    ATexture.fAttachedToTarget := True;

    Self.fTexture2D := ATexture.fHandle;
    Self.fAttachment := ATexture;

    Self.fWidth := ATexture.Width;
    Self.fHeight := ATexture.Height;

    Self.MakeCurrentTarget();

    glFramebufferParameteri(GL_FRAMEBUFFER, GL_FRAMEBUFFER_DEFAULT_WIDTH, ATexture.Width);
    glFramebufferParameteri(GL_FRAMEBUFFER, GL_FRAMEBUFFER_DEFAULT_HEIGHT, ATexture.Height);

    glFrameBufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, ATexture.fHandle, 0);

    Self.fRenderRect := RectIWH(0,0,Self.Width,Self.Height);

    Self.MakeCurrentTarget();
  end;

procedure TPGLRenderTarget.RestoreTexture();
var
W,H: GLInt;
  begin
    if Assigned(Self.fAttachment) = False then exit;

    Self.DrawLastBatch();

    Self.fAttachment.fAttachedToTarget := False;
    Self.fAttachment.fTarget := nil;
    Self.fAttachment := nil;

    Self.fTexture2D := Self.fOwnedTexture;
    PGL.BindTexture(0,Self.fOwnedTexture);
    glGetTexLevelParameterIV(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, @W);
    glGetTexLevelParameterIV(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, @H);

    Self.fWidth := W;
    Self.fHeight := H;

    glFrameBufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, Self.fOwnedTexture, 0);

    glFramebufferParameteri(GL_FRAMEBUFFER, GL_FRAMEBUFFER_DEFAULT_WIDTH, Self.Width);
    glFramebufferParameteri(GL_FRAMEBUFFER, GL_FRAMEBUFFER_DEFAULT_Height, Self.Height);

    glDrawBuffer(GL_COLOR_ATTACHMENT0);

    Self.fRenderRect := RectIWH(0,0,Self.Width,Self.Height);
  end;


procedure TPGLRenderTarget.CopyFromTexture(var ASource: TPGLTexture; ASourceRect: TPGLRectI; ADestX, ADestY: GLInt);
  begin
    glCopyImageSubData(ASource.fHandle, GL_TEXTURE_2D, 0, ASourceRect.Left, ASourceRect.Top, 0, Self.fTexture2D, GL_TEXTURE_2D, 0,
      ADestX, ADestY, 0, ASourceRect.Width, ASourceRect.Height, 1);
  end;

procedure TPGLRenderTarget.CopyFromData(AData: Pointer; ADataWidth, ADataHeight: GLInt; ADestRect, ASourceRect: TPGLRectI);
var
Ptr: PByte;
DataPos, BytePos: GLInt;
DataX, DataY, ByteX, ByteY: GLFloat;
Bytes: TArray<Byte>;
DataStepX,DataStepY,ByteStepX,ByteStepY: GLFloat;
UseDataWidth, UseDataHeight: GLInt;
ForWidth,ForHeight: GLInt;
I,Z: GLInt;
  begin

    Ptr := AData;
    DataPos := 0;
    DataX := ASourceRect.Left;
    DataY := ASourceRect.Top;

    SetLength(Bytes, (ADestRect.Width * ADestRect.Height) * 4);

    // decide to use the data or the target width and height for the loops
    ForWidth := ADestRect.Width - 1;
    ForHeight := ADestRect.Height - 1;

    DataStepX := ASourceRect.Width / ADestRect.Width;
    DataStepY := ASourceRect.Height / ADestRect.Height;
    ByteStepX := ADestRect.Width / ASourceRect.Width;
    ByteStepY := ADestRect.Height / ASourceRect.Height;


    for Z := 0 to ForHeight do begin
      for I := 0 to ForWidth do begin

        DataX := ASourceRect.Left + (DataStepX * I);
        DataY := ASourceRect.Top + (DataStepY * Z);
        DataPos := ((trunc(DataY) * ADataWidth) + trunc(DataX)) * 4;

        BytePos := ((Z * ADestRect.Width) + I) * 4;
        Move(Ptr[DataPos], Bytes[BytePos], 4);

      end;
    end;

    PGL.BindTexture(0, Self.fTexture2D);
    glTexSubImage2D(GL_TEXTURE_2D, 0, ADestRect.Left, ADestRect.Top, ADestRect.Width, ADestRect.Height, GL_RGBA,
      GL_UNSIGNED_BYTE, @Bytes[0]);

  end;

procedure TPGLRenderTarget.CopyToTarget(ATarget: TPGLRenderTarget; ASourceRect: TPGLRectI; ADestRect: TPGLRectI);
var
Ver,Coord: TArray<TPGLVec3>;
ReturnBlend: GLInt;
  begin

    Self.MakeCurrentTarget();

    // do on GPU texture to texture copy if rects are the same size
    if (ASourceRect.Width = ADestRect.Width) and (ASourceRect.Height = ADestRect.Height) then begin

      glCopyImageSubData(Self.fTexture2D, GL_TEXTURE_2D, 0, ASourceRect.Left, Self.Height - ASourceRect.Top - ASourceRect.Height, 0,
        ATarget.fTexture2D, GL_TEXTURE_2D, 0, ADestRect.Left, ADestRect.Top, 0, ASourceRect.Width, ASourceRect.Height, 1);

      exit;
    end;


    // Cache the enabled state of glBlend and then turn off
    glGetIntegerV(GL_BLEND, @ReturnBlend);
    glDisable(GL_BLEND);

    // make sure depth testing is turned off
    glDisable(GL_DEPTH_TEST);

    Ver := ADestRect.toVectors();
    ScaleNDC(Ver,ATarget.Width,ATarget.Height);

    Coord := ASourceRect.toVectors();
    ScaleCoord(Coord,Self.Width,Self.Height);

    ATarget.MakeCurrentTarget();
    glBindVertexArray(PGL.DrawState.Buffers.VAO);

    PGL.BindTexture(0, Self.fTexture2D);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVec3) * 4, @Ver[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVec3) * 4, @Coord[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, 0);

    PGL.UseProgram('CopyBlt');

    glUniform1i(PGL.GetUniform('SourceTex'),0);

    glDrawArrays(GL_QUADS, 0, 4);

    PGL.DrawState.Buffers.Reset();

    // return blending to it's original state
    if ReturnBlend = 1 then begin
      glEnable(GL_BLEND);
    end;

  end;


procedure TPGLRenderTarget.Blit(ATarget: TPGLRenderTarget; ASourceRect, ADestRect: TPGLRectI; ABlitMode: PPGLBlitMode = nil);
var
SourceVer: TArray<TPGLVec3>;
DestVer: TArray<TPGLVec3>;
Coord: TArray<TPGLVec3>;
BlitMode: PPGLBlitMode;
  begin

    if ABlitMode <> nil then begin
      BlitMode := ABlitMode;
    end else begin
      pglBlitMode(pgl_blend, pgl_no_copy_depth);
      BlitMode := @PGL.BlitMode;
    end;

    Self.MakeCurrentTarget();
    Self.DrawLastBatch();

    glDisable(GL_SCISSOR_TEST);

    if BlitMode.BlendMode = pgl_overwrite then begin
      glEnable(GL_DEPTH_TEST);
      glDepthFunc(GL_ALWAYS);
      glDepthMask(GL_FALSE);
    end else begin
      glEnable(GL_DEPTH_TEST);
      glDepthFunc(GL_LEQUAL);
      glDepthMask(GL_TRUE);
    end;



    SourceVer := ASourceRect.toVectors();

    DestVer := ADestRect.toVectors();

    ASourceRect.SetTop(Self.Height - ASourceRect.Top - ASourceRect.Height);

    SetLength(Coord,4);
    Coord[0] := Vec2(ASourceRect.Left / Self.Width, ASourceRect.Bottom / Self.Height);
    Coord[1] := Vec2(ASourceRect.Right / Self.Width, ASourceRect.Bottom / Self.Height);
    Coord[2] := Vec2(ASourceRect.Right / Self.Width, ASourceRect.Top / Self.Height);
    Coord[3] := Vec2(ASourceRect.Left / Self.Width, ASourceRect.Top / Self.Height);

    ATarget.MakeCurrentTarget();

    PGL.BindTexture(0, Self.fTexture2D);
    PGL.BindTexture(1, ATarget.fTexture2D);
    PGL.BindTexture(2, Self.fDepthBuffer);

    if BlitMode.DepthMode = TPGLBlitDepth.pgl_copy_depth then begin
      PGL.BindTexture(3, ATarget.fDepthBuffer);
    end;

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVec3) * 4, @SourceVer[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVec3) * 4, @DestVer[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, 0);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVec3) * 4, @Coord[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(2, 3, GL_FLOAT, GL_FALSE, 0, 0);

    PGL.UseProgram('Blit');

    glUniform1i(PGL.GetUniform('SourceTex'),0);
    glUniform1i(PGL.GetUniform('DestTex'),1);
    glUniform1i(PGL.GetUniform('SourceDepth'),2);

    if BlitMode.DepthMode = pgl_copy_depth then begin
      glUniform1i(PGL.GetUniform('DestDepth'),3);
    end;

    glUniform1ui(PGL.GetUniform('BlendMode'), Ord(BlitMode.BlendMode));
    glUniform1ui(PGL.GetUniform('DepthMode'), Ord(BlitMode.DepthMode));

    glUniformMatrix4fv(PGL.GetUniform('ProjMat'),1,GL_FALSE,@PGL.DrawState.Camera.ProjectionMatrix);

    glDrawArrays(GL_QUADS, 0, 4);

    PGL.DrawState.Buffers.Reset();
    PGL.UnbindAllTextures();

  end;

procedure TPGLRenderTarget.Pixelate(APixelSize: GLUInt = 2);
var
Ver: TArray<TPGLVec3>;
Coord: TArray<TPGLVec3>;
  begin

    Self.DrawLastBatch();

    if APixelSize < 2 then exit;

    Ver := RectI(-1,-1,1,1).toVectors;
    Coord := RectI(0,0,1,1).toVectors;

    Self.MakeCurrentTarget();
    glBindVertexArray(PGL.DrawState.Buffers.VAO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, PGL.DrawState.Buffers.EBO);

    PGL.BindTexture(0,Self.fTexture2D);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVec3) * 4, @Ver[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(0,3,GL_FLOAT,GL_FALSE,0,0);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVec3) * 4, @Coord[0]);
    PGL.DrawState.Buffers.CurrentVBO.SetAttribPointer(1,3,GL_FLOAT,GL_FALSE,0,0);

    PGL.UseProgram('Pixelate Target');

    glUniform1i(PGL.GetUniform('tex'),0);
    glUniform1ui(PGL.GetUniform('PixelSize'),APixelSize);

    glDrawElements(GL_TRIANGLES,6,GL_UNSIGNED_INT,nil);

    PGL.DrawState.Buffers.Reset();
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                TPGLRenderTexture
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


constructor TPGLRenderTexture.Create(AWidth: Integer; AHeight: Integer);
  begin
    inherited Create(AWidth,AHeight);
    Self.CreateFBO(AWidth,AHeight);
  end;

Destructor TPGLRenderTexture.Destroy();
  begin
    inherited Destroy();
  end;

procedure TPGLRenderTexture.Free();
  begin
    inherited Free();
  end;

procedure TPGLRenderTexture.SetSize(AWidth,AHeight: GLUInt);
var
CheckVar: GLEnum;
Buff: GLEnum;
  begin

    Self.MakeCurrentTarget();
    Self.fWidth := AWidth;
    Self.fHeight := AHeight;
    Self.fRenderRect := RectIWH(0,0,Self.Width,Self.Height);

    PGL.BindTexture(0,Self.fTexture2D);
    glInvalidateTexSubImage(Self.fTexture2D, 0, 0, 0, 0, Self.Width, Self.Height, 1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, AWidth, AHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);

    PGL.BindTexture(0,Self.fBackTexture2D);
    glInvalidateTexSubImage(Self.fBackTexture2D, 0, 0, 0, 0, Self.Width, Self.Height, 1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, AWidth, AHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);

    PGL.BindTexture(0,Self.fDepthBuffer);
    glInvalidateTexSubImage(Self.fDepthBuffer, 0, 0, 0, 0, Self.Width, Self.Height, 1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32, AWidth, AHeight, 0, GL_DEPTH_COMPONENT, GL_FLOAT, nil);
    PGL.BindTexture(0,0);

    glFrameBufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, Self.fTexture2D, 0);
    glFrameBufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, Self.fBackTexture2D, 0);
    glFrameBufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, Self.fDepthBuffer, 0);

    glFrameBufferParameterI(GL_FRAMEBUFFER, GL_FRAMEBUFFER_DEFAULT_WIDTH, Self.Width);
    glFrameBufferParameterI(GL_FRAMEBUFFER, GL_FRAMEBUFFER_DEFAULT_HEIGHT, Self.Height);

    if Assigned(Self.fAttachment) then begin
      Self.fAttachment.fWidth := AWidth;
      Self.fAttachment.fHeight := AHeight;
      Self.fAttachment.fDataSize := (AWidth * AHeight) * 4;
    end;

    CheckVar := glCheckFrameBufferStatus(GL_FRAMEBUFFER);
    if CheckVar <> GL_FRAMEBUFFER_COMPLETE then begin
      CheckVar := CheckVar;
    end;

  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                TPGLWindow
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLWindow.Create(AWidth: Integer = 800; AHeight: Integer = 600; ATitle: string = 'Window'; AFormat: PPGLWindowFormat = nil; ASettings: PPGLFeatureSettings = nil);
  begin

    inherited Create(AWidth,AHeight);

    Self.fTitle := ATitle;

    pglStart(AWidth, AHeight, AFormat^, ASettings^, ATitle);

    Self.fWidth := Context.Width;
    Self.fHeight := Context.Height;
    Self.GlobalDrawValues.TargetWidth := Self.fWidth;
    Self.GlobalDrawValues.TargetHeight := Self.fHeight;
    Self.fRenderRect := RectIWH(0,0,Self.Width,Self.Height);

    PGL.fContext := PGLContext.Context;

    // enables and disables
    if ASettings.OpenGLDebugContext then begin
      glEnable(GL_DEBUG_OUTPUT);
      glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
      glDebugMessageCallback(@Debug,nil);
    end;


    Self.fSizable := False; // TO-DO
    Self.fKeepCentered := False; // TO-DO
    Self.fFullScreen := AFormat.FullScreen;

    Self.fOSHandle := PGL.fContext.Handle;
    Self.fDC := PGL.fContext.DC;
    Self.fScreenWidth := GetDeviceCaps(Self.DC, HORZRES);
    Self.fScreenHeight := GetDeviceCaps(Self.DC, VERTRES);

    Self.CreateFBO(Self.fWidth,Self.fHeight);

    glBlitNamedFramebuffer := wglGetProcAddress('glBlitNamedFramebuffer');
    glBindTextureUnit := wglGetProcAddress('glBindTextureUnit');


  end;

procedure TPGLWindow.Update();
  begin
    SwapBuffers(Self.DC);
    Self.Clear();
    PGL.fContext.PollEvents();
  end;

procedure TPGLWindow.Close();
  begin
    PGL.fContext.Close();
    PGL.fRunning := False;
  end;

procedure TPGLWindow.Finish();
var
Ver: TArray<TPGLVec3>;
Coord: TArray<TPGLVec3>;
  begin

    PGL.DrawState.CurrentTarget.DrawLastBatch();

    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_TRUE);

    glEnable(GL_SCISSOR_TEST);
    glScissor(0,0,Self.Width,Self.Height);

    Self.MakeCurrentTarget();
    glBindFrameBuffer(GL_FRAMEBUFFER,0);

    glBindVertexArray(PGL.DrawState.Buffers.VAO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, PGL.DrawState.Buffers.EBO);

    PGL.BindTexture(0, Self.fTexture2D);

    Ver := Self.RenderRect.toVectors();

    SetLength(Coord,4);
    Coord[0] := Vec3(0,0);
    Coord[1] := Vec3(1,0);
    Coord[2] := Vec3(1,1);
    Coord[3] := Vec3(0,1);
    FlipVerticle(Coord);

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVec3) * 4, @Ver[0]);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, Pointer(0));

    PGL.DrawState.Buffers.SelectNextVBO();
    PGL.DrawState.Buffers.CurrentVBO.SubData(SizeOf(TPGLVec3) * 4, @Coord[0]);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, Pointer(0));

    PGL.UseProgram('Display');

    glUniform1f(PGL.GetUniform('planeWidth'), Self.Width);
    glUniform1f(PGL.GetUniform('planeHeight'), Self.Height);
    glUniform1i(PGL.GetUniform('tex'),0);

    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nil);

    PGL.DrawState.Buffers.Reset();

    glBindFrameBuffer(GL_FRAMEBUFFER, PGL.DrawState.CurrentTarget.fFrameBuffer);

  end;

procedure TPGLWindow.UpdatePosition();
  begin
    // TO-DO
  end;

procedure TPGLWindow.SetTitle(ATitle: string = '');
  begin
    PGL.fContext.SetTitle(ATitle);
  end;

procedure TPGLWindow.SetScreenCenter();
var
x,y: GLInt;
  begin
    Context.SetPosition( trunc((Context.ScreenWidth / 2) - (Self.Width / 2)), trunc((Context.ScreenHeight / 2) - (Self.Height / 2)));
  end;

procedure TPGLWindow.SetKeepCentered(ACentered: Boolean = True);
  begin
    Self.fKeepCentered := ACentered;
    if ACentered then begin
      Self.SetScreenCenter();
    end;
  end;

procedure TPGLWindow.SetHasTitleBar(ATitleBar: Boolean = True);
  begin
    // TO-DO
  end;

procedure TPGLWindow.SetSizable(ASizable: Boolean = True);
  begin
    Self.fSizable := ASizable;
    PGL.Context.SetCanSize(ASizable);
  end;

function TPGLWindow.SetWidth(AWidth: GLUint): Boolean;
  begin
    Result := Self.SetSize(AWidth,Self.Height);
  end;

function TPGLWindow.SetHeight(AHeight: GLUint): Boolean;
  begin
    Result := Self.SetSize(Self.Width,AHeight);
  end;

function TPGLWindow.SetSize(AWidth, AHeight: GLUint): Boolean;
var
ReturnSizable: Boolean;
  begin

    Result := False;

    if Context.SetSize(AWidth,AHeight,True) = False then begin
      exit;
    end;

    Result := True;

    Self.fWidth := AWidth;
    Self.fHeight := AHeight;
    Self.fRenderRect := RectIWH(0,0,Self.fWidth,Self.fHeight);

    Self.MakeCurrentTarget();

    glFrameBufferParameterI(GL_FRAMEBUFFER, GL_FRAMEBUFFER_DEFAULT_WIDTH, Self.Width);
    glFrameBufferParameterI(GL_FRAMEBUFFER, GL_FRAMEBUFFER_DEFAULT_HEIGHT, Self.Height);

    PGL.BindTexture(0,Self.fTexture2D);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, AWidth, AHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);

    PGL.BindTexture(0,Self.fBackTexture2D);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, AWidth, AHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);

    PGL.BindTexture(0,Self.fDepthBuffer);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32, AWidth, AHeight, 0, GL_DEPTH_COMPONENT, GL_FLOAT, nil);
    PGL.BindTexture(0,0);

    glViewPort(0,0,Self.width,Self.Height);
  end;

procedure TPGLWindow.SetFullScreen(AFullScreen: Boolean = True);
  begin
      PGL.Context.SetFullScreen(AFullScreen);
      Self.fFullScreen := PGL.Context.FullScreen;
  end;

procedure TPGLWindow.SetPosition(APosition: TPGLVec2);
var
X,Y: GLUInt;
  begin
    if (APosition.X >= 0) and (APosition.X < PGL.Context.ScreenWidth) then begin
      X := trunc(APosition.X);
    end else Begin
      X := Self.Left;
    end;

    if (APosition.Y >= 0) and (APosition.Y < PGL.Context.ScreenHeight) then begin
      Y := trunc(APosition.Y);
    end else Begin
      Y := Self.Top;
    end;

    PGL.Context.SetPosition(X,Y);
    Self.UpdatePosition();
  end;


procedure TPGLWindow.SetMaximizeProc(AProc: TPGLWindowProc);
  begin
    Self.fMaximizeProc := AProc;
  end;

procedure TPGLWindow.SetMinimizeProc(AProc: TPGLWindowProc);
  begin
    Self.fMinimizeProc := AProc;
  end;

procedure TPGLWindow.SetGotFocusProc(AProc: TPGLWindowProc);
  begin
    Self.fGotFocusProc := AProc;
  end;

procedure TPGLWindow.SetLostFocusProc(AProc: TPGLWindowProc);
  begin
    Self.fLostFocusProc := AProc;
  end;

procedure TPGLWindow.SetWindowCloseProc(AProc: TPGLWindowProc);
  begin
    PGL.Context.RegisterWindowCloseCallBack(AProc);
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                TPGLInstance
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLInstance.Create();
  begin
    Self.fRunning := False;
    Self.fWindow := nil;
    Self.fEXEPath := ExtractFilePath(ParamStr(0));
    Self.fSourcePath := Self.fEXEPath;
  end;

destructor TPGLInstance.Destroy();
  begin
    inherited Destroy();
  end;

procedure TPGLInstance.Free();
  begin
    inherited Free();
  end;

procedure TPGLInstance.Init(var AWindow: TPGLWindow; AWidth: Integer; AHeight: Integer; ATitle: string; AFormat: PPGLWindowFormat = nil; ASettings: PPGLFeatureSettings = nil);
var
UseFormat: TPGLWindowFormat;
UseSettings: TPGLFeatureSettings;
TempDC: Integer;
Success: Integer;
I: GLInt;
MaskBit: GLInt;
  begin

    // don't allow a second init
    if Self.fRunning then exit;

    if AFormat <> nil then begin
      UseFormat := AFormat^;
    end;

    if ASettings <> nil then begin
      UseSettings := ASettings^;
    end;


    Self.DrawState.OwnedCamera := TPGLCamera.Create();
    Self.DrawState.Camera := Self.DrawState.OwnedCamera;

    // init OpenGL
    AWindow := TPGLWindow.Create(AWidth,AHeight,ATitle, @UseFormat, @UseSettings); // window and context creation happens here

    // make sure the window has correct data
    AWindow.UpdatePosition();

    // update self with current data, fetch data from OS
    Self.fRunning := True;
    Self.fWindow := AWindow;
    Self.fKeyBoard := Self.fContext.Keyboard;
    Self.fMouse := Self.fContext.Mouse;
    Self.fController := Self.fContext.Controller;

    Self.fDepthWrite := True;
    Self.fAlphaChannel := True;

    // callbacks

    // load all shaders in shader directory
    GlobalHeader := AnsiString(pglReadFile(PGL.SourcePath + 'Shaders/Global Values Header.txt'));
    GlobalBody := AnsiString(pglReadFile(PGL.SourcePath + 'Shaders/Global Values Body.txt'));

    Self.CreateShaders();

    // create initial sampler objects
    Self.CreateSamplers();

    // create the temp buffer used for copying and other functions
    Self.TempBuffer := TPGLRenderTexture.Create(AWidth,AHeight);

    // create temp sprite used for some drawing functions
    Self.TempSprite := TPGLSprite.Create();

    // Setup initial draw state
    Self.DrawState.TransparentColor := pgl_magenta_f;
    Self.DrawState.State := '';
    Self.DrawState.Buffers.FillBuffers();
    Self.DrawState.CurrentTarget := Self.fWindow;
    Self.DrawState.CurrentProgram := nil;
    Self.DrawState.ColorCompareThreshold := 0.0;
    Self.DrawState.ViewNear := 0;
    Self.DrawState.ViewFar := 1;
    Self.DrawState.Camera.SetViewport(Self.fWindow.RenderRect, 0, 1);
    Self.DrawState.Camera.GetProjection();

    // query GL states and info
    glGetIntegerV(GL_MINOR_VERSION, @Self.fMinVer);
    glGetIntegerV(GL_MAJOR_VERSION, @Self.fMajVer);
    glGetIntegerV(GL_MAX_UNIFORM_BLOCK_SIZE, @Self.fMaxUBOSize);
    glGetIntegerV(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, @Self.fMaxTexUnits);
    glGetIntegerV(GL_MAX_TEXTURE_IMAGE_UNITS, @Self.fMaxSamplerUnits);
      SetLength(Self.fTexUnit, Self.fMaxSamplerUnits);
    glGetIntegerV(GL_MAX_TEXTURE_MAX_ANISOTROPY, @Self.fMaxAnisoTrophy);



  end;

procedure TPGLInstance.Run(AMainLoop: TPGLProc);
  begin
    while Self.fRunning do begin
      AMainLoop();

      if Self.fWindow.Closeflag = 1 then begin
        Self.fRunning := False;
      end;

    end;

    Self.Quit();
  end;


procedure TPGLInstance.Quit();
  begin
    // TO-Do
  end;


procedure TPGLInstance.SetColorCompareThreshold(AValue: GLFloat);
  begin
    Self.DrawState.ColorCompareThreshold := Clampf(AValue);
  end;


procedure TPGLInstance.SetTransparentColor(AColor: TPGLColorF);
  begin
    Self.DrawState.TransparentColor := AColor;
  end;


procedure TPGLInstance.SelectCamera(ACamera: TPGLCamera);
  begin

    if Self.Camera = ACamera then Exit;

    Self.DrawState.CurrentTarget.DrawLastBatch();

    if Assigned(ACamera) then begin
      Self.DrawState.Camera := ACamera;
    end else begin
      Self.DrawState.Camera := SElf.DrawState.OwnedCamera;
    end;

    Self.DrawState.Camera.GetProjection();

  end;


procedure TPGLInstance.SetViewRange(ANear: Single; AFar: Single);
  begin
    Self.DrawState.ViewNear := ANear;
    Self.DrawState.ViewFar := AFar;
    Self.DrawState.Camera.SetViewport(Self.DrawState.Camera.ViewPort, ANear, AFar);
  end;


procedure TPGLInstance.EnableDepthWrite();
  begin
    if PGL.DrawState.CurrentTarget <> nil then begin
      PGL.DrawState.CurrentTarget.DrawLastBatch();
    end;
    Self.fDepthWrite := True;
  end;


procedure TPGLInstance.DisableDepthWrite();
  begin
    if PGL.DrawState.CurrentTarget <> nil then begin
      PGL.DrawState.CurrentTarget.DrawLastBatch();
    end;
    Self.fDepthWrite := False;
  end;


procedure TPGLInstance.EnableAlphaChannel();
  begin
    if Self.fAlphaChannel = false then begin
      Self.fAlphaChannel := True;
      glEnable(GL_BLEND);
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    end;
  end;


procedure TPGLInstance.DisableAlphaChannel();
  begin
    if Self.fAlphaChannel = true then begin
      Self.fAlphaChannel := False;
      glDisable(GL_BLEND);
    end;
  end;


procedure TPGLInstance.SetDrawFilter(AFilter: TPGLDrawFilter);
  begin

    if AFilter = Self.DrawFilter then Exit;

    Self.fDrawFilter := AFilter;

    if AFilter = TPGLDrawFilter.pgl_nearest then begin
      glSamplerParameterI(Self.fSampler, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
      glSamplerParameterI(Self.fSampler, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    end else begin
      glSamplerParameterI(Self.fSampler, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glSamplerParameterI(Self.fSampler, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    end;

  end;


procedure TPGLInstance.SetAnisotropy(AValue: GLInt);
  begin
    if AValue = Self.fAnisotropy then Exit;
    if (AValue <= 0) or (AValue > Self.fMaxAnisoTrophy) then Exit;

    glSamplerParameterI(Self.fSampler, GL_TEXTURE_MAX_ANISOTROPY, AValue);
    Self.fAnisotropy := AValue;
  end;

procedure TPGLInstance.DeleteImage(var AImage: TPGLImage);
  begin
    Self.RemoveImage(AImage);
    AImage.Free();
    AImage := Nil;
  end;

procedure TPGLInstance.DeleteTexture(var ATexture: TPGLTexture);
  begin
    Self.RemoveTexture(ATexture);
    ATexture.Free();
    ATexture := Nil;
  end;

procedure TPGLInstance.DeleteSprite(var ASprite: TPGLSPrite);
  begin
    Self.RemoveSprite(ASprite);
    ASprite.Free();
    ASprite := Nil;
  end;

procedure TPGLInstance.DeleteFont(var AFont: TPGLFont);
  begin
    Self.RemoveFont(AFont);
    AFont.Free();
    AFont := Nil;
  end;

procedure TPGLInstance.DeleteText(var AText: TPGLText);
  begin
    Self.RemoveText(AText);
    AText.Free();
    AText := Nil;
  end;

procedure TPGLInstance.DeleteRenderTexture(var ARenderTexture: TPGLRenderTexture); register;
  begin
    if Self.DrawState.CurrentTarget = ARenderTexture then begin
      Self.DrawState.CurrentTarget := Nil;
    end;

    Self.RemoveRenderTexture(ARenderTexture);
    ARenderTexture.Free();
    ARenderTexture := Nil;
  end;


procedure TPGLInstance.OutputTextureBindings();
Var
I: GLInt;
CurUnit, CurTex: GLUint;
OutString: String;
  begin

    for I := 0 to 31 do begin
      glActiveTexture(GL_TEXTURE0 + I);
      glGetIntegerV(GL_TEXTURE_BINDING_2D, @CurTex);
      OutString := OutString + 'Texture Unit ' + I.ToString + ': ' + CurTex.ToSTring + sLineBreak;
    end;

    AllocConsole();
    WriteLn(OutString);

    DebugBreak();

  end;

function TPGLInstance.SetCurrentTarget(var ATarget: TPGLRenderTarget): Boolean;
  begin
    if Self.DrawState.CurrentTarget <> ATarget then begin
      // if PGL already has a current target, draw it's last batch before switching targets
      if Self.DrawState.CurrentTarget <> nil then begin
        Self.DrawState.CurrentTarget.DrawLastBatch();
      end;

      Self.DrawState.CurrentTarget := ATarget;

      Self.DrawState.Camera.SetViewport(Self.DrawState.CurrentTarget.RenderRect, PGL.Camera.ViewNear, PGL.Camera.ViewDistance);
      Self.DrawState.CurrentTarget.GlobalDrawValues.ViewNear := PGL.Camera.ViewNear;
      Self.DrawState.CurrentTarget.GlobalDrawValues.ViewFar := PGL.Camera.ViewDistance;

      glBindBuffer(GL_SHADER_STORAGE_BUFFER, PGL.DrawState.Buffers.StaticSSBO.Buffer);
      glBufferData(GL_SHADER_STORAGE_BUFFER, SizeOf(Self.DrawState.CurrentTarget.GlobalDrawValues), @Self.DrawState.CurrentTarget.GlobalDrawValues, GL_STREAM_DRAW);
      PGL.DrawState.Buffers.StaticSSBO.BindToBase(9);

      Result := True;

    end else begin

      Result := False;
    End;

    if ATarget <> nil then begin
      glViewPort(0,0,ATarget.Width,ATarget.Height);
    end;
  end;

procedure TPGLInstance.UseProgram(AName: string);
var
I: Integer;
ErrorMessage: String;
  begin
    // search for and use shader program by name
    for I := 0 to High(Self.fProgramList) do begin
       if Self.fProgramList[i].Name = AName then begin
        Self.DrawState.CurrentProgram := Self.fProgramList[i];
        glUseProgram(Self.fProgramList[i].ID);

        glBindBuffer(GL_SHADER_STORAGE_BUFFER, Self.DrawState.Buffers.StaticSSBO.Buffer);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 9, Self.DrawState.Buffers.StaticSSBO.Buffer);

        exit;
       end;
    end;

    // didn't find, send a debug message
    ErrorMessage := 'Could not find/use program ' + AName + '!';
    pglDebug(0,0,0,0,Length(ErrorMessage),PAnsiChar(AnsiString(ErrorMessage)),nil);

  end;

function TPGLInstance.GetUniform(AName: string): GLint; register;
  begin
    Result := Self.DrawState.CurrentProgram.GetUniform(AName);
  end;

procedure TPGLInstance.CreateShaders();
var
Dir: TDirectory;
Files: TArray<String>;
I: Integer;
PathName: String;
  begin

    Dir.SetCurrentDirectory(Self.SourcePath + 'Shaders\');
    Files := Dir.GetDirectories(Self.SourcePath + 'Shaders\');

    for I := 0 to High(Files) do begin

      SetLength(Self.fProgramList, Length(Self.fProgramList) + 1);
      Self.fProgramList[High(Self.fProgramList)] := TPGLProgram.Create(Files[i] + '\');

    end;
  end;


procedure TPGLInstance.CreateSamplers();
var
I: GLInt;
  begin
    Self.fDrawFilter := pgl_nearest;
    Self.fAnisotropy := 1;

    glGenSamplers(1,@Self.fSampler);
    glSamplerParameterI(Self.fSampler, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glSamplerParameterI(Self.fSampler, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glSamplerParameterI(Self.fSampler, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glSamplerParameterI(Self.fSampler, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glSamplerParameterI(Self.fSampler, GL_TEXTURE_MAX_ANISOTROPY , 1);

    for I := 0 to 31 do begin
      glBindSampler(I,Self.fSampler);
    end;

  end;


function TPGLInstance.GetTextureUnit(Index: GLUint): GLUint;
  begin
    // return 0 if querying out of range
    if Index > Cardinal(High(Self.fMaxTexUnits)) then Begin
      Result := 0;
      exit;
    end;

    Result := Self.fTexUnit[Index];
  end;


procedure TPGLInstance.UpdateDrawState(ANewTarget: TPGLRenderTarget);
  begin

  end;

procedure TPGLInstance.AddImage(var AImage: TPGLImage);
  begin
    SetLength(Self.fImages, Length(Self.fImages) + 1);
    Self.fImages[High(Self.fImages)] := AImage;
  end;

procedure TPGLInstance.RemoveImage(var AImage: TPGLImage);
var
I: GLInt;
ImgPos: GLInt;
  begin

    ImgPos := -1;

    for I := 0 to High(Self.fImages) do begin
      if Self.fImages[i] = AImage then begin
        ImgPos := I;
        Break;
      end;
    end;

    if ImgPos = - 1 then exit;

    for I := ImgPos to High(Self.fImages) - 1 do begin
      Self.fImages[i] := Self.fImages[I + 1];
    end;

    SetLength(Self.fImages, Length(Self.fImages) - 1);
  end;

Procedure TPGLInstance.GenTexture(var ATexture: TPGLTexture);
var
Data: TArray<byte>;
  begin
    // create the GL texture
    glGenTextures(1,@ATexture.fHandle);
    glBindTexture(GL_TEXTURE_2D,ATexture.fHandle);

    SetLength(Data, (ATexture.Width * ATexture.Height) * 4);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, ATexture.Width, ATexture.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);

    // set initial parameters
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);

    glBindTexture(GL_TEXTURE_2D,0);

    Self.AddTexture(ATexture);
  end;


procedure TPGLInstance.AddTexture(var ATexture: TPGLTexture);
var
I: GLInt;
  begin
    SetLength(Self.fTextures, Length(Self.fTextures) + 1);
    I := High(Self.fTextures);
    Self.fTextures[i] := ATexture;
  end;


procedure TPGLInstance.RemoveTexture(var ATexture: TPGLTexture);
var
I: GLInt;
TexPos: GLInt;
  begin

    TexPos := -1;

    for I := 0 to High(Self.fTextures) do begin
      if Self.fTextures[i] = ATexture then begin
        TexPos := I;
        Break;
      end;
    end;

    if TexPos = - 1 then exit;

    for I := TexPos to High(Self.fTextures) - 1 do begin
      Self.fTextures[i] := Self.fTextures[I + 1];
    end;

    SetLength(Self.fTextures, Length(Self.fTextures) - 1);

    glDeleteTextures(1,@ATexture.Handle);
    ATexture.fHandle := 0;
    ATexture.fDataSize := 0;
    ATexture.fWidth := 0;
    ATexture.fHeight := 0;

  end;

procedure TPGLInstance.AddSPrite(var ASprite: TPGLSprite);
  begin
    SetLength(Self.fSprites, Length(Self.fSprites) + 1);
    Self.fSprites[High(Self.fSprites)] := ASprite;
  end;

procedure TPGLInstance.RemoveSprite(var ASprite: TPGLSprite);
var
I: GLInt;
SpritePos: GLInt;
  begin

    SpritePos := -1;

    for I := 0 to High(Self.fsprites) do begin
      if Self.fsprites[i] = ASprite then begin
        SpritePos := I;
        Break;
      end;
    end;

    if SpritePos = - 1 then exit;

    for I := SpritePos to High(Self.fsprites) - 1 do begin
      Self.fsprites[i] := Self.fsprites[I + 1];
    end;

    SetLength(Self.fsprites, Length(Self.fsprites) - 1);
  end;

procedure TPGLInstance.AddFont(var AFont: TPGLFont);
  begin
    SetLength(Self.fFonts, Length(Self.fFonts) + 1);
    Self.fFonts[High(Self.fFonts)] := AFont;
  end;

procedure TPGLInstance.RemoveFont(var AFont: TPGLFont);
var
I: GLInt;
FontPos: GLInt;
  begin

    FontPos := -1;

    for I := 0 to High(Self.fFonts) do begin
      if Self.fFonts[i] = AFont then begin
        FontPos := I;
        Break;
      end;
    end;

    if FontPos = - 1 then exit;

    for I := FontPos to High(Self.fFonts) - 1 do begin
      Self.fFonts[i] := Self.fFonts[I + 1];
    end;

    SetLength(Self.fFonts, Length(Self.fFonts) - 1);

    Self.UpdateFontDestroy(AFont);

  end;

procedure TPGLInstance.AddText(var AText: TPGLText);
  begin
    SetLength(Self.fTexts, Length(Self.fTexts) + 1);
    Self.fTexts[High(Self.fTexts)] := AText;
  end;

procedure TPGLInstance.RemoveText(var AText: TPGLText);
var
I: GLInt;
TextPos: GLInt;
  begin

    TextPos := -1;

    for I := 0 to High(Self.fTexts) do begin
      if Self.fTexts[i] = AText then begin
        TextPos := I;
        Break;
      end;
    end;

    if TextPos = - 1 then exit;

    for I := TextPos to High(Self.fTexts) - 1 do begin
      Self.fTexts[i] := Self.fTexts[I + 1];
    end;

    SetLength(Self.fTexts, Length(Self.fTexts) - 1);

  end;

procedure TPGLInstance.AddRenderTexture(var ARenderTexture: TPGLRenderTexture); register;
  begin
    SetLength(Self.fRenderTextures, Length(Self.fRenderTextures) + 1);
    Self.fRenderTextures[High(Self.fRenderTextures)] := ARenderTexture;
  end;

procedure TPGLInstance.RemoveRenderTexture(var ARenderTexture: TPGLRenderTexture); register;
var
I: GLInt;
RenTexPos: GLInt;
  begin

    RenTexPos := -1;

    for I := 0 to High(Self.fRenderTextures) do begin
      if Self.fRenderTextures[i] = ARenderTexture then begin
        RenTexPos := I;
        Break;
      end;
    end;

    if RenTexPos = - 1 then exit;

    for I := RenTexPos to High(Self.fRenderTextures) - 1 do begin
      Self.fRenderTextures[i] := Self.fRenderTextures[I + 1];
    end;

    SetLength(Self.fRenderTextures, Length(Self.fRenderTextures) - 1);

  end;

procedure TPGLInstance.UpdateFontRefresh(var AFont: TPGLFont);
var
I: GLInt;
  begin
    for I := 0 to High(Self.fTexts) do begin
      if Self.fTexts[i].Font = AFont then begin
        Self.fTexts[i].SetText(Self.fTexts[i].Text);
      end;
    end;
  end;

procedure TPGLInstance.UpdateFontDestroy(var AFont: TPGLFont);
var
I: GLInt;
  begin
    // Reset TPGLTexts that use the font
    for I := 0 to High(Self.fTexts) do begin
      if Self.fTexts[i].fFont = AFont then begin
        Self.fTexts[i].Reset();
      end;
    end;
  end;

procedure TPGLInstance.UpdateTextureDestroy(var ATexture: TPGLTexture);
var
I: GLInt;
  begin
    // restore textures of TPGLRenderTargets that have texture as attachment
    for I := 0 to High(Self.fRenderTextures) do begin
      if Self.fRenderTextures[i].fAttachment = ATexture then begin
        Self.fRenderTextures[i].RestoreTexture();
      end;
    end;

    // remove texture reference from sprites that use texture
    for I := 0 to High(Self.fSprites) do begin
      if Self.fSprites[i].fTexture = ATexture then begin
        Self.fSprites[i].fTexture := nil;
        Self.fSprites[i].SetSize(0,0);
        Self.fSprites[i].SetTextureRect(RectFWH(0,0,0,0));
      end;
    end;

  end;

function TPGLInstance.GetImageCount(): GLInt;
  begin
    Result := Length(Self.fImages);
  end;

function TPGLInstance.GetTextureCount(): GLInt;
  begin
    Result := Length(Self.fTextures);
  end;

function TPGLInstance.GetSpriteCount(): GLInt;
  begin
    Result := Length(Self.fSprites);
  end;

function TPGLInstance.GetFontCount(): GLInt;
  begin
    Result := Length(Self.fFonts);
  end;

function TPGLInstance.GetTextCount(): GLInt;
  begin
    Result := Length(Self.fTexts);
  end;

function TPGLInstance.GetRenderTextureCount(): GLInt;
  begin
    Result := Length(Self.fRenderTextures);
  end;

procedure TPGLInstance.BindTexture(ATextureUnit: GLUint = 0; ATextureHandle: GLUint = 0);
  begin
    if ATextureUnit > Cardinal(High(Self.fMaxTexUnits)) then Begin
      exit;
    end;

//    if Self.fTexUnit[ATextureUnit] <> ATextureHandle then begin
      glActiveTexture(GL_TEXTURE0 + ATextureUnit);
      glBindTexture(GL_TEXTURE_2D, ATextureHandle);
      Self.fTexUnit[ATextureUnit] := ATextureHandle;
//    end;
  end;

procedure TPGLInstance.BindTexture(ATextureUnit: GLUint; var ATexture: TPGLTexture);
  begin
    if ATextureUnit > Cardinal(High(Self.fMaxTexUnits)) then Begin
      exit;
    end;

    if ATexture.fHandle = 0 then begin
      exit;
    end;

//    if Self.fTexUnit[ATextureUnit] <> ATexture.Handle then begin
      glActiveTexture(GL_TEXTURE0 + ATextureUnit);
      glBindTexture(GL_TEXTURE_2D, ATexture.fHandle);
      Self.fTexUnit[ATextureUnit] := ATexture.Handle;
//    end;
  end;


procedure TPGLInstance.UnbindTexture(var ATexture: TPGLTexture);
  begin
    if Assigned(ATexture) = false then exit;
    if ATexture.fHandle = 0 then exit;
    Self.UnbindTexture(ATexture.fHandle);
  end;


procedure TPGLInstance.UnbindTexture(ATextureHandle: Cardinal = 0);
var
I: GLInt;
  begin
    if ATextureHandle = 0 then exit;

    for I := 0 to High(Self.fTexUnit) do begin
      if Self.fTexUnit[i] = ATextureHandle then begin
        glActiveTexture(I);
        glBindTexture(GL_TEXTURE_2D, 0);
      end;
    end;
  end;

procedure TPGLInstance.UnbindAllTextures();
var
I: GLInt;
  begin
    for I := 0 to High(Self.fTexUnit) do begin
      if Self.fTexUnit[I] <> 0 then begin
        PGL.BindTexture(0,0);
      end;
    end;
  end;

procedure TPGLInstance.SetLigthReferenceBuffer(ATarget: TPGLRenderTarget);
  begin
    Self.fLightReferenceBuffer := ATarget;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                Unit Initialization
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

Initialization
  begin
    PGL := TPGLInstance.Create();
  end;


end.
