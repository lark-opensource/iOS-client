//
//  CJPayBaseRequest.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/24.
//

#import <Foundation/Foundation.h>
#import <TTNetworkManager/TTNetworkManager.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayRequestSerializeType) {
    CJPayRequestSerializeTypeJSON,
    CJPayRequestSerializeTypeURLEncode,
};

#define CJPayRequestStartNotifictionName @"CJPayRequestStartNotifictionName"
#define CJPayRequestFinishNotificationName @"CJPayRequestFinishNotificationName"

@interface CJPayBaseRequest : NSObject

+ (NSString *)deskServerHostString;

+ (NSString *)deskServerUrlString; //非收银台聚合接口调用此path

+ (NSString *)cashierServerUrlString; //收银台接口调用此path

+ (NSMutableDictionary *)buildBaseParams; //默认verison为1.0， 添加timestamp

+ (NSMutableDictionary *)buildBaseParamsWithVersion:(NSString *)version
                                     needTimestamp:(BOOL)needTimestamp; //聚合接口不传timestamp调用此api。三方默认传timestamp，不要用这个

+ (void)startRequestWithUrl:(NSString *)urlString
              requestParams:(NSDictionary *)requestParams
                   callback:(TTNetworkJSONFinishBlock)callback;

+ (void)startRequestWithUrl:(NSString *)urlString
         serializeType:(CJPayRequestSerializeType)serializeType
              requestParams:(NSDictionary *)requestParams
                   callback:(TTNetworkJSONFinishBlock)callback;

+ (void)startRequestWithUrl:(NSString *)urlString
                     method:(NSString *)method
              requestParams:(NSDictionary *)requestParams
               headerFields:(NSDictionary *)headerFields
              serializeType:(CJPayRequestSerializeType)serializeType
                   callback:(TTNetworkJSONFinishBlock)callback;

+ (void)startRequestWithUrl:(NSString *)urlString
                     method:(NSString *)method
              requestParams:(NSDictionary *)requestParams
               headerFields:(NSDictionary *)headerFields
              serializeType:(CJPayRequestSerializeType)serializeType
                   callback:(TTNetworkJSONFinishBlock)callback
           needCommonParams:(BOOL)needCommonParams;

+ (void)startRequestWithUrl:(NSString *)urlString
                     method:(NSString *)method
              requestParams:(NSDictionary *)requestParams
               headerFields:(NSDictionary *)headerFields
              serializeType:(CJPayRequestSerializeType)serializeType
                   callback:(TTNetworkJSONFinishBlock)callback
           needCommonParams:(BOOL)needCommonParams
               highPriority:(BOOL)highPriority;

+ (void)monitor:(NSString *)reuqestUrlStr error:(nullable NSError *)error response:(nullable TTHttpResponse *)response;
+ (void)exampleMonitor:(NSString *_Nonnull)reuqestUrlStr error:(nullable NSError *)error response:(nullable TTHttpResponse *)response;

@end

@interface CJPayBaseRequest(Config)

+ (void)setGConfigHost:(NSString *)configHost;
+ (NSString *)gConfigHost;

@end

NS_ASSUME_NONNULL_END
