//
//  AWEVideoCoverConfig.m
//  AWEStudio-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/11/23.
//

#import "AWEVideoCoverConfig.h"
#import "CKConfigKeysDefines.h"
#import <CreativeKit/UIImage+ACC.h>
#import <CreativeKit/ACCMacros.h>
#import <AVFoundation/AVUtilities.h>

static CGFloat const kAWEVideoCoverCellSpace = 1.0f;

@implementation AWEVideoCoverConfig

+ (CGSize)ratio
{
    return CGSizeMake(3, 4);
}

+ (UIImage *)cropImage:(UIImage *)image
{
    return [self cropImage:image offset:CGPointZero];
}

+ (UIImage *)cropImage:(UIImage *)image offset:(CGPoint)offset
{
    CGSize size = image.size;
    CGRect rect = AVMakeRectWithAspectRatioInsideRect([AWEVideoCoverConfig ratio], CGRectMake(0, 0, size.width, size.height));
    
    CGFloat offsetX = size.width * offset.x;
    CGFloat offsetY = size.height * offset.y;
    rect.origin.x -= offsetX;
    rect.origin.y -= offsetY;
    
    return [image acc_crop:rect];
}


+ (NSInteger)numberOfCellsPerRow
{
    return ACC_SCREEN_WIDTH > 1024 ? 5 : (ACC_SCREEN_WIDTH > 650 ? 4 : 3);
}

+ (CGFloat)cellWidth
{
    CGFloat allCellWidth = ACC_SCREEN_WIDTH - kAWEVideoCoverCellSpace * ([self numberOfCellsPerRow] - 1);
    return ceil(allCellWidth / [self numberOfCellsPerRow] - 1);
}

+ (CGFloat)cellHeight
{
    return floor([self cellWidth] * [self ratio].height / [self ratio].width);
}

+ (CGFloat)bottomHeight
{
    if (([AWEVideoCoverConfig coverStyle] & ACCRecommendCoverStyleChooseCoverChange) > 0) {
        return 245;
    }
    return 274;
}

+ (ACCRecommendCoverStyle)coverStyle
{
    NSInteger value = ACCConfigInt(kConfigInt_cover_style);
    if (value == 1) {
        return ACCRecommendCoverStyleChooseCoverChange;
    } else if (value == 2) {
        return ACCRecommendCoverStyleChooseCoverChange | ACCRecommendCoverStylePublishChange;
    } else if (value == 3) {
        return ACCRecommendCoverStyleChooseCoverChange | ACCRecommendCoverStylePublishChange | ACCRecommendCoverStylePreviewChange;
    } else if (value == 4) {
        return ACCRecommendCoverStyleChooseCoverChange | ACCRecommendCoverStylePublishChange | ACCRecommendCoverStylePublishNoPreviewEntry;
    }
    return ACCRecommendCoverStyleDefault;
}

+ (CGFloat)buttonCenterYOffset
{
    return ACC_NAVIGATION_BAR_HEIGHT - 22;
}

+ (CGFloat)previewTopMargin
{
    if (ACCConfigBool(kConfigBool_enable_cover_clip)) {
        return ACC_NAVIGATION_BAR_HEIGHT;
    }
    return ACC_NAVIGATION_BAR_HEIGHT + 8;
}

+ (CGFloat)previewTopPadding
{
    if (ACCConfigBool(kConfigBool_enable_cover_clip)) {
        return 16;
    }
    return 0;
}

@end
