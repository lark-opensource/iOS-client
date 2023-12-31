//
//  HMDTTMonitorInterceptorParams.h
//  Heimdallr
//
//  Created by liuhan on 2023/9/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HMDTTMonitorStoreActionType);
typedef NS_ENUM(NSInteger, HMDTTMonitorTrackerType);

@interface HMDTTMonitorInterceptorParam : NSObject

@property (nonatomic, copy) NSString *appID;

@property (nonatomic, copy, nullable) NSString *serviceName;

@property (nonatomic, copy, nullable) NSString *logType;

@property (nonatomic, assign) HMDTTMonitorStoreActionType storeType;

@property (nonatomic, assign) HMDTTMonitorTrackerType trackType;

/// 传入数据，需要做immutablecopy
@property (nonatomic, strong) NSDictionary *wrapData;

/// 频繁上报累计数量
@property (nonatomic, assign) long accumulateCount;

/// 是否是新接口
@property (nonatomic, assign) BOOL isNewInterface;

@property (nonatomic, assign) BOOL needUpload;

@property (nonatomic, copy) NSString *traceParent;

@property (nonatomic, assign) NSInteger singlePointOnly;

@end

NS_ASSUME_NONNULL_END
