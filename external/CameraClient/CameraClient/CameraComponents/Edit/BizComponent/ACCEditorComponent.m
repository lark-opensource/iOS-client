//
//  ACCEditorComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/9/18.
//

#import "ACCEditorComponent.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>

@interface ACCEditorComponent ()

@end

@implementation ACCEditorComponent

- (instancetype)initWithServiceProvider:(id<IESServiceProvider, IESServiceRegister>) serviceProvider;
{
    self = [super init];
    if (self) {
        _serviceProvider = serviceProvider;
    }
    return self;
}

- (void)setRepository:(AWEVideoPublishViewModel *)repository
{
    _repository = repository;
}

- (void)setupWithCompletion:(void (^)(NSError *))completion
{
    if (completion) {
        completion(nil);
    }
}

@end
