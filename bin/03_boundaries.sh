#!/bin/bash
#
# 03_boundaries.sh: script para generar límites político-administrativos.
#
# (C) 2012 - 2014 Martin Andres Gomez Gimenez <mggimenez@i-nis.com.ar>
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



# Crea el directorio bounds/
if [ ! -d ${WORKDIR}/bounds ]; then
  mkdir --parents ${WORKDIR}/bounds
  echo ">>> Creando directorio bounds."
fi

# Selecciona el país, si no se pasan argumentos se procesan todos los países.
# PAIS = [all | argentina | bolivia | brazil | chile | paraguay | uruguay]
if [[ "${1}" == "" || "${1}" == "all" ]]; then
    PAIS="south-america"
  else
    PAIS="${1}"
fi

# Genera los datos límitrofes.
cd ${WORKDIR}

echo
echo "------------------------------------------------------------------------"
echo "Procesando límites político-administrativos con osmfilter."
echo "boundary: administrative,postal_code"
echo "------------------------------------------------------------------------"
echo

# Extrayendo información de límites.
${OSMFILTER} ${HASH_MEM} ${PAIS}-latest.o5m --drop-version --keep-nodes= \
--keep-ways-relations="boundary=administrative =postal_code postal_code=" \
--out-o5m > ${PAIS}-boundaries.o5m
