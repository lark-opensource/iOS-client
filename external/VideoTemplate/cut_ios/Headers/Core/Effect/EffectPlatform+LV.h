//
//  EffectPlatform+LV.h
//  LVResourceDownloader
//
//  Created by xiongzhuang on 2019/12/14.
//

#import <EffectPlatformSDK/EffectPlatform+Additions.h>
#import "LVEffectDownloadProxy.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LVEffectErrorType) {
    LVEffectErrorTypeVerifyFontMD5Failed = 10001, // 字体MD5校验失败
    LVEffectErrorTypeReachTryMaxCount = 10002, // 达到下载的限制
};

typedef void(^LVEffectPlatformDownloadProgressBlock)(CGFloat progress, NSInteger tryCount);
typedef void(^LVEffectPlatformDownloadCompletionBlock)(NSError *_Nullable error, NSString  *_Nullable filePath, NSInteger tryCount);


/**
 Effect资源包的校验器
 */
@protocol LVEffectValidator<NSObject>

- (NSError * _Nullable)verifyEffectModel:(IESEffectModel *)effectModel;

@end

@interface EffectPlatform (LV)

/**
 下载特效
 
 @param effectModel 特效 model
 @param tryMaxCount 尝试下载的最大次数
 @param progressBlock 进度回调，返回进度 0~1
 @param completion 下载成功回调， 错误码参见 HTSEffectDefines
 */
- (void)lv_downloadEffect:(IESEffectModel *)effectModel
              tryMaxCount:(NSInteger)tryMaxCount
                validator:(id<LVEffectValidator> _Nullable)validator
                 progress:(LVEffectPlatformDownloadProgressBlock _Nullable)progressBlock
               completion:(LVEffectPlatformDownloadCompletionBlock _Nullable)completion;


/// 下载模型
/// @param modelNames 算法名:[模型名1,模型名2...]
/// @param completion 下载成功回调
+ (void)lv_fetchModelNames:(NSDictionary<NSString *,NSArray<NSString *> *> *)modelNames
                completion:(void (^)(BOOL success, NSError *_Nullable error))completion;


/// 查询缓存中模型名对应的模型信息
/// @param modelNames 算法名:[模型名1,模型名2...]
+ (NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *)lv_modelInfosOfModelNames:(NSDictionary<NSString *,NSArray<NSString *> *> *)modelNames;

@end

@interface IESEffectModel (LV)

/**
 附加信息
 */
- (NSDictionary * _Nullable)lv_extraDictionary;


/**
 附加信息
 */
- (NSDictionary * _Nullable)lv_sdkExtraDictionary;
@end

@interface IESEffectModel (LVFont)
/**
 下载的字体文件是否有效
 */
- (BOOL)lv_fontFileIsValid;

@end

@interface LVFontEffectValidator: NSObject <LVEffectValidator, LVEffectValidateDelegate>

@end

NS_ASSUME_NONNULL_END
