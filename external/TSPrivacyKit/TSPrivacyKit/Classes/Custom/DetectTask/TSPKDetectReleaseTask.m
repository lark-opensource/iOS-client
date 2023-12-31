//
//  TSPKDetectReleaseTask.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import "TSPKDetectReleaseTask.h"
#import "TSPKStoreManager.h"
#import "TSPKUtils.h"
#import "TSPKRelationObjectModel.h"

@implementation TSPKDetectResult

@end

@implementation TSPKDetectReleaseTask

- (void)setup
{
    self.onCurrentThread = NO;
    self.ignoreSameReport = NO;
}

- (void)executeWithScheduleTime:(NSTimeInterval)scheduleTime
{
    [self executeWithInstanceAddressAndScheduleTime:nil scheduleTime:scheduleTime];
}

- (void)executeWithInstanceAddressAndScheduleTime:(NSString *_Nullable)instanceAddress scheduleTime:(NSTimeInterval)scheduleTime {
    id<TSPKStore> store = [[TSPKStoreManager sharedManager] getStoreOfStoreId:self.detectEvent.detectPlanModel.interestMethodType];
    [store getStoreDataWithInstanceAddress:instanceAddress completion:^(NSDictionary * _Nonnull dict) {
        NSTimeInterval actualTimeStamp = [TSPKUtils getRelativeTime];
        
        TSPKDetectResult *result = [self checkIfRecordingStopped:dict atTimeStamp:scheduleTime];
        
        [self handleDetectResult:result detectTimeStamp:actualTimeStamp store:store info:dict];
        
    }];
}

- (void)handleDetectResult:(TSPKDetectResult *)result
           detectTimeStamp:(NSTimeInterval)detectTimeStamp
                     store:(id<TSPKStore>)store
                      info:(NSDictionary *)dict {
    
}

#pragma mark -
- (TSPKDetectResult *)checkIfRecordingStopped:(NSDictionary *_Nonnull)dict atTimeStamp:(NSTimeInterval)timestamp
{
    TSPKDetectResult *detectResult = [TSPKDetectResult new];
    detectResult.isRecordStopped = YES;
    
    for (NSString *key in dict.allKeys) {
        TSPKRelationObjectModel *objectModel = (TSPKRelationObjectModel *)dict[key];
        if (self.ignoreSameReport && [objectModel sameSinceLastReport]) {
            continue;
        }
        
        TSPKEventData *unreleaseStart = [objectModel checkUnreleaseStartAtTime:timestamp condition:self.detectEvent.condition];
        if (unreleaseStart == nil) {
            continue; // stopped or cancelled
        }
        TSPKAPIModel *apiInfo = unreleaseStart.apiModel;
        if (apiInfo.customReleaseCheckBlock) {
            TSPKCheckResult result = apiInfo.customReleaseCheckBlock(apiInfo.instance);
            if (result == TSPKCheckResultUnrelease) {
                detectResult.isRecordStopped = NO;
                detectResult.instanceAddress = apiInfo.hashTag;
                break;
            }
        } else {
            detectResult.isRecordStopped = NO;
            detectResult.instanceAddress = apiInfo.hashTag;
            break;
        }
    }
    return detectResult;
}

@end
