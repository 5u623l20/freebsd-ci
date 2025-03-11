#!/bin/sh

set -ex

if [ -n "${CROSS_TOOLCHAIN}" ]; then
	CROSS_TOOLCHAIN_PARAM=CROSS_TOOLCHAIN=${CROSS_TOOLCHAIN}
fi

MAKECONF=${MAKECONF:-/dev/null}
MAKECONF_AMD=${MAKECONF_AMD:-/dev/null}
MAKECONF_INTEL=${MAKECONF_INTEL:-/dev/null}
SRCCONF=${SRCCONF:-/dev/null}
FBSD_BRANCH=${FBSD_BRANCH:-main}
JFLAG=${JFLAG:-12}
TARGET=${TARGET:-amd64}
TARGET_ARCH=${TARGET_ARCH:-amd64}
ARTIFACT=${WORKSPACE}/diff.html
ARTIFACT_DEST=artifact/reproducibility/${FBSD_BRANCH}/${TARGET}/${TARGET_ARCH}/${GIT_COMMIT}-${TESTTYPE}.html
export TESTTYPE=${TESTTYPE:-timestamp}
# Set SOURCE_DATE_EPOCH to today at 00:00:00 UTC
export SOURCE_DATE_EPOCH=$(date -u -j -f "%Y-%m-%d %H:%M:%S" "$(date -u +%Y-%m-%d) 00:00:00" +%s)

if [ ${TESTTYPE} = "timestamp" ]; then
	echo $SOURCE_DATE_EPOCH
	export MAKEOBJDIRPREFIX=${WORKSPACE}/obj1
	rm -fr ${MAKEOBJDIRPREFIX}
	cd /usr/src
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
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
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	diffoscope --html ${WORKSPACE}/diff.html ${WORKSPACE}/obj1 ${WORKSPACE}/obj2
elif [ ${TESTTYPE} = "arch" ]; then
	echo $SOURCE_DATE_EPOCH
	export MAKEOBJDIRPREFIX=${WORKSPACE}/objamd
	rm -fr ${MAKEOBJDIRPREFIX}
	cd /usr/src
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF_AMD} \
		SRCCONF=${SRCCONF}
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF_AMD} \
		SRCCONF=${SRCCONF}
	export MAKEOBJDIRPREFIX=${WORKSPACE}/objintel
	rm -fr ${MAKEOBJDIRPREFIX}
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF_INTEL} \
		SRCCONF=${SRCCONF}
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF_INTEL} \
		SRCCONF=${SRCCONF}
	diffoscope --html ${WORKSPACE}/diff.html ${WORKSPACE}/objamd ${WORKSPACE}/objintel
elif [ ${TESTTYPE} = "path" ]; then
	cp -Rp /usr/src ${WORKSPACE}/src1
	cp -Rp /usr/src ${WORKSPACE}/src2
	echo $SOURCE_DATE_EPOCH
	export MAKEOBJDIRPREFIX=${WORKSPACE}/objpath1
	rm -fr ${MAKEOBJDIRPREFIX}
	cd ${WORKSPACE}/src1
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	export MAKEOBJDIRPREFIX=${WORKSPACE}/objpath2
	rm -fr ${MAKEOBJDIRPREFIX}
	cd ${WORKSPACE}/src2
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	diffoscope --html ${WORKSPACE}/diff.html ${WORKSPACE}/objpath1 ${WORKSPACE}/objpath2
elif [ ${TESTTYPE} = "parallel" ]; then
	echo $SOURCE_DATE_EPOCH
	export MAKEOBJDIRPREFIX=${WORKSPACE}/objjx
	rm -fr ${MAKEOBJDIRPREFIX}
	cd /usr/src
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	export MAKEOBJDIRPREFIX=${WORKSPACE}/objj1
	rm -fr ${MAKEOBJDIRPREFIX}
	export JFLAG=1
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	diffoscope --html ${WORKSPACE}/diff.html ${WORKSPACE}/objj1 ${WORKSPACE}/objjx
elif [ ${TESTTYPE} = "locale" ]; then
	echo $SOURCE_DATE_EPOCH
	export MAKEOBJDIRPREFIX=${WORKSPACE}/objlocalec
	rm -fr ${MAKEOBJDIRPREFIX}
	cd /usr/src
	export LC_ALL=C
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	export MAKEOBJDIRPREFIX=${WORKSPACE}/objlocalefr
	rm -fr ${MAKEOBJDIRPREFIX}
	export LC_ALL=fr_FR.UTF-8
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	diffoscope --html ${WORKSPACE}/diff.html ${WORKSPACE}/objlocalec ${WORKSPACE}/objlocalefr
elif [ ${TESTTYPE} = "kernconf" ]; then
	echo $SOURCE_DATE_EPOCH
	export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
	rm -fr ${MAKEOBJDIRPREFIX}
	cd /usr/src
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo -E make -j ${JFLAG} -DNO_CLEAN WITH_REPRODUCIBLE_BUILD=yes \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		KERNCONF=GENERIC-NODEBUG \
		SRCCONF=${SRCCONF}
	diffoscope --html ${WORKSPACE}/diff.html ${WORKSPACE}/obj/usr/src/amd64.amd64/sys/GENERIC ${WORKSPACE}/obj/usr/src/amd64.amd64/sys/GENERIC-NODEBUG
fi
# #	Variable	Purpose	How to Test It in CI
# 5	Kernel Config (KERNCONF)	Ensures kernel builds don’t embed unintended
# metadata.	Build with GENERIC vs. a modified kernel config.
# 6	Compiler Version (clang)	Detects non-deterministic behavior across
# compiler versions.	Build with Clang 13 vs. Clang 16.
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
