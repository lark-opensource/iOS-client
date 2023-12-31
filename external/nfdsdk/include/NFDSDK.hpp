#pragma once





extern "C" {


// define basic types
typedef enum NFDScanMode {
    NFD_SCAN_NONE = 0,
    NFD_SCAN_MODE_USS, //(1<<0)
    NFD_SCAN_MODE_BLE, //(1<<1)
    NFD_SCAN_MODE_USS_BLE
} NFDScanMode;

typedef enum NFDScanErrorCode {
    NFD_NO_ERROR = 0,
    USS_DEVICE_ERROR = -1,
    USS_TIMEOUT_ERROR = -2,
    USS_SHARE_KEY_ERROR = -3,
    USS_LOW_HIGH_FREQ = -4,
    USS_NO_SOUND = -5,
    USS_ALREADY_SCANNING = -6,
} NFDScanErrorCode;

typedef enum NFDLogLevel {
    LEVEL_TRACE = 0,
    LEVEL_DEBUG = 1,
    LEVEL_INFO = 2,
    LEVEL_WARN = 3,
    LEVEL_ERROR = 4,
    LEVEL_CRITICAL = 5
} NFDLogLevel;

typedef enum NFDBlePermissionState {
    BLE_PERMISSION_UNKNOWN = 0,
    BLE_PERMISSION_RESETTING = 1,
    BLE_PERMISSION_UNSUPPORTED = 2,
    BLE_PERMISSION_UNAUTHORIZED = 3,
    BLE_PERMISSION_POWEREDOFF = 4,
    BLE_PERMISSION_POWEREDON = 5
} NFDBlePermissionState;

typedef enum NFDUsage {
    UNKNOWN = 0, //未知
    USS_PREVENT_AUDIO, //入会防啸叫检测
    USS_SHARE_SCREEN, //会前投屏
    USS_SHARE_SCREEN_IN_MEETING, //会中投屏
    USS_PREVIEW_AUTO, // 入会预览页面自动搜索发现会议室
    USS_PREVIEW_MANUAL, // 入会预览页面手动搜索发现会议室
    USS_ONTHECALL_AUTO, // 会中自动搜索会议室
    USS_ONTHECALL_MANUAL, // 会中手动搜索会议室

    BLE_SCAN_ROOMS = 100, //蓝牙发现会议室

    ADV_CONTROLLER = 200, //控制器广播
} NFDUsage;

typedef enum NFDReturnValue {



//
// Created by zhanghaifeng.frank on 2022/12/21.
//

// notice : only can be include by NFDType.h for enum NFDReturnValue
// only use English for comment
        // 0
        NFD_SUCCESS,
        NFD_NO_MEMORY,
        NFD_USS_OPERATION_FAILED, /*logic error, should not happend*/
        NFD_USS_CODE_INVALID,
        NFD_USS_NO_DEVICE,
        NFD_USS_OPEN_DEVICE_FAILED,
        NFD_BLE_DSID_FORMAT_ERROR,
        NFD_ADVERTISER_NOT_INIT,
        NFD_ADVERTISER_ALREADY_START,
        NFD_ADVERTISER_START_FAILED,
        // 10
        NFD_ADVERTISER_UPDATE_FAILED,
        NFD_ADVERTISER_NOT_STARTED,
        NFD_ADVERTISER_CONFIG_FAILED,
        NFD_ADVERTISER_STOP_FAILED,
        NFD_SCANNER_NOT_INIT,
        NFD_SCANNER_CONFIG_FAILED,
        NFD_SCANNER_MODE_NOT_SET,
        NFD_SCANNER_NOT_STARTED,
        NFD_BLE_SERVER_ALREADY_STARTED,
        NFD_BLE_SERVER_NOT_STARTED,
        // 20
        NFD_BLE_CLIENT_ALREADY_STARTED,
        NFD_BLE_CLIENT_NOT_STARTED,
        NFD_BLE_CONTROLLER_NOT_INIT,
        NFD_BLE_NOT_CONFIG,
        NFD_BLE_NOT_SUPPORTED,
        NFD_BLE_NOT_ENABLED,
        NFD_USS_AUDIO_PERMISSION_FAILED,
        NFD_BLE_ANDROID_LOCATION_PERMISSION_FAILED,
        NFD_LOGGER_REGSITER_REPLACE,
        NFD_LOGGER_REGISTER_ERROR,
        //30
        NFD_BLE_POWEROFF,
        NFD_BLE_UNAUTHORIZED,
        NFD_BLE_ADVERTISE_DATA_FORMATE_ERROR,
        NFD_BLE_SCAN_CANNOT_UPDATE,
        NFD_SYNC_CALL_TIMEOUT,
        //35 new add for multi instance
        NFD_SCANNER_START_FAILED,
        NFD_SCANNER_INIT_FAILED,
        NFD_SCANNER_UNINIT_FAILED,
        NFD_BLE_PSDA_ERROR,


} NFDReturnValue;

// callbacks
///
typedef void (*BleScanCallback)(void);

typedef void (*NFDScanCallback)(int id, const char *paramJson,
                                NFDScanErrorCode code);
///
typedef void (*NFDLoggerCallback)(int id, NFDLogLevel level, const char *msg);

///
typedef void (*NFDTrackerFuncCallback)(int id, const char *event,
                                       const char *params);
typedef void (*NFDApplyBlePermissionCallback)(NFDBlePermissionState status);

/// scan call back

typedef int (*NFDIOSBleScanImp)(void *cetral);


}
//
// Created by zhanghaifeng.frank on 2023/4/12.
//

extern "C" {


bool NFDAdvertiserIsInit();
NFDReturnValue NFDAdvertiserInit(NFDLoggerCallback loggerCB,
                                  NFDTrackerFuncCallback trackerFuncCB);
NFDReturnValue NFDAdvertiserConfig(NFDScanMode advMode, const char *config, const char* key);
NFDReturnValue NFDAdvertiserStart(const char *code);
NFDReturnValue NFDAdvertiserUpdate(const char *code);
NFDReturnValue NFDAdvertiserStop(void);
NFDReturnValue NFDAdvertiserUninit(void);
NFDReturnValue NFDUssSetPcmGain(float gain);





int NFDGenerateScannerInstanceID();
bool NFDScannerIsInit(int);
NFDReturnValue NFDScannerInit(int id, NFDLoggerCallback loggerCB,
                               NFDTrackerFuncCallback trackerFuncCB);
NFDReturnValue NFDScannerConfig(int id, const char *config);
NFDReturnValue NFDScannerStart(int id, int timeout, NFDScanMode mode, NFDScanCallback callback, NFDUsage usage);
NFDReturnValue NFDScannerStop(int);
NFDReturnValue NFDScannerUninit(int);






void NFDSDKInit(int id, NFDLoggerCallback loggerCB, NFDTrackerFuncCallback trackerFuncCB);
void NFDSDKUnInit();
void NFDSDKUnregisterLogger(int id);
void NFDSDKUnregisterTracker(int id);

void setIOSBleScanImp(NFDIOSBleScanImp imp);

NFDReturnValue NFDApplyBlePermission(int id, NFDApplyBlePermissionCallback cb);



} // extern "C"
