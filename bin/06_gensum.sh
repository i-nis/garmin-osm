#!/bin/bash
#
# 06_gensum.sh: script para generar sumas para verificar el archivo "gmapsupp.img".
#
# (C) 2006 - 2021 Martin Andres Gomez Gimenez <mggimenez@nis.com.ar>
# Distributed under the terms of the GNU General Public License v3
#



# Función para generar sumas MD5, SHA1, SHA256, etc.
# NAME: nombre del programa que invoca.
# HASHES: algoritmos para verificar sumas.
# FILE: archivo desde el cual se creará la suma.
gensum() {
  local FILE="$1"
  local HASHES="md5 sha1 sha256"

  for hash in $HASHES; do
    SUM=`$hash"sum" $FILE`
    echo "# Use el comando \"$hash"sum" --check $FILE.$hash\" para verificar" > $FILE.$hash
    echo "$SUM" >> $FILE.$hash
  done

}

gensum "gmapsupp.img"

