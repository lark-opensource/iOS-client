//
//  LVTemplateDataManager.h
//  LVTemplate
//
//  Created by iRo on 2019/8/11.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "LVModelType.h"
#import "LVMediaDraft.h"
#import "LVAIMattingManager.h"
#import "LVCutSameConsumer.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LVTemplateDataManagerError) {
    LVTemplateDataManagerErrorCreateDraftPath = 10000,
    LVTemplateDataManagerErrorUnzipFile,
    LVTemplateDataManagerErrorParseDraft,
    LVTemplateDataManagerErrorCopyResource,
    LVTemplateDataManagerErrorPayloadNotExists,
    LVTemplateDataManagerErrorSegmentNotExists,
    LVTemplateDataManagerErrorCropsCountLessThan4,
    LVTemplateDataManagerErrorFetchEffectFailed,
    LVTemplateDataManagerErrorKeyframeCountNotMatch,
};

typedef NS_ENUM(NSUInteger, LVTemplateCartoonOutputType) {
    LVTemplateCartoonOutputTypeUnknown,
    LVTemplateCartoonOutputTypeImage,
    LVTemplateCartoonOutputTypeVideo,
};

@class LVTemplateDataManager;

@protocol LVTemplateDataManagerDelegate <NSObject>

@required
- (void)templateDataManager:(LVTemplateDataManager *)manager didFailureWithErrorCode:(LVTemplateDataManagerError)code withSubErrorCode:(NSError *)subCode;

- (void)templateDataManager:(LVTemplateDataManager *)manager didChangeProcessProgress:(CGFloat)progress;

- (void)templateDataManagerDraftDecodeDidFinish:(LVTemplateDataManager *)manager;

- (void)templateDataManagerDraftProcessDidComplete:(LVTemplateDataManager *)manager;

- (void)templateDataManager:(LVTemplateDataManager *)manager downloadFile:(NSURL *)fileURL completion:(void(^)( NSString * _Nullable path, NSError * _Nullable error))completion;

@end

@class LVPlayerItemSource;

typedef void(^LVTemplateDataManagerProgress)(CGFloat progress);
typedef void(^LVTemplateDataManagerCompletion)(LVTemplateDataManager * _Nonnull manager, NSError * _Nullable error);

@interface LVTemplateDataManager : NSObject

/**
 唯一标示，用来生成文件目录
*/
@property (nonatomic, copy, readonly) NSString *relativePath;

/**
 当前的草稿路径
 */
@property (nonatomic, copy, readonly, nullable) NSString *draftPath;

/**
 当前的草稿
 */
@property (nonatomic, strong, readonly, nullable) LVMediaDraft *draft;

/**
 模板未被替换素材前的原始草稿
 */
@property (nonatomic, strong, readonly, nullable) LVMediaDraft *initialDraft;

/**
 智能抠图
 */
@property (nonatomic, strong, readonly) LVAIMattingManager *mattingManager;

/**
 代理
 */
@property (nonatomic, weak) id<LVTemplateDataManagerDelegate> delegate;

///**
// 初始化
// @param domain 工作域
// @return LVTemplateDataManager
// */
//- (instancetype)initWithDomain:(NSString *)domain;

/**
 初始化
 
 @param draftRelativePath 草稿路径
 @param domain 工作域
 @return LVTemplateDataManager
 */
- (instancetype)initWithDraftRelativePath:(NSString *)draftRelativePath domain:(NSString *)domain;

/**
 清理模板缓存
 */
- (BOOL)clearTemplate;

// ---------------- new logic start --------------------

/**
 初始化
 @param draft 草稿
 */
- (instancetype)initWithDraft:(LVMediaDraft *)draft;


/**
 初始化
 @param domain 工作域
 @param templateURL 模板zip包URL
 */
- (instancetype)initWithDomain:(NSString *)domain templateURL:(NSString *)templateURL;

/**
 异步生成草稿
 */
- (void)setup;

/**
 异步生成草稿
 @param completion 完成回调
 */
- (void)setupWtihCompletion:(LVTemplateDataManagerCompletion _Nullable)completion;

/**
 异步生成草稿
 @param progressBlock 进度回调
 @param completion 完成回调
 */
- (void)setupWtihProgress:(LVTemplateDataManagerProgress _Nullable)progressBlock
               completion:(LVTemplateDataManagerCompletion _Nullable)completion;

/**
 取消生成草稿
 */
- (void)cancel;

/**
 当前草稿资源能否被替换
 */
- (BOOL)replaceIsEnable;

// ---------------- new logic end --------------------

@end

@interface LVTemplateDataManager (LVVideoPayload)

/**
 视频图片

 @param resourceID 图片保存在本地的名字
 @param payloadId 资源标识
 @param imageData 图片数据
 @param imageSize 图片大小
 @param sourceTimeRange 播放时的时间范围
 @param isCartoon 是否带漫画效果
 @param tmpCartoonFilePath 漫画图片路径
 @return 成功/失败
 */
- (BOOL)replaceImageDataAssetWithResourceID:(NSString *)resourceID
                                  payloadID:(NSString *)payloadId
                                  imageData:(NSData * _Nullable)imageData
                                  imageSize:(CGSize)imageSize
                            sourceTimeRange:(CMTimeRange)sourceTimeRange
                         tmpCartoonFilePath:(NSString * _Nullable)tmpCartoonFilePath
                          cartoonOutputType:(LVTemplateCartoonOutputType)cartoonOutputType;

/**
视频图片

@param resourceID 图片保存在本地的名字
@param payloadId 资源标识
@param imagePath 图片路径
@param imageSize 图片大小
@param sourceTimeRange 播放时的时间范围
@return 成功/失败
*/
- (BOOL)replaceImagePathWithResourceID:(NSString *)resourceID
                             payloadID:(NSString *)payloadId
                             imagePath:(NSString *)imagePath
                             imageSize:(CGSize)imageSize
                       sourceTimeRange:(CMTimeRange)sourceTimeRange;

/**
 视频图片

 @param payloadId 资源标识
 @param resourceID 图片保存在本地的名字
 @param image 图片
 @param sourceTimeRange 范围
 @return 成功/失败
 */
- (BOOL)replaceImageAssetWithResourceID:(NSString *)resourceID
                              payloadID:(NSString *)payloadId
                                  image:(UIImage *)image
                        sourceTimeRange:(CMTimeRange)sourceTimeRange;

/**
 正常视频
 
 @param payloadId 资源标识
 @param path 视频地址
 @param sourceTimeRange 范围
 @return 成功/失败
 */

- (BOOL)replaceNormalVideoAssetWithResourceID:(NSString *)resourceID
                              PayloadID:(NSString *)payloadId
                                   path:(NSString *)path
                        sourceTimeRange:(CMTimeRange)sourceTimeRange
                           tmpCartoonFilePath:(NSString * _Nullable)tmpCartoonFilePath
                            cartoonOutputType:(LVTemplateCartoonOutputType)cartoonOutputType;

/**
 视频/倒放视频

 @param payloadId 资源标识
 @param path 视频地址
 @param sourceTimeRange 范围
 @return 成功/失败
 */

- (BOOL)replaceVideoAssetWithResourceID:(NSString *)resourceID
                              PayloadID:(NSString *)payloadId
                                   path:(NSString *)path
                        sourceTimeRange:(CMTimeRange)sourceTimeRange;
/**
 视频/倒放视频

 @param payloadId 资源标识
 @param path 视频地址
 @param sourceTimeRange 范围
 @param tmpCartoonFilePath 漫画图片路径
 @return 成功/失败
 */

- (BOOL)replaceVideoAssetWithResourceID:(NSString *)resourceID
                              PayloadID:(NSString *)payloadId
                                   path:(NSString *)path
                        sourceTimeRange:(CMTimeRange)sourceTimeRange
                     tmpCartoonFilePath:(NSString * _Nullable)tmpCartoonFilePath
                      cartoonOutputType:(LVTemplateCartoonOutputType)cartoonOutputType;

/**
 sourceTimeRange

 @param sourceTimeRange sourceTimeRange
 @param payloadId 资源标识
 @return  成功/失败
 */
- (BOOL)replaceSourceTimeRange:(CMTimeRange)sourceTimeRange
                    payloadID:(NSString *)payloadId;

/**
 
 视频裁剪区域
 
 @param crops 裁剪区域数组
 @param payloadId 资源标识
 @return 成功/失败
 */
- (BOOL)replaceVideoCrops:(NSArray<NSValue *> *)crops
                  payloadID:(NSString *)payloadId;


/**
 视频音量
 
 @param volume 音量
 @param keyframeVolumes 关键帧音量
 @param payloadId 资源标识
 @return 成功/失败
 */
- (BOOL)replaceVideoVolume:(NSInteger)volume keyframeVolumes:(NSArray<NSNumber *> * _Nullable)keyframeVolumes payloadID:(NSString *)payloadId;

/**
 替换视频relativePath

 @param relativePath 资源相对路劲
 @param cartoonImageRelativePath 漫画资源相对路劲
 @param payloadId 资源标识
 @param sourceTimeRange 范围
 @param isVideo 视频/图片
 @return 成功/失败
 */
- (BOOL)replaceRelativePath:(NSString *)relativePath
   cartoonImageRelativePath:(NSString * _Nullable)cartoonImageRelativePath
                  payloadID:(NSString *)payloadId
            sourceTimeRange:(CMTimeRange)sourceTimeRange
                    isVideo:(BOOL)isVideo ;

@end

@interface LVTemplateDataManager (LVTextPayload)

/**
 替换文字

 @param payloadId 资源标识
 @param text 新文字
 @return 成功/失败
 */
- (BOOL)replaceTextWithPayloadID:(NSString *)payloadId
                            text:(NSString *)text;

@end

@interface LVTemplateDataManager (LVDraftTailLeaderPayload)

/**
 替换片尾文字

 @param payloadId 资源标识
 @param text 文字
 @return 成功/失败
 */
- (BOOL)replaceTailLeaderTextWithPayloadID:(NSString *)payloadId
                                      text:(NSString *)text;
@end

@interface LVTemplateDataManager (Keyframe)

/**
 重新计算关键帧时间偏移

 @param segment 具体片段
 @param sourceTimeRange 时间范围
 */
- (void)recalculateKeyframeTimeOffset:(LVMediaSegment *)segment sourceTimeRange:(CMTimeRange)sourceTimeRange;
@end

@interface LVTemplateDataManager (LVDraftAudioPayload)

///**
// 调整单个音频的音量
//
// @param audioID 需要调整的音频ID，在草稿中体现为segmentID
// @param volume 指定的音量
// */
//- (BOOL)setVolumeForAudio:(NSString *)audioID
//               WithVolume:(CGFloat)volume;
//
///**
// 调整全部音频的音量
//
// @param volume 指定的音量
// */
//- (BOOL)setVolumeForAllAudioWithVolume:(CGFloat)volume;
//
///**
// 新增音频
// 构造一个新音频片段放入草稿中
//
// @param asset 音频资源
// @param speed 倍速播放
//
// @return 若成功，返回新构造的音频segmentID作为音频标识给上层
// */
//- (NSString *)addNewAudioWithResourceAsset:(AVURLAsset *)asset
//                           sourceTimeRange:(CMTimeRange)sourceTimeRange
//                                     speed:(CGFloat)speed;

/**
 替换背景音乐
 删除草稿中所有的音轨，然后构造一个新音轨放入草稿中作为新的背景音乐
 
 @param asset 音频资源
 @param sourceTimeRange 范围
 @param speed 倍速播放
 */
- (BOOL)replaceBackgroundMusicWithResourceAsset:(AVURLAsset *)asset
                                sourceTimeRange:(CMTimeRange)sourceTimeRange
                                          speed:(CGFloat)speed;
/**
 禁掉模板所有声音
*/
- (void)muteAllAudio;

/**
 获得模版视频时长
 一键MV需求增加
 
 @return 模版视频时长
 */
- (CMTime)templateDuration;

@end


@interface LVTemplateDataManager (LVCutSameConsumer)

/**
 替换video资源
 */
- (void)replaceVideoAssetWithResourceID:(NSString *)resourceID
                              PayloadID:(NSString *)payloadId
                                   path:(NSString *)path
                        sourceTimeRange:(CMTimeRange)sourceTimeRange
                              nleFolder:(NSString *)nleFolder
                       fromCutSameDraft:(LVMediaDraft *)draft
                                  toNLE:(NLEModel_OC *)nleModel;

/**
 选择video range
 */
- (void)replaceSourceTimeRange:(CMTimeRange)sourceTimeRange
                     payloadID:(NSString *)payloadId
              fromCutSameDraft:(LVMediaDraft *)draft
                         toNLE:(NLEModel_OC *)nleModel;


/**
 替换image资源
 */
- (void)replaceImagePathWithResourceID:(NSString *)resourceID
                             payloadID:(NSString *)payloadId
                             imagePath:(NSString *)imagePath
                             imageSize:(CGSize)imageSize
                       sourceTimeRange:(CMTimeRange)sourceTimeRange
                             nleFolder:(NSString *)nleFolder
                      fromCutSameDraft:(LVMediaDraft *)draft
                                 toNLE:(NLEModel_OC *)nleModel;

/**
 选择image高光区域
 */
- (void)replaceVideoCrops:(NSArray<NSValue *> *)crops
                payloadID:(NSString *)payloadId
         fromCutSameDraft:(LVMediaDraft *)draft
                    toNLE:(NLEModel_OC *)nleModel;


/**
 替换文字
 */
- (void)replaceTextWithPayloadID:(NSString *)payloadId
                            text:(NSString *)text
                fromCutSameDraft:(LVMediaDraft *)draft
                           toNLE:(NLEModel_OC *)nleModel;

@end



//替换视频素材，内部会拷贝到草稿目录，并修改 LVCutSameVideoMaterial 和NLE
//目前不会判断原草稿目录是否已经存在素材，用uuid 来命名文件
@interface LVTemplateDataManager (NLEModel)

/**
 替换video资源
 */
- (BOOL)nlemodel_replaceVideoAssetWithInfo:(LVCutSameVideoMaterial *)material
                                originPath:(NSString *)originPath
                                      path:(NSString *)path
                           sourceTimeRange:(CMTimeRange)sourceTimeRange
                                 nleFolder:(NSString *)nleFolder
                                     toNLE:(NLEModel_OC *)nleModel;

/**
 选择video range
 */
- (void)nlemodel_replaceSourceTimeRangeWithInfo:(LVCutSameVideoMaterial *)material
                                sourceTimeRange:(CMTimeRange)sourceTimeRange
                                          toNLE:(NLEModel_OC *)nleModel;

/**
 替换image资源
 */
- (BOOL)nlemodel_replaceImagePathWithInfo:(LVCutSameVideoMaterial *)material
                                imagePath:(NSString *)imagePath
                          processFilePath:(NSString *)processFilePath
                                imageSize:(CGSize)imageSize
                          sourceTimeRange:(CMTimeRange)sourceTimeRange
                                nleFolder:(NSString *)nleFolder
                                    toNLE:(NLEModel_OC *)nleModel;

/**
 选择高光区域
 */
- (void)nlemodel_replaceCropsWithInfo:(LVCutSameVideoMaterial *)material
                                Crops:(NSArray<NSValue *> *)crops
                                toNLE:(NLEModel_OC *)nleModel;

/**
 替换文字
 */
- (void)nlemodel_replaceTextWithInfo:(LVCutSameTextMaterial *)material
                                text:(NSString *)text
                               toNLE:(NLEModel_OC *)nleModel;


// 获取多媒体资源封面图
- (UIImage *)nlemodel_coverOfVideoMaterial:(LVCutSameVideoMaterial *)videoMaterial
                                 draftPath:(NSString *)draftPath
                                preferSize:(CGSize)imageSize;

// 获得文字资源对应时刻抽帧图
- (UIImage *)nlemodel_coverOfTextMaterial:(LVCutSameTextMaterial *)textMaterial
                                draftPath:(NSString *)draftPath
                               preferSize:(CGSize)imageSize
                                  withNLE:(NLEModel_OC *)nleModel;

- (void)downloadTemplateRelativeEffectsWithCompletion:(void(^)(BOOL success, NSError *error))completion;


@end

NS_ASSUME_NONNULL_END
