#!/bin/bash
#
# build_mkgmap.sh: script descargar y compilar mkgmap.jar
#
# (C) 2012 - 2014 Martin Andres Gomez Gimenez <mggimenez@i-nis.com.ar>
# Distributed under the terms of the GNU General Public License v3
#

# Requiere los siguientes paquetes:
# gcc: http://gcc.gnu.org/


WORKDIR=`pwd`


OSMCONVERT_URL="http://m.m.i24.cc/osmconvert.c"
OSMFILTER_URL="http://m.m.i24.cc/osmfilter.c"
PBFTOOSM_URL="http://m.m.i24.cc/pbftoosm.c"

OSMCONVERT="${WORKDIR}/bin/osmconvert"
OSMFILTER="${WORKDIR}/bin/osmfilter"
PBFTOOSM="${WORKDIR}/bin/pbftoosm"



rm -rf ${WORKDIR}/mkgmap
rm -rf ${WORKDIR}/splitter


svn export http://svn.mkgmap.org.uk/mkgmap/trunk mkgmap

# Se compila mkgmap
cd ${WORKDIR}/mkgmap
ant


cd ${WORKDIR}
svn export http://svn.mkgmap.org.uk/splitter/trunk splitter

# Se compila splitter
cd ${WORKDIR}/splitter
ant


wget -O - ${OSMCONVERT_URL} | cc -x c - -lz -O3 -o  ${OSMCONVERT} &>/dev/null
wget -O -  ${OSMFILTER_URL} | cc -x c - -O3 -o ${OSMFILTER} &>/dev/null
wget -O - ${PBFTOOSM_URL} |  cc -x c - -lz -O3 -o ${PBFTOOSM} &>/dev/null
