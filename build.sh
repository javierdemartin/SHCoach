# Javier de Martín Gil
#
# 

BUILD_SCHEME="SHCoachFramework"

WORKING_DIR=$HOME

FRAMEWORK_NAME="SHCoachFramework"

echo $WORKING_DIR

SIMULATOR_ARCHIVE_PATH="${WORKING_DIR}/${BUILD_SCHEME}-iphonesimulator.xcarchive"
IOS_ARCHIVE_PATH="${WORKING_DIR}/${BUILD_SCHEME}-ios.xcarchive"
CATALYST_ARCHIVE_PATH="${WORKING_DIR}/${BUILD_SCHEME}-catalyst.xcarchive"

SIMULATOR_FRAMEWORK_PATH="${SIMULATOR_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
IOS_FRAMEWORK_PATH="${IOS_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
CATALYST_FRAMEWORK_PATH="${CATALYST_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"

OUTPUT_PATH="${WORKING_DIR}/${FRAMEWORK_NAME}.xcframework"

rm -rf ${OUTPUT_PATH}

xcodebuild archive \
	-quiet \
	clean \
	-scheme ${BUILD_SCHEME}  \
	-archivePath ${SIMULATOR_ARCHIVE_PATH} \
	-sdk iphonesimulator \
	-destination="generic/platform=iOS Simulator" \
	SKIP_INSTALL=NO \
	ENABLE_BITCODE=YES \
	BUILD_LIBRARIES_FOR_DISTRIBUTION=YES 

xcodebuild archive \
	-quiet \
	clean \
	-scheme ${BUILD_SCHEME}  \
	-archivePath ${IOS_ARCHIVE_PATH} \
	-sdk iphoneos \
	-destination="generic/platform=iOS" \
	BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
	SKIP_INSTALL=NO \
	ENABLE_BITCODE=YES
	
xcodebuild archive \
	-quiet \
	clean \
	-scheme ${BUILD_SCHEME}  \
	-archivePath ${CATALYST_ARCHIVE_PATH} \
	-sdk macosx12.0 \
	-destination="platform=macOS,variant=Mac Catalyst" \
	BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
	SKIP_INSTALL=NO \
	ENABLE_BITCODE=YES \
	SUPPORTS_MACCATALYST=YES
	
echo "================================="

# List out with lipo all the available architectures in the exported xcarchive

lipo -info ${SIMULATOR_FRAMEWORK_PATH}/${FRAMEWORK_NAME}
lipo -info ${IOS_FRAMEWORK_PATH}/${FRAMEWORK_NAME}
lipo -info ${CATALYST_FRAMEWORK_PATH}/${FRAMEWORK_NAME}
	
# XCFramework creation

xcodebuild -create-xcframework \
    -framework ${SIMULATOR_FRAMEWORK_PATH} \
    -framework ${IOS_FRAMEWORK_PATH} \
    -framework ${CATALYST_FRAMEWORK_PATH} \
    -output ${OUTPUT_PATH}

rm -rf ${SIMULATOR_ARCHIVE_PATH}
rm -rf ${IOS_ARCHIVE_PATH}
rm -rf ${CATALYST_ARCHIVE_PATH}