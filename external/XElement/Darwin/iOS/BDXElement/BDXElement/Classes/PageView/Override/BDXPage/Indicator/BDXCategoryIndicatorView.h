//
//  BDXCategoryComponentView.h
//  DQGuess
//
//  Created by jiaxin on 2018/7/25.
//  Copyright © 2018年 jingbo. All rights reserved.
//

#import "BDXCategoryBaseView.h"
#import "BDXCategoryIndicatorCell.h"
#import "BDXCategoryIndicatorCellModel.h"
#import "BDXCategoryIndicatorProtocol.h"

@interface BDXCategoryIndicatorView : BDXCategoryBaseView

@property (nonatomic, strong) NSArray <UIView<BDXCategoryIndicatorProtocol> *> *indicators;


@property (nonatomic, assign, getter=isCellBackgroundColorGradientEnabled) BOOL cellBackgroundColorGradientEnabled;
//default：[UIColor clearColor]
@property (nonatomic, strong) UIColor *cellBackgroundUnselectedColor;
//default：[UIColor grayColor]
@property (nonatomic, strong) UIColor *cellBackgroundSelectedColor;

//----------------------separatorLine-----------------------//
//default NO
@property (nonatomic, assign, getter=isSeparatorLineShowEnabled) BOOL separatorLineShowEnabled;
//default [UIColor lightGrayColor]
@property (nonatomic, strong) UIColor *separatorLineColor;
//default CGSizeMake(1/[UIScreen mainScreen].scale, 20)
@property (nonatomic, assign) CGSize separatorLineSize;

@end

@interface BDXCategoryIndicatorView (UISubclassingIndicatorHooks)


- (void)refreshLeftCellModel:(BDXCategoryBaseCellModel *)leftCellModel rightCellModel:(BDXCategoryBaseCellModel *)rightCellModel ratio:(CGFloat)ratio NS_REQUIRES_SUPER;

@end
