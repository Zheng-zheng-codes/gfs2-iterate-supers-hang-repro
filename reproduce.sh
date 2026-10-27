#!/bin/sh
# Run this inside the guest, after copying syz-execprog, syz-executor,
# repro/repro.kernsight.prog and repro/repro.prog to the same directory tree.
set -e
cd "$(dirname "$0")"

for f in syz-execprog syz-executor repro/repro.kernsight.prog repro/repro.prog; do
	if [ ! -f "$f" ]; then
		echo "missing: $f" >&2
		exit 1
	fi
done

echo "step 1/2: state construction (159 programs)"
./syz-execprog -procs=1 -repeat=1 -disable=swap \
	-executor ./syz-executor ./repro/repro.kernsight.prog

echo "step 2/2: crashing testcase"
./syz-execprog -procs=1 -repeat=1 -disable=swap \
	-executor ./syz-executor ./repro/repro.prog

echo "Both commands returned. Keep the VM running: the hung-task panic can"
echo "appear after this point."
