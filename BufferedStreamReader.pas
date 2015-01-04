//   Copyright 2015 Asbjørn Heid
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
unit BufferedStreamReader;

interface

uses
  System.SysUtils, System.Classes, BufferedStream;

type
  TBufferedStreamReaderOption = (BufferedStreamReaderOwnsSource);
  TBufferedStreamReaderOptions = set of TBufferedStreamReaderOption;

  /// <summary>
  ///  <para>
  ///  A simple text reader for streams.
  ///  </para>
  ///  <remarks>
  ///  <para>
  ///  NOTE: Always use the Stream property for accessing
  ///  the underlying source stream. Failure to do so will result in pain.
  ///  </para>
  ///  <para>
  ///  The reader relies on the TBufferedStream for parsing.
  ///  If the source stream is not a TBufferedStream the source will be
  ///  automatically wrapped by a TBufferedStream instance.
  ///  </para>
  ///  </remarks>
  /// </summary>
  TBufferedStreamReader = class
  strict private
    FOwnsSourceStream: boolean;
    FBufferedStream: TBufferedStream;
    FEncoding: TEncoding;
    FEndOfStream: boolean;

    function GetStream: TStream; inline;
    function GetBufferedData: TBytes; inline;

    property BufferedData: TBytes read GetBufferedData;
  public
    /// <summary>
    ///  Creates a bufferd stream reader instance.
    /// </summary>
    /// <param name="SourceStream">
    ///  Stream to read text from. If the SourceStream is not a TBufferedStream
    ///  it will be wrapped, in which case you should use the Stream property
    ///  if you need to read additional data after reading some text.
    /// </param>
    /// <param name="Encoding">
    ///  Encoding of the text. Note, BOM is not detected automatically.
    /// </param>
    constructor Create(const SourceStream: TStream;
      const Encoding: TEncoding;
      const Options: TBufferedStreamReaderOptions = []);
    destructor Destroy; override;


    /// <summary>
    ///  <para>
    ///  Reads a single line of text from the source stream.
    ///  Line breaks detected are LF, CR and CRLF.
    ///  </para>
    ///  <para>
    ///  If no more data can be read from the source stream, it
    ///  returns an empty string.
    ///  </para>
    /// </summary>
    function ReadLine: string;

    /// <summary>
    ///  <para>
    ///  Reads text from the source stream until a delimiter is found or
    ///  the end of the source stream is reached.
    ///  </para>
    ///  <para>
    ///  If no more data can be read from the source stream, it
    ///  returns an empty string.
    ///  </para>
    /// </summary>
    function ReadUntil(const Delimiter: UInt8): string; overload;

    /// <summary>
    ///  <para>
    ///  Reads text from the source stream until a text delimiter is found or
    ///  the end of the source stream is reached. The delimiter is encoded using
    ///  the current Encoding, and the encoded delimiter is used for matching.
    ///  </para>
    ///  <para>
    ///  If no more data can be read from the source stream, it
    ///  returns an empty string.
    ///  </para>
    /// </summary>
    function ReadUntil(const Delimiter: string): string; overload;

    /// <summary>
    ///  <para>
    ///  Reads any remaining text from the source stream.
    ///  </para>
    ///  <para>
    ///  If no more data can be read from the source stream, it
    ///  returns an empty string.
    ///  </para>
    /// </summary>
    function ReadToEnd: string;

    property Encoding: TEncoding read FEncoding;

    /// <summary>
    ///  The buffered stream. Use this if you need to read aditional
    ///  (possibly binary) data after reading text.
    /// </summary>
    property Stream: TStream read GetStream;
    property OwnsSourceStream: boolean read FOwnsSourceStream;

    /// <summary>
    ///  True if the end of the source stream was detected during the previous
    ///  read operation.
    /// </summary>
    property EndOfStream: boolean read FEndOfStream;
  end;

implementation

{ TBufferedStreamReader }

constructor TBufferedStreamReader.Create(const SourceStream: TStream;
  const Encoding: TEncoding; const Options: TBufferedStreamReaderOptions);
var
  opts: TBufferedStreamOptions;
begin
  inherited Create;

  if (SourceStream is TBufferedStream) then
  begin
    FBufferedStream := TBufferedStream(SourceStream);
    FOwnsSourceStream := BufferedStreamReaderOwnsSource in Options;
  end
  else
  begin
    FOwnsSourceStream := True;
    opts := [];
    if (BufferedStreamReaderOwnsSource in Options) then
      Include(opts, BufferedStreamOwnsSource);

    FBufferedStream := TBufferedStream.Create(SourceStream, opts);
  end;

  FEncoding := Encoding;
end;

destructor TBufferedStreamReader.Destroy;
begin
  if (FOwnsSourceStream) then
    FBufferedStream.Free;

  FBufferedStream := nil;

  inherited;
end;

function TBufferedStreamReader.GetBufferedData: TBytes;
begin
  result := FBufferedStream.BufferedData;
end;

function TBufferedStreamReader.GetStream: TStream;
begin
  result := FBufferedStream;
end;

function TBufferedStreamReader.ReadLine: string;
var
  curIndex, postLineBreakIndex: integer;
begin
  FEndOfStream := False;

  curIndex := 0;
  postLineBreakIndex := -1;

  while True do
  begin
    if (curIndex + 2 > Length(BufferedData)) and (not FEndOfStream) then
      FEndOfStream := not FBufferedStream.FillBuffer;

    if (curIndex >= Length(BufferedData)) then
    begin
      curIndex := Length(BufferedData);
      postLineBreakIndex := curIndex;
      break;
    end;

    if (BufferedData[curIndex] = 10) then
    begin
      postLineBreakIndex := curIndex + 1;
      break;
    end
    else if (BufferedData[curIndex] = 13) then
    begin
      if (curIndex + 1 < Length(BufferedData)) and (BufferedData[curIndex+1] = 10) then
        postLineBreakIndex := curIndex + 2
      else
        postLineBreakIndex := curIndex + 1;
      break;
    end;

    curIndex := curIndex + 1;
  end;

  result := Encoding.GetString(BufferedData, 0, curIndex);

  FBufferedStream.ConsumeBuffer(postLineBreakIndex);
end;

function TBufferedStreamReader.ReadToEnd: string;
begin
  FEndOfStream := False;

  while (not FEndOfStream) do
  begin
    FEndOfStream := not FBufferedStream.FillBuffer;
  end;

  result := Encoding.GetString(BufferedData, 0, Length(BufferedData));

  FBufferedStream.ConsumeBuffer(Length(BufferedData));
end;

function TBufferedStreamReader.ReadUntil(const Delimiter: string): string;
var
  encodedDelimiter: TBytes;
  curIndex, matchIndex, postDelimiterIndex: integer;
begin
  if (Delimiter = '') then
  begin
    result := ReadToEnd;
    exit;
  end;

  FEndOfStream := False;

  curIndex := 0;
  matchIndex := 0;
  postDelimiterIndex := -1;

  encodedDelimiter := Encoding.GetBytes(Delimiter);

  // TODO - perhaps some better algorithm than the naive scan
  while True do
  begin
    if (curIndex + 1 > Length(BufferedData)) and (not FEndOfStream) then
      FEndOfStream := not FBufferedStream.FillBuffer;

    if (curIndex >= Length(BufferedData)) then
    begin
      curIndex := Length(BufferedData);
      postDelimiterIndex := curIndex;
      break;
    end;

    if (BufferedData[curIndex] = encodedDelimiter[matchIndex]) then
    begin
      matchIndex := matchIndex + 1;
      if (matchIndex >= Length(encodedDelimiter)) then
      begin
        postDelimiterIndex := curIndex + 1;
        curIndex := postDelimiterIndex - matchIndex;
        break;
      end;
    end
    else
    begin
      // reset curIndex in case we've restarted the matching
      curIndex := curIndex - matchIndex;
      matchIndex := 0;
    end;

    curIndex := curIndex + 1;
  end;

  result := Encoding.GetString(BufferedData, 0, curIndex);

  FBufferedStream.ConsumeBuffer(postDelimiterIndex);
end;

function TBufferedStreamReader.ReadUntil(const Delimiter: UInt8): string;
var
  curIndex, postDelimiterIndex: integer;
begin
  FEndOfStream := False;

  curIndex := 0;
  postDelimiterIndex := -1;

  while True do
  begin
    if (curIndex + 1 > Length(BufferedData)) and (not FEndOfStream) then
      FEndOfStream := not FBufferedStream.FillBuffer;

    if (curIndex >= Length(BufferedData)) then
    begin
      curIndex := Length(BufferedData);
      postDelimiterIndex := curIndex;
      break;
    end;

    if (BufferedData[curIndex] = Delimiter) then
    begin
      postDelimiterIndex := curIndex + 1;
      break;
    end;

    curIndex := curIndex + 1;
  end;

  result := Encoding.GetString(BufferedData, 0, curIndex);

  FBufferedStream.ConsumeBuffer(postDelimiterIndex);
end;

end.
