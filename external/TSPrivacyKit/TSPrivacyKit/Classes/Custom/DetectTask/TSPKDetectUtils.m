//

#import "TSPKDetectUtils.h"

#import "TSPKRelationObjectModel.h"

NSString * const TSPKReleasePrefixStr = @"<Released>";
NSString * const TSPKUnReleasePrefixStr = @"<UnReleased>";
NSString * const TSPKInvalidPrefixStr = @"<Invalid>";

@implementation TSPKDetectUtils

+ (TSPKEventData *_Nullable)createSnapshotWithDataDict:(NSDictionary * _Nonnull)dict
                                  atTimeStamp:(NSTimeInterval)timestamp
                                lastCleanTime:(NSTimeInterval)lastCleanTime
                                  inCondition:(TSPKDetectCondition * _Nonnull)condition
                                       instanceAddress:(NSString * _Nullable)instanceAddress
{
    NSString *extraInfo = @"";
    TSPKEventData *newEvent = nil;
    
    if (instanceAddress.length > 0 && dict[instanceAddress]) {
        extraInfo = [self createSnapshotStringWithDict:dict key:instanceAddress atTimeStamp:timestamp inCondition:condition];
        
        TSPKRelationObjectModel *objectModel = (TSPKRelationObjectModel *)dict[instanceAddress];
        newEvent = [[objectModel getLatestOpenEventData] copy];
    } else {
        // key is instaceAddress
        for (NSString *key in dict.allKeys) {
            NSString *snapshot = [self createSnapshotStringWithDict:dict key:key atTimeStamp:timestamp inCondition:condition];
            
            extraInfo = [extraInfo length] > 0 ? [NSString stringWithFormat:@"%@\n%@", extraInfo, snapshot] : snapshot;//new line
            
            TSPKRelationObjectModel *objectModel = (TSPKRelationObjectModel *)dict[key];
            BOOL isUnrelease = (objectModel.objectStatus == TSPKRelationObjectStatusStart);
            // subEvents used to downgrade
            if (isUnrelease) {
                TSPKEventData *recordEvent = [[objectModel checkUnreleaseStartAtTime:timestamp condition:condition] copy];
                
                if (newEvent == nil) {
                    newEvent = [recordEvent copy];
                }
                
                if (recordEvent) {
                    [newEvent.subEvents addObject:recordEvent];
                }
            }
        }
    }
    
    // snapshot footer
    if (lastCleanTime > 0) {
        NSTimeInterval gap = timestamp - lastCleanTime;
        extraInfo = [NSString stringWithFormat:@"%@\nCleanTime:%.2f,", extraInfo, gap];
    }
    if (condition.timeGapToCancelDetect > 0) {
        NSTimeInterval detectTime = timestamp - condition.timeGapToCancelDetect;
        extraInfo = [NSString stringWithFormat:@"%@\nDetectTime:%.2f,TimeGap:%.2f", extraInfo, detectTime, condition.timeGapToCancelDetect];
    } else {
        extraInfo = [NSString stringWithFormat:@"%@\nDetectTime:%.2f", extraInfo, timestamp];
    }
    newEvent.extraInfo = extraInfo;

    return newEvent;
}

+ (NSString *)createSnapshotStringWithDict:(NSDictionary * _Nonnull)dict
                                       key:(NSString *)key
                                  atTimeStamp:(NSTimeInterval)timestamp
                                  inCondition:(TSPKDetectCondition * _Nonnull)condition {
    TSPKRelationObjectModel *objectModel = (TSPKRelationObjectModel *)dict[key];
    NSString *snapshot = [objectModel snapshotAtTime:timestamp condition:condition];
    snapshot = [NSString stringWithFormat:@"%@:%@", key, snapshot];
    
    BOOL isUnrelease = (objectModel.objectStatus == TSPKRelationObjectStatusStart);
    BOOL validStatus = (objectModel.objectStatus != TSPKRelationObjectStatusDefault);
    
    NSString *prefix = TSPKInvalidPrefixStr;
    if (validStatus) {
        prefix = isUnrelease ? TSPKUnReleasePrefixStr : TSPKReleasePrefixStr;
    }
    snapshot = [NSString stringWithFormat:@"%@%@", prefix, snapshot];
 
    return snapshot;
}

+ (TSPKEventData *_Nullable)createSnapshotWithDataDict:(NSDictionary * _Nonnull)dict
                                  atTimeStamp:(NSTimeInterval)timestamp
                                lastCleanTime:(NSTimeInterval)lastCleanTime
                                           inCondition:(TSPKDetectCondition * _Nonnull)condition {
    return [self createSnapshotWithDataDict:dict atTimeStamp:timestamp lastCleanTime:lastCleanTime inCondition:condition instanceAddress:nil];
}

@end
