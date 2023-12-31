//
//  ACCGamePlayServiceContainer.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/8/17.
//

#import "ACCGamePlayServiceContainer.h"
#import "ACCGamePlayNetServiceImpl.h"

@implementation ACCGamePlayServiceContainer

- (nonnull id<GPNetServiceProtocol>)provideGPNetServiceProtocol {
    return [[ACCGamePlayNetServiceImpl alloc] init];
}

@end
