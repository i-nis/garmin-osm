#!/bin/bash
#
# 01_cleanosmdata.sh: script para eliminar mapas y archivos fuentes previamente
# generados.
#
# (C) 2012 - 2015 Martin Andres Gomez Gimenez <mggimenez@ingeniovirtual.com.ar>
# Distributed under the terms of the GNU General Public License v3
#



PAISES="south-america argentina bolivia brazil chile paraguay uruguay"


ALL="$1"
FECHA=$(date +%G%m%d)
WORKDIR=`pwd`



# Borra la informacíón
for pais in ${PAISES}; do

  if [ -e ${pais} ]; then
    rm -f state.txt
    rm -f *.osc
    rm -f ${pais}/*.args
    rm -f ${pais}/*.gz
    rm -f ${pais}/*.gpi
    rm -f ${pais}/*.iso
    rm -f ${pais}/*.img*
    rm -f ${pais}/*.kml
    rm -f ${pais}/*.log
    rm -f ${pais}/*.log.*
    rm -f ${pais}/*.mdx
    rm -f ${pais}/*.mp
    rm -f ${pais}/*.osm
    rm -f ${pais}/*.osm.gz
    rm -f ${pais}/*.pbf
    rm -f ${pais}/*.tdb
    rm -f ${pais}/*.txt
    rm -f ${pais}/img/*
    rm -f gpi/*.gpi
    rm -f gpx/${pais}/*.gpx
    rm -f gpx/*/*.gpx
    rm -f gpx/*/*/*.gpx

    if [ "${ALL}" == "all" ]; then
      rm -f ${pais}/*.o5m
      rm -f ${pais}/*.pbf
      rm -f *.osm.bz2
      rm -f *.pbf
      rm -f ${pais}/*.zip
      rm -f bounds/*
      rm -rf sea*
    fi

  fi

done

rm -f *.osm
rm -f *.tar.bz2*
rm -f *.img*
rm -f *.mdx*
rm -f *.tdb*
rm -f *-boundaries.*
