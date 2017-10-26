#!/bin/bash

git clone https://github.com/ldbc/ldbc_snb_datagen.git /opt/ldbc_snb_datagen
chmod -R g=u /opt/ldbc_snb_datagen
cp /local/repository/ldbc_snb_datagen.conf/* /opt/ldbc_snb_datagen/
