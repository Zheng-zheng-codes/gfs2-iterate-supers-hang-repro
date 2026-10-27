# gfs2: hung task in __iterate_supers with leftover glocks during unmount

Reproduction materials for a syzkaller report:

```
INFO: task hung in __iterate_supers
```

A task in `sync()` blocks on `s_umount` in `__iterate_supers()`. The same
`s_umount` is held by a gfs2 unmount in `deactivate_super()`, which is waiting
in `gfs2_wait_glocks()` for leftover glocks. gfs2 reports

```
gfs2: fsid=syz:syz.0: 1 glocks left after 61 seconds; still waiting
gfs2: fsid=syz:syz.0: 1 glocks left after 122 seconds; still waiting
```

and the hung-task watchdog panics at 143 seconds.

## Status

- Original report: Linux 7.1.3
- Reproduced: Linux 7.2.11 (state-primed) and Linux 7.3.0
- C reproducer: not available (C conversion failed during state-primed reproduction)
- The crash was reproduced using the full 159-program sequence; the required
  subset is not yet known.
- The 7.3.0 sequence is 159 programs long and about 14 MB (embedded images)

## 7.3.0 observed sequence

- `293.585 s`: gfs2 withdraw due to an invalid metadata block in
  `gfs2_meta_buffer()`, reached from `gfs2_dirty_inode()` during
  `gfs2_create_inode()`. A failslab failure in `gfs2_glock_get()` immediately
  precedes the withdraw.
- `361.670 s`: `1 left-over quota data objects`
- `423.109 s`: `1 glocks left after 61 seconds; still waiting`
- `484.549 s`: `1 glocks left after 122 seconds; still waiting`
- `489.029 s`: hung task in `__iterate_supers()`; `s_umount` held by
  `syz-executor/12077` at `deactivate_super+0xb1/0xd0`
- `489.033 s`: `Kernel panic - not syncing: hung_task: blocked tasks`

The replayed `syz-execprog` had already returned when the hung task fired; the
unmount was still running asynchronously. A harness that stops at
`syz-execprog` exit will miss the panic.

## Reproduction

Fresh KVM guest, kernel command line in `7.3/cmdline-7.3.txt`:

```sh
scp syz-execprog syz-executor repro/repro.kernsight.prog root@guest:/tmp/
ssh root@guest
cd /tmp && chmod +x syz-execprog syz-executor
./syz-execprog -procs=1 -repeat=1 -disable=swap -executor ./syz-executor ./repro.kernsight.prog
```

Settings: `sandbox=none`, threaded executor, `procs=1`, `repeat=1`. The
programs run one at a time in file order. `repro/repro.prog` alone is not
sufficient.

The sequence contains syzkaller fault-injection annotations. In the 7.3.0 run
a failslab failure in `gfs2_glock_get()` is injected from `gfs2_create_inode()`.
No additional debugfs fault-injection configuration was used.

## Kernel sources

- 7.1.3: Linux v7.1.3, commit
  `113be0295f4f632d61f4e9c93322f70e2365f54d`, build tag
  `linux-7.1.3-kernsight-kasan-v1`. The saved tree is not a git checkout.
- 7.2.11: Linux v7.2.11, commit
  `8316c24ec1b77dba19ba072ca4fe251b36dc65d3`, release tarball sha256
  `fd0fc479f983a8c05313f13e9c36330fe6651cf725396748c40d5cd93fa1e6a4`.
- 7.3.0: mainline Linux v7.3, commit
  `091b06388b117fefdcb63336ac09956a4914b961`, release tarball sha256
  `87363c24f10e06321eb362765521094e94471f6bff8bce2d6b3e40f39f004953`.

For 7.2.11 and 7.3.0 the source tarball checksums were verified and only the
kernel configuration was adapted; no kernel source changes were made. No
source diff is included for 7.1.3. The KernSight changes are in the syzkaller
tree, not in the kernel.

## Contents

```
repro/repro.prog                  original syzkaller testcase (not sufficient alone)
repro/repro.kernsight.prog        159-program state-construction sequence
7.1.3/report0                     original 7.1.3 hung-task report
7.1.3/log0                        full 7.1.3 console log
7.1.3/machineInfo0                original machine information
7.1.3/description                 syzbot description
7.1.3/pre_state0                  captured pre-crash state vector
7.2.11/repro.report               7.2.11 state-primed reproduction report
7.2.11/repro.log                  7.2.11 reproduction console excerpt
7.2.11/repro.kernsight.prog       same 159-program sequence
7.2.11/RESULT.md                  7.2.11 reproduction summary
7.3/serial-7.3.log                full 7.3.0 console log
7.3/console-7.3.log               replay harness output
7.3/cmdline-7.3.txt               kernel command line
7.3/boot-info-7.3.txt             guest boot information
7.3/RESULT-7.3.txt                7.3.0 replay summary
kernel/kernel-7.1.3.config        kernel config for the 7.1.3 report
kernel/kernel-7.2.11.config       kernel config for the 7.2.11 replay
kernel/kernel-7.3.config          kernel config for the 7.3.0 replay
kernel/SOURCES.md                 source tags, commits and tarball checksums
verify.sh                         re-checks the numbers quoted above
MANIFEST.sha256                   sha256 of every file in this repository
```

The kernel configs match the `-kernsight-kasan` builds used for the three
kernels (KASAN/KCOV; gfs2 built in). No gfs2 source changes were made for
this testing.

## Quick check

```sh
./verify.sh
```
