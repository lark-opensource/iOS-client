//
//  ACCKaraokeDataHelperProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/3/22.
//

@class IESEffectModel;

typedef NS_ENUM(NSInteger, ACCKaraokeDataType) {
    ACCKaraokeDataTypeVideoMVTemplate = 0, // MV视频模板
    ACCKaraokeDataTypeIMGMVTemplate = 1, // MV图片模板
    ACCKaraokeDataTypeLyricStyle = 2, // 歌词样式
    ACCKaraokeDataTypeLyricInfoStyle = 3, // 歌曲信息样式
    ACCKaraokeDataTypeLyricFont = 4, //字体
    ACCKaraokeDataTypeLyricSoundEffect = 5 // 混响
};

@protocol ACCKaraokeDataHelperProtocol <NSObject>

+ (BOOL)karaokeLyricModelValid:(IESEffectModel *)model;
// 根据id获取缓存model
+ (IESEffectModel *)effectForEffectId:(NSString *)effectId;
// 根据type获取对应的默认id
+ (NSString *)effectIdForDataType:(ACCKaraokeDataType)type;
// 拉取歌词贴纸相关资源，回调为歌名和字体资源
+ (void)fetchRelatedInfos:(IESEffectModel *)sticker completion:(void(^)(IESEffectModel *, IESEffectModel *, BOOL))completion;

@end
