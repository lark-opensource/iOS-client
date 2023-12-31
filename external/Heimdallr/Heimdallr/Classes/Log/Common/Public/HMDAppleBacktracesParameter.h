//
//  HMDAppleBacktracesParameter.h
//  Pods
//
//  Created by wangyinhui on 2021/9/6.
//

#import <Foundation/Foundation.h>
#import "HMDThreadBacktraceParameter.h"
#import "HMDLog.h"

@interface HMDAppleBacktracesParameter : HMDThreadBacktraceParameter

@property(nonatomic, assign)BOOL needAllThreads; //是否获取所有线程，当为YES时，isGetMainThread失效，默认值：NO

@property(nonatomic, assign)HMDLogType logType; //log类型

@property(nonatomic, strong, nullable)NSString *exception; //异常名称

@property(nonatomic, strong, nullable)NSString *reason; //异常原因

@end
