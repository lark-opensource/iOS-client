//
//  EffectPlatform+Search.h
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/5/31.
//

#import "EffectPlatform.h"
#import "IESSearchEffectsModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^fetchSearchRecommendWordsCompletion) (NSError * _Nullable error, NSString * _Nullable searchTips, NSArray<NSString *> * _Nullable recommendWords);
typedef void(^fetchSearchEffectsCompletion) (NSError * _Nullable error, IESSearchEffectsModel * _Nullable searchEffectsModel);

@interface EffectPlatform (Search)

/**
 猜你想搜
 @param panel 面板
 @param category 分类
 @param extraParameters 额外参数
 @param completion  回调返回搜索框文案和搜索推荐词列表
 */
- (void)fetchSearchRecommendWordsWithPanel:(NSString *)panel
                                  category:(NSString *)category
                           extraParameters:(NSDictionary *)extraParameters
                                completion:(fetchSearchRecommendWordsCompletion _Nullable)completion;

/**
 特效搜索
 @param keyword  查询词
 @param searchID 搜索用，翻页时把上一页的search_id 带上，第一次查询传0即可
 @param completion 回调返回特效列表和分页相关的属性
 */
- (void)fetchSearchEffectsWithKeyWord:(NSString *)keyword
                             searchID:(NSString *)searchID
                           completion:(fetchSearchEffectsCompletion _Nullable)completion;

/**
 特效搜索
 @param keyword  查询词
 @param searchID 搜索用，翻页时把上一页的search_id 带上，第一次查询传0即可
 @param cursor 开始位置
 @param pageCount 数量
 @param extraParameters 额外参数
 @param completion  回调返回特效列表和分页相关的属性
 */
- (void)fetchSearchEffectsWithKeyWord:(NSString *)keyword
                             searchID:(NSString *)searchID
                               cursor:(NSInteger)cursor
                            pageCount:(NSInteger)pageCount
                      extraParameters:(NSDictionary *)extraParameters
                           completion:(fetchSearchEffectsCompletion _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
