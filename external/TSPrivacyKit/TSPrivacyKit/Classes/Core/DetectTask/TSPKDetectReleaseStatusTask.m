//
//  TSPKDetectReleaseStatusTask.m
//  Indexer
//
//  Created by bytedance on 2022/2/17.
//

#import "TSPKDetectReleaseStatusTask.h"
#import "TSPKEventManager.h"
#import "TSPKEvent.h"

@implementation TSPKDetectReleaseStatusTask

- (void)handleDetectResult:(TSPKDetectResult *)result
           detectTimeStamp:(NSTimeInterval)detectTimeStamp
                     store:(id<TSPKStore>)store
                      info:(NSDictionary *)dict {
    TSPKEvent *event = [TSPKEvent new];
    
    event.eventType = TSPKEventTypeReleaseTypeStatus;
    TSPKEventData *eventData = [TSPKEventData new];
    eventData.isReleased = result.isRecordStopped;
    
    TSPKAPIModel *apiModel = [TSPKAPIModel new];
    apiModel.pipelineType = self.detectEvent.detectPlanModel.interestMethodType;
    apiModel.dataType = self.detectEvent.detectPlanModel.dataType;
    eventData.apiModel = apiModel;
    
    event.eventData = eventData;
    
    [TSPKEventManager dispatchEvent:event];
    
    [self markTaskFinish];
}

@end
