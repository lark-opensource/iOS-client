//
//  TMASlideLineButton.h
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/28.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSUInteger, TMASlideLineButtonPosition) {
    TMASlideLineButtonPositionNone,
    TMASlideLineButtonPositionLeft,
    TMASlideLineButtonPositionRight,
    TMASlideLineButtonPositionBoth,
};

@interface TMASlideLineButton : UIButton

@property (nonatomic, assign) TMASlideLineButtonPosition linePosition;

@property (nonatomic, strong) UIColor *lineColor;

@end
