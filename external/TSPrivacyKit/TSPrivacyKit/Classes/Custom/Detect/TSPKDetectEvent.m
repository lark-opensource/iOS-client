//
//  TSPKDetectEvent.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import "TSPKDetectEvent.h"

NSString * const TSPKEventTagDetectEvent = @"DetectEvent";

@implementation TSPKDetectEvent

- (NSString *)tag {
    return TSPKEventTagDetectEvent;
}

- (TSPKDetectTaskType)taskType
{
    return self.detectPlanModel.taskType;
}

@end
