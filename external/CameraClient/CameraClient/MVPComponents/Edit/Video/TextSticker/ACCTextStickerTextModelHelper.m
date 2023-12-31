//
//  ACCTextStickerTextModelHelper.m
//  CameraClient-Pods-Aweme
//
//  Created by fengming.shi on 2021/1/28 00:39.
//	Copyright © 2021 Bytedance. All rights reserved.
	

#import "ACCTextStickerTextModelHelper.h"
#import <CreationKitArch/ACCCustomFontProtocol.h>
#import <CreationKitArch/AWEStoryTextImageModel.h>
#import <CreativeKit/ACCMacros.h>

@implementation ACCTextStickerTextModelHelper

+ (CGFloat)fitFontSizeWithContent:(NSString *)content fontModel:(AWEStoryFontModel *)fontModel fontSize:(CGFloat)fontSize
{
    UIFont *font = [ACCCustomFont() fontWithModel:fontModel size:fontSize] ?: [UIFont systemFontOfSize:fontSize];
    if (!font) {
        return fontSize;
    }
    CGFloat fixedWidth = [content sizeWithAttributes:@{NSFontAttributeName:font}].width;
    while (fixedWidth > ACC_SCREEN_WIDTH - 32 * 2) {
        fontSize = fontSize - 1;
        fixedWidth = [content sizeWithAttributes:@{NSFontAttributeName:[ACCCustomFont() fontWithModel:fontModel size:fontSize]}].width;
    }
    return fontSize;
}

@end
