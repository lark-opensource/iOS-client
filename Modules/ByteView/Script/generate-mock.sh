#!/bin/bash

BASEDIR=$(dirname "$0")/..
OUTPUT_FILE="${BASEDIR}/Modules/ByteView/Tests/Mock/"
echo "Generated Mock File = $OUTPUT_FILE"

if [ $# -eq 0 ]; then 
	INPUT_FILES=(
		"RequiredServices.swift"
		"CalendarService.swift"
		"ClientMutexService.swift"
		"FeedbackService.swift"
		"FloatingManipulator.swift"
		"GroupService.swift"
		"InviteService.swift"
		"KMPlaceholderTextView.swift"
		"MeetService.swift"
		"MutexService.swift"
		"NTPTimeService.swift"
		"MeetManipulator.swift"
		"SceneCoordinatorType.swift"
		"SceneManipulator.swift"
		"SearchService.swift"
		"ShareService.swift"
		"TrackDefines.swift"
		"UserService.swift"
		"RoomService.swift"
		"VideoConferenceService.swift"
		"TrackDispatcher.swift"
		"MeetingInfoService.swift"
		"VideoChatService.swift"
		"TerminationMonitor.swift"
		"I18nService.swift"
		"ActiveSpeakerService.swift"
		"DataManipulatorType.swift"
  		"VariableFeatureSwitchService.swift"
		)
else
	INPUT_FILES=( "$@" )
fi
INPUT_FILES_STRING=""
for FILE_NAME in "${INPUT_FILES[@]}"
do
    INPUT_FILE=`find ${BASEDIR}/Modules/ByteView/src -name "$FILE_NAME" | head -1`
    if [ ! -z "$INPUT_FILE" ]; then
        if [ -z "$INPUT_FILES_STRING" ]; then
            INPUT_FILES_STRING="${INPUT_FILE}"
        else
            INPUT_FILES_STRING="${INPUT_FILES_STRING} ${INPUT_FILE}"
        fi
    fi
done

${INPUT_FILES_STRING}
"${BASEDIR}/Example/Pods/Cuckoo/run" generate --debug --no-class-mocking --no-timestamp --testable "ByteView" --output "${OUTPUT_FILE}" \
    ${INPUT_FILES_STRING}


