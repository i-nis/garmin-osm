#!/bin/bash
#
# 04_splitter.sh: script para dividir el mapa fuente en mapas mas pequeños.
#
# (C) 2012 - 2015 Martin Andres Gomez Gimenez <mggimenez@ingeniovirtual.com.ar>
# Distributed under the terms of the GNU General Public License v3
#



MAPID=98000001
WORKDIR=`pwd`
SPLITTER="${WORKDIR}/splitter/dist/splitter.jar"

# Colores
G='\E[1;32;40m'
Y='\E[1;33;40m'
W='\E[0;38;40m'

COMMON_OPTIONS="--keep-complete=true --wanted-admin-level=8 --max-areas=512"
COMMON_OPTIONS="${COMMON_OPTIONS} --max-nodes=160000 --no-trim"
COMMON_OPTIONS="${COMMON_OPTIONS} --overlap=0 --output=xml --resolution=12"
COMMON_OPTIONS="${COMMON_OPTIONS} --search-limit=400000"

rm -f template.args



# Función para seleccionar opciones por país.
options () {

  local PAIS="$1"
  local COMMON="$2"

  case ${PAIS} in

    all )
      OPTIONS="--description=Argentina --geonames-file=cities15000.zip ${COMMON}"
      ;;

    argentina )
      OPTIONS="--geonames-file=AR.zip ${COMMON}"
      ;;

    bolivia )
      OPTIONS="--geonames-file=BO.zip ${COMMON}"
      ;;

    brazil )
      OPTIONS="--geonames-file=BR.zip ${COMMON}"
      ;;

    colombia )
      OPTIONS="--geonames-file=CO.zip ${COMMON}"
      ;;

    chile )
      OPTIONS="--geonames-file=CL.zip ${COMMON}"
      ;;

    ecuador )
      OPTIONS="--geonames-file=EC.zip ${COMMON}"
      ;;

    peru )
      OPTIONS="--geonames-file=PE.zip ${COMMON}"
      ;;

    paraguay )
      OPTIONS="--geonames-file=PY.zip ${COMMON}"
      ;;

    uruguay )
      OPTIONS="--geonames-file=UY.zip ${COMMON}"
      ;;

  esac

}



# Selecciona el país, si no se pasan argumentos se procesan todos los países.
# PAIS = [all | argentina | bolivia | brazil | chile | paraguay | uruguay]
if [[ "${1}" == "" || "${1}" == "all" ]]; then
    PAIS="south-america"
  else
    PAIS="${1}"
fi

# Verifica si existen mosaicos precompilados para el mar.
if [ -e ${WORKDIR}/sea/index.txt.gz ]; then
  COMMON_OPTIONS="${COMMON_OPTIONS} --precomp-sea=${WORKDIR}/sea/"
fi

echo "------------------------------------------------------------------------"
echo "Generando mosaicos de ${PAIS}."
echo "------------------------------------------------------------------------"
echo

cd ${WORKDIR}/${PAIS}
options "${PAIS}" "${COMMON_OPTIONS}"

if [ -e ${PAIS}.list ]; then
  OPTIONS="${OPTIONS} --split-file=${PAIS}.list"
fi

echo
echo -e ">>> Creando mosaicos para ${G}${PAIS}${W} con spliter.jar..."
echo
java -Xmx1536m -enableassertions -jar ${SPLITTER} ${OPTIONS} --mapid=${MAPID} \
${WORKDIR}/${PAIS}.o5m

if [ -e areas.list ]; then
  mv --force areas.list ${PAIS}.list
fi

if [ -e template.args ]; then
  mv --force template.args ${PAIS}.args
fi
