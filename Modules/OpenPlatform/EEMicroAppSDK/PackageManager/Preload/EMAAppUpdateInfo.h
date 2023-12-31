//
//  EMAAppUpdateInfo.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/11/14.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPBaseJSONModel.h>
#import <OPFoundation/BDPUniqueID.h>

/// meta_push_hit中新增字段'intercepted'的可选值
/// https://bytedance.feishu.cn/docx/doxcnUwrkhSQM8Vh4yS4iknlZSx
typedef NS_ENUM(NSUInteger, OPPreInstallInterceptedType) {
    OPPreInstallInterceptedCached = 0,
    OPPreInstallInterceptedNetworkUnavailable = 1,
    OPPreInstallInterceptedNotNeedUpdate = 2,
    OPPreInstallInterceptedServerForceUpdate = 3,
    OPPreInstallInterceptedSettingForceUpdate = 4,
    OPPreInstallInterceptedNotWifiAllow = 5,
    OPPreInstallInterceptedExceedMaxUpdateTimes = 6,
    OPPreInstallInterceptedExceedMaxCountPerDay = 7,
    OPPreInstallInterceptedCustom = 100
};

/// meta_push_hit中'新增'source_from'字段可选值
/// https://bytedance.feishu.cn/docx/doxcnUwrkhSQM8Vh4yS4iknlZSx
typedef NS_ENUM(NSInteger, OPMetaHitSourceFromType) {
    OPMetaHitSourceFromUnknown = 0,
    OPMetaHitSourceFromPush = 1,
    OPMetaHitSourceFromPull = 2,
};

NS_ASSUME_NONNULL_BEGIN
@protocol EMAAppUpdateInfo;
@interface EMAAppUpdateInfo : BDPBaseJSONModel

@property (nonatomic, copy) NSString *app_id;
@property (nonatomic, copy) NSString *app_version;
@property (nonatomic, assign) NSInteger app_version_code;
@property (nonatomic, assign) BOOL need_clear_cache;
@property (nonatomic, assign) BOOL need_update;
@property (nonatomic, assign) BOOL force_update;
@property (nonatomic, assign) NSUInteger max_update_times;
@property (nonatomic, copy) NSString *strategy_version;
@property (nonatomic, assign) NSInteger priority;
@property (nonatomic, assign) NSUInteger updated_times;
@property (nonatomic, assign) NSUInteger update_failed_times;    // 连续更新请求失败次数
@property (nonatomic, assign) NSUInteger max_update_failed_times; // 最大连续更新请求失败次数（默认值3）
@property (nonatomic, copy) NSString *ext_type; //标记是否是小程序还是离线包【 gadget/ web_offline】
@property (nonatomic, strong) NSArray <EMAAppUpdateInfo>* extensions; //新数据嵌套的 appInfo 信息，可包含H5离线包类型
@property (nonatomic, strong) NSNumber *sourceFrom; // 数据来源(不是下发的,是本地赋值)

- (BDPUniqueID *)uniqueID;

/// 提供给Swift调用. 其内部还是调用JSONModel中的+ (NSMuteableArray *)arrayOfModelsFromDictionaries:error: 方法
+ (NSArray *)arrayOfAppUpdateInfoFromDictionaries:(NSArray *)array error:(NSError **)err;

@end

NS_ASSUME_NONNULL_END
