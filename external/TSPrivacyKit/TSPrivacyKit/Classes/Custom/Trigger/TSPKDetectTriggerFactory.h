//
//  TSPKDetectTriggerFactory.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import <Foundation/Foundation.h>

#import "TSPKDetectConsts.h"
#import "TSPKDetectTrigger.h"
#import "TSPKDetectPlanModel.h"



@interface TSPKDetectTriggerFactory : NSObject

//+ (TSPKDetectTrigger *)detectTriggerOfType:(TSPKDetectTriggerType)type params:(NSDictionary *)params;

+ (TSPKDetectTrigger * _Nullable)detectTriggerOfDetectPlanModel:(TSPKDetectPlanModel * _Nonnull)planModel;

@end


