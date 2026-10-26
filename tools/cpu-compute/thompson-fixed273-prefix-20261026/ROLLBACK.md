# Rollback

With experiment jobs closed, restore the Thompson source and coupled working selection from commit `3da0bc00a034977dd5aac8c35242d06c732fb984`, then commit that working-branch rollback. Restore both `phys/module_mp_thompson.F` and `tools/cpu-working/` together. The source-only inverse is preserved in INVERSE.diff.

The retained parent image is `/pool/wrf-experiment/wrf-cpu/builds/current0b40-rkscalar-row-one-em-member-experimental-r1/wrf.exe`, SHA256 `4b87b01053f074ae6381824309f6649b1b53efdf6161ae7fbb6df997ba2bd18b`; archive SHA256 `021af719497d01a66ddad2c835e3684132828e50b6f6375e80fc885f294e657e`. It retains all earlier improvements and its own three-/nine-hour checks. Use the original resource, input, runtime and cache acceptance before launching. Preserve evidence files. Production and master are outside this rollback.
