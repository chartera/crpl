import os, strutils, threadpool, asyncdispatch, parseopt, tables

var callbacks = tables.initTable[string, proc(params: varargs[string]): string]()
var infos: seq[string] = @[]
var pointer: string
var temp_head = """ 
__________CRPL____________

"""
var temp_foot = """ 

___________-.-______________
"""

proc info(params: varargs[string]): string =
  result =
    temp_head & "\n" &
      strutils.join(infos, "\n") &
      "\n " & temp_foot
      
proc callback_dash_dash(key: string, val: varargs[string]): void =
  if tables.hasKey(callbacks, key):
    echo(callbacks[key](val))
  else:
    echo("Command not available, try --i")

proc param_to_callback*(arg: string, info: string,  callback:
                        proc(params: varargs[string]): string) =
  infos.add(info)
  tables.add(callbacks, arg, callback)


proc c_callback(p: OptParser, key: string): void =
  try:
    var rest: TaintedString = cmdLineRest(p)
    var args = split(rest.string, " ")
    var args_list: seq[string] = @[]

    for i, arg in args:
      args_list.add(args[i].split("=")[1])    

    callback_dash_dash("--" & key, args_list)
    echo(pointer & " ")
  except:
    echo("Command not available, try --i")
    write(stdout, "> ")

    
proc parse_cmd*(c: string): void =
  var cmd: string = c
  if cmd.len == 0:
      cmd = "--i"      
  var p = parseopt.initOptParser(cmd)
  for kind, key, val in p.getopt():
    case kind
    of cmdArgument:
      parse_cmd("--i")
      break
    of cmdLongOption:
      case key
      of "b", "d", "e", "f", "g", "h", "i", "j", "k", "m", "n", "o",
           "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z":
        callback_dash_dash("--" & key, val)
        write(stdout, pointer & " ")
        break
      of "a":
        c_callback(p, key)
        break
      of "c":
        c_callback(p, key)
        break
      of "l":
        c_callback(p, key)
      else:
        parse_cmd("--i")
        break
    of cmdShortOption:     # bugg!!!!
      parse_cmd("--i")
      break
    of cmdEnd: assert(false)

proc defaults(): void =
  pointer = "> "
  param_to_callback("--i", "--i See all arguments", info)
    
proc start_cmd*(params: string): void =
  defaults()
  parse_cmd(params)

var cmd: FlowVar[string]
var re: string

proc start_repl*() {.async.} =
  cmd = spawn readline(stdin)
  while threadpool.isReady(cmd) == false:
    await asyncdispatch.sleepAsync(1000)  
  re = ^cmd
  parse_cmd(re)
  waitFor start_repl()
    
defaults()
echo("\n")
parse_cmd("--i")
