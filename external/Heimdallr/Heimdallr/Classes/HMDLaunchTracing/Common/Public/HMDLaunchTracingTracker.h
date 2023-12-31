//
//  HMDTracingStartTracker.h
//  AFgzipRequestSerializer-iOS13.0
//
//  Created by zhangxiao on 2019/12/23.
//

#import <Foundation/Foundation.h>
#import "HMDOTSpan.h"
#import "HMDOTTraceDefine.h"


@interface HMDLaunchTracingTracker : NSObject

@property (nonatomic, copy, nullable) void (^firstRenderCompletion)(void);

+ (nonnull instancetype)sharedTracker;

/// 获取load=>didfinishlaunch之间的span，如果使用请在 start 方法之前调用， 因为 start 的过程中会对 +load 时间进行写入
- (HMDOTSpan * _Nullable)loadToDidFinishLaunchSpan;

/// 更精确的首次+load时间，如果传入nil，或者不调用此接口，则用Heimdallr内部默认的+load时间
/// @param loadDate 更精确的首次+load时间
- (void)resetLoadDate:(NSDate * _Nullable)loadDate;

/// 启动 trace; 为了防止 debug 下启动流程被打断 造成比较长的启动时间上报 影响线上环境, debug ([TTMacroManager isDebug])下不开启，span写入模式默认是HMDOTTraceInsertModeAllSpanBatch
/// HMDOTTraceInsertModeAllSpanBatch:  整个trace完成时所有span批量写入，磁盘IO很轻量，但是一旦中间发生异常所有span都会丢失
/// 请务必在Appdelegate中的didFinishLaunching方法中同步调用，不要早也不要晚
/// @param needCustomFinish 是否自定义结束时间节点
- (void)startWithCustomFinish:(BOOL)needCustomFinish;

///获取didfinishlaunch=>首次渲染完成的span，startWithUsedCustomFinish方法调用之后才有效
- (nullable HMDOTSpan *)didFinishLaunchToRenderSpan;

/// 创建首次渲染之后的自定义根span，如定义首页异步拉取数据完成绘制之后
/// @param spanName 根span的名字
- (nullable HMDOTSpan *)addRootSpanAfterFirstRenderWithName:(NSString * _Nullable)spanName;

/// 通过 span name 获取  自定义根span
/// @param operationName span 的名称
- (HMDOTSpan * _Nullable)fetchCustomRootSpanWithOperationName:(NSString * _Nullable)operationName;

- (void)addFilterTag:(NSString * _Nonnull)tagName value:(id _Nonnull)value;

/// 当 isUsedCutomerFinish 为 YES 的时候,  调用此方法 手动结束 启动流程;
- (void)customFinish;


@end

