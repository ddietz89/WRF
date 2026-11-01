#!/bin/bash
# Reproducible selected-configuration build r3: branch 3919078b + pinned submodules + configure overlay + tools/ helpers.
set -euo pipefail
B=/pool/wrf-experiment/wrf-cpu/builds/selected-source-3919078b-r4; R4=/pool/wrf-experiment/wrf-cpu/builds/clean-full-source-7bde78fc-tpifix-r4
cd $B; test ! -e WRF
echo "1af5a91c68a63efe6f05f72c918e924ef83185101ed5d1ba3066ff42e4ea50b7  $B/wrf-3919078b.tar.gz" | sha256sum -c -
tar xzf wrf-3919078b.tar.gz
mkdir -p r4src && tar xzf $R4/wrf-clean-7bde78fc-tpifix.tar.gz -C r4src
for s in phys/GFL phys/MYNN-EDMF phys/MYNN-SFC phys/TEMPO phys/fire_behavior phys/noahmp phys/physics_mmm; do rm -rf WRF/$s; cp -a r4src/WRF/$s WRF/$s; done; rm -rf r4src
source /pool/wrf-experiment/toolchains/gnu/13.3.0/env.sh; export TMPDIR=$B/tmp; mkdir -p $TMPDIR
H=$B/sel-helpers; mkdir -p $H; T=$B/WRF/tools
GCC=/pool/wrf-experiment/toolchains/gnu/13.3.0/bin/gcc; MPICC=/pool/wrf-experiment/toolchains/gnu/13.3.0/mpi-ucx-xpmem/bin/mpicc; MPIF90=/pool/wrf-experiment/toolchains/gnu/13.3.0/mpi-ucx-xpmem/bin/mpif90
$GCC -O2 -mavx2 -mno-fma -fno-fast-math -ffp-contract=off -std=c11 -c $T/cpu-compute/hpg-nhx-isolated-avx2-consumer/wrf_hpg_nhx_consume_avx2.c -o $H/nhx-helper-O2.o
$GCC -O2 -std=c11 -mavx2 -mno-fma -fno-fast-math -ffp-contract=off -frounding-math -DWRF_PHY_HEIGHT_PARENT_O2=1 -c $T/cpu-compute/phy-height-private-avx2-fixed8/phy_height_row_legacy.c -o $H/phy-height-helper-O2.o
TS=$T/cpu-memory/thompson-table-sharing
(cd $H && $MPIF90 -O2 -fno-fast-math -ffp-contract=off -w -fno-fast-math -ffp-contract=off -ffree-form -ffree-line-length-none -fconvert=big-endian -frecord-marker=4 -fallow-argument-mismatch -fallow-invalid-boz -g -c $TS/shared_table_iso.f90 -o $H/shared_table_iso.o)
$MPICC -std=c11 -O2 -Wall -Wextra -Werror -fno-fast-math -ffp-contract=off -I$TS -c $TS/shared_table.c -o $H/shared_table.o
$MPICC -std=c11 -O2 -Wall -Wextra -Werror -fno-fast-math -ffp-contract=off -I$TS -c $TS/thompson_tpi_bridge.c -o $H/thompson_tpi_bridge.o
cp $H/shared_table_iso.mod WRF/phys/
sha256sum $H/*.o > helpers.sha256
sed 's|^FC              =       time $(DM_FC)|FC              =       $(DM_FC)|' /pool/wrf-experiment/wrf-cpu/builds/clean-head-generic-r4/configure.wrf > WRF/configure.wrf
sed "s|@SEL_HELPERS@|$H|" $B/overlay.wrf >> WRF/configure.wrf
cd WRF; s=$(date +%s)
/pool/wrf-experiment/toolchains/bootstrap/bin/csh -f ./compile -j 32 em_real > ../compile-pass1.log 2>&1 || true
cp $H/shared_table_iso.mod phys/ 2>/dev/null || true
/pool/wrf-experiment/toolchains/bootstrap/bin/csh -f ./compile -j 32 em_real > ../compile-pass2.log 2>&1 || true
e=$(date +%s); cd ..
printf '{"seconds":%d,"wrf_exe":"%s","libwrflib":"%s","librsl_lite":"%s","fatal_pass2":%d}\n' $((e-s)) "$(sha256sum WRF/main/wrf.exe 2>/dev/null|cut -c1-64)" "$(sha256sum WRF/main/libwrflib.a|cut -c1-64)" "$(sha256sum WRF/external/RSL_LITE/librsl_lite.a|cut -c1-64)" "$(grep -c -E 'Fatal Error|undefined reference' compile-pass2.log || true)" > build-result.json
cat build-result.json
