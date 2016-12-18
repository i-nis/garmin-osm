#!/bin/bash
#
# gengpx.sh: script para generar archivos GPX.
#
# (C) 2012 - 2016 Martin Andres Gomez Gimenez <mggimenez@ingeniovirtual.com.ar>
# Distributed under the terms of the GNU General Public License v3
#

# Requiere los siguientes paquetes:
# osmconvert: http://wiki.openstreetmap.org/wiki/osmconvert
# osmfilter: http://wiki.openstreetmap.org/wiki/osmfilter

WORKDIR=`pwd`
OSMCONVERT="${WORKDIR}/bin/osmconvert"
OSMFILTER="${WORKDIR}/bin/osmfilter"

# Uso de memoria: 128 MiB
HASH_MEM="--hash-memory=128"

BITMAP_PATH="$WORKDIR/bitmaps"



# Función para crear directorios.
function create_directory() {
  local DIRECTORY=$1

  if [ ! -d $DIRECTORY ]; then
    mkdir --parent $DIRECTORY
  fi

}


# Función para setear alertas por proximidad.
function proximity() {
  local DISTANCE=$1

  awk '{ gsub("</sym>","</sym>\n \
  <extensions>\n \
    <gpxx:WaypointExtension>\n \
      <gpxx:Proximity>'${DISTANCE}'</gpxx:Proximity>\n \
      <gpxx:DisplayMode>SymbolAndName</gpxx:DisplayMode>\n \
    </gpxx:WaypointExtension>\n \
  </extensions>"); print }'
}


POIS_DIR="$WORKDIR/gpx"
cd $WORKDIR

# Si no existe el directorio destino para POIs est es creado.
create_directory "$POIS_DIR"


# Se cambia el formato de .osm a .o5m mediante la herramienta osmconvert.
if [ ! -e south-america.o5m ]; then
  $OSMCONVERT ${HASH_MEM} --drop-version south-america.osm \
  --out-o5m >south-america.o5m
fi



$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-ways="highway=* and maxspeed>=80" \
> south-america-ways_highspeed.osm

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-ways="highway=* and maxspeed>50 and maxspeed<80" \
> south-america-ways_medspeed.osm

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-ways="highway=* and maxspeed<=50" \
> south-america-ways_lowspeed.osm


# Cruces ferroviarios
# ----------------------------------------------------------------------------
FFCC="$POIS_DIR/cruces_ferroviarios"
create_directory "$FFCC"

$OSMFILTER ${HASH_MEM} south-america-ways_highspeed.osm --keep= \
--keep-nodes="railway=level_crossing" > south-america-cruces_ferroviarios_highspeed.osm

$OSMFILTER ${HASH_MEM} south-america-ways_medspeed.osm --keep= \
--keep-nodes="railway=level_crossing" > south-america-cruces_ferroviarios_medspeed.osm

$OSMFILTER ${HASH_MEM} south-america-ways_lowspeed.osm --keep= \
--keep-nodes="railway=level_crossing" > south-america-cruces_ferroviarios_lowspeed.osm


gpsbabel -i osm -f south-america-cruces_ferroviarios_highspeed.osm \
-o gpx,garminextensions=1 -x position,distance=20m \
-F $FFCC/south-america-cruces_ffcch.gpx

gpsbabel -i osm -f south-america-cruces_ferroviarios_medspeed.osm \
-o gpx,garminextensions=1 -x position,distance=20m \
-F $FFCC/south-america-cruces_ffccm.gpx

gpsbabel -i osm -f south-america-cruces_ferroviarios_lowspeed.osm \
-o gpx,garminextensions=1 -x position,distance=20m \
-F $FFCC/south-america-cruces_ffccl.gpx

# Se reemplaza el nombre por uno legible y se setea próximidad.
sed 's/<name>osm-id [0-9]*/<name> A 300m. cruce de ferrocarril/g' \
$FFCC/south-america-cruces_ffcch.gpx  | \
proximity 300  > $FFCC/cruces_ferroviariosh.gpx

sed 's/<name>osm-id [0-9]*/<name> A 100m. cruce de ferrocarril/g' \
$FFCC/south-america-cruces_ffccm.gpx  | \
proximity 100  > $FFCC/cruces_ferroviariosm.gpx

sed 's/<name>osm-id [0-9]*/<name> Cruce de ferrocarril/g' \
$FFCC/south-america-cruces_ffccl.gpx  | \
proximity 25  > $FFCC/cruces_ferroviariosl.gpx

gpsbabel -i gpx \
-f $FFCC/cruces_ferroviariosh.gpx \
-f $FFCC/cruces_ferroviariosm.gpx \
-f $FFCC/cruces_ferroviariosl.gpx \
-x duplicate,location,shortname \
-o gpx,garminextensions=1 -F $FFCC/cruces_ferroviarios.gpx

rm --force $FFCC/south-america-cruces_ffcch.gpx
rm --force $FFCC/south-america-cruces_ffccm.gpx
rm --force $FFCC/south-america-cruces_ffccl.gpx
rm --force $FFCC/cruces_ferroviariosh.gpx
rm --force $FFCC/cruces_ferroviariosm.gpx
rm --force $FFCC/cruces_ferroviariosl.gpx
rm --force south-america-cruces_ferroviarios_highspeed.osm
rm --force south-america-cruces_ferroviarios_medspeed.osm
rm --force south-america-cruces_ferroviarios_lowspeed.osm


# Peajes
# ----------------------------------------------------------------------------
PEAJES="$POIS_DIR/peajes"
create_directory "$PEAJES"

$OSMFILTER ${HASH_MEM} south-america-ways_highspeed.osm --keep= \
--keep-nodes="barrier=toll_booth" > south-america-peajes_highspeed.osm

$OSMFILTER ${HASH_MEM} south-america-ways_medspeed.osm --keep= \
--keep-nodes="barrier=toll_booth" > south-america-peajes_medspeed.osm

$OSMFILTER ${HASH_MEM} south-america-ways_lowspeed.osm --keep= \
--keep-nodes="barrier=toll_booth" > south-america-peajes_lowspeed.osm

gpsbabel -i osm -f south-america-peajes_highspeed.osm \
-o gpx,garminextensions=1 -x position,distance=20m \
-F $PEAJES/south-america-peajesh.gpx

gpsbabel -i osm -f south-america-peajes_medspeed.osm \
-o gpx,garminextensions=1 -x position,distance=20m \
-F $PEAJES/south-america-peajesm.gpx

gpsbabel -i osm -f south-america-peajes_lowspeed.osm \
-o gpx,garminextensions=1 -x position,distance=20m \
-F $PEAJES/south-america-peajesl.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> A 300m. peaje/g' \
$PEAJES/south-america-peajesh.gpx | \
proximity 300 > $PEAJES/peajesh.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> A 100m. peaje/g' \
$PEAJES/south-america-peajesm.gpx | \
proximity 100 > $PEAJES/peajesm.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> Peaje/g' \
$PEAJES/south-america-peajesl.gpx | \
proximity 30 > $PEAJES/peajesl.gpx

gpsbabel -i gpx \
-f $PEAJES/peajesh.gpx \
-f $PEAJES/peajesm.gpx \
-f $PEAJES/peajesl.gpx \
-x duplicate,location,shortname \
-o gpx,garminextensions=1 -F $PEAJES/peajes.gpx

rm --force $PEAJES/peajesh.gpx \
rm --force $PEAJES/peajesm.gpx \
rm --force $PEAJES/peajesl.gpx \
rm --force $PEAJES/south-america-peajesh.gpx
rm --force $PEAJES/south-america-peajesm.gpx
rm --force $PEAJES/south-america-peajesl.gpx
rm --force south-america-peajes_highspeed.osm
rm --force south-america-peajes_medspeed.osm
rm --force south-america-peajes_lowspeed.osm
rm --force south-america-peajes.osm


# Radares 20 Km/h
# ----------------------------------------------------------------------------
RADARES_20="$POIS_DIR/radares/radares_20"
create_directory "$RADARES_20"

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-nodes="highway=speed_camera and maxspeed=20" > south-america-radares_20.osm

gpsbabel -i osm -f south-america-radares_20.osm \
-o gpx,garminextensions=1 -F $RADARES_20/south-america-radares_20kmh.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> 20 Km\/h/g' \
$RADARES_20/south-america-radares_20kmh.gpx > $RADARES_20/radares_20.gpx
rm --force $RADARES_20/south-america-radares_20kmh.gpx
rm --force south-america-radares_20.osm


# Radares 30 Km/h
# ----------------------------------------------------------------------------
RADARES_30="$POIS_DIR/radares/radares_30"
create_directory "$RADARES_30"

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-nodes="highway=speed_camera and maxspeed=30" > south-america-radares_30.osm

gpsbabel -i osm -f south-america-radares_30.osm \
-o gpx,garminextensions=1 -F $RADARES_30/south-america-radares_30kmh.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> 30 Km\/h/g' \
$RADARES_30/south-america-radares_30kmh.gpx > $RADARES_30/radares_30.gpx
rm --force $RADARES_30/south-america-radares_30kmh.gpx
rm --force south-america-radares_30.osm



# Radares 40 Km/h
# ----------------------------------------------------------------------------
RADARES_40="$POIS_DIR/radares/radares_40"
create_directory "$RADARES_40"

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-nodes="highway=speed_camera and maxspeed=40" > south-america-radares_40.osm

gpsbabel -i osm -f south-america-radares_40.osm \
-o gpx,garminextensions=1 -F $RADARES_40/south-america-radares_40kmh.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> 40 Km\/h/g' \
$RADARES_40/south-america-radares_40kmh.gpx > $RADARES_40/radares_40.gpx
rm --force $RADARES_40/south-america-radares_40kmh.gpx
rm --force south-america-radares_40.osm



# Radares 45 Km/h
# ----------------------------------------------------------------------------
RADARES_45="$POIS_DIR/radares/radares_45"
create_directory "$RADARES_45"

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-nodes="highway=speed_camera and maxspeed=45" > south-america-radares_45.osm

gpsbabel -i osm -f south-america-radares_45.osm \
-o gpx,garminextensions=1 -F $RADARES_45/south-america-radares_45kmh.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> 45 Km\/h/g' \
$RADARES_45/south-america-radares_45kmh.gpx > $RADARES_45/radares_45.gpx
rm --force $RADARES_45/south-america-radares_45kmh.gpx
rm --force south-america-radares_45.osm



# Radares 50 Km/h
# ----------------------------------------------------------------------------
RADARES_50="$POIS_DIR/radares/radares_50"
create_directory "$RADARES_50"

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-nodes="highway=speed_camera and maxspeed=50" > south-america-radares_50.osm

gpsbabel -i osm -f south-america-radares_50.osm \
-o gpx,garminextensions=1 -F $RADARES_50/south-america-radares_50kmh.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> 50 Km\/h/g' \
$RADARES_50/south-america-radares_50kmh.gpx > $RADARES_50/radares_50.gpx
rm --force $RADARES_50/south-america-radares_50kmh.gpx
rm --force south-america-radares_50.osm



# Radares 60 Km/h
# ----------------------------------------------------------------------------
RADARES_60="$POIS_DIR/radares/radares_60"
create_directory "$RADARES_60"

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-nodes="highway=speed_camera and maxspeed=60" > south-america-radares_60.osm

gpsbabel -i osm -f south-america-radares_60.osm \
-o gpx,garminextensions=1 -F $RADARES_60/south-america-radares_60kmh.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> 60 Km\/h/g' \
$RADARES_60/south-america-radares_60kmh.gpx > $RADARES_60/radares_60.gpx
rm --force $RADARES_60/south-america-radares_60kmh.gpx
rm --force south-america-radares_60.osm



# Radares 70 Km/h
# ----------------------------------------------------------------------------
RADARES_70="$POIS_DIR/radares/radares_70"
create_directory "$RADARES_70"

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-nodes="highway=speed_camera and maxspeed=70" > south-america-radares_70.osm

gpsbabel -i osm -f south-america-radares_70.osm \
-o gpx,garminextensions=1 -F $RADARES_70/south-america-radares_70kmh.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> 70 Km\/h/g' \
$RADARES_70/south-america-radares_70kmh.gpx > $RADARES_70/radares_70.gpx
rm --force $RADARES_70/south-america-radares_70kmh.gpx
rm --force south-america-radares_70.osm



# Radares 75 Km/h
# ----------------------------------------------------------------------------
RADARES_75="$POIS_DIR/radares/radares_75"
create_directory "$RADARES_75"

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-nodes="highway=speed_camera and maxspeed=75" > south-america-radares_75.osm

gpsbabel -i osm -f south-america-radares_75.osm \
-o gpx,garminextensions=1 -F $RADARES_75/south-america-radares_75kmh.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> 75 Km\/h/g' \
$RADARES_75/south-america-radares_75kmh.gpx > $RADARES_75/radares_75.gpx
rm --force $RADARES_75/south-america-radares_75kmh.gpx
rm --force south-america-radares_75.osm



# Radares 80 Km/h
# ----------------------------------------------------------------------------
RADARES_80="$POIS_DIR/radares/radares_80"
create_directory "$RADARES_80"

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-nodes="highway=speed_camera and maxspeed=80" > south-america-radares_80.osm

gpsbabel -i osm -f south-america-radares_80.osm \
-o gpx,garminextensions=1 -F $RADARES_80/south-america-radares_80kmh.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> 80 Km\/h/g' \
$RADARES_80/south-america-radares_80kmh.gpx > $RADARES_80/radares_80.gpx
rm --force $RADARES_80/south-america-radares_80kmh.gpx
rm --force south-america-radares_80.osm



# Radares 90 Km/h
# ----------------------------------------------------------------------------
RADARES_90="$POIS_DIR/radares/radares_90"
create_directory "$RADARES_90"

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-nodes="highway=speed_camera and maxspeed=90" > south-america-radares_90.osm

gpsbabel -i osm -f south-america-radares_90.osm \
-o gpx,garminextensions=1 -F $RADARES_90/south-america-radares_90kmh.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> 90 Km\/h/g' \
$RADARES_90/south-america-radares_90kmh.gpx > $RADARES_90/radares_90.gpx
rm --force $RADARES_90/south-america-radares_90kmh.gpx
rm --force south-america-radares_90.osm



# Radares 100 Km/h
# ----------------------------------------------------------------------------
RADARES_100="$POIS_DIR/radares/radares_100"
create_directory "$RADARES_100"

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-nodes="highway=speed_camera and maxspeed=100" > south-america-radares_100.osm

gpsbabel -i osm -f south-america-radares_100.osm \
-o gpx,garminextensions=1 -F $RADARES_100/south-america-radares_100kmh.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> 100 Km\/h/g' \
$RADARES_100/south-america-radares_100kmh.gpx > $RADARES_100/radares_100.gpx
rm --force $RADARES_100/south-america-radares_100kmh.gpx
rm --force south-america-radares_100.osm



# Radares 110 Km/h
# ----------------------------------------------------------------------------
RADARES_110="$POIS_DIR/radares/radares_110"
create_directory "$RADARES_110"

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-nodes="highway=speed_camera and maxspeed=110" > south-america-radares_110.osm

gpsbabel -i osm -f south-america-radares_110.osm \
-o gpx,garminextensions=1 -F $RADARES_110/south-america-radares_110kmh.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> 110 Km\/h/g' \
$RADARES_110/south-america-radares_110kmh.gpx > $RADARES_110/radares_110.gpx
rm --force $RADARES_110/south-america-radares_110kmh.gpx
rm --force south-america-radares_110.osm



# Radares 120 Km/h
# ----------------------------------------------------------------------------
RADARES_120="$POIS_DIR/radares/radares_120"
create_directory "$RADARES_120"

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-nodes="highway=speed_camera and maxspeed=120" > south-america-radares_120.osm

gpsbabel -i osm -f south-america-radares_120.osm \
-o gpx,garminextensions=1 -F $RADARES_120/south-america-radares_120kmh.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> 120 Km\/h/g' \
$RADARES_120/south-america-radares_120kmh.gpx > $RADARES_120/radares_120.gpx
rm --force $RADARES_120/south-america-radares_120kmh.gpx
rm --force south-america-radares_120.osm



# Radares 130 Km/h
# ----------------------------------------------------------------------------
RADARES_130="$POIS_DIR/radares/radares_130"
create_directory "$RADARES_130"

$OSMFILTER ${HASH_MEM} south-america.o5m --keep= \
--keep-nodes="highway=speed_camera and maxspeed=130" > south-america-radares_130.osm

gpsbabel -i osm -f south-america-radares_130.osm \
-o gpx,garminextensions=1 -F $RADARES_130/south-america-radares_130kmh.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> 130 Km\/h/g' \
$RADARES_130/south-america-radares_130kmh.gpx > $RADARES_130/radares_130.gpx
rm --force $RADARES_130/south-america-radares_130kmh.gpx
rm --force south-america-radares_130.osm



# Señales de stop
# ----------------------------------------------------------------------------
STOP="$POIS_DIR/pare"
create_directory "$STOP"

$OSMFILTER ${HASH_MEM} south-america-ways_highspeed.osm --keep=  \
--keep-nodes="highway=stop" > south-america-pare_highspeed.osm

$OSMFILTER ${HASH_MEM} south-america-ways_medspeed.osm --keep=  \
--keep-nodes="highway=stop" > south-america-pare_medspeed.osm

$OSMFILTER ${HASH_MEM} south-america-ways_lowspeed.osm --keep=  \
--keep-nodes="highway=stop" > south-america-pare_lowspeed.osm

gpsbabel -i osm -f south-america-pare_highspeed.osm -o gpx,garminextensions=1 \
-F $STOP/south-america-stoph.gpx

gpsbabel -i osm -f south-america-pare_medspeed.osm -o gpx,garminextensions=1 \
-F $STOP/south-america-stopm.gpx

gpsbabel -i osm -f south-america-pare_lowspeed.osm -o gpx,garminextensions=1 \
-F $STOP/south-america-stopl.gpx

# Se reemplaza el nombre por uno legible.
sed 's/<name>osm-id [0-9]*/<name> A 300m. pare/g' \
$STOP/south-america-stoph.gpx | \
proximity 300  > $STOP/pareh.gpx

sed 's/<name>osm-id [0-9]*/<name> A 100m. pare/g' \
$STOP/south-america-stopm.gpx | \
proximity 100  > $STOP/parem.gpx

sed 's/<name>osm-id [0-9]*/<name> Pare/g' \
$STOP/south-america-stopl.gpx | \
proximity 25  > $STOP/parel.gpx

gpsbabel -i gpx \
-f $STOP/pareh.gpx \
-f $STOP/parem.gpx \
-f $STOP/parel.gpx \
-x duplicate,location \
-o gpx,garminextensions=1 -F $STOP/pare.gpx



rm --force $STOP/south-america-stoph.gpx
rm --force $STOP/south-america-stopm.gpx
rm --force $STOP/south-america-stopl.gpx
rm --force $STOP/pareh.gpx
rm --force $STOP/parem.gpx
rm --force $STOP/parel.gpx
rm --force south-america-pare_highspeed.osm
rm --force south-america-pare_medspeed.osm
rm --force south-america-pare_lowspeed.osm
rm --force south-america-ways_highspeed.osm
rm --force south-america-ways_medspeed.osm
rm --force south-america-ways_lowspeed.osm

