//
//  AWEStickerLyricFontManager.h
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2019/10/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;

extern NSString * const AWEStickerLyricFontPanelStr;
extern NSString * const AWEStickerLyricFontExtraKey;

@interface AWEStickerLyricFontManager : NSObject

// 异步预下载歌词字体资源
+ (void)downloadLyricFontIfNeeded;

+ (IESEffectModel * _Nullable)effectModelWithFontName:(NSString *)fontName;

+ (void)fetchLyricFontResourceWithFontName:(NSString *)fontName completion:(void (^)(NSError *error, NSString *filePath))completion;

+ (nullable NSString *)formatFontDicWithJSONStr:(NSString *)strExtra;

@end

NS_ASSUME_NONNULL_END
