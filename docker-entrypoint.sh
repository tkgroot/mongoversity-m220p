#!/bin/bash
#
set -e

# fork serving the jupyter notebook
# create the directory where the logfile will be placed, then fork the process
if [[ ! -d /var/log/jupyter ]]; then
  #statements
  mkdir -p /var/log/jupyter
fi
jupyter notebook --ip=0.0.0.0 --port=8888 --allow-root --no-browser \
&> /var/log/jupyter/jupyter.log &
# wait for the jupyter notbook to start and print the first four lines of the
# logfile, which contains the login token for jupyter notebook
sleep 2s && head -n4 /var/log/jupyter/jupyter.log

# check if the first passing param is equal to run.py
if [[ "${1}" = "run.py" ]]; then
  # execute "python3 run.py"
  exec $(which python3) "${1}"
fi

exec "${@}"
