//
//  BDABTestBaseExperiment+Private.m
//  AFgzipRequestSerializer
//
//  Created by xushuangqing on 2018/10/8.
//

#import "BDABTestBaseExperiment+Private.h"
#import "BDABTestExposureManager.h"
#import "BDABTestExperimentItemModel.h"

@implementation BDABTestBaseExperiment (Private)

- (BOOL)hasExposed {
    BDABTestExperimentItemModel *result = [self getResultWithExposure:NO];
    if (result.vid == nil) {
        return NO;
    }
    else {
        return [[[BDABTestExposureManager sharedManager] exposureVidString] containsString:[result.vid stringValue]];
    }
}

@end
