//
//  ACCSkeletonDetectTipsView.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2020/12/14.
//

#import "ACCSkeletonDetectTipsView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface ACCSkeletonDetectTipsView()

@property (nonatomic, strong, readwrite) UILabel *contentLabel;

@end

@implementation ACCSkeletonDetectTipsView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentLabel = [[UILabel alloc] init];
        self.contentLabel.numberOfLines = 0;
        self.contentLabel.font = [ACCFont() systemFontOfSize:20 weight:ACCFontWeightMedium];
        self.contentLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        self.contentLabel.textAlignment = NSTextAlignmentCenter;
        self.contentLabel.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.3].CGColor;
        self.contentLabel.layer.shadowOpacity = 1;
        self.contentLabel.layer.shadowRadius = 10;
        self.contentLabel.layer.shadowOffset = CGSizeMake(0, 1);
        
        [self addSubview:self.contentLabel];
        
        ACCMasMaker(self.contentLabel, {
            make.left.right.equalTo(self).inset(54);
            make.top.equalTo(self.mas_top);
            make.bottom.equalTo(self.mas_bottom);
        });

    }
    return self;
}

@end
