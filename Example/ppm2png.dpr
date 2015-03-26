program ppm2png;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  PPMConverter in 'PPMConverter.pas';

procedure PrintUsage;
begin
  WriteLn('Usage:');
  WriteLn('  ppm2png inputfile [outputfile]');
  WriteLn;
end;

var
  inputFilename: string;
  outputFilename: string;
begin
  try
    if (ParamCount < 1) then
    begin
      PrintUsage();
      exit;
    end;

    inputFilename := ParamStr(1);

    if (ParamCount < 2) then
      outputFilename := ChangeFileExt(inputFilename, '.png')
    else
      outputFilename := ParamStr(2);


    ConvertPPMtoPNG(inputFilename, outputFilename);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
