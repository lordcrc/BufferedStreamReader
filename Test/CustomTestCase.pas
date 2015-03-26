unit CustomTestCase;

interface

uses
  TestFramework;

type
  TCustomTestCase = class(TTestCase)
  public
    procedure CheckNotNull(obj: pointer; msg: string = ''); overload; virtual;
    procedure CheckNull(obj: pointer; msg: string = ''); overload; virtual;
  end;

implementation

{ TCustomTestCase }

procedure TCustomTestCase.CheckNotNull(obj: pointer; msg: string);
begin
  FCheckCalled := True;
  if obj = nil then
    FailNotSame('pointer', PtrToStr(obj), msg, ReturnAddress);
end;

procedure TCustomTestCase.CheckNull(obj: pointer; msg: string);
begin
  FCheckCalled := True;
  if obj <> nil then
    FailNotSame('nil', PtrToStr(obj), msg, ReturnAddress);
end;

end.
