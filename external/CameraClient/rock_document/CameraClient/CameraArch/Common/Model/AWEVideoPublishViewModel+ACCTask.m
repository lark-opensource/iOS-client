//
//  AWEVideoPublishViewModel+ACCTask.m
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2021/4/7.
//

#import "AWEVideoPublishViewModel+ACCTask.h"
#import <CreationKitArch/ACCRepoDraftModel.h>

@implementation AWEVideoPublishViewModel (ACCTask)

- (instancetype)initWithTaskId:(NSString *)taskId
{
    self = [self init];
    if (self) {
        self.repoDraft.taskID = taskId;
    }
    return self;
}

@end
