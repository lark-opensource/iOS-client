//
//  AWEStickerLyricStyleManager.h
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2019/10/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const AWEStickerLyricStylePanelStr;// 歌词样式Panel
extern NSString * const AWEStickerKaraokeLyricStylePanelStr;// K歌歌词样式Panel
extern NSString * const AWEStickerKaraokeAudioBGPanelName;// K歌背景样式Panel
extern NSString * const AWEStickerKaraokeAudioEffectPanelName;// K歌音效样式Panel
extern NSString * const AWEKaraokeLyricFontNameId;
extern NSString * const AWEKaraokeLyricInfoStyleKey;
extern NSString * const AWELyricStyleDefaultColorKey;

@class IESEffectModel;

@interface AWEStickerLyricStyleManager : NSObject

+ (IESEffectModel * _Nullable)cachedEffectModelForEffectID:(NSString *)effectID panel:(NSString *)panel;

+ (void)fetchOrQueryCachedLyricRelatedEffectList:(NSString *)panel completion:(void (^)(NSError *, NSArray<IESEffectModel *> *))completion;

@end

NS_ASSUME_NONNULL_END
