//
//  BDTrackerCoreConstants.m
//  Applog
//
//  Created by bob on 2019/3/4.
//

#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackUtility.h"

#pragma mark - SDK VERSION Metas
NSString * const kBDAutoTrackerSDKVersion       = @"sdk_version";
NSString * const kBDPickerSDKVersion            = @"bindSdkVersion";
NSString * const kBDAutoTrackerSDKVersionCode   = @"sdk_version_code";
NSString * const kBDAutoTrackerVersionCode      = @"version_code";

NSInteger const BDAutoTrackerSDKMajorVersion = 6;
NSInteger const BDAutoTrackerSDKMinorVersion = 15;
NSInteger const BDAutoTrackerSDKPatchVersion = 5;
NSInteger const BDAutoTrackerSDKVersion      = BDAutoTrackerSDKMajorVersion * 10000 +
                                               BDAutoTrackerSDKMinorVersion * 100 +
                                               BDAutoTrackerSDKPatchVersion;
NSInteger const BDAutoTrackerSDKVersionCode = 10000000 + BDAutoTrackerSDKVersion;


#pragma mark - magic tag
// 顶层键
NSString * const kBDAutoTrackMagicTag               = @"magic_tag";
NSString * const BDAutoTrackMagicTag                = @"ss_app_log";


#pragma mark - time_sync
// 顶层键
// 也是服务器响应和UserDefaults存储中的键。
NSString * const kBDAutoTrackTimeSync               = @"time_sync";
NSString * const kBDAutoTrackServerTime             = @"server_time";
NSString * const kBDAutoTrackLocalTime              = @"local_time";

#pragma mark - event_v3 事件上报键名
/*
"event_v3" : [
  {
    "params" : {
      "user_level" : 100,
      "interests" : [
        "跑团",
        "登山"
      ]
    },
    "datetime" : "2020-09-20 20:25:40",
    "user_unique_id" : "123",
    "tea_event_index" : 104,
    "session_id" : "4D2AE83C-06C2-4C64-863E-FF26B8088542",
    "event" : "__profile_set",
    "nt" : 4,
    "local_time_ms" : 1600604740603
  }
]
*/
// 事件名
NSString * const kBDAutoTrackEventType              = @"event";
// 事件数据
NSString * const kBDAutoTrackEventData              = @"params";
// kBDAutoTrackEventTime和kBDAutoTrackEventTime都是即将通过网络上报事件时的时刻。
// 两者均为独立生成，一般会有微小差别。
NSString * const kBDAutoTrackEventTime              = @"datetime";
NSString * const kBDAutoTrackLocalTimeMS            = @"local_time_ms";
// BDAutoTrackNetworkConnectionType. 4代表是WiFi网络，5代表是4G网络
NSString * const kBDAutoTrackEventNetWork           = @"nt";
NSString * const kBDAutoTrackEventSessionID         = @"session_id";
NSString * const kBDAutoTrackEventUserID            = @"user_unique_id";
NSString * const kBDAutoTrackEventUserIDType        = @"$user_unique_id_type";

NSString * const kBDAutoTrackGlobalEventID          = @"tea_event_index";
// 标记Launch、Terminate事件是否是被动启动。
NSString * const kBDAutoTrackIsBackground           = @"is_background";
// 标记Launch事件是否是从后台恢复产生的，false是冷启动，true是热启动
NSString * const kBDAutoTrackResumeFromBackground   = @"$resume_from_background";

#pragma mark - header 各键名
/*
"header" : {
    "app_version_minor" : "1",
    "region" : "US",
    "access" : "WIFI",
    "os_version" : "14.0",
    "device_model" : "iPhone12,8",
    "bd_did" : "6889691537922006016",
    "vendor_id" : "6D22746E-8CD9-42BA-A507-0F6E1DF768D8",
    "app_name" : "dp_tob_sdk_test2",
    "carrier" : "",
    "sdk_version" : 50500,
    "custom" : {
      "level" : 1
    },
    "display_name" : "ObjCExample",
    "channel" : "App Store",
    "app_region" : "US",
    "user_agent" : "ObjCExample 1.0 rv:1 (iphone; iOS 14.0; en_US)",
    "idfa" : "00000000-0000-0000-0000-000000000000",
    "install_id" : "6889691537922010112",
    "user_unique_id" : "123",
    "os" : "iOS",
    "tz_name" : "Asia\/Shanghai",
    "tz_offset" : 28800,
    "app_language" : "en",
    "is_upgrade_user" : false,
    "mcc_mnc" : "",
    "aid" : "10000010",
    "ssid" : "fed3ab97-269b-43d0-b248-4efd1f537e06",
    "package" : "com.bytedance.rangersAppLog.ObjCExample",
    "language" : "en",
    "is_jailbroken" : false,
    "sdk_version_code" : 10050500,
    "app_version" : "1.0",
    "resolution" : "750*1334",
    "timezone" : 8
  }
*/

// 顶层键
NSString * const kBDAutoTrackHeader                 = @"header";
NSString * const kBDAutoTrackTracerData             = @"tracer_data";

// custom键，值是一个custom数组。touch_point也在custom键下。
NSString * const kBDAutoTrackCustom                 = @"custom";
NSString * const kBDAutoTrackTouchPoint             = @"touch_point"; // 用户触点。custom header field, set by user
NSString * const kBDAutoTrack__tr_web_ssid          = @"$tr_web_ssid";

NSString * const kBDAutoTrackBDDid                  = @"bd_did";
NSString * const kBDAutoTrackCD                     = @"cd";
NSString * const kBDAutoTrackInstallID              = @"install_id";
NSString * const kBDAutoTrackSSID                   = @"ssid";  // 数说ID

NSString * const kBDAutoTrackAPPID                  = @"aid";
NSString * const kBDAutoTrackAPPName                = @"app_name";
NSString * const kBDAutoTrackAPPDisplayName         = @"display_name";
NSString * const kBDAutoTrackChannel                = @"channel";
NSString * const kBDAutoTrackABSDKVersion           = @"ab_sdk_version";
NSString * const kBDAutoTrackIsFirstTime            = @"$is_first_time";  // 事件参数 - 首次触发标记. 标志一个用户的首次Launch事件。
NSString * const kBDAutoTrackLanguage               = @"language";
NSString * const kBDAutoTrackAppLanguage            = @"app_language";

NSString * const kBDAutoTrackOS                     = @"os";
#if TARGET_OS_IOS
NSString * const BDAutoTrackOSName                     = @"iOS";
#elif TARGET_OS_OSX
NSString * const BDAutoTrackOSName                     = @"MacOS";
#endif
NSString * const kBDAutoTrackOSVersion              = @"os_version";
NSString * const kBDAutoTrackDecivceModel           = @"device_model";
NSString * const kBDAutoTrackDecivcePlatform        = @"device_platform"; // used to generate UserAgent
NSString * const kBDAutoTrackPlatform               = @"platform";
NSString * const kBDAutoTrackSDKLib                 = @"sdk_lib";

NSString * const kBDAutoTrackResolution             = @"resolution";
NSString * const kBDAutoTrackTimeZone               = @"timezone";
NSString * const kBDAutoTrackAccess                 = @"access";
NSString * const kBDAutoTrackAPPVersion             = @"app_version";
NSString * const kBDAutoTrackAPPVersion2            = @"$app_version";
NSString * const kBDAutoTrackAPPBuildVersion        = @"app_version_minor";
NSString * const kBDAutoTrackPackage                = @"package";
NSString * const kBDAutoTrackCarrier                = @"carrier";
NSString * const kBDAutoTrackMCCMNC                 = @"mcc_mnc";
NSString * const kBDAutoTrackRegion                 = @"region";
NSString * const kBDAutoTrackAppRegion              = @"app_region";
NSString * const kBDAutoTrackTimeZoneName           = @"tz_name";
NSString * const kBDAutoTrackTimeZoneOffSet         = @"tz_offset";
NSString *     f_kBDAutoTrackIDFA()                 { return ral_base64_string(@"aWRmYQ=="); }  // idfa
NSString * const kBDAutoTrackVendorID               = @"vendor_id";
NSString * const kBDAutoTrackIsJailBroken           = @"is_jailbroken";
NSString * const kBDAutoTrackIsUpgradeUser          = @"is_upgrade_user";
NSString * const kBDAutoTrackUserAgent              = @"user_agent";

NSString * const kBDAutoTrackLinkType               = @"$link_type";    // ALink 唤醒类型
NSString * const kBDAutoTrackDeepLinkUrl            = @"$deeplink_url"; // ALink 的 deepLinkUrl

// 屏幕方向
NSString * const kBDAutoTrackScreenOrientation      = @"$screen_orientation";

// GPS
NSString * const kBDAutoTrackGeoCoordinateSystem      = @"$geo_coordinate_system";
NSString * const kBDAutoTrackLongitude                = @"$longitude";
NSString * const kBDAutoTrackLatitude                 = @"$latitude";

// 时长统计
NSString * const kBDAutoTrackEventDuration                 = @"$event_duration";

#pragma mark - iOS 14应对工作新增参数 (header)
// 目前只是注册请求header中携带
// 本地时区
NSString * const kBDAutoTrackLocalTZName            = @"local_tz_name";
// 手机开机时间
NSString * const kBDAutoTrackBootTime               = @"boot_time";
// 系统版本更新时间
NSString * const kBDAutoTrackMBTime                 = @"mb_time";
// CPU 核数
NSString * const kBDAutoTrackCPUNum                 = @"cpu_num";
// 系统磁盘空间
NSString * const kBDAutoTrackDiskMemory             = @"disk_total";
// 系统总内存空间
NSString * const kBDAutoTrackPhysicalMemory         = @"mem_total";

#pragma mark - macOS Identifier
//MacOS UUID
NSString * const kBDAutoTrackMacOSUUID              = @"macos_uuid";
//设备序列号
NSString * const kBDAutoTrackMacOSSerial            = @"macos_serial";
//设备硬件型号
NSString * const kBDAutoTrackSku                    = @"sku";


#pragma mark - query Key
// 注：有一些键既在header中，也在query中，比如aid。
NSString * const kBDAutoTrackTTInfo                 = @"tt_info"; // query key of a encrypted query data
NSString * const kBDAutoTrackTTData                 = @"tt_data"; // indicator of the existence of an encrypted query


#pragma mark - 服务器响应
/*
{
 "magic_tag": "ss_app_log",
 "message": "success",
 "server_time": 1600660771
}
*/
// 服务器JSON响应的message键. 用于比较服务器是否返回成功消息。
NSString * const kBDAutoTrackMessage                = @"message";
NSString * const BDAutoTrackMessageSuccess          = @"success";
NSString * const kBDAutoTrackRequestHTTPCode        = @"status_code";


#pragma mark - BDAutoTrackDefaults keys
/* Local Config Service */
NSString * const kBDAutoTrackConfigSSID          = @"kBDAutoTrackConfigSSID";  // 数说ID
NSString * const kBDAutoTrackConfigAppTouchPoint = @"kBDAutoTrackConfigAppTouchPoint";
NSString * const kBDAutoTrackConfigAppLanguage   = @"kBDAutoTrackConfigAppLanguage";
NSString * const kBDAutoTrackConfigAppRegion     = @"kBDAutoTrackConfigAppRegion";
NSString * const kBDAutoTrackConfigUserUniqueID  = @"kBDAutoTrackConfigUserUniqueID";
NSString * const kBDAutoTrackConfigUserUniqueIDType  = @"kBDAutoTrackConfigUserUniqueIDType";
NSString * const kBDAutoTrackConfigUserAgent     = @"kBDAutoTrackConfigUserAgent";

/* 用户维度的首次启动标记 */
NSString *const kBDAutoTrackIsFirstTimeLaunch    = @"kBDAutoTrackIsFirstTimeLaunch";  // 有效值: nil, "false"
/*! 应用维度的首次启动标记 */
NSString *const kBDAutoTrackIsAPPFirstTimeLaunch = @"kBDAutoTrackIsAPPFirstTimeLaunch";  // 有效值: nil, "false"

#pragma mark - h5bridge
NSString * const rangersapplog_script_message_handler_name = @"rangersapplog_ios_h5bridge_message_handler";
