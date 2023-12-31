//
//  BDDYCModelKey.h
//  BDDynamically
//
//  Created by zuopengliu on 6/7/2018.
//

#ifndef BDDYCModelKey_h
#define BDDYCModelKey_h



#pragma mark - request keys

/**
 URL request parameter keys
 */
#define kBDDYCAppIdReqKey               (@"aid")
#define kBDDYCAppNameReqKey             (@"app_name")
#define kBDDYCDeviceIdReqKey            (@"device_id")
#define kBDDYCChannelReqKey             (@"channel")
#define kBDDYCOSVersionReqKey           (@"os_version")             // system version
#define kBDDYCAppVersionReqKey          (@"version_code")           // app version
#define kBDDYCAppBuildVersionReqKey     (@"uvc")    // app build version
#define kBDDYCDeviceMachineReqKey       (@"dht")   // device hardware type
#define kBDDYCDevicePlatformReqKey      (@"device_platform")        // device platform 'iphone'
#define kBDDYCActiveArchReqKey          (@"aa")            // device supported latest arch
#define kBDDYCEngineTypeReqKey          (@"et")            // 使用热修复引擎类型 (int)
#define kBDDYCLocaleIdentifierReqKey    (@"locale_identifier")      //
#define kBDDYCLanguageReqKey            (@"language")               //
#define kBDDYCCountryCodeReqKey         (@"country")                //

#define kBDDYCQuaterbackListReqKey           (@"p1")                  // patch
#define kBDDYCQuaterbackIdReqKey             (@"pid")               // patch id
#define kBDDYCQuaterbackNameReqKey           (@"pname")             // patch name
#define kBDDYCQuaterbackVersionReqKey        (@"pvc")            // lastpatch_version



#pragma mark - response keys

/**
 URL response parameter keys
 */
#define KBDDYCURLResponseMsgKey         (@"message")
#define KBDDYCURLResponseDataKey        (@"data")

#define kBDDYCQuaterbackListRespKey          (@"p1")

#define kBDDYCQuaterbackIDRespKey            (@"id")               // patch_id
#define kBDDYCQuaterbackNameRespKey          (@"name")             // patch_name
#define kBDDYCQuaterbackVersionRespKey       (@"vc")            // patch_version
#define kBDDYCAppVersionRespKey         (@"app_version")            // app_version
#define kBDDYCAppBuildVersionRespKey    (@"app_build_version")      // app_build_version
#define kBDDYCQuaterbackMD5RespKey           (@"md5")
#define kBDDYCQuaterbackUrlRespKey           (@"url")
#define kBDDYCQuaterbackBackupUrlsRespKey    (@"backup_urls")
#define kBDDYCQuaterbackOfflineRespKey       (@"offline")                // turn_off
#define kBDDYCQuaterbackWifiOnlyRespKey      (@"wifionly")
#define kBDDYCQuaterbackOperationTypeRespKey (@"operation_type")         // 没有使用
#define kBDDYCQuaterbackArchRespKey          (@"arch")
#define kBDDYCQuaterbackAsyncLoad            (@"async_load")
#define kBDDYCQuaterbackChannel              (@"channel")
#define kBDDYCQuaterbackAPPVersionList       (@"app_version_list")
#define kBDDYCQuaterbackOSVersionRange       (@"os_version_range")


#pragma mark - other keys

#define kBDDYCModuleIDKey               (@"module_id")
#define kBDDYCNameRespKey               (@"name")
#define kBDDYCEncryptStatusKey          (@"encrypted")
#define kBDDYCEncryptPrivateKeyKey      (@"private_key")

#define kBDDYCPatchFilePathsKey         (@"file_paths")
#define kBDDYCPatchBundleNameKey        (@"bundle_name")
#define kBDDYCPatchBundlePathKey        (@"bundle_path")


#pragma mark - 本地目录

#define BDDYC_MODULE_ROOT_DIR     @"Better"
#define BDDYC_MODULE_PLIST_FILE   @"better_modules"



#endif /* BDDYCModelKey_h */

