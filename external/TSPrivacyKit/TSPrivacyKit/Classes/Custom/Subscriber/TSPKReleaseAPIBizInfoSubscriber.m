//
//  TSPKReleaseAPIBizInfoSubscriber.m
//  Musically
//
//  Created by bytedance on 2022/6/6.
//

#import "TSPKReleaseAPIBizInfoSubscriber.h"
#import "TSPKEvent.h"
#import "TSPKLock.h"
#import "TSPKUtils.h"

@interface TSPKReleaseAPIBizInfoSubscriber ()

@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableDictionary *> *mutableInfo;
@property (nonatomic, strong) id<TSPKLock> lock;

@end

@implementation TSPKReleaseAPIBizInfoSubscriber

+ (instancetype)sharedInstance {
    static TSPKReleaseAPIBizInfoSubscriber *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TSPKReleaseAPIBizInfoSubscriber alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _lock = [TSPKLockFactory getLock];
    }

    return self;
}

- (NSString *)uniqueId {
    return @"TSPKReleaseAPIBizInfoSubscriber";
}

- (BOOL)canHandelEvent:(TSPKEvent *)event {
    return YES;
}

- (TSPKHandleResult *_Nullable)hanleEvent:(TSPKEvent *)event {
    TSPKAPIModel *apiModel = event.eventData.apiModel;
    
    if (apiModel.apiUsageType != TSPKAPIUsageTypeStart && apiModel.apiUsageType != TSPKAPIUsageTypeStop) {
        return nil;
    }
    
    NSString *dataType = apiModel.dataType;
    if (dataType.length == 0) {
        return nil;
    }
    
    NSString *bizLine = apiModel.bizLine;
    if (bizLine.length == 0) {
        return nil;
    }
    
    NSString *midfix;
    NSString *suffix = @"Timestamp";
    if (apiModel.apiUsageType == TSPKAPIUsageTypeStart) {
        midfix = @"Open";
    } else {
        midfix = @"Close";
    }
    NSString *key = [NSString stringWithFormat:@"%@%@%@", bizLine, midfix, suffix];
    
    [self.lock lock];
    
    if (!self.mutableInfo[dataType]) {
        self.mutableInfo[dataType] = [NSMutableDictionary dictionary];
    }
    
    NSMutableDictionary *mutableApiInfo = self.mutableInfo[dataType];
    
    mutableApiInfo[key] = @([TSPKUtils getRelativeTime]);
    
    [self.lock unlock];
    
    return nil;
}

/// data apiType -> bizLine+(open/close) -> callTime
- (NSMutableDictionary <NSString *, NSMutableDictionary *> *)mutableInfo {
    if (!_mutableInfo) {
        _mutableInfo = [NSMutableDictionary dictionary];
    }
    
    return _mutableInfo;
}

- (NSDictionary *)getTimestampInfoWithDataType:(NSString *)dataType {
    NSDictionary *info;
    [self.lock lock];
    info = [self.mutableInfo[dataType] copy];
    [self.lock unlock];
    
    return info;
}

@end
