//
//  BDAutoTrackDevEventData.h
//  RangersAppLog
//
//  Created by bytedance on 2022/10/27.
//

#import "BDCommonEnumDefine.h"

@interface BDAutoTrackDevEventData : NSObject

@property (nonatomic, strong) NSMutableArray *statusList;
@property (nonatomic, assign) BDAutoTrackEventAllType type;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDictionary *properties;
@property (nonatomic, assign) NSInteger timestamp;

@property (nonatomic, strong) NSMutableArray<NSString *> *statusStrList;
@property (nonatomic, strong) NSString *typeStr;
@property (nonatomic, strong) NSString *propertiesJson;
@property (nonatomic, strong) NSString *timeStr;

- (void)addStatus:(BDAutoTrackEventStatus)status;

+ (NSString *)status2String:(BDAutoTrackEventStatus) status;

+ (NSString *)type2String:(BDAutoTrackEventAllType) type;

+ (BOOL)hasStatus:(BDAutoTrackEventStatus) status;

+ (BOOL)hasType:(BDAutoTrackEventAllType) type;

@end
