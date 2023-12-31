//
//  LVDraftAudioPayload.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import "LVDraftPayload.h"
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LVDraftAudioSourcePlatformType) {
    LVDraftAudioSourcePlatformTypeUnknown = -1, 
    LVDraftAudioSourcePlatformTypeLibrary, // 曲库
    LVDraftAudioSourcePlatformTypeArtist, // 艺术家开放平台
};

/**
 音频素材解析模型
 */
@interface LVDraftAudioPayload (Interface)
/**
 音乐ID
 */
//@property (nonatomic, copy, nullable) NSString *musicID;

/**
 音频长度
 */
@property (nonatomic, assign) CMTime duration;

/**
 音频名字
 */
//@property (nonatomic, copy) NSString *name;

/**
 音乐分类名字，统计使用
 */
@property (nonatomic, copy) NSString *categoryName;

@property (nonatomic, assign) LVDraftAudioSourcePlatformType sourcePlatformType;

///**
// 动画资源的相对路径
// */
//@property (nonatomic, copy) NSString *relativePath;

/**
 音频文件(录音，提取音乐，音乐)波形数据
 */
//@property (nonatomic, strong, nullable) NSArray<NSNumber *> *wavePoints;

/**
 资源asst
 */
@property (nonatomic, strong) AVURLAsset *asset;

/**
 人声增强资源asset
 */
@property (nonatomic, strong, nullable) AVURLAsset *intensifiesAudio;

/**
 人声增强音频路径
 */
@property (nonatomic, copy, nonnull) NSString *intensifiesAudioRelativePath;

/**
 初始化素材资源
 
 @param type 类型
 @param musicID 音乐ID
 @param asset 资源包
 @return 资源实例
 */
- (instancetype)initWithType:(LVPayloadRealType)type musicID:(NSString *)musicID asset:(AVURLAsset *)asset;

/**
 初始化素材资源
 
 @param type 类型
 @param asset 资源包
 @return 资源实例
 */
- (instancetype)initWithType:(LVPayloadRealType)type asset:(AVURLAsset *)asset;

@end

NS_ASSUME_NONNULL_END
