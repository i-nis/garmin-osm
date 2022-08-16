#!/bin/bash
#
# 02_getosmdata.sh: script para descargar datos desde OpenStreetMap.
#
# (C) 2012 - 2022 Martin Andres Gomez Gimenez <mggimenez@nis.com.ar>
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
south-america-latest.o5m --out-o5m > ${PAIS}.o5m.tmp

echo


# Filtra elementos que no serán utilizados.
echo "------------------------------------------------------------------------"
echo "Filtrando elementos que no se utilizarán."
echo "------------------------------------------------------------------------"

${OSMFILTER} ${HASH_MEM} \
--drop="abandoned=" \
--drop="amenity=animal_boarding" \
--drop="amenity=animal_breeding" \
--drop="amenity=animal_shelter" \
--drop="amenity=childcare" \
--drop="amenity=dog_toilet" \
--drop="amenity=fountain" \
--drop="amenity=give_box" \
--drop="amenity=hunting_stand" \
--drop="amenity=kitchen" \
--drop="amenity=kneipp_water_cure" \
--drop="amenity=lounger" \
--drop="amenity=photo_booth" \
--drop="amenity=recycling" \
--drop="amenity=sanitary_dump_station" \
--drop="amenity=shelter" \
--drop="amenity=shower" \
--drop="amenity=vending_machine" \
--drop="amenity=waste_transfer_station" \
--drop="amenity=yes" \
--drop="artwork_type=" \
--drop="attractions=" \
--drop="building=apartments" \
--drop="building=bungalow" \
--drop="building=cabin" \
--drop="building=carport" \
--drop="building=conservatory" \
--drop="building=construction" \
--drop="building=container" \
--drop="building=cowshed" \
--drop="building=detached" \
--drop="building=digester" \
--drop="building=dormitory" \
--drop="building=farm" \
--drop="building=farm_auxiliary" \
--drop="building=ger" \
--drop="building=greenhouse" \
--drop="building=house" \
--drop="building=houseboat" \
--drop="building=hut" \
--drop="building=residential" \
--drop="building=ruins" \
--drop="building=semidetached_house" \
--drop="building=service" \
--drop="building=shed" \
--drop="building=slurry_tank" \
--drop="building=stable" \
--drop="building=static_caravan" \
--drop="building=sty" \
--drop="building=tent" \
--drop="building=terrace" \
--drop="building=transformer_tower" \
--drop="building=tree_house" \
--drop="building=yes" \
--drop="building=water_tower" \
--drop="craft=" \
--drop="power=" \
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
--drop-nodes="amenity=baking_oven" \
--drop-nodes="amenity=bbq" \
--drop-nodes="amenity=bench" \
--drop-nodes="amenity=clock" \
--drop-nodes="amenity=dive_centre" \
--drop-nodes="amenity=drinking_water" \
--drop-nodes="amenity=waste_basket" \
--drop-nodes="amenity=waste_disposal" \
--drop-nodes="amenity=water_point" \
--drop-nodes="amenity=watering_place" \
--drop-nodes="basin=" \
--drop-nodes="emergency!=emergency_ward_entrance" \
--drop-nodes="leisure=picnic_table" \
--drop-nodes="playground=" \
--drop-nodes="tourism=artwork" \
--drop-tags="comment=" \
--drop-tags="created_by=" \
--drop-tags="fixme=" \
--drop-tags="flag=" \
--drop-tags="highway=bus_stop" \
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
--drop-tags="power=" \
--drop-tags="public_transport=stop_position" \
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
--drop-tags="source*=" \
--drop-tags="source_ref=" \
--drop-tags="start_date=" \
--drop-tags="structure=" \
--drop-tags="substance=" \
--drop-tags="survey_date=" \
--drop-tags="todo=" \
--drop-tags="tracktype=" \
--drop-tags="tower:type=" \
--drop-tags="url=" \
--drop-tags="usage=" \
--drop-tags="wheelchair=" \
--drop-tags="width=" \
--drop-tags="wikidata=" \
--drop-tags="wikipedia=" \
--drop-ways="basin=" \
--drop-ways="highway=dismantled" \
--drop-ways="highway=disused" \
--drop-ways="highway=demolished" \
--drop-ways="highway=footway and bicycle!=yes" \
--drop-ways="highway=neverbuilt" \
--drop-ways="highway=proposed" \
--drop-ways="highway=proposal" \
--drop-ways="highway=planned" \
--drop-ways="highway~.*proposed.*" \
--drop-ways="highway~x-.*" \
--drop-ways="highway=razed" \
--drop-ways="highway=rejected" \
--drop-ways="highway=steps" \
--drop-ways="highway=unbuilt" \
--drop-ways="highway=via_ferrata" \
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
--drop-ways="railway=abandoned" \
--drop-ways="railway=platform" \
--drop-ways="recycling_type" \
--drop-ways="waterway=drain" \
--drop-ways="public_transport=platform and highway!=*" \
--verbose \
--out-o5m ${PAIS}.o5m.tmp > ${PAIS}.o5m

rm -f ${PAIS}.o5m.tmp
echo



# Descarga datos para el país seleccionado (por defecto para todos).
if [ ! -d ${WORKDIR}/${PAIS} ]; then
  mkdir --parents ${WORKDIR}/${PAIS}
  echo -e ">>> Creando directorio ${G}$PAIS${W}."
fi

download_geonames "${PAIS}"



# Descarga de oceanos precompilados.
if [ "${URLSEA}" != "" ]; then

  if [ ! -d ${WORKDIR}/sea ]; then
    cd ${WORKDIR}
    ${GET} ${URLSEA}
    unzip sea-latest.zip
    rm -f sea-latest.zip
  fi

fi

