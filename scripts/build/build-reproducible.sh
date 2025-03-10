#!/bin/sh

set -ex

if [ -n "${CROSS_TOOLCHAIN}" ]; then
	CROSS_TOOLCHAIN_PARAM=CROSS_TOOLCHAIN=${CROSS_TOOLCHAIN}
fi

MAKECONF=${MAKECONF:-/dev/null}
SRCCONF=${SRCCONF:-/dev/null}
FBSD_BRANCH=${FBSD_BRANCH:-main}
JFLAG=${JFLAG:-12}
TARGET=${TARGET:-amd64}
TARGET_ARCH=${TARGET_ARCH:-amd64}
ARTIFACT=${WORKSPACE}/diff.html
ARTIFACT_DEST=artifact/reproducibility/${FBSD_BRANCH}/${TARGET}/${TARGET_ARCH}/${GIT_COMMIT}-${TESTTYPE}.html
export TESTTYPE=${TESTTYPE:-timestamp}

if [ ${TESTTYPE} = "timestamp" ]; then
	# Set SOURCE_DATE_EPOCH to today at 00:00:00 UTC
	export SOURCE_DATE_EPOCH=$(date -u -j -f "%Y-%m-%d %H:%M:%S" "$(date -u +%Y-%m-%d) 00:00:00" +%s)
	echo $SOURCE_DATE_EPOCH
	export MAKEOBJDIRPREFIX=${WORKSPACE}/obj1
	rm -fr ${MAKEOBJDIRPREFIX}
	sudo make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	# One year from today's date at 00:00:00 UTC
	export SOURCE_DATE_EPOCH=$(date -u -j -v+1y -f "%Y-%m-%d %H:%M:%S" "$(date -u +%Y-%m-%d) 00:00:00" +%s)
	echo $SOURCE_DATE_EPOCH
	export MAKEOBJDIRPREFIX=${WORKSPACE}/obj2
	rm -fr ${MAKEOBJDIRPREFIX}
	sudo make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	diffoscope --html ${WORKSPACE}/diff.html ${WORKSPACE}/obj1 ${WORKSPACE}/obj2
fi
# #	Variable	Purpose	How to Test It in CI
# 2	CPU Type (-march flags)	Detects CPU-specific optimizations.	Build on AMD
# vs. Intel vs. ARM64.
# 3	Build Path (PWD)	Catches absolute path issues in binaries.	Build in
# /build1/ and /build2/ and compare.
# 4	Parallelism (make -j)	Detects race conditions in parallel builds.	Build
# with -j1 vs. -j8 and compare results.
# 5	Kernel Config (KERNCONF)	Ensures kernel builds don’t embed unintended
# metadata.	Build with GENERIC vs. a modified kernel config.
# 6	Compiler Version (clang)	Detects non-deterministic behavior across
# compiler versions.	Build with Clang 13 vs. Clang 16.
# 7	Locale (LC_ALL)	Catches string sorting inconsistencies.	Build with LC_ALL=C
# vs. LC_ALL=fr_FR.UTF-8.
# 8	Filesystem (UFS vs. ZFS)	Ensures FS-specific metadata doesn’t affect
# reproducibility.	Build on both UFS and ZFS and compare.
# 9	User (UID/GID)	Ensures builds don’t embed UID/GID metadata.	Build as
# root and as a non-root user.
# 10	Linking (static vs. dynamic)	Ensures symbol tables are consistently
# ordered.	Build with different linkers and compare ELF headers.
#
#
sudo mkdir -p ${ARTIFACT_DEST}
sudo mv ${ARTIFACT} ${ARTIFACT_DEST}

echo "${GIT_COMMIT}" | sudo tee ${ARTIFACT_DEST}/revision.txt

echo "USE_GIT_COMMIT=${GIT_COMMIT}" > ${WORKSPACE}/trigger.property
