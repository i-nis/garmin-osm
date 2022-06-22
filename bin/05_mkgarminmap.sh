#!/bin/bash
#
# 05_mkgarminmap.sh: script para crear el mapa gmapsupp.img para los dispositivos
# GPS Garmin.
#
# (C) 2011 - 2021 Martin Andres Gomez Gimenez <mggimenez@nis.com.ar>
# Distributed under the terms of the GNU General Public License v3
#



MAPNAME=98000001
PRODUCTID=1
FECHA=$(date +%y%m%d)
WORKDIR=`pwd`
MKGMAP="${WORKDIR}/mkgmap/mkgmap.jar"

# Colores
G='\E[1;32;40m'
Y='\E[1;33;40m'
W='\E[0;38;40m'

COPY="Colaboradores de OpenStreetMap, ODbL."
COPY_URL="http://www.openstreetmap.org/copyright"
COPYRIGHT="${COPY} Para más detalle vea ${COPY_URL}."



# Selecciona el país, si no se pasan argumentos se procesan todos los países.
# PAIS = [all | argentina | bolivia | brazil | chile | paraguay | uruguay]
if [[ "${1}" == "" || "${1}" == "all" ]]; then
    PAIS="south-america"
    DESCRIPTION="Argentina y resto del cono sur - ${FECHA}"
    JAVA_MEM="-Xmx4096m"
  else
    PAIS="${1}"
    DESCRIPTION="${PAIS} - ${FECHA}"
    JAVA_MEM="-Xmx2048m"
fi

# Verifica si los límites ya fueron creados previamente o deben crearse.
if [ $(ls -1 ${WORKDIR}/bounds/ |  wc -l) == 0 ]; then
  echo "------------------------------------------------------------------------"
  echo "Generando archivos de límites para ${PAIS}."
  echo "------------------------------------------------------------------------"
  echo

  java ${JAVA_MEM} -cp ${MKGMAP} \
  uk.me.parabola.mkgmap.reader.osm.boundary.BoundaryPreprocessor\
  ${PAIS}-boundaries.o5m bounds/

  FILES=$(ls -1 ${WORKDIR}/bounds/ |  wc -l)

  echo -e ">>> Se han creado ${Y}${FILES}${W} archivos para ${G}${PAIS}${W}."
fi

# Verifica si existen mosaicos precompilados para el mar.
if [ -e ${WORKDIR}/sea/index.txt.gz ]; then
  OPTIONS="--precomp-sea=${WORKDIR}/sea/"
fi


cd ${WORKDIR}/${PAIS}

echo "------------------------------------------------------------------------"
echo "Generando mapa de ${PAIS} con mkgmap."
echo "------------------------------------------------------------------------"
echo

java ${JAVA_MEM} -enableassertions -jar ${MKGMAP} ${OPTIONS} \
--max-jobs=2 \
--copyright-message="${COPY}" \
--product-id=${PRODUCTID} \
--product-version=${FECHA} \
--family-id=980 \
--mapname=${MAPNAME} \
--style-file=${WORKDIR}/styles/ \
--style=default_ar \
--improve-overview \
--reduce-point-density=4 \
--reduce-point-density-polygon=8 \
--min-size-polygon=12 \
--polygon-size-limits="24:12,18:10,16:8,14:4,12:2,11:0" \
--simplify-lines="23:2.6,22:4.2,21:5.4,20:6" \
--bounds=${WORKDIR}/bounds/ \
--location-autofill=is_in,nearest \
--index \
--housenumbers \
--split-name-index \
--road-name-config=${WORKDIR}/roadNameConfig.txt \
--latin1 \
--drive-on=detect,right \
--generate-sea \
--add-pois-to-areas \
--add-pois-to-lines \
--link-pois-to-ways \
--process-destination \
--process-exits \
--make-opposite-cycleways \
--order-by-decreasing-area \
--ignore-fixme-values \
--max-routing-island-len=500 \
--fix-roundabout-direction \
--name-tag-list=name,place_name,alt_name \
--merge-lines \
--allow-reverse-merge \
--preserve-element-order \
--remove-ovm-work-files=false \
--roundabout-flare-rules-config=${WORKDIR}/RoundaboutFlareRules.config \
--route \
--add-boundary-nodes-at-admin-boundaries=2 \
--poi-address \
--report-roundabout-issues=all \
--report-routing-islands \
--report-similar-arcs \
--report-dead-ends=2 \
--output-dir=${WORKDIR}/ \
--read-config=${PAIS}.args > ${PAIS}.log 2>&1



# Crea una única imagen de mapa ruteable para Garmin.
cd ${WORKDIR}
echo "${DESCRIPTION}" > licencia.txt
echo "${COPYRIGHT}" >> licencia.txt
echo -e ">>> Creando imagen ${G}gmapsupp.img${W}."

java ${JAVA_MEM} -enableassertions \
-jar ${MKGMAP} \
--max-jobs=2 \
--description="${DESCRIPTION}" \
--license-file=licencia.txt \
--overview-mapname="Argentina" \
--family-id=980 \
--family-name="OpenStreetMap" \
--housenumbers \
--split-name-index \
--index \
--latin1 \
--route \
--gmapsupp \
980*.img ovm_*.img mapnik.txt


if [ -e ${WORKDIR}/mapnik.typ ]; then
  mv mapnik.typ mapnik.TYP
fi

