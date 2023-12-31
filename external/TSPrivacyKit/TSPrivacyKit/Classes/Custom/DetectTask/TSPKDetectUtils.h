//

#import <Foundation/Foundation.h>

#import "TSPKEventData.h"
#import "TSPKDetectCondition.h"


@interface TSPKDetectUtils : NSObject

+ (TSPKEventData *_Nullable)createSnapshotWithDataDict:(NSDictionary * _Nonnull)dict
                                  atTimeStamp:(NSTimeInterval)timestamp
                                lastCleanTime:(NSTimeInterval)lastCleanTime
                                  inCondition:(TSPKDetectCondition * _Nonnull)condition;

/// only create one instance snapshot
+ (TSPKEventData *_Nullable)createSnapshotWithDataDict:(NSDictionary * _Nonnull)dict
                                  atTimeStamp:(NSTimeInterval)timestamp
                                lastCleanTime:(NSTimeInterval)lastCleanTime
                                  inCondition:(TSPKDetectCondition * _Nonnull)condition
                                       instanceAddress:(NSString * _Nullable)instanceAddress;

@end

