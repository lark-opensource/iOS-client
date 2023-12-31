//
//  BDBDConfiguration.h
//  BDDynamically
//
//  Created by zuopengliu on 3/6/2018.
//

#import <Foundation/Foundation.h>
#import "BDDYCMonitor.h"
#import "BDQBDelegate.h"

//

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, kBDBDMainRequestType) {
    kBDBDMainRequestTypeTTNet = 100,
    kBDBDMainRequestTypeNSURLSession
};


//#if BDAweme
//__attribute__((objc_runtime_name("AWECFEradicate")))
//#elif BDNews
//__attribute__((objc_runtime_name("TTDParadigm")))
//#elif BDHotSoon
//__attribute__((objc_runtime_name("HTSDPresentiment")))
//#elif BDDefault
//__attribute__((objc_runtime_name("BDDRiddle")))
//#endif
@interface BDBDConfiguration : NSObject

#pragma mark - parameters

/**
 [Required]
 App在公司内部唯一标识，又名`SSAppID`, or read info.plist key `SSAppID`
 */
@property (nonatomic, copy, nonnull) NSString *aid;

/**
 [Required]
 设备id
 */
@property (nonatomic, copy,  nonnull) NSString* (^getDeviceIdBlock)(void);

/**
 [Optional]
 install id
 */
@property (nonatomic, copy, nullable) NSString* (^getInstallIdBlock)(void);

/**
 App渠道；默认读取 info.plist 的 `CHANNEL_NAME` 字段
 */
@property (nonatomic, copy, nonnull) NSString *channel;

/**
 [Optional]
 App三位主版本号；默认读取`CFBundleShortVersionString`
 */
@property (nonatomic, copy, nonnull) NSString *appVersion;

/**
 [Optional]
 App编译版本号，头条内部通常是四位版本号；默认读取`CFBundleVersion`
 */
@property (nonatomic, copy, nonnull) NSString *appBuildVersion;

@property (nonatomic, assign) kBDBDMainRequestType requestType;


#pragma mark - network parameters

// `distArea` 和 `domainName` 决定请求接口的域名。
// 如果手动设置了 domainName ，将使用 domainName 作为接口域名，否则将使用 distArea 配置的默认域名
/**
 [Required]
 产品发布地区；Default is `kBDDYCDeployAreaCN`
 */
@property (nonatomic, assign) BDDYCDeployArea distArea;

/**
 [Optional]
 Domain name, Default is from `distArea` field.
 根据产品实际需求可动态配置部署域名
 */
@property (nonatomic, copy, nonnull) NSString *domainName;

/**
 Common network parameters
 */
@property (nonatomic, copy, nonnull) NSDictionary* (^commonNetworkParamsBlock)(void);

/**
 判断当前网络是否为WIFI
 */
@property (nonatomic, copy, nullable) BOOL (^isWifiNetworkBlock)(void);

/// 是否支持切换前台是请求xxx包;默认：YES
@property (nonatomic, assign) BOOL enableEnterForegroundRequest;

/**
 自定义Monitor实现，不设置时有默认实现（反射调用TTMonitor）
 */
@property (nonatomic, strong) id<BDBDMonitorClass> monitor;

@end


NS_ASSUME_NONNULL_END
