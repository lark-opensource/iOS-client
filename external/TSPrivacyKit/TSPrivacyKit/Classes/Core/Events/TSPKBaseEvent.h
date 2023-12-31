//
//  TSPKBaseEvent.h
//  Aweme
//
//  Created by admin on 2021/12/18.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TSPKEventType) {
    TSPKEventTypeDefault,
    
    // API Enter
    TSPKEventTypeAccessEntryHandle, // can influence decision-making, but if one subscriber build new TSPKHandleResult and paramter needFuse equal YES, subscribers after this, can't receive message
    TSPKEventTypeAccessEntryResult,
    
    TSPKEventTypeSaveRecordComplete,
    TSPKEventTypeSaveRecordFailed,
    TSPKEventTypeReleaseAPICallInfo,
    TSPKEventTypeReleaseAPIBizCallInfo,
    
    TSPKEventTypeExecuteReleaseDetect,
    TSPKEventTypeDetectBadCase,
    TSPKEventTypeIgnoreDetect,
    TSPKEventTypeReportLog,
    TSPKEventTypeReleaseTypeStatus,
    
    // Network Enter
    TSPKEventTypeNetworkRequest,
    TSPKEventTypeNetworkResponse
};

extern NSString *_Nonnull const TSPKEventTagBase;

@interface TSPKBaseEvent : NSObject

@property(nonatomic, readonly, nonnull) NSString *tag;

@end
