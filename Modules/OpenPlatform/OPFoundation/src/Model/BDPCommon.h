//
//  BDPCommon.h
//  TTHelium
//
//  Created by CsoWhy on 2018/10/14.
//

#import <Foundation/Foundation.h>
#import "BDPSandboxProtocol.h"
#import "BDPAuthorization+BDPSchema.h"
#import "BDPAuthorization+BDPUI.h"
#import "BDPAuthorization.h"
//#import "BDPDefineBase.h"
#import "BDPMacroUtils.h"
#import "BDPModel.h"
#import "BDPPkgFileReadHandleProtocol.h"
#import "BDPSchema.h"

@protocol ECONetworkServiceContext;
@class OPTrace;
/**
 * 当前小程序实例中与宿主无关的相关内容。主要模块：
 * 1.小程序版本及其他小程序基础信息BDPAppModel
 * 2.沙盒数据访问BDPSandbox
 * 3.用户授权模块BDPAuthorization
 * 4.其他一些当前小程序相关参数
 */
@interface BDPCommon : NSObject <ECONetworkServiceContext>

/// 应用Meta
@property (nonatomic, strong) BDPModel *model;

/// 应用沙盒数据访问对象
@property (nonatomic, strong) id<BDPSandboxProtocol> sandbox;

/// 通用应用的唯一复合ID，支持各种应用形态
@property (nonatomic, strong) BDPUniqueID *uniqueID;

/// 小程序 JSBridge 权限校验
@property (nonatomic, strong) BDPAuthorization *auth;

/// jssdk版本号 3位
@property (nonatomic, copy) NSString *sdkVersion;

/// jssdk版本号 4位
@property (nonatomic, copy) NSString *sdkUpdateVersion;

/// 小程序 Schema 对象
@property (nonatomic, copy) BDPSchema *schema;

/// 小程序冷启动 Schema 对象
@property (nonatomic, copy) BDPSchema *coldBootSchema;

/// 是否为激活状态
@property (nonatomic, assign) BOOL isActive;

/// onDocumetReady
@property (nonatomic, assign) BOOL isReady;

/// 是否被销毁
@property (nonatomic, assign) BOOL isDestroyed;

/// 能否跳端
@property (nonatomic, assign) BOOL canLaunchApp;

/// 标识app是否在**宿主前台**显示；不使用isActive的原因是它app切后台会设置NO
@property (nonatomic, assign) BOOL isForeground;

/// vdom 渲染完成标记。
@property (nonatomic, assign) BOOL isSnapshotReady;

/** reader是否处理资源加载的相关任务 */
@property (nonatomic, assign, getter=isReaderOff) BOOL readerOff;

/// 小程序文件读取句柄对象
@property (nonatomic, strong) BDPPkgFileReader reader;

/// 更多按钮上面的badgeNum
@property (nonatomic, assign) NSUInteger moreBtnBadgeNum;

/// 是否是常用应用
@property (nonatomic, assign) BOOL isCommonApp;

/// 真机调试地址
@property (nonatomic, copy, nullable) NSString *realMachineDebugAddress;

/// 性能调试地址
@property (nonatomic, copy, nullable) NSString *performanceTraceAddress;

/// common的s初始化方法
/// @param model 小程序meta
/// @param schema 小程序schema
- (instancetype)initWithModel:(BDPModel *)model schema:(BDPSchema *)schema;

/// 通过schema 和 uniqueID 创建common实例。需要配合updateWithModel一起使用
/// @param schema 小程序schema
/// @param uniqueID 小程序的uniqueID
- (instancetype)initWithSchema:(BDPSchema *)schema uniqueID:(BDPUniqueID *)uniqueID;

/// 通过meta更新common
/// @param model 小程序meta。
- (void)updateWithModel:(BDPModel *)model;


/// 获取 Trace
- (OPTrace * _Nonnull)getTrace;

@end

