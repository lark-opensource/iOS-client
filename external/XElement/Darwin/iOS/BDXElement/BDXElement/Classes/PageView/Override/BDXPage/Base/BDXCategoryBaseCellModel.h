//
//  BDXCategoryBaseCellModel.h

//
//  Created by jiaxin on 2018/3/15.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BDXCategoryViewDefines.h"

@interface BDXCategoryBaseCellModel : NSObject

@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign) CGFloat cellWidth;
@property (nonatomic, assign) CGFloat cellSpacing;
@property (nonatomic, assign, getter=isSelected) BOOL selected;

@property (nonatomic, assign, getter=isCellWidthZoomEnabled) BOOL cellWidthZoomEnabled;
@property (nonatomic, assign) CGFloat cellWidthNormalZoomScale;
@property (nonatomic, assign) CGFloat cellWidthCurrentZoomScale;
@property (nonatomic, assign) CGFloat cellWidthSelectedZoomScale;

@property (nonatomic, assign, getter=isSelectedAnimationEnabled) BOOL selectedAnimationEnabled;
@property (nonatomic, assign) NSTimeInterval selectedAnimationDuration;
@property (nonatomic, assign) BDXCategoryCellSelectedType selectedType;

@property (nonatomic, assign, getter=isTransitionAnimating) BOOL transitionAnimating;

@end
