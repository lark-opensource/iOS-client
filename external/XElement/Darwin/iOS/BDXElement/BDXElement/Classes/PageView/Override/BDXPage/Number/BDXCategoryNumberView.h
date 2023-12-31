//
//  BDXCategoryNumberView.h
//  DQGuess
//
//  Created by jiaxin on 2018/4/9.
//  Copyright © 2018年 jingbo. All rights reserved.
//

#import "BDXCategoryTitleView.h"
#import "BDXCategoryNumberCell.h"
#import "BDXCategoryNumberCellModel.h"

@interface BDXCategoryNumberView : BDXCategoryTitleView

@property (nonatomic, strong) NSArray <NSNumber *> *counts;

@property (nonatomic, copy) NSString *(^numberStringFormatterBlock)(NSInteger number);

@property (nonatomic, strong) UIFont *numberLabelFont;

@property (nonatomic, strong) UIColor *numberBackgroundColor;

@property (nonatomic, strong) UIColor *numberTitleColor;

@property (nonatomic, assign) CGFloat numberLabelWidthIncrement;

@property (nonatomic, assign) CGFloat numberLabelHeight;

@property (nonatomic, assign) CGPoint numberLabelOffset;

@property (nonatomic, assign) BOOL shouldMakeRoundWhenSingleNumber;

@end
