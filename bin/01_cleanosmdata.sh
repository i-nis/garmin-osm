#!/bin/bash
#
# 01_cleanosmdata.sh: script para eliminar mapas y archivos fuentes previamente
# generados. 
#
# (C) 2012 - 2021 Martin Andres Gomez Gimenez <mggimenez@nis.com.ar>
# Distributed under the terms of the GNU General Public License v3
#
#
# Uso:
# El script debe invocarse directamente sobre el directorio raíz de las siguientes
# maneras:
#
# bin/01_cleanosmdata.sh
#	Realiza un borrado parcial. Se utiliza especialmente para volver a generar
#	un mapa sin necesidad de actualizar los datos desde OpenStreetMap.
#
# bin/01_cleanosmdata.sh all
#	Elimina todos los datos generados por el usuario. Se utiliza para generar un
#	mapa nuevo actualizado.



PAISES="south-america argentina bolivia brazil colombia chile ecuador paraguay peru uruguay"


ALL="$1"
FECHA=$(date +%Y%m%d)
WORKDIR=`pwd`



# Realiza un borrado parcial.
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

    # Elimina todos los datos generados por el usuario.
    if [ "${ALL}" == "all" ]; then
      rm -f ${pais}/*.o5m
      rm -f ${pais}/*.pbf
      rm -f ${pais}/areas.poly
      rm -f ${pais}/${pais}.list
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

