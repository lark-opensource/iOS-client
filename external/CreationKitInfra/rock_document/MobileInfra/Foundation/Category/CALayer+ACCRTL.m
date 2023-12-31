//
//  CALayer+ACCRTL.m
//  CameraClient-Pods-Aweme
//
// Created by Ma Chao on 2021 / 3 / 17
//

#import "CALayer+ACCRTL.h"
#import <CreationKitInfra/ACCRTLProtocol.h>

@implementation CALayer (ACCRTL)

- (CGAffineTransform)accrtl_basicTransform
{
    return [ACCRTL() accrtl_basicTransformFor:self];
}

@end
