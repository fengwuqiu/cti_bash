#!/bin/bash

home_dir=${HOME}/cti_bash

if [ -d "${home_dir}" ] ; then

   rm -rf  ${home_dir}

fi

cd  ${HOME}
git clone https://gitee.com/ctinav/cti_bash.git

bash   ${home_dir}/base.sh