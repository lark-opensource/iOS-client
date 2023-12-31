//
//  AWEStoryToolBar.h
//  AWEStudio
//
//  Created by hanxu on 2018/11/19.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWEStoryColorChooseView.h"
#import "AWEStoryFontChooseView.h"

typedef NS_ENUM(NSInteger, AWEStoryToolBarType) {
    AWEStoryToolBarTypeColor = 0,
    AWEStoryToolBarTypeColorAndFont = 1,
    AWEStoryToolBarTypeColorAndFontWithOutAlign = 2,
    AWEStoryToolBarTypeColorFontAndTextReader = 3,
};

@interface AWEStoryToolBar : UIView

@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *alignmentButton;
@property (nonatomic, strong) UIButton *textReaderButton;
@property (nonatomic, strong) AWEStoryFontChooseView *fontChooseView;
@property (nonatomic, strong) AWEStoryColorChooseView *colorChooseView;

- (instancetype)initWithType:(AWEStoryToolBarType)type;

+ (CGFloat)barHeight;

@end
