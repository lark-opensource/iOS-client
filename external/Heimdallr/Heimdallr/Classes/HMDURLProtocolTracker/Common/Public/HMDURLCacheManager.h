//
//  HMDURLCacheManager.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/2/3.
//

#import <Foundation/Foundation.h>



@interface HMDURLCacheManager : NSObject

+ (nonnull instancetype)sharedInstance;

- (void)registerCustomCachePath:(NSString * _Nullable)path;
- (void)unregisterCustomCachePath:(NSString * _Nullable)path;

@end


