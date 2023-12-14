#! /usr/bin/env bash

# Colores y formatos
BOLD="\033[1m"
BLACK="\u001B[30m"
RED="\u001B[31m"
GREEN="\u001B[32m"
YELLOW="\u001B[33m"
BLUE="\u001B[34m"
PURPLE="\u001B[35m"
CYAN="\u001B[36m"
WHITE="\u001B[37m"
RESET="\u001B[0m"

# Nombre del fichero
name="acp"

# Ruta relativa hasta la fuente del git
gitRelDir=""
# Ruta absoluta hasta la fuente del git
gitDir=""
# Bandera de si se ha encontrado
found=1

# Busca entre los directorios padres 
# hasta encontrar el directorio fuente del git
function getGitSource () {
     dir="$1"
     if [ -e .git ] && [ -d .git ]; then
          gitDir="$PWD"
          gitRelDir="$dir"
          found=0
          return 0
     elif [[ "$PWD" == "/" ]]; then
          found=1
          return 1
     else
          cd ..
          getGitSource "../$dir"
          return $?
     fi
}

# Muestra su forma de uso y ayuda
function help () {
     echo -e "This program make, if no error in the execution, the git add, git commit -m and git push (if is specified or if the command is executed in a git hierarchy, root or child dir, in which case will ask if you want to push to a remote git)"
     echo -e ""
     echo -e "${BOLD}USE${RESET}"
     echo -e "\t$name [dir or files to add] [-c \"commit message\"] [-p]"
     echo -e ""
     echo -e "If you specify some file or dir names the 'git add' command will be tried with that arguments"
     echo -e ""
     echo -e " -c, --commitMessage\tSet the commit message (will not be asked)"
     echo -e " -p, --push\t\tSet the push option. The program will try a push"
     echo -e ""
     echo -e "${BOLD}EXAMPLES${RESET}"
     echo -e "· $name"
     echo -e "The program will try to found the git source (git root dir) and do execute a 'git add' from there. In this case, beacause the commit message is not specified, the program will ask it. And, if you are in git with remote conexion will ask if you want to push it"
     echo -e ""
     # completar que me da flojera ahora
     exit 0
}

# Muestra la información relativa a los directorios de git
function showGitAdd () {
     ## Se han pasado argumentos
     [ $found -ne 0 ] && return 0
     ## Se ha encontrado un git source
     echo -e "${GREEN}git source used: ${BOLD}$(echo "$gitDir" | sed "s|$HOME|~|")${RESET}"
     ## Estamos en la carpeta raiz del git
     [[ "$gitDir" == "$PWD" ]] && echo -e "${GREEN}You are at the root git dir${RESET}" && return 0
     ## En otro caso mostramos en que carpeta del git estamos
     echo -e "${GREEN}You are at:      ${BOLD}$(echo "$PWD" | sed "s|$gitDir/||")${RESET}\n"
}

# Sale mostrando y eliminando el fichero.
#    $1 <- Mensaje de error
#    $2 <- fichero destino de error
function saveExit () {
     echo -e "\n${BOLD}${RED}MESSAGE ERROR${RESET}${RED}:\n$1${RESET}\n"
     ! [ -e "$2" ] || ! [ -f "$2" ] && exit 1
     echo -e "${RED}${BOLD}ERROR DESCRIPTION:${RESET}${RED}\n$(cat $2)${RESET}\n"
     rm $2
     exit 1
}

# Argumentos para las 3 llamadas
addArg=" ."
commitMessage=""
push=1

# Conversión de argv a los argumentos individuales
for i in "${@}"; do
     if [[ "$1" == "-c" || "$1" == "--commitMessage" ]]; then
          shift
          commitMessage="$1"
          shift
     elif [[ "$1" == "-p" || "$1" == "--push" ]]; then
          shift
          push=0
     elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
          help
     elif [[ "$1" != "" ]]; then
          [[ "$addArg" == " ." ]] && addArg=""
          addArg="$addArg $1"
          shift
     fi 
done

echo -e ""

if ! [[ "$addArg" != " ." ]]; then
     # No se ha espeficiado ni ruta ni ficheros -> de busca
     origin="$PWD"
     getGitSource .
     cd "$origin"
     [ $found -ne 0 ] && saveExit "no git source founded"
     addArg=" $gitRelDir"
fi 

showGitAdd

! [ -n "$(git status $addArg --porcelain)" ] && saveExit "no hay cambios en $addArg"

# git add
echo -e "${CYAN}Trying '${BOLD}git add${addArg}${RESET}'"
error="/tmp/addResult"
git add $addArg > $error 2> $error
ping -c 1 localhost > /dev/null
[ -n "$(cat $error)" ] && saveExit "failed attempt to add" $error
echo -e "${GREEN}Added files ${BOLD}successfully${RESET}${GREEN}: ${BOLD}"
added_files=$(git status --porcelain | cut -c4-)
if [ -n "$added_files" ]; then
     # Leer la salida línea por línea
     while IFS= read -r line; do
          # Extraer el nombre del archivo de cada línea
          archivo=$(echo "$line" ) #| awk '{print $2}')
          # Imprimir el nombre del archivo
          echo -e "\t· $archivo"
     done <<< "$added_files"
else 
     echo -e "${BOLD}${YELLOW}WARNIGN${RESET}${YELLOW}: No changes added"
fi
echo -e "${RESET}"
# git commit -m message
if [[ "$commitMessage" == "" ]]; then
     # No se ha especificado mensaje pues se pide
     echo -e "${BOLD}${CYAN}**The commit message wasn't specified**${RESET}"
     echo -ne "${CYAN}Set the commit message\n>> ${RESET}"
     read -r commitMessage
     echo ""
fi 

echo -e "${CYAN}Trying 'git commit' with message: ${BOLD}${commitMessage}${RESET}"
error="/tmp/commitResult"
r=$(git commit -m "$commitMessage" 2> "$error")
[ $? -ne 0 ] && saveExit "failed attempt to commit" $error 
echo -e "${BOLD}Commit result:${RESET}\n${r}"
echo -e "${GREEN}${BOLD}DONE!!${RESET}${GREEN}Commited ${BOLD}successfully${RESET}\n"

# git push
if [ -n "$(git remote)" ]; then
     echo -e "${BOLD}${YELLOW}GIT Remoto identificado y push no especificado${RESET}"
     echo -e "${CYAN}Desea hacer un push? [y -> yes | others -> no]${RESET}"
     read -r tmp
     [[ "$(echo "$tmp" | grep -i y | wc -w)" != "0" ]] && push=0
fi
[ $push -ne 0 ] && exit 0
echo -e "${CYAN}Trying to push the commit to ${BOLD}$(git remote)$RESET"
error="/tmp/pushResult"
echo -e "${BOLD}Push Result${RESET}:"
git push
[ $? -ne 0 ] && saveExit "failed attempt to push" $error
echo -e "${GREEN}${BOLD}DONE!!${RESET}${GREEN} the commit was pushed succesfully"
