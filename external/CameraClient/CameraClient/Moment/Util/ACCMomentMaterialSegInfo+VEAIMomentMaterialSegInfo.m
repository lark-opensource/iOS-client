//
//  ACCMomentMaterialSegInfo+VEAIMomentMaterialSegInfo.m
//  Pods
//
//  Created by Pinka on 2020/6/10.
//

#import "ACCMomentMaterialSegInfo+VEAIMomentMaterialSegInfo.h"
#import "ACCMomentReframe+VEAIMomentReframeFrame.h"

@implementation ACCMomentMaterialSegInfo (VEAIMomentMaterialSegInfo)

- (instancetype)initWithSegInfo:(VEAIMomentMaterialSegInfo *)segInfo
{
    self = [super init];
    
    if (self) {
        self.fragmentId = segInfo.fragmentId;
        self.startTime = segInfo.startTime;
        self.endTime = segInfo.endTime;
        self.clipFrame = [[ACCMomentReframe alloc] initWithReframe:segInfo.clipFrame];
    }
    
    return self;
}

@end
