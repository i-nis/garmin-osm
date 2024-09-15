#!/bin/bash
#
# 02_getosmdata.sh: script para descargar datos desde OpenStreetMap.
#
# (C) 2012 - 2024 Martin Andres Gomez Gimenez <mggimenez@nis.com.ar>
# Distributed under the terms of the GNU General Public License v3
#

# Requiere los siguientes paquetes:
# bzip2: http://www.bzip.org/
# wget: http://www.gnu.org/software/wget/
# osmconvert: http://wiki.openstreetmap.org/wiki/osmconvert
# zip: http://www.info-zip.org/

# Uso:
# El script debe invocarse directamente sobre el directorio raíz de las siguientes
# maneras:
#
# bin/02_getosmdata.sh
#	Descarga y actualiza datos desde OpenStreetMap para el cono sur.
#
# bin/02_getosmdata.sh país
# 	Descarga y actualiza datos desde OpenStreetMap para el país seleccionado. El
#	valor de país puede ser uno de los siguientes:
#		argentina
#		bolivia
#		brazil
#		chile
#		colombia
#		ecuador
#		paraguay
#		peru
#		uruguay
#


WORKDIR=`pwd`
BUNZIP2="/bin/bunzip2 --force"
GET="/usr/bin/wget --continue --no-check-certificate"
OSMCONVERT="${WORKDIR}/bin/osmconvert"
OSMCONVERT_OPTS="--complete-ways --complete-multipolygons --complete-boundaries --drop-author --drop-broken-refs"
OSMFILTER="${WORKDIR}/bin/osmfilter"

# Datos desde OSM
URL="https://download.geofabrik.de"
URLGEONAMES="https://download.geonames.org/export/dump"
URLSEA="http://osm.thkukuk.de/data/sea-latest.zip"
RDAY="${URL}/south-america-updates"
OSMDAYSTATE="${RDAY}/state.txt"

# Uso de memoria: 1024 MiB
HASH_MEM="--hash-memory=1024"

# Colores
G='\E[1;32;40m'
Y='\E[1;33;40m'
W='\E[0;38;40m'

# Opciones para cortar el cono sur de América.
COORD="-76,-56,-48,-17"



# Función para seleccionar geoname a descargar por país.
geoname () {
  local PAIS="$1"

  case ${PAIS} in
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



# Función para descargar datos de las ciudades.
download_geonames() {
  local P="${1}"
  local COUNTRIES=""

  cd ${WORKDIR}/${P}

  if [ "${P}" == "all" ] || [ "${P}" == "south-america" ]; then
      COUNTRIES="argentina bolivia brazil chile colombia ecuador paraguay peru uruguay"

      for country in ${COUNTRIES}; do
        geoname "${country}"

        if [ ! -e south-america.zip ]; then
          echo -e ">>> Descargando ${G}${GEONAME}${W}."
          ${GET} ${URLGEONAMES}/${GEONAME}
        fi

      unzip -p ${GEONAME} >> south-america.txt
      rm -f ${GEONAME}
      done

      zip south-america.zip south-america.txt
      rm -f south-america.txt

    else
      geoname "${P}"

      if [ ! -e ${GEONAME} ]; then
        echo -e ">>> Descargando ${G}${GEONAME}${W}."
        ${GET} ${URLGEONAMES}/${GEONAME}
      fi

  fi

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
    echo "Descargando ${URL}/south-america-latest.osm.pbf"
    echo "------------------------------------------------------------------------"
    echo

    ${GET} ${OSMDAYSTATE}
    mv state.txt state.txt.old
    ${GET} ${URL}/south-america-latest.osm.pbf

    echo "------------------------------------------------------------------------"
    echo "Generando ${PAIS} con osmconvert desde: "
    echo "${URL_PAIS}/south-america-latest.osm.pbf"
    echo "Area definida por: ${BOX}"
    echo "------------------------------------------------------------------------"
    echo

    ${OSMCONVERT} ${HASH_MEM} south-america-latest.osm.pbf \
    --verbose --out-o5m > south-america-latest.o5m

    rm -f south-america-latest.osm.pbf

  else

    echo "------------------------------------------------------------------------"
    echo "Actualizando ${PAIS} con osmconvert desde: "
    echo "${URL}."
    echo "Area definida por: ${BOX}"
    echo "------------------------------------------------------------------------"
    echo

    rm -f ${WORKDIR}/state.txt
    ${GET} ${OSMDAYSTATE}

    LATEST=`awk -F \= /sequenceNumber/'{print $2}' state.txt`
    OLD=`awk -F \= /sequenceNumber/'{print $2}' state.txt.old`
    I=1
    N=$((LATEST - OLD))

    if [ ${LATEST} != ${OLD} ]; then
      OLD=$((OLD + 1))
      SBOX="-B=south-america/south-america.poly"
      rm -f ${PAIS}.o5m

      for i in `seq ${OLD} ${LATEST}`; do

        # La URL para la organización de archivos diferenciales es del tipo:
        # https://download.geofabrik.de/south-america-updates/AAA/BBB/CCC.osc.gz
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

      rm state.txt
    fi

fi



# Arma el mapa del país o la región indicada, quitando información que no
# será utilizada.
${OSMCONVERT} ${HASH_MEM} ${OSMCONVERT_OPTS} ${BOX} \
--drop-version \
--verbose \
south-america-latest.o5m --out-o5m > ${PAIS}.o5m

echo



# Filtra elementos que no serán utilizados.
echo "------------------------------------------------------------------------"
echo "Descargando otros datos necesarios para generar el mapa."
echo "------------------------------------------------------------------------"

# Descarga datos para el país seleccionado (por defecto para todos).
if [ ! -d ${WORKDIR}/${PAIS} ]; then
  mkdir --parents ${WORKDIR}/${PAIS}
  echo -e ">>> Creando directorio ${G}$PAIS${W}."
fi

echo -e ">>> Descargando nombres geográficos para ${G}$PAIS${W}."
download_geonames "${PAIS}"



# Descarga de oceanos precompilados.
echo -e ">>> Descargando ${G}oceanos precompilados${W}."
if [ "${URLSEA}" != "" ]; then

  if [ ! -d ${WORKDIR}/sea ]; then
    cd ${WORKDIR}
    ${GET} ${URLSEA}
    unzip sea-latest.zip
    rm -f sea-latest.zip
  fi

fi

