//
//  ACCMessageProtocol.h
//  Pods
//
//  Created by liyingpeng on 2020/6/4.
//

#ifndef ACCMessageProtocol_h
#define ACCMessageProtocol_h

#import "ACCCameraWrapper.h"
#import "ACCCameraSubscription.h"
#import "ACCEffectEvent.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMessageProtocol <ACCCameraWrapper, ACCCameraSubscription>

- (void)bindEffectMessage;

#pragma mark -

- (void)sendMessageToEffect:(IESMMEffectMessage *)message;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCMessageProtocol_h */
