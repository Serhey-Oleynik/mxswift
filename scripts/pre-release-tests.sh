
IS_LOCAL=0
IS_QUICK=1
if [ "$1" == "l" ]; then
	echo "Local test"
	IS_LOCAL=1
fi

if [ "$1" == "f" ]; then
	echo "Full"
	IS_QUICK=0
else
	echo "Quick"
fi

ISLOCAL="${IS_LOCAL}" . scripts/common.sh
TV_OS=0

# ios 7 sim
#if [ `xcrun simctl list | grep "${DEFAULT_IOS7_SIMULATOR}" | wc -l` == 0 ]; then
#	xcrun simctl create $DEFAULT_IOS7_SIMULATOR 'iPhone 4s' 'com.apple.CoreSimulator.SimRuntime.iOS-7-1'
#else
#	echo "${DEFAULT_IOS7_SIMULATOR} exists"
#fi

#ios 8 sim
#if [ `xcrun simctl list | grep "${DEFAULT_IOS8_SIMULATOR}" | wc -l` == 0 ]; then
#	xcrun simctl create $DEFAULT_IOS8_SIMULATOR 'iPhone 6' 'com.apple.CoreSimulator.SimRuntime.iOS-8-4'
#else
#	echo "${DEFAULT_IOS8_SIMULATOR} exists"
#fi

if [ "${IS_LOCAL}" -eq 1 ]; then
	. scripts/automation-tests.sh
fi

if [ `xcodebuild -showsdks | grep tvOS | wc -l` -ge 4 ]; then
	printf "${GREEN}tvOS found${RESET}\n"
	TV_OS=1
fi

#ios 9 sim
if simulator_available "${DEFAULT_IOS9_SIMULATOR}"; then
	echo "${DEFAULT_IOS9_SIMULATOR} exists"
else
		xcrun simctl create "${DEFAULT_IOS9_SIMULATOR}" 'iPhone 6' "${DEFAULT_IOS_SIMULATOR_RUNTIME}"
fi

#watch os 2 sim
if simulator_available "${DEFAULT_WATCHOS2_SIMULATOR}"; then
	echo "${DEFAULT_WATCHOS2_SIMULATOR} exists"
else
	xcrun simctl create "${DEFAULT_WATCHOS2_SIMULATOR}" 'Apple Watch - 38mm' 'com.apple.CoreSimulator.SimRuntime.watchOS-2-0'
fi

#watch os 2 sim
if [ "${TV_OS}" -eq 1 ]; then
	if simulator_available "${DEFAULT_TVOS_SIMULATOR}"; then
		echo "${DEFAULT_TVOS_SIMULATOR} exists"
	else
		xcrun simctl create $DEFAULT_TVOS_SIMULATOR 'Apple TV 1080p' 'com.apple.CoreSimulator.SimRuntime.tvOS-9-0'
	fi
fi

if [ "${IS_QUICK}" -eq 1 ]; then
	CONFIGURATIONS=(Release)
else
	CONFIGURATIONS=(Debug Release-Tests Release)
fi

# make sure watchos builds
# temporary solution
WATCH_OS_BUILD_TARGETS=(RxSwift-watchOS RxCocoa-watchOS RxBlocking-watchOS)
for scheme in ${WATCH_OS_BUILD_TARGETS[@]}
do
	for configuration in ${CONFIGURATIONS[@]}
	do
		echo
		printf "${GREEN}${build} ${BOLDCYAN}${scheme} - ${configuration}${RESET}\n"
		echo
		xcodebuild -workspace Rx.xcworkspace \
					-scheme ${scheme} \
					-configuration ${configuration} \
					-derivedDataPath "${BUILD_DIRECTORY}" \
					build | xcpretty -c; STATUS=${PIPESTATUS[0]}

		if [ $STATUS -ne 0 ]; then
			echo $STATUS
	 		exit $STATUS
		fi
	done
done

#make sure all iOS tests pass
for configuration in ${CONFIGURATIONS[@]}
do
	rx "RxTests-iOS" ${configuration} $DEFAULT_IOS9_SIMULATOR test
done

#make sure all tvOS tests pass
if [ $TV_OS -eq 1 ]; then
	for configuration in ${CONFIGURATIONS[@]}
	do
		rx "RxTests-tvOS" ${configuration} $DEFAULT_TVOS_SIMULATOR test
	done
fi

#make sure all watchOS tests pass
#tests for Watch OS are not available rdar://21760513
# for configuration in ${CONFIGURATIONS[@]}
# do
# 	rx "RxTests-watchOS" ${configuration} $DEFAULT_WATCHOS2_SIMULATOR test
# done

#make sure all OSX tests pass
for configuration in ${CONFIGURATIONS[@]}
do
	rx "RxTests-OSX" ${configuration} "" test
done

# make sure no module can be built
for scheme in "RxExample-iOS-no-module"
do
	for configuration in ${CONFIGURATIONS[@]}
	do
		#rx ${scheme} ${configuration} $DEFAULT_IOS7_SIMULATOR build
		#rx ${scheme} ${configuration} $DEFAULT_IOS8_SIMULATOR build
		rx ${scheme} ${configuration} $DEFAULT_IOS9_SIMULATOR build
	done
done

# make sure with modules can be built
for scheme in "RxExample-iOS"
do
	for configuration in ${CONFIGURATIONS[@]}
	do
	rx ${scheme} ${configuration} $DEFAULT_IOS9_SIMULATOR build
	done
done

# make sure osx builds
for scheme in "RxExample-OSX"
do
	for configuration in ${CONFIGURATIONS[@]}
	do
		rx ${scheme} ${configuration} "" build
	done
done

if [ "${IS_LOCAL}" -eq 1 ]; then
	mdast -u mdast-slug -u mdast-validate-links ./*.md
	mdast -u mdast-slug -u mdast-validate-links ./**/*.md
fi
