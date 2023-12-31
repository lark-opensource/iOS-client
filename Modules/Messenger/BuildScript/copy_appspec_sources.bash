# should run on root dir
function reset () {
    echo $'\e[32m'"$@"$'\e[0m'
    git checkout -- Lark ShareExtension NotificationServiceExtension Lark.xcodeproj
}
function sync() {
    reset "reset git state in Lark and ShareExtension for ${config}"
    ./BuildScript/XcodeEdit ./ BuildScript/config.json ${config}
    rsync -avR "${sources[@]}" Apps/${to}/
}

common_sources=(
    Lark/./Info.plist
    'Lark/Supporting Files/./Lark.entitlements'
    ShareExtension/Info.plist
    ShareExtension/ShareExtension.entitlements
    NotificationServiceExtension/Info.plist
    NotificationServiceExtension/NotificationServiceExtension.entitlements
)
function sync_inhouse () {
    sources=("${common_sources[@]}")
    config=inhouse to=Lark sync
}
function sync_inhouse_oversea () {
    sources=("${common_sources[@]}" Lark/./*.lproj)
    config=inhouse-oversea to=LarkInternational sync
}
function sync_internal () {
    sources=("${common_sources[@]}")
    config=internal to=LarkReleaseChina sync
}
function sync_international () {
    sources=("${common_sources[@]}" Lark/./*.lproj)
    config=international to=LarkReleaseInternational sync

    echo sort the output strings to ensure stable order
    find Apps/LarkReleaseInternational -name '*.strings' -exec sort '{}' -o '{}' \;
}

if (($#==0)); then
    sync_inhouse
    sync_inhouse_oversea
    sync_internal
    sync_international
else
    for i; do
        case "$i" in
            (inhouse|internal|international)
                sync_$i;;
            (inhouse_oversea|inhouse-oversea)
                sync_inhouse_oversea;;
        esac
    done
fi


reset "reset to origin"
