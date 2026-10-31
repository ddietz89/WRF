#!/bin/bash
# Clean full-source build: HEAD 0ef11ead + pinned submodules + WRFPLUS guard fix (3 filter tokens).
set -euo pipefail
B=/pool/wrf-experiment/wrf-cpu/builds/clean-full-source-0ef11ead-wrfplusfix-r3
cd "$B"; test ! -e WRF
echo "f9416c420a150858cc1a110e7137909977462648e95ea2d4d213f049629be479  $B/wrf-clean-0ef11ead-wrfplusfix.tar.gz" | sha256sum -c -
echo "6d2d788bd02677e6b3603cf9f011b5d51ad19cc418accc773da5a713c1fb7c5c  /pool/wrf-experiment/wrf-cpu/builds/clean-head-generic-r4/configure.wrf" | sha256sum -c -
tar xzf wrf-clean-0ef11ead-wrfplusfix.tar.gz; cp /pool/wrf-experiment/wrf-cpu/builds/clean-head-generic-r4/configure.wrf WRF/
source /pool/wrf-experiment/toolchains/gnu/13.3.0/env.sh; export TMPDIR=$B/tmp; mkdir -p $TMPDIR
cd WRF; s=$(date +%s)
/pool/wrf-experiment/toolchains/bootstrap/bin/csh -f ./compile -j 16 em_real > ../compile-pass1.log 2>&1 || true
/pool/wrf-experiment/toolchains/bootstrap/bin/csh -f ./compile -j 16 em_real > ../compile-pass2.log 2>&1 || true
e=$(date +%s); cd ..
printf '{"seconds":%d,"wrf_exe":"%s","libwrflib":"%s","librsl_lite":"%s","fatal_pass2":%d}\n' $((e-s)) "$(sha256sum WRF/main/wrf.exe 2>/dev/null|cut -c1-64)" "$(sha256sum WRF/main/libwrflib.a|cut -c1-64)" "$(sha256sum WRF/external/RSL_LITE/librsl_lite.a|cut -c1-64)" "$(grep -c -E 'Fatal Error|undefined reference' compile-pass2.log || true)" > build-result.json
cat build-result.json; test -x WRF/main/wrf.exe
