//
//  HMDRecordStore+DeleteRecord.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/19.
//

#import "HMDRecordStore.h"
#import "HMDRecordStoreObject.h"


struct HMDRecordLocalIDRange {
    NSUInteger minLocalID;
    NSUInteger maxLocalID;
};
typedef struct HMDRecordLocalIDRange HMDRecordLocalIDRange;

@interface HMDRecordStore (DeleteRecord)

- (BOOL)cleanupRecordsWithRange:(HMDRecordLocalIDRange)range
                  andConditions:(NSArray * _Nullable)andConditions
                     storeClass:(Class<HMDRecordStoreObject> _Nonnull)storeClass;

- (BOOL)logicalCleanupRecordsWithRange:(HMDRecordLocalIDRange)range
                         andConditions:(NSArray * _Nullable)andConditions
                            storeClass:(Class<HMDRecordStoreObject> _Nonnull)storeClass
                                object:(id _Nonnull)object;

+ (HMDRecordLocalIDRange)localIDRange:(NSArray * _Nullable)records;

@end

