//
//  BDPMonitorEvent.m
//  Timor
//
//  Created by yinyuan on 2018/12/9.
//

#import "BDPMonitorEvent.h"
#import "BDPTracker.h"
#import "BDPVersionManager.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import "BDPUtils.h"
#import "BDPCommonManager.h"
#import "BDPSchemaCodec.h"
#import "BDPMonitorHelper.h"
#import "BDPSchemaCodec.h"
#import <OPFoundation/OPFoundation-Swift.h>
#import "BDPTimorClient.h"
#import <ECOProbe/ECOProbe-Swift.h>
#import "OPResolveDependenceUtil.h"


BDPMonitorEvent * _Nonnull BDPMonitorWithName(NSString * _Nonnull eventName, BDPUniqueID * _Nullable uniqueID) {
    return BDPMonitorWithNameAndCode(eventName, nil, uniqueID);
}

BDPMonitorEvent * _Nonnull BDPMonitorWithCode(OPMonitorCode * _Nonnull monitorCode, BDPUniqueID * _Nullable uniqueID) {
    return BDPMonitorWithNameAndCode(nil, monitorCode, uniqueID);
}

BDPMonitorEvent * _Nonnull BDPMonitorWithNameAndCode(NSString * _Nullable eventName, OPMonitorCode * _Nullable monitorCode, BDPUniqueID * _Nullable uniqueID) {
    BDPTracing *tracing = [BDPTracingManager.sharedInstance getTracingByUniqueID:uniqueID];
    return (BDPMonitorEvent *)[[BDPMonitorEvent alloc] initWithService:nil name:eventName monitorCode:monitorCode].setUniqueID(uniqueID).bdpTracing(tracing);
}

@interface OPMonitorEvent (BDPExtensionPrivate)

- (void)applyAppCommon:(BDPCommon *)common;

@end

@interface BDPMonitorEvent()

@property (nonatomic, strong) OPAppUniqueID *_uniqueID;

@end

@implementation BDPMonitorEvent

- (instancetype)initWithService:(id<OPMonitorServiceProtocol>)service name:(NSString *)name monitorCode:(OPMonitorCode *)monitorCode {

    // 默认采用 Gadget 定制上报
    service = service ?: GDMonitorService.gadgetMonitorService;
    self = [super initWithService:service name:name monitorCode:monitorCode];
    if (self) {
        //https://t.wtturl.cn/NFPT1vY/
        //修复 localLibVersionString 获取时会偶现造成卡顿的问题，将耗时操作放在独立线程中获取
        if (!OPSDKFeatureGating.enableMonitorFlushInQueue) {
            self.addCategoryValue(kEventKey_js_version, BDPVersionManager.localLibVersionString);
            self.addCategoryValue(kEventKey_js_grey_hash, BDPVersionManager.localLibGreyHash);
        }
    }
    return self;
}

- (void (^)(void))flush {
    id flushBlock = ^{};
    if (OPSDKFeatureGating.enableMonitorFlushInQueue) {
        //打开线程安全模式，确保之后的 dictionary 来自 ECOSafeMutableDictionary
        [self enableThreadSafe]();
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            self.addCategoryValue(kEventKey_js_version, BDPVersionManager.localLibVersionString);
            self.addCategoryValue(kEventKey_js_grey_hash, BDPVersionManager.localLibGreyHash);
            [self innerFlush];
        });
    } else {
        flushBlock = [self innerFlush];
    }
    
    return flushBlock;
}

- (void (^)(void))innerFlush {
    
    NSDictionary *baseData = self.data;
    if (baseData) {
        
        // 应用公共参数检查和设置
        NSString *appID = [baseData bdp_stringValueForKey:kEventKey_app_id];
        if (!self._uniqueID.isValid && !BDPIsEmptyString(appID)) {
            
            NSString *identifier = [baseData bdp_stringValueForKey:kEventKey_identifier];
            NSString *versionTypeString = [baseData bdp_stringValueForKey:kEventKey_version_type];
            NSString *appTypeString = [baseData bdp_stringValueForKey:kEventKey_app_type];
            
            BDPUniqueID *uniqueID = [BDPUniqueID uniqueIDWithAppID:appID
                                                        identifier:identifier
                                                       versionType:OPAppVersionTypeFromString(versionTypeString)
                                                           appType:appTypeString ? OPAppTypeFromString(appTypeString) : BDPTypeNativeApp
                                     ];
            
            if (BDPIsEmptyString([baseData bdp_stringValueForKey:kEventKey_app_version])
                || BDPIsEmptyString([baseData bdp_stringValueForKey:kEventKey_scene])) {
                // 公共参数不全, 这里为了健壮性补齐，后续考虑重构接口来彻底解决该问题
                
                BDPCommon *common = BDPCommonFromUniqueID(uniqueID);
                
                // TODO: 新容器架构上线后将删除的逻辑
                if (!common && BDPIsEmptyString(appTypeString)) {
                    // 目前只有这两个应用有接入 BDPCommon，后续考虑重构接口来彻底解决该问题
                    if (!common) {
                        common = [self tryGetAppCommon:appID appType:BDPTypeNativeApp];
                    }
                }
                
                if (common) {
                    self._uniqueID = common.uniqueID;
                    [self applyAppCommon:common];
                } else {
                    self._uniqueID = uniqueID;
                }
            }
        }
        
        // 如果 trace_id 为空则设置 trace_id
        if (self._uniqueID && BDPIsEmptyString([baseData bdp_stringValueForKey:OPMonitorEventKey.trace_id])) {
            self.tracing([BDPTracingManager.sharedInstance getTracingByUniqueID:self._uniqueID]);
        }
    }
    
    return [super flush];
}

/// 重写方法增加 tracing 类型检查
- (OPMonitorEvent * _Nonnull (^)(id<OPTraceProtocol> trace))tracing {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(id<OPTraceProtocol> trace) {
        typeof(weakSelf) self = weakSelf;
        if (self && trace) {
            if (![trace conformsToProtocol:@protocol(OPTraceProtocol)]) {
                // 防止有人误用
                NSAssert(NO, @"tracing(BDPTracing) only accept a <OPTraceProtocol> instance. Please use bdpTracing(BDPTracing *) for BDPTracing. event:%@ file:%@ function:%@ line:%@", self.name, self.fileName, self.funcName, @(self.line));
                if([trace isKindOfClass:[NSString class]]) {
                    super.tracing([[BDPTracing alloc] initWithTraceId:trace]);
                }
            } else {
                super.tracing(trace);
            }
        }
        return self;
    };
}

- (BDPMonitorEvent * _Nonnull (^ _Nonnull)(BDPUniqueID * _Nonnull uniqueID))setUniqueID {
    __weak typeof(self) weakSelf = self;
    return ^BDPMonitorEvent *(BDPUniqueID * _Nullable uniqueID) {
        typeof(weakSelf) self = weakSelf;
        if (self && uniqueID) {
            self.addCategoryValue(kEventKey_app_id, uniqueID.appID);
            self.addCategoryValue(kEventKey_identifier, uniqueID.identifier);
            self.addCategoryValue(kEventKey_app_type, OPAppTypeToString(uniqueID.appType));
            self.addCategoryValue(kEventKey_version_type, OPAppVersionTypeToString(uniqueID.versionType));
            if (uniqueID.appType == OPAppTypeBlock) {
                self.addCategoryValue(kEventKey_block_id, [OPResolveDependenceUtil blockIDWithID:uniqueID]);
                self.addCategoryValue(kEventKey_block_host, [OPResolveDependenceUtil hostWithID:uniqueID]);
                self.addCategoryValue(kEventKey_use_merge_js_sdk, @"1");
                self.addCategoryValue(kEventKey_app_version, [OPResolveDependenceUtil packageVersionWithID:uniqueID]);
            }
        }
        [self addFlushTaskWithName:@"setUniqueID" task:^(OPMonitorEvent *monitor) {
            if (monitor && uniqueID) {
                monitor.addCategoryValue(kEventKey_new_container, @"1");
                
                if ([monitor isKindOfClass:[BDPMonitorEvent class]]) {
                    ((BDPMonitorEvent *)monitor)._uniqueID = uniqueID;
                }
                // 设置App公共参数
                BDPCommon *common = BDPCommonFromUniqueID(uniqueID);
                if (common) {
                    [monitor applyAppCommon: common];
                }
            }
        }];
        return self;
    };
}

// TODO: 新容器上线后删除的逻辑
- (BDPCommon *)tryGetAppCommon:(NSString *)appID appType:(BDPType)appType {
    BDPUniqueID *uniqueID = [BDPUniqueID uniqueIDWithAppID:appID
                                                identifier:nil
                                               versionType:OPAppVersionTypeCurrent
                                                   appType:appType];
    return BDPCommonFromUniqueID(uniqueID);
}

@end

@implementation OPMonitorEvent (BDPExtensionPrivate)

- (void)applyAppCommon:(BDPCommon *)common {
    if (common) {
        // 如果版本为空，设置版本
        NSString *appVersion = common.model.version;
        if (!BDPIsEmptyString(appVersion)) {
            self.addCategoryValue(kEventKey_app_version, appVersion);
        }
        //设置应用版本不为空，则设置应用版本
        NSString *applicationVersion = common.model.appVersion;
        if (!BDPIsEmptyString(applicationVersion)) {
            self.addCategoryValue(kEventKey_application_version, applicationVersion);
        }
        
        // 增加compile_version通用字段埋点
        NSString *compileVersion = common.model.compileVersion;
        if (!BDPIsEmptyString(compileVersion)) {
            self.addCategoryValue(kEventKey_compile_version, compileVersion);
        }

        // 设置场景值
        NSString *scene = common.schema.scene;
        if (!BDPIsEmptyString(scene)) {
            self.addCategoryValue(kEventKey_scene, scene);

            NSString *sub_scene = common.schema.subScene;
            if (!BDPIsEmptyString(sub_scene)) {
                self.addCategoryValue(kEventKey_sub_scene, sub_scene);
            }
        }
    }
}

@end

@implementation OPMonitorEvent (BDPExtension)

- (OPMonitorEvent * _Nonnull (^_Nonnull)(id<OPTraceProtocol> trace))bdpTracing {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(id<OPTraceProtocol> trace) {
        typeof(weakSelf) self = weakSelf;
        return self.tracing(trace);
    };
}

@end
