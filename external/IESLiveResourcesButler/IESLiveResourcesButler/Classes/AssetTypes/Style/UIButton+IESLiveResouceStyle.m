//
//  UIButton+IESLiveResouceStyle.m
//  Pods
//
//  Created by Zeus on 17/1/10.
//
//

#import "UIButton+IESLiveResouceStyle.h"
#import "UIView+IESLiveResouceStyle.h"
#import "IESLiveResouceStyleModel.h"

@implementation UIButton (IESLiveResouceStyle)

- (void)setStyleModel:(IESLiveResouceStyleModel *)styleModel
{
    [super setStyleModel:styleModel];
    if (styleModel.textColor) {
        [self setTitleColor:styleModel.textColor forState:UIControlStateNormal];
    }
}

@end
