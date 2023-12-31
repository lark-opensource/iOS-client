//
//  TSPKDetectEvent.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import <Foundation/Foundation.h>

#import "TSPKDetectCondition.h"
#import "TSPKEventData.h"
#import "TSPKDetectConsts.h"
#import "TSPKDetectPlanModel.h"
#import "TSPKBaseEvent.h"

extern NSString *_Nonnull const TSPKEventTagDetectEvent;

@interface TSPKDetectEvent : TSPKBaseEvent

@property (nonatomic, strong, nullable) TSPKDetectCondition *condition;
@property (nonatomic, strong, nonnull) TSPKEventData *eventData;
@property (nonatomic, strong, nonnull) TSPKDetectPlanModel *detectPlanModel;

- (TSPKDetectTaskType)taskType;

@end


