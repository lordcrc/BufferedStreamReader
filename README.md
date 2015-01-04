BufferedStreamReader
====================

A simple, buffered TStreamReader replacement for Delphi. 

Unlike the TStreamReader in the RTL, it can be used to process any remaining 
data after reading some text.

Two classes are provided:

`TBufferedStreamReader` class which takes a TStream and has methods to read 
text from the stream, as well as allowing for the unread (possibly binary) data 
to be processed further. It has methods to read a line, until a byte or 
string delimiter, or until the end of the stream.

`TBufferedStream` class which acts as a read-only buffered TStream 
implementation which provides access to the buffer and has methods to
fill and consume the buffer. The position is tracked according to the consumed
bytes, so reading from the `TBufferedStream` does not skip buffered data.
