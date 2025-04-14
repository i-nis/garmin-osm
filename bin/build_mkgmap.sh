#!/bin/bash
#
# build_mkgmap.sh: script descargar e instalar:
# * mkgmap
# * splitter
# * osmconvert
# * osmfilter
# * pbftoosm
#
# (C) 2012 - 2025 Martin Andres Gomez Gimenez <mggimenez@nis.com.ar>
# Distributed under the terms of the GNU General Public License v3
#


WORKDIR=`pwd`
MKGMAP_DOWNLOAD_URL="http://www.mkgmap.org.uk/download"
MKGMAP_VERSION="r4923"
SPLITTER_VERSION="r654"


OSMCONVERT_URL="http://m.m.i24.cc/osmconvert.c"
OSMFILTER_URL="http://m.m.i24.cc/osmfilter.c"
PBFTOOSM_URL="http://m.m.i24.cc/pbftoosm.c"

OSMCONVERT="${WORKDIR}/bin/osmconvert"
OSMFILTER="${WORKDIR}/bin/osmfilter"
PBFTOOSM="${WORKDIR}/bin/pbftoosm"

MKGMAP_TO_REMOVE=$(ls | grep mkgmap-r)
SPLITTER_TO_REMOVE=$(ls | grep splitter-r)


wget -c ${MKGMAP_DOWNLOAD_URL}/mkgmap-${MKGMAP_VERSION}.zip
wget -c ${MKGMAP_DOWNLOAD_URL}/splitter-${SPLITTER_VERSION}.zip

# Verifica que mkgmap-${MKGMAP_VERSION}.zip fue descargado para actualizar.
if [ -e mkgmap-${MKGMAP_VERSION}.zip ]; then
  rm -rf ${WORKDIR}/${MKGMAP_TO_REMOVE}
  unzip mkgmap-${MKGMAP_VERSION}.zip
  rm -f mkgmap-${MKGMAP_VERSION}.zip
  ln --symbolic mkgmap-${MKGMAP_VERSION} mkgmap
fi

# Verifica que splitter-${SPLITTER_VERSION}.zip fue descargado para actualizar.
if [ -e splitter-${SPLITTER_VERSION}.zip ]; then
  rm -rf ${WORKDIR}/${SPLITTER_TO_REMOVE}
  unzip splitter-${SPLITTER_VERSION}.zip
  rm -f splitter-${SPLITTER_VERSION}.zip
  ln --symbolic splitter-${SPLITTER_VERSION} splitter
fi

wget -O - ${OSMCONVERT_URL} | cc -x c - -lz -O3 -o  ${OSMCONVERT} &>/dev/null
wget -O -  ${OSMFILTER_URL} | cc -x c - -O3 -o ${OSMFILTER} &>/dev/null
wget -O - ${PBFTOOSM_URL} |  cc -x c - -lz -O3 -o ${PBFTOOSM} &>/dev/null

