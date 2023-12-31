//
//  BDDYCModuleRequest.h
//  BDDynamically
//
//  Created by zuopengliu on 7/3/2018.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, kBDDYCModuleRequestType) {
    kBDDYCModuleRequestTypeTTNet = 100,
    kBDDYCModuleRequestTypeNSURLSession
};



/**
 接口请求
 接口URL: https://security.snssdk.com/api/plugin/config/v1",
 后端数据库描述文档: https://wiki.bytedance.net/pages/viewpage.action?pageId=203691510
 后端接口文档: http://testing.byted.org/static/main/index.html#/interface/detail?id=772

 响应接口字段查看 `BDDYCModuleModel.h` 文件
 */
/**
 请求描述
 
 请求方式：POST
 <Request>
 [paramters]
 {
 device_id              设备ID                      string
 channel                渠道                        string
 app_id                 应用id                      string
 app_name               应用名称                     string
 os_version             iOS系统版本号                string
 
 app_version            应用版本(通常是3位应用版本)    string
 app_build_version      应用build版本（通常是4位版本） string
 device_platform        当前设备信息(iphone/ipad)    string
 }
 
 [body]
 {
 "name": "abc",                 补丁名称      string
 "lastpatch_version":"1.2.3"    最新补丁版本   string
 }
 
 <Response>
 {
 
 }
 */

#if BDAweme
__attribute__((objc_runtime_name("AWECFBlustering")))
#elif BDNews
__attribute__((objc_runtime_name("TTDIvy")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDElephant")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDRomaineCrepe")))
#endif
@interface BDDYCPatchModel : NSObject
// key: name
@property (nonatomic, copy) NSString *name;

// key: lastpatch_version
@property (nonatomic, copy) NSString *latestVersion;
@end

#if BDAweme
__attribute__((objc_runtime_name("AWECFFracas")))
#elif BDNews
__attribute__((objc_runtime_name("TTDTyphoonHerb")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDChimpanzee")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDCabbage")))
#endif
@interface BDDYCModuleRequest : NSObject
@property (nonatomic,   copy) NSString *domainName;
@property (nonatomic,   copy) NSString *requestUrl;
@property (nonatomic, copy) NSDictionary *queryParams;
@property (nonatomic, copy) NSDictionary *bodyParams;

#pragma mark - app parameters

// 使用的热修复类型，0: Brady, 1: JSContext
@property (nonatomic, assign) NSInteger engineType;

// App在公司内部唯一标识，又名`SSAppID`
@property (nonatomic, copy) NSString *aid;

// App名称，默认读取应用bundle_id
@property (nonatomic, copy) NSString *appName;

// 设备id
@property (nonatomic, copy) NSString *deviceId;

// install id
@property (nonatomic, copy) NSString *installId;

// App渠道
@property (nonatomic, copy) NSString *channel;

// 系统版本号 [[UIDevice currentDevice] systemVersion]
@property (nonatomic, copy, readonly) NSString *osVersion;

@property (nonatomic, copy, readonly) NSString *systemName;

// 设备平台信息，目前固定为iphone
@property (nonatomic, copy, readonly) NSString *devicePlatform;

// 设备硬件信息 hw.machine （如）
@property (nonatomic, copy, readonly) NSString *deviceHardwareType;

// 当前设备的最新支持架构信息，i386/x86_64/armv7/arm64
@property (nonatomic, copy, readonly) NSString *activeArch;

// App三位主版本号
@property (nonatomic, copy) NSString *appVersion;

// App编译版本号，通常是四位版本号
@property (nonatomic, copy) NSString *appBuildVersion;

// 补丁[模块]信息
@property (nonatomic, strong) NSArray *quaterbacks;

#pragma mark -

@property (nonatomic, copy, readonly) NSString *language;

@property (nonatomic, assign) kBDDYCModuleRequestType requestType;

@end

@interface BDDYCModuleRequest (NSURLRequest)

- (NSURLRequest *)requestWithFormData:(NSDictionary *)formDict
                                 body:(NSDictionary *)bodyDict;

@end
