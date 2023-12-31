//
//  UILabel+IESLiveResouceStyle.m
//  Pods
//
//  Created by Zeus on 17/1/10.
//
//

#import "UILabel+IESLiveResouceStyle.h"
#import "IESLiveResouceStyleModel.h"

@implementation UILabel (IESLiveResouceStyle)

-(void)setStyleModel:(IESLiveResouceStyleModel *)styleModel{
    [super setStyleModel:styleModel];
    if (styleModel.font) {
        self.font = styleModel.font;
    }
    if (styleModel.textColor) {
        self.textColor = styleModel.textColor;
    }
}

@end
