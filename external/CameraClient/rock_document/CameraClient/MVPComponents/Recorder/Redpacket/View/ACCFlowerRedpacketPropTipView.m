//
//  ACCFlowerRedpacketPropTipView.m
//  Indexer
//
//  Created by imqiuhang on 2021/11/29.
//

#import "ACCFlowerRedpacketPropTipView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIFont+ACC.h>
#import <CreativeKit/ACCMacros.h>

@implementation ACCFlowerRedpacketPropTipView

- (void)showOnView:(UIView *)rootView text:(nonnull NSString *)text
{
    if (self.superview != nil || !rootView) {
        return;
    }
    
    self.userInteractionEnabled = NO;
    
    self.textColor = [UIColor whiteColor];
    self.font = [UIFont acc_pingFangSemibold:22.f];
    self.text = text;
    self.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.25].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 2);
    self.layer.shouldRasterize = YES;
    self.layer.shadowRadius = 2.0;
    self.layer.shadowOpacity = 1.0;
    [self sizeToFit];
    
    [rootView addSubview:self];
    
    ACCMasMaker(self, {
        make.centerY.equalTo(rootView).multipliedBy(0.72);
        make.centerX.equalTo(rootView);
    });
    
    self.alpha = 0.f;
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1.f;
    }];
    
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        [self p_hide];
    });
}

- (void)p_hide
{
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0.f;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
