//
//  TMAPluginNetworkTools.h
//  Timor
//
//  Created by changrong on 2020/9/17.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/OPAppUniqueID.h>

NS_ASSUME_NONNULL_BEGIN

/// 为 TMAPluginNetwork 提供的工具类，与上下文状态无关
@interface TMAPluginNetworkTools : NSObject

/// 组件 tt.request 的multipartBody
+ (NSData *)multipartBodyWithName:(NSString *)name
                         boundary:(NSString *)boundary
                         fileName:(NSString *)fileName
                         fileData:(NSData *)fileData
                    otherFormData:(NSDictionary *)otherFormData;

#pragma mark - tt.request header monitor

/// tt.request req/res header 信息通过埋点上报
///     1. 上报哪些 key 通过配置下发控制: tt_request_header_monitor
///     2. header value 通过掩码处理
///     3. cookie 掩码特殊处理
///
/// tt_request_header_monitor 格式示例:
/// {
///    default_header_keys: {   // 默认需要处理的 req，res 的 header key
///        "request_header_keys": ["1", "2", "3"],
///        "response_header_keys": ["1", "2", "3"]
///    },
///    header_keys: {           // 应用维度配置
///        "app_id": {
///            "request_header_keys": ["1", "2", "3"],
///            "response_header_keys": ["1", "2", "3"]
///        },
///    }
/// }
///
///
/// tt.request Request header 埋点信息
/// @param uniqueID uniqueID
/// @param header 原始 request header
+ (NSString *)monitorValueForUniqueID:(nullable OPAppUniqueID *)uniqueID requestHeader:(NSDictionary<NSString *, NSString *> *)header;

/// tt.request Response header 埋点信息
/// @param uniqueID uniqueID
/// @param header 原始 Response header
+ (NSString *)monitorValueForUniqueID:(nullable OPAppUniqueID *)uniqueID responseHeader:(NSDictionary<NSString *, NSString *> *)header;

+ (NSString *)cookieMaskValueForOrigin:(NSString *)origin;

@end

NS_ASSUME_NONNULL_END
