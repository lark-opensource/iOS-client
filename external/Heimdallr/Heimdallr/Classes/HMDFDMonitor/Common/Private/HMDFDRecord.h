//
//  HMDFDRecord.h
//  Pods
//
//  Created by wangyinhui on 2022/2/10.
//

#import "HMDTrackerRecord.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDFDRecord : HMDTrackerRecord

@property(nonatomic, strong) NSString *log;
@property(nonatomic, assign) int maxFD;
@property(nonatomic, strong) NSDictionary *fds;
@property(nonatomic, strong) NSString *errType;
@property(nonatomic, assign) double memoryUsage;
@property(nonatomic, assign) double freeMemoryUsage;
@property(nonatomic, assign) double freeDiskUsage;
@property (nonatomic, assign) NSInteger freeDiskBlockSize;
@property(nonatomic, strong) NSString *access;
@property(nonatomic, strong) NSString *lastScene;
@property(nonatomic, strong) NSString *business;  //业务方
@property(nonatomic, strong) NSDictionary *operationTrace;

@end

NS_ASSUME_NONNULL_END

