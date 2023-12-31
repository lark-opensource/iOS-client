//
//  HMDDebugRealConfig.h
//  Heimdallr
//
//  Created by joy on 2018/4/19.
//

#import <Foundation/Foundation.h>

extern NSString *const kHMDALogConfig;

@interface HMDDebugRealConfig : NSObject

@property (nonatomic, assign) NSTimeInterval fetchStartTime;
@property (nonatomic, assign) NSTimeInterval fetchEndTime;
@property (nonatomic, strong) NSArray *uploadTypeArray;
@property (nonatomic, strong) NSMutableArray *uploadFileTypeArray;
@property (nonatomic, assign) BOOL isNeedWifi;
@property (nonatomic, assign) NSUInteger limitCnt;
@property (nonatomic, strong) NSArray *andConditions;
@property (nonatomic, strong) NSArray *orConditions;

- (instancetype)initWithParams:(NSDictionary *)params;
- (BOOL)checkIfAllowedDebugRealUploadWithType:(NSString *)type;
- (BOOL)checkIfNetworkAllowedDebugRealUpload;

@end
