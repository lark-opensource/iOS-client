//Copyright © 2021 Bytedance. All rights reserved.

#import <Foundation/Foundation.h>
#import <TSPrivacyKit/TSPKSubscriber.h>

/// used to match senstive api access with jsb call info, and upload
@interface TSPKCrossPlatformSubscriber : NSObject <TSPKSubscriber>

- (void)setConfigs:(NSDictionary * _Nullable)configs;

@end
