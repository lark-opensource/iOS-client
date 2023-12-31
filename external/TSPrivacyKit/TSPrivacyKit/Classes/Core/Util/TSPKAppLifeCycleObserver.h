//Copyright © 2021 Bytedance. All rights reserved.

#import <Foundation/Foundation.h>

@interface TSPKAppLifeCycleObserver : NSObject

+ (instancetype _Nonnull)sharedObserver;
- (void)setup;

- (NSString *_Nullable)getCurrentPage;
- (BOOL)isAppBackground;
- (NSTimeInterval)getTimeLastDidEnterBackground;
- (NSTimeInterval)getServerTimeLastDidEnterBackground;

@end
