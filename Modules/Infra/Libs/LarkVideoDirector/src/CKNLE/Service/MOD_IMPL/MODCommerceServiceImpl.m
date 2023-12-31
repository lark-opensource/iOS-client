//
//  MODCommerceServiceImpl.m
//  CameraClient
//
//  Created by haoyipeng on 2021/11/1.
//  Copyright © 2021 chengfei xiao. All rights reserved.
//

#import "MODCommerceServiceImpl.h"

@implementation MODCommerceServiceImpl

- (BOOL)isFromMissionQuickStartWithPublishViewModel:(nonnull AWEVideoPublishViewModel *)publishModel {
    return NO;
}

- (void)runTasksWithContext:(ACCAdTaskContextBuildBlock _Nullable)ctxBuilder runTasks:(NSArray * _Nullable)tasks {
    
}

- (BOOL)shouldUseCommerceMusic {
    return NO;
}

- (void)trackWithContext:(ACCAdTrackContextBuildBlock _Nullable)block {

}

- (BOOL)isEnterFromECommerceComment:(nullable id<ACCPublishRepository>)model {
    return NO;
}

@end
