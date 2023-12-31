//
//  TSPKDetectTaskFactory.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/28.
//

#import "TSPKDetectTaskFactory.h"
#import "TSPKDetectReleaseStatusTask.h"
#import "TSPKDetectReleaseBadCaseTask.h"

@implementation TSPKDetectTaskFactory

+ (TSPKDetectTask *_Nonnull)taskOfType:(TSPKDetectTaskType)taskType event:(TSPKDetectEvent *_Nonnull)event
{
    if (taskType == TSPKDetectTaskTypeDetectReleaseBadCase) {
        return [[TSPKDetectReleaseBadCaseTask alloc] initWithDetectEvent:event];
    } else if (taskType == TSPKDetectTaskTypeDetectReleaseStatus) {
        return [[TSPKDetectReleaseStatusTask alloc] initWithDetectEvent:event];
    }
    return nil;
}

@end
