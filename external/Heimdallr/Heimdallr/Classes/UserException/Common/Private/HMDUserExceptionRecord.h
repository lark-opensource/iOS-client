//
//  HMDUserExceptionRecord.h
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/4/1.
//

#import "HMDTrackerRecord.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kHMDUserExceptionEventType;

@interface HMDUserExceptionRecord : HMDTrackerRecord

@property(nonatomic, strong) NSString *log;
@property(nonatomic, strong) NSString *type;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *subTitle;
@property(nonatomic, assign) BOOL needSymbolicate;
@property(nonatomic, assign) double memoryUsage;
@property(nonatomic, assign) double freeMemoryUsage;
@property(nonatomic, assign) double freeDiskUsage;
@property (nonatomic, assign) NSInteger freeDiskBlockSize;
@property(nonatomic, strong) NSString *access;
@property(nonatomic, strong) NSString *lastScene;
@property(nonatomic, strong) NSString *business;  //业务方
@property(nonatomic, strong) NSDictionary<NSString *, id> *customParams;
@property(nonatomic, strong) NSDictionary<NSString *, id> *filters;
@property(nonatomic, strong) NSDictionary *operationTrace;
@property(nonatomic, strong) NSArray<NSDictionary *> *addressList;
@property(nonatomic, strong) NSDictionary *viewHierarchy;

#if RANGERSAPM
@property(nonatomic, strong) NSString *appID;
#endif

@property(nonatomic, strong) NSString *aggregationKey;
 
@end

NS_ASSUME_NONNULL_END
