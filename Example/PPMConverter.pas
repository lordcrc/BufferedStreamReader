unit PPMConverter;

interface

procedure ConvertPPMtoPNG(const InputFilename, OutputFilename: string);

implementation

uses
  System.SysUtils, System.Classes, BufStream, BufStreamReader, Vcl.Imaging.pngimage,
  System.Math;

{$POINTERMATH ON}

type
  PUInt8 = ^UInt8;
  PUInt16 = ^UInt16;
  PPMtoPNGConverter = class
  strict private
    type PPMHeader = record
      Width: integer;
      Height: integer;
      MaxValue: integer;
    end;
    // valid PPM header delimiters: tab, lf, cr, space
    const HeaderDelims: array[0..3] of UInt8 = (9, 10, 13, 32);
  strict private
    FHeader: PPMHeader;
    FReader: BufferedStreamReader;

    procedure VerifyMagic;
    function SkipSingleWhitespace: boolean;
    procedure SkipWhitespace;
    function ReadHeaderProperty: string;

    procedure ReadHeader;

    procedure RunConversion(const OutputStream: TStream);

    property Header: PPMHeader read FHeader;
    property Reader: BufferedStreamReader read FReader;
  public
    procedure Convert(const InputFilename, OutputFilename: string);
  end;

procedure ConvertPPMtoPNG(const InputFilename, OutputFilename: string);
var
  c: PPMtoPNGConverter;
begin
  c := nil;
  try
    c := PPMtoPNGConverter.Create;

    c.Convert(InputFilename, OutputFilename);
  finally
    c.Free;
  end;
end;

{ PPMtoPNGConverter }

procedure PPMtoPNGConverter.Convert(const InputFilename, OutputFilename: string);
var
  outs: TFileStream;
begin
  outs := nil;
  try
    FReader := BufferedStreamReader.Create(
      TFileStream.Create(InputFilename, fmOpenRead, fmShareDenyWrite),
      TEncoding.ASCII, // per PPM specification
      [BufferedStreamReaderOwnsSource]
    );

    VerifyMagic;

    ReadHeader;

    outs := TFileStream.Create(OutputFilename, fmCreate, fmShareExclusive);

    RunConversion(outs);

  finally
    FReader.Free;
    outs.Free;
  end;
end;

procedure PPMtoPNGConverter.ReadHeader;
var
  s: string;
begin
  s := ReadHeaderProperty;
  FHeader.Width := StrToInt(s);

  s := ReadHeaderProperty;
  FHeader.Height := StrToInt(s);

  s := ReadHeaderProperty;
  FHeader.MaxValue := StrToInt(s);

  // header should only have single whitespace character
  // after it, before the binary image data
  // the ReadUntil call in ReadHeaderProperty will
  // consume this character, so we can start reading
  // the image data after this
end;

function PPMtoPNGConverter.ReadHeaderProperty: string;
begin
  SkipWhitespace;
  result := Reader.ReadUntil(HeaderDelims);
end;

procedure PPMtoPNGConverter.RunConversion(const OutputStream: TStream);

  procedure ConvertLine8bit(const SrcLine, DestLine: pointer; const Width: integer);
  var
    s, d: PUInt8;
    x: integer;
  begin
    s := SrcLine;
    d := DestLine;
    for x := 0 to Width-1 do
    begin
      d[3 * x + 2] := s[3 * x + 0];
      d[3 * x + 1] := s[3 * x + 1];
      d[3 * x + 0] := s[3 * x + 2];
    end;
  end;


  procedure ConvertLine16bit(const SrcLine, DestLine1, DestLine2: pointer; const Width: integer);
  var
    s, d1, d2: PUInt8;
    x: integer;
  begin
    s := SrcLine;
    d1 := DestLine1;
    d2 := DestLine2;
    for x := 0 to Width-1 do
    begin
      d1[3 * x + 2] := s[6 * x + 0];
      d2[3 * x + 2] := s[6 * x + 1];

      d1[3 * x + 1] := s[6 * x + 2];
      d2[3 * x + 1] := s[6 * x + 3];

      d1[3 * x + 0] := s[6 * x + 4];
      d2[3 * x + 0] := s[6 * x + 5];
    end;
  end;

var
  png: TPngImage;
  bytesPerChannel: integer;
  line: TBytes;
  y: integer;
begin
  png := nil;
  try
    bytesPerChannel := 1;
    if (Header.MaxValue > 255) then
      bytesPerChannel := 2;

    png := TPngImage.CreateBlank(COLOR_RGB, 8 * bytesPerChannel, Header.Width, Header.Height);

    SetLength(line, 3 * Header.Width * bytesPerChannel);

    for y := 0 to Header.Height-1 do
    begin
      // read one row of binary image data from input stream
      Reader.Stream.ReadBuffer(line[0], Length(line));

      if (bytesPerChannel = 1) then
        ConvertLine8bit(@line[0], png.Scanline[y], Header.Width)
      else
        ConvertLine16bit(@line[0], png.Scanline[y], png.ExtraScanline[y], Header.Width);
    end;

    png.SaveToStream(OutputStream);
  finally
    png.Free;
  end;
end;


function PPMtoPNGConverter.SkipSingleWhitespace: boolean;
var
  nextChar: integer;
begin
  result := False;

  // check next character
  nextChar := Reader.Peek;

  if (  (nextChar <> HeaderDelims[0])
    and (nextChar <> HeaderDelims[1])
    and (nextChar <> HeaderDelims[2])
    and (nextChar <> HeaderDelims[3])
  ) then
    exit;

  // consume delimiter
  Reader.ReadChars(1);
end;

procedure PPMtoPNGConverter.SkipWhitespace;
begin
  while SkipSingleWhitespace do
  begin
  end;
end;

procedure PPMtoPNGConverter.VerifyMagic;
var
  magic: TCharArray;
begin
  magic := Reader.ReadChars(2);

  if (Length(magic) <> 2) or (magic[0] <> 'P') or (magic[1] <> '6') then
    raise Exception.Create('Input file is not a valid Portable PixMap (binary)');
end;

end.
