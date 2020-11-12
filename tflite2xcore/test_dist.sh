#!/usr/bin/bash
set -e

TEMP_ENV=$(mktemp -d)

# create empty environment
conda create -y --prefix ${TEMP_ENV} python=3.6

# activate environment
eval "$(conda shell.bash hook)"
conda activate ${TEMP_ENV}

# install tflite2xcore package
pip install -e .

# test package import
python -c "import tflite2xcore"

# clean up
conda deactivate

if [ -d ${TEMP_ENV} ]; then
    rm -rf ${TEMP_ENV}
fi