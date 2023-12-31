//
//  BytedCertManager+AliyunPrivate.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2022/3/14.
//

#import "BytedCertManager.h"
#import "BytedCertError.h"

NS_ASSUME_NONNULL_BEGIN


@interface BytedCertManager (AliyunPrivate)

+ (void)p_initAliyunSDK;

+ (NSString *)p_aliyunSDKVersion;

+ (NSDictionary *)p_aliyunMetaInfo;

@end

NS_ASSUME_NONNULL_END
