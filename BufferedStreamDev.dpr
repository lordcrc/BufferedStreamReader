program BufferedStreamDev;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  WinAPI.Windows,
  System.SysUtils,
  System.Classes,
  BufStream in 'BufStream.pas',
  BufStreamReader in 'BufStreamReader.pas',
  EncodingHelper in 'EncodingHelper.pas';

function GetData: TBytes;
begin
  result := TEncoding.UTF8.GetBytes(
    'This is a test' + #13#10 +
    'Это тест' + #13#10 +
    '0123456789');
end;

procedure RunTest1;
var
  ss: TBytesStream;
  bs: BufferedStream;
  data: array[0..9] of UInt8;
begin
  ss := nil;
  bs := nil;
  try
    ss := TBytesStream.Create(GetData());
    bs := BufferedStream.Create(ss, [], 3);

    bs.FillBuffer;
    WriteLn('Source position: ', ss.Position);
    WriteLn('Buffer position: ', bs.Position);
    WriteLn;

    bs.ConsumeBuffer(1);
    WriteLn('Source position: ', ss.Position);
    WriteLn('Buffer position: ', bs.Position);
    WriteLn;

    bs.Read(data, SizeOf(data));
    WriteLn('Source position: ', ss.Position);
    WriteLn('Buffer position: ', bs.Position);
    WriteLn;
    WriteLn;
  finally
    bs.Free;
    ss.Free;
  end;
end;

procedure RunTest2;
var
  ss: TBytesStream;
  sr: BufferedStreamReader;
  s: string;
begin
  ss := nil;
  sr := nil;
  try
    ss := TBytesStream.Create(GetData());
    sr := BufferedStreamReader.Create(ss, TEncoding.UTF8);

    s := sr.ReadLine;
    WriteLn('Line data: "' + s + '"');
    WriteLn('Source position: ', ss.Position);
    WriteLn('Buffer position: ', sr.Stream.Position);
    WriteLn;

    s := sr.ReadLine;
    WriteLn('Line data: "' + s + '"');
    WriteLn('Source position: ', ss.Position);
    WriteLn('Buffer position: ', sr.Stream.Position);
    WriteLn;

    s := sr.ReadLine;
    WriteLn('Line data: "' + s + '"');
    WriteLn('Source position: ', ss.Position);
    WriteLn('Buffer position: ', sr.Stream.Position);
    WriteLn;
    WriteLn;
  finally
    sr.Free;
    ss.Free;
  end;
end;

procedure RunTest3;
var
  ss: TBytesStream;
  sr: BufferedStreamReader;
  s: string;
begin
  sr := nil;
  try
    ss := TBytesStream.Create(GetData());
    sr := BufferedStreamReader.Create(ss, TEncoding.UTF8, [BufferedStreamReaderOwnsSource]);

    s := sr.ReadUntil(' т');
    WriteLn('Line data: "' + s + '"');
    WriteLn('Source position: ', ss.Position);
    WriteLn('Buffer position: ', sr.Stream.Position);
    WriteLn;

    s := sr.ReadUntil(13);
    WriteLn('Line data: "' + s + '"');
    WriteLn('Source position: ', ss.Position);
    WriteLn('Buffer position: ', sr.Stream.Position);
    WriteLn;

    s := sr.ReadLine;
    WriteLn('Line data: "' + s + '"');
    WriteLn('Source position: ', ss.Position);
    WriteLn('Buffer position: ', sr.Stream.Position);
    WriteLn;

    s := sr.ReadToEnd;
    WriteLn('Line data: "' + s + '"');
    WriteLn('Source position: ', ss.Position);
    WriteLn('Buffer position: ', sr.Stream.Position);
    WriteLn;
    WriteLn;
  finally
    sr.Free;
  end;
end;

procedure RunTest4;
var
  ss: TBytesStream;
  sr: BufferedStreamReader;
  c: TCharArray;
  s: string;
begin
  sr := nil;
  try
    ss := TBytesStream.Create(GetData());
    sr := BufferedStreamReader.Create(ss, TEncoding.UTF8, [BufferedStreamReaderOwnsSource]);

    sr.ReadLine;

    c := sr.ReadChars(1);
    SetString(s, PChar(@c[0]), Length(c));
    WriteLn('Line data: "' + s + '"');
    WriteLn('Source position: ', ss.Position);
    WriteLn('Buffer position: ', sr.Stream.Position);
    WriteLn;

    c := sr.ReadChars(2);
    SetString(s, PChar(@c[0]), Length(c));
    WriteLn('Line data: "' + s + '"');
    WriteLn('Source position: ', ss.Position);
    WriteLn('Buffer position: ', sr.Stream.Position);
    WriteLn;
    WriteLn;
  finally
    sr.Free;
  end;
end;

begin
  try
    SetConsoleOutputCP(CP_UTF8);

//    RunTest1;
//
//    RunTest2;
//
//    RunTest3;

    RunTest4;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  ReadLn;
end.
