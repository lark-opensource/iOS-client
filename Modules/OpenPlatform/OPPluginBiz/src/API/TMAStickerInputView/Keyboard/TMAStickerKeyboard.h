//
//  TMASktickerKeyboard.h
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/28.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMASticker.h"
@class TMAStickerKeyboard;

@protocol TMAStickerKeyboardDelegate <NSObject>

- (void)stickerKeyboard:(TMAStickerKeyboard *)stickerKeyboard didClickEmoji:(TMAEmoji *)emoji;
- (void)stickerKeyboardDidClickDeleteButton:(TMAStickerKeyboard *)stickerKeyboard;
- (void)stickerKeyboardDidClickSendButton:(TMAStickerKeyboard *)stickerKeyboard;

@end

@interface TMAStickerKeyboard : UIView

@property (nonatomic, weak) id<TMAStickerKeyboardDelegate> delegate;

- (CGFloat)heightThatFits;

@end
