//
//  BytedCertNetResponse.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/14.
//

#import <Foundation/Foundation.h>
#import <TTNetworkManager/TTNetworkManager.h>

NS_ASSUME_NONNULL_BEGIN


@interface BytedCertNetResponse : NSObject

@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, copy, nullable) NSString *logId;

+ (instancetype _Nonnull)responseWithTTNetHttpResponse:(TTHttpResponse *)httpResponse;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype _Nonnull)initWithStatusCode:(NSInteger)statusCode logId:(NSString *_Nullable)logId;

@end

NS_ASSUME_NONNULL_END
