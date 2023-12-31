//
//  TSPKDetectPlan.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import <Foundation/Foundation.h>

#import "TSPKDetectEvent.h"
#import "TSPKDetectPlanModel.h"


@protocol TSPKDetectPlanDelegate <NSObject>

- (void)handleDetectEvent:(TSPKDetectEvent *_Nullable)detectEvent;

@end

@interface TSPKDetectPlan : NSObject

@property (nonatomic, weak, nullable) id<TSPKDetectPlanDelegate> delegate;

- (instancetype _Nullable)initWithPlanModel:(TSPKDetectPlanModel *_Nullable)planModel;

- (void)updateWithPlanModel:(TSPKDetectPlanModel *_Nullable)planModel;

@end

