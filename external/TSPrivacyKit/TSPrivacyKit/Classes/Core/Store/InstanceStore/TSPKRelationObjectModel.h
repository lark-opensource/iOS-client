//
//  TSPKRelationObjectModel.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/26.
//

#import <Foundation/Foundation.h>

#import "TSPKEventData.h"
#import "TSPKDetectCondition.h"



typedef NS_ENUM(NSUInteger, TSPKRelationObjectStatus) {
    TSPKRelationObjectStatusDefault,
    TSPKRelationObjectStatusStart,
    TSPKRelationObjectStatusStop,
    TSPKRelationObjectStatusDealloc
};

@interface TSPKRelationObjectModel : NSObject

@property (nonatomic, readonly) TSPKRelationObjectStatus objectStatus;
@property (nonatomic, readonly) NSTimeInterval updateTimeStamp;
@property (nonatomic) NSTimeInterval reportTimeStamp;

- (void)saveEventData:(nullable TSPKEventData *)eventData;

- (BOOL)sameSinceLastReport;

- (nullable TSPKEventData *)checkUnreleaseStartAtTime:(NSTimeInterval)timestamp condition:(nullable TSPKDetectCondition *)condition;

- (nullable NSString *)snapshotAtTime:(NSTimeInterval)timestamp condition:(nullable TSPKDetectCondition *)condition;

- (void)removeLastStartBacktrace;

- (nullable TSPKEventData *)getLatestOpenEventData;

@end


