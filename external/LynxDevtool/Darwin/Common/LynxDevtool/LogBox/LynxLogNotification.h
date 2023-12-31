//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxLogBoxManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxLogNotificationManager : NSObject

- (instancetype)initWithLogBoxManager:(LynxLogBoxManager *)manager;
- (void)showNotificationWithMsg:(nullable NSString *)msg withLevel:(LynxLogBoxLevel)level;
- (void)updateNotificationMsg:(nullable NSString *)msg withLevel:(LynxLogBoxLevel)level;
- (void)updateNotificationMsgCount:(nullable NSNumber *)count withLevel:(LynxLogBoxLevel)level;
- (void)showNotification;
- (void)hideNotification;
- (void)removeNotificationWithLevel:(LynxLogBoxLevel)level;
- (void)closeNotification:(LynxLogBoxLevel)level;

@end

NS_ASSUME_NONNULL_END
