//
//  TTKitchenKeyReporter.m
//  TTKitchen
//
//  Created by liujinxing on 2020/8/31.
//

#import "TTKitchenKeyReporter.h"
#import <Heimdallr/HMDUserExceptionTracker.h>
#import <ByteDanceKit/BTDMacros.h>


@interface TTKitchenKeyReporter ()

@property (atomic, assign) NSTimeInterval lastInjectTime;

// 用于上报key访问时堆栈信息的一些属性
@property (nonatomic, assign) double reporterInitTime;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *messagesForkeyWaittingForReport;
@property (nonatomic, strong) dispatch_semaphore_t messagesSemaphore;

@property (nonatomic, strong) NSMutableSet <NSString *> * keysHaveBeenReported;
@property (nonatomic, strong) dispatch_semaphore_t reportedKeysSemaphore;


@end

@implementation TTKitchenKeyReporter

+ (instancetype)sharedReporter {
    static dispatch_once_t onceToken;
    static TTKitchenKeyReporter *reporter;
    dispatch_once(&onceToken, ^{
        reporter = TTKitchenKeyReporter.new;
    });
    return reporter;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _reporterInitTime = [[NSDate date] timeIntervalSince1970];
        _keyStackReportRepeatly = NO;
        _messagesSemaphore = dispatch_semaphore_create(1);
        _reportedKeysSemaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reportKeysUsedBeforeHeimdallrRunning {
    @weakify(self);
    dispatch_semaphore_wait(self.messagesSemaphore, DISPATCH_TIME_FOREVER);
    NSDictionary <NSString *, NSDictionary<NSString *,id> *> *tmpMessages = [self.messagesForkeyWaittingForReport copy];
    dispatch_semaphore_signal(self.messagesSemaphore);
    [tmpMessages enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary<NSString *,id> * _Nonnull messages, BOOL * _Nonnull stop) {
        @strongify(self);
        NSMutableDictionary *params = NSMutableDictionary.new;
        [params setValue:key forKey:@"key"];
        [params setValue:messages[@"access_time"] forKey:@"access_time"];
        [params setValue:messages[@"thread"] forKey:@"thread"];
        [[HMDUserExceptionTracker sharedTracker] trackUserExceptionWithType:@"SettingsKeyReporter" backtracesArray:@[messages[@"backtrace"]] customParams:params filters:nil callback:^(NSError * _Nullable error) {
            if (!error) {
                dispatch_semaphore_wait(self.reportedKeysSemaphore, DISPATCH_TIME_FOREVER);
                [self.keysHaveBeenReported addObject:key];
                dispatch_semaphore_signal(self.reportedKeysSemaphore);
            }
        }];
    }];
    dispatch_semaphore_wait(self.messagesSemaphore, DISPATCH_TIME_FOREVER);
    [self.messagesForkeyWaittingForReport removeAllObjects];
    dispatch_semaphore_signal(self.messagesSemaphore);
    
}

- (void)kitchenWillGetKey:(NSString *)key {
    if (!self.keyStackReportEnabled) {
        return;
    }
    if (!self.keyStackReportRepeatly) {
        dispatch_semaphore_wait(self.reportedKeysSemaphore, DISPATCH_TIME_FOREVER);
        NSSet *tmpSet = [self.keysHaveBeenReported copy];
        dispatch_semaphore_signal(self.reportedKeysSemaphore);
        if ([tmpSet containsObject:key]) {
            return;
        }
    }
    double useTime = [[NSDate date] timeIntervalSince1970] - self.reporterInitTime;
    if (![HMDUserExceptionTracker sharedTracker].isRunning) {
        HMDThreadBacktrace * backTrace = [HMDThreadBacktrace backtraceOfThread:[HMDThreadBacktrace currentThread] symbolicate:YES skippedDepth:0 suspend:YES];
        NSMutableDictionary <NSString *, id> *params = NSMutableDictionary.new;
        [params setValue:[NSString stringWithFormat:@"%f", useTime] forKey:@"access_time"];
        [params setValue:[NSString stringWithFormat:@"%@",[NSThread currentThread]] forKey:@"thread"];
        [params setValue:backTrace forKey:@"backtrace"];
        dispatch_semaphore_wait(self.messagesSemaphore, DISPATCH_TIME_FOREVER);
        [self.messagesForkeyWaittingForReport setValue:params forKey:key];
        dispatch_semaphore_signal(self.messagesSemaphore);
    }
    else {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self reportKeysUsedBeforeHeimdallrRunning];
        });
        NSMutableDictionary <NSString *, id> *params = NSMutableDictionary.new;
        [params setValue:key forKey:@"key"];
        [params setValue:[NSNumber numberWithDouble:useTime] forKey:@"access_time"];
        [params setValue:[NSString stringWithFormat:@"%@",[NSThread currentThread]] forKey:@"thread"];
        @weakify(self);
        [[HMDUserExceptionTracker sharedTracker] trackCurrentThreadLogExceptionType:@"SettingsKeyReporter" skippedDepth:0 customParams:params filters:nil callback:^(NSError * _Nullable error) {
            @strongify(self);
            if (!error) {
                dispatch_semaphore_wait(self.reportedKeysSemaphore, DISPATCH_TIME_FOREVER);
                [self.keysHaveBeenReported addObject:key];
                dispatch_semaphore_signal(self.reportedKeysSemaphore);
            }
        }];
    }
}

- (NSMutableDictionary<NSString *,NSDictionary<NSString *,id> *> *)messagesForkeyWaittingForReport {
    if (!_messagesForkeyWaittingForReport) {
        _messagesForkeyWaittingForReport = NSMutableDictionary.new;
    }
    return _messagesForkeyWaittingForReport;
}

- (NSMutableSet<NSString *> *)keysHaveBeenReported {
    if (!_keysHaveBeenReported) {
        _keysHaveBeenReported = NSMutableSet.new;
    }
    return _keysHaveBeenReported;
}

// MARK: - TTKitchenKeyErrorReporter
- (void)reportMigrationErrorWithMsg:(NSDictionary *)msg {
    if ([[HMDUserExceptionTracker sharedTracker] isRunning]) {
        [[HMDUserExceptionTracker sharedTracker] trackCurrentThreadLogExceptionType:@"TTKitchenMigrationFailed" skippedDepth:0 customParams:msg filters:nil callback:nil];
    }
    else {
        HMDThreadBacktrace * backTrace = [HMDThreadBacktrace backtraceOfThread:[HMDThreadBacktrace currentThread] symbolicate:YES skippedDepth:0 suspend:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (backTrace) {
                [[HMDUserExceptionTracker sharedTracker] trackUserExceptionWithType:@"TTKitchenMigrationFailed" backtracesArray:@[backTrace] customParams:msg filters:nil callback:nil];
            }
        });
    }
}
- (void)reportMMKVErrorWithMsg:(NSDictionary *)msg {
    if ([[HMDUserExceptionTracker sharedTracker] isRunning]) {
        [[HMDUserExceptionTracker sharedTracker] trackCurrentThreadLogExceptionType:@"TTKitchenMMKVError" skippedDepth:0 customParams:msg filters:nil callback:nil];
    }
    else {
        HMDThreadBacktrace * backTrace = [HMDThreadBacktrace backtraceOfThread:[HMDThreadBacktrace currentThread] symbolicate:YES skippedDepth:0 suspend:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (backTrace) {
                [[HMDUserExceptionTracker sharedTracker] trackUserExceptionWithType:@"TTKitchenMMKVError" backtracesArray:@[backTrace] customParams:msg filters:nil callback:nil];
            }
        });
    }
}

@end
