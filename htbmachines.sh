#!/bin/bash 

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

function ctrl_c(){
  echo -e "\n${redColour}[-] Saliendo...${endColour}\n"
  tput cnorm; exit 1
}


trap ctrl_c INT

# Variables globales

main_url="https://htbmachines.github.io/bundle.js"

function helpPanel(){
  echo -e "\n${yellowColour}[+]${endColour}${grayColour} Uso:${endColour}"
  echo -e "\t${purpleColour}u)${endColour} ${grayColour}Descargar o actualizar archivos necesarios.${endColour}"
  echo -e "\t${purpleColour}m)${endColour} ${grayColour}Buscar por un nombre de maquina${endColour}"
  echo -e "\t${purpleColour}i)${endColour} ${grayColour}Buscar por dirección IP${endColour}"
  echo -e "\t${purpleColour}h)${endColour} ${grayColour}Mostrar este panel de ayuda${endColour}\n"

}

function updateFiles(){
  if [ ! -f bundle.js ]; then
    tput civis
    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Descargando archivos necesarios...${endColour}"
    curl -s -X GET $main_url | js-beautify > bundle.js
    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Archivos descargados con éxito.${endColour}"
    tput cnorm
  else
    curl -s -X GET $main_url | js-beautify > bundle_temp.js
    md5value_copy="$(md5sum bundle_temp.js | awk '{print $1}')"
    md5value_origi="$(md5sum bundle.js | awk {'print $1'})"

    if [ "$md5value_copy" == "$md5value_origi" ]; then
        echo -e "\n${yellowColour}[+]${endColour} ${grayColour}No hay actualizaciones${endColour}"
        rm bundle_temp.js 
    else 
        echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Actualizando archivos necesarios...${endColour}"
        sleep 2
        rm bundle.js && mv bundle_temp.js bundle.js
        echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Actualizados con éxito.${endColour}"
    fi
  fi  
}

function searchMachine(){
  machineName="$1"
  if [ -f bundle.js ]; then
    if  grep -qi "name: \"$machineName\"" bundle.js ; then
      echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Listando las propiedades de la máquina${endColour} ${blueColour}$machineName${endColour}${grayColour}:${endColour}\n"
      cat bundle.js | awk -v IGNORECASE=1 "/name: \"$machineName\"/,/resuelta:/" | grep -vE "id:|sku:|resuelta:" | tr -d '"' | tr -d "," | sed 's/^ *//' > "$machineName"
      echo -e "\t${yellowColour}[+]${endColour} ${grayColour}Dirección IP -> ${blueColour}$(cat $machineName | grep "ip:" | awk '{print $2}')${endColour}"
      echo -e "\t${yellowColour}[+]${endColour} ${grayColour}Sistema Operativo -> ${blueColour}$(cat $machineName | grep "so:" | awk '{print $2}')${endColour}"
      echo -e "\t${yellowColour}[+]${endColour} ${grayColour}Dificultad -> ${blueColour}$(cat $machineName | grep "dificultad:" | awk '{print $2}')${endColour}"
      echo -e "\t${yellowColour}[+]${endColour} ${grayColour}Habilidades -> ${blueColour}$(cat $machineName | grep "skills:" | sed "s/skills: //")${endColour}"
      echo -e "\t${yellowColour}[+]${endColour} ${grayColour}Certificaciones -> ${blueColour}$(cat $machineName | grep "like:" | sed 's/like: //')${endColour}"
      echo -e "\t${yellowColour}[+]${endColour} ${grayColour}Resolucion -> ${blueColour}$(cat $machineName | grep "youtube:" | awk '{print $2}')${endColour}\n"
      rm "$machineName"
    else 
      echo -e "\n${yellowColour}[-]${endColour} La máquina ${redColour}$machineName${endColour} no se encuentra registrada.\n"
    fi
  else echo -e "\n${redColour}[-]${endColour} ${grayColour}Por favor descargue los archivos necesarios.${endColour}\n"
  fi
}
function searchIP(){
  ipAddress="$1"
  if [ -f bundle.js ]; then
    if grep -qiE "ip: \"$ipAddress\"," bundle.js; then
      machineName=$(cat bundle.js | grep "ip: \"$ipAddress\"" -B 3 | grep "name:" | sed "s/^ *//" | awk '{print $2}' | tr -d '"' | tr -d ',')
      echo -e "\n${yellowColour}[+]${endColour} ${grayColour}La dirección IP ${endColour}${blueColour}$ipAddress${endColour}${grayColour} corresponde a la máquina $machineName\n"
    else 
      echo -e "\n${yellowColour}[-]${endColour}${grayColour} La dirección IP ${endColour}${redColour}$ipAddress${endColour}${grayColour} no se encuentra registrada\n"
    fi
  else echo -e "\n${redColour}[-]${endColour} ${grayColour}Por favor descargue los archivos necesarios.${endColour}\n"
  fi
}

# Indicadores
declare -i parameter_counter=0 

while getopts "m:ui:h" arg; do 
  case $arg in 
    m) machineName=$OPTARG; let parameter_counter+=1;;
    u) let parameter_counter+=2;;
    i) ipAddress=$OPTARG; let parameter_counter+=3;;
    h) ;;
  esac
done

if [ $parameter_counter -eq 1 ]; then
  searchMachine $machineName
elif [ $parameter_counter -eq 2 ]; then
  updateFiles
elif [ $parameter_counter -eq 3 ]; then
  searchIP $ipAddress
else 
  helpPanel
fi
