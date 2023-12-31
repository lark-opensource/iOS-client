//
//  ACCInteractionStickerFontHelper.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/8/20.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCCustomFontProtocol.h>

/*
 * customer fonts for interaction stickers, reuse text sticker's fonts temporary，and
 * will change to new 'effect pannel' for these stickers later
 *
 * for feature: mention and hashtag sticker and
 * will add POI and other stickers if AB result is positive ↑↑↑
 *
 * will auto pre download these fonts
 */

FOUNDATION_EXPORT NSString * const ACCInteractionStcikerSocialFontName;

NS_ASSUME_NONNULL_BEGIN

@interface ACCInteractionStickerFontHelper : NSObject
/// @return nil if font is not valid(not exist or not downloaded) now
+ (UIFont *_Nullable)interactionFontWithFontName:(NSString *)fontName
                                        fontSize:(CGFloat)fontSize;

+ (BOOL)shouldExtraPreDownloadFont:(AWEStoryFontModel *)fontModel;
+ (void)downloadFontIfNeedWithFont:(AWEStoryFontModel *)font;

@end

NS_ASSUME_NONNULL_END
