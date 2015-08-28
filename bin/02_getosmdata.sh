#!/bin/bash
#
# 02_getosmdata.sh: script para descargar datos desde OpenStreetMap.
#
# (C) 2012 - 2015 Martin Andres Gomez Gimenez <mggimenez@ingeniovirtual.com.ar>
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

    colombia )
      GEONAME="CO.zip"
      ;;

    ecuador )
      GEONAME="EC.zip"
      ;;

    paraguay )
      GEONAME="PY.zip"
      ;;

    peru )
      GEONAME="PE.zip"
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
    BOX="-b=${COORD}"
  else
    PAIS="${1}"
    BOX="-B=${PAIS}/${PAIS}.poly"
fi

# Descarga south-america-latest.o5m
if [ ! -e south-america-latest.o5m ]; then

    echo "------------------------------------------------------------------------"
    echo "Descargando ${URL}/south-america-latest.osm.bz2"
    echo "------------------------------------------------------------------------"
    echo

    ${GET} ${URL}/south-america-latest.osm.bz2

    echo "------------------------------------------------------------------------"
    echo "Generando ${PAIS} con osmconvert desde: "
    echo "${URL_PAIS}/south-america-latest.osm.bz2"
    echo "Area definida por: ${BOX}"
    echo "------------------------------------------------------------------------"
    echo

    bzcat south-america-latest.osm.bz2 | ${OSMCONVERT} - ${HASH_MEM} \
    --verbose --out-o5m > south-america-latest.o5m

    rm -f south-america-latest.osm.bz2
    ${GET} ${OSMDAYSTATE}
    mv state.txt state.txt.old

  else

    echo "------------------------------------------------------------------------"
    echo "Actualizando ${PAIS} con osmconvert desde: "i
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
      SBOX="-B=south-america/south-america.poly"
      OSMCONVERT_OPTS="--complete-ways --complex-ways --drop-broken-refs"
      rm -f ${PAIS}.o5m

      for i in `seq ${OLD} ${LATEST}`; do

        # La URL para la organización de archivos diferenciales es del tipo: 
        # http://planet.openstreetmap.org/replication/day/AAA/BBB/CCC.osc.gz
        # Donde el número de secuencia es N = AAA*1000000 + BBB*1000 + CCC.
        # Por ejemplo para un archivo cuyo número de secuencia es 60277 le
        # corresponde una locación en /000/060/277.
        #
        # Para formar la URL es necesario saber con cuantos ceros deben anteponerse
        # al número de secuencia obtenido para la variable ${i}.
        NUMBER_CEROS=$((9 - ${#i}))
        CEROS=""

        for n in $(seq ${NUMBER_CEROS}); do 
          CEROS="0${CEROS}"
        done

        # Se genera la locación del archivo a descargar ${LOCATION} y el nombre
        # del archivo ${FILE} sin la extensión.
        LOCATION=$(echo "${CEROS}${i}" | sed -e 's/.\{3\}/\/&/g')
        FILE=$(echo "${LOCATION}" | awk -F \/ //'{print $(NF)}')

        STEPS="${Y}${I}${W} de ${Y}${N}${W}"
        echo -e ">>> Actualizando cambios (${STEPS}) a ${G}versión ${i}${W}"

        ${GET} ${RDAY}${LOCATION}.osc.gz

        if [ -e ${FILE}.osc.gz ]; then
          gunzip --decompress --force ${FILE}.osc.gz

          ${OSMCONVERT} ${HASH_MEM} ${OSMCONVERT_OPTS} ${SBOX} \
          --verbose --merge-versions south-america-latest.o5m ${FILE}.osc --out-o5m \
          > south-america-latest_new.o5m

          mv --force south-america-latest_new.o5m south-america-latest.o5m
          rm --force ${FILE}.osc

          NOW=$((OLD + I - 1))
          sed 's/'${LATEST}'/'${NOW}'/g' state.txt > state.txt.old

        fi

        I=$((I + 1))

      done

    fi

fi

${OSMCONVERT} ${HASH_MEM} ${BOX} --drop-version --verbose \
south-america-latest.o5m --out-o5m > ${PAIS}.o5m



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

