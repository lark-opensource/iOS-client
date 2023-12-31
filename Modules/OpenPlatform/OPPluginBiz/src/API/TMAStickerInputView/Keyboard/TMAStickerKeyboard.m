//
//  TMASktickerKeyboard.m
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/28.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import "TMAStickerKeyboard.h"
#import "TMAEmojiPreviewView.h"
#import "TMAStickerPageView.h"
#import "TMAStickerDataManager.h"
#import "TMAQueuingScrollView.h"
#import "TMASlideLineButton.h"
#import <OPFoundation/UIImage+EMA.h>
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/UIColor+EMA.h>
#import <OPFoundation/UIWindow+EMA.h>

#import <OPFoundation/OPFoundation-Swift.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

static CGFloat const TMAStickerTopInset = 12.0;
static CGFloat const TMAStickerScrollViewHeight = 132.0;
static CGFloat const TMAKeyboardPageControlTopMargin = 10.0;
static CGFloat const TMAKeyboardPageControlHeight = 7.0;
static CGFloat const TMAKeyboardPageControlBottomMargin = 6.0;
static CGFloat const TMAKeyboardCoverButtonWidth = 70.0;
static CGFloat const TMAKeyboardCoverButtonHeight = 44.0;
static CGFloat const TMAPreviewViewWidth = 92.0;
static CGFloat const TMAPreviewViewHeight = 137.0;

static NSString *const TMAStickerPageViewReuseID = @"TMAStickerPageView";

@interface TMAStickerKeyboard () <TMAStickerPageViewDelegate, TMAQueuingScrollViewDelegate, UIInputViewAudioFeedback>
@property (nonatomic, strong) NSArray<TMASticker *> *stickers;
@property (nonatomic, strong) TMAQueuingScrollView *queuingScrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) NSArray<TMASlideLineButton *> *stickerCoverButtons;
@property (nonatomic, strong) TMASlideLineButton *sendButton;
@property (nonatomic, strong) UIScrollView *bottomScrollableSegment;
@property (nonatomic, strong) UIView *bottomBGView;
@property (nonatomic, strong) TMAEmojiPreviewView *emojiPreviewView;
@end

@implementation TMAStickerKeyboard {
    NSUInteger _currentStickerIndex;
}

- (instancetype)init {
    self = [self initWithFrame:CGRectZero];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _currentStickerIndex = 0;
        _stickers = [TMAStickerDataManager sharedInstance].allStickers.copy;

        self.backgroundColor = UDOCColor.bgBase;
        [self addSubview:self.queuingScrollView];
        [self addSubview:self.pageControl];
        [self addSubview:self.bottomBGView];
        [self addSubview:self.sendButton];
        [self addSubview:self.bottomScrollableSegment];

        [self changeStickerToIndex:0];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.queuingScrollView.contentSize = CGSizeMake([self numberOfPageForSticker:[self stickerAtIndex:_currentStickerIndex]] * CGRectGetWidth(self.bounds), TMAStickerScrollViewHeight);
    self.queuingScrollView.frame = CGRectMake(0, TMAStickerTopInset, CGRectGetWidth(self.bounds), TMAStickerScrollViewHeight);
    self.pageControl.frame = CGRectMake(0, CGRectGetMaxY(self.queuingScrollView.frame) + TMAKeyboardPageControlTopMargin, CGRectGetWidth(self.bounds), TMAKeyboardPageControlHeight);

    self.bottomScrollableSegment.contentSize = CGSizeMake(self.stickerCoverButtons.count * TMAKeyboardCoverButtonWidth, TMAKeyboardCoverButtonHeight);
    self.bottomScrollableSegment.frame = CGRectMake(0, CGRectGetHeight(self.bounds) - TMAKeyboardCoverButtonHeight - self.safeAreaInsets.bottom, CGRectGetWidth(self.bounds) - TMAKeyboardCoverButtonWidth, TMAKeyboardCoverButtonHeight);
    [self reloadScrollableSegment];

    self.sendButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - TMAKeyboardCoverButtonWidth, CGRectGetMinY(self.bottomScrollableSegment.frame), TMAKeyboardCoverButtonWidth, TMAKeyboardCoverButtonHeight);
    self.bottomBGView.frame = CGRectMake(0, CGRectGetMinY(self.bottomScrollableSegment.frame), CGRectGetWidth(self.frame), TMAKeyboardCoverButtonHeight + self.safeAreaInsets.bottom);
}

- (CGFloat)heightThatFits {
    
    UIWindow *window = self.window ?: OPWindowHelper.fincMainSceneWindow;
    
    CGFloat bottomInset = 0;
    bottomInset = window.safeAreaInsets.bottom;
    return TMAStickerTopInset + TMAStickerScrollViewHeight + TMAKeyboardPageControlTopMargin + TMAKeyboardPageControlHeight + TMAKeyboardPageControlBottomMargin + TMAKeyboardCoverButtonHeight + bottomInset;
}

#pragma mark - getter / setter

- (TMAQueuingScrollView *)queuingScrollView {
    if (!_queuingScrollView) {
        _queuingScrollView = [[TMAQueuingScrollView alloc] init];
        _queuingScrollView.delegate = self;
        _queuingScrollView.pagePadding = 0;
        _queuingScrollView.alwaysBounceHorizontal = NO;
    }
    return _queuingScrollView;
}

- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.hidesForSinglePage = YES;
        _pageControl.currentPageIndicatorTintColor = UDOCColor.primaryPri500;
        _pageControl.pageIndicatorTintColor = [UIColor colorWithHexString:@"#D8D8D8"];
    }
    return _pageControl;
}

- (TMASlideLineButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [[TMASlideLineButton alloc] init];
        _sendButton.titleLabel.font = [UIFont systemFontOfSize:17];
        [_sendButton setTitle:BDPI18n.send forState:UIControlStateNormal];
        [_sendButton setTitleColor:UDOCColor.staticWhite forState:UIControlStateNormal];
        [_sendButton setBackgroundColor:UDOCColor.primaryPri500];
        _sendButton.linePosition = TMASlideLineButtonPositionLeft;
        _sendButton.lineColor = UDOCColor.lineDividerDefault;
        [_sendButton addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendButton;
}

- (UIScrollView *)bottomScrollableSegment {
    if (!_bottomScrollableSegment) {
        _bottomScrollableSegment = [[UIScrollView alloc] init];
        _bottomScrollableSegment.showsHorizontalScrollIndicator = NO;
        _bottomScrollableSegment.showsVerticalScrollIndicator = NO;
    }
    return _bottomScrollableSegment;
}

- (UIView *)bottomBGView {
    if (!_bottomBGView) {
        _bottomBGView = [[UIView alloc] init];
        _bottomBGView.backgroundColor = UDOCColor.bgBody;
    }
    return _bottomBGView;
}

- (TMAEmojiPreviewView *)emojiPreviewView {
    if (!_emojiPreviewView) {
        _emojiPreviewView = [[TMAEmojiPreviewView alloc] init];
        _emojiPreviewView.backgroundColor = UDOCColor.bgBody;
    }
    return _emojiPreviewView;
}

#pragma mark - private method

- (TMASticker *)stickerAtIndex:(NSUInteger)index {
    if (self.stickers && index < self.stickers.count) {
        return self.stickers[index];
    }
    return nil;
}

- (NSUInteger)numberOfPageForSticker:(TMASticker *)sticker {
    if (!sticker) {
        return 0;
    }

    NSUInteger numberOfPage = (sticker.emojis.count / TMAStickerPageViewMaxEmojiCount) + ((sticker.emojis.count % TMAStickerPageViewMaxEmojiCount == 0) ? 0 : 1);
    return numberOfPage;
}

- (void)reloadScrollableSegment {
    for (UIButton *button in self.stickerCoverButtons) {
        [button removeFromSuperview];
    }
    self.stickerCoverButtons = nil;

    if (!self.stickers || !self.stickers.count) {
        return;
    }

    NSMutableArray *stickerCoverButtons = [[NSMutableArray alloc] init];
    for (NSUInteger index = 0, max = self.stickers.count; index < max; index++) {
        TMASticker *sticker = self.stickers[index];
        if (!sticker) {
            return;
        }

        TMASlideLineButton *button = [[TMASlideLineButton alloc] init];
        button.tag = index;
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        button.linePosition = TMASlideLineButtonPositionRight;
        button.lineColor = UDOCColor.lineDividerDefault;
        button.backgroundColor = (_currentStickerIndex == index ? UDOCColor.bgBody : [UIColor clearColor]);
        [button setImage:[self emojiImageWithName:sticker.coverImageName] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(changeSticker:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomScrollableSegment addSubview:button];
        [stickerCoverButtons addObject:button];
        button.frame = CGRectMake(index * TMAKeyboardCoverButtonWidth, 0, TMAKeyboardCoverButtonWidth, TMAKeyboardCoverButtonHeight);
    }
    self.stickerCoverButtons = stickerCoverButtons;
}

- (UIImage *)emojiImageWithName:(NSString *)name {
    if (!name.length) {
        return nil;
    }

    return [UIImage ema_imageNamed:name];//[UIImage ema_imageNamed:[@"Sticker.bundle" stringByAppendingPathComponent:name]];
}

- (void)changeStickerToIndex:(NSUInteger)toIndex {
    if (toIndex >= self.stickers.count) {
        return;
    }

    TMASticker *sticker = [self stickerAtIndex:toIndex];
    if (!sticker) {
        return;
    }

    _currentStickerIndex = toIndex;

    TMAStickerPageView *pageView = [self queuingScrollView:self.queuingScrollView pageViewForStickerAtIndex:0];
    [self.queuingScrollView displayView:pageView];

    [self reloadScrollableSegment];
}

#pragma mark - target / action

- (void)changeSticker:(UIButton *)button {
    [self changeStickerToIndex:button.tag];
}

- (void)sendAction:(TMASlideLineButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerKeyboardDidClickSendButton:)]) {
        [self.delegate stickerKeyboardDidClickSendButton:self];
    }
}

#pragma mark - TMAQueuingScrollViewDelegate

- (void)queuingScrollViewChangedFocusView:(TMAQueuingScrollView *)queuingScrollView previousFocusView:(UIView *)previousFocusView {
    TMAStickerPageView *currentView = (TMAStickerPageView *)self.queuingScrollView.focusView;
    self.pageControl.currentPage = currentView.pageIndex;
}

- (UIView<TMAReusablePage> *)queuingScrollView:(TMAQueuingScrollView *)queuingScrollView viewBeforeView:(UIView *)view {
    return [self queuingScrollView:queuingScrollView pageViewForStickerAtIndex:((TMAStickerPageView *)view).pageIndex - 1];
}

- (UIView<TMAReusablePage> *)queuingScrollView:(TMAQueuingScrollView *)queuingScrollView viewAfterView:(UIView *)view {
    return [self queuingScrollView:queuingScrollView pageViewForStickerAtIndex:((TMAStickerPageView *)view).pageIndex + 1];
}

- (TMAStickerPageView *)queuingScrollView:(TMAQueuingScrollView *)queuingScrollView pageViewForStickerAtIndex:(NSUInteger)index {
    TMASticker *sticker = [self stickerAtIndex:_currentStickerIndex];
    if (!sticker) {
        return nil;
    }

    NSUInteger numberOfPages = [self numberOfPageForSticker:sticker];
    self.pageControl.numberOfPages = numberOfPages;
    if (index >= numberOfPages) {
        return nil;
    }

    TMAStickerPageView *pageView = [queuingScrollView reusableViewWithIdentifer:TMAStickerPageViewReuseID];
    if (!pageView) {
        pageView = [[TMAStickerPageView alloc] initWithReuseIdentifier:TMAStickerPageViewReuseID];
        pageView.delegate = self;
    }
    pageView.pageIndex = index;
    [pageView configureWithSticker:sticker];
    return pageView;
}

#pragma mark - TMAStickerPageViewDelegate

- (void)stickerPageView:(TMAStickerPageView *)stickerPageView didClickEmoji:(TMAEmoji *)emoji {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerKeyboard:didClickEmoji:)]) {
        [[UIDevice currentDevice] playInputClick];
        [self.delegate stickerKeyboard:self didClickEmoji:emoji];
    }
}

- (void)stickerPageViewDidClickDeleteButton:(TMAStickerPageView *)stickerPageView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerKeyboardDidClickDeleteButton:)]) {
        [[UIDevice currentDevice] playInputClick];
        [self.delegate stickerKeyboardDidClickDeleteButton:self];
    }
}

- (void)stickerPageView:(TMAStickerPageView *)stickerKeyboard showEmojiPreviewViewWithEmoji:(TMAEmoji *)emoji buttonFrame:(CGRect)buttonFrame {
    if (!emoji) {
        return;
    }

    self.emojiPreviewView.emoji = emoji;

    UIWindow *window = stickerKeyboard.window;
    
    CGRect buttonFrameAtKeybord = CGRectMake(buttonFrame.origin.x, TMAStickerTopInset + buttonFrame.origin.y, buttonFrame.size.width, buttonFrame.size.height);
    CGFloat containerHeight = [UIWindow ema_currentContainerSize:window].height;
    self.emojiPreviewView.frame = CGRectMake(CGRectGetMidX(buttonFrameAtKeybord) - TMAPreviewViewWidth / 2, containerHeight - CGRectGetHeight(self.bounds) + CGRectGetMaxY(buttonFrameAtKeybord) - TMAPreviewViewHeight, TMAPreviewViewWidth, TMAPreviewViewHeight);

    if (window) {
        [window addSubview:self.emojiPreviewView];
    }
}

- (void)stickerPageViewHideEmojiPreviewView:(TMAStickerPageView *)stickerKeyboard {
    [self.emojiPreviewView removeFromSuperview];
}

#pragma mark - UIInputViewAudioFeedback

- (BOOL)enableInputClicksWhenVisible {
    return YES;
}

@end
