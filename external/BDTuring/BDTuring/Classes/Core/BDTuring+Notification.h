//
//  BDTuring+Notification.h
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuring.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuring (Notification)

- (void)onWillChangeStatusBarOrientation:(NSNotification *)notification;
- (void)onDidEnterBackground;
- (void)onWillEnterForeground;

@end

NS_ASSUME_NONNULL_END
