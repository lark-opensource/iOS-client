//
//  ACCPropExploreExperimentalControl.h
//  CameraClient-Pods-AwemeCore
//
//  Created by wanghongyu on 2021/10/28.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

@interface ACCPropExploreExperimentalControl : NSObject

+ (instancetype)sharedInstance;

- (void)setPublishModel:(nonnull AWEVideoPublishViewModel *)publishModel;

- (BOOL)hiddenSearchEntry;

@end

