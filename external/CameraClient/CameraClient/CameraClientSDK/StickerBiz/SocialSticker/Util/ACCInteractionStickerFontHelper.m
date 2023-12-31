//
//  ACCInteractionStickerFontHelper.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/8/20.
//

#import "ACCInteractionStickerFontHelper.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCMacros.h>

NSString * const ACCInteractionStcikerSocialFontName = @"文悦后现代体";

@implementation ACCInteractionStickerFontHelper

+ (BOOL)shouldExtraPreDownloadFont:(AWEStoryFontModel *)fontModel {
    NSDictionary *wishDict = ACCConfigDict(kConfigDict_new_year_wish_default_font_setting);
    NSString *fontType = [wishDict acc_stringValueForKey:@"font_type"];
    if ([fontModel.fontName isEqualToString:fontType]) {
        return YES;
    }
    if (!ACCConfigBool(kConfigBool_sticker_support_mention_hashtag)) {
        return NO;
    }
    
    NSArray <NSString *> * const interactionStcikerFontNames = [self interactionStcikerFontNames];
    
    if (ACC_isEmptyString(fontModel.fontName)) {
        return NO;
    }
    
    return [interactionStcikerFontNames containsObject:fontModel.fontName];
}

+ (UIFont *)interactionFontWithFontName:(NSString *)fontName fontSize:(CGFloat)fontSize {
    
    // bad case
    if (!ACCConfigBool(kConfigBool_sticker_support_mention_hashtag)) {
        return nil;
    }
    
    NSArray<AWEStoryFontModel *> *stickerFonts = [ACCCustomFont() stickerFonts];
    AWEStoryFontModel *targetFontModel = [stickerFonts acc_match:^BOOL(AWEStoryFontModel * _Nonnull item) {
        return [item.fontName isEqualToString:fontName];
    }];

    if (!targetFontModel) {
        return nil;
    }
    
    if (!targetFontModel.download) {
        [self downloadFontIfNeedWithFont:targetFontModel];
        return nil;
    }

    return [ACCCustomFont() fontWithModel:targetFontModel size:fontSize];
}

+ (void)downloadFontIfNeedWithFont:(AWEStoryFontModel *)font {
    
    if (!font || font.download || font.downloadState == AWEStoryTextFontDownloading) {
        return;
    }
    
    [ACCCustomFont() downloadFontWithModel:font completion:^(NSString * _Nonnull filePath, BOOL success) {
        
    }];
}

+ (NSArray <NSString * > *)interactionStcikerFontNames {
    return @[ACCInteractionStcikerSocialFontName];
}

@end
