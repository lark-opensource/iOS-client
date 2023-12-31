//
//  CJPayBaseListViewModel.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/18.
//

#import "CJPayBaseListViewModel.h"
#import "CJPayBaseListCellView.h"
#import "CJPayCommonListViewController.h"

@implementation CJPayBaseListViewModel

- (instancetype)initWithViewController:(CJPayCommonListViewController *)vc {
    self = [super init];
    if (self) {
        self.viewController = vc;
    }
    return self;
}

- (CGFloat)getViewHeight {
    return self.viewHeight;
}

- (Class)getViewClass {
    if (self.viewClass) {
        return self.viewClass;
    }
    return [CJPayBaseListCellView class];
}

- (CGFloat)getTopMarginHeight {
    return self.topMarginHeight;
}

- (CGFloat)getBottomMarginHeight {
    return self.bottomMarginHeight;
}

- (UIColor *)getTopMarginColor {
    if (self.topMarginColor) {
        return self.topMarginColor;
    }
    return UIColor.grayColor;
}

- (UIColor *)getBottomMarginColor {
    if (self.bottomMarginColor) {
        return self.bottomMarginColor;
    }
    return UIColor.grayColor;
}

@end
