//
//  EMAPageIndcatorView.h
//  TTMicroApp
//
//  Created by yinyuan on 2018/12/13.
//

#import <UIKit/UIKit.h>

@interface EMAPageIndcatorView : UIView

/// 小圆点宽高
@property (nonatomic, assign) CGFloat dotSize;

/// 小圆点间距
@property (nonatomic, assign) CGFloat dotMargin;

/// 小圆点选中颜色
@property (nonatomic, strong) UIColor *selectedColor;

/// 小圆点未选中颜色
@property (nonatomic, strong) UIColor *unselectedColor;

/// 总页数
@property (nonatomic, assign) NSUInteger totalPage;

/// 当前页数
@property (nonatomic, assign) NSUInteger currentPage;

// 只有一个页面时，隐藏所有的点
@property (nonatomic, assign) BOOL hideDotsWhenOnlyOnePage;

@end
