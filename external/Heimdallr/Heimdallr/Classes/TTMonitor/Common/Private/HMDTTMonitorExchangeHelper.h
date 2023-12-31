//
//  HMDTTMonitorHookHelper.h
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 20/5/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDTTMonitorExchangeHelper : NSObject

@property (nonatomic, assign, class) BOOL isSwizzled;

+ (void)exchangeTTMonitorInterfaceIfNeeded:(NSNumber *)needHook;

@end

NS_ASSUME_NONNULL_END

