//
//  LarkProcessInfoPrivate.h
//  LarkPerf
//
//  Created by KT on 2020/6/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LarkProcessInfoPrivate : NSObject

///通过ActivePrewarm字段检查是否是prewark，该字段还在验证中，暂不使用
+ (BOOL)checkPreWarm;
// 进程创建时间
+ (NSTimeInterval)processStartTime;
+ (CFTimeInterval)getWillFinishLaunchTime;
+ (int)isWarmLaunch;
+ (long)getHardPageFault;
+ (long)getSoftPageFault;

@end

NS_ASSUME_NONNULL_END
