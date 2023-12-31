//
//  CJPayCustomRightView.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/24.
//

#import "CJPayCustomRightView.h"
#import "CJPayUIMacro.h"
#import "CJPayButton.h"

@interface CJPayCustomRightView()

@end

@implementation CJPayCustomRightView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

#pragma mark - Private Method
- (void)p_setupUI {
    [self addSubview:self.rightButton];
    self.rightButton.cj_width = 24;
    self.rightButton.cj_height = 24;
    
    self.rightButton.center = self.center;
}

- (void)setRightButtonCenterOffset:(NSInteger)offset {
    self.rightButton.center = CGPointMake(self.center.x, self.center.y+offset);
}

#pragma mark - Public Method
- (void)setRightButtonImageWithName:(NSString *)imageName {
    [self.rightButton cj_setBtnImageWithName:CJString(imageName)];
}

#pragma mark - Getter & Setter
-(CJPayButton *)rightButton {
    if (!_rightButton) {
        _rightButton = [[CJPayButton alloc] init];
    }
    return _rightButton;
}



@end
