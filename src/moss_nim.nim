import encodings, glob, net, os, strutils, tables

const
  LANGUAGES = ["c", "cc", "java", "ml", "pascal", "ada", "lisp", "scheme",
      "haskell", "fortran", "ascii", "vhdl", "verilog", "perl", "matlab",
      "python", "mips", "prolog", "spice", "vb", "csharp", "modula2", "a8086",
      "javascript", "plsql"]
  SERVER: string = "moss.stanford.edu"
  PORT: Port = Port(7690)

type MossNim = object
  userid: string
  options: Table[string, string]
  baseFiles: seq[(string, string)]
  files: seq[(string, string)]

proc getLanguages*(obj: var MossNim): array[len(LANGUAGES),
    string] = return LANGUAGES

proc setIgnoreLimit*(obj: var MossNim, m: string) = obj.options["m"] = m

proc setCommentString*(obj: var MossNim, c: string) = obj.options["c"] = c

proc setNumberOfMatchingFiles*(obj: var MossNim, n: string) =
  if n.parseInt > 1:
    obj.options["n"] = n

proc setDirectoryMode*(obj: var MossNim, mode: string) = obj.options["d"] = mode

proc setExperimentalServer*(obj: var MossNim, opt: string) = obj.options["x"] = opt

proc addBaseFile*(obj: var MossNim, filePath: string,
    displayName: string = "") =
  if fileExists(filePath) and getFileSize(filePath) > 0:
    obj.baseFiles.add((filePath, displayName))
  else:
    raise newException(IOError, "File '$#' not found or is empty" % filePath)

proc addFile*(obj: var MossNim, filePath: string, displayName: string = "") =
  if fileExists(filePath) and getFileSize(filePath) > 0:
    obj.files.add((filePath, displayName))
  else:
    raise newException(IOError, "File '$#' not found or is empty" % filePath)

proc addFilesByWildcard*(obj: var MossNim, wildcard: string) =
  for path in walkGlob(wildcard):
    obj.addFile(path)

proc uploadFile(obj: var MossNim, socket: Socket, filePath, displayName: string,
    fileID: int, onSend: proc(a, b: string) = proc(a, b: string) = discard) =
  var dispname = if displayName == "": filePath.replace(" ", "_").replace("\\",
      "/") else: displayName

  var message = "file $# $# $# $#\n" % [$fileID, obj.options["l"], $getFileSize(
      filePath), dispname]
  socket.send(message.convert())
  socket.send(readFile(filePath))
  onSend(filePath, dispname)

proc send*(obj: var MossNim, displayName = "", onSend: proc(a,
    b: string) = proc(a, b: string) = discard): string =
  var socket = newSocket()
  socket.connect(SERVER, PORT)
  echo("Connected to server")
  socket.send("moss $#\n" % obj.userid.convert())
  socket.send("directory $#\n" % obj.options["d"].convert())
  socket.send("X $#\n" % obj.options["x"].convert())
  socket.send("maxmatches $#\n" % obj.options["m"].convert())
  socket.send("show $#\n" % obj.options["n"].convert())
  socket.send("language $#\n" % obj.options["l"].convert())

  if socket.recvLine() == "no":
    socket.send("end\n".convert())
    socket.close()
    raise newException(ValueError, "Language not accepted by the Moss server")

  for (filePath, displayName) in obj.baseFiles:
    echo "Uploading base file $#" % filePath
    obj.uploadFile(socket, filePath, displayName, 0, onSend)

  for ind, (filePath, displayName) in obj.files:
    echo "Uploading file $#" % filePath
    obj.uploadFile(socket, filePath, displayName, ind+1, onSend)

  socket.send("query 0 $#\n" % obj.options["c"].convert())
  echo("Query submitted. Waiting for response from server...")

  var response = socket.recvLine()

  socket.send("end\n".convert())
  socket.close()

  return response.replace("\n", "")

proc initMossNim*(userid: string, language: string): MossNim =
  var obj: MossNim
  obj.userid = userid
  obj.options = {"l": "c", "m": "10", "d": "0", "x": "0", "c": "",
      "n": "250"}.toTable
  obj.options["l"] = if language in LANGUAGES: language else: raise newException(
      ValueError, "Invalid/unsupported language specified -- $#." % language)
  obj.baseFiles = @[]
  obj.files = @[]
  return obj
