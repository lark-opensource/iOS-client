//
//  AWEMusicEditorCollectionHeaderView.m
//  AWEStudio
//
//  Created by 黄鸿森 on 2018/3/23.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEMusicEditorCollectionHeaderView.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEMusicEditorCollectionHeaderView()
@property (nonatomic, strong) UIView *dotView;
@end

@implementation AWEMusicEditorCollectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _dotView = [[UIView alloc] init];
        _dotView.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainerInverse);
        _dotView.layer.cornerRadius = 3;
        _dotView.layer.masksToBounds = YES;
        [self addSubview:_dotView];
        
        ACCMasMaker(_dotView, {
            make.center.equalTo(self);
            make.width.height.equalTo(@6);
        });
    }
    return self;
}

- (void)updateDotTop:(CGFloat)top
{
    ACCMasReMaker(_dotView, {
        make.centerX.equalTo(self);
        make.top.equalTo(@(top));
        make.width.height.equalTo(@6);
    });
}

@end
