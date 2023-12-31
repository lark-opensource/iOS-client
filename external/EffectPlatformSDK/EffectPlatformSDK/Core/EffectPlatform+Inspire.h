//
//  EffectPlatform+Inspire.h
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/10/9.
//

#import "EffectPlatform.h"
#import "IESEffectTopListResponseModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface EffectPlatform (Inspire)

/**
 特效榜单
 @param panel 面板
 @param extraParameters 额外的请求参数
 @param completion 回调返回effect列表和关联effect
 */
- (void)fetchTopListEffectsWithPanel:(NSString *)panel
                     extraParameters:(NSDictionary * _Nullable)extraParameters
                          completion:(void(^)(NSError * _Nullable error,
                                              IESEffectTopListResponseModel * _Nullable responseModel))completion;

/**
 特效相关的视频推荐(非Loki接口，抖音业务接口)
 @param requestURL 抖音业务的请求域名
 @param categoryID inspiration分类id
 @param count 个数
 @param extraParameters 额外的参数
 @param completion 回调返回effect列表
 */
- (void)fetchRecommendInspiredEffectsWithRequestURL:(NSString *)requestURL
                                           category:(NSInteger)categoryID
                                              count:(NSInteger)count
                                    extraParameters:(NSDictionary * _Nullable)extraParameters
                                         completion:(void(^)(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects))completion;

@end

NS_ASSUME_NONNULL_END
