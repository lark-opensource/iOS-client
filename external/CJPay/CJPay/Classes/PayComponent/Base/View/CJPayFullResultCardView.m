//
//  CJPayFullResultCardView.m
//  CJPaySandBox
//
//  Created by wangxiaohong on 2023/3/9.
//

#import "CJPayFullResultCardView.h"
#import "CJPayUIMacro.h"

@implementation CJPayFullResultCardView

- (void)resetLynxCardSize:(CGSize)size {
    CGFloat width = size.width > 0 ? size.width : self.frame.size.width;
    CGFloat height = size.height > 0 ? size.height : self.frame.size.height;
    CJPayMasUpdate(self, {
        make.height.mas_equalTo(height);
        make.width.mas_equalTo(width);
    });
    [self setNeedsLayout];
}

@end
