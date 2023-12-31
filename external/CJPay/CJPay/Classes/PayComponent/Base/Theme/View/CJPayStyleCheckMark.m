//
//  CJPayStyleCheckMark.m
//  CJPay
//
//  Created by liyu on 2019/10/28.
//

#import "CJPayStyleCheckMark.h"

#import "CJPayUIMacro.h"

static CGFloat const kDiameter = 20;

@implementation CJPayStyleCheckMark

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self cj_showCornerRadius:kDiameter/2];
        
        [self p_applyDefaultAppearance];
        [self setEnable:YES];
        [self setSelected:YES];
    }
    return self;
}

- (instancetype)initWithDiameter:(CGFloat)diameter {
    self = [super init];
    if (self) {
        CGFloat checkdiameter = diameter ?: kDiameter;
        [self cj_showCornerRadius:checkdiameter/2];
        [self p_applyDefaultAppearance];
        [self setEnable:YES];
        [self setSelected:YES];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    if (CGRectEqualToRect(self.bounds, CGRectZero)) {
        return CGSizeMake(kDiameter, kDiameter);
    } else {
        return CGSizeMake(self.bounds.size.width, self.bounds.size.height);
    }
}

- (void)p_applyDefaultAppearance {
    CJPayStyleCheckMark *appearance = [CJPayStyleCheckMark appearance];
    if (appearance.backgroundColor == nil) {
        self.backgroundColor = [UIColor cj_fe2c55ff];
    }
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    if (selected) {
        @CJWeakify(self)
        [self cj_setImage:@"cj_select_icon" completion:^(BOOL isSuccess) {
            @CJStrongify(self)
            if (isSuccess) {
                self.backgroundColor = [CJPayStyleCheckMark appearance].backgroundColor ?: [UIColor cj_fe2c55ff];
            }
        }];
    } else {
        self.backgroundColor = [UIColor clearColor];
        [self cj_setImage:self.enable ? @"cj_noselect_icon" : @"cj_disable_check_icon"];
    }
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    if (self.selected) {
        return;
    }
    [self cj_setImage:enable ? @"cj_noselect_icon" : @"cj_disable_check_icon"];
}

@end
