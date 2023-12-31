//
//  BDPPerformanceProfileManager.h
//  TTMicroApp
//
//  Created by ChenMengqi on 2022/12/13.
//

#import <Foundation/Foundation.h>
#import "OPMicroAppJSRuntimeProtocol.h"
#import <OPFoundation/OPJSEngineProtocol.h>
#import <OPFoundation/BDPCommon.h>

NS_ASSUME_NONNULL_BEGIN

/**
 - serviceContainerLoad: 小程序 Service 容器加载
 - webviewContainerLoad: 小程序 WebView 容器加载
 - serviceJSSDKLoad: 小程序 Service JSSDK 加载
 - webviewJSSDKLoad: 小程序 Service JSSDK 加载
 - metaLoad: 小程序 meta 加载
 - packageLoad: 小程序代码包加载
 - appServiceJSRun: app-service.js  执行
 - pageFrameJSRun: page-frame.js 执行
 - subAppServiceJSRun: sub-app-service.js 执行（客户端一期不包含，后续再支持）
 - subPageFrameJSRun: sub-app-service.js 执行（客户端一期不包含，后续再支持）
 */
typedef NS_ENUM(NSUInteger, BDPPerformanceKey) {
    BDPPerformanceLaunch,
    BDPPerformanceWarmLaunch,
    BDPPerformanceServiceContainerLoad,
    BDPPerformanceWebviewContainerLoad,
    BDPPerformanceServiceJSSDKLoad,
    BDPPerformanceWebviewJSSDKLoad,
    BDPPerformanceMetaLoad,
    BDPPerformancePackageLoad,
    BDPPerformanceAppServiceJSRun,
    BDPPerformancePageFrameJSRun,
    BDPPerformanceDomready
};

#define kBDPPerformanceWebviewId @"webviewId"

@interface BDPPerformanceProfileManager : NSObject


+ (instancetype)sharedInstance;

/// 建立性能分析所需websocket链接
/// - Parameters:
///   - address: socket address
///   - jsThread: js线程
-(void)buildConnectionWithAddress:(NSString *)address jsThread:(id<OPMicroAppJSRuntimeProtocol>)jsThread;

@property (nonatomic, strong) BDPUniqueID *uniqueID;
/// 是否允许 性能分析
@property (nonatomic, assign, readonly) BOOL profileEnable;

/// 当前是否已经domready（对于apppage等生成有不同处理逻辑）
@property (nonatomic, assign, readonly) BOOL isDomready;

/// domready 后发送前期数据
-(void)flushLaunchPointsWhenDomready;

/// 发送jssdk切片后的数据
-(void)flushJSSDKPerformanceData:(NSDictionary *)performanceData;

/// 发送启动阶段的性能（起点）
/// - Parameters:
///   - key: 表示是什么行为的性能数据
///   - extra: 额外数据
- (void)monitorLoadTimelineWithStartKey:(BDPPerformanceKey)key
                               uniqueId:(nullable BDPUniqueID *)uniqueId
                                  extra:(nullable NSDictionary *)extra;
    

/// 发送启动阶段的性能（终点）
/// - Parameters:
///   - key: 表示是什么行为的性能数据
///   - extra: 额外数据
- (void)monitorLoadTimelineWithEndKey:(BDPPerformanceKey)key
                             uniqueId:(nullable BDPUniqueID *)uniqueId
                                extra:(nullable NSDictionary *)extra;


-(BOOL)enableProfileForCommon:(BDPCommon *)common;

///点击按钮后 结束调试
-(void)endProfileAfterFinishDebugButtonPressed;

/// 停止当前连接
-(void)endConnection;

/// 初始化 profile manager
-(void)initForProfileManager;

// 获取当前性能数据
-(NSArray *)getPerformanceEntriesByUniqueId:(BDPUniqueID *)uniqueId;


//清理当前性能数据
-(void)removePerformanceEntriesForUniqueId:(OPAppUniqueID *)uniqueId;

@end

NS_ASSUME_NONNULL_END
