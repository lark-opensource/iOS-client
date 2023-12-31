//
//  ACCEditViewModel.m
//  CameraClient
//
//  Created by liuqing on 2020/2/21.
//

#import "ACCEditViewModel.h"

@implementation ACCEditViewModel

@synthesize serviceProvider = _serviceProvider;

- (void)onCleared
{
    
}

- (AWEVideoPublishViewModel *)repository {
    NSAssert(_repository, @"should set repository instance before access: %@", NSStringFromClass(self.class));
    return _repository;
}

@end
