//
//  HMDMemoryGraphGenerator.h
//  Pods
//
//  Created by fengyadong on 2020/02/21.
//

#import <Foundation/Foundation.h>
#import "HeimdallrModule.h"
#import "HMDMemoryGraphTool.h"

typedef NS_ENUM(NSUInteger, HMDMemoryGraphSupported) {
    /* 设备相关支持 */
    HMDMemoryGraphSupportedNotSimulator = 1<<0,     // 非模拟器
    HMDMemoryGraphSupportedIOSVersion   = 1<<1,     // iOS系统版本 >= 10.0
    HMDMemoryGraphSupportedARM64        = 1<<2,     // 64位系统
    HMDMemoryGraphSupportedPerformance   = 1<<3,     // 性能要求
    HMDMemoryGraphSupportedNotASAN      = 1<<4,     // 非ASAN
    
    /* 业务限制 */
    HMDMemoryGraphSupportedLimitPerDay  = 1<<5,     // 未超过单日次数限制
    
    /* 设备支持Memory graph功能*/
    HMDMemoryGraphSupportedDeviceAll    = HMDMemoryGraphSupportedNotSimulator |
                                          HMDMemoryGraphSupportedIOSVersion |
                                          HMDMemoryGraphSupportedARM64 |
                                          HMDMemoryGraphSupportedPerformance |
                                          HMDMemoryGraphSupportedNotASAN,
    
    /* Memory graph启动条件*/
    HMDMemoryGraphSupportedStartEnabled = HMDMemoryGraphSupportedDeviceAll |
                                          HMDMemoryGraphSupportedLimitPerDay,
    HMDMemoryGraphSupportedPerformace = HMDMemoryGraphSupportedPerformance,
};

typedef void(^HMDMemoryGraphCompleteBlock)(NSError *_Nullable, NSString *_Nullable);
typedef void(^HMDMemoryGraphCloudControlCompleteBlock)(NSError *_Nullable, NSString *_Nullable, NSDictionary *_Nullable);

@interface HMDMemoryGraphGenerator : HeimdallrModule

+ (nonnull instancetype)sharedGenerator;

/// 手动触发内存分析
/// @param immediateUpload 是否立即上报日志
/// @param finishBlock 完成回调，如果error是nil说明成功
- (void)manualGenerateImmediateUpload:(BOOL)immediateUpload
                          finishBlock:(void(^ _Nullable)(NSError *_Nullable))finishBlock;

/// 手动触发内存分析，自定义触发方式
/// @param immediateUpload 是否立即上报日志
/// @param activateManner 触发方式，默认为@"manual"
/// @param finishBlock 完成回调，如果error是nil说明成功
- (void)manualGenerateImmediateUpload:(BOOL)immediateUpload
                       activateManner:(NSString* _Nullable)activateManner
                          finishBlock:(HMDMemoryGraphFinishBlock _Nullable)finishBlock;

/// 手动触发内存分析，自定义触发方式，thread not safe
/// @param immediateUpload 是否立即上报日志
/// @param activateManner 触发方式，默认为@"manual"
/// @param filters 自定义筛选项，会在单点查询列表页筛选项中显示
/// @param context 自定义信息，会在单点查询详情页显示
/// @param finishBlock 完成回调，如果error是nil说明成功
- (void)manualGenerateImmediateUpload:(BOOL)immediateUpload
                       activateManner:(nullable NSString*)activateManner
                        customFilters:(nullable NSDictionary<NSString*, id>*)filters
                        customContext:(nullable NSDictionary<NSString*, id>*)context
                          finishBlock:(nullable HMDMemoryGraphFinishBlock)finishBlock;
@end
