//
//  BDImageConfigConstants.m
//  BDWebImageToB
//
//  Created by 陈奕 on 2020/10/22.
//

#import "BDImageConfigConstants.h"

NSString * const kBDImageSDKVersion                 = @"sdk_version";
NSString * const kBDImageAppVersion                 = @"app_version";
NSString * const kBDImageOS                         = @"os";
NSString * const kBDImageOSVersion                  = @"os_version";
NSString * const kBDImageAid                        = @"aid";

NSString * const kBDImageStatusCode                 = @"status_code";
NSString * const kBDImageMsg                        = @"msg";
NSString * const kBDImageOk                         = @"ok";
NSString * const kBDImageData                       = @"data";
NSString * const kBDImageCustomSettings             = @"custom_settings";
NSString * const kBDImageAllowLogType               = @"allow_log_type";
NSString * const kBDImageLoadMonitor                = @"imagex_load_monitor";
NSString * const kBDImageLoadErrorMonitor           = @"imagex_load_monitor_error";
NSString * const kBDImageGeneralSettings            = @"general_settings";
NSString * const kBDImageFetchInterval              = @"fetch_settings_interval";

NSString * const kBDImageSuperResolution            = @"SR";
NSString * const kBDImageEnabledSuperResolution     = @"enable_sr";

NSString * const kBDImageAuthCode                   = @"auth_code";
NSString * const kBDImageServerTime                 = @"server_time";

NSString * const KBDImageTTNet                      = @"TTNet";
NSString * const kBDImageHttpDNSSettings            = @"httpdns_settings";
NSString * const kBDImageTTNetSettings              = @"ttnet_settings";
NSString * const kBDImageHttpSecretkey              = @"ttnet_http_dns_secretkey";
NSString * const kBDImageHttpServiceId              = @"ttnet_http_dns_serviceid";
NSString * const kBDImageEnabledHttpDNS             = @"ttnet_http_dns_enabled";
NSString * const kBDImageEnabledH2                  = @"ttnet_h2_enabled";

NSString * const kBDImageSettingFetchIntervalKey = @"kBDImageSettingFetchIntervalKey";
NSString * const kBDImageMonitorRateKey = @"kBDImageMonitorRateKey";
NSString * const kBDImageErrorMonitorRateKey = @"kBDImageErrorMonitorRateKey";
NSString * const kBDImageSettingsStoredKey = @"kBDImageSettingsStoredKey";
NSString * const kBDImageSettingsServerTimeKey = @"kBDImageSettingsServerTimeKey";
NSString * const kBDImageSettingsAuthCodeKey = @"kBDImageSettingsAuthCodeKey";
NSString * const kBDImageTTNetEnabledSR = @"kBDImageEnabledSR";
NSString * const kBDImageTTNetEnabledHttpDNS = @"kBDImageTTNetEnabledHttpDNS";
NSString * const kBDImageTTNetEnabledH2 = @"kBDImageTTNetEnabledH2";
NSString * const kBDImageHttpDNSAuthId = @"kBDImageHttpDNSAuthId";
NSString * const kBDImageHttpDNSAuthKey = @"kBDImageHttpDNSAuthKey";

// 公钥Key1和Key2
NSString * const kBDImageSignaturePublicKey1 = @"MIIBCgKCAQEAsITd9d+K2VTVqpOoia55MY02UFteRVCep8VDL9oHLORAQ4fb1nF0DYYS/624o8wlSUfSihET56k2LoYd59jRxQmgAJAktPIQOvweRydQ9lQnysmkvl/QwQW+mxcsJbQSDQvHE6VzDkKUORIf8XsQBzabWpjs91WEi4yn3KyH++Hj1m8gmRK1vHCuPE0pw0JY7ngBOszZ7RXEaGB4ME1JzXZuyVA44QGBAqOChLO3FD49t4U8j6IqtPoQA9ZU68RHd5nJ9+m8Zwlvb/b4N5Jip6xtc2TA2zcEa3sGwOj6QdX/taKamqBFtLTbbXNZkLyg9SwTEcjunsrytBVx6ZKx5QIDAQAB";
NSString * const kBDImageSignaturePublicKey2 = @"MIIBCgKCAQEAwEN3JSM9ZPk+xJYdUAmvNLtH9jCJU4pDMvnGAASFd/S6obo4iCGxPClhw5Ktj7QXRh1gYaP4TzmG53Y630XJc2v3lsi4FL0d/4VF25ZD4qcgT39gvDtvKzYIeoU9LB+G4u1t2/XTcRbwen3SuifRTegWPbpNQvh/fAK/9Ty1eKkoH6HlOzQS0QU9kE7sdWvW8VjCkIsKIaHan3wiPJmRmy7j4f11jni67dR0NMP5a8wz54PeBVrqkqX+P6Cq9meiPrm7VD1G1Z4z4Ap3UGfMM+Q2m07CLdoRKQin8LVB1zFYvG+oFL5Oul2fwEsOAfpnamfwGlENS9GF+Bqbgv4sLwIDAQAB";
// 公钥id
NSString * const kBDImageSignaturePublicKey1Id = @"0001";
NSString * const kBDImageSignaturePublicKey2Id = @"0002";

NSString * const kBDImageSignature = @"Signature";
NSString * const kBDImageSuiteID = @"SuiteID";
NSString * const kBDImageAddOn = @"AddOn";
NSString * const kBDImageBundleID = @"BundleID";
NSString * const kBDImageCFBundleIdentifier = @"CFBundleIdentifier";
NSString * const kBDImageStartTime = @"StartTime";
NSString * const kBDImageEndTime = @"EndTime";

NSString * const kBDImageDomainHttpDNS     =   @"httpdns.volcengineapi.com";
NSString * const kBDImageDomainNetlog      =   @"crash.snssdk.com";
NSString * const kBDImageDomainBoe         =   @".boe-gateway.byted.org";

// 自适应
NSString * const kBDImageAdaptiveFormat                 = @"image_adaptive_format";
NSString * const kBDImageAnimatedAdaptivePolicy         = @"animated_adaptive_policy";
NSString * const kBDImageStaticAdaptivePolicy           = @"static_adaptive_policy";

// 成功拉群配置之后会发起一个开启 http dns 的通知
NSString * const kBDImageFetchConfigSuccess     = @"kBDImageFetchConfigSuccess";
