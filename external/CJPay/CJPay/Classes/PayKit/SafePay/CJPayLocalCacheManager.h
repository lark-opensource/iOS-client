//
//  CJPayLocalCacheManager.h
//  CJPaySandBox
//
//  Created by wangxinhua on 2023/5/20.
//

#import <Foundation/Foundation.h>
#import "CJPaySafeFeatures.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayLocalCacheManager : NSObject


/// 初始化的时候，从本地缓存加载特征
- (void)loadCache;
/// 存储特征到内存中，只有特征的属性needPersistence  为 YES时，才会真正的缓存
/// - Parameter feature: 具体特征信息
- (BOOL)appendFeature:(CJPayBaseSafeFeature *) feature;
- (BOOL)appendFeatures:(NSArray<CJPayBaseSafeFeature *> *)features;

/// 查询符合特定条件的特征
/// - Parameters:
///   - name: 特征类型
///   - conditionBlock: 条件限制
- (NSArray<CJPayBaseSafeFeature *> *)allFeaturesFor:(NSString *)name  conditionBlock:(nonnull BOOL (^)(CJPayBaseSafeFeature * _Nonnull))conditionBlock;

/// 同步特征信息到缓存中
- (BOOL)synchronize;

@end

NS_ASSUME_NONNULL_END
