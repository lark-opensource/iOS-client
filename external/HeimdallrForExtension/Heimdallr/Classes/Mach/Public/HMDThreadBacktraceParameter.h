//
//  HMDThreadBacktraceParameter.h
//  Pods
//
//  Created by wangyinhui on 2021/9/6.
//

#import <Foundation/Foundation.h>
#import <mach/mach.h>

#define HMD_THREAD_BACKTRACE_MAX_THREAD_COUNT 500


@interface HMDThreadBacktraceParameter : NSObject

@property(nonatomic, assign)thread_t keyThread; //指定需要获取调用栈的线程id,获取所有线程时无需指定

@property(nonatomic, assign)BOOL isGetMainThread; //指定获取主线程的调用栈，为YES时，keyThread无效，默认值：NO

@property(nonatomic, assign)NSUInteger maxThreadCount; //获取所有线程调用栈时，最大线程数量，默认值：500

@property(nonatomic, assign)NSUInteger skippedDepth; //指定需要忽略的栈顶栈帧数量，默认值：0

@property(nonatomic, assign)BOOL suspend; //获取调用栈时是否挂起线程，不挂起时调用栈可能不准确，默认值：NO

@property(nonatomic, assign)BOOL needDebugSymbol; //Debug环境是否进行符号化，只在Debug是生效，默认值：NO

@end

