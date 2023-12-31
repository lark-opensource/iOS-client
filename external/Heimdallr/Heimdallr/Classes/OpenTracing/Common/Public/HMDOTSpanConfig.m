//
//  HMDOTSpanConfig.m
//  AWEAnywhereArena
//
//  Created by liuhan on 2022/6/7.
//

#import "HMDOTSpanConfig.h"
#import "NSDictionary+HMDSafe.h"

@implementation HMDOTSpanApiAllData

- (NSDictionary *_Nullable)generateMovinglineData {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data hmd_setObject:self.url forKey:@"url"];
    [data hmd_setObject:@(self.status) forKey:@"status"];
    [data hmd_setObject:@(self.duration) forKey:@"duration"];
    return [data copy];
}

@end

@implementation HMDOTSpanTTMonitorData

- (NSDictionary *_Nullable)generateMovinglineData {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data hmd_setObject:self.serviceName forKey:@"service_name"];
    [data hmd_setObject:self.logType forKey:@"log_type"];
    return [data copy];
}

@end

@implementation HMDOTSpanViewData

- (NSDictionary *_Nullable)generateMovinglineData {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data hmd_setObject:self.btm forKey:@"btm"];
    [data hmd_setObject:@(self.status) forKey:@"status"];
    return [data copy];
}

@end

@implementation HMDOTSpanCustomEventData

- (NSDictionary *_Nullable)generateMovinglineData {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setValue:self.event forKey:@"event"];
    [data hmd_setObject:@(self.threadID) forKey:@"thread_id"];
    [data hmd_setObject:self.threadName forKey:@"thread_name"];
    return [data copy];
}

@end

@interface HMDOTSpanConfig()

@property (nonatomic, copy, readwrite) NSString *operationName;

@property (atomic, copy, readwrite, nullable) NSArray<NSDictionary *> *logs;

@end

@implementation HMDOTSpanConfig

- (instancetype)initWithOperationName:(NSString *)operationName {
    if (self = [super init]) {
        self.operationName = operationName;
        self.needReferenceOtherLog = YES;
    }
    return self;
}

- (void)logMessage:(NSString *)message fields:(NSDictionary<NSString*, NSString*>*)fields {
    if(!message && !fields) return;
    
    NSMutableDictionary *logItem = [NSMutableDictionary dictionary];
    [logItem setValue:fields forKey:@"fields"];
    
    NSMutableArray<NSDictionary *> *mutableLogs = [NSMutableArray arrayWithArray:self.logs];
    [mutableLogs addObject:[logItem copy]];
    self.logs = mutableLogs;
}

@end
