program BufferedStreamTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  WinAPI.Windows,
  System.SysUtils,
  System.Classes,
  BufferedStream in 'BufferedStream.pas',
  BufferedStreamReader in 'BufferedStreamReader.pas';

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
  bs: TBufferedStream;
  data: array[0..9] of UInt8;
begin
  ss := nil;
  bs := nil;
  try
    ss := TBytesStream.Create(GetData());
    bs := TBufferedStream.Create(ss, [], 3);

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
  sr: TBufferedStreamReader;
  s: string;
begin
  ss := nil;
  sr := nil;
  try
    ss := TBytesStream.Create(GetData());
    sr := TBufferedStreamReader.Create(ss, TEncoding.UTF8);

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
  sr: TBufferedStreamReader;
  s: string;
begin
  ss := nil;
  sr := nil;
  try
    ss := TBytesStream.Create(GetData());
    sr := TBufferedStreamReader.Create(ss, TEncoding.UTF8, [BufferedStreamReaderOwnsSource]);

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

begin
  try
    SetConsoleOutputCP(CP_UTF8);

    RunTest1;

    RunTest2;

    RunTest3;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  ReadLn;
end.
