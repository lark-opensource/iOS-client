//
//  NSDate+HMDAccurate.h
//  Heimdallr
//
//  Created by fengyadong on 2020/4/2.
//

#import <Foundation/Foundation.h>

@interface NSDate (HMDAccurate)

/// 根据开机时间的间隔计算当前准确的时间，排除用户手动修改时间的干扰
+ (NSDate * _Nullable)hmd_accurateDate;

@end
