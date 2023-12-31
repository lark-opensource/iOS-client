//
//  CJPayFeatureCollectorManager.h
//  CJPaySandBox
//
//  Created by wangxinhua on 2023/5/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN



@class CJPayBaseSafeFeature;
@class CJPayFeatureCollectContext;

@protocol CJPayFeatureRecord <NSObject>

/// 记录特征信息，支持持久化存储
/// - Parameter feature: 具体特征信息
- (void)recordFeature:(CJPayBaseSafeFeature *)feature;

/// 获得所有符合条件的特征
/// - Parameters:
///   - name: 特征名称
///   - conditionBlock: 条件判断block
- (NSArray<CJPayBaseSafeFeature *> *)allFeaturesFor:(NSString *)name conditionBlock:(BOOL(^)(CJPayBaseSafeFeature *))conditionBlock;

/// 获得当前特征存储的上下问信息
- (CJPayFeatureCollectContext *)getContext;

@end

@protocol CJPayFeatureCollector <NSObject>

@property (nonatomic, weak) id<CJPayFeatureRecord> recordManager;
/// 开始收集特征
- (void)beginCollect;

/// 停止收集特征
- (void)endCollect;

@optional
/// 意图特征
- (NSDictionary *)buildIntentionParams;

/// 设备特征
- (NSDictionary *)buildDeviceParams;

@end


/// 特征上下文信息
@interface CJPayFeatureCollectContext: NSObject

@property (nonatomic, copy) NSString *page;

@end


@interface CJPayFeatureCollectorManager : NSObject

/// 注册特征收集器
/// - Parameter collector: 特征收集器
- (void)registerCollector:(id<CJPayFeatureCollector>)collector;

/// 进入了某个场景
/// - Parameter sceneName: 场景名称
- (void)enterScene:(NSString *)sceneName;

/// 退出了某个场景
/// - Parameter sceneName: 场景名称
- (void)leaveScene:(NSString *)sceneName;

/// 生成特征相关请求参数
- (NSDictionary *)buildFeaturesParams;

@end

NS_ASSUME_NONNULL_END
