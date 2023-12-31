//
//  TMAStickerTextView.h
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/19.
//  Copyright © 2018年 ZAKER. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const kTMAStickerTextEmptyChar = @"\ufeff";

@interface TMAStickerTextView : UITextView

@property (nonatomic, strong) NSString *placeholderStr;

@property (nonatomic, strong) UIColor *emaPlaceholderColor;

@property (nonatomic, assign) BOOL hasPicture;

- (instancetype)initWithFrame:(CGRect)frame returnKeyOpt:(BOOL)returnKeyOpt;

- (CGRect)verticalCenterContentSizeToFit;

- (void)updateEmptyCharaterIfNeeded;

@end
