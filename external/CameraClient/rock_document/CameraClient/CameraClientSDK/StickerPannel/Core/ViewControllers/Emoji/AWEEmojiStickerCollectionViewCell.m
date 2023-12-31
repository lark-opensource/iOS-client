//
//  AWEEmojiStickerCollectionViewCell.m
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/21.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEEmojiStickerCollectionViewCell.h"
#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>

@implementation AWEEmojiStickerCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    CGFloat scale = ACC_SCREEN_WIDTH / 375.0;
    [self.contentView addSubview:self.imageView];
    ACCMasMaker(self.imageView, {
        make.top.equalTo(@(8.5 * scale));
        make.bottom.equalTo(self.contentView.mas_bottom).offset(- 8.5 * scale);
        make.width.equalTo(self.imageView.mas_height);
        make.centerX.equalTo(self.contentView.mas_centerX);
    });
    
}

@end
