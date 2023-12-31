//
//  HMDUITrackRecord.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/12.
//

#import "HMDUITrackableContext.h"
#import "HMDRecordStoreObject.h"

@interface HMDUITrackRecord : NSObject<HMDRecordStoreObject>

@property (nonatomic, assign) NSUInteger localID;
@property (nonatomic, assign) NSUInteger sequenceCode;
@property (nonatomic, assign) CFTimeInterval inAppTime;
@property (nonatomic, copy) NSString *sessionID;

@property (nonatomic, assign) CFTimeInterval timestamp;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *event;
@property (nonatomic, strong) NSDictionary *extraInfo;
@property (nonatomic, weak) HMDUITrackableContext *context;
@property (nonatomic, assign) NSUInteger enableUpload;

+ (instancetype)newRecord;

- (NSDictionary *)reportDictionary;

@end

