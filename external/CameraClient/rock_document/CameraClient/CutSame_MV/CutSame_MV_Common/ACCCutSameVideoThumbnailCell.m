//
//  ACCCutSameVideoThumbnailCell.m
//  Essay
//
//  Created by 王丽辉 on 15/6/12.
//  Copyright (c) 2015年 Bytedance. All rights reserved.
//

#import "ACCCutSameVideoThumbnailCell.h"

@implementation ACCCutSameVideoThumbnailCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.thumbnailImageView];
        self.contentView.clipsToBounds = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.thumbnailImageView.frame = self.contentView.bounds;
}

- (UIImageView *)thumbnailImageView
{
    if (!_thumbnailImageView) {
        _thumbnailImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        _thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        _thumbnailImageView.clipsToBounds = YES;
    }
    return _thumbnailImageView;
}

@end
