//
//  LVMediaSegment+AudioEffect.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/13.
//

#import "LVMediaSegment.h"
#import <TTVideoEditor/IESMMAudioEffectConfig.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVMediaSegment (AudioEffect)

- (nullable IESMMAudioFadeConfig *)fadeConfig;

@end

NS_ASSUME_NONNULL_END
