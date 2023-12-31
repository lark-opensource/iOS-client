//
//  ACCMomentReframe+VEAIMomentReframeFrame.m
//  Pods
//
//  Created by Pinka on 2020/6/10.
//

#import "ACCMomentReframe+VEAIMomentReframeFrame.h"

@implementation ACCMomentReframe (VEAIMomentReframeFrame)

- (instancetype)initWithReframe:(VEAIMomentReframeFrame)reframe
{
    self = [super init];
    
    if (self) {
        self.centerX = reframe.centerX;
        self.centerY = reframe.centerY;
        self.width = reframe.width;
        self.height = reframe.height;
        self.rotateAngle = reframe.rotateAngle;
    }
    
    return self;
}

@end
