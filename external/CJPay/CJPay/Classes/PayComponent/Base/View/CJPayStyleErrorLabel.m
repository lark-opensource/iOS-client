//
//  CJPayStyleErrorLabel.m
//  CJPay
//
//  Created by liyu on 2019/11/13.
//

#import "CJPayStyleErrorLabel.h"
#import "CJPayUIMacro.h"

@implementation CJPayStyleErrorLabel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_installAppearance];
    }
    return self;
}

- (void)p_installAppearance {
    CJPayStyleErrorLabel *appearance = [CJPayStyleErrorLabel appearance];
    if (appearance.textColor == nil) {
        self.textColor = [UIColor cj_fe2c55ff];
    } else {
        self.textColor = appearance.textColor;
    }
}

- (BOOL)isAccessibilityElement {
    return YES;
}

@end
