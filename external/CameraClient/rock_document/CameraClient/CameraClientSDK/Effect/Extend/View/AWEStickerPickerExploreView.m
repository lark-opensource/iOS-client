//
//  AWEStickerPickerExploreView.m
//  CameraClient-Pods-Aweme
//
//  Created by wanghongyu on 2021/9/23.
//

#import "AWEStickerPickerExploreView.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>


@interface AWEStickerPickerExploreView()

@property (nonatomic, strong) CALayer *bgLayer;

@property (nonatomic, strong, readwrite) ACCCollectionButton *exploreButton;

@end

@implementation AWEStickerPickerExploreView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        
        
        // Add background layer.
        CALayer *bgLayer = [CALayer layer];
        self.bgLayer = bgLayer;
        bgLayer.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer3).CGColor;
        bgLayer.cornerRadius = 18;
        //bgLayer.frame = CGRectMake(8, 8, layerWidth, 36);
        bgLayer.name = @"cornerButtonLayer";
        [self.layer addSublayer:bgLayer];
        
        // Add favorite button.
        ACCCollectionButton *exploreButton = [ACCCollectionButton buttonWithType:UIButtonTypeCustom];
        self.exploreButton = exploreButton;
        exploreButton.contentMode = UIViewContentModeCenter;
        exploreButton.displayMode = ACCCollectionButtonDisplayModeTitleAndImage;
        exploreButton.titleLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightSemibold];
        [exploreButton setImage:ACCResourceImage(@"iconStickerExplore") forState:UIControlStateNormal];
        [exploreButton setTitle:@"道具探索" forState:UIControlStateNormal];
        exploreButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        exploreButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        exploreButton.imageEdgeInsets = UIEdgeInsetsMake(0, 18, 1, 0);
        exploreButton.titleEdgeInsets = UIEdgeInsetsMake(0, 18, 1, 0);
        [self addSubview:exploreButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.bgLayer.frame = CGRectInset(self.bounds, 9, 9);
    self.exploreButton.frame = self.bounds;
}



@end
