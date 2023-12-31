//
//  EffectPlatform+AlgorithmModel.h
//  Pods
//
//  Created by 琨王 on 2019/3/6.
//

#import "EffectPlatform.h"

NS_ASSUME_NONNULL_BEGIN

typedef char *_Nullable (*platformsdk_resource_finder)(void *, const char *, const char *);

@interface EffectPlatform (AlgorithmModel)

#if !TARGET_IPHONE_SIMULATOR
/**
 !!!!! 注意 ！！！！
 业务层务必调用 IESVideoEditor 中 IESMMParamModule 的 setResourceFinder 方法
 或者在创建 Effect 实例的时候注入这个 finder
 */
+ (platformsdk_resource_finder)getResourceFinder API_DEPRECATED_WITH_REPLACEMENT("[[IESEffectManager manager] getResourceFinder]", ios(8.0, 13.7));
#endif
/**
 启动模型下发模块
 
 @param excludePattern AB 用，业务端传入假装本地没有的名单，完成模型 比如 "*tt_catbody*|*tt_petbody*"
 */
+ (void)setUpAlgorithmModelWithExcludePattern:(NSString *)excludePattern API_DEPRECATED("This method was deprecated, please remove the calling.", ios(8.0, 13.7));

/**
 启动模型下发模块
 
 @param excludePattern AB 用，业务端传入假装本地没有的名单，完成模型 比如 "*tt_catbody*|*tt_petbody*"
 @param downloadModels 是否立即下载模型
 */
+ (void)setUpAlgorithmModelWithExcludePattern:(NSString *)excludePattern downloadModels:(BOOL)downloadModels API_DEPRECATED("This method was deprecated, please remove the calling.", ios(8.0, 13.7));

/**
 设置是否自动下载模型
 @param autoDownloadAlgorithmModel 是否自动下载
 */
+ (void)setAutoDownloadAlgorithmModel:(BOOL)autoDownloadAlgorithmModel API_DEPRECATED("This method was deprecated, please remove the calling.", ios(8.0, 13.7));


/**
 检测EffectSDK的版本升级
 */
+ (void)checkEffectSDKVersionUpdate API_DEPRECATED("This method was deprecated, please remove the calling.", ios(8.0, 13.7));

/**
 设置算法模型下载的回调
 可选（用于端监控）

 @param completion 回调
 */
+ (void)setAlgorithmModelDownloadCompletionBlock:(void (^)(BOOL success,
                                                           NSString *names,
                                                           NSError *error,
                                                           NSTimeInterval processTime))completion API_DEPRECATED("This method was deprecated, please remove the calling.", ios(8.0, 13.7));


/**
 设置下载下来的算法模型被使用过的回调
 可选（用于端监控）
 
 @param completion 回调
 */
+ (void)setAlgorithmModelUseBlock:(void (^)(BOOL isFound,
                                            NSString *modelName,
                                            NSString *modelShortName,
                                            NSString *version,
                                            NSInteger sizeType, 
                                            NSString *downloadedModels))completion API_DEPRECATED("This method was deprecated, please remove the calling.", ios(8.0, 13.7));


@end

NS_ASSUME_NONNULL_END
