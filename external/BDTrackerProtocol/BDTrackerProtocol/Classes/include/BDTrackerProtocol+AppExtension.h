//
//  BDTrackerProtocol+AppExtension.h
//  BDTrackerProtocol
//
//  Created by bob on 2020/11/5.
//

#import "BDTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTrackerProtocol (AppExtension)

+ (void)eventV3:(NSString *)event
         params:(nullable NSDictionary *)params
      localTime:(long long)localTime;

@end

NS_ASSUME_NONNULL_END
