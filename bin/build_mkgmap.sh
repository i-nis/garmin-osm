#!/bin/bash
#
# build_mkgmap.sh: script descargar e instalar:
# * mkgmap
# * splitter
# * osmconvert
# * osmfilter
# * pbftoosm
#
# (C) 2012 - 2022 Martin Andres Gomez Gimenez <mggimenez@nis.com.ar>
# Distributed under the terms of the GNU General Public License v3
#


WORKDIR=`pwd`
MKGMAP_DOWNLOAD_URL="http://www.mkgmap.org.uk/download"
MKGMAP_VERSION="r4905"
SPLITTER_VERSION="r653"


OSMCONVERT_URL="http://m.m.i24.cc/osmconvert.c"
OSMFILTER_URL="http://m.m.i24.cc/osmfilter.c"
PBFTOOSM_URL="http://m.m.i24.cc/pbftoosm.c"

OSMCONVERT="${WORKDIR}/bin/osmconvert"
OSMFILTER="${WORKDIR}/bin/osmfilter"
PBFTOOSM="${WORKDIR}/bin/pbftoosm"



rm -rf ${WORKDIR}/mkgmap*
rm -rf ${WORKDIR}/splitter*

wget -c ${MKGMAP_DOWNLOAD_URL}/mkgmap-${MKGMAP_VERSION}.zip
wget -c ${MKGMAP_DOWNLOAD_URL}/splitter-${SPLITTER_VERSION}.zip

unzip mkgmap-${MKGMAP_VERSION}.zip
unzip splitter-${SPLITTER_VERSION}.zip

rm -f mkgmap-${MKGMAP_VERSION}.zip
rm -f splitter-${SPLITTER_VERSION}.zip

ln --symbolic mkgmap-${MKGMAP_VERSION} mkgmap
ln --symbolic splitter-${SPLITTER_VERSION} splitter

wget -O - ${OSMCONVERT_URL} | cc -x c - -lz -O3 -o  ${OSMCONVERT} &>/dev/null
wget -O -  ${OSMFILTER_URL} | cc -x c - -O3 -o ${OSMFILTER} &>/dev/null
wget -O - ${PBFTOOSM_URL} |  cc -x c - -lz -O3 -o ${PBFTOOSM} &>/dev/null

