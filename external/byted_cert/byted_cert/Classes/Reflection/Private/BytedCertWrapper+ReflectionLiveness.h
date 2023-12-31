//
//  BytedCertWrapper+ReflectionLiveness.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/17.
//

#import "BytedCertWrapper.h"

NS_ASSUME_NONNULL_BEGIN


@interface BytedCertWrapper (ReflectionLiveness)

+ (BOOL)isReflectionLivenessModelReady;

+ (int)reflectionLivenessModelStatus;

@end

NS_ASSUME_NONNULL_END
