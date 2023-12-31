//
//  LVDraftVideoPayload.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import "LVDraftPayload.h"
#import "LVVideoCropInfo.h"

NS_ASSUME_NONNULL_BEGIN

/*
 @interface LVDraftVideoPayload : LVDraftPayload
 @property (nonatomic, nullable, copy) NSString *categoryID;
 @property (nonatomic, nullable, copy) NSString *categoryName;
 @property (nonatomic, strong)         LVVideoCropInfo *crop;
 @property (nonatomic, assign)         LVCropRatio cropRatio;
 @property (nonatomic, assign)         double cropScale;
 @property (nonatomic, assign)         NSInteger durationMilliSeconds;
 @property (nonatomic, assign)         NSInteger height;
 @property (nonatomic, nullable, copy) NSString *intensifiesAudioRelativePath;
 @property (nonatomic, nullable, copy) NSString *intensifiesRelativePath;
 @property (nonatomic, nullable, copy) NSString *materialID;
 @property (nonatomic, nullable, copy) NSString *materialName;
 @property (nonatomic, copy)           NSString *relativePath;
 @property (nonatomic, nullable, copy) NSString *reverseIntensifiesRelativePath;
 @property (nonatomic, nullable, copy) NSString *reverseRelativePath;
 @property (nonatomic, assign)         NSInteger width;
 @end
 */

/**
 智能抠图对应生效
EnableFunction  启用功能
ApplyEffect 应用效果
 */
typedef NS_OPTIONS(NSUInteger, LVVideoAIMattingMask) {
    LVVideoAIMattingMaskNone  = 0,
    LVVideoAIMattingMaskEnableFunction = 1 << 0,
    LVVideoAIMattingMaskApplyEffect = 1 << 1,
};

@interface LVDraftVideoPayload(Interface)
/**
 媒体资源唯一标识
 */
@property (nonatomic, copy) NSString *resourceIdentifier;

/**
 资源asset
 */
@property (nonatomic, strong, nullable) AVURLAsset *video;

/**
 倒放资源asset
 */
@property (nonatomic, strong, nullable) AVURLAsset *reversedVideo;

/**
 人声增强资源asset
 */
@property (nonatomic, strong, nullable) AVURLAsset *intensifiesVideo;

/**
 人声增强倒放资源asset
 */
@property (nonatomic, strong, nullable) AVURLAsset *reverseIntensifiesVideo;

/**
 人声增强后的音频asset
 */
@property (nonatomic, strong, nullable) AVURLAsset *intensifiesAudio;

/**
 图片资源asst
 */
@property (nonatomic, strong, nullable) AVAsset *photoAsset;


/// 玩法视频 asset
@property (nonatomic, strong, nullable) AVURLAsset *gameplayVideo;

/**
 视频素材分类ID
 */
//@property (nonatomic, copy, nullable) NSString *categoryId;

/**
 视频素材分类名
 */
//@property (nonatomic, copy, nullable) NSString *categoryName;

/**
 视频素材ID
 */
//@property (nonatomic, copy, nullable) NSString *materialId;

/**
 视频素材名称
 */
//@property (nonatomic, copy, nullable) NSString *materialName;

/**
 图片尺寸
 */
@property (nonatomic, assign) CGSize size;

/**
 视频相对草稿路径
 */
//@property (nonatomic, copy, nonnull) NSString *relativePath;
//
/**
 倒放视频的路径
 */
@property (nonatomic, copy, nonnull) NSString *reverseRelativePath;

/**
 人声增强视频相对草稿路径
 */
@property (nonatomic, copy, nonnull) NSString *intensifiesRelativePath;

/**
 人声增强倒放视频的路径
 */
@property (nonatomic, copy, nonnull) NSString *reverseIntensifiesRelativePath;

/**
 人声增强音频路径
 */
@property (nonatomic, copy, nonnull) NSString *intensifiesAudioRelativePath;

/*
 导出模板时挂载的封页路径
*/
@property (nonatomic, copy, nonnull) NSString *coverPath;

// 系统相册的路径，兜底用
@property (nonatomic, copy, nullable) NSString *mediaImagePath;

///**
// 视频区域
// */
//@property (nonatomic, strong) LVVideoCropInfo *crop;

///**
//视频裁剪比例
//*/
//@property (nonatomic, assign) LVVideoCropRatio cropRatio;

///**
//视频裁剪之后的适配画布的scale值
//*/
//@property (nonatomic, assign) CGFloat cropScale;

/**
 视频素材初始化
 
 @param asset 资源
 @param type 类型
 @param resourceID 资源ID
 @param pathExtension 文件后缀
 */
- (instancetype)initWithAsset:(nullable AVURLAsset *)asset
                         type:(LVPayloadRealType)type
                   resourceID:(NSString *)resourceID
                pathExtension:(NSString *)pathExtension;

/**
 更新视频资源
 
 @param video 视频资源
 @param isReverse 是否倒放
 */
- (void)updateVideo:(AVURLAsset *)video isReverse:(BOOL)isReverse;

/**
 更新人声增强视频资源
 
 @param video 视频资源
 @param isReverse 是否倒放
 */
- (void)updateAudioStrongVideo:(AVURLAsset *)video isReverse:(BOOL)isReverse;

/**
 人声增强音频
 
 @param audio 音频资源
 */
- (void)updateAudio:(AVURLAsset *)audio;

/**
 更新图片资源
 
 @param photo 视频资源
 @param size 更新尺寸
 */
- (void)updatePhoto:(NSString *)photo size:(CGSize)size;


- (void)updateGamePlayAsset;

/**
资源的裁剪尺寸
*/
- (CGSize)cropSize;

@end

@interface LVDraftVideoPayload (FilePath)

/**
 视频绝对路径
 */
- (NSString *)videoAbsolutePath;

/**
 【倒放】视频绝对路径
 */
- (NSString *)reversedVideoAbsolutePath;

/**
 【人声增强】视频绝对路径
 */
- (NSString *)intensifiesVideoAbsolutePath;

/**
 【人声增强】【倒放】视频绝对路径
 */
- (NSString *)reverseIntensifiesVideoAbsolutePath;

/**
 人声增强音频绝对路径
 */
- (NSString *)intensifiesAudioAbsolutePath;

// 玩法资源绝对路径
- (NSString *)gameplayAbsolutePath;

@end

@interface LVDraftVideoPayload (AlbumIdentifier)
/**
 生成可以标识来自相册格式的identifier（）
*/
+ (NSString *)generateAlbumResourceIdentifierWithIdentifier:(NSString *)identifier modificationDate:(nullable NSDate *)modificationDate;
+ (BOOL)isValidAlbumResourceIdentifier:(NSString *)resourceIdentifier;
@end


@interface LVDraftVideoPayload (ResourceExtraTypeOption)
/// 视频/图片全部对应的附加效果类型
@property (nonatomic, readonly, assign) LVVideoResourceExtraTypeOption appliedResourceExtraTypeOption;

/// 判断是否应用某种附加效果
- (BOOL)isAppliedResourceExtraType:(LVVideoResourceExtraTypeOption)option;

/// 累加附加效果类型
- (void)addResourceExtraType:(LVVideoResourceExtraTypeOption)option;

/// 移除附加效果类型
- (void)removeResourceExtraType:(LVVideoResourceExtraTypeOption)option;

/// 重置附加效果类型
- (void)resetResourceExtraType;
@end


@interface LVDraftVideoPayload (AIMatting)
@property (nonatomic, readonly) LVVideoAIMattingMask aiMattingMask;
@property (nonatomic, readonly) BOOL aiMattingMaskEnableFunction;
@property (nonatomic, assign) BOOL aiMattingMaskApplyEffect;
@property (nonatomic, assign) BOOL aiMattingEnabled;
@end

NS_ASSUME_NONNULL_END
