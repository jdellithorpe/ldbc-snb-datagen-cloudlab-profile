#!/bin/bash

git clone https://github.com/ldbc/ldbc_snb_datagen.git /mnt/dataset/ldbc_snb_datagen
chmod -R g=u /mnt/dataset/ldbc_snb_datagen
cp /local/repository/ldbc_snb_datagen.conf/* /mnt/dataset/ldbc_snb_datagen/
