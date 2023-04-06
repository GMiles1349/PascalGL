unit PGLTypes;

interface

uses
  System.SysUtils, Types, Classes, Math, math.Vectors;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Enums
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


  type TPGLVectorComponent = (VX = 0, VY = 1, VZ = 2);


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Value Types
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Colors
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


  type
    PPGLColorF = ^TPGLColorF;
    TPGLColorF =  record
    public
      Red,Green,Blue,Alpha: Single;
      function Inverse(): TPGLColorf; register;
      function ToString(): String; register;
      procedure Lighten(AValue: Single); register;
      function ToGrey(): TPGLColorF; register;
  end;

  type
    PPGLColorI = ^TPGLColorI;
    TPGLColorI =  record
    public
      Red,Green,Blue,Alpha: Byte;
      function Inverse(): TPGLColorf; register;
      function ToString(): String; register;
      function ToGrey(): TPGLColorI; register;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Rects
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    PPGLRectI = ^TPGLRectI;
    TPGLRectI = record
    private
      fX,fY,fZ,fLeft,fTop,fRight,fBottom,fWidth,fHeight: Integer;

    public
      property X: Integer read fX;
      property Y: Integer read fY;
      property Z: Integer read fZ;
      property Left: Integer read fLeft;
      property Right: Integer read fRight;
      property Top: Integer read fTop;
      property Bottom: Integer read fBottom;
      property Width: Integer read fWidth;
      property Height: Integer read fHeight;
      property X1: Integer read fLeft;
      property X2: Integer read fRight;
      property Y1: Integer read fTop;
      property Y2: Integer read fBottom;

      class operator Initialize(out Dest: TPGLRectI);

      procedure Update(AFrom: Integer); register;
      procedure SetCenter(AX: Single = 0; AY: Single = 0; AZ: Single = 0); register;
      procedure SetX(AX: Single); register;
      procedure SetY(AY: Single); register;
      procedure SetLeft(ALeft: Single); register;
      procedure SetRight(ARight: Single); register;
      procedure SetTop(ATop: Single); register;
      procedure SetBottom(ABottom: Single); register;
      procedure SetTopLeft(ALeft, ATop: Single); register;
      procedure SetBottomRight(ARight, ABottom: Single); register;
      procedure SetSize(AWidth,AHeight: Single; AFrom: Integer = 0); register;
      procedure SetWidth(AWidth: Single; AFrom: Integer = 0); register;
      procedure SetHeight(AHeight: Single; AFrom: Integer = 0); register;
      procedure Grow(AIncWidth,AIncHeight: Single); register;
      procedure Stretch(APerWidth,APerHeight: Single); register;
      procedure FitInRect(ARect: TPGLRectI); register;
      procedure Translate(AX,AY,AZ: Single); register;

      function RandomSubRect(): TPGLRectI; register;
  end;


  type
    PPGLRectF = ^TPGLRectF;
    TPGLRectF = record
    private
      fX,fY,fZ,fLeft,fTop,fRight,fBottom,fWidth,fHeight: Single;

    public
      property X: Single read fX;
      property Y: Single read fY;
      property Z: Single read fZ;
      property Left: Single read fLeft;
      property Right: Single read fRight;
      property Top: Single read fTop;
      property Bottom: Single read fBottom;
      property Width: Single read fWidth;
      property Height: Single read fHeight;
      property X1: Single read fLeft;
      property X2: Single read fRight;
      property Y1: Single read fTop;
      property Y2: Single read fBottom;

      class operator Initialize (out Dest: TPGLRectF); register;

      procedure Update(AFrom: Integer); register;
      procedure SetX(AX: Single); register;
      procedure SetY(AY: Single); register;
      procedure SetZ(AZ: Single); register;
      procedure SetLeft(ALeft: Single); register;
      procedure SetRight(ARight: Single); register;
      procedure SetTop(ATop: Single); register;
      procedure SetBottom(ABottom: Single); register;
      procedure SetTopLeft(ALeft,ATop: Single); register;
      procedure SetBottomRight(ARight,ABottom: Single); register;
      procedure SetSize(AWidth,AHeight: Single; AFrom: Integer = 0); register;
      procedure Grow(AIncWidth,AIncHeight: Single); register;
      procedure Stretch(APerWidth,APerHeight: Single); register;
      procedure SetWidth(AWidth: Single; AFrom: Integer = 0); register;
      procedure SetHeight(AHeight: Single; AFrom: Integer = 0); register;
      procedure Translate(AX,AY: Single); register;

      function RandomSubRect(): TPGLRectF; register;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Vectors
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    PPGLVec2 = ^TPGLVec2;
    TPGLVec2 =  record
    X,Y: Single;

    class operator Add(A,B: TPGLVec2): TPGLVec2; register;
    class operator Subtract(A,B: TPGLVec2): TPGLVec2; register;
    class operator Multiply(A: TPGLVec2; B: Single): TPGLVec2; register;
    class operator Divide(A: TPGLVec2; B: Single): TPGLVec2; register;
    class operator Negative(A: TPGLVec2): TPGLVec2; register;

    procedure Translate(AValues: TPGLVec2); register;
    function ToString(APrecision: Cardinal = 0): String; register;
  end;


  type
    PPGLVec3 = ^TPGLVec3;
    TPGLVec3 =  record
    private
      function GetNormal(): TPGLVec3; register;
      function GetLength(): Single; register;

    public
      X,Y,Z: Single;

      property Normal: TPGLVec3 read GetNormal;
      property Length: Single read GetLength;

      class operator Add(A,B: TPGLVec3): TPGLVec3; register;
      class operator Add(A: TPGLVec3; B: Single): TPGLVec3; register;
      class operator Subtract(A,B: TPGLVec3): TPGLVec3; register;
      class operator Subtract(A: TPGLVec3; B: Single): TPGLVec3; register;
      class operator Divide(A: TPGLVec3; B: Single): TPGLVec3; register;
      class operator Divide(A: Single; B: TPGLVec3): TPGLVec3; register;
      class operator Multiply(A: TPGLVec3; B: Single): TPGLVec3; register;
      class operator Multiply(A,B: TPGLVec3): TPGLVec3; register;
      class operator Negative(A: TPGLVec3): TPGLVec3; register;

      procedure Negate(); register;
      procedure Translate(AX: Single = 0; AY: Single = 0; AZ: Single = 0); overload; register;
      procedure Translate(AValues: TPGLVec3); overload; register;
      procedure Rotate(AX,AY,AZ: Single); register;
      procedure Cross(AVec: TPGLVec3); register;
      function Dot(AVec: TPGLVec3): Single; register;
      function GetTargetVector(ATarget: TPGLVec3): TPGLVec3; register;
      function toNDC(ADispWidth, ADispHeight: Single): TPGLVec3; register;
      function Swizzle(AComponents: TArray<TPGLVectorComponent>): TPGLVec3; register;

  end;


  {$A4}
  type
    PPGLVec4 = ^TPGLVec4;
    TPGLVec4 =  record
    X,Y,Z,W: Single;
  end;
  {$A8}


  type
    PPGLVertex = ^TPGLVertex;
    TPGLVertex =  record
    public
      Vector: TPGLVec3;
      Color: TPGLColorF;
      TexCoord: TPGLVec3;
      Normal: TPGLVec3;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLMat4
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    PPGLMat4 = ^TPGLMat4;
    TPGLMat4 = record
      public
        M: Array [0..3, 0..3] of Single;

        property AX: Single read M[0,0] write M[0,0];
        property AY: Single read M[1,0] write M[1,0];
        property AZ: Single read M[2,0] write M[2,0];
        property AW: Single read M[3,0] write M[3,0];
        property BX: Single read M[0,1] write M[0,1];
        property BY: Single read M[1,1] write M[1,1];
        property BZ: Single read M[2,1] write M[2,1];
        property BW: Single read M[3,1] write M[3,1];
        property CX: Single read M[0,2] write M[0,2];
        property CY: Single read M[1,2] write M[1,2];
        property CZ: Single read M[2,2] write M[2,2];
        property CW: Single read M[3,2] write M[3,2];
        property DX: Single read M[0,3] write M[0,3];
        property DY: Single read M[1,3] write M[1,3];
        property DZ: Single read M[2,3] write M[2,3];
        property DW: Single read M[3,3] write M[3,3];

        class operator Initialize(out Dest: TPGLMat4); register;
        class operator Multiply(A: TPGLMat4; B: TPGLMat4): TPGLMat4; overload; register;
        class operator Multiply(A: TPGLMat4; B: TPGLVec4): TPGLVec4; overload; register;
        class operator Implicit(A: Array of Single): TPGLMat4; register;

        procedure Zero(); register;
        procedure SetIdentity(); register;
        procedure Fill(AValues: TArray<Single>); register;
        procedure Negate(); register;
        procedure Inverse(); register;
        procedure Scale(AFactor: Single); register;
        procedure Transpose(); register;
        procedure MakeTranslation(AX: Single = 0; AY: Single = 0; AZ: Single = 0); overload; register;
        procedure MakeTranslation(AValues: TPGLVec3); overload; register;
        procedure Translate(AX: Single = 0; AY: Single = 0; AZ: Single = 0); overload; register;
        procedure Translate(AValues: TPGLVec3); overload; register;
        procedure Rotate(AX: Single = 0; AY: Single = 0; AZ: Single = 0); overload; register;
        procedure Rotate(AValues: TPGLVec3); overload; register;
        procedure MakeScale(AX, AY, AZ: Single); register;
        procedure Perspective(AFOV, Aspect, ANear, AFar: Single; VerticalFOV: Boolean = True); register;
        procedure Ortho(ALeft,ARight,ABottom,ATop,ANear,AFar: Single); register;
        procedure LookAt(AFrom,ATo,AUp: TPGLVec3); register;

  end;


  type TPGLCylinder = record
    private
      fRadius: Single;
      fHeight: Single;
      fCenter: TPGLVec3;
      fBottomCenter: TPGLVec3;
      fTopCenter: TPGLVec3;
      fUp: TPGLVec3;

    public
      procedure SetBottomCenter(const ABottomCenter: TPGLVec3);
      procedure SetCenter(const ACenter: TPGLVec3);
      procedure SetHeight(const AHeight: Single);
      procedure SetRadius(const ARadius: Single);
      procedure SetTopCenter(const ATopCenter: TPGLVec3);
      procedure SetUpVector(const AUpVector: TPGLVec3);

      property Radius: Single read fRadius write SetRadius;
      property Height: Single read fHeight write SetHeight;
      property Center: TPGLVec3 read fCenter write SetCenter;
      property Top: TPGLVec3 read fTopCenter write SetTopCenter;
      property Bottom: TPGLVec3 read fBottomCenter write SetBottomCenter;

      constructor Create(ACenter: TPGLVec3; AUpVector: TPGLVec3; ARadius, AHeight: Single); register;

      procedure Translate(AValue: TPGLVec3); register;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLPlane
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type TPGLPlane = record
    Normal: TPGLVec3;
    Distance: Single;

    constructor Create(P1: TPGLVec3; ANormal: TPGLVec3);
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLFrustum
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


  type TPGLFrustum = record
    type TPGLFrustumFaces = record
      Top,Bottom,Left,Right,Near,Far: TPGLPlane;
    end;

    private
      Faces: TPGLFrustumFaces;
    public

      // view culling
      function isInViewSphere(APosition: TPGLVec3; ARadius: Single): Boolean; register;

      function OnorForwardSphere(const [ref] AFace: TPGLPlane; var ACenter: TPGLVec3; var ARadius: Single): Boolean; register;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLCamera
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type TPGLCamera = class
    private
      fPosition: TPGLVec3;
      fNDCPos: TPGLVec3;
      fDirection: TPGLVec3;
      fUp: TPGLVec3;
      fRight: TPGLVec3;
      fTarget: TPGLVec3;
      fViewNear: Single;
      fViewDistance: Single;
      fFOV: Single;
      fFOVVerticle: Boolean;
      fCameraType: Integer;
      fViewport: TPGLRectF;
      fView: TPGLMat4;
      fProjection: TPGLMat4;
      fFrustum: TPGLFrustum;
      fAngles: TPGLVec3;
      fVerticleFlip: Boolean;

      procedure GetDirection(); register;
      procedure GetRight(); register;
      procedure GetUp(); register;
      procedure GetNewAngles(); register;
      procedure ConstructFrustum(); register;

    public
      property Position: TPGLVec3 read fPosition;
      property Direction: TPGLVec3 read fDirection;
      property Up: TPGLVec3 read fUp;
      property Right: TPGLVec3 read fRight;
      property Target: TPGLVec3 read fTarget;
      property ViewNear: Single read fViewNear;
      property ViewDistance: Single read fViewDistance;
      property FOV: Single read fFOV;
      property FOVVerticle: Boolean read fFOVVerticle;
      property CameraType: Integer read fCameraType;
      property Viewport: TPGLRectF read fViewport;
      property ViewMatrix: TPGLMat4 read fView;
      property ProjectionMatrix: TPGLMat4 read fProjection;
      property Angles: TPGLVec3 read fAngles;
      property Frustum: TPGLFrustum read fFrustum;

      constructor Create(); register;

      procedure GetProjection(); register;

      procedure Set2DCamera(); register;
      procedure Set3DCamera(); register;
      procedure SetViewport(ABounds: TPGLRectF; AViewNear: Single = 0; AViewFar: Single = 1); register;
      procedure SetViewDistance(AViewDistance: Single); register;
      procedure SetPosition(APos: TPGLVec3); register;
      procedure SetTarget(ATarget: TPGLVec3); register;
      procedure SetDirection(ADirection: TPGLVec3); register;
      procedure SetFOV(AValue: Single; AVerticleFOV: Boolean = true); register;
      procedure Translate(AValues: TPGLVec3); register;
      procedure Rotate(AValues: TPGLVec3); register;
      procedure LockVerticleFlip(AEnable: Boolean = True); register;

      // view culling
      function SphereInView(APosition: TPGLVec3; ARadius: Single): Boolean; register;

  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Helper Types
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


  {* Rects *}
  type TPGLRectIHelper = record helper for TPGLRectI
    private
      function GetCenter(): TPGLVec3; register;
      function GetTopLeft(): TPGLVec3; register;
      function GetTopRight(): TPGLVec3; register;
      function GetBottomLeft(): TPGLVec3; register;
      function GetBottomRight(): TPGLVec3; register;

    public
      property Center: TPGLVec3 read GetCenter;
      property TopLeft: TPGLVec3 read GetTopLeft;
      property TopRight: TPGLVec3 read GetTopRight;
      property BottomLeft: TPGLVec3 read GetBottomLeft;
      property BottomRight: TPGLVec3 read GetBottomRight;

      class operator Implicit(A: TPGLRectF): TPGLRectI; register;
      class operator Implicit(A: TRect): TPGLRectI; register;
      class operator Add(A: TPGLRectI; B: TPGLVec3): TPGLRectI; register;
      class operator Subtract(A: TPGLRectI; B: TPGLVec3): TPGLRectI; register;

      function toVectors(): TArray<TPGLVec3>; register;
      procedure Assign(ARectF: TPGLRectF); register;
      procedure ScaleToFit(AFitRect: TPGLRectF); register;
  end;


  type TPGLRectFHelper = record helper for TPGLRectF
    private
      function GetCenter(): TPGLVec3; register;
      function GetTopLeft(): TPGLVec3; register;
      function GetTopRight(): TPGLVec3; register;
      function GetBottomLeft(): TPGLVec3; register;
      function GetBottomRight(): TPGLVec3; register;

    public
      property Center: TPGLVec3 read GetCenter;
      property TopLeft: TPGLVec3 read GetTopLeft;
      property TopRight: TPGLVec3 read GetTopRight;
      property BottomLeft: TPGLVec3 read GetBottomLeft;
      property BottomRight: TPGLVec3 read GetBottomRight;

      class operator Implicit(A: TPGLRectI): TPGLRectF; register;
      class operator Add(A: TPGLRectF; B: TPGLVec3): TPGLRectF; register;
      class operator Subtract(A: TPGLRectF; B: TPGLVec3): TPGLRectF; register;

      function toVectors(): TArray<TPGLVec3>; register;
      function toTexCoords(): TArray<TPGLVec3>; register;
      procedure Assign(ARectI: TPGLRectI); register;
      procedure SetCenter(ACenter: TPGLVec3); register;
  end;


  {* Vectors *}
  type TPGLVec2Helper = record helper for TPGLVec2
    class operator Implicit(A: TPoint): TPGLVec2;  register;
    class operator Implicit(A: TPGLVec3): TPGLVec2;  register;
    class operator Implicit(A: TPGLVec4): TPGLVec2;  register;
    class operator Explicit(A: TPoint): TPGLVEc2;  register;
    class operator Explicit(A: TPGLVec3): TPGLVec2;  register;
    class operator Explicit(A: TPGLVec4): TPGLVec2;  register;
    class operator Add(A,B: TPGLVec2): TPGLVec2;  register;
    class operator Equal(A,B: TPGLVec2): Boolean;  register;
    class operator NotEqual(A,B: TPGLVec2): Boolean;  register;
  end;


  type TPGLVec3Helper = record helper for TPGLVec3
    class operator Implicit(A: TPoint): TPGLVec3;  register;
    class operator Implicit(A: TPGLVec2): TPGLVec3;  register;
    class operator Implicit(A: TPGLVec4): TPGLVec3;  register;
    class operator Explicit(A: TPGLVec2): TPGLVec3;  register;
    class operator Explicit(A: TPGLVec4): TPGLVec3;  register;
    class operator Multiply(A: TPGLVec3; B: TPGLMat4): TPGLVec3; register;
  end;

  type TPGLVec4Helper = record helper for TPGLVec4
    class operator Implicit(A: TPGLVec2): TPGLVec4;  register;
    class operator Implicit(A: TPGLVec3): TPGLVec4;  register;
    class operator Explicit(A: TPGLVec2): TPGLVec4;  register;
    class operator Explicit(A: TPGLVec3): TPGLVec4;  register;
  end;


  {* Colors *}
  type TPGLColorFHelper = record helper for TPGLColorF
    public
      class operator Equal(Color1: TPGLColorF; Color2: TPGLColorF): Boolean;  register;
      class operator Equal(ColorF: TPGLColorF; ColorI: TPGLColorI): Boolean;  register;
      class operator NotEqual(A,B: TPGLColorF): Boolean; register;
      class operator Implicit(ColorI: TPGLColorI): TPGLColorF; register;
      class operator Implicit(AData: Pointer): TPGLColorF; register;
      class operator Implicit(AColor: Cardinal): TPGLColorF; register;
      class operator Implicit(AColor: TPGLColorF): Cardinal; register;
      class operator Implicit(AVector: TPGLVec4): TPGLColorF; register;
      class operator Explicit(AData: Pointer): TPGLColorF; register;
      class operator Explicit(AVector: TPGLVec4): TPGLColorF; register;
      class operator Add(A,B: TPGLColorF): TPGLColorF;  register;
      class operator Add(A: TPGLColorF; B: TPGLVec4): TPGLColorF;  register;
      class operator Subtract(A,B: TPGLColorF): TPGLColorF;  register;
      class operator Subtract(A: TPGLColorF; B: TPGLVec4): TPGLColorF;  register;
      class operator Multiply(A: TPGLColorF; B: Single): TPGLColorF;  register;
      function toColorI(): TPGLColorI; register;
  end;

  type TPGLColorIHelper = record helper for TPGLColorI
    public
      class operator Equal(Color1: TPGLColorI; Color2: TPGLColorI): Boolean; register;
      class operator Equal(ColorI: TPGLColorI; ColorF: TPGLColorF): Boolean; register;
      class operator Implicit(ColorF: TPGLColorF): TPGLColorI; register;
      class operator Implicit(AData: Pointer): TPGLColorI; register;
      class operator Implicit(AColor: Cardinal): TPGLColorI; register;
      class operator Implicit(AColor: TPGLColorI): Cardinal; register;
      class operator Explicit(AData: Pointer): TPGLColorI; register;
      class operator Add(A,B: TPGLColorI): TPGLColorI;  register;
      class operator Add(A: TPGLColorI; B: TPGLVec4): TPGLColorI;  register;
      class operator Subtract(A,B: TPGLColorI): TPGLColorI;  register;
      class operator Subtract(A: TPGLColorI; B: TPGLVec4): TPGLColorI;  register;
      class operator Multiply(A: TPGLColorI; B: Single): TPGLColorI;  register;
      function toColorF(): TPGLColorF; register;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Procedures
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


  {* Colors *}
  function ColorF(R,G,B: Single; A: Single = 1): TPGLColorF; overload; register;
  function ColorF(AColorI: TPGLColorI): TPGLColorF; overload; register;

  function ColorI(R,G,B: Single; A: Single = 255): TPGLColorI; overload; register;
  function ColorI(AColorF: TPGLColorF): TPGLColorI; overload; register;

  function GetColorIncrements(AStartColor, AEndColor: TPGLColorF; AIncrements: Cardinal): TPGLVec4; register;

  {* Rects *}
  function RectI(ALeft,ATop,ARight,ABottom: Integer): TPGLRectI; overload; register;
  function RectI(ACenter: TPGLVec3; AWidth,AHeight: Single): TPGLRectI; overload; register;
  function RectI(ARect: TPGLRectF): TPGLRectI; overload; register;
  function RectIWH(ALeft,ATop,AWidth,AHeight: Single): TPGLRectI; register;

  function RectF(ALeft,ATop,ARight,ABottom: Single): TPGLRectF; overload; register;
  function RectF(ACenter: TPGLVec3; AWidth,AHeight: Single): TPGLRectF; overload; register;
  function RectF(ARect: TPGLRectI): TPGLRectF; overload; register;
  function RectFWH(ALeft,ATop,AWidth,AHeight: Single): TPGLRectF; register;

  function ScaleRect(ARect: TPGLRectF; AXRatio, AYRatio: Single): TPGLRectF; register;

  {* Vectors *}
  function Vec2(AX: Single = 0; AY: Single = 0): TPGLVec2; overload; register;
  function Vec2(AVector: TPGLVec3): TPGLVec2; overload; register;
  function Vec3(AX: Single = 0; AY: Single = 0; AZ: Single = 0): TPGLVec3; register;
  function Vec4(AX: Single = 0; AY: Single = 0; AZ: Single = 0; AW: Single = 0): TPGLVec4; register;
  function Vertex(AVector: TPGLVec3; ATexCoord: TPGLVec3; AColor: TPGLColorF; ANormal: TPGLVec3): TPGLVertex; register;

  function Cross(AVec1, AVec2: TPGLVec3): TPGLVec3; register;
  function Dot(AVec1, AVec2: TPGLVec3): Single; register
  function VectorLength(AVec: TPGLVec3): Single; register;
  function Normal(AVec: TPGLVec3): TPGLVec3; register;
  procedure Normalize(var AVec: TPGLVec3); overload; register;
  procedure Normalize(var AVec: TPGLVec2); overload; register;
  function Direction(APosition: TPGLVec3; ATarget: TPGLVec3): TPGLVec3; register;
  function Right(AUpVector: TPGLVec3; ADirectionVector: TPGLVec3): TPGLVec3; register;
  function Up(ADirectionVector: TPGLVec3; ARightVector: TPGLVec3): TPGLVec3; register;
  function SignedDistance(AVector1, AVector2: TPGLVec3): Single; register;
  procedure ScaleCoord(var AVectors: TArray<TPGLVec3>;  AWidth: Single = 0; AHeight: Single = 0; ADepth: Single = 0); register;
  procedure ScaleNDC(var AVectors: TArray<TPGLVec3>;  AWidth: Single = 0; AHeight: Single = 0; ADepth: Single = 0); register;
  procedure FlipVerticle(var AVectors: TArray<TPGLVec3>); register;
  procedure FlipHorizontal(var AVectors: TArray<TPGLVec3>); register;

  {* Matrices *}
  function MatrixAdjoint(AMatrix: TPGLMat4): TPGLMat4; register; inline;
  function MatrixInverse(AMatrix: TPGLMat4): TPGLMat4; register; inline;
  function MatrixDeterminant(AMatrix: TPGLMat4): Single; register; inline;
  function MatrixScale(AMatrix: TPGLMat4; AFactor: Single): TPGLMat4; register; inline;
  function MatrixNegate(AMatrix: TPGLMat4): TPGLMat4; register; inline;
  function MatrixTranspose(AMatrix: TPGLMat4): TPGLMat4; register; inline;

  {* Cylinder *}
  function Cylinder(ACenter,AUp: TPGLVec3; ARadius,AHeight: Single): TPGLCylinder; register;

  {* Math *}
  function Distance(APoint1, APoint2: TPGLVec3): Single; register;
  function GetAngle(AStart, AEnd: TPGLVec2): Single;  register;
  function InRect(AVec: TPGLVec3; ARect: TPGLRectF): Boolean; register;
  function RectCollision(ARect1,ARect2: TPGLRectF): Boolean; register;
  function InTriangle(ACheckPoint: TPGLVec3; T1,T2,T3: TPGLVec3): Boolean; register;
  function CircleRectCollision(ACircle: TPGLVec3; ARectangle: TPGLRectF): Boolean; register;
  function LineIntersect(Line1Start, Line1End, Line2Start, LIne2End: TPGLVec3; out AIntersection: TPGLVec3): Boolean; register;
  function LineRectIntersect(LineStart, LineEnd: TPGLVec3; ARect: TPGLRectF; out AIntersection: TArray<TPGLVec3>): Boolean; register;
  function LinePlaneIntersect(L1,L2,PP,PN: TPGLVec3; out AIntersect: TPGLVec3): Boolean; register;
  function CylinderCollision(const ACylinder1, ACylinder2: TPGLCylinder): Boolean; register;
  function DetInternal(a1, a2, a3, b1, b2, b3, c1, c2, c3: Single): Single; register;


  {* Transformations *}
  function TransformToView(out AVector: TPGLVec3; ALeft, ATop, ARight, ABottom, ANear, AFar: Single): TPGLVec3; register;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                            Variables and Constants
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

const

  // Size Constants
  ColorISize: Integer = 4;
  ColorFSize: Integer = 16;

  // colors Integer
  pgl_empty: TPGLColorI =         (Red: 0; Green: 0; Blue: 0; Alpha: 0);
  pgl_white: TPGLColorI =         (Red: 255; Green: 255; Blue: 255; Alpha: 255);
  pgl_black: TPGLColorI =         (Red: 0; Green: 0; Blue: 0; Alpha: 255);

  pgl_grey: TPGLColorI =          (Red: 128; Green: 128; Blue: 128; Alpha: 255);
  pgl_light_grey: TPGLColorI =    (Red: 75; Green: 75; Blue: 75; Alpha: 255);
  pgl_dark_grey: TPGLColorI =     (Red: 225; Green: 225; Blue: 225; Alpha: 255);

  pgl_red: TPGLColorI =           (Red: 255; Green: 0; Blue: 0; Alpha: 255);
  pgl_ligh_red: TPGLColorI =      (Red: 255; Green: 125; Blue: 128; Alpha: 255);
  pgl_dark_red: TPGLColorI =      (Red: 128; Green: 0; Blue: 0; Alpha: 255);

  pgl_yellow: TPGLColorI =        (Red: 255; Green: 255; Blue: 0; Alpha: 255);
  pgl_light_yellow: TPGLColorI =  (Red: 255; Green: 255; Blue: 128; Alpha: 255);
  pgl_dark_yellow: TPGLColorI =   (Red: 128; Green: 128; Blue: 0; Alpha: 255);

  pgl_blue: TPGLColorI =          (Red: 0; Green: 0; Blue: 255; Alpha: 255);
  pgl_light_blue: TPGLColorI =    (Red: 128; Green: 128; Blue: 255; Alpha: 255);
  pgl_dark_blue: TPGLColorI =     (Red: 0; Green: 0; Blue: 128; Alpha: 255);

  pgl_green: TPGLColorI =         (Red: 0; Green: 255; Blue: 0; Alpha: 255);
  pgl_light_green: TPGLColorI =   (Red: 128; Green: 255; Blue: 128; Alpha: 255);
  pgl_dark_green: TPGLColorI =    (Red: 0; Green: 128; Blue: 0; Alpha: 255);

  pgl_orange: TPGLColorI =        (Red: 255; Green: 128; Blue: 0; Alpha: 255);
  pgl_light_orange: TPGLColorI =  (Red: 255; Green: 190; Blue: 128; Alpha: 255);
  pgl_dark_orange: TPGLColorI =   (Red: 128; Green: 64; Blue: 0; Alpha: 255);

  pgl_brown: TPGLColorI =         (Red: 128; Green: 64; Blue: 0; Alpha: 255);
  pgl_light_brown: TPGLColorI =   (Red: 180; Green: 90; Blue: 0; Alpha: 255);
  pgl_dark_brown: TPGLColorI =    (Red: 96; Green: 48; Blue: 0; Alpha: 255);

  pgl_purple: TPGLColorI =        (Red: 128; Green: 0; Blue: 128; Alpha: 255);
  pgl_cyan: TPGLColorI =          (Red: 0; Green: 255; Blue: 255; Alpha: 255);
  pgl_magenta: TPGLColorI =       (Red: 255; Green: 0; Blue: 255; Alpha: 255);
  pgl_pink: TPGLColorI =          (Red: 255; Green: 196; Blue: 196; Alpha: 255);

  // colors float
  pgl_empty_f: TPGLColorF =         (Red: 0 / 255; Green: 0 / 255; Blue: 0 / 255; Alpha: 0 / 255);
  pgl_white_f: TPGLColorF =         (Red: 255 / 255; Green: 255 / 255; Blue: 255 / 255; Alpha: 255 / 255);
  pgl_black_f: TPGLColorF =         (Red: 0 / 255; Green: 0 / 255; Blue: 0 / 255; Alpha: 255 / 255);

  pgl_grey_f: TPGLColorF =          (Red: 128 / 255;  Green: 128 / 255;  Blue: 128 / 255;  Alpha: 255 / 255);
  pgl_light_grey_f: TPGLColorF =    (Red: 75 / 255;  Green: 75 / 255;  Blue: 75 / 255;  Alpha: 255 / 255);
  pgl_dark_grey_f: TPGLColorF =     (Red: 225 / 255;  Green: 225 / 255;  Blue: 225 / 255;  Alpha: 255 / 255);

  pgl_red_f: TPGLColorF =           (Red: 255 / 255;  Green: 0 / 255;  Blue: 0 / 255;  Alpha: 255 / 255);
  pgl_ligh_red_f: TPGLColorF =      (Red: 255 / 255;  Green: 125 / 255;  Blue: 128 / 255;  Alpha: 255 / 255);
  pgl_dark_red_f: TPGLColorF =      (Red: 128 / 255;  Green: 0 / 255;  Blue: 0 / 255;  Alpha: 255 / 255);

  pgl_yellow_f: TPGLColorF =        (Red: 255 / 255;  Green: 255 / 255;  Blue: 0 / 255;  Alpha: 255 / 255);
  pgl_light_yellow_f: TPGLColorF =  (Red: 255 / 255;  Green: 255 / 255;  Blue: 128 / 255;  Alpha: 255 / 255);
  pgl_dark_yellow_f: TPGLColorF =   (Red: 128 / 255;  Green: 128 / 255;  Blue: 0 / 255;  Alpha: 255 / 255);

  pgl_blue_f: TPGLColorF =          (Red: 0 / 255;  Green: 0 / 255;  Blue: 255 / 255;  Alpha: 255 / 255);
  pgl_light_blue_f: TPGLColorF =    (Red: 128 / 255;  Green: 128 / 255;  Blue: 255 / 255;  Alpha: 255 / 255);
  pgl_dark_blue_f: TPGLColorF =     (Red: 0 / 255;  Green: 0 / 255;  Blue: 128 / 255;  Alpha: 255 / 255);

  pgl_green_f: TPGLColorF =         (Red: 0 / 255;  Green: 255 / 255;  Blue: 0 / 255;  Alpha: 255 / 255);
  pgl_light_green_f: TPGLColorF =   (Red: 128 / 255;  Green: 255 / 255;  Blue: 128 / 255;  Alpha: 255 / 255);
  pgl_dark_green_f: TPGLColorF =    (Red: 0 / 255;  Green: 128 / 255;  Blue: 0 / 255;  Alpha: 255 / 255);

  pgl_orange_f: TPGLColorF =        (Red: 255 / 255;  Green: 128 / 255;  Blue: 0 / 255;  Alpha: 255 / 255);
  pgl_light_orange_f: TPGLColorF =  (Red: 255 / 255;  Green: 190 / 255;  Blue: 128 / 255;  Alpha: 255 / 255);
  pgl_dark_orange_f: TPGLColorF =   (Red: 128 / 255;  Green: 64 / 255;  Blue: 0 / 255;  Alpha: 255 / 255);

  pgl_brown_f: TPGLColorF =         (Red: 128 / 255;  Green: 64 / 255;  Blue: 0 / 255;  Alpha: 255 / 255);
  pgl_light_brown_f: TPGLColorF =   (Red: 180 / 255;  Green: 90 / 255;  Blue: 0 / 255;  Alpha: 255 / 255);
  pgl_dark_brown_f: TPGLColorF =    (Red: 96 / 255;  Green: 48 / 255;  Blue: 0 / 255;  Alpha: 255 / 255);

  pgl_purple_f: TPGLColorF =        (Red: 128 / 255;  Green: 0 / 255;  Blue: 128 / 255;  Alpha: 255 / 255);
  pgl_cyan_f: TPGLColorF =          (Red: 0 / 255;  Green: 255 / 255;  Blue: 255 / 255;  Alpha: 255 / 255);
  pgl_magenta_f: TPGLColorF =       (Red: 255 / 255;  Green: 0 / 255;  Blue: 255 / 255;  Alpha: 255 / 255);
  pgl_pink_f: TPGLColorF =          (Red: 255 / 255;  Green: 196 / 255;  Blue: 196 / 255;  Alpha: 255 / 255);

  // rects
  from_center: Integer = 0;
  from_left: Integer  = 1;
  from_top: Integer  = 2;
  from_right: Integer  = 3;
  from_bottom: Integer  = 4;

  // other
  camera_type_2D: Integer = 0;
  camera_type_3D: Integer = 1;

implementation

uses
  PGLMain, PGLMath; // for access to TPGLInstance and PGL state object

function ColorF(R,G,B: Single; A: Single = 1): TPGLColorF;
  begin
    Result.Red := ClampF(R);
    Result.Green := ClampF(G);
    Result.Blue := ClampF(B);
    Result.Alpha := ClampF(A);
  end;

function ColorF(AColorI: TPGLColorI): TPGLColorF;
  begin
    Result := AColorI.toColorF;
  end;

function ColorI(R,G,B: Single; A: Single = 255): TPGLColorI;
  begin
    Result.Red := ClampI(R);
    Result.Green := ClampI(G);
    Result.Blue := ClampI(B);
    Result.Alpha := ClampI(A);
  end;

function ColorI(AColorF: TPGLColorF): TPGLColorI;
  begin
    Result := AColorF.toColorI;
  end;


function GetColorIncrements(AStartColor, AEndColor: TPGLColorF; AIncrements: Cardinal): TPGLVec4;
var
RedChange,GreenChange,BlueChange,AlphaChange: Single;
RedDiff,GreenDiff,BlueDiff,AlphaDiff: Single;
  begin
    RedDiff := AEndColor.Red - AStartColor.Red;
    GreenDiff := AEndColor.Green - AStartColor.Green;
    BlueDiff := AEndColor.Blue - AStartColor.Blue;
    AlphaDiff := AEndColor.Alpha - AStartColor.Alpha;
    RedChange := RedDiff / AIncrements;
    GreenChange := GreenDiff / AIncrements;
    BlueChange := BlueDiff / AIncrements;
    AlphaChange := AlphaDiff / AIncrements;
    Result := Vec4(RedChange,GreenChange,BlueChange,AlphaChange);
  end;


function RectI(ALeft,ATop,ARight,ABottom: Integer): TPGLRectI;
  begin
    Result.fLeft := ALeft;
    Result.fTop := ATop;
    Result.fRight := ARight;
    Result.fBottom := ABottom;
    Result.fWidth := ARight - ALeft + 1;
    Result.fHeight := ABottom - ATop + 1;
    Result.fX := ALeft + trunc(Result.fWidth / 2);
    Result.fY := ATop + trunc(Result.fHeight / 2);
  end;

function RectI(ACenter: TPGLVec3; AWidth,AHeight: Single): TPGLRectI;
  begin
    Result.fWidth := trunc(AWidth);
    Result.fHeight := trunc(AHeight);
    Result.SetCenter(ACenter.X, ACenter.Y, ACenter.Z);
  end;

function RectI(ARect: TPGLRectF): TPGLRectI;
  begin
    Result.fWidth := trunc(ARect.Width);
    Result.fHeight := trunc(ARect.Height);
    Result.SetCenter(ARect.X, ARect.Y, ARect.Z);
  end;

function RectIWH(ALeft,ATop,AWidth,AHeight: single): TPGLRectI;
  begin
    Result.fLeft := Trunc(ALeft);
    Result.fTop := Trunc(ATop);
    Result.fWidth := Trunc(AWidth);
    Result.fHeight := Trunc(AHeight);
    Result.fRight := Trunc(ALeft + (AWidth));
    Result.fBottom := Trunc(ATop + (AHeight));
    Result.fX := Trunc(ALeft + (AWidth / 2));
    Result.fY := Trunc(ATop + (AHeight / 2));
  end;

function RectF(ALeft,ATop,ARight,ABottom: Single): TPGLRectF;
  begin
    Result.fLeft := ALeft;
    Result.fTop := ATop;
    Result.fRight := ARight;
    Result.fBottom := ABottom;
    Result.fWidth := ARight - ALeft;
    Result.fHeight := ABottom - ATop;
    Result.fX := ALeft + (Result.fWidth / 2);
    Result.fY := ATop + (Result.fHeight / 2);
  end;

 function RectF(ACenter: TPGLVec3; AWidth,AHeight: Single): TPGLRectF;
  begin
    Result.fWidth := (AWidth);
    Result.fHeight := (AHeight);
    Result.SetCenter(ACenter);
  end;

function RectF(ARect: TPGLRectI): TPGLRectF;
  begin

  end;

function RectFWH(ALeft,ATop,AWidth,AHeight: Single): TPGLRectF;
  begin
    Result.fLeft := ALeft;
    Result.fTop := ATop;
    Result.fWidth := AWidth;
    Result.fHeight := AHeight;
    Result.fRight := ALeft + (AWidth);
    Result.fBottom := ATop + (AHeight);
    Result.fX := ALeft + (AWidth / 2);
    Result.fY := ATop + (AHeight / 2);
    Result.fZ := 0;
  end;

function ScaleRect(ARect: TPGLRectF; AXRatio, AYRatio: Single): TPGLRectF;
var
NewX,NewY,NewWidth,NewHeight: Single;
  begin
    NewX := ARect.Left * AXRatio;
    NewY := ARect.Top * AYRatio;
    NewWidth := ARect.width * AXRatio;
    NewHeight := ARect.Height * AYRatio;
    Result := RectFWH(NewX,NewY,NewWidth,NewHeight);
  end;


{* Vectors *}
function Vec2(AX: Single = 0; AY: Single = 0): TPGLVec2;
  begin
    Result.X := AX;
    Result.Y := AY;
  end;

function Vec2(AVector: TPGLVec3): TPGLVec2;
  begin
    Result.X := AVector.X;
    Result.Y := AVector.Y;
  end;

function Vec3(AX: Single = 0; AY: Single = 0; AZ: Single = 0): TPGLVec3;
  begin
    Result.X := AX;
    Result.Y := AY;
    Result.Z := AZ;
  end;

function Vec4(AX: Single = 0; AY: Single = 0; AZ: Single = 0; AW: Single = 0): TPGLVec4;
  begin
    Result.X := AX;
    Result.Y := AY;
    Result.Z := AZ;
    Result.W := AW;
  end;

function Vertex(AVector: TPGLVec3; ATexCoord: TPGLVec3; AColor: TPGLColorF; ANormal: TPGLVec3): TPGLVertex;
  begin
    Result.Vector := AVector;
    Result.TexCoord := ATexCoord;
    Result.Color := AColor;
    Result.Normal := ANormal;
  end;

function Cross(AVec1, AVec2: TPGLVec3): TPGLVec3;
  begin
    Result.X := (AVec1.Y * AVec2.Z) - (AVec1.Z * AVec2.Y);
    Result.Y := (AVec1.Z * AVec2.X) - (AVec1.X * AVec2.Z);
    Result.Z := (AVec1.X * AVec2.Y) - (AVec1.Y * AVec2.X);
  end;

function Dot(AVec1, AVec2: TPGLVec3): Single;
  begin
    Result := (AVec1.X * AVec2.X) + (AVec1.Y * AVec2.Y) + (AVec1.Z * AVec2.Z);
  end;

function VectorLength(AVec: TPGLVec3): Single;
  begin
    Result := Sqrt( (AVec.X * AVec.X) + (AVec.Y * AVec.Y) + (AVec.Z * AVec.Z) );
  end;

function Normal(AVec: TPGLVec3): TPGLVec3;
  begin
    Result := AVec;
    Normalize(Result);
  end;

procedure Normalize(var AVec: TPGLVec3);
var
Len: Single;
  begin
    Len := VectorLength(AVec);
    AVec.X := AVec.X / Len;
    AVec.Y := AVec.Y / Len;
    AVec.Z := AVec.Z / Len;
  end;

procedure Normalize(var AVec: TPGLVec2);
var
Len: Single;
  begin
    Len := VectorLength(AVec);
    AVec.X := AVec.X / Len;
    AVec.Y := AVec.Y / Len;
  end;

function Direction(APosition: TPGLVec3; ATargeT: TPGLVec3): TPGLVec3;
  begin
    Result := Normal(APosition - ATarget);
  end;

function Right(AUpVector: TPGLVec3; ADirectionVector: TPGLVec3): TPGLVec3;
  begin
    Result := Normal(Cross(AUpVector,ADirectionVector));
  end;

function Up(ADirectionVector: TPGLVec3; ARightVector: TPGLVec3): TPGLVec3;
  begin
    Result := Cross(ADirectionVector, ARightVector);
  end;

function SignedDistance(AVector1, AVector2: TPGLVec3): Single;
  begin
    Result := VectorLength(AVector1 - AVector2) * Sign(Dot(AVector1, AVector2));
  end;

procedure ScaleCoord(var AVectors: TArray<TPGLVec3>; AWidth: Single = 0; AHeight: Single = 0; ADepth: Single = 0);
var
Len: Integer;
I: Integer;
  begin
    Len := Length(AVectors);

    for I := 0 to Len - 1 do begin
      AVectors[i].X := AVectors[i].X / AWidth;
      AVectors[i].Y := AVectors[i].Y / AHeight;
      AVectors[i].Z := AVectors[i].Z / ADepth;
    end;

  end;

procedure ScaleNDC(var AVectors: TArray<TPGLVec3>; AWidth: Single = 0; AHeight: Single = 0; ADepth: Single = 0);
var
Len: Integer;
I: Integer;
  begin
    Len := Length(AVectors);

    for I := 0 to Len - 1 do begin
      AVectors[i].X := -1 + ((AVectors[i].X / AWidth) * 2);
      AVectors[i].Y := -1 + ((AVectors[i].Y / AHeight) * 2);
      AVectors[i].Z := -1 + ((AVectors[i].Z / ADepth) * 2);
    end;

  end;

procedure FlipVerticle(var AVectors: TArray<TPGLVec3>);
var
Low,High,Middle,Diff: Single;
I: Integer;
  begin

    Low := AVectors[0].Y;
    High := Low;

    for I := 1 to Length(AVectors) - 1 do begin
      if AVectors[i].Y < Low then Low := AVectors[i].Y;
      if AVectors[i].Y > High then High := AVectors[i].Y;
    end;

    Middle := Low + ((High - Low) / 2);

    for I := 0 to Length(AVectors) - 1 do begin
      Diff := AVectors[i].Y - Middle;
      AVectors[i].Y := Middle + (Diff * -1);
    end;

  end;

procedure FlipHorizontal(var AVectors: TArray<TPGLVec3>);
var
Low,High,Middle,Diff: Single;
I: Integer;
  begin

    Low := 0;
    High := 0;

    for I := 0 to Length(AVectors) - 1 do begin
      if AVectors[i].X < Low then Low := AVectors[i].X;
      if AVectors[i].X > High then High := AVectors[i].X;
    end;

    Middle := Low + ((High - Low) / 2);

    for I := 0 to Length(AVectors) - 1 do begin
      Diff := AVectors[i].X - Middle;
      AVectors[i].X := Middle + (Diff * -1);
    end;

  end;


{* Matrices *}
function MatrixAdjoint(AMatrix: TPGLMat4): TPGLMat4;
var
a1, a2, a3, a4, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4: Single;
  begin
    a1 := AMatrix.M[0,0];
    b1 := AMatrix.M[0,1];
    c1 := AMatrix.M[0,2];
    d1 := AMatrix.M[0,3];
    a2 := AMatrix.M[1,0];
    b2 := AMatrix.M[1,1];
    c2 := AMatrix.M[1,2];
    d2 := AMatrix.M[1,3];
    a3 := AMatrix.M[2,0];
    b3 := AMatrix.M[2,1];
    c3 := AMatrix.M[2,2];
    d3 := AMatrix.M[2,3];
    a4 := AMatrix.M[3,0];
    b4 := AMatrix.M[3,1];
    c4 := AMatrix.M[3,2];
    d4 := AMatrix.M[3,3];

    Result.M[0,0] := DetInternal(b2, b3, b4, c2, c3, c4, d2, d3, d4);
    Result.M[1,0] := -DetInternal(a2, a3, a4, c2, c3, c4, d2, d3, d4);
    Result.M[2,0] := DetInternal(a2, a3, a4, b2, b3, b4, d2, d3, d4);
    Result.M[3,0] := -DetInternal(a2, a3, a4, b2, b3, b4, c2, c3, c4);

    Result.M[0,1] := -DetInternal(b1, b3, b4, c1, c3, c4, d1, d3, d4);
    Result.M[1,1] := DetInternal(a1, a3, a4, c1, c3, c4, d1, d3, d4);
    Result.M[2,1] := -DetInternal(a1, a3, a4, b1, b3, b4, d1, d3, d4);
    Result.M[3,1] := DetInternal(a1, a3, a4, b1, b3, b4, c1, c3, c4);

    Result.M[0,2] := DetInternal(b1, b2, b4, c1, c2, c4, d1, d2, d4);
    Result.M[1,2] := -DetInternal(a1, a2, a4, c1, c2, c4, d1, d2, d4);
    Result.M[2,2] := DetInternal(a1, a2, a4, b1, b2, b4, d1, d2, d4);
    Result.M[3,2] := -DetInternal(a1, a2, a4, b1, b2, b4, c1, c2, c4);

    Result.M[0,3] := -DetInternal(b1, b2, b3, c1, c2, c3, d1, d2, d3);
    Result.M[1,3] := DetInternal(a1, a2, a3, c1, c2, c3, d1, d2, d3);
    Result.M[2,3] := -DetInternal(a1, a2, a3, b1, b2, b3, d1, d2, d3);
    Result.M[3,3] := DetInternal(a1, a2, a3, b1, b2, b3, c1, c2, c3);
  end;


function MatrixInverse(AMatrix: TPGLMat4): TPGLMat4;
var
Det: Single;
Default: TPGLMat4;
  begin
    Det := MatrixDeterminant(AMatrix);
    if Abs(Det) < Epsilon then
      Result := Default
    else
      Result := MatrixScale(MatrixAdjoint(AMatrix), 1/ Det);
  end;


function MatrixDeterminant(AMatrix: TPGLMat4): Single;
  begin
    Result :=
      AMatrix.M[0,0] * DetInternal(AMatrix.M[1,1], AMatrix.M[2,1], AMatrix.M[3,1], AMatrix.M[1,2],
      AMatrix.M[2,2], AMatrix.M[3,2], AMatrix.M[1,3], AMatrix.M[2,3], AMatrix.M[3,3])
      - AMatrix.M[0,1] * DetInternal(AMatrix.M[1,0], AMatrix.M[2,0], AMatrix.M[3,0], AMatrix.M[1,2], AMatrix.M[2,2],
      AMatrix.M[3,2], AMatrix.M[1,3], AMatrix.M[2,3], AMatrix.M[3,3])
      + AMatrix.M[0,2] * DetInternal(AMatrix.M[1,0], AMatrix.M[2,0], AMatrix.M[3,0], AMatrix.M[1,1], AMatrix.M[2,1],
      AMatrix.M[3,1], AMatrix.M[1,3], AMatrix.M[2,3], AMatrix.M[3,3])
      - AMatrix.M[0,3] * DetInternal(AMatrix.M[1,0], AMatrix.M[2,0], AMatrix.M[3,0], AMatrix.M[1,1], AMatrix.M[2,1],
      AMatrix.M[3,1], AMatrix.M[1,2], AMatrix.M[2,2], AMatrix.M[3,2]);
  end;


function MatrixScale(AMatrix: TPGLMat4; AFactor: Single): TPGLMat4;
var
I: Integer;
  begin
    for I := 0 to 2 do
    begin
      Result.M[I,0] := AMatrix.M[I,0] * AFactor;
      Result.M[I,1] := AMatrix.M[I,1] * AFactor;
      Result.M[I,2] := AMatrix.M[I,2] * AFactor;
      Result.M[I,3] := AMatrix.M[I,3] * AFactor;
    end;
  end;


function MatrixNegate(AMatrix: TPGLMat4): TPGLMat4;
var
I,Z: Integer;
  begin
    for I := 0 to 3 do begin
      for Z := 0 to 3 do begin
        Result.M[I,Z] := -AMatrix.M[I,Z];
      end;
    end;
  end;

function MatrixTranspose(AMatrix: TPGLMat4): TPGLMat4;
  begin
    Result := AMatrix;
    Result.Transpose();
  end;

function Cylinder(ACenter,AUp: TPGLVec3; ARadius,AHeight: Single): TPGLCylinder;
  begin
    Result.fRadius := ARadius;
    Result.fHeight := AHeight;
    Result.fUp := AUp;
    Result.SetCenter(ACenter);
  end;

function Distance(APoint1, APoint2: TPGLVec3): Single;
  begin
    Result := Sqrt( IntPower(APoint1.X - APoint2.X, 2) + IntPower(APoint1.Y - APoint2.Y, 2) + IntPower(APoint1.Z - APoint2.Z, 2) );
  end;

function GetAngle(AStart, AEnd: TPGLVec2): Single;
  begin
    Result := ArcTan2(AEnd.Y - AStart.Y, AEnd.X - AStart.X);
  end;

function InRect(AVec: TPGLVec3; ARect: TPGLRectF): Boolean;
  begin

    Result := False;

    if (Avec.X >= ARect.Left) and
      (AVec.X <= ARect.Right) and
      (AVec.Y >= ARect.Top) and
      (AVec.Y <= ARect.Bottom) then begin
        Result := True;
    end;

  end;

function RectCollision(ARect1,ARect2: TPGLRectF): Boolean;
var
DiffWidth,ComWidth: Single;
  begin
    Result := False;

    DiffWidth := abs(ARect1.X - ARect2.X);
    ComWidth := (ARect1.Width / 2) + (ARect2.Width / 2);
    if DiffWidth < ComWidth then begin

      DiffWidth := abs(ARect1.Y- ARect2.Y);
      ComWidth := (ARect1.Height / 2) + (ARect2.Height / 2);
      if DiffWidth < ComWidth then begin
        Result := True;
      end;
    end;
  end;

function InTriangle(ACheckPoint: TPGLVec3; T1,T2,T3: TPGLVec3): Boolean;
var
A,B,C: Single;
  begin
    Result := False;

    a := ((T2.Y - T3.Y)*(ACheckPoint.X - T3.X) + (T3.X - T2.X)*(ACheckPoint.Y - T3.Y)) / ((T2.Y - T3.Y)*(T1.x - T3.X) + (T3.X - T2.X)*(T1.Y - T3.Y));
    b := ((T3.Y - T1.Y)*(ACheckPoint.X - T3.X) + (T1.x - T3.X)*(ACheckPoint.Y - T3.Y)) / ((T2.Y - T3.Y)*(T1.x - T3.X) + (T3.X - T2.X)*(T1.Y - T3.Y));
    c := 1 - a - b;

    if (A >= 0) and (A <= 1) and (B >= 0) and (B <= 1) and (C >= 0) and (C <= 1) then begin
      Result := True;
    end;
  end;


function CircleRectCollision(ACircle: TPGLVec3; ARectangle: TPGLRectF): Boolean;
// ACircle is represented by a TPGLVec3 in that X and Y represent the center of the circle
// and Z represents the radius of the circle;
var
Closest: TPGLVec2;
  begin

    result := false;

    // first, check if the center of the circle is in the rectangle
    if InRect(ACircle, ARectangle) then begin
      result := true;
      exit;
    end;

    // if not, calculate closest point of rectangle to center of circle
    // if closest point is within Radius distance, we have collision

    Closest.X := Max(ARectangle.X1,Min(ACircle.X, ARectangle.X2));
    Closest.Y := Max(ARectangle.Y1,Min(ACircle.Y, ARectangle.Y2));

    if Distance(Closest, TPGLVec2(ACircle)) <= ACircle.Z then begin
      Result := true;
    end;

  end;


function LineIntersect(Line1Start, Line1End, Line2Start, LIne2End: TPGLVec3; out AIntersection: TPGLVec3): Boolean;
var
uA, uB: Single;
  begin

    Result := false;

    uA := ((Line2End.X-Line2Start.X)*(Line1Start.Y-Line2Start.Y) -
          (Line2End.Y-Line2Start.Y)*(Line1Start.X-Line2Start.X)) / ((Line2End.Y-Line2Start.Y)*(Line1End.X-Line1Start.x) -
          (Line2End.X-Line2Start.X)*(Line1End.Y-Line1Start.Y));

    uB := ((Line1end.X-Line1Start.X)*(Line1Start.Y-Line2Start.Y) -
          (Line1end.Y-Line1Start.Y)*(Line1Start.X-Line2Start.X)) / ((Line2End.Y-Line2Start.Y)*(Line1End.X-Line1Start.X) -
          (Line2End.X-Line2Start.X)*(Line1End.y-Line1Start.y));

    if (uA >= 0) and (uA <= 1) and (uB >= 0) and (uB <= 1) then begin
      Result := True;
      AIntersection.X := Line1Start.X + (uA * (Line1End.X-Line1Start.X));
      AIntersection.Y := Line1Start.Y + (uA * (Line1End.y-Line1Start.Y));
    end;
  end;


function LineRectIntersect(LineStart, LineEnd: TPGLVec3; ARect: TPGLRectF; out AIntersection: TArray<TPGLVec3>): Boolean; register;
var
RectPoint1, RectPoint2: TPGLVec3;
I: Integer;
CurDist: Single;
OutPoint: TPGLVec3;
SendPoints: TArray<TPGLVec3>;
OldDist: Single;
  begin

    Result := False;
    CurDist := 0;
    OldDist := 0;

    for I := 0 to 3 do begin

      case I of

        0: // left
          begin
            RectPoint1 := ARect.TopLeft;
            RectPoint2 := ARect.BottomLeft;
          end;

        1: // right
          begin
            RectPoint1 := Arect.TopRight;
            RectPoint2 := Arect.BottomRight;
          end;

        2: // top
          begin
            RectPoint1 := ARect.TopLeft;
            RectPoint2 := ARect.TopRight;
          end;

        3: // bottom
          begin
            RectPoint1 := ARect.BottomLeft;
            RectPoint2 := ARect.BottomRight;
          end;

      end;


      if LineIntersect(LineStart,LineEnd,RectPoint1,RectPoint2,OutPoint) then begin
        Result := True;
        SetLength(SendPoints, Length(SendPoints) + 1);
        SendPoints[High(SendPoints)] := OutPoint;
      end;

    end;


    AIntersection := SendPoints;

  end;


function LinePlaneIntersect(L1,L2,PP,PN: TPGLVec3; out AIntersect: TPGLVec3): Boolean;
var
U,W: TPGLVec3;
DotVal: Single;
Fac: Single;
  begin
    // p0, p1: Define the line.
    // p_co, p_no: define the plane:
    // p_co Is a point on the plane (plane coordinate).
    // p_no Is a normal vector defining the plane direction;
    // (does not need to be normalized).

    // Return a Vector or None (when the intersection can't be found).

    Result := false;

    U := L2 - L1;
    DotVal := Dot(PN, U);

    if (abs(DotVal) > epsilon) then begin
        // The factor of the point between p0 -> p1 (0 - 1)
        // if 'fac' is between (0 - 1) the point intersects with the segment.
        // Otherwise:
        //  < 0.0: behind p0.
        //  > 1.0: infront of p1.
        W := L1 - PP;
        Fac := -Dot(PN, W) / DotVal;

        if (Fac < 0) or (Fac > 1) then begin
          result := false;
          Exit;
        end;

        U := U * Fac;
        AIntersect := L1 + U;
        Result := True;

    end else begin
      //The segment is parallel to plane.
      Result := False;
    end;
  end;


function CylinderCollision(const ACylinder1, ACylinder2: TPGLCylinder): Boolean; register;
var
CheckC1, CheckC2: TPGLCylinder;
OutPoint: TPGLVec3;
CheckPoint: TPGLVec3;
ComWidth: Single;
Right: TPGLVec3;
  begin
    Result := False;

    CheckC1 := ACylinder1;
    CheckC2 := ACylinder2;

    CheckC2.SetUpVector(CheckC2.fUp - (CheckC1.fUp * Dot(CheckC2.fUp, CheckC1.fUp)) );
    CheckC1.SetUpVector(Vec3(0,1,0));

    Right := Vec3(0,0,CheckC2.fUp.Y);

    CheckPoint := CheckC1.Top;

    if LinePlaneIntersect(CheckC2.Bottom, CheckC2.Top, CheckC1.Top, CheckC1.fUp, OutPoint) = False then begin
      CheckPoint := CheckC1.Bottom;
      if LinePlaneIntersect(CheckC2.Bottom, CheckC2.Top, CheckC1.Bottom, CheckC1.fUp, OutPoint) = False then begin
        Exit;
      end;
    end;

    ComWidth := CheckC1.Radius + CheckC2.Radius;
    if Distance(OutPoint, CheckPoint) <= ComWidth then begin
      Result := True;
    end;

  end;


function DetInternal(a1, a2, a3, b1, b2, b3, c1, c2, c3: Single): Single;
  begin
    Result := a1 * (b2 * c3 - b3 * c2) - b1 * (a2 * c3 - a3 * c2) + c1 * (a2 * b3 - a3 * b2);
  end;


function TransformToView(out AVector: TPGLVec3; ALeft, ATop, ARight, ABottom, ANear, AFar: Single): TPGLVec3;
  begin

    // calculating the point on viewport
    Result.X := 0.5 * (AVector.X + 1) * (ARight - ALeft);
    Result.Y := 0.5 * (AVector.Y + 1) * (ABottom - ATop);
    Result.Z := 0.5 * (AVector.Z + 1) * (AFar - ANear);

    AVector := Result;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   FloatClamp
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLColorF
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

function TPGLColorF.Inverse: TPGLColorF;
  begin
    Result.Red := 1 - Self.Red;
    Result.Green := 1 - Self.Green;
    Result.Blue := 1 - Self.Blue;
  end;

function TPGLColorF.ToString: String;
  begin
    Result := Self.Red.ToString + ', ' + Self.Green.ToString + ', ' + Self.Blue.ToString + ', ' + Self.Alpha.ToString;
  end;

procedure TPGLColorF.Lighten(AValue: Single);
var
Brightness: Single;
  begin
    // TO-DO
  end;

function TPGLColorF.ToGrey(): TPGLColorF; register;
var
Value: Single;
  begin
    Value := ClampF((Self.Red * 0.2126) + (Self.Green * 0.7152) + (Self.Blue * 0.0722));
    Result := ColorF(Value, Value, Value, Self.Alpha);
  end;

function TPGLColorFHelper.toColorI: TPGLColorI;
  begin
    Result.Red := ClampI(Self.Red * 255);
    Result.Green := ClampI(Self.Green * 255);
    Result.Blue := ClampI(Self.Blue * 255);
    Result.Alpha := ClampI(Self.Alpha * 255);
  end;

class operator TPGLColorFHelper.Equal(Color1: TPGLColorF; Color2: TPGLColorF): Boolean;
var
Diff: Single;
  begin
    Result := False;

    // exit and return false if any components fall outside of thresholdrange
    Diff := abs(Color1.Red - Color2.Red);
    if Diff > PGL.ColorCompareThreshold then exit;

    Diff := abs(COlor1.Green - Color2.Green);
    if Diff > PGL.ColorCompareThreshold then exit;

    Diff := abs(COlor1.Blue - Color2.Blue);
    if Diff > PGL.ColorCompareThreshold then exit;

    Diff := abs(COlor1.Alpha - Color2.Alpha);
    if Diff > PGL.ColorCompareThreshold then exit;

    Result := True;

  end;

class operator TPGLColorFHelper.Equal(ColorF: TPGLColorF; ColorI: TPGLColorI): Boolean;
var
Diff: Single;
  begin
    Result := False;

    // exit and return false if any components fall outside of thresholdrange
    Diff := abs((ColorF.Red * 255) - ColorI.Red) / 255;
    if Diff > PGL.ColorCompareThreshold then exit;

    Diff := abs((ColorF.Green * 255) - ColorI.Green) / 255;
    if Diff > PGL.ColorCompareThreshold then exit;

    Diff := abs((ColorF.Blue * 255) - ColorI.Blue) / 255;
    if Diff > PGL.ColorCompareThreshold then exit;

    Diff := abs((ColorF.Alpha * 255) - ColorI.Alpha) / 255;
    if Diff > PGL.ColorCompareThreshold then exit;

    Result := True;

  end;

class operator TPGLColorFHelper.NotEqual(A,B: TPGLColorF): Boolean;
  begin
    Result := False;
    if (A.Red <> B.Red) or (A.Green <> B.Green) or (A.Blue <> B.Blue) or (A.Alpha <> B.Alpha) then begin
      Result := True;
    end;
  end;

class operator TPGLColorFHelper.Implicit(ColorI: TPGLColorI): TPGLColorF;
  begin
    Result.Red := ClampF(ColorI.Red / 255);
    Result.Green := ClampF(ColorI.Green / 255);
    Result.Blue := ClampF(ColorI.Blue / 255);
    Result.Alpha := ClampF(ColorI.Alpha / 255);
  end;

class operator TPGLColorFHelper.Implicit(AData: Pointer): TPGLColorF;
  begin
    Move(AData^, Result, ColorFSize);
  end;

class operator TPGLColorFHelper.Implicit(AColor: Cardinal): TPGLColorF;
var
Ptr: PByte;
  begin
    // convert 32 bit integer value into ColorI. This assumes a COLORREF created from
    // the RGB windows macro

    // Set Pointer to the interger
    Ptr := @AColor;

    // Assign each byte to the corresponding field of TPGLColorI;
    Result.Red := (Ptr[0]) / 255;
    Result.Green := (Ptr[1]) / 255;
    Result.Blue := (Ptr[2]) / 255;
    Result.Alpha := (Ptr[3]) / 255
  end;

class operator TPGLColorFHelper.Implicit(AColor: TPGLColorF): Cardinal;
var
RPtr: PByte;
  begin
    // convert TPGLColorF to 32 bit Uint
    RPtr := @Result;
    RPtr[0] := trunc(AColor.Red * 255);
    RPtr[1] := trunc(AColor.Green * 255);
    RPtr[2] := trunc(AColor.Blue * 255);
    RPtr[3] := trunc(AColor.Alpha * 255);
  end;

class operator TPGLColorFHelper.Implicit(AVector: TPGLVec4): TPGLColorF;
  begin
    Result.Red := ClampF(AVector.X);
    Result.Green := ClampF(AVector.Y);
    Result.Blue := ClampF(AVector.Z);
    Result.Alpha := ClampF(AVector.W);
  end;

class operator TPGLColorFHelper.Explicit(AData: Pointer): TPGLColorF;
  begin
    Move(AData^, Result, ColorFSize);
  end;

class operator TPGLColorFHelper.Explicit(AVector: TPGLVec4): TPGLColorF;
  begin
    Result.Red := ClampF(AVector.X);
    Result.Green := ClampF(AVector.Y);
    Result.Blue := ClampF(AVector.Z);
    Result.Alpha := ClampF(AVector.W);
  end;

class operator TPGLColorFHelper.Add(A,B: TPGLColorF): TPGLColorF;
  begin
    Result.Red := ClampF(A.Red + B.Red);
    Result.Green := ClampF(A.Green + B.Green);
    Result.Blue := ClampF(A.Blue + B.Blue);
    Result.Alpha := ClampF(A.Alpha + B.Alpha);
  end;

class operator TPGLColorFHelper.Add(A: TPGLColorF; B: TPGLVec4): TPGLColorF;
  begin
    Result.Red := ClampF(A.Red + B.X);
    Result.Green := ClampF(A.Green + B.Y);
    Result.Blue := ClampF(A.Blue + B.Z);
    Result.Alpha := ClampF(A.Alpha + B.W);
  end;

class operator TPGLColorFHelper.Subtract(A,B: TPGLColorF): TPGLColorF;
  begin
    Result.Red := ClampF(A.Red - B.Red);
    Result.Green := ClampF(A.Green - B.Green);
    Result.Blue := ClampF(A.Blue - B.Blue);
    Result.Alpha := ClampF(A.Alpha - B.Alpha);
  end;

class operator TPGLColorFHelper.Subtract(A: TPGLColorF; B: TPGLVec4): TPGLColorF;
  begin
    Result.Red := ClampF(A.Red - B.X);
    Result.Green := ClampF(A.Green - B.Y);
    Result.Blue := ClampF(A.Blue - B.Z);
    Result.Alpha := ClampF(A.Alpha - B.W);
  end;

class operator TPGLColorFHelper.Multiply(A: TPGLColorF; B: Single): TPGLColorF;
  begin
    Result.Red := ClampF(A.Red * B);
    Result.Green := ClampF(A.Green * B);
    Result.Blue := ClampF(A.Blue * B);
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLColorI
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

function TPGLColorI.Inverse: TPGLColorF;
  begin
    Result.Red := 255 - Self.Red;
    Result.Green := 255 - Self.Green;
    Result.Blue := 255 - Self.Blue;
  end;

function TPGLColorI.ToString: String;
  begin
    Result := Self.Red.ToString + ', ' + Self.Green.ToString + ', ' + Self.Blue.ToString + ', ' + Self.Alpha.ToString;
  end;

function TPGLColorI.ToGrey(): TPGLColorI;
var
Value: Single;
  begin
    Value := ClampI((Self.Red * 0.2126) + (Self.Green * 0.7152) + (Self.Blue * 0.0722));
    Result := ColorI(Value, Value, Value, Self.Alpha);
  end;


function TPGLColorIHelper.toColorF: TPGLColorF;
  begin
    Result.Red := ClampF(Self.Red / 255);
    Result.Green := ClampF(Self.Green / 255);
    Result.Blue := ClampF(Self.Blue / 255);
    Result.Alpha := ClampF(Self.Alpha / 255);
  end;

class operator TPGLColorIHelper.Equal(Color1: TPGLColorI; Color2: TPGLColorI): Boolean;
var
Diff: Single;
  begin

  Result := False;

  // exit and return false if any components fall outside of thresholdrange
  Diff := Abs(Color1.Red - Color2.Red) / 255;
  if Diff > PGL.ColorCompareThreshold then exit;

  Diff := Abs(Color1.Green - Color2.Green) / 255;
  if Diff > PGL.ColorCompareThreshold then exit;

  Diff := Abs(Color1.Blue - Color2.Blue) / 255;
  if Diff > PGL.ColorCompareThreshold then exit;

  Diff := Abs(Color1.Alpha - Color2.Alpha) / 255;
  if Diff > PGL.ColorCompareThreshold then exit;

  Result := True;

  end;

class operator TPGLColorIHelper.Equal(ColorI: TPGLColorI; ColorF: TPGLColorF): Boolean;
var
Diff: Single;
  begin

  Result := False;

  // exit and return false if any components fall outside of thresholdrange
  Diff := Abs(ColorI.Red - (ColorF.Red * 255)) / 255;
  if Diff > PGL.ColorCompareThreshold then exit;

  Diff := Abs(ColorI.Green - (ColorF.Green * 255)) / 255;
  if Diff > PGL.ColorCompareThreshold then exit;

  Diff := Abs(ColorI.Blue - (ColorF.Blue * 255)) / 255;
  if Diff > PGL.ColorCompareThreshold then exit;

  Diff := Abs(ColorI.Alpha - (ColorF.Alpha * 255)) / 255;
  if Diff > PGL.ColorCompareThreshold then exit;

  Result := True;

  end;

class operator TPGLColorIHelper.Implicit(ColorF: TPGLColorF): TPGLColorI;
  begin
    Result.Red := ClampI(ColorF.Red * 255);
    Result.Green := ClampI(ColorF.Green * 255);
    Result.Blue := ClampI(ColorF.Blue * 255);
    Result.Alpha := ClampI(ColorF.Alpha * 255);
  end;

class operator TPGLColorIHelper.Implicit(AData: Pointer): TPGLColorI;
  begin
    Move(AData^, Result, ColorISize);
  end;

class operator TPGLColorIHelper.Implicit(AColor: Cardinal): TPGLColorI;
var
Ptr: PByte;
  begin
    // convert 32 bit integer value into ColorI. This assumes a COLORREF created from
    // the RGB windows macro

    // Set Pointer to the interger
    Ptr := @ AColor;

    // Assign each byte to the corresponding field of TPGLColorI;
    Result.Red := Ptr[0];
    Result.Green := Ptr[1];
    Result.Blue := Ptr[2];
    Result.Alpha := Ptr[3];
  end;

class operator TPGLColorIHelper.Implicit(AColor: TPGLColorI): Cardinal;
var
RPtr: PByte;
  begin
    // convert TPGLColorF to 32 bit Uint
    RPtr := @Result;
    Move(AColor, RPtr[0], 4);
  end;

class operator TPGLColorIHelper.Explicit(AData: Pointer): TPGLColorI;
  begin
    Move(AData^, Result, ColorISize);
  end;

class operator TPGLColorIHelper.Add(A,B: TPGLColorI): TPGLColorI;
  begin
    Result.Red := ClampI(A.Red + B.Red);
    Result.Green := ClampI(A.Green + B.Green);
    Result.Blue := ClampI(A.Blue + B.Blue);
    Result.Alpha := ClampI(A.Alpha + B.Alpha);
  end;

class operator TPGLColorIHelper.Add(A: TPGLColorI; B: TPGLVec4): TPGLColorI;
  begin
    Result.Red := ClampI(A.Red + B.X);
    Result.Green := ClampI(A.Green + B.Y);
    Result.Blue := ClampI(A.Blue + B.Z);
    Result.Alpha := ClampI(A.Alpha + B.W);
  end;

class operator TPGLColorIHelper.Subtract(A,B: TPGLColorI): TPGLColorI;
  begin
    Result.Red := ClampI(A.Red - B.Red);
    Result.Green := ClampI(A.Green - B.Green);
    Result.Blue := ClampI(A.Blue - B.Blue);
    Result.Alpha := ClampI(A.Alpha - B.Alpha);
  end;

class operator TPGLColorIHelper.Subtract(A: TPGLColorI; B: TPGLVec4): TPGLColorI;
  begin
    Result.Red := ClampI(A.Red - B.X);
    Result.Green := ClampI(A.Green - B.Y);
    Result.Blue := ClampI(A.Blue - B.Z);
    Result.Alpha := ClampI(A.Alpha - B.W);
  end;

class operator TPGLColorIHelper.Multiply(A: TPGLColorI; B: Single): TPGLColorI;
  begin
    Result.Red := ClampI(A.Red * B);
    Result.Green := ClampI(A.Green * B);
    Result.Blue := ClampI(A.Blue * B);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLRectI
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

class operator TPGLRectI.Initialize(out Dest: TPGLRectI);
  begin
    Dest.fLeft := 0;
    Dest.fRight := 0;
    Dest.fTop := 0;
    Dest.fBottom := 0;
    Dest.fWidth := 0;
    Dest.fHeight := 0;
    Dest.fX := 0;
    Dest.fY := 0;
    dest.fZ := 0;
  end;

procedure TPGLRectI.Update(AFrom: Integer);
// AFrom expects a constant value of from_center, from_left, from_top, from_right, from_bottom
  begin

    case AFrom of

      0: // from_center
        begin
          Self.fLeft := Self.fX - trunc(Self.fWidth / 2);
          Self.fRight := Self.fLeft + (Self.fWidth);
          Self.fTop := Self.fY - trunc(Self.fHeight / 2);
          Self.fBottom := Self.fTop + (Self.fHeight);
        end;

      1: // from_left
        begin
          Self.fX := Self.fLeft + trunc(Self.fWidth / 2);
          Self.fRight := Self.fLeft + (Self.fWidth);
        end;

      2: // from_top
        begin
          Self.fY := Self.fTop + trunc(Self.fHeight / 2);
          Self.fBottom := Self.fTop + (Self.fHeight);
        end;

      3: // from_right
        begin
          Self.fX := Self.fRight - trunc(Self.fWidth / 2);
          Self.fLeft := Self.fRight - (Self.fWidth);
        end;

      4: //from_bottom
        begin
          Self.fY := Self.fBottom - trunc(Self.fHeight / 2);
          Self.fTop := Self.fBottom - (Self.fHeight);
        end;


    end;

  end;

procedure TPGLRectI.SetCenter(AX: Single = 0; AY: Single = 0; AZ: Single = 0);
  begin
    Self.fX := trunc(AX);
    Self.fY := trunc(AY);
    Self.fZ := trunc(AZ);
    Self.Update(from_center);
  end;

procedure TPGLRectI.SetX(AX: Single);
  begin
    Self.fX := trunc(AX);
    Self.Update(from_center);
  end;

procedure TPGLRectI.SetY(AY: Single);
  begin
    Self.fY := trunc(AY);
    Self.Update(from_center);
  end;

procedure TPGLRectI.SetLeft(ALeft: Single);
  begin
    Self.fLeft := trunc(ALeft);
    Self.Update(from_left);
  end;

procedure TPGLRectI.SetRight(ARight: Single);
  begin
    Self.fRight := trunc(ARight);
    Self.Update(from_right);
  end;

procedure TPGLRectI.SetTop(ATop: Single);
  begin
    Self.fTop := trunc(ATop);
    Self.Update(from_top);
  end;

procedure TPGLRectI.SetBottom(ABottom: Single);
  begin
    Self.fBottom := trunc(ABottom);
    Self.Update(from_bottom);
  end;

procedure TPGLRectI.SetTopLeft(ALeft: Single; ATop: Single);
  begin
      Self.SetCenter(ALeft + (Self.Width / 2), ATop + (Self.Height / 2), Self.Z);
  end;

procedure TPGLRectI.SetBottomRight(ARight: Single; ABottom: Single);
  begin
    Self.SetCenter(ARight - (Self.Width / 2), ABottom - (Self.Height / 2), Self.Z);
  end;

procedure TPGLRectI.SetSize(AWidth,AHeight: Single; AFrom: Integer = 0);
  begin
    Self.fWidth := trunc(AWidth);
    Self.fHeight := trunc(AHeight);
    Self.Update(AFrom);
  end;

procedure TPGLRectI.SetWidth(AWidth: Single; AFrom: Integer = 0);
  begin
    Self.fWidth := trunc(AWidth);
    Self.Update(AFrom);
  end;

procedure TPGLRectI.SetHeight(AHeight: Single; AFrom: Integer = 0);
  begin
    Self.fHeight := trunc(AHeight);
    Self.Update(AFrom);
  end;

procedure TPGLRectI.Grow(AIncWidth,AIncHeight: Single);
  begin
    Inc(Self.fWidth,trunc(AIncWidth));
      if Self.fWidth < 0 then begin
        Self.fWidth := 0;
      end;

    Inc(Self.fHeight,trunc(AIncHeight));
      if Self.fHeight < 0 then begin
        Self.fHeight := 0;
      end;

    Self.Update(from_center);
  end;

procedure TPGLRectI.Stretch(APerWidth,APerHeight: Single);
  begin
    Self.fWidth := RoundF(Self.fWidth * APerWidth);
      if Self.fWidth < 0 then begin
        Self.fWidth := 0;
      end;

    Self.fHeight := RoundF(Self.fHeight * APerHeight);
      if Self.fHeight < 0 then begin
        Self.fHeight := 0;
      end;

    Self.Update(from_center);
  end;

procedure TPGLRectI.FitInRect(ARect: TPGLRectI);
var
NewLeft,NewTop,NewRight,NewBottom: Integer;
  begin
    NewLeft := Self.Left;
    NewTop := Self.Top;
    NewRight := Self.Right;
    NewBottom := Self.Bottom;

    if (Self.Left >= ARect.Left) and (Self.Right <= ARect.Right) and (Self.Top >= ARect.Top) and (Self.Bottom <= ARect.Bottom) then begin
      Exit;
    end;

    If Self.Left < ARect.Left then NewLeft := ARect.Left;
    if Self.Right > ARect.Right then NewRight := Arect.Right;
    if Self.Top < ARect.Top then NewTop := ARect.Top;
    if Self.Bottom > ARect.Bottom then NewBottom := ARect.Bottom;

    Self := RectI(NewLeft, NewTop, NewRight, NewBottom);

  end;

procedure TPGLRectI.Translate(AX,AY,AZ: Single);
  begin
    Inc(Self.fX, trunc(AX));
    Inc(Self.fY, trunc(AY));
    Inc(Self.fZ, trunc(AZ));
    Self.Update(from_center);
  end;


function TPGLRectI.RandomSubRect: TPGLRectI;
var
L,R,T,B: Integer;
  begin
    R := trunc(Rnd(Self.Right));
    L := trunc(Rnd(R));
    B := trunc(Rnd(Self.Bottom));
    T := trunc(Rnd(B));
    Result := RectI(L,T,R,B);
  end;

class operator TPGLRectIHelper.Implicit(A: TPGLRectF): TPGLRectI;
  begin
    Result.fX := trunc(A.X);
    Result.fY := trunc(A.Y);
    Result.fZ := trunc(A.Z);
    Result.fWidth := trunc(A.Width);
    Result.fHeight := trunc(A.Height);
    Result.fLeft := trunc(A.Left);
    Result.fTop := trunc(A.Top);
    Result.fRight := trunc(A.Right);
    Result.fBottom := trunc(A.Bottom);
  end;

class operator TPGLRectIHelper.Implicit(A: TRect): TPGLRectI;
  begin
    Result := RectI(A.Left, A.Top, A.Right, A.Bottom);
  end;

class operator TPGLRectIHelper.Add(A: TPGLRectI; B: TPGLVec3): TPGLRectI; register;
  begin
    Result := A;
    Result.Translate(B.X, B.Y, B.Z);
  end;

class operator TPGLRectIHelper.Subtract(A: TPGLRectI; B: TPGLVec3): TPGLRectI;
  begin
    Result := A;
    Result.Translate(-B.X, -B.Y, -B.Z);
  end;

function TPGLRectIHelper.GetCenter: TPGLVec3;
  begin
    Result := Vec3(Self.fX, Self.fY, Self.fZ);
  end;

function TPGLRectIHelper.GetTopLeft(): TPGLVec3;
  begin
    Result := Vec3(Self.fLeft, Self.fTop, Self.fZ);
  end;

function TPGLRectIHelper.GetTopRight(): TPGLVec3;
  begin
    Result := Vec3(Self.fRight, Self.fTop, Self.fZ);
  end;

function TPGLRectIHelper.GetBottomLeft(): TPGLVec3;
  begin
    Result := Vec3(Self.fLeft, Self.fBottom, Self.fZ);
  end;

function TPGLRectIHelper.GetBottomRight(): TPGLVec3;
  begin
    Result := Vec3(Self.fRight, Self.fBottom, Self.fZ);
  end;

function TPGLRectIHelper.toVectors: System.TArray<TPGLVec3>;
  begin
    SetLength(Result,4);
    Result[0] := Vec3(Self.Left, Self.Top, Self.Z);
    Result[1] := Vec3(Self.Right, Self.Top, Self.Z);
    Result[2] := Vec3(Self.Right, Self.Bottom, Self.Z);
    Result[3] := Vec3(Self.Left, Self.Bottom, Self.Z);
  end;

procedure TPGLRectIHelper.Assign(ARectF: TPGLRectF);
  begin
    Self.fLeft := trunc(ARectF.Left);
    Self.fTop := trunc(ARectF.Top);
    self.fRight := trunc(ARectF.Right);
    Self.fBottom := trunc(ARectF.Bottom);
    Self.fWidth := trunc(ARectF.Width);
    Self.fHeight := trunc(ARectF.Height);
    Self.fX := trunc(ARectF.X);
    Self.fY := trunc(ARectF.Y);
  end;


procedure TPGLRectIHelper.ScaleToFit(AFitRect: TPGLRectF);
var
NewWidth,NewHeight: Integer;
WidthPer,HeightPer: Single;
Success: Boolean;
  begin

    Success := False;
    NewWidth := Self.Width;
    NewHeight := Self.Height;

    if NewWidth < AFitRect.Width then begin
      WidthPer := NewWidth * ((Self.Width / NewWidth));
      NewWidth := trunc(NewWidth * WidthPer) ;
      NewHeight := trunc(NewHeight * WidthPer);
    end;

    if NewHeight < AFitRect.Height then begin
      HeightPer := NewHeight * ((Self.Height / NewHeight));
      NewHeight := trunc(NewHeight * HeightPer);
      NewWidth := trunc(NewWidth * HeightPer);
    end;

    repeat

      if NewWidth > AFitRect.Width then begin
        WidthPer := AFitRect.Width / NewWidth;
        NewWidth := trunc(AFitRect.Width);
        NewHeight := trunc(NewHeight * WidthPer);
      end;

      if NewHeight > AFitRect.Height then begin
        HeightPer := AFitRect.Height / NewHeight;
        NewHeight := trunc(AFitRect.Height);
        NewWidth := trunc(NewWidth * HeightPer);
      end;

      if (NewWidth <= AFitRect.Width) and (NewHeight <= AFitRect.Height) then begin
        Success := True;
      end;

    until Success = True;

    Self.SetSize(NewWidth,NewHeight,from_center);


  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLRectF
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

class operator TPGLRectF.Initialize(out Dest: TPGLRectF);
  begin
    Dest.fLeft := 0;
    Dest.fRight := 0;
    Dest.fTop := 0;
    Dest.fBottom := 0;
    Dest.fWidth := 0;
    Dest.fHeight := 0;
    Dest.fX := 0;
    Dest.fY := 0;
    dest.fZ := 0;
  end;

procedure TPGLRectF.Update(AFrom: Integer);
  begin

    case AFrom of

      0: // from_center
        begin
          Self.fLeft := Self.fX - (Self.fWidth / 2);
          Self.fRight := Self.fLeft + (Self.fWidth);
          Self.fTop := Self.fY - (Self.fHeight / 2);
          Self.fBottom := Self.fTop + (Self.fHeight);
        end;

      1: // from_left
        begin
          Self.fX := Self.fLeft + (Self.fWidth / 2);
          Self.fRight := Self.fLeft + (Self.fWidth);
        end;

      2: // from_top
        begin
          Self.fY := Self.fTop + (Self.fHeight / 2);
          Self.fBottom := Self.fTop + (Self.fHeight);
        end;

      3: // from_right
        begin
          Self.fX := Self.fRight - (Self.fWidth / 2);
          Self.fLeft := Self.fRight - (Self.fWidth);
        end;

      4: //from_bottom
        begin
          Self.fY := Self.fBottom - (Self.fHeight / 2);
          Self.fTop := Self.fBottom - (Self.fHeight);
        end;


    end;

  end;

procedure TPGLRectF.SetX(AX: Single);
  begin
    Self.fX := AX;
    Self.Update(from_center);
  end;

procedure TPGLRectF.SetY(AY: Single);
  begin
    Self.fY := AY;
    Self.Update(from_center);
  end;

procedure TPGLRectF.SetZ(AZ: Single);
  begin
    Self.fZ := AZ;
    Self.Update(from_center);
  end;

procedure TPGLRectF.SetLeft(ALeft: Single);
  begin
    Self.fLeft := ALeft;
    Self.Update(from_left);
  end;

procedure TPGLRectF.SetRight(ARight: Single);
  begin
    Self.fRight := ARight;
    Self.Update(from_right);
  end;

procedure TPGLRectF.SetTop(ATop: Single);
  begin
    Self.fTop := ATop;
    Self.Update(from_top);
  end;

procedure TPGLRectF.SetBottom(ABottom: Single);
  begin
    Self.fBottom := ABottom;
    Self.Update(from_bottom);
  end;

procedure TPGLRectF.SetTopLeft(ALeft: Single; ATop: Single);
  begin
    Self.SetCenter(Vec3(ALeft + (Self.Width / 2), ATop + (Self.Height / 2), Self.Z));
  end;

procedure TPGLRectF.SetBottomRight(ARight: Single; ABottom: Single);
  begin
    Self.SetCenter(Vec3(ARight - (Self.Width / 2), ABottom - (Self.Height / 2), Self.Z));
  end;

procedure TPGLRectF.SetSize(AWidth,AHeight: Single; AFrom: Integer = 0);
  begin
    Self.fWidth := AWidth;
    Self.fHeight := AHeight;
    Self.Update(AFrom);
  end;

procedure TPGLRectF.SetWidth(AWidth: Single; AFrom: Integer = 0);
  begin
    Self.fWidth := AWidth;
    Self.Update(AFrom);
  end;

procedure TPGLRectF.SetHeight(AHeight: Single; AFrom: Integer = 0);
  begin
    Self.fHeight := AHeight;
    Self.Update(AFrom);
  end;

procedure TPGLRectF.Grow(AIncWidth,AIncHeight: Single);
  begin
    IncF(Self.fWidth,AIncWidth);
      if Self.fWidth < 0 then begin
        Self.fWidth := 0;
      end;

    IncF(Self.fHeight,AIncHeight);
      if Self.fHeight < 0 then begin
        Self.fHeight := 0;
      end;

    Self.Update(from_center);
  end;

procedure TPGLRectF.Stretch(APerWidth,APerHeight: Single);
  begin
    Self.fWidth := Self.fWidth * APerWidth;
      if Self.fWidth < 0 then begin
        Self.fWidth := 0;
      end;

    Self.fHeight := Self.fHeight * APerHeight;
      if Self.fHeight < 0 then begin
        Self.fHeight := 0;
      end;

    Self.Update(from_center);
  end;

procedure TPGLRectF.Translate(AX,AY: Single);
  begin
    IncF(Self.fX, AX);
    IncF(Self.fY, AY);
    Self.Update(from_center);
  end;

function TPGLRectF.RandomSubRect: TPGLRectF;
var
L,R,T,B: Single;
  begin
    R := Rnd(Self.Width - 1);
    L := Rnd(R);
    B := Rnd(Self.Height - 1);
    T := Rnd(B);
    Result := PGLTypes.RectF(L,T,R,B);
  end;

class operator TPGLRectFHelper.Implicit(A: TPGLRectI): TPGLRectF;
  begin
    Result.fX := (A.X);
    Result.fY := (A.Y);
    Result.fZ := (A.Z);
    Result.fWidth := (A.Width);
    Result.fHeight := (A.Height);
    Result.fLeft := (A.Left);
    Result.fTop := (A.Top);
    Result.fRight := (A.Right);
    Result.fBottom := (A.Bottom);
  end;

class operator TPGLRectFHelper.Add(A: TPGLRectF; B: TPGLVec3): TPGLRectF;
  begin
    Result := A;
    Result.Translate(B.X, B.Y);
  end;

class operator TPGLRectFHelper.Subtract(A: TPGLRectF; B: TPGLVec3): TPGLRectF;
  begin
    Result := A;
    Result.Translate(-B.X, -B.Y);
  end;

function TPGLRectFHelper.GetCenter: TPGLVec3;
  begin
    Result := Vec3(Self.fX, Self.fY, Self.fZ);
  end;

function TPGLRectFHelper.GetTopLeft(): TPGLVec3;
  begin
    Result := Vec3(Self.fLeft, Self.fTop, Self.fZ);
  end;

function TPGLRectFHelper.GetTopRight(): TPGLVec3;
  begin
    Result := Vec3(Self.fRight, Self.fTop, Self.fZ);
  end;

function TPGLRectFHelper.GetBottomLeft(): TPGLVec3;
  begin
    Result := Vec3(Self.fLeft, Self.fBottom, Self.fZ);
  end;

function TPGLRectFHelper.GetBottomRight(): TPGLVec3;
  begin
    Result := Vec3(Self.fRight, Self.fBottom, Self.fZ);
  end;

procedure TPGLRectFHelper.SetCenter(ACenter: TPGLVec3);
  begin
    Self.fX := ACenter.X;
    Self.fY := ACenter.Y;
    Self.fZ := ACenter.Z;
    Self.Update(from_center);
  end;

function TPGLRectFHelper.toVectors: System.TArray<TPGLVec3>;
  begin
    SetLength(Result,4);
    Result[0] := Vec3(Self.Left, Self.Top, Self.fZ);
    Result[1] := Vec3(Self.Right, Self.Top, Self.fZ);
    Result[2] := Vec3(Self.Right, Self.Bottom, Self.fZ);
    Result[3] := Vec3(Self.Left, Self.Bottom, Self.fZ);
  end;

function TPGLRectFHelper.toTexCoords(): TArray<TPGLVec3>;
  begin
    SetLength(Result,4);
    Result[0] := Vec2(Self.Left / Self.Width, Self.Top / Self.Height);
    Result[1] := Vec2(Self.Right / Self.Width, Self.Top / Self.Height);
    Result[2] := Vec2(Self.Right / Self.Width, Self.Bottom / Self.Height);
    Result[3] := Vec2(Self.Left / Self.Width, Self.Bottom / Self.Height);
  end;

procedure TPGLRectFHelper.Assign(ARectI: TPGLRectI);
  begin
    Self.fLeft := (ARectI.Left);
    Self.fTop := (ARectI.Top);
    self.fRight := (ARectI.Right);
    Self.fBottom := (ARectI.Bottom);
    Self.fWidth := (ARectI.Width);
    Self.fHeight := (ARectI.Height);
    Self.fX := (ARectI.X);
    Self.fY := (ARectI.Y);
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLVec2
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

procedure TPGLVec2.Translate(AValues: TPGLVec2);
  begin
    Self.X := Self.X + AValues.X;
    Self.Y := Self.Y + AValues.Y;
  end;

function TPGLVec2.ToString(APrecision: Cardinal = 0): String;
  begin
    Result := Self.X.ToString(TFloatFormat.ffFixed, APrecision, 0)  + ', ' + Self.Y.ToString(TFloatFormat.ffFixed, APrecision, 0);
  end;

class operator TPGLVec2.Add(A,B: TPGLVec2): TPGLVec2;
  begin
    Result.X := A.X + B.X;
    Result.Y := A.Y + B.Y;
  end;

class operator TPGLVec2.Subtract(A,B: TPGLVec2): TPGLVec2;
  begin
    Result.X := A.X - B.X;
    Result.Y := A.Y - B.Y;
  end;

class operator TPGLVec2.Multiply(A: TPGLVec2; B: Single): TPGLVec2;
  begin
    Result.X := A.X * B;
    Result.Y := A.Y * B;
  end;

class operator TPGLVec2.Divide(A: TPGLVec2; B: Single): TPGLVec2;
  begin
    Result.X := A.X / B;
    Result.Y := A.Y / B;
  end;

class operator TPGLVec2.Negative(A: TPGLVec2): TPGLVec2;
  begin
    Result.X := -Result.X;
    Result.Y := -Result.Y;
  end;

class operator TPGLVec2Helper.Implicit(A: TPoint): TPGLVEc2;
  begin
    Result.X := A.X;
    Result.Y := A.Y;
  end;

class operator TPGLVec2Helper.Implicit(A: TPGLVec3): TPGLVec2;
  begin
    Result.X := A.X;
    Result.Y := A.Y;
  end;

class operator TPGLVec2Helper.Implicit(A: TPGLVec4): TPGLVec2;
  begin
    Result.X := A.X;
    Result.Y := A.Y;
  end;

class operator TPGLVec2Helper.Explicit(A: TPoint): TPGLVEc2;
  begin
    Result.X := A.X;
    Result.Y := A.Y;
  end;

class operator TPGLVec2Helper.Explicit(A: TPGLVec3): TPGLVec2;
  begin
    Result.X := A.X;
    Result.Y := A.Y;
  end;

class operator TPGLVec2Helper.Explicit(A: TPGLVec4): TPGLVec2;
  begin
    Result.X := A.X;
    Result.Y := A.Y;
  end;

 class operator TPGLVec2Helper.Add(A,B: TPGLVec2): TPGLVec2;
  begin
    Result.X := A.X + B.X;
    Result.Y := A.Y + B.Y;
  end;

 class operator TPGLVec2Helper.Equal(A,B: TPGLVec2): Boolean;
  begin
    Result := (A.X = B.X) and (A.Y = B.Y);
  end;

 class operator TPGLVec2Helper.NotEqual(A,B: TPGLVec2): Boolean;
  begin
    Result := (A.X <> B.X) or (A.Y <> B.Y);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLVec3
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

class operator TPGLVec3Helper.Implicit(A: TPoint): TPGLVec3;
  begin
    Result.X := A.X;
    Result.Y := A.Y;
  end;

class operator TPGLVec3Helper.Implicit(A: TPGLVec2): TPGLVec3;
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := 0;
  end;

class operator TPGLVec3Helper.Implicit(A: TPGLVec4): TPGLVec3;
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := A.Z;
  end;

class operator TPGLVec3Helper.Explicit(A: TPGLVec2): TPGLVec3;
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := 0;
  end;

class operator TPGLVec3Helper.Explicit(A: TPGLVec4): TPGLVec3;
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := A.Z;
  end;

class operator TPGLVec3Helper.Multiply(A: TPGLVec3; B: TPGLMat4): TPGLVec3;
  begin
    Result := B * A;
  end;

class operator TPGLVec3.Add(A,B: TPGLVec3): TPGLVec3;
  begin
    Result.X := A.X + B.X;
    Result.Y := A.Y + B.Y;
    Result.Z := A.Z + B.Z;
  end;

class operator TPGLVec3.Add(A: TPGLVec3; B: Single): TPGLVec3;
  begin
    Result.X := A.X + B;
    Result.Y := A.Y + B;
    Result.Z := A.Z + B;
  end;

class operator TPGLVec3.Subtract(A,B: TPGLVec3): TPGLVec3;
  begin
    Result.X := A.X - B.X;
    Result.Y := A.Y - B.Y;
    Result.Z := A.Z - B.Z;
  end;

class operator TPGLVec3.Subtract(A: TPGLVec3; B: Single): TPGLVec3;
  begin
    Result.X := A.X - B;
    Result.Y := A.Y - B;
    Result.Z := A.Z - B;
  end;

class operator TPGLVec3.Divide(A: TPGLVec3; B: Single): TPGLVec3;
  begin
    Result.X := A.X / B;
    Result.Y := A.Y / B;
    Result.Z := A.Z / B;
  end;

class operator TPGLVec3.Divide(A: Single; B: TPGLVec3): TPGLVec3;
  begin
    Result.X := A / B.X;
    Result.Y := A / B.Y;
    Result.Z := A / B.Z;
  end;

class operator TPGLVec3.Multiply(A: TPGLVec3; B: Single): TPGLVec3;
  begin
    Result.X := A.X * B;
    Result.Y := A.Y * B;
    Result.Z := A.Z * B;
  end;

class operator TPGLVec3.Multiply(A,B: TPGLVec3): TPGLVec3;
  begin
    Result.X := A.X * B.X;
    Result.Y := A.Y * B.Y;
    Result.Z := A.Z * B.Z;
  end;

class operator TPGLVec3.Negative(A: TPGLVec3): TPGLVec3;
  begin
    Result.X := -A.X;
    Result.Y := -A.Y;
    Result.Z := -A.Z;
  end;

function TPGLVec3.GetNormal: TPGLVec3;
var
TVec: TPGLVec3;
  begin
    TVec := Self;
    Normalize(TVec);
    Result := TVec;
  end;

function TPGLVec3.GetLength: Single;
  begin
    Result := PGLTypes.VectorLength(Self);
  end;

procedure TPGLVec3.Negate();
  begin
    Self.X := -Self.X;
    Self.Y := -Self.Y;
    Self.Z := -Self.Z;
  end;

procedure TPGLVec3.Translate(AX: Single = 0; AY: Single = 0; AZ: Single = 0);
  begin
    Incf(Self.X, AX);
    Incf(Self.Y, AY);
    Incf(Self.Z, AZ);
  end;

procedure TPGLVec3.Translate(AValues: TPGLVec3);
  begin
    Incf(Self.X, AValues.X);
    Incf(Self.Y, AValues.Y);
    Incf(Self.Z, AValues.Z);
  end;

procedure TPGLVec3.Rotate(AX,AY,AZ: Single);
  begin

  end;

procedure TPGLVec3.Cross(AVec: TPGLVec3);
  begin
    Self := PGLTypes.Cross(Self, AVec);
  end;

function TPGLVec3.Dot(AVec: TPGLVec3): Single;
  begin
    Result := PGLTypes.Dot(Self,AVec);
  end;

function TPGLVec3.GetTargetVector(ATarget: TPGLVec3): TPGLVec3;
  begin
    Result := PGLTypes.Normal(Self - ATarget);
  end;

function TPGLVec3.toNDC(ADispWidth, ADispHeight: Single): TPGLVec3;
  begin
    Result.X := -1 + ((Self.X / ADispWidth) * 2);
    Result.Y := -1 + ((Self.Y / ADispHeight) * 2);
  end;

function TPGLVec3.Swizzle(AComponents: TArray<TPGLVectorComponent>): TPGLVec3;
var
I: Integer;
Vals: Array [0..2] of Single;
  begin
    Result := Vec3(0,0,0);

    for I := 0 to  trunc( Smallest( [High(AComponents), 2] )) do begin

      case AComponents[i] of
        VX: Vals[i] := Self.X;
        VY: Vals[i] := Self.Y;
        VZ: Vals[i] := Self.Z;
      end;

    end;

    Result := Vec3(Vals[0], Vals[1], Vals[2]);

  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLVec4
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

class operator TPGLVec4Helper.Implicit(A: TPGLVec2): TPGLVec4;
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := 0;
    Result.W := 0;
  end;

class operator TPGLVec4Helper.Implicit(A: TPGLVec3): TPGLVec4;
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := A.Z;
    Result.W := 0;
  end;

class operator TPGLVec4Helper.Explicit(A: TPGLVec2): TPGLVec4;
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := 0;
    Result.W := 0;
  end;

class operator TPGLVec4Helper.Explicit(A: TPGLVec3): TPGLVec4;
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := A.Z;
    Result.W := 0;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLVertex
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLMat4
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

class operator TPGLMat4.Initialize(out Dest: TPGLMat4);
  begin
    Dest.SetIdentity();
  end;

class operator TPGLMat4.Multiply(A: TPGLMat4; B: TPGLMat4): TPGLMat4;
var
I,J,K: Integer;
Sum: Single;
  begin

    for I := 0 to 3 do begin
      for J := 0 to 3 do begin

        Sum := 0;
        for K := 0 to 3 do begin
          Sum := Sum + (A.M[K,J] * B.M[I,K]);
        end;

        Result.M[I,J] := Sum;

      end;
    end;

  end;


class operator TPGLMat4.Multiply(A: TPGLMat4; B: TPGLVec4): TPGLVec4;
  begin
    Result.X := ((A.M[0,0] * B.X) + (A.M[1,0] * B.X) + (A.M[2,0] * B.X)) + A.M[3,0];
    Result.Y := ((A.M[0,1] * B.Y) + (A.M[1,1] * B.Y) + (A.M[2,1] * B.Y)) + A.M[3,1];
    Result.Z := ((A.M[0,2] * B.Z) + (A.M[1,2] * B.Z) + (A.M[2,2] * B.Z)) + A.M[3,2];
    Result.W := ((A.M[0,3] * B.W) + (A.M[1,3] * B.W) + (A.M[2,3] * B.W)) + A.M[3,3];

//    Result.X := ((A.M[0,0] * B.X) + (A.M[0,1] * B.X) + (A.M[0,2] * B.X)) + A.M[0,3];
//    Result.Y := ((A.M[1,0] * B.Y) + (A.M[1,1] * B.Y) + (A.M[1,2] * B.Y)) + A.M[1,3];
//    Result.Z := ((A.M[2,0] * B.Z) + (A.M[2,1] * B.Z) + (A.M[2,2] * B.Z)) + A.M[2,3];
//    Result.W := ((A.M[3,0] * B.W) + (A.M[3,1] * B.W) + (A.M[3,2] * B.W)) + A.M[3,3];
  end;


class operator TPGLMat4.Implicit(A: Array of Single): TPGLMat4;
var
Len,I,Z,R: Integer;
  begin

    if Length(A) > 16 then begin
      Len := 16;
    end else begin
      Len := Length(A);
    end;

    R := 0;
    I := 0;
    Z := 0;

    while R < Len do begin
        Result.M[I,Z] := A[R];

        Inc(R);

        Inc(I);
        if I > 3 then begin
          I := 0;
          Inc(Z);
        end;
    end;

  end;

procedure TPGLMat4.Zero();
var
I: Integer;
  begin
    for I := 0 to 3 do begin
      Self.M[I,0] := 0;
      Self.M[I,1] := 0;
      Self.M[I,2] := 0;
      Self.M[I,3] := 0;
    end;
  end;

procedure TPGLMat4.SetIdentity();
var
I,Z: Integer;
  begin

    for I := 0 to 3 do begin
      for Z := 0 to 3 do begin

        if I = z then begin
          Self.M[I,Z] := 1;
        end else begin
          Self.M[I,Z] := 0;
        end;

      end;
    end;

  end;


procedure TPGLMat4.Fill(AValues: System.TArray<Single>);
var
I,Z: Integer;
  begin

    for Z := 0 to 3 do begin
      for  I := 0 to 3 do begin

        Self.M[Z,I] := AValues[ (Z * 4) + I];

      end;
    end;

  end;

procedure TPGLMat4.Negate();
var
I,Z: Integer;
  begin
    for I := 0 to 3 do begin
      for Z := 0 to 3 do begin
        Self.M[I,Z] := -Self.M[I,Z];
      end;
    end;
  end;

procedure TPGLMat4.Inverse();
  begin
    Self := MatrixInverse(Self);
  end;

procedure TPGLMat4.Scale(AFactor: Single);
  begin
    Self := MatrixScale(Self,AFactor);
  end;

procedure TPGLMat4.Transpose();
var
I,Z: Integer;
TempMat: TPGLMat4;
  begin
    for I := 0 to 3 do begin
      for Z := 0 to 3 do begin
        TempMat.M[I,Z] := Self.M[Z,I];
      end;
    end;

    Self := TempMat;
  end;

procedure TPGLMat4.MakeTranslation(AX: Single = 0; AY: Single = 0; AZ: Single = 0);
  begin
    Self.SetIdentity();
    Self.AW := AX;
    Self.BW := AY;
    Self.CW := AZ;
  end;

procedure TPGLMat4.MakeTranslation(AValues: TPGLVec3);
  begin
    Self.SetIdentity();
    Self.AW := AValues.X;
    Self.BW := AValues.Y;
    Self.CW := AValues.Z;
  end;

procedure TPGLMat4.Translate(AX: Single = 0; AY: Single = 0; AZ: Single = 0);
  begin
    Self.AW := Self.AW + AX;
    Self.BW := Self.BW + AY;
    Self.CW := Self.CW + AZ;
  end;

procedure TPGLMat4.Translate(AValues: TPGLVec3);
  begin
    Self.AW := Self.AW + AValues.X;
    Self.BW := Self.BW + AValues.Y;
    Self.CW := Self.CW + AValues.Z;
  end;

procedure TPGLMat4.Rotate(AX: Single = 0; AY: Single = 0; AZ: Single = 0);
var
XMat,YMat,ZMat: TPGLMat4;
  begin
    Self.SetIdentity();
    XMat.SetIdentity();
    YMat.SetIdentity();
    ZMat.SetIdentity();

    if AX <> 0 then begin
      XMat.BY := cos(AX);
      XMat.BZ := -sin(AX);
      XMat.CY := sin(AX);
      XMat.CZ := cos(AX);
    end;

    if AY <> 0 then begin
      YMat.AX := cos(AY);
      YMat.AZ := sin(AY);
      YMat.CX := -sin(AY);
      YMat.CZ := cos(AY);
    end;

    if AZ <> 0 then begin
      ZMat.AX := cos(AZ);
      ZMat.AY := -sin(AZ);
      ZMat.BX := sin(AZ);
      ZMat.BY := cos(AZ);
    end;

    Self := XMat * YMat * ZMat;

  end;

procedure TPGLMat4.Rotate(AValues: TPGLVec3);
  begin
    Self.Rotate(AValues.X, AValues.Y, AValues.Z);
  end;


procedure TPGLMat4.MakeScale(AX, AY, AZ: Single);
  begin

    Self.SetIdentity();
    Self.AX := -1 + ((1 / AX) * 2);
    Self.AY := -1 + ((1 / AY) * 2);
    Self.AZ := -1 + ((1 / AZ) * 2);

  end;

procedure TPGLMat4.Perspective(AFOV, Aspect, ANear, AFar: Single; VerticalFOV: Boolean = True);
var
YScale,XScale: Single;
  begin

    AFOV := AFOV * (Pi / 180);

    if VerticalFOV = False then begin
      XScale := 1 / Tangent(AFOV / 2);
      YScale := XScale / Aspect;
    end else begin
      YScale := 1 / Tangent(AFOV / 2);
      XScale := YScale / Aspect;
    end;

    Self.M[0,0] := XScale;
    Self.M[1,0] := 0;
    Self.M[2,0] := 0;
    Self.M[3,0] := 0;

    Self.M[0,1] := 0;
    Self.M[1,1] := YScale;
    Self.M[2,1] := 0;
    Self.M[3,1] := 0;

    Self.M[0,2] := 0;
    Self.M[1,2] := 0;
    Self.M[2,2] := AFar / (ANear - AFar);
    Self.M[3,2] := (AFar * ANear) / (ANear - AFar);

    Self.M[0,3] := 0;
    Self.M[1,3] := 0;
    Self.M[2,3] := -1;
    Self.M[3,3] := 0;

  end;

procedure TPGLMat4.Ortho(ALeft,ARight,ABottom,ATop,ANear,AFar: Single);
var
N,F: Single;
  begin

    Self.SetIdentity();

    Self.M[0,0] := 2 / (ARight - ALeft);
    Self.M[1,1] := 2 / (ATop - ABottom);
    Self.M[2,2] := -2 / (ANear - AFar);
    Self.M[3,0] := ((ALeft + ARight) / (ALeft - ARight));
    Self.M[3,1] := ((ATop + ABottom) / (ABottom - ATop));
    Self.M[3,2] := ((ANear + AFar) / (ANear - AFar));


  end;

procedure TPGLMat4.LookAt(AFrom,ATo,AUp: TPGLVec3);
var
Right,NewUp,Direction: TPGLVec3;
TransMat: TPGLMat4;
  begin

    Direction := Normal(AFrom - ATo);
    Right := Cross(Direction, AUp);
    Normalize(Right);
    NewUp := Cross(Direction, Right);
    NewUp.Negate();
    Normalize(NewUp);

    Self := [Right.X, Right.Y, Right.Z, 0,
             NewUp.X, NewUp.Y, NewUp.Z, 0,
             Direction.X, Direction.Y, Direction.Z, 0,
             0,       0,       0,           1];

    TransMat.MakeTranslation(-AFrom);

    Self := Self * TransMat;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLCylinder
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLCylinder.Create(ACenter: TPGLVec3; AUpVector: TPGLVec3; ARadius: Single; AHeight: Single);
  begin
    Self.fRadius := ARadius;
    Self.fHeight := AHeight;
    Self.fUp := AUpVector;
    Self.SetCenter(ACenter);
  end;

procedure TPGLCylinder.Translate(AValue: TPGLVec3);
  begin
    Self.Center := Self.Center + AValue;
  end;

procedure TPGLCylinder.SetBottomCenter(const ABottomCenter: TPGLVec3);
  begin
    fBottomCenter := ABottomCenter;
    fCenter := ABottomCenter + (fUp * (fHeight / 2));
    fTopCenter := ABottomCenter + (fUp * fHeight);
  end;

procedure TPGLCylinder.SetCenter(const ACenter: TPGLVec3);
  begin
    fCenter := ACenter;
    fBottomCenter := fCenter - (fUp * (fHeight / 2));
    fTopCenter := fCenter + (fUp * (fHeight / 2));
  end;

procedure TPGLCylinder.SetHeight(const AHeight: Single);
  begin
    fHeight := AHeight;
    fBottomCenter := fCenter - (fUp * (fHeight / 2));
    fTopCenter := fCenter + (fUp * (fHeight / 2));
  end;

procedure TPGLCylinder.SetRadius(const ARadius: Single);
  begin
    fRadius := ARadius;
  end;

procedure TPGLCylinder.SetTopCenter(const ATopCenter: TPGLVec3);
  begin
    fTopCenter := ATopCenter;
    fCenter := ATopCenter - (fUp * (fHeight / 2));
    fBottomCenter := ATopCenter - (fUp * fHeight);
  end;

procedure TPGLCylinder.SetUpVector(const AUpVector: TPGLVec3);
  begin
    Self.fUp := AUpVector;
    fBottomCenter := fCenter - (fUp * (fHeight / 2));
    fTopCenter := fCenter + (fUp * (fHeight / 2));
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLPlane
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLPlane.Create(P1: TPGLVec3; ANormal: TPGLVec3);
  begin
    Self.Normal := ANormal.Normal;
    Self.Distance := Dot(P1,Normal.Normal);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLFrustum
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}
function TPGLFrustum.isInViewSphere(APosition: TPGLVec3; ARadius: Single): Boolean;
  begin
    Result := False;
    if (Self.OnorForwardSphere(Self.Faces.Left, APosition, ARadius)) and
       (Self.OnorForwardSphere(Self.Faces.Right, APosition, ARadius)) and
       (Self.OnorForwardSphere(Self.Faces.Far, APosition, ARadius)) and
       (Self.OnorForwardSphere(Self.Faces.Near, APosition, ARadius)) and
       (Self.OnorForwardSphere(Self.Faces.Top, APosition, ARadius)) and
       (Self.OnorForwardSphere(Self.Faces.Bottom, APosition, ARadius)) then begin
          Result := True;
    end;
  end;


function TPGLFrustum.OnorForwardSphere(const [ref] AFace: TPGLPlane; var ACenter: TPGLVec3; var ARadius: Single): Boolean; register;
  begin
    result := Dot(AFace.Normal, ACenter) - AFace.Distance > -ARadius;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLCamera
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TPGLCamera.Create();
  begin
    Self.SetViewport(RectFWH(0,0,800,600));
    Self.Set2DCamera();
    Self.fFOV := 60;
    Self.fFOVVerticle := True;
    Self.SetPosition(Vec3(0,0,0));
    Self.SetTarget(Vec3(0,0,1));
    Self.fVerticleFlip := True;
  end;

procedure TPGLCamera.GetDirection();
  begin
    Self.fDirection := Normal(Self.fPosition - Self.fTarget);
  end;

procedure TPGLCamera.GetRight();
  begin
    Self.fRight := Normal(Cross(Vec3(0,1,0), Self.Direction));
  end;

procedure TPGLCamera.GetUp();
  begin
    Self.fUp := Cross(Self.Direction, Self.Right);
  end;

procedure TPGLCamera.GetNewAngles();
  begin
    Self.fAngles.Z := ArcTan(Self.Direction.Y / Self.Direction.X);
  end;


procedure TPGLCamera.ConstructFrustum();
var
HalfVSide,HalfHSide: Single;
FrontMultFar: TPGLVec3;
  begin
    HalfVSide := Self.ViewDistance * Tan(Radians(Self.fFOV) / 2);
    HalfHSide := HalfVSide * (Self.Viewport.width / Self.ViewPort.Height);
    FrontMultFar := -Self.Direction * Self.ViewDistance;

    Self.fFrustum.Faces.Near := TPGLPlane.Create(Self.Position + (-Self.Direction * Self.ViewNear), -Self.Direction);

    Self.fFrustum.Faces.Far := TPGLPlane.Create((Self.Position + frontMultFar), Self.Direction);

    Self.fFrustum.Faces.Right := TPGLPlane.Create(Self.Position,
                            Cross(frontMultFar - Self.Right * HalfHSide, Self.Up));

    Self.fFrustum.Faces.Left := TPGLPlane.Create(Self.Position,
                            Cross(Self.Up,frontMultFar + Self.Right * halfHSide));

    Self.fFrustum.Faces.Top := TPGLPlane.Create(Self.Position,
                            Cross(Self.Right, frontMultFar - Self.Up * halfVSide));

    Self.fFrustum.Faces.Bottom := TPGLPlane.Create(Self.Position,
                            Cross(frontMultFar + Self.Up * halfVSide, Self.Right));
  end;

procedure TPGLCamera.GetProjection();
  begin

    case Self.fCameraType of

      0:
        begin
          Self.ProjectionMatrix.Ortho(Self.ViewPort.Left, Self.ViewPort.Right, Self.ViewPort.Bottom, Self.ViewPort.Top, Self.fViewNear, Self.ViewDistance);
          Self.ViewMatrix.SetIdentity();
        end;

      1:
        begin
          Self.fProjection.Perspective(Self.FOV, Self.fViewport.Width / Self.fViewPort.Height, Self.fViewNear, Self.fViewDistance, Self.FOVVerticle);
          Self.fView.LookAt(Self.Position, Self.Target, Self.Up);
        end;

    end;

    Self.ConstructFrustum();

  end;

procedure TPGLCamera.Set2DCamera();
  begin
    Self.fCameraType := camera_type_2D;
    Self.GetProjection();
  end;

procedure TPGLCamera.Set3DCamera();
  begin
    Self.fCameraType := camera_type_3D;
    Self.GetProjection();
  end;

procedure TPGLCamera.SetViewport(ABounds: TPGLRectF; AViewNear: Single = 0; AViewFar: Single = 1);
  begin
    Self.fViewport := ABounds;
    Self.fViewNear := AViewNear;
    Self.fViewDistance := aViewFar;
    Self.GetProjection();
  end;

procedure TPGLCamera.SetViewDistance(AViewDistance: Single);
  begin
    Self.fViewDistance := AViewDistance;
    Self.GetProjection();
  end;

procedure TPGLCamera.SetPosition(APos: TPGLVec3);
  begin
    Self.fPosition := APos;
  end;

procedure TPGLCamera.SetTarget(ATarget: TPGLVec3);
  begin
    Self.fTarget := ATarget;
    Self.GetDirection();
    Self.GetNewAngles();
    Self.GetRight();
    Self.GetUp();
    Self.GetProjection();
  end;

procedure TPGLCamera.SetDirection(ADirection: TPGLVec3);
  begin
    Self.fDirection := ADirection;
    Self.SetTarget(Self.Position - Self.Direction);
  end;

procedure TPGLCamera.SetFOV(AValue: Single; AVerticleFOV: Boolean = true);
  begin
    Self.fFOV := AValue;
    Self.fFOVVerticle := AVerticleFOV;
    Self.GetProjection();
  end;

procedure TPGLCamera.Translate(AValues: TPGLVec3);
  begin
    Self.fPosition := Self.fPosition + AValues;
    Self.SetTarget(Self.Position - Self.Direction);
  end;

procedure TPGLCamera.Rotate(AValues: TPGLVec3);
  begin

    if Self.fCameraType = camera_type_2d then exit;

    Self.fAngles := Self.fAngles + AValues;
    ClampRadians(Self.fAngles.X);
    ClampRadians(Self.fAngles.Y);
    ClampRadians(Self.fAngles.Z);

    if Self.fVerticleFlip = True then begin
      if Self.fAngles.X > ((Pi / 2) * 0.99) then begin
        Self.fAngles.X := ((Pi / 2) * 0.99);
      end;
      if Self.fAngles.X < (-(Pi / 2) * 0.99) then begin
        Self.fAngles.X := (-(Pi / 2) * 0.99)
      end;
    end;

    Self.fDirection.X := (cos(Self.fAngles.Y) * cos(Self.fAngles.X));
    Self.fDirection.Y := sin(Self.fAngles.X);
    Self.fDirection.Z := (sin(Self.fAngles.Y) * cos(Self.fAngles.X));

    Self.fTarget := (Self.Position - (Self.Direction * 10));
    Self.GetRight();
    Self.GetUp();
    Self.GetProjection();
  end;

procedure TPGLCamera.LockVerticleFlip(AEnable: Boolean = True);
  begin
    Self.fVerticleFlip := AEnable;
  end;

function TPGLCamera.SphereInView(APosition: TPGLVec3; ARadius: Single): Boolean;
  begin
    Result := Self.fFrustum.isInViewSphere(APosition, ARadius);
  end;



end.
