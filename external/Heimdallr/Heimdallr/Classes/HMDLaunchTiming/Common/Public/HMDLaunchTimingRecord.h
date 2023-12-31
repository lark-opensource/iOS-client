//
//  HMDLaunchTimingRecord.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/5/31.
//

#import <Foundation/Foundation.h>
#import "HMDRecordStoreObject.h"


#pragma mark --- report key define 
extern NSString * _Nonnull const kHMDLaunchTimingKeyLogType;
extern NSString * _Nonnull const kHMDLaunchTimingKeyNetworkQuality;
extern NSString * _Nonnull const kHMDLaunchTimingKeySessionId;
extern NSString * _Nonnull const kHMDLaunchTimingKeyNetworkType;
extern NSString * _Nonnull const kHMDLaunchTimingKeyLogID;
extern NSString * _Nonnull const kHMDlaunchTimingKeyService;
extern NSString * _Nonnull const kHMDLaunchTimingValueLogType;
extern NSString * _Nonnull const kHMDLaunchTimingValueService;
extern NSString * _Nonnull const kHMDLaunchTimingKeyName;
extern NSString * _Nonnull const kHMDLaunchTimingKeyPageType;
extern NSString * _Nonnull const kHMDLaunchTimingKeyStart;
extern NSString * _Nonnull const kHMDlaunchTimingKeyEnd;
extern NSString * _Nonnull const kHMDLaunchTimingKeySpans;
extern NSString * _Nonnull const kHMDLaunchTimingModuleName;
extern NSString * _Nonnull const kHMDLaunchTimingSpanName;
extern NSString * _Nonnull const kHMDLaunchTimingKeyCollectFrom;
extern NSString * _Nonnull const kHMDLaunchTimingKeyPageName;
extern NSString * _Nonnull const kHMDLaunchTimingKeyCustomModel;
extern NSString * _Nonnull const kHMDLaunchTimingKeyTrace;
extern NSString * _Nonnull const kHMDLaunchTimingKeyPerfData;
extern NSString * _Nonnull const kHMDLaunchTimingKeyListData;
extern NSString * _Nonnull const kHMDLaunchTimingKeyThreadList;
extern NSString * _Nonnull const kHMDLaunchTimingKeyModuleName;
extern NSString * _Nonnull const kHMDLaunchTimingKeySpanName;
extern NSString * _Nonnull const kHMDLaunchTimingKeyThread;
extern NSString * _Nonnull const kHMDLaunchTimingKeyPrewarm;

@interface HMDLaunchTimingRecord : NSObject <HMDRecordStoreObject>

@property (nonatomic, assign) NSUInteger localID;
@property (nonatomic, assign) NSUInteger sequenceCode;
@property (nonatomic, assign) CFTimeInterval timestamp;
@property (nonatomic, assign) CFTimeInterval timeInterval;
@property (nonatomic, assign) NSInteger netQualityType;
@property (nonatomic, assign) NSInteger netType;
@property (nonatomic, assign) NSUInteger enableUpload;
@property (nonatomic, copy, nullable) NSString *sessionID;
@property (nonatomic, copy, nullable) NSDictionary *perfData;
@property (nonatomic, copy, nullable) NSDictionary *trace;

+ (instancetype _Nonnull)newRecord;
+ (NSString * _Nonnull)tableName;
- (NSDictionary * _Nonnull)reportDictWithDebugReal:(BOOL)debugReal;

- (NSDictionary *_Nullable)reportDictionary;
@end

