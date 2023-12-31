
#!/bin/sh

#  Iconizer.sh
#  https://github.com/home-assistant/Iconic
#
#  Script in charge of executing SwiftGen, passing the icon font file path, the enum name and the custom stencil as arguments.
#

# The optional font file path passed as arg
INPUT_PATH=$1

# The optional custom name to use instead of deriving one via file name
CUSTOM_NAME=$2

# The root path for the generated files
OUTPUT_PATH=`dirname $0`

# The font catalog output path
CATALOG_PATH=${OUTPUT_PATH}/Catalog

# The path of custom Iconic stencil
STENCIL_PATH=${OUTPUT_PATH}/iconic-default.stencil

# The path of SwiftGen exec
EXEC_PATH=${OUTPUT_PATH}/swiftgen/bin/swiftgen


function getFileTitle()
{
    # Input variables
    FILE_NAME=$1

    # Removes the file extension
    name="${FILE_NAME%.*}"

    # Splits and removes all substrings with the separator characters in the file name
    # like whitespaces, dash, underscore, etc.
    title="${name%%[" -_–"]*}"

    # Specially, we want to strip the string starting from the word "Icon", and append it manually,
    # so a string like 'MaterialIconsFont' would look like 'MaterialIcon'.
    title="${title%%"icon"*}"
    title="${title%%"Icon"*}Icon"

    # Upper case the first character
    title="$(tr '[:lower:]' '[:upper:]' <<< ${title:0:1})${title:1}"

    echo "${title}"
}

function iconize()
{
    # Input variables
    FONT_PATH=$1
    FONT_NAME=$2
    OUTPUT_NAME=$3

    echo "Iconizer: Generating API name '${OUTPUT_NAME}'"

    # Creates the output folder (no error if existing)
    mkdir -p ${OUTPUT_PATH}/

    # Executes Swiftgen with a custom stencil template
    ${EXEC_PATH} icons ${FONT_PATH} --templatePath ${STENCIL_PATH} --output ${OUTPUT_PATH}/${OUTPUT_NAME}.swift --enumName ${OUTPUT_NAME}
    #${EXEC_PATH} xcassets ${FONT_PATH} --templatePath ${STENCIL_PATH} --output ${OUTPUT_PATH}/${OUTPUT_NAME}.swift --param enumName=${OUTPUT_NAME}

    # # Moves and renames the JSON output to the HTML directory
    # mv ${OUTPUT_PATH}/${OUTPUT_NAME}.json ${CATALOG_PATH}/data.json
    # echo "Iconizer: Moving catalog's json to '${CATALOG_PATH}/data.json'"

    # # Copies the font file to the HTML directory
    # cp -r ${FONT_PATH} ${CATALOG_PATH}/${FONT_NAME}
    # echo "Iconizer: Moving catalog's font to '${CATALOG_PATH}/${FONT_NAME}'"
    rm -f ${OUTPUT_PATH}/${OUTPUT_NAME}.json
    echo "Iconizer: Removing catalog's json"
}

function init()
{
    # Input variables
    FONT_PATH=$1
    CUSTOM_NAME=$2

    echo "Iconizer: Initializing with font at path '${FONT_PATH}'"

    # Input's file name and extension
    FONT_NAME=$(basename "${FONT_PATH}")
    INPUT_EXTENSION="${FONT_NAME##*.}"

    if [ -z "$CUSTOM_NAME" ]; then
      # Capitalized first word of the file name, with the 'Icon' suffix.
      # ie: FontAwesomeIcon out of a string like 'FontAwesome'
      CUSTOM_NAME=$( getFileTitle "${FONT_NAME}" )
    fi

    CUSTOM_NAME='Icon'

    echo "Iconizer: Processing file '${FONT_NAME}' with extension '${INPUT_EXTENSION}'"

    # Only TTF and OTF are supported font files
    if [ ${INPUT_EXTENSION} = 'ttf' ] || [ ${INPUT_EXTENSION} = 'otf' ]; then
        iconize ${FONT_PATH} ${FONT_NAME} ${CUSTOM_NAME}
    else
        echo "Iconizer: Unsupported '${INPUT_EXTENSION}' file. Please provide a TTF or OTF file path."
    fi
}


# Handle missing file path
if [ -z ${INPUT_PATH} ]; then
    # echo "Iconizer: No font file was found at path '${INPUT_PATH}'. Using FontAwesome as default font."

    # # Uses FontAwesome as default
    # init '${OUTPUT_PATH}/Fonts/FontAwesome/FontAwesome.otf'

    echo "Iconizer: No font file was found at path '${INPUT_PATH}'."
elif [ -z ${CUSTOM_NAME} ]; then
    init ${INPUT_PATH}
else
    init ${INPUT_PATH} ${CUSTOM_NAME}
fi
