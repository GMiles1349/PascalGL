unit glDrawImages;

{$HINTS OFF}

interface

Uses
  System.Types, System.AnsiStrings, WinAPI.Windows;

  type TPGLBitMapBuffer = packed record
    // 14 Byte header
    TypeChar: WORD;
    FileSize: DWORD;
    Reserved1: WORD;
    Reserved2: WORD;
    OffSet: DWORD;

    // 40 byte core info
    HeaderSize: DWORD;
    Width: DWORD;
    Height: DWORD;
    Planes: WORD;
    BPP: WORD;
    Compression: DWORD;
    ImageSize: DWORD;
    HRes: DWORD;
    VRes: DWORD;
    PalleteColors: DWORD;
    ImportantColors: DWORD;

    ImageData: TArray<Byte>;
    DataSize: UInt32;
  end;


  function pglReadBMP(AFileName: AnsiString; out AWidth: Integer; out AHeight: Integer): Pointer; register;
  procedure pglWriteBmp(AFileName: AnsiString; ASource: Pointer; AWidth,AHeight: Integer; AChannels: Integer = 4); register;
  function pglExtractFileExtension(AFileName: AnsiString): AnsiString; register;
  procedure pglAlignImageData(var ASource: TArray<Byte>; AWidth,AHeight: Integer); register;
  procedure pglRemoveImageAlignment(var ASource: TArray<Byte>; AWidth,AHeight: Integer; Channels: Integer = 4); register;
  procedure pglReverseImageBytes(var ASource: TArray<Byte>; AWidth,AHeight: Integer; Channels: Integer = 4); register
  procedure pglFlipImage(var ASource: TArray<Byte>; AWidth,AHeight: Integer; Channels: Integer = 4); register;
  procedure pglAddImageAlphaChannel(var ASource: TArray<Byte>; AWidth,AHeight: Integer; Channels: Integer); register;
  procedure pglRemoveImageAlphaChannel(var ASource: TArray<Byte>; AWidth,AHeight: Integer; Channels: Integer = 4); register;



implementation


function pglExtractFileExtension(AFileName: AnsiString): AnsiString;
var
Len: Integer;
SPos: Integer;
  begin
    Len := Length(AFileName);
    SPos := AnsiPos(AnsiString('.'),AFileName);
    Result := LowerCase(AnsiMidStr(AFileName,SPos,Len-SPos+1));
  end;

procedure pglRemoveAlphaChannel(ASource: Pointer; ADataSize: Integer);
  begin

  end;


procedure pglAlignImageData(var ASource: TArray<Byte>; AWidth,AHeight: Integer);
var
ByteWidth: Integer;
PadSize: Integer;
Channels: Integer;
Buffer: TArray<Byte>;
BufferPos,SourcePos: Integer;
NewLength: Integer;
I: Integer;
  begin

    // Determine number of channels, exit if it's not 3 or 4
    if (AWidth * AHeight) * 3 = Length(ASource) then begin
      Channels := 3;
    end else if (AWidth * AHeight) * 4 = Length(ASource) then begin
      Channels := 4;
    end else begin
      exit;
    end;

    // get the current byte width of the data
    ByteWidth := (AWidth * Channels);
    PadSize := ByteWidth mod 4;
    PadSize := 4 - PadSize;
    if PadSize = 0 then begin
      // exit if we're already aligned to 4 bytes
      exit;
    end;

    // insert padding to rows if we're not aligned
    SetLength(Buffer,Length(ASource));
    Move(ASource[0],Buffer[0],Length(ASource));

    // Calculate the new size of the source and resize
    NewLength := ((ByteWidth + PadSize) * AHeight);
    SetLength(ASource,0);
    SetLength(ASource,NewLength);

    BufferPos := 0;
    SourcePos := 0;

    for I := 0 to AHeight - 1 do begin
      Move(Buffer[BufferPos],ASource[SourcePos],ByteWidth);
      Inc(BufferPos,ByteWidth);
      Inc(SourcePos,ByteWidth + PadSize);
    end;

  end;


procedure pglRemoveImageAlignment(var ASource: TArray<Byte>; AWidth,AHeight: Integer; Channels: Integer = 4);
var
Buffer: TArray<Byte>;
NewLength: Integer;
ByteWidth: Integer;
OldWidth: Integer;
PadSize: Integer;
BufferPos,SourcePos: Integer;
I: Integer;
  begin

    // get the current byte width of the data
    ByteWidth := (AWidth * Channels);
    PadSize := ByteWidth mod 4;
    PadSize := 4 - PadSize;
    if PadSize = 0 then begin
      // exit if we're not aligned on 4 bytes
      exit;
    end;

    OldWidth := trunc(Length(ASource) / AHeight);

    SetLength(Buffer,Length(ASource));
    NewLength := (AWidth * AHeight) * Channels;

    Move(ASource[0],Buffer[0],Length(ASource));
    SetLength(ASource,NewLength);

    SourcePos := 0;
    BufferPos := 0;

    for I := 0 to AHeight - 1 do begin
      Move(Buffer[BufferPos], ASource[SourcePos],ByteWidth);
      Inc(SourcePos,ByteWidth);
      Inc(BufferPos,OldWidth);
    end;

  end;


procedure pglReverseImageBytes(var ASource: TArray<Byte>; AWidth,AHeight: Integer; Channels: Integer = 4);
var
I: Integer;
TempBytes: TArray<Byte>;
  begin

    if Channels = 4 then begin
      SetLength(TempBytes,4);
      for I := 0 to trunc(Length(ASource) / Channels) - 1 do begin
        Move(ASource[I * 4],TempBytes[0],4);
        ASource[(I * 4) + 0] := TempBytes[2];
        ASource[(I * 4) + 1] := TempBytes[1];
        ASource[(I * 4) + 2] := TempBytes[0];
      end;

    end else begin
      SetLength(TempBytes,3);
      for I := 0 to trunc(Length(ASource) / Channels) - 1 do begin
        Move(ASource[I * 3],TempBytes[0],3);
        ASource[(I * 3) + 0] := TempBytes[2];
        ASource[(I * 3) + 1] := TempBytes[1];
        ASource[(I * 3) + 2] := TempBytes[0];
      end;

    end;

  end;


procedure pglFlipImage(var ASource: TArray<Byte>; AWidth,AHeight: Integer; Channels: Integer = 4);
var
ByteWidth: Integer;
I: Integer;
Buffer: TArray<Byte>;
SourcePos,BufferPos: Integer;
  begin

    ByteWidth := trunc(AWidth * Channels);
    SetLength(Buffer,Length(ASource));
    SourcePos := 0;
    BufferPos := Length(Buffer) - ByteWidth;

    for I := 0 to AHeight - 1 do begin
      Move(ASource[SourcePos],Buffer[BufferPos],ByteWidth);
      Inc(SourcePos,ByteWidth);
      Dec(BufferPos,ByteWidth);
    end;

    Move(Buffer[0],ASource[0],Length(Buffer));

  end;


procedure pglAddImageAlphaChannel(var ASource: TArray<Byte>; AWidth,AHeight: Integer; Channels: Integer);
var
I: Integer;
OldLength,NewLength: Integer;
Buffer: TArray<Byte>;
SourcePos,BufferPos: Integer;
  begin

    OldLength := Length(ASource);
    NewLength := (AWidth * AHeight) * (Channels + 1);

    SetLength(Buffer,OldLength);
    Move(ASource[0],Buffer[0],OldLength);

    SetLength(ASource,NewLength);

    BufferPos := 0;
    SourcePos := 0;

    for I := 0 to trunc(Length(Buffer) / Channels) - 1 do begin
      Move(Buffer[BufferPos],ASource[SourcePos], Channels);
      ASource[SourcePos + 3] := 255;
      Inc(BufferPos,Channels);
      Inc(SourcePos,Channels + 1);
    end;
  end;


procedure pglRemoveImageAlphaChannel(var ASource: TArray<Byte>; AWidth,AHeight: Integer; Channels: Integer = 4);
var
I: Integer;
OldLength,NewLength: Integer;
Buffer: TArray<Byte>;
SourcePos,BufferPos: Integer;
  begin

    OldLength := Length(ASource);
    NewLength := (AWidth * AHeight) * (Channels - 1);

    SetLength(Buffer,OldLength);
    Move(ASource[0],Buffer[0],OldLength);

    SetLength(ASource,NewLength);

    BufferPos := 0;
    SourcePos := 0;

    for I := 0 to trunc(Length(Buffer) / Channels) - 1 do begin
      Move(Buffer[BufferPos],ASource[SourcePos], Channels - 1);
      Inc(BufferPos,Channels);
      Inc(SourcePos,Channels - 1);
    end;
  end;


function pglReadBMP(AFileName: AnsiString; out AWidth: Integer; out AHeight: Integer): Pointer;
var
BitMap: TPGLBitMapBuffer;
Buffer: array of Byte;
InFile: HFILE;
FileStruct: OFSTRUCT;
BytesRead: Cardinal;
  begin

    // Openg the file, get the file handle, and read the Bitmap header and info into the bitmap struct
    InFile := OpenFile(PAnsiChar(AnsiString(AFileName)), FileStruct, OF_PROMPT or OF_READ);
    ReadFile(InFile, BitMap, 54, BytesRead, nil);

    // Get the size of the image data and size the BitMap's data array and the buffer array
    BitMap.DataSize := BitMap.ImageSize;
    SetLength(BitMap.ImageData,BitMap.DataSize);
    // Buffer array is sized to be 32bpp
    SetLength(Buffer, (BitMap.Width * BitMap.Height) * 4);

    // Read the image data from the file into the BitMap's data array
    ReadFile(InFile, BitMap.ImageData[0], BitMap.DataSize, BytesRead, Nil);

    // Remove any row padding and adjust data size
    pglRemoveImageAlignment(BitMap.ImageData,BitMap.Width,BitMap.Height,trunc(BitMap.BPP / 8));
    BitMap.DataSize := Length(BitMap.ImageData);

    // Flip the bytes from BGRA to RGBA
    pglReverseImageBytes(BitMap.ImageData,BitMap.Width,BitMap.Height,trunc(BitMap.BPP / 8));

    // Flip the image vertically so that it's top-to-bottom
    pglFlipImage(BitMap.ImageData,BitMap.Width,BitMap.Height,trunc(BitMap.BPP / 8));

    // Add the alpha channel
    pglAddImageAlphaChannel(BitMap.ImageData,BitMap.Width,BitMap.Height,trunc(BitMap.BPP / 8));
    BitMap.DataSize := Length(BitMap.ImageData);
    Inc(BitMap.BPP,8);

    CloseHandle(InFile);

    Result := GetMemory(BitMap.DataSize);
    Move(BitMap.ImageData[0],Result^,BitMap.DataSize);

    AWidth := BitMap.Width;
    AHeight := BitMap.Height;

  end;


procedure pglWriteBmp(AFileName: AnsiString; ASource: Pointer; AWidth,AHeight: Integer; AChannels: Integer = 4);
var
CheckPointer: PByte;
CheckValue: Byte;
DataSize: Integer;
Buffer: TArray<Byte>;
BitMapBuffer: TPGLBitMapBuffer;
OutFile: HFILE;
FileStruct: OFSTRUCT;
BytesWritten: Cardinal;
Success: LongBool;
ErrorCode: Cardinal;
FileBuffer: PByte;
  begin

    // exit on nil pointer
    if ASource = nil then exit;

    // Check if number of channels is correct
    CheckPointer := ASource;

    try
      // if this succeeds, then the image is 32 bpp
      DataSize := (AWidth * AHeight) * AChannels;
      CheckValue := CheckPointer[DataSize - 1] // Ignore hint
    except
      // try to check for 24 bpp if 32 bpp check fails
      try
        // if this succeeds, then the image is 24 bpp
        AChannels := 3;
        DataSize := (AWidth * AHeight) * AChannels;
        CheckValue := CheckPointer[DataSize - 1]; // Ignore hint
      except
        // if 24 bpp check fails, then exit
        exit;
      end;
    end;

    SetLength(Buffer,DataSize);
    Move(ASource^,Buffer[0],DataSize);
    If AChannels = 4 Then Begin
      pglFlipImage(Buffer, AWidth, AHeight, 4);

      pglRemoveImageAlphaChannel(Buffer, AWidth, AHeight, 4);
      DataSize := Length(Buffer);

      pglReverseImageBytes(Buffer, AWidth, AHeight, 3);

      pglAlignImageData(Buffer,AWidth,AHeight);
      DataSize := Length(Buffer);

      AChannels := 3;
    End;

    // Fill buffer to write to file if checks succeeded
    BitMapBuffer.TypeChar := MakeWord(Ord('B'),Ord('M'));
    BitMapBuffer.FileSize := 54 + DataSize;
    BitMapBuffer.Reserved1 := 0;
    BitMapBuffer.Reserved2 := 0;
    BitMapBuffer.OffSet := 54;
    BitMapBuffer.HeaderSize := 40;
    BitMapBuffer.Width := AWidth;
    BitMapBuffer.Height := AHeight;
    BitMapBuffer.Planes := 1;
    BitMapBuffer.BPP := trunc(AChannels * 8);
    BitMapBuffer.Compression := 0;
    BitMapBuffer.ImageSize := DataSize;
    BitMapBuffer.HRes := 0;
    BitMapBuffer.VRes := 0;
    BitMapBuffer.PalleteColors := 0;
    BitMapBuffer.ImportantColors := 0;

    // Check for the file
    OutFile := OpenFile(PAnsiChar(AFileName),FileStruct,OF_CREATE or OF_WRITE);

    if OutFile = HFILE_ERROR then begin
      OutFile := CreateFileA(PAnsiChar(AFileName), GENERIC_ALL, 0,nil,CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,0);
    end;

    FileBuffer := GetMemory(BitMapBuffer.FileSize);
    Move(BitMapBuffer,FileBuffer[0],54);
    Move(Buffer[0],FileBuffer[54],DataSize);

    Success := WriteFile(OutFile,FileBuffer[0],BitMapBuffer.FileSize,BytesWritten,nil);

    FreeMemory(FileBuffer);
    CloseHandle(OutFile);


    // Check for errors
    If Success = False Then Begin
      ErrorCode := GetLastError(); // Ignore hint
    end else begin
      ErrorCode := GetLastError(); // Ignore hint
    End;


  end;

end.
