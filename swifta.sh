#!/bin/bash

# --- A. GLOBAL VARIABLES & CONSTANTS --- #

modPath=~/swift # default swift repo
cgiPath=~/web   # default web folder
success=false   # process result

# --- B. GLOBAL UTILITY FUNCTIONS (it's best to not access [A])--- #

# get color index by name
function color() {
  local col="$1"
  if ! [[ $col =~ '^[0-9]$' ]]; then
    case $(echo $col | tr '[:upper:]' '[:lower:]') in
      black)   col=0 ;;
      red)     col=1 ;;
      green)   col=2 ;;
      yellow)  col=3 ;;
      blue)    col=4 ;;
      magenta) col=5 ;;
      cyan)    col=6 ;;
      white)   col=7 ;;
      *)       col=-1;;
    esac
  fi
  echo "$col"
}

# print with color - no new line
function printnl() {
  # $2 is foreground color
  if [ ! $2 == "" ]; then tput setaf $(color $2); fi
  # $3 is background color OR style
  if [ ! $3 == "" ]; then
    if [ $(color $3) -ge 0 -a $(color $3) -le 9 ]; then 
      tput setab $(color $3)
    else
      tput $3
    fi
  fi
  # $4 is style
  if [ ! $4 == "" ]; then tput $4; fi 
  echo -e "$1\c"
  if [ ! $2 == "" ]; then tput sgr0; fi # reset
}

# print with new line
function print() {
  printnl "$@"; echo
}

# split file name into its parts
splitPath() {
  local sp_dir= sp_fname= sp_bname= sp_ext=
  (( $# >= 2 )) || {
    echo "ERROR: Specify input path with an output variable name." >&2
    exit 2
  }
  sp_dir=$(dirname "$1")
  sp_fname=$(basename "$1")
  sp_ext=$([[ $sp_fname = *.* ]] && printf %s ".${sp_fname##*.}" || printf '')
  if [[ "$sp_fname" == "$sp_ext" ]]; then
    sp_bname=$sp_fname
    sp_ext=''
  else
    sp_bname=${sp_fname%$sp_ext}
  fi
  [[ -n $2 ]] && printf -v "$2" "$sp_dir"
  [[ -n $3 ]] && printf -v "$3" "$sp_fname"
  [[ -n $4 ]] && printf -v "$4" "$sp_bname"
  [[ -n $5 ]] && printf -v "$5" "$sp_ext"
  return 0 # true
}

# check file existence
fileExist() {
  if [ -f "$1" ]; then
    return 0 # true
  else
    return 1 # false
  fi
}

# check directory existence
dirExist() {
  if [ -d "$1" ]; then
    return 0 # true
  else
    return 1 # false
  fi
}

# remove file with existence check
removeFile() {
  for f in "$@"; do
    if [ -f "$f" ]; then
      local CMD="rm $f"; echo "\$ $CMD"; eval $CMD;
    fi
  done
}

# execute shell command with echo
execCommand() {
  for f in "$@"; do
    local CMD="$f"; echo "\$ $CMD"; eval $CMD;
  done
}

# --- C. INTERNAL PROGRAM FUNCTIONS (depends on [A] and [B]) --- #

# compile each un-compiled swift module
compileMod() {
  local fDir= ffName= fbName= fExt=
  splitPath "$1" fDir ffName fbName fExt
  if fileExist "$fbName.swiftmodule" || fileExist "$modPath/$fbName.swiftmodule"; then
    print "# NOTE: Module $fbName had been compiled." yellow
  else
    print "# Compiling module $1.swift ..." green
    execCommand "swiftc -O -emit-library -emit-object $fDir/$fbName.swift -module-name $fbName"
    if fileExist "$fbName.o"; then
      execCommand "ar rcs lib$fbName.a $fbName.o"
      execCommand "swiftc -O -emit-module $fDir/$fbName.swift -module-name $fbName"
    else
      print "# ERROR: Compilation failed!" red
      return 1 # false
    fi
  fi
  return 0 # true
}

# compile all imported swift modules (1 level depth)
compileMods() {
  # search for import clause
  local mods=$(awk '{for(i=0;i<=NF;i++) if ($i=="import") print $(i+1)}' $1)
  for src in $mods; do
    if fileExist "$src.swift"; then 
      #compileMods "$src.swift"
      if ! compileMod "$src"; then return 1; fi
    elif fileExist "$modPath/$src.swift"; then
      #compileMods "$modPath/$src.swift"
      if ! compileMod "$modPath/$src"; then return 1; fi
    else 
      print "# NOTE: $src.swift file is not found." yellow
    fi
  done
  return 0 # true
}

# compile swift main program
compileMain() {
  local main=main
  local fDir= ffName= fbName= fExt=
  splitPath "$1" fDir ffName fbName fExt
  # main program must be named main.swift
  execCommand "cp $fDir/$ffName $main.swift"
  # compile main program
  if compileMods "$main.swift"; then
    # generate list of modules parameter
    local mods="-I . -L . -I $modPath -L $modPath"
    local import=$(awk '{for(i=0;i<=NF;i++) if ($i=="import") print $(i+1)}' $main.swift)
    for mod in $import; do
      if fileExist "$mod.swiftmodule"; then
        mods="$mods -l$mod"
      else
        print "# NOTE: Module $mod is skipped." yellow
      fi
    done
    print "# Compiling main $fDir/$ffName ..." green
    execCommand "swiftc $main.swift -O $mods -o $fbName $2 $3 $4 $5 $6 $7 $8 $9"
    if ! fileExist "$fbName"; then return 1; fi
  else
    print "# ERROR: Compilation failed!" red
    return 1 # false
  fi
  return 0 # true
}

# --- MAIN PROGRAM --- #

splitPath "$1" FDIR FFNAME FBNAME FEXT

# tool help
if [ "$1" == "" ]; then
  echo "Usage: swifta [main source file] <options>"
  echo "Options: "
  echo " -run  Run the executable after compilation."
  echo "       The executable will be deleted after run."
  #echo " -mod  Compile as module instead of executable."
  #echo "       <Module path> Path to module output."
  echo " -cgi  Deploy executable as CGI app."
  echo "       <CGI path> Path to CGI folder."
  #echo " -inc  Include a folder into compilation."
  #echo "       [include path] Path to included folder."
  echo " other options are passed-on to the compiler."
  echo "_____"
  echo "ERROR: You must supply a source file as an argument."
  return 1
fi

# quit on inexistence main program
if [ ! -f "$1" ]; then
  print "ERROR: \"$1\" source file is not found." red
  return 1
fi

# interpret and save parameters
i=1
pIsRun=false
pIsCGI=false
for arg in "$@"; do
  # this way will allow argument to be put anywhere in the list
  if [ $arg == "-run" ]; then
    pIsRun=true
    # cut this argument out of the list
    set -- "${@:1:($i-1)}" "${@:($i+1):$#}"
  elif [ $arg == "-cgi" ]; then
    pIsCGI=true
    set -- "${@:1:($i-1)}" "${@:($i+1):$#}"
    if dirExist "${!i}"; then
      cgiPath="${!i}" # replace default path
      set -- "${@:1:($i-1)}" "${@:($i+1):$#}"
    fi
  # check for main program duplication and skip it
  # WARNING: do not reverse the comparation sequence
  elif [ $arg == "$1" ] && [[ $i > 1 ]]; then
    set -- "${@:1:($i-1)}" "${@:($i+1):$#}"
  else
    let "i++"
  fi
done
cArgs="$2 $3 $4 $5 $6 $7 $8 $9" # skip $1

swiftc -v
print "# Compiling $1 program ... " green
if compileMain $1 $cArgs; then
  if $pIsRun; then
    print "# Executing $FBNAME ..." green
    execCommand "./$FBNAME"
  elif $pIsCGI; then
    print "# Deploying $FBNAME.cgi to $cgiPath ..." green
    execCommand "mv $FBNAME $cgiPath/$FBNAME.cgi"
  fi
  success=true
else
  success=false
fi

print "# Cleaning up garbage files ..." green
removeFile main.swift
removeFile *.a
removeFile *.o
removeFile *.swiftdoc
removeFile *.swiftmodule
if $pIsRun; then removeFile $FBNAME; fi
    
if $success; then 
  print "# Done successfully." green
else 
  print "# Done with error!" red
fi