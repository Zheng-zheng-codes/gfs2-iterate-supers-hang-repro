#!/usr/bin/env bash
# Re-check the numbers quoted in the report and the repository README.
set -u

cd "$(dirname "$0")" || exit 1

fail=0

check() {
	local desc="$1" file="$2" pattern="$3"
	if grep -aqF -- "$pattern" "$file"; then
		printf 'ok   %s\n' "$desc"
	else
		printf 'FAIL %s (missing in %s: %s)\n' "$desc" "$file" "$pattern"
		fail=1
	fi
}

check_count() {
	local desc="$1" file="$2" pattern="$3" expected="$4"
	local got
	got=$(grep -acF -- "$pattern" "$file" 2>/dev/null || true)
	if [ "$got" = "$expected" ]; then
		printf 'ok   %s (%s)\n' "$desc" "$got"
	else
		printf 'FAIL %s (expected %s, got %s)\n' "$desc" "$expected" "$got"
		fail=1
	fi
}

check_count "159 programs in 7.3.0 sequence" repro/repro.kernsight.prog "executing program " 159
check_count "one hung-task line in 7.3.0 serial log" 7.3/serial-7.3.log "INFO: task " 1

check "7.3.0 sync stack" 7.3/serial-7.3.log "__iterate_supers+0x377/0x460"
check "7.3.0 s_umount held by unmount" 7.3/serial-7.3.log "at: deactivate_super+0xb1/0xd0"
check "7.3.0 61-second glock message" 7.3/serial-7.3.log "1 glocks left after 61 seconds; still waiting"
check "7.3.0 122-second glock message" 7.3/serial-7.3.log "1 glocks left after 122 seconds; still waiting"
check "7.3.0 quota leftover message" 7.3/serial-7.3.log "1 left-over quota data objects"
check "7.3.0 gfs2 withdraw" 7.3/serial-7.3.log "about to withdraw this file system"
check "7.3.0 hung-task panic" 7.3/serial-7.3.log "Kernel panic - not syncing: hung_task: blocked tasks"

check "7.2.11 hung task" 7.2.11/repro.report "blocked for more than 142 seconds"
check "7.2.11 sync stack" 7.2.11/repro.report "__iterate_supers+0x377/0x460"
check "7.2.11 s_umount held by unmount" 7.2.11/repro.report "at: deactivate_super+0xae/0xd0"

check "7.1.3 hung task" 7.1.3/report0 "INFO: task syz.7.2306:58274 blocked for more than 143 seconds."
check "7.1.3 sync stack" 7.1.3/report0 "__iterate_supers+0x1e6/0x340"
check "7.1.3 491-second glock message" 7.1.3/log0 "2 glocks left after 491 seconds; still waiting"

for cfg in kernel/kernel-7.1.3.config kernel/kernel-7.2.11.config kernel/kernel-7.3.config; do
	check "$cfg exists" "$cfg" "CONFIG_GFS2_FS=y"
	check "$cfg KASAN" "$cfg" "CONFIG_KASAN=y"
	check "$cfg failslab" "$cfg" "CONFIG_FAILSLAB=y"
done

check "7.1.3 source commit" kernel/SOURCES.md "113be0295f4f632d61f4e9c93322f70e2365f54d"
check "7.2.11 source commit" kernel/SOURCES.md "8316c24ec1b77dba19ba072ca4fe251b36dc65d3"
check "7.3.0 source commit" kernel/SOURCES.md "091b06388b117fefdcb63336ac09956a4914b961"

check "reproduce.sh step 1" reproduce.sh "step 1/2: state construction"
check "reproduce.sh step 2" reproduce.sh "step 2/2: crashing testcase"

if [ -f MANIFEST.sha256 ]; then
	if sha256sum -c MANIFEST.sha256 >/dev/null 2>&1; then
		printf 'ok   MANIFEST.sha256\n'
	else
		printf 'FAIL MANIFEST.sha256\n'
		fail=1
	fi
else
	printf 'FAIL MANIFEST.sha256 missing\n'
	fail=1
fi

if [ "$fail" -ne 0 ]; then
	printf '\nFAILED\n'
	exit 1
fi
printf '\nPASS\n'
