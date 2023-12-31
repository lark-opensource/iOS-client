//
//  HMDStartRecord.h
//  Heimdallr
//
//  Created by 谢俊逸 on 23/2/2018.
//

#import <Foundation/Foundation.h>
#import "HMDRecordStoreObject.h"

@interface HMDStartRecord : NSObject <HMDRecordStoreObject>

@property(nonatomic, assign) NSUInteger localID;
@property(nonatomic, assign) NSUInteger sequenceCode;
@property(nonatomic, assign) CFTimeInterval timestamp;
@property(nonatomic, assign) CFTimeInterval timeInterval;
@property(nonatomic, assign) NSUInteger enableUpload;
@property(nonatomic, assign) NSInteger netQualityType;
@property(nonatomic, assign) BOOL prewarm;
@property(nonatomic, copy, nullable) NSString *sessionID;
@property(nonatomic, copy, nullable) NSString *timeType;

- (NSDictionary *_Nonnull)reportDictionary;

@end
