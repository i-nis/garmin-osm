#!/bin/bash
#
# gengpi.sh: script para generar POIs para Garmin.
#
# (C) 2012 - 2021 Martin Andres Gomez Gimenez <mggimenez@nis.com.ar>
# Distributed under the terms of the GNU General Public License v3
#

# Requiere los siguientes paquetes:
# osmconvert: http://wiki.openstreetmap.org/wiki/osmconvert
# osmfilter: http://wiki.openstreetmap.org/wiki/osmfilter
WORKDIR=`pwd`
OSMCONVERT="${WORKDIR}/bin/osmconvert"
OSMFILTER="${WORKDIR}/bin/osmfilter"
BITMAP_PATH="${WORKDIR}/bitmaps"

# Uso de memoria: 1024 MiB
HASH_MEM="--hash-memory=1024"

# Opciones para cortar el cono sur de América.
COORD="-77,-56,-49,-16"



# Función para crear directorios
function create_directory() {
  local DIRECTORY=${1}

  if [ ! -d ${DIRECTORY} ]; then
    mkdir --parent ${DIRECTORY}
  fi

}


# Función para eliminar archivos generados sin información.
function generated_pois() {
  local ARCHIVE=${1}

  ARCHIVE_SIZE=$(stat -c %s ${ARCHIVE})

  if [ ${ARCHIVE_SIZE} -ne 179 ]; then
    return 0
  else
    return 1
  fi

}

POIS_DIR="$WORKDIR/gpi"
cd $WORKDIR

# Si no existe el directorio destino para POIs est es creado.
create_directory "$POIS_DIR"


# Se cambia el formato de .osm a .o5m mediante la herramienta osmconvert.
if [ ! -e south-america.o5m ]; then
  $OSMCONVERT ${HASH_MEM} ${BOX} --drop-version  --verbose \
  south-america-latest.o5m --out-o5m > south-america.o5m
fi

# Semáforos
# --------------------------------------------------------------------------------
${OSMFILTER} south-america.o5m --keep=  \
--keep-nodes="crossing=traffic_signals or highway=traffic_signals" > semaforos.osm

if generated_pois "semaforos.osm"; then

  gpsbabel -i osm -f semaforos.osm \
    -o garmin_gpi,sleep=5,unique=0,proximity=20,category="Semaforos",bitmap="$BITMAP_PATH/semaforo.bmp" \
    -F ${POIS_DIR}/semaforos.gpi
fi

rm -f semaforos.osm


# Estacionamientos
# --------------------------------------------------------------------------------
${OSMFILTER} south-america.o5m --keep=  \
--keep-nodes="amenity=parking" > parking.osm

if generated_pois "parking.osm"; then
  gpsbabel -i osm -f parking.osm \
    -o garmin_gpi,sleep=5,unique=0,category="Estacionamientos",bitmap="$BITMAP_PATH/estacionamiento.bmp" \
    -F ${POIS_DIR}/estacionamientos.gpi
fi

rm -f parking.osm


# Estaciones de servicio
# --------------------------------------------------------------------------------
# Axion
${OSMFILTER} south-america.o5m --keep=  \
--keep-nodes="amenity=fuel and brand=Axion" > combustible_axion.osm

if generated_pois "combustible_axion.osm"; then
  gpsbabel -i osm -f combustible_axion.osm \
    -o garmin_gpi,sleep=5,unique=0,category="Estaciones Axion",bitmap="$BITMAP_PATH/esso.bmp" \
    -F ${POIS_DIR}/combustible_axion.gpi
fi

# EG3
${OSMFILTER} south-america.o5m --keep=  \
--keep-nodes="amenity=fuel and brand=EG3" > combustible_eg3.osm

if generated_pois "combustible_eg3.osm"; then
  gpsbabel -i osm -f combustible_eg3.osm \
    -o garmin_gpi,sleep=5,unique=0,category="Estaciones EG3",bitmap="$BITMAP_PATH/eg3.bmp" \
    -F ${POIS_DIR}/combustible_eg3.gpi
fi


# Esso
${OSMFILTER} south-america.o5m --keep=  \
--keep-nodes="amenity=fuel and brand=Esso" > combustible_esso.osm

if generated_pois "combustible_esso.osm"; then
  gpsbabel -i osm -f combustible_esso.osm \
    -o garmin_gpi,sleep=5,unique=0,category="Estaciones Esso",bitmap="$BITMAP_PATH/esso.bmp" \
    -F ${POIS_DIR}/combustible_esso.gpi
fi


# Oil
${OSMFILTER} south-america.o5m --keep=  \
--keep-nodes="amenity=fuel and brand=Oil" > combustible_oil.osm

if generated_pois "combustible_oil.osm"; then
  gpsbabel -i osm -f combustible_oil.osm \
    -o garmin_gpi,sleep=5,unique=0,category="Estaciones Oil",bitmap="$BITMAP_PATH/oil.bmp" \
    -F ${POIS_DIR}/combustible_oil.gpi
fi


# Petrobras
${OSMFILTER} south-america.o5m --keep=  \
--keep-nodes="amenity=fuel and brand=Petrobras" > combustible_petrobras.osm

if generated_pois "combustible_petrobras.osm"; then
  gpsbabel -i osm -f combustible_petrobras.osm \
    -o garmin_gpi,sleep=5,unique=0,category="Estaciones Petrobras",bitmap="$BITMAP_PATH/petrobras.bmp" \
    -F ${POIS_DIR}/combustible_petrobras.gpi
fi


# Shell
${OSMFILTER} south-america.o5m --keep=  \
--keep-nodes="amenity=fuel and brand=Shell" > combustible_shell.osm

if generated_pois "combustible_shell.osm"; then
  gpsbabel -i osm -f combustible_shell.osm \
    -o garmin_gpi,sleep=5,unique=0,category="Estaciones Shell",bitmap="$BITMAP_PATH/shell.bmp" \
    -F ${POIS_DIR}/combustible_shell.gpi
fi


# YPF
${OSMFILTER} south-america.o5m --keep=  \
--keep-nodes="amenity=fuel and brand=YPF" > combustible_ypf.osm

if generated_pois "combustible_ypf.osm"; then
  gpsbabel -i osm -f combustible_ypf.osm \
    -o garmin_gpi,sleep=5,unique=0,category="Estaciones YPF",bitmap="$BITMAP_PATH/ypf.bmp" \
    -F ${POIS_DIR}/combustible_ypf.gpi
fi


# Otras estaciones de servicio
${OSMFILTER} south-america.o5m --keep=  \
--keep-nodes="amenity=fuel and brand=Independent" > combustible_independientes.osm

if generated_pois "combustible_independientes.osm"; then
  gpsbabel -i osm -f combustible_independientes.osm \
    -o garmin_gpi,sleep=5,unique=0,category="Estaciones de servicio independientes",bitmap="$BITMAP_PATH/surtidor.bmp" \
    -F ${POIS_DIR}/combustible_independientes.gpi
fi

rm -f combustible_*.osm



# Estaciones de tren
# -------------------------------------------------------------------------------
${OSMFILTER} south-america.o5m --keep=  \
--keep-nodes="railway=station" > estaciones_trenes.osm

if generated_pois "estaciones_trenes.osm"; then
  gpsbabel -i osm -f estaciones_trenes.osm \
    -o garmin_gpi,sleep=5,unique=0,category="Estaciones de trenes",bitmap="$BITMAP_PATH/tren.bmp" \
    -F ${POIS_DIR}/estaciones_trenes.gpi
fi

rm -f estaciones_trenes.osm



# Lomos de burro
# -------------------------------------------------------------------------------
${OSMFILTER} south-america.o5m --keep=  \
--keep-nodes=" traffic_calming=yes" > lomos_de_burro.osm

if generated_pois "lomos_de_burro.osm"; then
  gpsbabel -i osm -f lomos_de_burro.osm \
    -o garmin_gpi,sleep=5,unique=0,category="Lomos de burro",bitmap="$BITMAP_PATH/lomo_de_burro.bmp" \
    -F ${POIS_DIR}/lomos_de_burros.gpi
fi

rm -f lomos_de_burro.osm

