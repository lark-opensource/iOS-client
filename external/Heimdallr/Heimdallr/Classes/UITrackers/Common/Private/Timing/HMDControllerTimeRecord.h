//
//  HMDControllerTimeRecord.h
//  Heimdallr
//
//  Created by joy on 2018/5/10.
//

#import <Foundation/Foundation.h>
#import "HMDRecordStoreObject.h"

@interface HMDControllerTimeRecord : NSObject<HMDRecordStoreObject>

@property (nonatomic, assign) NSUInteger localID;
@property (nonatomic, assign) NSUInteger sequenceCode;
@property (nonatomic, copy) NSString *sessionID;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, assign) NSTimeInterval inAppTime;
@property (nonatomic, copy) NSString *pageName;
@property (nonatomic, copy) NSString *typeName;
@property (nonatomic, assign) NSTimeInterval timeInterval;
@property (nonatomic, assign) NSUInteger isReported;
@property (nonatomic, assign) NSUInteger isFirstOpen;
@property (nonatomic, assign) NSUInteger enableUpload;
@property (nonatomic, assign) NSInteger netQualityType;

+ (instancetype)newRecord;

- (NSDictionary *)reportDictionary;
@end
