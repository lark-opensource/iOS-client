//
//  ACCEditorVolumeComponent.m
//  CameraClient-Pods-AwemeCore
//
//  Created by yangguocheng on 2021/9/26.
//

#import "ACCEditorVolumeComponent.h"
#import "ACCEditVolumeBizModule.h"

@implementation ACCEditorVolumeComponent

- (void)setupWithCompletion:(void (^)(NSError *))completion
{
    ACCEditVolumeBizModule *volumeBizModule = [[ACCEditVolumeBizModule alloc] initWithServiceProvider:self.serviceProvider];
    [volumeBizModule setup];
    if (completion) {
        completion(nil);
    }
}

@end
