//
//  TTKitchenModelLog.m
//  TTKitchen-Browser-Core-SettingsSyncer
//
//  Created by Peng Zhou on 2020/4/23.
//

#import "TTKitchenLogManager.h"
#import "TTKitchenManager.h"
#import <ByteDanceKit/BTDMacros.h>

@interface TTKitchenLogManager ()

@property (atomic, copy, nullable)   NSDictionary<NSString*, NSDictionary *> *allLogs;
@property (nonatomic, strong, nonnull)  dispatch_queue_t logQueue;

@end

@implementation TTKitchenLogManager

+ (instancetype)sharedInstance {
    static TTKitchenLogManager* s_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_instance = [[TTKitchenLogManager alloc] init];
    });
    return s_instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _maxLogCount = 3;
        _allLogs = NSDictionary.new;
        _logQueue = dispatch_queue_create("com.bytedance.TTKitchenLogManager", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSDictionary *)getLog {
    return [self.allLogs copy];
}

- (void)addCurrentLogEntry:(NSDictionary *)dict {
    if (_maxLogCount <= 0) {
        return;
    }
    dispatch_async(self.logQueue, ^{
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        NSDictionary *currentKitchen = dict ? [dict copy] : @{};
        
        if (currentKitchen.count == 0) {
            return;
        }
        NSMutableDictionary * tmpAllLogs = [NSMutableDictionary dictionaryWithDictionary:self.allLogs];
        if (tmpAllLogs.count == self.maxLogCount) {
            NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:nil
                                                                       ascending:YES
                                                                        selector:@selector(localizedCompare:)];
            NSString *oldest = [[tmpAllLogs.allKeys sortedArrayUsingDescriptors:@[sortDesc]] firstObject];
            [tmpAllLogs removeObjectForKey:oldest];
        }
        
        [tmpAllLogs setValue:currentKitchen forKey:[NSString stringWithFormat:@"%f", currentTime]];
        self.allLogs = [tmpAllLogs copy];
    });
}

@end
