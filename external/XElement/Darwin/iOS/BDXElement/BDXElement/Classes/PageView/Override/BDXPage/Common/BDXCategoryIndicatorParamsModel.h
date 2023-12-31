//
//  BDXCategoryIndicatorParamsModel.h
//  BDXCategoryView
//
//  Created by jiaxin on 2018/12/13.
//  Copyright © 2018 jiaxin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BDXCategoryViewDefines.h"


@interface BDXCategoryIndicatorParamsModel : NSObject

@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) CGRect selectedCellFrame;
@property (nonatomic, assign) NSInteger leftIndex;
@property (nonatomic, assign) CGRect leftCellFrame;
@property (nonatomic, assign) NSInteger rightIndex;
@property (nonatomic, assign) CGRect rightCellFrame;
@property (nonatomic, assign) CGFloat percent;
@property (nonatomic, assign) NSInteger lastSelectedIndex;
@property (nonatomic, assign) BDXCategoryCellSelectedType selectedType; 

@end
