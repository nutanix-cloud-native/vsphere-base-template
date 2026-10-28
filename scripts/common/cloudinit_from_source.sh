#!/bin/bash -ux

CLOUDINIT_VERSION="${CLOUDINIT_VERSION:-23.1.1}"

CLOUDINIT_DOWNLOADFILE="/tmp/cloudinit.tar.gz"
CLOUDINIT_EXTRACT_FOLDER="/tmp/cloudinit"

if type python3; then
    PYTHON_CMD=python3
    PIP_CMD=pip3
else
    PYTHON_CMD=python
    PIP_CMD=pip
fi

function fatal {
    echo "$1" >&2
    exit 1
}

function download {
    url=$1
    filename=$2

    if [ -x "$(which wget)" ] ; then
        wget -q "$url" -O "$filename"
    elif [ -x "$(which curl)" ]; then
        curl -o "$filename" -sfL "$url"
    else
        echo "Could not find curl or wget, please install one." >&2
        exit 1
    fi
}


type ${PYTHON_CMD} || fatal "${PYTHON_CMD} not found"
type ${PIP_CMD} || fatal "${PIP_CMD} not found"

download "https://github.com/canonical/cloud-init/archive/refs/tags/${CLOUDINIT_VERSION}.tar.gz" ${CLOUDINIT_DOWNLOADFILE}
mkdir -p ${CLOUDINIT_EXTRACT_FOLDER}
tar xzf ${CLOUDINIT_DOWNLOADFILE} -C ${CLOUDINIT_EXTRACT_FOLDER}

${PIP_CMD} install -r "${CLOUDINIT_EXTRACT_FOLDER}/cloud-init-${CLOUDINIT_VERSION}/requirements.txt"
(   cd "${CLOUDINIT_EXTRACT_FOLDER}/cloud-init-${CLOUDINIT_VERSION}" || exit 1
    ${PYTHON_CMD} setup.py build
    ${PYTHON_CMD} setup.py install -O1 --skip-build --init-system systemd --install-scripts /usr/bin
)

/bin/systemctl enable cloud-config.service
/bin/systemctl enable cloud-final.service
/bin/systemctl enable cloud-init-local.service
# cloud-init 24.3+ renamed cloud-init.service -> cloud-init-network.service
# and added cloud-init-main.service as the primary single-process unit
if systemctl cat cloud-init-main.service >/dev/null 2>&1; then
  /bin/systemctl enable cloud-init-main.service cloud-init-network.service
else
  /bin/systemctl enable cloud-init.service
fi

/bin/systemctl daemon-reload

rm -Rf ${CLOUDINIT_EXTRACT_FOLDER} ${CLOUDINIT_DOWNLOADFILE}
