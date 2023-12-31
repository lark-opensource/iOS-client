//
//  TMAStickerPageView.h
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/15.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMAReusablePage.h"
@class TMAStickerPageView;
@class TMASticker;
@class TMAEmoji;

extern NSUInteger const TMAStickerPageViewMaxEmojiCount;

@protocol TMAStickerPageViewDelegate <NSObject>

- (void)stickerPageView:(TMAStickerPageView *)stickerPageView didClickEmoji:(TMAEmoji *)emoji;
- (void)stickerPageViewDidClickDeleteButton:(TMAStickerPageView *)stickerPageView;
- (void)stickerPageView:(TMAStickerPageView *)stickerKeyboard showEmojiPreviewViewWithEmoji:(TMAEmoji *)emoji buttonFrame:(CGRect)buttonFrame;
- (void)stickerPageViewHideEmojiPreviewView:(TMAStickerPageView *)stickerKeyboard;

@end

@interface TMAStickerPageView : UIView <TMAReusablePage>

@property (nonatomic, weak) id<TMAStickerPageViewDelegate> delegate;
@property (nonatomic, assign) NSUInteger pageIndex;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

- (void)configureWithSticker:(TMASticker *)sticker;

@end
