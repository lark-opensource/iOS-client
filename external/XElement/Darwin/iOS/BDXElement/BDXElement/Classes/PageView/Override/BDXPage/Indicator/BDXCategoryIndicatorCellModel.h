//
//  BDXCategoryComponentCellModel.h
//  DQGuess
//
//  Created by jiaxin on 2018/7/25.
//  Copyright © 2018年 jingbo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDXCategoryBaseCellModel.h"

@interface BDXCategoryIndicatorCellModel : BDXCategoryBaseCellModel

@property (nonatomic, assign, getter=isSepratorLineShowEnabled) BOOL sepratorLineShowEnabled;
@property (nonatomic, strong) UIColor *separatorLineColor;
@property (nonatomic, assign) CGSize separatorLineSize;

@property (nonatomic, assign) CGRect backgroundViewMaskFrame; 

@property (nonatomic, assign, getter=isCellBackgroundColorGradientEnabled) BOOL cellBackgroundColorGradientEnabled;
@property (nonatomic, strong) UIColor *cellBackgroundSelectedColor;
@property (nonatomic, strong) UIColor *cellBackgroundUnselectedColor;

@end
