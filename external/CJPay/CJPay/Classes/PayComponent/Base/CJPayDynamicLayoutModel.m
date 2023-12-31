//
//  CJPayDynamicLayoutModel.m
//  CJPaySandBox
//
//  Created by 利国卿 on 2023/4/22.
//

#import "CJPayDynamicLayoutModel.h"

@implementation CJPayDynamicLayoutModel

- (instancetype)initModelWithTopMargin:(CGFloat)topMargin
                          bottomMargin:(CGFloat)bottomMargin
                            leftMargin:(CGFloat)leftMargin
                           rightMargin:(CGFloat)rightMargin {
    
    self = [super init];
    if (self) {
        _topMargin = topMargin;
        _bottomMargin = bottomMargin;
        _leftMargin = leftMargin;
        _rightMargin = rightMargin;
    }
    return self;
}

@end
