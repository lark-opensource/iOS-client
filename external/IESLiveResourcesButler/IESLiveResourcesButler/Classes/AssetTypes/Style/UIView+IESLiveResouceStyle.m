//
//  UIView+IESLiveResouceStyle.m
//  Pods
//
//  Created by Zeus on 17/1/10.
//
//

#import "UIView+IESLiveResouceStyle.h"
#import "IESLiveResouceStyleModel.h"

@implementation UIView (IESLiveResouceStyle)
@dynamic styleModel;

- (void)setStyleModel:(IESLiveResouceStyleModel *)styleModel
{
    if (styleModel.clipsToBounds) {
        self.clipsToBounds = [styleModel.clipsToBounds boolValue];
    }
    if (styleModel.backgroudColor) {
        self.backgroundColor = styleModel.backgroudColor;
    }
    if (styleModel.alpha) {
        self.alpha = [styleModel.alpha floatValue];
    }
    if (styleModel.borderColor) {
        self.layer.borderColor = styleModel.borderColor.CGColor;
    }
    if (styleModel.borderWidth) {
        self.layer.borderWidth = [styleModel.borderWidth floatValue];
    }
    if (styleModel.cornerRadius) {
        self.layer.cornerRadius = [styleModel.cornerRadius floatValue];
    }
}

@end
