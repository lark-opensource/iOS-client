//
//  TMAStickerPageView.m
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/15.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import "TMAStickerPageView.h"
#import "TMASticker.h"
#import "TMAButton.h"
#import <OPFoundation/UIImage+EMA.h>
#import <OPPluginBiz/OPPluginBiz-Swift.h>

NSUInteger const TMAStickerPageViewMaxEmojiCount = 20;
static NSUInteger const TMAStickerPageViewLineCount = 3;
static NSUInteger const TMAStickerPageViewButtonPerLine = 7;
static CGFloat const TMAStickerPageViewEmojiButtonLength = 32.0;
static CGFloat const TMAStickerPageViewEmojiButtonVerticalMargin = 16.0;

@interface TMAStickerPageView ()
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) NSTimer *deleteEmojiTimer;
@property (nonatomic, strong) TMASticker *sticker;
@property (nonatomic, strong) NSArray<TMAButton *> *emojiButtons;
@end

@implementation TMAStickerPageView

@synthesize focused = _focused;
@synthesize reuseIdentifier = _reuseIdentifier;
@synthesize nonreusable = _nonreusable;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame]) {
        NSMutableArray *emojiButtons = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0; i < TMAStickerPageViewMaxEmojiCount; i++) {
            TMAButton *button = [[TMAButton alloc] init];
            button.tag = i;
            [button addTarget:self action:@selector(didClickEmojiButton:) forControlEvents:UIControlEventTouchUpInside];
            UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressEmoji:)];
            longPressRecognizer.minimumPressDuration = 0.2;
            [button addGestureRecognizer:longPressRecognizer];
            [emojiButtons addObject:button];
            [self addSubview:button];
        }
        self.emojiButtons = emojiButtons;
        [self addSubview:self.deleteButton];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame reuseIdentifier:nil];
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    return [self initWithFrame:CGRectZero reuseIdentifier:reuseIdentifier];
}

- (UIButton *)deleteButton {
    if (!_deleteButton) {
        _deleteButton = [[UIButton alloc] init];
        [_deleteButton setImage:[UIImage ema_imageNamed:@"tma_chat_emotion_delete"] forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(didTouchDownDeleteButton:) forControlEvents:UIControlEventTouchDown];
        [_deleteButton addTarget:self action:@selector(didTouchUpInsideDeleteButton:) forControlEvents:UIControlEventTouchUpInside];
        [_deleteButton addTarget:self action:@selector(didTouchUpOutsideDeleteButton:) forControlEvents:UIControlEventTouchUpOutside];
    }
    return _deleteButton;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat screenWidth = CGRectGetWidth(self.bounds);
    CGFloat spaceBetweenButtons = (screenWidth - TMAStickerPageViewButtonPerLine * TMAStickerPageViewEmojiButtonLength) / (TMAStickerPageViewButtonPerLine + 1);
    for (TMAButton *button in self.emojiButtons) {
        NSUInteger index = button.tag;
        if (index > self.sticker.emojis.count) {
            break;
        }

        NSUInteger line = index / TMAStickerPageViewButtonPerLine;
        NSUInteger row = index % TMAStickerPageViewButtonPerLine;

        CGFloat minX = row * TMAStickerPageViewEmojiButtonLength + (row + 1) * spaceBetweenButtons;
        CGFloat minY = line * (TMAStickerPageViewEmojiButtonLength + TMAStickerPageViewEmojiButtonVerticalMargin);
        button.frame = CGRectMake(minX, minY, TMAStickerPageViewEmojiButtonLength, TMAStickerPageViewEmojiButtonLength);
        button.touchInsets = UIEdgeInsetsMake(-TMAStickerPageViewEmojiButtonVerticalMargin / 2, -spaceBetweenButtons / 2, -TMAStickerPageViewEmojiButtonVerticalMargin / 2, -spaceBetweenButtons / 2);
    }

    CGFloat minDeleteX = screenWidth - spaceBetweenButtons - TMAStickerPageViewEmojiButtonLength;
    CGFloat minDeleteY = (TMAStickerPageViewLineCount - 1) * (TMAStickerPageViewEmojiButtonLength + TMAStickerPageViewEmojiButtonVerticalMargin);
    self.deleteButton.frame = CGRectMake(minDeleteX, minDeleteY, TMAStickerPageViewEmojiButtonLength, TMAStickerPageViewEmojiButtonLength);
}

- (void)configureWithSticker:(TMASticker *)sticker {
    if (!sticker) {
        return;
    }
    self.sticker = sticker;

    NSArray<TMAEmoji *> *emojis = [self emojisForSticker:sticker atPage:self.pageIndex];
    NSUInteger index = 0;
    for (TMAEmoji *emoji in emojis) {
        if (index > TMAStickerPageViewMaxEmojiCount) {
            break;
        }

        TMAButton *button = self.emojiButtons[index];
        [button setImage:[self emojiImageWithName:emoji.imageName] forState:UIControlStateNormal];
        index += 1;
    }

    [self setNeedsLayout];
}

#pragma mark - TMAReusablePage

- (void)prepareForReuse {
    self.sticker = nil;
    for (TMAButton *button in self.emojiButtons) {
        [button setImage:nil forState:UIControlStateNormal];
        button.frame = CGRectZero;
    }
}

#pragma mark - private method

- (void)didClickEmojiButton:(UIButton *)button {
    NSUInteger index = button.tag;
    NSArray<TMAEmoji *> *emojis = [self emojisForSticker:self.sticker atPage:self.pageIndex];
    if (index >= emojis.count) {
        return;
    }

    TMAEmoji *emoji = emojis[index];
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerPageView:didClickEmoji:)]) {
        [self.delegate stickerPageView:self didClickEmoji:emoji];
    }
}

- (void)didTouchDownDeleteButton:(UIButton *)button {
    if (self.deleteEmojiTimer) {
        [self.deleteEmojiTimer invalidate];
        self.deleteEmojiTimer = nil;
    }

    self.deleteEmojiTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(delegateDeleteEmoji) userInfo:nil repeats:YES];
}

- (void)didTouchUpInsideDeleteButton:(UIButton *)button {
    [self delegateDeleteEmoji];

    if (self.deleteEmojiTimer) {
        [self.deleteEmojiTimer invalidate];
        self.deleteEmojiTimer = nil;
    }
}

- (void)didTouchUpOutsideDeleteButton:(UIButton *)button {
    if (self.deleteEmojiTimer) {
        [self.deleteEmojiTimer invalidate];
        self.deleteEmojiTimer = nil;
    }
}

- (void)delegateDeleteEmoji {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerPageViewDidClickDeleteButton:)]) {
        [self.delegate stickerPageViewDidClickDeleteButton:self];
    }
}

- (NSArray<TMAEmoji *> *)emojisForSticker:(TMASticker *)sticker atPage:(NSUInteger)page {
    if (!sticker || !sticker.emojis.count) {
        return nil;
    }

    NSUInteger totalPage = sticker.emojis.count / TMAStickerPageViewMaxEmojiCount + 1;
    if (page >= totalPage) {
        return nil;
    }

    BOOL isLastPage = (page == totalPage - 1 ? YES : NO);
    NSUInteger beginIndex = page * TMAStickerPageViewMaxEmojiCount;
    NSUInteger length = (isLastPage ? (sticker.emojis.count - page * TMAStickerPageViewMaxEmojiCount) : TMAStickerPageViewMaxEmojiCount);
    NSArray *emojis = [sticker.emojis subarrayWithRange:NSMakeRange(beginIndex, length)];
    return emojis;
}

- (UIImage *)emojiImageWithName:(NSString *)name {
    if (!name.length) {
        return nil;
    }
    
    UIImage *image = [TMAEmotionResource imageBy:name];//[UIImage ema_imageNamed:[@"Sticker.bundle" stringByAppendingPathComponent:name]];
    return image;
}

- (void)didLongPressEmoji:(UILongPressGestureRecognizer *)recognizer {
    if (!self.emojiButtons || !self.emojiButtons.count) {
        return;
    }

    NSArray<TMAEmoji *> *emojis = [self emojisForSticker:self.sticker atPage:self.pageIndex];
    if (!emojis || !emojis.count) {
        return;
    }

    TMAEmoji *emoji = nil;
    UIButton *currentButton = nil;
    CGPoint point = [recognizer locationInView:self];
    for (NSUInteger i = 0, max = self.emojiButtons.count; i < max; i++) {
        if (CGRectContainsPoint(UIEdgeInsetsInsetRect(self.emojiButtons[i].frame, self.emojiButtons[i].touchInsets), point)) {
            if (i < emojis.count) {
                currentButton = self.emojiButtons[i];
                emoji = emojis[i];
            }
            break;
        }
    }

    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self showPreviewViewWithEmoji:emoji button:currentButton];
            break;
        case UIGestureRecognizerStateChanged:
            [self showPreviewViewWithEmoji:emoji button:currentButton];
            break;
        case UIGestureRecognizerStateEnded:
            [self hidePreviewViewForButton:currentButton];
            if (currentButton) {
                [self didClickEmojiButton:currentButton];
            }
            break;
        default:
            [self hidePreviewViewForButton:currentButton];
            break;
    }
}

- (void)showPreviewViewWithEmoji:(TMAEmoji *)emoji button:(UIButton *)button {
    if (!emoji) {
        [self hidePreviewViewForButton:button];
        return;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerPageView:showEmojiPreviewViewWithEmoji:buttonFrame:)]) {
        [self.delegate stickerPageView:self showEmojiPreviewViewWithEmoji:emoji buttonFrame:button.frame];
    }
}

- (void)hidePreviewViewForButton:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerPageViewHideEmojiPreviewView:)]) {
        [self.delegate stickerPageViewHideEmojiPreviewView:self];
    }
}

@end
