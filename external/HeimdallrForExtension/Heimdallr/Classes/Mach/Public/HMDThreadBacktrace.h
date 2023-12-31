//
//  HMDThreadBacktrace.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import "HMDThreadBacktraceParameter.h"

@class HMDThreadBacktraceFrame;



@interface HMDThreadBacktrace : NSObject
@property(nonatomic, assign) NSUInteger threadIndex;
@property(nonatomic, assign) uintptr_t threadID;
@property(nonatomic, assign) float threadCpuUsage;
@property(nonatomic, assign) BOOL crashed; // 当前线程是否为崩溃线程
@property(nonatomic, strong, nullable) NSString *name;
@property(nonatomic, strong, nullable) NSArray<HMDThreadBacktraceFrame *> *stackFrames;// 栈顶(0)->栈底(max)
@property(nonatomic, assign) NSTimeInterval timestamp;
@property(nonatomic, readonly) BOOL isSymbol; // 当前堆栈是否符号化

+ (thread_t)mainThread;

+ (thread_t)currentThread;

+ (vm_address_t)getImageHeaderAddressWithName:(NSString * _Nullable)name;

+ (vm_address_t)getAppImageHeaderAddressWithName:(NSString * _Nullable)name;

#pragma mark - recommend API

/**
 * 获取所有线程调用栈，推荐使用
 * @param parameter 获取调用栈的参数
 *  -keyThread BOOL 指定需要获取调用栈的线程id,获取所有线程时无需指定
 *  -isGetMainThread BOOL 指定获取主线程的调用栈，为YES时，keyThread无效，默认值：NO
 *  -maxThreadCount NSUInteger 获取所有线程调用栈时，最大线程数量，默认值：500
 *  -skippedDepth NSUInteger 指定需要忽略的栈顶栈帧数量，默认值：0
 *  -suspend BOOL 获取调用栈时是否挂起线程，不挂起时调用栈可能不准确，默认值：NO
 *  -needDebugSymbol BOOL Debug环境是否进行符号化，只在Debug是生效，默认值：NO
 */
+ (NSArray<HMDThreadBacktrace *> * _Nullable)backtraceOfAllThreadsWithParameter:(HMDThreadBacktraceParameter * _Nonnull)parameter;

/**
 * 获取单个线程调用栈，推荐使用
 *@param parameter 获取调用栈参数
 *  -keyThread BOOL 指定需要获取调用栈的线程id,获取所有线程时无需指定
 *  -isGetMainThread BOOL 指定获取主线程的调用栈，为YES时，keyThread无效，默认值：NO
 *  -maxThreadCount NSUInteger 获取所有线程调用栈时，最大线程数量，默认值：500
 *  -skippedDepth NSUInteger 指定需要忽略的栈顶栈帧数量，默认值：0
 *  -suspend BOOL 获取调用栈时是否挂起线程，不挂起时调用栈可能不准确，默认值：NO
 *  -needDebugSymbol BOOL Debug环境是否进行符号化，只在Debug是生效，默认值：NO
 */
+ (HMDThreadBacktrace * _Nullable)backtraceOfThreadWithParameter:(HMDThreadBacktraceParameter * _Nonnull)parameter;

#pragma mark - unrecommend API
+ (NSArray<HMDThreadBacktrace *> * _Nullable)backtraceOfAllThreadsWithKeyThread:(thread_t)keyThread
                                                          symbolicate:(BOOL)symbolicate
                                                         skippedDepth:(NSUInteger)skippedDepth
                                                              suspend:(BOOL)suspend
                                                       maxThreadCount:(NSUInteger)maxThreadCount;

+ (HMDThreadBacktrace * _Nullable)backtraceOfMainThreadWithSymbolicate:(BOOL)symbolicate
                                                skippedDepth:(NSUInteger)skippedDepth
                                                     suspend:(BOOL)suspend;

+ (HMDThreadBacktrace * _Nullable)backtraceOfThread:(thread_t)thread
                              symbolicate:(BOOL)symbolicate
                             skippedDepth:(NSUInteger)skippedDepth
                                  suspend:(BOOL)suspend;

+ (HMDThreadBacktraceFrame * _Nullable)symbolicateForAddress:(uintptr_t)address;

- (void)symbolicate:(bool)needSymbolName; // 符号化（获取image信息）

// 搜索第一个App自身调用栈地址（顶栈调用）
// 不存在返回 0
- (uintptr_t)topAppAddress;

// 搜索最后一个App自身调用栈地址（底栈调用）
// 不存在返回 0
- (uintptr_t)bottomAppAddress;

@end

