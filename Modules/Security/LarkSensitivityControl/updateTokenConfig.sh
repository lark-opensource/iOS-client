    function download_token() {
        url=$1
        name=$2
        
        # download token file
        curl --location --request POST $url --header 'Content-Type: application/json' --data-raw '{"terminal_type":4}' --output "./${name}.json"

        # get code value
        result=$(cat ${name}.json | python3 -c "import sys, json; print(json.load(sys.stdin)['code'])")

        if [ ${result} == 0 ]
        then
            # zip token file
            if [[ ! -d "../Modules/Security/LarkSensitivityControl/resources" ]]; then
              mkdir -p "../Modules/Security/LarkSensitivityControl/resources"
              echo "create resources folder"
            fi

            zip -m "../Modules/Security/LarkSensitivityControl/resources/${name}.zip" "./${name}.json"
            echo "zip tokenConfig & delete json data"
        else
            # delete token file
            rm -f "${name}.json"
            echo "delete json data"
        fi
    }
    download_token https://thrones.bytedance.net/api/module/compliance/api_control/token/config_list_v2 token_config_list
