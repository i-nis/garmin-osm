#!/bin/bash
#
# 02_getosmdata.sh: script para descargar datos desde OpenStreetMap.
#
# (C) 2012 - 2014 Martin Andres Gomez Gimenez <mggimenez@i-nis.com.ar>
# Distributed under the terms of the GNU General Public License v3
#

# Requiere los siguientes paquetes:
# bzip2: http://www.bzip.org/
# wget: http://www.gnu.org/software/wget/
# osmconvert: http://wiki.openstreetmap.org/wiki/osmconvert

WORKDIR=`pwd`
BUNZIP2="/bin/bunzip2 --force"
GET="/usr/bin/wget --continue"
OSMCONVERT="${WORKDIR}/bin/osmconvert"

# Datos desde OSM
URL="http://download.geofabrik.de"
URLGEONAMES="http://download.geonames.org/export/dump"
URLSEA="http://osm2.pleiades.uni-wuppertal.de/sea/latest/sea.tar.bz2"
PLANETOSM="http://planet.openstreetmap.org"
RDAY="${PLANETOSM}/replication/day"
OSMDAYSTATE="${RDAY}/state.txt"

# Uso de memoria: 128 MiB
HASH_MEM="--hash-memory=128"

# Colores
G='\E[1;32;40m'
Y='\E[1;33;40m'
W='\E[0;38;40m'

# Opciones para cortar el cono sur de América.
COORD="-77,-56,-49,-16"

# Función para seleccionar geoname a descargar por país.
geoname () {

  local PAIS="$1"

  case ${PAIS} in
    all )
      GEONAME="cities15000.zip"
      ;;

    argentina )
      GEONAME="AR.zip"
      ;;

    bolivia )
      GEONAME="BO.zip"
      ;;

    brazil )
      GEONAME="BR.zip"
      ;;

    chile )
      GEONAME="CL.zip"
      ;;

    paraguay )
      GEONAME="PY.zip"
      ;;

    uruguay )
      GEONAME="UY.zip"
      ;;

  esac

}



# Datos desde OSM

# Selecciona el país, si no se pasan argumentos se procesan todos los países.
# PAIS = [all | argentina | bolivia | brazil | chile | paraguay | uruguay]
if [[ "${1}" == "" || "${1}" == "all" ]]; then
    PAIS="south-america"
    URL_PAIS="${URL}/${PAIS}"
    BOX="-b=${COORD}"
    OSMCONVERT_OPTS="--complete-ways --complex-ways --drop-broken-refs"
  else
    PAIS="${1}"
    URL_PAIS="${URL}/south-america/${PAIS}"
    OSMCONVERT_OPTS="-B=${PAIS}/${PAIS}"
fi

# Descarga south-america.o5m
if [ ! -e ${PAIS}-latest.o5m ]; then

    echo "------------------------------------------------------------------------"
    echo "Descargando ${URL_PAIS}-latest.osm.bz2"
    echo "------------------------------------------------------------------------"
    echo

    ${GET} ${URL_PAIS}-latest.osm.bz2

    echo "------------------------------------------------------------------------"
    echo "Generando ${PAIS} con osmconvert desde: "
    echo "${URL_PAIS}-latest.osm.bz2"
    echo "Area definida por: ${BOX}"
    echo "------------------------------------------------------------------------"
    echo

    bzcat ${PAIS}-latest.osm.bz2 | ${OSMCONVERT} - ${HASH_MEM} \
    --verbose --out-o5m > ${PAIS}-latest.o5m

    ${OSMCONVERT} ${HASH_MEM} ${BOX} ${OSMCONVERT_OPTS} -B=${PAIS}/${PAIS}.poly \
    --verbose ${PAIS}-latest.o5m --out-o5m > ${PAIS}.o5m

    rm -f ${PAIS}-latest.osm.bz2

  else

    echo "------------------------------------------------------------------------"
    echo "Actualizando ${PAIS} con osmconvert desde: "
    echo "${PLANETOSM}."
    echo "Area definida por: ${BOX}"
    echo "------------------------------------------------------------------------"
    echo

    ${GET} ${OSMDAYSTATE}

    LATEST=`awk -F \= /sequenceNumber/'{print $2}' state.txt`
    OLD=`awk -F \= /sequenceNumber/'{print $2}' state.txt.old`
    I=1
    N=$((LATEST - OLD))

    if [ ${LATEST} != ${OLD} ]; then
      OLD=$((OLD + 1))
      rm -f ${PAIS}.o5m

      for i in `seq ${OLD} ${LATEST}`; do

        STEPS="${Y}${I}${W} de ${Y}${N}${W}"
        echo -e ">>> Actualizando cambios (${STEPS}) a ${G}versión ${i}${W}"
        ${GET} ${RDAY}/000/000/${i}.osc.gz

        if [ -e ${i}.osc.gz ]; then
          gunzip --decompress --force ${i}.osc.gz

          ${OSMCONVERT} ${HASH_MEM} ${OSMCONVERT_OPTS} -B=${PAIS}/${PAIS}.poly \
          --verbose --merge-versions ${PAIS}-latest.o5m ${i}.osc --out-o5m \
          > ${PAIS}-latest_new.o5m

          mv --force ${PAIS}-latest_new.o5m ${PAIS}-latest.o5m
          rm --force ${i}.osc

          NOW=$((OLD + I - 1))
          sed 's/'${LATEST}'/'${NOW}'/g' state.txt > state.txt.old

        fi

        I=$((I + 1))

      done

    ${OSMCONVERT} ${HASH_MEM} ${BOX} ${OSMCONVERT_OPTS} --drop-version --verbose \
    ${PAIS}-latest.o5m --out-o5m > ${PAIS}.o5m

    fi

fi



# Descarga datos para el país seleccionado (por defecto para todos).
for pais in ${PAIS}; do
  geoname "${pais}"

  if [ ! -d ${WORKDIR}/${pais} ]; then
    mkdir --parents ${WORKDIR}/${pais}
    echo -e ">>> Creando directorio ${G}$pais${W}."
  fi

  cd ${WORKDIR}/${pais}

  if [ ! -e ${GEONAME} ]; then
    echo -e ">>> Descargando ${G}${GEONAME}${W}."
    ${GET} ${URLGEONAMES}/${GEONAME}
  fi
done


# Descarga de oceanos precompilados
if [ ! -d ${WORKDIR}/sea ]; then
  cd ${WORKDIR}
  ${GET} ${URLSEA}
  tar -jxvpf sea.tar.bz2
  SEADIR=$(ls */index.txt.gz | awk -F \/ //'{print $1}')
  mv ${SEADIR} sea
fi
