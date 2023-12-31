//
//  BDXCategoryIndicatorImageView.h
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/17.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryIndicatorComponentView.h"

@interface BDXCategoryIndicatorImageView : BDXCategoryIndicatorComponentView

@property (nonatomic, strong, readonly) UIImageView *indicatorImageView;

@property (nonatomic, assign) BOOL indicatorImageViewRollEnabled;

@property (nonatomic, assign) CGSize indicatorImageViewSize;

@end
