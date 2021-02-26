#!/bin/bash
#
# 02_getosmdata.sh: script para descargar datos desde OpenStreetMap.
#
# (C) 2012 - 2021 Martin Andres Gomez Gimenez <mggimenez@nis.com.ar>
# Distributed under the terms of the GNU General Public License v3
#

# Requiere los siguientes paquetes:
# bzip2: http://www.bzip.org/
# wget: http://www.gnu.org/software/wget/
# osmconvert: http://wiki.openstreetmap.org/wiki/osmconvert

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
GET="/usr/bin/wget --continue"
OSMCONVERT="${WORKDIR}/bin/osmconvert"
OSMCONVERT_OPTS="--complete-ways --complete-multipolygons --complete-boundaries --drop-author --drop-broken-refs"
OSMFILTER="${WORKDIR}/bin/osmfilter"

# Datos desde OSM
URL="https://download.geofabrik.de"
URLGEONAMES="https://download.geonames.org/export/dump"
URLSEA="http://osm.thkukuk.de/data/sea-latest.zip"
PLANETOSM="https://planet.openstreetmap.org"
RDAY="${PLANETOSM}/replication/day"
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

    south-america )
      GEONAME="cities15000.zip"
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
    echo "Descargando ${URL}/south-america-latest.osm.pbf"
    echo "------------------------------------------------------------------------"
    echo

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
    ${GET} ${OSMDAYSTATE}
    mv state.txt state.txt.old

  else

    echo "------------------------------------------------------------------------"
    echo "Actualizando ${PAIS} con osmconvert desde: "
    echo "${PLANETOSM}."
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

      rm state.txt
    fi

fi



# Arma el mapa del país o la región indicada, quitando información que no
# será utilizada.
${OSMCONVERT} ${HASH_MEM} ${OSMCONVERT_OPTS} ${BOX} \
--drop-version \
--verbose \
south-america-latest.o5m --out-o5m > ${PAIS}.o5m.tmp

echo


# Filtra elementos que no serán utilizados.
echo "------------------------------------------------------------------------"
echo "Filtrando elementos que no se utilizarán."
echo "------------------------------------------------------------------------"

${OSMFILTER} ${HASH_MEM} \
--drop="abandoned=" \
--drop="artwork_type=" \
--drop="power=" \
--drop-nodes="amenity=bench" \
--drop-nodes="amenity=fountain" \
--drop-nodes="amenity=recycling" \
--drop-nodes="basin=" \
--drop-nodes="highway=bus_stop" \
--drop-nodes="leisure=picnic_table" \
--drop-nodes="natural=" \
--drop-nodes="playground=" \
--drop-nodes="power=" \
--drop-nodes="public_transport=platform" \
--drop-nodes="public_transport=stop_position and bus=yes" \
--drop-nodes="tourism=artwork" \
--drop-relations="network=" \
--drop-relations="route=power" \
--drop-relations="route=railway" \
--drop-relations="route=bus" \
--drop-relations="route=detour" \
--drop-relations="route=evacuation" \
--drop-relations="route=foot" \
--drop-relations="route=hiking" \
--drop-relations="route=horse" \
--drop-relations="route=inline_skates" \
--drop-relations="route=mtb" \
--drop-relations="route=piste" \
--drop-relations="route=running" \
--drop-relations="route=ski" \
--drop-relations="route=snowmobile" \
--drop-relations="route=train" \
--drop-relations="route=tram" \
--drop-relations="trolleybus" \
--drop-relations="route_master=aerialway" \
--drop-relations="route_master=bus" \
--drop-relations="route_master=monorail" \
--drop-relations="route_master=tram" \
--drop-relations="route_master=train" \
--drop-relations="route_master=trolleybus" \
--drop-relations="superroute=" \
--drop-relations="waterway=" \
--drop-tags="fixme=" \
--drop-tags="flag=" \
--drop-tags="horse=" \
--drop-tags="image=" \
--drop-tags="incline=" \
--drop-tags="indoor=" \
--drop-tags="inscription=" \
--drop-tags="intermittent=" \
--drop-tags="internet_access=" \
--drop-tags="kerb= lamp_type=" \
--drop-tags="lamp_type=" \
--drop-tags="lane_markings=" \
--drop-tags="leaf_cycle=" \
--drop-tags="leaf_type=" \
--drop-tags="link=" \
--drop-tags="lit=" \
--drop-tags="mapillary=" \
--drop-tags="material=" \
--drop-tags="memorial=" \
--drop-tags="nombre_estadisticas=" \
--drop-tags="noname=" \
--drop-tags="note=" \
--drop-tags="operator=" \
--drop-tags="owner=" \
--drop-tags="plant=" \
--drop-tags="population=" \
--drop-tags="power=" \
--drop-tags="protection_title=" \
--drop-tags="pump=" \
--drop-tags="railway:position=" \
--drop-tags="railway:preferred_direction=" \
--drop-tags="ref:AGESIC=" \
--drop-tags="roof =" \
--drop-tags="sac_scale=" \
--drop-tags="seamark=" \
--drop-tags="smoking=" \
--drop-tags="source=" \
--drop-tags="start_date=" \
--drop-tags="structure=" \
--drop-tags="substance=" \
--drop-tags="survey_date=" \
--drop-tags="tracktype=" \
--drop-tags="tower:type=" \
--drop-tags="url=" \
--drop-tags="usage=" \
--drop-tags="width=" \
--drop-tags="wikidata=" \
--drop-tags="wikipedia=" \
--drop-ways="amenity=fountain" \
--drop-ways="attractions=" \
--drop-ways="barrier=" \
--drop-ways="basin=" \
--drop-ways="building=apartments" \
--drop-ways="building=bungalow" \
--drop-ways="building=cabin" \
--drop-ways="building=detached" \
--drop-ways="building=dormitory" \
--drop-ways="building=farm" \
--drop-ways="building=ger" \
--drop-ways="building=house" \
--drop-ways="building=residential" \
--drop-ways="building=semidetached_house" \
--drop-ways="building=static_caravan" \
--drop-ways="building=terrace" \
--drop-ways="building=yes" \
--drop-ways="highway=footway and bicycle!=yes" \
--drop-ways="highway=steps" \
--drop-ways="landcover=" \
--drop-ways="public_transport=platform" \
--drop-ways="railway=platform" \
--drop-ways="recycling_type" \
--drop-ways="waterway=drain" \
--drop-ways="landuse=allotments and highway!=*" \
--drop-ways="landuse=brownfield and highway!=*" \
--drop-ways="landuse=farmland and highway!=*" \
--drop-ways="landuse=farmyard and highway!=*" \
--drop-ways="landuse=grass and highway!=*" \
--drop-ways="landuse=greenfield and highway!=*" \
--drop-ways="landuse=industrial and highway!=*" \
--drop-ways="landuse=landfill and highway!=*" \
--drop-ways="landuse=meadow and highway!=*" \
--drop-ways="landuse=orchard and highway!=*" \
--drop-ways="landuse=quarry and highway!=*" \
--drop-ways="landuse=residential and highway!=*" \
--verbose \
--out-o5m ${PAIS}.o5m.tmp > ${PAIS}.o5m

rm -f ${PAIS}.o5m.tmp
echo



# Descarga datos para el país seleccionado (por defecto para todos).
geoname "${PAIS}"

if [ ! -d ${WORKDIR}/${PAIS} ]; then
  mkdir --parents ${WORKDIR}/${PAIS}
  echo -e ">>> Creando directorio ${G}$PAIS${W}."
fi

cd ${WORKDIR}/${PAIS}

if [ ! -e ${GEONAME} ]; then
  echo -e ">>> Descargando ${G}${GEONAME}${W}."
  ${GET} ${URLGEONAMES}/${GEONAME}
fi



# Descarga de oceanos precompilados.
if [ "${URLSEA}" != "" ]; then

  if [ ! -d ${WORKDIR}/sea ]; then
    cd ${WORKDIR}
    ${GET} ${URLSEA}
    unzip sea-latest.zip
    rm -f sea-latest.zip
  fi

fi

