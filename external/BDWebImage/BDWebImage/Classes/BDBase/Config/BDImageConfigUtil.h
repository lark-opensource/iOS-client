//
//  BDImageConfigUtil.h
//  BDWebImageToB
//
//  Created by 陈奕 on 2020/6/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^BDImageNetworkFinishBlock)(NSError * _Nullable error, NSDictionary *  _Nullable jsonObj);

@interface BDImageConfigUtil : NSObject

+ (void)networkAsyncRequestForURL:(NSString *)requestURL
                          headers:(NSDictionary *)headerField
                           method:(NSString *)method
                            queue:(nullable dispatch_queue_t)queue
                         callback:(BDImageNetworkFinishBlock)callback;

+ (NSDictionary *)defalutHeaderFieldWithAppId:(NSString *)appid;

+ (NSString *)commonParametersWithAppId:(NSString *)appid;

+ (NSDictionary *)decodeWithBase64Str:(NSString *)base64Str;

+ (NSString *)bdImageJSONRepresentation:(id)param;

+ (BOOL)verify:(NSString *)content signature:(NSString *)signature withPublicKey:(NSString *)publicKey;

@end

NS_ASSUME_NONNULL_END
