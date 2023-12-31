//
//  TSPKDetectPlanModel.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import <Foundation/Foundation.h>

#import "TSPKDetectConsts.h"
#import "TSPKSceneRuleModel.h"


@interface TSPKDetectPlanModel : NSObject

@property (nonatomic, copy, nonnull) NSString *interestMethodType;
@property (nonatomic, copy, nullable) NSString *dataType;
@property (nonatomic) TSPKDetectTaskType taskType;
@property (nonatomic, strong, nullable) TSPKSceneRuleModel *ruleModel;

- (NSString * _Nonnull)planUid;

- (TSPKDetectTriggerType)triggerType;

@end

