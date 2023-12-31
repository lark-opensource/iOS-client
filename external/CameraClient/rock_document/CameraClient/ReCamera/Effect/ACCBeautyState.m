//
//  ACCBeautyState.m
//  CameraClient
//
//  Created by luochaojing on 2019/12/25.
//

#import "ACCBeautyState.h"

@implementation ACCBeautyState

+ (ACCBeautyState *)state {
    ACCBeautyState *state = [[ACCBeautyState alloc] init];
    return state;
}

- (id)copyWithZone:(NSZone *)zone {
    ACCBeautyState *other = [[[self class] alloc] init];
    other.smoothValue = self.smoothValue;
    other.faceLiftValue = self.faceLiftValue;
    return other;
}

@end
