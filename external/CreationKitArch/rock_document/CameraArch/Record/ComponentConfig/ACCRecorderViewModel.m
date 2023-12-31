//
//  ACCRecorderViewModel.m
//  CameraClient
//
//  Created by DING Leo on 2020/2/11.
//

#import "ACCRecorderViewModel.h"

@implementation ACCRecorderViewModel

@synthesize serviceProvider = _serviceProvider;

- (void)onCleared
{
    
}

- (AWEVideoPublishViewModel *)repository {
    NSAssert(_repository, @"should set repository instance before access: %@", NSStringFromClass(self.class));
    return _repository;
}

@end
