//
//  TSPKDetectTaskFactory.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/28.
//

#import <Foundation/Foundation.h>

#import "TSPKDetectTask.h"
#import "TSPKDetectConsts.h"
#import "TSPKDetectEvent.h"


@interface TSPKDetectTaskFactory : NSObject

+ (TSPKDetectTask *_Nonnull)taskOfType:(TSPKDetectTaskType)taskType event:(TSPKDetectEvent *_Nonnull)event;

@end

