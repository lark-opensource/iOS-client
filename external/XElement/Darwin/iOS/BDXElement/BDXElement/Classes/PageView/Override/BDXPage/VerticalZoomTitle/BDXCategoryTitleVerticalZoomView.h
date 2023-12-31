//
//  BDXCategoryTitleVerticalZoomView.h
//  BDXCategoryView
//
//  Created by jiaxin on 2019/2/14.
//  Copyright © 2019 jiaxin. All rights reserved.
//

#import "BDXCategoryTitleView.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDXCategoryTitleVerticalZoomView : BDXCategoryTitleView

@property (nonatomic, assign) CGFloat maxVerticalFontScale;
@property (nonatomic, assign) CGFloat minVerticalFontScale;
@property (nonatomic, assign) CGFloat maxVerticalCellSpacing;
@property (nonatomic, assign) CGFloat minVerticalCellSpacing;


- (void)listDidScrollWithVerticalHeightPercent:(CGFloat)percent;

@end

NS_ASSUME_NONNULL_END
