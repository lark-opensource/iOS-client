//
//  TMAEmojiPreviewView.m
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/28.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import "TMAEmojiPreviewView.h"
#import "TMAEmoji.h"
#import <OPFoundation/UIImage+EMA.h>
#import <OPFoundation/UIColor+EMA.h>
#import <OPPluginBiz/OPPluginBiz-Swift.h>

static CGFloat TMAEmojiPreviewImageTopPadding = 18.0;
static CGFloat TMAEmojiPreviewImageLeftRightPadding = 22.0;
static CGFloat TMAEmojiPreviewImageLength = 48.0;
static CGFloat TMAEmojiPreviewImageBottomMargin = 2.0;
static CGFloat TMAEmojiPreviewTextMaxWidth = 60.0;
static CGFloat TMAEmojiPreviewTextHeight = 13.0;

@interface TMAEmojiPreviewView ()
@property (nonatomic, strong) UIImageView *emojiImageView;
@property (nonatomic, strong) UILabel *descriptionLabel;
@end

@implementation TMAEmojiPreviewView

- (instancetype)init {
    if (self = [super init]) {
        self.image = [UIImage ema_imageNamed:@"tma_emoji-preview-bg"];
        [self addSubview:self.emojiImageView];
        [self addSubview:self.descriptionLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (!self.emoji) {
        return;
    }
    self.emojiImageView.image = [TMAEmotionResource imageBy:self.emoji.imageName];//[UIImage ema_imageNamed:[@"Sticker.bundle" stringByAppendingPathComponent:self.emoji.imageName]];
    self.emojiImageView.frame = CGRectMake(TMAEmojiPreviewImageLeftRightPadding, TMAEmojiPreviewImageTopPadding, TMAEmojiPreviewImageLength, TMAEmojiPreviewImageLength);

    self.descriptionLabel.text = self.emoji.emojiDescription;
    CGSize labelSize = [self.descriptionLabel textRectForBounds:CGRectMake(0, 0, TMAEmojiPreviewTextMaxWidth, TMAEmojiPreviewTextHeight) limitedToNumberOfLines:1].size;
    self.descriptionLabel.frame = CGRectMake((CGRectGetWidth(self.bounds) - labelSize.width) / 2, CGRectGetMaxY(self.emojiImageView.frame) + TMAEmojiPreviewImageBottomMargin, labelSize.width, labelSize.height);
}

- (void)setEmoji:(TMAEmoji *)emoji {
    if (_emoji != emoji) {
        _emoji = emoji;
        [self setNeedsLayout];
    }
}

- (UIImageView *)emojiImageView {
    if (!_emojiImageView) {
        _emojiImageView = [[UIImageView alloc] init];
    }
    return _emojiImageView;
}

- (UILabel *)descriptionLabel {
    if (!_descriptionLabel) {
        _descriptionLabel = [[UILabel alloc] init];
        _descriptionLabel.font = [UIFont systemFontOfSize:11.0];
        _descriptionLabel.textColor = [UIColor colorWithHexString:@"#4A4A4A"];
        _descriptionLabel.lineBreakMode = NSLineBreakByCharWrapping;
    }
    return _descriptionLabel;
}

@end
