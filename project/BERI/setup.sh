## Bluespec

# pickup Cambridge Comptuer Laboratory configuration files where possible
# and ensure we're using Quartus 12.1

if [ -n "${QUARTUS_SETUP_SH}" -a -r "${QUARTUS_SETUP_SH}" ] ; then
    . ${QUARTUS_SETUP_SH}
elif [ -f /local/ecad/setup.bash ] ; then
    . /local/ecad/setup.bash
elif [ -f /usr/groups/ecad/setup.bash ] ; then
    . /usr/groups/ecad/setup.bash
fi

# Edit these enviornmental variables for the local setup!

PATH=/usr/groups/ctsrd/local/bin:/usr/groups/ecad/mips/sde-6.06/bin:$PATH
export PATH

if [ ! -n "${QUARTUS_ROOTDIR}" ]; then
	export QUARTUS_ROOTDIR=/usr/groups/ecad/altera/current/quartus
fi
bsversion=current
if [ ! -n "${ECAD_LICENSES}" ]; then
	export ECAD_LICENSES=/usr/groups/ecad/licenses
fi
BLUESPEC_LICENSE_FILE="$ECAD_LICENSES/bluespec.lic"
if [ ! -n "${LM_LICENSE_FILE}" ]; then
	export LM_LICENSE_FILE="$LM_LICENSE_FILE:$BLUESPEC_LICENSE_FILE"
fi
if [ ! -n "${BLUESPEC}" ]; then
	export BLUESPEC=/usr/groups/ecad/bluespec/$bsversion
fi
if [ ! -n "${BLUESPECDIR}" ]; then
	export BLUESPECDIR=/usr/groups/ecad/bluespec/$bsversion/lib
fi
# avoid Qsys build collisions in /tmp on shared machines
if [ ! -n "${TEMP}" ]; then
        export TEMP=/tmp/$USER
fi
if [ ! -n "${TMP}" ]; then
        export TMP=/tmp/$USER
fi

if [ -d "$QUARTUS_ROOTDIR/bin" ] ; then
  PATH="$PATH:$QUARTUS_ROOTDIR/bin"
fi
if [ -d "$QUARTUS_ROOTDIR/sopc_builder/bin" ] ; then
  PATH="$PATH:$QUARTUS_ROOTDIR/sopc_builder/bin"
fi
if [ -d "$BLUESPEC/bin" ] ; then
  PATH="$PATH:$BLUESPEC/bin"
fi
