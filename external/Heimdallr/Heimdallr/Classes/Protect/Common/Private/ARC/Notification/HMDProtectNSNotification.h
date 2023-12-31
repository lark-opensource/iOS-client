//
//  HMDProtectNSNotification.h
//  Heimdallr
//
//  Created by fengyadong on 2018/4/10.
//

#import <Foundation/Foundation.h>
#import "HMDProtect_Private.h"

NS_ASSUME_NONNULL_BEGIN

extern void HMD_Protect_toggle_Notification_protection(_Nullable HMDProtectCaptureBlock);
void HMD_Protect_Notification_captureException(HMDProtectCapture * _Nonnull capture);

@interface NSNotificationCenter (HMDProtectNotification)

- (void)HMDP_addObserver:(id)observer
                selector:(SEL)aSelector
                    name:(nullable NSNotificationName)aName
                  object:(nullable id)anObject;

- (void)HMDP_removeObserver:(id)observer;

- (void)HMDP_removeObserver:(id)observer
                       name:(nullable NSNotificationName)aName
                     object:(nullable id)anObject;

@end

NS_ASSUME_NONNULL_END

