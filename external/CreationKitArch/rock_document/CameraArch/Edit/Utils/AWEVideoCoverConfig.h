//
//  AWEVideoCoverConfig.h
//  AWEStudio-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/11/23.
//

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, ACCRecommendCoverStyle) {
    ACCRecommendCoverStyleDefault = 0,
    ACCRecommendCoverStyleChooseCoverChange = 1 << 0, // choose cover view change
    ACCRecommendCoverStylePublishChange = 1 << 1, // publish view change
    ACCRecommendCoverStylePreviewChange = 1 << 2, // preview view change
    ACCRecommendCoverStylePublishNoPreviewEntry = 1 << 3, // publish view without preview entry
};

@interface AWEVideoCoverConfig : NSObject

+ (CGSize)ratio;
+ (UIImage *)cropImage:(UIImage *)image offset:(CGPoint)offset;
+ (UIImage *)cropImage:(UIImage *)image;

+ (ACCRecommendCoverStyle)coverStyle;

+ (NSInteger)numberOfCellsPerRow;
+ (CGFloat)cellWidth;
+ (CGFloat)cellHeight;

+ (CGFloat)bottomHeight;

+ (CGFloat)buttonCenterYOffset;
+ (CGFloat)previewTopMargin;
+ (CGFloat)previewTopPadding;

@end
