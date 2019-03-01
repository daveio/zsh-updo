#!/usr/bin/env zsh
# https://github.com/daveio/zsh-updo
# vim:ai:ff=unix:fenc=utf-8:ts=2:et:nu:wrap

UPDO_BINARY_URL="https://transfer.sh/uY6rL/updo"
UPDO_PLUGIN_PATH="$(dirname "${0}")"
UPDO_BINARY_PATH="$(dirname "${0}")/bin"
UPDO_PATH_SETUP_HAS_RUN=0

_updo_path_setup() {
  if [[ ${UPDO_PATH_SETUP_HAS_RUN} -eq 0 ]]; then
    export PATH="${PATH}:${UPDO_BINARY_PATH}"
    UPDO_PATH_SETUP_HAS_RUN=1
  fi
}

_updo_ci_test () {
  echo "inside ci test function with ${#} args, first arg ${1}"
}

_updo_check () {
  if command -v updo >/dev/null 2>&1; then
    if [[ $(updo hello) == *"daveio/updo"* ]]; then
      # no install necessary
      return 0
    else
      # install necessary, but there's a name clash
      return 253
    fi
  else
    # install necessary, and there's no clash
    return 254
  fi
}

_updo_install () {
  if [[ ${UPDO_WAS_INSTALLED} -ne 1 ]]; then
    if [[ ! -d ${UPDO_BINARY_PATH} ]]; then
      mkdir -p ${UPDO_BINARY_PATH}
    fi
    curl -L -o "${UPDO_BINARY_PATH}/updo" "${UPDO_BINARY_URL}"
    chmod +x "${UPDO_BINARY_PATH}/updo"
    touch ${UPDO_PLUGIN_PATH}/_updo-was-installed
  fi
}

if [[ -f "${UPDO_PLUGIN_PATH}/_updo-was-installed" ]]; then
  UPDO_WAS_INSTALLED=1
  _updo_path_setup
else
  UPDO_WAS_INSTALLED=0
fi

_updo_check
UPDO_STATUS=$?

if [[ $UPDO_STATUS -eq 0 ]]; then
  # updo is installed and available, we don't need to do anything yet
  echo "updo is installed and available, we don't need to do anything yet"
  true
elif [[ $UPDO_STATUS -eq 253 ]]; then
  if [[ -z $UPDO_SILENCE_CLASH_WARNING ]]; then
    # we need to install updo and there's a clash
    _updo_install
    _updo_path_setup
    echo "updo has been installed to ${UPDO_BINARY_PATH}"
    echo "but there is another command with the same name available in"
    echo "your shell. You may need to intervene by modifying your shell's"
    echo "PATH variable manually."
    echo -n "Your PATH is currently set to"
    echo " ${PATH}"
    echo "To silence this warning, set UPDO_SILENCE_CLASH_WARNING to any"
    echo "non-empty value."
    true
  fi
elif [[ $UPDO_STATUS -eq 254 ]]; then
  # we need to install updo but there's no clash
  _updo_install
  _updo_path_setup
  true
else
  # something went seriously wrong
  echo "updo setup failed"
  exit 1
fi

# updo is now installed and the PATH set up
