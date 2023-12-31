//
//  AWEEditPageProtocol.h
//  AWEStudio
//
//  Created by hanxu on 2018/11/3.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCEditViewControllerInputData.h"

@protocol ACCEditServiceProtocol;

@protocol AWEEditPageProtocol <NSObject>

@property (nonatomic, strong, readonly) ACCEditViewControllerInputData *inputData;

- (AWEVideoPublishViewModel *)publishModel;
- (AWEVideoPublishViewModel *)sourceModel;
- (void)setCoverImage:(UIImage *)image;

@optional
- (id<ACCEditServiceProtocol>)pageEditService;
- (AWEEditAndPublishCancelBlock)cancelBlock; // nav dismiss 时的回调。

@end
