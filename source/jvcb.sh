#! /usr/bin/env bash
source colours.sh 
source env.sh 

# Variables de programa
name="jvcb"
configFile="$config/.compile" # Fichero de configuración

bin='bin/'     # Carpet destino con los ejecutables
run=""         # Execution java file
args=""        # Execution arguments
compile=""     # Files to compile
exclude=""     # Exclude files
info=1         # Mode Information
loaded=1       # Flag is load the configuration file
editor="vi"  # Editor

error="/tmp/error"  # File which will content the message error

loadConfiguration () {
     ! [ -e $configFile ] || ! [ -f $configFile ] && return 1
     while read line; do 
          line=$(echo $line | sed "s|--.*||")
          ! [ -n "$line" ] && continue
          action=$(echo "$line" | cut -d '=' -f 1 | tr -d '[:space:]')
          value=$(echo "$line" | cut -d '=' -f 2)
          case "$action" in
               exclude)
                    exclude=$(echo "$value" | tr ',' ' ')
               ;;
               bin) 
                    bin="$value"
               ;;
               editor)
                    editor="$value"
               ;;
               error)
                    error="$value"
               ;;
               info)
                    if [ $value -eq 0 ]; then
                         info=0
                    else
                         info=1
                    fi
               ;;
               *) 
                    echo "Unkowed instruction $actio=$value" 
               ;;
          esac
     done < <(cat $configFile)
     loaded=0
}

saveExit () {
     echo -e "\n${BOLD}${RED}MESSAGE ERROR${RESET}${RED}:\n$1${RESET}\n"
     if [ -e "$error" ] && [ -f "$error" ] && [[ "$(cat $error)"  != "" ]]; then
          echo -e "${RED}${BOLD}ERROR DESCRIPTION:${RESET}${RED}\n$(cat $error)${RESET}\n"
          rm $error
     fi
     exit 1
}

parseArgs () {
     local sinfo=1
     local argsMode=0    # flag to indicate we are recollecting execution args 
                         # 0 -> compile files
                         # 1 -> args execution
                         # 2 -> exclude files
     for i in "${@}"; do
          if [[ "$1" == "-c" || "$1" == "--config" ]]; then
               $editor $configFile
               exit 0
          elif [[ "$1" == "-a" || "$1" == "--args" ]]; then
               argsMode=1
               shift
          elif [[ "$1" == "-e" || "$1" == "--exclude" ]]; then
               argsMode=2
               shift
          elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
               echo "help" && exit 0
          elif [[ "$1" == "-i" || "$1" == "--info" ]]; then
               info=0
               shift
          elif [[ "$1" == "-s" || "$1" == "--sinfo" ]]; then
               sinfo=0
               shift
          elif [[ "$1" == "-r" || "$1" == "--run" ]]; then
               [ $argsMode -ne 0 ] && saveExit "Incorrect use\nFor more information use $name -h or $name --help"
               shift
               run="$1"
          elif [[ "$1" == "-b" || "$1" == "--bin" ]]; then
               command="$1"
               shift
               [[ "$1" == "" ]] && saveExit "Incorrect use for $command.\n${BOLD}USE${RESET}${RED}: $name ... -b bin_dir"
               bin="$1"
               shift
          else 
               element="$1"
               shift
               if [ $argsMode -eq 0 ]; then
                    [[ "$compile" == "" ]] && compile="$element" && continue
                    compile="$compile $element"
               elif [ $argsMode -eq 1 ]; then
                    [[ "$args" == "" ]] && args="$element" && continue
                    args="$args $element"
               elif [ $argsMode -eq 2 ]; then
                    [[ "$exclude" == "" ]] && exclude="$element" && continue
                    exclude="$exclude $element"
               fi
          fi
     done
     [[ "$compile" == "" ]] && saveExit "the program need elements to compile"
     ! [[ -e $bin  && ! -d $bin ]] && mkdir -p $bin 2> $error || saveExit "failed attempt to create $bin dir"
     for i in $exclude; do
          echo "$i in $compile"
          compile=$(echo "$compile" | sed "s/ \b$i\b//g")
     done
     [ $sinfo -eq 0 ] && 
          echo -e "${BOLD}INFO${RESET}" &&
          echo -e "\tbin='$bin'" &&
          echo -e "\tcompile='$compile'" &&
          echo -e "\trun='$run'" &&
          echo -e "\targs='$args'" &&
          echo -e "\texclude='$exclude'" &&
          echo -e "\teditor='$editor'" &&
          echo -e "\tloaded='$loaded'" 
}               

cleanClassFiles () { 
     classFiles=$(find $bin | grep .class)
     [ -n "$classFiles" ] && rm  $classFiles
}

compileFiles () {
     javac -d $bin $compile 2> $error
     [[ $? -ne 0 ]] && saveExit "compilation has failed" $error
     if [ $info -eq 0 ]; then
          echo -e "\n${GREEN}Files compiled:"
          for i in $(find $bin | grep .class | sed "s|$bin/||g" | sed "s|.class|.java|g" | grep -vF "$"); do
               echo -e "\t${GREEN}· ${i}${RESET}"
          done
     fi
     echo -e "\n${BOLD}${GREEN}DONE!!!${RESET}${GREEN} compiled ${BOLD}succesfully${RESET}"
}

# Cargamos la configuración por defecto y transformamos los argumentos
loadConfiguration
parseArgs $@

cleanClassFiles
compileFiles

! [ -n "$run" ] && exit 0

package=$(cat $run | grep -w package)
if [[ "$package" != "//"* ]]; then
     package=$(echo "$package"| sed "s/\bpackage\b//" | sed "s/;//" | sed "s/^[[:space:]]*//;s/[[:space:]]*$//")
else
     package=""
fi
run=$(echo "$run" | sed 's|.*/\([^/]*\)\.java$|\1|')
[[ "$package" != "" ]] && run="$package.$run"
echo -en "${CYAN}\nRunning ${BOLD}${run}"
if [ $info -eq 0 ] && [[ "$args" != "" ]]; then
     echo -e " with the arguments:${BOLD}"
     for i in $args; do
          echo -e "\t· ${i}"
     done
fi
echo -e "\n${RESET}"
java -cp $bin $run $args
