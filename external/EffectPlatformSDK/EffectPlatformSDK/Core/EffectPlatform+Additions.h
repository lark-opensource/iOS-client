//
//  EffectPlatform+Additions.h
//  EffectPlatformSDK
//
//  Created by lixingdong on 2019/10/15.
//

#import "EffectPlatform.h"
NS_ASSUME_NONNULL_BEGIN
@interface EffectPlatform (Additions)

- (EffectPlatform *)initWithAccessKey:(NSString *)accessKey;

- (void)configAccessKey:(NSString *)accessKey;

/**
 缓存特效
 
 @param effect 特效
 */
- (void)saveCacheWithEffect:(IESEffectModel *)effect;

/**
 缓存的特效
 
 @param effectId 特效Id
 @return 缓存的特效 model， 若无返回 nil
 */
- (IESEffectModel *)cachedEffectOfEffectId:(NSString *)effectId;

/**
缓存的特效

@param panel 面板标识
@return 缓存的特效列表 model， 若无返回 nil
*/
- (IESEffectPlatformResponseModel *)cachedEffectsOfPanel:(NSString *)panel;

/**
 缓存的特效
 
 @param panel 面板标识
 @param category 分类标识
 @return 缓存的特效列表 model， 若无返回 nil
 */
- (IESEffectPlatformNewResponseModel *)cachedEffectsOfPanel:(NSString *)panel category:(NSString *)category;

/**
检查本地缓存的特效列表与服务器的是否一致

@param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
@param completion 检查回调，needUpdate 为 YES 的情况下需要更新列表
*/
- (void)checkEffectUpdateWithPanel:(NSString *)panel completion:(void (^)(BOOL needUpdate))completion;

/**
 检查本地缓存的特效列表与服务器的是否一致
 
 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param category 分类名称
 @param completion 检查回调，needUpdate 为 YES 的情况下需要更新列表
 */
- (void)checkEffectUpdateWithPanel:(NSString *)panel
                          category:(NSString *)category
                        completion:(void (^)(BOOL needUpdate))completion;

/**
下载特效列表

@param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
@param completion 下载回调， 错误码参见 HTSEffectDefines
*/
- (void)downloadEffectListWithPanel:(NSString *)panel
                         completion:(EffectPlatformFetchListCompletionBlock)completion;

/**
 获取某个分类下的特效列表（支持分页）
 
 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param category 分类名称
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
- (void)downloadEffectListWithPanel:(NSString *)panel
                           category:(NSString *)category
                          pageCount:(NSInteger)pageCount
                             cursor:(NSInteger)cursor
                    sortingPosition:(NSInteger)position
                         completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;

/**
 下载特效
 
 @param effectModel 特效 model
 @param progressBlock 进度回调，返回进度 0~1
 @param completion 下载成功回调， 错误码参见 HTSEffectDefines
 */
- (void)downloadEffect:(IESEffectModel *)effectModel
              progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
            completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion;

- (void)downloadEffectListWithEffectIDS:(NSArray<NSString *> *)effectIDs
                             completion:(void (^)(NSError *_Nullable error, NSArray<IESEffectModel *> *_Nullable effects))completion;

/**
根据resourceIds下载特效列表

@param resourceIds 资源ids
@param panel 面板
@param completion 下载回调， 错误码参见 HTSEffectDefines
*/
- (void)downloadEffectListWithResourceIds:(NSArray<NSString *> *)resourceIds
                                    panel:(NSString *)panel
                               completion:(void (^)(NSError *_Nullable error, NSArray<IESEffectModel *> *_Nullable effects))completion;

/**
 根据url请求返回json数据
 */
- (void)requestWithURLString:(NSString *)urlString
                  parameters:(NSDictionary *)parameters
                      cookie:(NSString * _Nullable)cookie
                  httpMethod:(NSString *)httpMethod
                  completion:(nonnull void (^)(NSError * _Nullable, NSDictionary * _Nullable))completion;


- (NSArray<IESEffectModel *> *)effectsFromArrayJson:(NSArray *)jsonDict  
                                     withURLPrefixs:(NSArray<NSString *> *)urlPrefixs
                                              error:(NSError ** _Nullable)error;

@end
NS_ASSUME_NONNULL_END
