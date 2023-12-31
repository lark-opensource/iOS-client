//
//  HMDProtectFixLibdispatch.h
//  Heimdallr
//
//  Created by maniackk on 2021/8/5.
//

#import <Foundation/Foundation.h>


@interface HMDProtectFixLibdispatch : NSObject

+ (nonnull instancetype)sharedInstance;

//[[HMDProtectFixLibdispatch sharedInstance] fixGCDCrash]
//这个方法必须保证在开启bdfishhook之后，且ttnet初始化之前调用。
//此方法生效，需要在slardar安全气垫上报配置中配置CFFileDescriptor
- (void)fixGCDCrash;

@end

