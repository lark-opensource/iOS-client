//
//  HMDTrackerRecord.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import <Foundation/Foundation.h>
#import "HMDRecordStoreObject.h"

@class HMDApplicationSession;
@interface HMDTrackerRecord : NSObject<HMDRecordStoreObject>

@property (nonatomic, assign) NSUInteger localID;
@property (nonatomic, assign) NSUInteger sequenceCode;
@property (nonatomic, copy, nullable) NSString *sessionID;
@property (nonatomic, assign) CFTimeInterval timestamp;
@property (nonatomic, assign) CFTimeInterval inAppTime;
@property (nonatomic, assign) NSUInteger enableUpload;

//env info
@property (nonatomic, copy, nullable) NSString *osVersion;
@property (nonatomic, copy, nullable) NSString *appVersion;
@property (nonatomic, copy, nullable) NSString *buildVersion;
@property (nonatomic, copy, nullable) NSString *sdkVersion;

// net quality
@property (nonatomic, assign) NSInteger netQualityType;

+ (instancetype _Nullable)newRecord;

//TODO: 应该把record转上报数据的逻辑移到model层
- (NSDictionary * _Nullable)environmentInfo;

//subclass can override
- (void)recoverWithSessionRecord:(HMDApplicationSession * _Nullable)sessionRecord;


- (NSDictionary * _Nullable)reportDictionary;

@end
