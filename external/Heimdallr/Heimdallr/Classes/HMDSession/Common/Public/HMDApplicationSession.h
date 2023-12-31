//
//  HMDApplicationSession.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/12.
//



#import <Foundation/Foundation.h>
#import "HMDRecordStoreObject.h"
#import "HMDBackgroundMonitor.h"

extern NSString * _Nullable kHMDSessionIDChangeNotification;
FOUNDATION_EXPORT BOOL HMDApplicationSession_backgroundState(void);

@protocol HMDApplicationSessionUpdate<NSObject>

- (void)didUpdateForProperty:(NSString * _Nullable)property;

- (void)didUpdateWithSessionDic:(NSDictionary *_Nullable)sessionDic;

@end

@interface HMDApplicationSession : NSObject<HMDRecordStoreObject>

@property (nonatomic, weak, nullable) id<HMDApplicationSessionUpdate> delegate;
@property (atomic, assign) NSUInteger localID;
@property (nonatomic, assign) NSUInteger sequenceCode;
@property (atomic, copy, nullable) NSString *sessionID;
@property (nonatomic, assign) CFTimeInterval timeInSession;
@property (atomic, assign) CFTimeInterval duration;
@property (atomic, assign) double memoryUsage;
@property (atomic, assign) double deviceMemoryUsage;
@property (atomic, assign) double freeMemory;
@property (atomic, assign) double freeDisk;
@property (atomic, assign) CFTimeInterval timestamp;
@property (atomic, copy, nullable) NSDictionary<NSString*, id> *customParams;
@property (atomic, assign, readonly, getter=isBackgroundStatus) BOOL backgroundStatus;
@property (atomic, readonly, nullable) NSString *eternalSessionID;
@property (atomic, strong, nullable) NSDictionary<NSString*, id> *filters;

@property (nonatomic, strong, nullable) NSString *osVersion;
@property (nonatomic, strong, nullable) NSString *appVersion;
@property (nonatomic, strong, nullable) NSString *buildVersion;
@property (nonatomic, strong, nullable) NSString *sdkVersion;

- (NSDictionary *_Nullable)dictionaryValue;

@end

