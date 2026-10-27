# Kernel sources

- 7.1.3
  - tag: `v7.1.3`
  - commit: `113be0295f4f632d61f4e9c93322f70e2365f54d`
  - build tag: `linux-7.1.3-kernsight-kasan-v1`
  - krelease: `7.1.3-kernsight-kasan`
- 7.2.11
  - tag: `v7.2.11`
  - commit: `8316c24ec1b77dba19ba072ca4fe251b36dc65d3`
  - release tarball sha256: `fd0fc479f983a8c05313f13e9c36330fe6651cf725396748c40d5cd93fa1e6a4`
  - krelease: `7.2.11-kernsight-kasan`
- 7.3.0
  - tag: `v7.3`
  - commit: `091b06388b117fefdcb63336ac09956a4914b961`
  - release tarball sha256: `87363c24f10e06321eb362765521094e94471f6bff8bce2d6b3e40f39f004953`
  - krelease: `7.3.0-kernsight-kasan`

For 7.2.11 and 7.3.0 the source tarball checksums were verified and only the
kernel configuration was adapted; no kernel source changes were made. No
source diff is included for 7.1.3. The KernSight changes are in the syzkaller
tree, not in the kernel.

The kernel configs used for the runs are in this directory:
`kernel-7.1.3.config`, `kernel-7.2.11.config`, `kernel-7.3.config`.
