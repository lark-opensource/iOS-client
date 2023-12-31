//
//  ACCEffectEvent.h
//  Pods
//
//  Created by liyingpeng on 2020/6/4.
//

#ifndef ACCEffectEvent_h
#define ACCEffectEvent_h
#import <TTVideoEditor/IESMMEffectMessage.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEffectEvent <NSObject>

@optional

- (void)onEffectMessageReceived:(IESMMEffectMessage *)message;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCEffectEvent_h */
