
/*!@file HMDCrashLoadOption.c
   @author somebody
   @abstract HMDCrashLoadOption is the option
 */

#include <dispatch/dispatch.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <pthread.h>
#include "HMDMacro.h"
#include "HMDCrashLoadOption.h"
#include "HMDCrashLoadOption+Private.h"

enum : uint64_t {
    HMDCrashLoadOptionStatusCreated = 0xcbe4c9a2841097f4,
    HMDCrashLoadOptionStatusMoved   = 0x415e7026408e396f,
    HMDCrashLoadOptionStatusDestroy = 0xd5160bf2d57657c7,
};

#pragma mark - Create, Destroy, Move and Destruct

HMDCLoadOptionRef _Nullable HMDCrashLoadOption_create(void) {
    HMDCLoadOptionRef result = calloc(1, sizeof(struct HMDCLoadOption));
    result->optionStatus.mask = HMDCrashLoadOptionStatusCreated;
    return result;
}

void HMDCrashLoadOption_destroy(HMDCLoadOptionRef _Nonnull option) {
    if(option == NULL) DEBUG_RETURN_NONE;
    
    if(option->optionStatus.mask != HMDCrashLoadOptionStatusCreated)
        DEBUG_RETURN_NONE;
    
    if(option->uploadOption.host          != NULL) free(option->uploadOption.host);
    if(option->uploadOption.appID         != NULL) free(option->uploadOption.appID);
    
    if(option->userProfile.channel        != NULL) free(option->userProfile.channel);
    if(option->userProfile.appName        != NULL) free(option->userProfile.appName);
    if(option->userProfile.installID      != NULL) free(option->userProfile.installID);
    if(option->userProfile.deviceID       != NULL) free(option->userProfile.deviceID);
    if(option->userProfile.userID         != NULL) free(option->userProfile.userID);
    if(option->userProfile.scopedDeviceID != NULL) free(option->userProfile.scopedDeviceID);
    if(option->userProfile.scopedUserID   != NULL) free(option->userProfile.scopedUserID);
    
    option->optionStatus.mask = HMDCrashLoadOptionStatusDestroy;
    
    free(option);
}

void HMDCLoadOption_moveContent(HMDCLoadOptionRef _Nonnull from,
                                HMDCLoadOptionRef _Nonnull to) {
    if(from == NULL || to == NULL)
        DEBUG_RETURN_NONE;
    
    if(from->optionStatus.mask != HMDCrashLoadOptionStatusCreated)
        DEBUG_RETURN_NONE;
    
    to[0] = from[0];
    
    from->uploadOption.host          = NULL;
    from->uploadOption.appID         = NULL;
    
    from->userProfile.channel        = NULL;
    from->userProfile.appName        = NULL;
    from->userProfile.installID      = NULL;
    from->userProfile.deviceID       = NULL;
    from->userProfile.userID         = NULL;
    from->userProfile.scopedDeviceID = NULL;
    from->userProfile.scopedUserID   = NULL;
    
    to->optionStatus.mask = HMDCrashLoadOptionStatusMoved;
}

void HMDCLoadOption_destructContent(HMDCLoadOptionRef _Nonnull moved) {
    if(moved == NULL) DEBUG_RETURN_NONE;
    
    if(moved->optionStatus.mask != HMDCrashLoadOptionStatusMoved)
        DEBUG_RETURN_NONE;
    
    if(moved->uploadOption.host          != NULL) free(moved->uploadOption.host);
    if(moved->uploadOption.appID         != NULL) free(moved->uploadOption.appID);
    
    if(moved->userProfile.channel        != NULL) free(moved->userProfile.channel);
    if(moved->userProfile.appName        != NULL) free(moved->userProfile.appName);
    if(moved->userProfile.installID      != NULL) free(moved->userProfile.installID);
    if(moved->userProfile.deviceID       != NULL) free(moved->userProfile.deviceID);
    if(moved->userProfile.userID         != NULL) free(moved->userProfile.userID);
    if(moved->userProfile.scopedDeviceID != NULL) free(moved->userProfile.scopedDeviceID);
    if(moved->userProfile.scopedUserID   != NULL) free(moved->userProfile.scopedUserID);
    
    moved->optionStatus.mask = HMDCrashLoadOptionStatusDestroy;
}

#pragma mark - Upload

void HMDCrashLoadOption_setEnableUpload(HMDCLoadOptionRef _Nonnull option,
                                        bool enableUpload) {
    if(option == NULL) DEBUG_RETURN_NONE;
    
    option->uploadOption.enable = enableUpload;
}

void HMDCrashLoadOption_setUploadHost(HMDCLoadOptionRef _Nonnull option,
                                      const char * _Nonnull host) {
    if(option == NULL) DEBUG_RETURN_NONE;
    if(host == NULL) DEBUG_RETURN_NONE;
    
    char * _Nonnull dumpHost;
    if((dumpHost = strdup(host)) == NULL) DEBUG_RETURN_NONE;
    
    if(option->uploadOption.host != NULL) free(option->uploadOption.host);
    option->uploadOption.host = dumpHost;
}

void HMDCrashLoadOption_setAppID(HMDCLoadOptionRef _Nonnull option,
                                 const char * _Nonnull appID) {
    if(option == NULL) DEBUG_RETURN_NONE;
    if(appID == NULL) DEBUG_RETURN_NONE;
    
    char * _Nonnull dumpAppID;
    if((dumpAppID = strdup(appID)) == NULL) DEBUG_RETURN_NONE;
    
    if(option->uploadOption.appID != NULL) free(option->uploadOption.appID);
    option->uploadOption.appID = dumpAppID;
}

void HMDCrashLoadOption_uploadIfKeepLoadCrash(HMDCLoadOptionRef _Nonnull option,
                                              bool keepLoadCrash) {
    if(option == NULL) DEBUG_RETURN_NONE;
    
    option->uploadOption.keepLoadCrash = keepLoadCrash;
}

void HMDCrashLoadOption_keepLoadCrashIncludePreviousCrash
    (HMDCLoadOptionRef _Nonnull option, uint32_t maxIncludePreviousCount) {
    
    uint32_t limit = HMD_CLOAD_KEEP_LOAD_CRASH_INCLUDE_PREVIOUS_CRASH_MAX_COUNT;
    
    if(maxIncludePreviousCount > limit) {
        maxIncludePreviousCount = limit;
    }
    
    option->uploadOption.keepLoadCrashIncludePreviousCrashCount =
        maxIncludePreviousCount;
}

void HMDCrashLoadOption_uploadIfCrashTrackerProcessFailed
    (HMDCLoadOptionRef _Nonnull option, bool processFailed) {
    
    if(option == NULL) DEBUG_RETURN_NONE;
    
    option->uploadOption.crashTrackerProcessFailed = processFailed;
}

void HMDCrashLoadOption_dropCrashIfProcessFailed
    (HMDCLoadOptionRef _Nonnull option, bool dropCrash) {
    
    if(option == NULL) DEBUG_RETURN_NONE;
    
    option->directoryOption.dropCrashIfProcessFailed = dropCrash;
}

#pragma mark - User Profile

void HMDCrashLoadOption_setEnableMirror(HMDCLoadOptionRef _Nonnull option,
                                        bool enableMirror) {
    if(option == NULL) DEBUG_RETURN_NONE;
    
    option->userProfile.enableMirror = enableMirror;
}

void HMDCrashLoadOption_setChannel(HMDCLoadOptionRef _Nonnull option,
                                   const char * _Nonnull  channel,
                                   HMDCLoadOptionPriority channelPriority) {
    if(option == NULL) DEBUG_RETURN_NONE;
    if(channel == NULL) DEBUG_RETURN_NONE;
    
    char * _Nonnull dumpChannel;
    if((dumpChannel = strdup(channel)) == NULL) DEBUG_RETURN_NONE;
    
    if(option->userProfile.channel != NULL) free(option->userProfile.channel);
    option->userProfile.channel = dumpChannel;
    
    option->userProfile.channelPriority = channelPriority;
}

void HMDCrashLoadOption_setAppName(HMDCLoadOptionRef _Nonnull option,
                                   const char * _Nonnull  appName,
                                   HMDCLoadOptionPriority appNamePriority)  {
    if(option == NULL) DEBUG_RETURN_NONE;
    if(appName == NULL) DEBUG_RETURN_NONE;
    
    char * _Nonnull dumpAppName;
    if((dumpAppName = strdup(appName)) == NULL) DEBUG_RETURN_NONE;
    
    if(option->userProfile.appName != NULL) free(option->userProfile.appName);
    option->userProfile.appName = dumpAppName;
    
    option->userProfile.appNamePriority = appNamePriority;
}

void HMDCrashLoadOption_setInstallID(HMDCLoadOptionRef _Nonnull option,
                                   const char * _Nonnull  installID,
                                   HMDCLoadOptionPriority installIDPriority) {
    if(option == NULL) DEBUG_RETURN_NONE;
    if(installID == NULL) DEBUG_RETURN_NONE;
    
    char * _Nonnull dumpInstallID;
    if((dumpInstallID = strdup(installID)) == NULL) DEBUG_RETURN_NONE;
    
    if(option->userProfile.installID != NULL) free(option->userProfile.installID);
    option->userProfile.installID = dumpInstallID;
    
    option->userProfile.installIDPriority = installIDPriority;
}

void HMDCrashLoadOption_setDeviceID(HMDCLoadOptionRef _Nonnull option,
                                    const char * _Nonnull  deviceID,
                                    HMDCLoadOptionPriority deviceIDPriority)  {
    if(option == NULL) DEBUG_RETURN_NONE;
    if(deviceID == NULL) DEBUG_RETURN_NONE;
    
    char * _Nonnull dumpDeviceID;
    if((dumpDeviceID = strdup(deviceID)) == NULL) DEBUG_RETURN_NONE;
    
    if(option->userProfile.deviceID != NULL) free(option->userProfile.deviceID);
    option->userProfile.deviceID = dumpDeviceID;
    
    option->userProfile.deviceIDPriority = deviceIDPriority;
}

void HMDCrashLoadOption_setUserID(HMDCLoadOptionRef _Nonnull option,
                                  const char * _Nonnull  userID,
                                  HMDCLoadOptionPriority userIDPriority)  {
    if(option == NULL) DEBUG_RETURN_NONE;
    if(userID == NULL) DEBUG_RETURN_NONE;
    
    char * _Nonnull dumpUserID;
    if((dumpUserID = strdup(userID)) == NULL) DEBUG_RETURN_NONE;
    
    if(option->userProfile.userID != NULL) free(option->userProfile.userID);
    option->userProfile.userID = dumpUserID;
    
    option->userProfile.userIDPriority = userIDPriority;
}

void HMDCrashLoadOption_setScopedDeviceID(HMDCLoadOptionRef _Nonnull option,
                                          const char * _Nonnull  scopedDeviceID,
                                   HMDCLoadOptionPriority scopedDeviceIDPriority)  {
    if(option == NULL) DEBUG_RETURN_NONE;
    if(scopedDeviceID == NULL) DEBUG_RETURN_NONE;
    
    char * _Nonnull dumpScopedDeviceID;
    if((dumpScopedDeviceID = strdup(scopedDeviceID)) == NULL) DEBUG_RETURN_NONE;
    
    if(option->userProfile.scopedDeviceID != NULL) free(option->userProfile.scopedDeviceID);
    option->userProfile.scopedDeviceID = dumpScopedDeviceID;
    
    option->userProfile.scopedDeviceIDPriority = scopedDeviceIDPriority;
}

void HMDCrashLoadOption_setScopedUserID(HMDCLoadOptionRef _Nonnull option,
                                        const char * _Nonnull  scopedUserID,
                                        HMDCLoadOptionPriority scopedUserIDPriority)  {
    if(option == NULL) DEBUG_RETURN_NONE;
    if(scopedUserID == NULL) DEBUG_RETURN_NONE;
    
    char * _Nonnull dumpScopedUserID;
    if((dumpScopedUserID = strdup(scopedUserID)) == NULL) DEBUG_RETURN_NONE;
    
    if(option->userProfile.scopedUserID != NULL) free(option->userProfile.scopedUserID);
    option->userProfile.scopedUserID = dumpScopedUserID;
    
    option->userProfile.scopedUserIDPriority = scopedUserIDPriority;
}
